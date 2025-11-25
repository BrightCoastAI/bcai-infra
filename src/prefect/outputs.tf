output "service_url" {
  description = "Prefect server/UI Cloud Run URL."
  value       = google_cloud_run_service.prefect_api.status[0].url
}

output "service_account_email" {
  description = "Service account running Prefect."
  value       = google_service_account.prefect.email
}

output "work_pool_name" {
  description = "Name of the Prefect work pool managed by the worker."
  value       = local.work_pool_name
}

output "database_connection_name" {
  description = "Cloud SQL instance connection name."
  value       = google_sql_database_instance.prefect.connection_name
}

output "database_secret_id" {
  description = "Secret Manager secret storing the database connection URL."
  value       = google_secret_manager_secret.db_url.id
}
