output "service_url" {
  description = "COS Cloud Run service URL."
  value       = google_cloud_run_service.cos.status[0].url
}

output "service_account_email" {
  description = "Service account running COS."
  value       = google_service_account.cos.email
}

output "database_connection_name" {
  description = "Cloud SQL instance connection name."
  value       = google_sql_database_instance.cos.connection_name
}

output "database_secret_id" {
  description = "Secret Manager secret storing the COS database URL."
  value       = google_secret_manager_secret.db_url.id
}

output "artifact_registry" {
  description = "Artifact Registry path for COS images."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/cos"
}
