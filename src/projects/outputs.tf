output "project_ids" {
  description = "Map of project identifiers."
  value = {
    dev  = google_project.dev.project_id
    prod = google_project.prod.project_id
  }
}

output "project_numbers" {
  description = "Map of project numeric IDs."
  value = {
    dev  = google_project.dev.number
    prod = google_project.prod.number
  }
}

output "environment_service_accounts" {
  description = "Per-environment service account emails for automations."
  value = {
    dev  = google_service_account.environment["dev"].email
    prod = google_service_account.environment["prod"].email
  }
}
