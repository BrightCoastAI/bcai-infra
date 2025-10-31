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
