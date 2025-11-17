locals {
  environment_service_accounts = {
    dev = {
      project_id   = google_project.dev.project_id
      account_id   = "env-dev-sa"
      display_name = "Dev Automation Service Account"
      description  = "General-purpose service account for dev automation and workflows."
    }
    prod = {
      project_id   = google_project.prod.project_id
      account_id   = "env-prod-sa"
      display_name = "Prod Automation Service Account"
      description  = "General-purpose service account for prod automation and workflows."
    }
  }
}

resource "google_service_account" "environment" {
  for_each = local.environment_service_accounts

  project      = each.value.project_id
  account_id   = each.value.account_id
  display_name = each.value.display_name
  description  = each.value.description
}
