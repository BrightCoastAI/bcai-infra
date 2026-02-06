locals {
  name_prefix = var.name_prefix
  labels      = merge(var.labels, { component = "openclaw" })
  network_tag = "${var.name_prefix}-ssh"
}

resource "google_compute_network" "openclaw" {
  project                 = var.project_id
  name                    = "${local.name_prefix}-net"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "openclaw" {
  project       = var.project_id
  name          = "${local.name_prefix}-subnet"
  region        = var.region
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.openclaw.id
}

resource "google_compute_firewall" "ssh" {
  project = var.project_id
  name    = "${local.name_prefix}-ssh"
  network = google_compute_network.openclaw.name

  direction     = "INGRESS"
  priority      = 1000
  source_ranges = var.ssh_source_ranges
  target_tags   = [local.network_tag]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "egress" {
  project = var.project_id
  name    = "${local.name_prefix}-egress"
  network = google_compute_network.openclaw.name

  direction          = "EGRESS"
  priority           = 1000
  destination_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "all"
  }
}

resource "google_secret_manager_secret" "slack_app_token" {
  project   = var.project_id
  secret_id = var.app_token_secret_id

  replication {
    auto {}
  }

  labels = local.labels
}

resource "google_secret_manager_secret" "slack_bot_token" {
  project   = var.project_id
  secret_id = var.bot_token_secret_id

  replication {
    auto {}
  }

  labels = local.labels
}

resource "google_service_account" "openclaw" {
  project      = var.project_id
  account_id   = "${local.name_prefix}-sa"
  display_name = "OpenClaw runtime"
  description  = "Service account for the OpenClaw gateway VM."
}

locals {
  runtime_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/secretmanager.secretAccessor",
  ]
}

resource "google_project_iam_member" "openclaw_runtime_roles" {
  for_each = toset(local.runtime_roles)

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.openclaw.email}"
}

resource "google_compute_instance" "openclaw" {
  project      = var.project_id
  name         = "${local.name_prefix}-vm"
  zone         = var.zone
  machine_type = var.machine_type
  labels       = local.labels
  tags         = [local.network_tag]

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.boot_disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.openclaw.id

    dynamic "access_config" {
      for_each = var.enable_external_ip ? [1] : []
      content {}
    }
  }

  service_account {
    email  = google_service_account.openclaw.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = file("${path.module}/startup-lite.sh")

  depends_on = [
    google_secret_manager_secret.slack_app_token,
    google_secret_manager_secret.slack_bot_token,
  ]
}
