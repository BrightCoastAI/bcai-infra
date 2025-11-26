locals {
  labels = merge(
    var.base_labels,
    {
      environment = "ci"
      cost_center = "ci"
      component   = "buildkite"
    }
  )

  services = [
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "storage.googleapis.com",
    "secretmanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudkms.googleapis.com",
  ]

  owner_members = distinct(
    compact(
      concat(
        [
          "user:${var.core_admin_account}",
          "user:${var.platform_owner_account}",
        ],
        var.additional_admins,
      )
    )
  )

  buildkite_agent_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/storage.objectViewer",
    "roles/artifactregistry.reader",
    "roles/secretmanager.secretAccessor",
  ]
}

resource "google_project" "ci" {
  name                = var.project_name
  project_id          = var.project_id
  org_id              = var.folder_id == null ? var.organization_id : null
  folder_id           = var.folder_id
  billing_account     = var.billing_account_id
  labels              = local.labels
  auto_create_network = false
}

resource "google_project_service" "ci" {
  for_each = toset(local.services)

  project = google_project.ci.project_id
  service = each.key

  disable_on_destroy         = false
  disable_dependent_services = true
}

resource "google_project_iam_member" "owner_members" {
  for_each = toset(local.owner_members)

  project = google_project.ci.project_id
  role    = "roles/owner"
  member  = each.key
}

resource "google_project_iam_member" "service_account_admins" {
  for_each = toset(local.owner_members)

  project = google_project.ci.project_id
  role    = "roles/iam.serviceAccountAdmin"
  member  = each.key
}

resource "google_service_account" "buildkite_agents" {
  project      = google_project.ci.project_id
  account_id   = "buildkite-agents"
  display_name = "Buildkite agents"
  description  = "Runs the Buildkite Elastic CI stack in the CI hub project."
}

resource "google_project_iam_member" "buildkite_agent_roles" {
  for_each = toset(local.buildkite_agent_roles)

  project = google_project.ci.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.buildkite_agents.email}"
}

resource "google_secret_manager_secret" "buildkite_agent_token" {
  project   = google_project.ci.project_id
  secret_id = "buildkite-agent-token"

  replication {
    auto {}
  }

  labels = local.labels
}

resource "google_compute_network" "buildkite" {
  name                    = var.network_name
  project                 = google_project.ci.project_id
  auto_create_subnetworks = false

  depends_on = [google_project_service.ci]
}

resource "google_compute_subnetwork" "buildkite" {
  name                     = "${var.network_name}-subnet"
  project                  = google_project.ci.project_id
  region                   = var.region
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true
  network                  = google_compute_network.buildkite.id

  depends_on = [google_project_service.ci]
}

resource "google_compute_router" "buildkite" {
  name    = "${var.network_name}-router"
  project = google_project.ci.project_id
  region  = var.region
  network = google_compute_network.buildkite.id

  depends_on = [google_project_service.ci]
}

resource "google_compute_router_nat" "buildkite" {
  name   = "${var.network_name}-nat"
  region = var.region
  router = google_compute_router.buildkite.name
  project = google_project.ci.project_id

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.buildkite.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  depends_on = [google_project_service.ci]
}

resource "google_service_account_iam_member" "impersonation" {
  for_each = var.target_service_accounts

  service_account_id = "projects/-/serviceAccounts/${each.value}"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.buildkite_agents.email}"
}
