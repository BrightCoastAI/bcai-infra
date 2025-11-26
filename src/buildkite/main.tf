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
    "cloudfunctions.googleapis.com",
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudscheduler.googleapis.com",
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

resource "google_secret_manager_secret" "buildkite_agent_token" {
  project   = google_project.ci.project_id
  secret_id = var.agent_token_secret_id

  replication {
    auto {}
  }

  labels = local.labels

  depends_on = [google_project_service.ci]
}

data "google_secret_manager_secret_version" "source_agent_token" {
  count = var.seed_agent_secret ? 1 : 0

  project = var.source_agent_secret_project_id
  secret  = var.source_agent_secret_name
  version = "latest"
}

resource "google_secret_manager_secret_version" "buildkite_agent_token" {
  count = var.seed_agent_secret ? 1 : 0

  secret      = google_secret_manager_secret.buildkite_agent_token.id
  secret_data = data.google_secret_manager_secret_version.source_agent_token[0].secret_data
}

module "buildkite_stack" {
  source = "github.com/buildkite/terraform-buildkite-elastic-ci-stack-for-gcp"

  project_id                   = google_project.ci.project_id
  region                       = var.region
  buildkite_organization_slug  = var.buildkite_organization_slug
  buildkite_agent_token_secret = var.agent_token_secret_id

  stack_name      = var.stack_name
  buildkite_queue = var.buildkite_queue
  min_size        = var.agent_min_replicas
  max_size        = var.agent_max_replicas
  machine_type    = var.agent_machine_type
  labels          = local.labels
  zones           = ["${var.region}-a", "${var.region}-b"]

  depends_on = [google_project_service.ci]
}

resource "google_service_account_iam_member" "impersonation" {
  for_each = var.target_service_accounts

  service_account_id = "projects/-/serviceAccounts/${each.value}"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${module.buildkite_stack.agent_service_account_email}"
}
