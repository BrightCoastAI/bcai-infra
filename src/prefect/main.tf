locals {
  name_prefix    = "prefect-${var.environment}"
  labels         = merge(var.labels, { environment = var.environment, component = "prefect" })
  work_pool_name = "gcp-cloud-run-pool"
  worker_name    = "gcp-cloud-run-worker"
}

resource "random_password" "db" {
  length  = 24
  special = true
}

resource "random_password" "api_auth_password" {
  length  = 20
  special = false
}

locals {
  api_auth_username = "admin"
  api_auth_string   = "${local.api_auth_username}:${random_password.api_auth_password.result}"
}

resource "google_artifact_registry_repository" "prefect" {
  project       = var.project_id
  location      = var.region
  repository_id = "prefect"
  description   = "Prefect images for ${var.environment}"
  format        = "DOCKER"
  labels        = local.labels
}

resource "google_sql_database_instance" "prefect" {
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

resource "google_sql_database" "prefect" {
  name     = "prefect"
  instance = google_sql_database_instance.prefect.name
  project  = var.project_id
}

resource "google_sql_user" "prefect" {
  name     = "prefect"
  instance = google_sql_database_instance.prefect.name
  project  = var.project_id
  password = random_password.db.result
}

resource "google_secret_manager_secret" "db_url" {
  secret_id = "${local.name_prefix}-database-url"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = local.labels
}

resource "google_secret_manager_secret_version" "db_url" {
  secret      = google_secret_manager_secret.db_url.id
  secret_data = "postgresql+asyncpg://prefect:${urlencode(random_password.db.result)}@/${google_sql_database.prefect.name}?host=/cloudsql/${google_sql_database_instance.prefect.connection_name}"
}

resource "google_secret_manager_secret" "api_auth" {
  secret_id = "${local.name_prefix}-api-auth"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = local.labels
}

resource "google_secret_manager_secret_version" "api_auth" {
  secret      = google_secret_manager_secret.api_auth.id
  secret_data = local.api_auth_string
}

resource "google_service_account" "prefect" {
  project      = var.project_id
  account_id   = "${local.name_prefix}-sa"
  display_name = "Prefect ${var.environment} runtime"
  description  = "Runs Prefect server/UI and Cloud Run worker."
}

locals {
  runtime_roles = [
    "roles/editor",
    "roles/run.admin",
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor",
    "roles/iam.serviceAccountUser",
    "roles/artifactregistry.reader",
  ]
}

resource "google_project_iam_member" "prefect_runtime_roles" {
  for_each = toset(local.runtime_roles)

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.prefect.email}"
}

resource "google_service_account_iam_member" "prefect_act_as_self" {
  service_account_id = google_service_account.prefect.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.prefect.email}"
}

