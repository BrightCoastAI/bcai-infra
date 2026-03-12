# ── AI Chief of Staff (COS) ──────────────────────────────────────────────
#
# Per-environment Cloud SQL + Cloud Run for the COS pipeline.
# Secrets (graph creds, telegram, openrouter, logfire) are created
# externally and referenced by name using the {profile}-{suffix} pattern.
# Only the database-url secret is managed here (computed from Cloud SQL).

locals {
  name_prefix = "cos-${var.environment}"
  labels      = merge(var.labels, { component = "cos" })

  # The 7 externally-managed secrets, referenced by their Secret Manager
  # name.  The profile prefix (e.g. "dev-", "adam-") comes from var.cos_profile.
  secrets = {
    GRAPH_TENANT_ID     = "${var.cos_profile}-graph-tenant-id"
    GRAPH_CLIENT_ID     = "${var.cos_profile}-graph-client-id"
    GRAPH_CLIENT_SECRET = "${var.cos_profile}-graph-client-secret"
    TELEGRAM_BOT_TOKEN  = "${var.cos_profile}-telegram-bot-token"
    TELEGRAM_CHAT_ID    = "${var.cos_profile}-telegram-chat-id"
    OPENROUTER_API_KEY  = "${var.cos_profile}-openrouter-api-key"
    LOGFIRE_TOKEN       = "${var.cos_profile}-logfire-token"
  }
}

# ── Cloud SQL ────────────────────────────────────────────────────────────

resource "random_password" "db" {
  length  = 24
  special = true
}

resource "google_sql_database_instance" "cos" {
  name             = "${local.name_prefix}-sql"
  project          = var.project_id
  region           = var.region
  database_version = "POSTGRES_15"

  deletion_protection = var.environment == "prod"

  settings {
    tier              = var.sql_tier
    disk_size         = var.db_disk_size_gb
    disk_autoresize   = true
    activation_policy = "ALWAYS"
    user_labels       = local.labels

    ip_configuration {
      ipv4_enabled = true
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = var.environment == "prod"
    }

    insights_config {
      query_insights_enabled = true
    }
  }
}

resource "google_sql_database" "cos" {
  name     = "cos"
  instance = google_sql_database_instance.cos.name
  project  = var.project_id
}

resource "google_sql_user" "cos" {
  name     = "cos"
  instance = google_sql_database_instance.cos.name
  project  = var.project_id
  password = random_password.db.result
}

# ── Database URL secret (managed by Terraform) ──────────────────────────

resource "google_secret_manager_secret" "db_url" {
  secret_id = "${var.cos_profile}-database-url"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = local.labels
}

resource "google_secret_manager_secret_version" "db_url" {
  secret      = google_secret_manager_secret.db_url.id
  secret_data = "postgresql://cos:${urlencode(random_password.db.result)}@/${google_sql_database.cos.name}?host=/cloudsql/${google_sql_database_instance.cos.connection_name}"
}

# ── Service account ──────────────────────────────────────────────────────

resource "google_service_account" "cos" {
  project      = var.project_id
  account_id   = "${local.name_prefix}-sa"
  display_name = "COS ${var.environment} runtime"
  description  = "Runs the AI Chief of Staff Cloud Run service."
}

locals {
  runtime_roles = [
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor",
    "roles/run.invoker",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ]
}

resource "google_project_iam_member" "cos_runtime_roles" {
  for_each = toset(local.runtime_roles)

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.cos.email}"
}

# ── Cloud Run service ────────────────────────────────────────────────────

resource "google_cloud_run_service" "cos" {
  name     = "${local.name_prefix}-service"
  location = var.region
  project  = var.project_id

  metadata {
    annotations = {
      "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing"
    }
  }

  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale"      = tostring(var.min_instances)
        "autoscaling.knative.dev/maxScale"      = tostring(var.min_instances)
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.cos.connection_name
        "run.googleapis.com/cpu-throttling"     = "false"
      }
      labels = local.labels
    }

    spec {
      service_account_name  = google_service_account.cos.email
      container_concurrency = 1

      containers {
        image = var.cos_image

        ports {
          container_port = 8080
        }

        resources {
          limits = {
            cpu    = var.cloud_run_cpu
            memory = var.cloud_run_memory
          }
        }

        # ── Profile selection ────────────────────────────────────────
        env {
          name  = "COS_PROFILE"
          value = var.cos_profile
        }

        # ── Database URL (Terraform-managed secret) ──────────────────
        env {
          name = "COS_DATABASE_URL"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.db_url.secret_id
              key  = "latest"
            }
          }
        }

        # ── Externally-managed secrets ───────────────────────────────
        dynamic "env" {
          for_each = local.secrets
          content {
            name = env.key
            value_from {
              secret_key_ref {
                name = env.value
                key  = "latest"
              }
            }
          }
        }

        command = ["/bin/sh"]
        args = [
          "-c",
          <<-EOT
            set -euo pipefail
            PORT="$${PORT:-8080}"
            python -m http.server "$${PORT}" &>/dev/null &
            exec cos --profile "$${COS_PROFILE}" loop
          EOT
        ]
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_iam_member.cos_runtime_roles,
    google_secret_manager_secret_version.db_url,
  ]
}