resource "google_cloud_run_service" "prefect_api" {
  name     = "${local.name_prefix}-api"
  location = var.region
  project  = var.project_id

  metadata {
    annotations = {
      "run.googleapis.com/ingress" = "all"
    }
  }

  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale"      = tostring(var.min_instances)
        "autoscaling.knative.dev/maxScale"      = tostring(var.min_instances)
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.prefect.connection_name
        "run.googleapis.com/cpu-throttling"     = "false"
      }
      labels = local.labels
    }

    spec {
      service_account_name  = google_service_account.prefect.email
      container_concurrency = 10

      containers {
        image = var.prefect_image

        ports {
          container_port = 8080
        }

        resources {
          limits = {
            cpu    = var.cloud_run_cpu
            memory = var.cloud_run_memory
          }
        }

        env {
          name = "PREFECT_API_DATABASE_CONNECTION_URL"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.db_url.secret_id
              key  = "latest"
            }
          }
        }

        env {
          name  = "PREFECT_SERVER_API_HOST"
          value = "0.0.0.0"
        }

        env {
          name  = "PREFECT_SERVER_API_PORT"
          value = "8080"
        }

        env {
          name  = "PREFECT_WORK_POOL_NAME"
          value = local.work_pool_name
        }

        env {
          name  = "PREFECT_LOGGING_LEVEL"
          value = "INFO"
        }

        # Ensure event-driven automations are enabled (Prefect accepts both
        # PREFECT_API_* and PREFECT_SERVER_* prefixes; we standardize on API).
        env {
          name  = "PREFECT_API_SERVICES_TRIGGERS_ENABLED"
          value = "true"
        }

        env {
          name  = "PREFECT_API_SERVICES_EVENT_PERSISTER_ENABLED"
          value = "true"
        }

        env {
          name = "PREFECT_SERVER_API_AUTH_STRING"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.api_auth.secret_id
              key  = "latest"
            }
          }
        }

        env {
          name = "PREFECT_API_AUTH_STRING"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.api_auth.secret_id
              key  = "latest"
            }
          }
        }

        # Force UI to call the API on the same origin instead of 0.0.0.0.
        env {
          name  = "PREFECT_UI_API_URL"
          value = "/api"
        }

        command = ["/bin/sh"]
        args = [
          "-c",
          <<-EOT
            set -euo pipefail

            PORT="$${PORT:-8080}"
            prefect server start --host 0.0.0.0 --port "$${PORT}" --log-level INFO
          EOT
        ]
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_member" "api_invoker" {
  location = var.region
  project  = var.project_id
  service  = google_cloud_run_service.prefect_api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service" "prefect_worker" {
  name     = "${local.name_prefix}-worker"
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
        "autoscaling.knative.dev/minScale"  = "1"
        "run.googleapis.com/cpu-throttling" = "false"
      }
      labels = merge(local.labels, { component = "prefect-worker" })
    }

    spec {
      service_account_name  = google_service_account.prefect.email
      container_concurrency = 1

      containers {
        image = var.prefect_image

        ports {
          container_port = 8080
        }

        resources {
          limits = {
            cpu    = var.cloud_run_cpu
            memory = var.cloud_run_memory
          }
        }

        env {
          name  = "PREFECT_API_URL"
          value = "${google_cloud_run_service.prefect_api.status[0].url}/api"
        }

        env {
          name  = "PREFECT_WORK_POOL_NAME"
          value = local.work_pool_name
        }

        env {
          name  = "PREFECT_WORKER_NAME"
          value = local.worker_name
        }

        env {
          name  = "PREFECT_LOGGING_LEVEL"
          value = "INFO"
        }

        env {
          name  = "PREFECT_API_ENABLE_HTTP2"
          value = "false"
        }

        env {
          name  = "PREFECT_DEBUG_MODE"
          value = "1"
        }

        env {
          name = "PREFECT_API_AUTH_STRING"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.api_auth.secret_id
              key  = "latest"
            }
          }
        }

        env {
          name  = "PREFECT_API_AUTH_SECRET_NAME"
          value = google_secret_manager_secret.api_auth.secret_id
        }

        env {
          name  = "WORKER_REGION"
          value = var.region
        }

        env {
          name  = "WORKER_SERVICE_ACCOUNT"
          value = google_service_account.prefect.email
        }

        env {
          name  = "WORKER_IMAGE"
          value = var.prefect_image
        }

        command = ["/bin/sh"]
        args = [
          "-c",
          <<-EOT
            set -euo pipefail

            POOL_NAME="$${PREFECT_WORK_POOL_NAME}"
            WORKER_NAME="$${PREFECT_WORKER_NAME}"
            PORT="$${PORT:-8080}"

            # Lightweight health endpoint for Cloud Run readiness/liveness.
            python -m http.server "$${PORT}" >/tmp/health.log 2>&1 &

            # Ensure Cloud Run worker type is available (no-op when using custom image).
            pip install --no-cache-dir "prefect-gcp>=0.6.0" >/tmp/prefect-gcp-install.log 2>&1 || true

            # Create pool only if it doesn't exist yet (never --overwrite).
            prefect work-pool inspect "$${POOL_NAME}" >/dev/null 2>&1 || \
              prefect work-pool create "$${POOL_NAME}" --type cloud-run

            # Patch the work pool base job template so spawned Cloud Run jobs
            # inherit the API URL, auth credentials, region, service account,
            # and image from the worker's environment.
            python3 - <<'PYEOF'
            import base64
            import os

            import httpx

            api_url = os.environ["PREFECT_API_URL"].rstrip("/")
            auth = os.environ.get("PREFECT_API_AUTH_STRING", "")
            pool_name = os.environ["PREFECT_WORK_POOL_NAME"]
            region = os.environ.get("WORKER_REGION", "australia-southeast1")
            service_account = os.environ.get("WORKER_SERVICE_ACCOUNT", "")
            image = os.environ.get("WORKER_IMAGE", "")
            auth_secret_name = os.environ.get("PREFECT_API_AUTH_SECRET_NAME", "")

            headers = {}
            if auth:
                b64 = base64.b64encode(auth.encode()).decode()
                headers["Authorization"] = f"Basic {b64}"

            resp = httpx.get(f"{api_url}/work_pools/{pool_name}", headers=headers, timeout=30.0)
            resp.raise_for_status()
            pool = resp.json()

            template = pool.get("base_job_template") or {}
            variables = template.get("variables") or {}
            properties = variables.get("properties") or {}

            changed = False

            def set_default(property_name: str, value: str) -> bool:
                prop = properties.get(property_name)
                if not isinstance(prop, dict) or not value:
                    return False
                if prop.get("default") == value:
                    return False
                prop["default"] = value
                return True

            changed = set_default("region", region) or changed
            changed = set_default("service_account_name", service_account) or changed
            changed = set_default("image", image) or changed

            env_prop = properties.get("env")
            if isinstance(env_prop, dict):
                current_env_default = env_prop.get("default")
                if not isinstance(current_env_default, dict):
                    current_env_default = {}

                new_env_default = dict(current_env_default)
                new_env_default["PREFECT_API_URL"] = api_url

                auth_added_via_secret_selector = False
                auth_secret_prop = properties.get("prefect_api_auth_string_secret")
                if auth_secret_name and isinstance(auth_secret_prop, dict):
                    secret_selector = {"secret": auth_secret_name, "version": "latest"}
                    if auth_secret_prop.get("default") != secret_selector:
                        auth_secret_prop["default"] = secret_selector
                        changed = True
                    auth_added_via_secret_selector = True

                if auth and not auth_added_via_secret_selector:
                    new_env_default["PREFECT_API_AUTH_STRING"] = auth

                if current_env_default != new_env_default:
                    env_prop["default"] = new_env_default
                    changed = True

            if changed:
                resp = httpx.patch(
                    f"{api_url}/work_pools/{pool_name}",
                    headers=headers,
                    json={"base_job_template": template},
                    timeout=30.0,
                )
                resp.raise_for_status()
                print("Work pool template updated successfully")
            else:
                print("Work pool template already up to date")
            PYEOF

            prefect worker start --type cloud-run --pool "$${POOL_NAME}" --name "$${WORKER_NAME}"
          EOT
        ]
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_storage_bucket" "cache" {
  name                        = "bcai-prefect-cache-${var.environment}"
  location                    = var.region
  project                     = var.project_id
  uniform_bucket_level_access = true
  labels                      = local.labels
}
