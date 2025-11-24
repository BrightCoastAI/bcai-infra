output "project_ids" {
  description = "Map of created project IDs."
  value       = module.projects.project_ids
}

output "environment_service_accounts" {
  description = "Per-environment service account emails for automations."
  value       = module.projects.environment_service_accounts
}

output "prefect_service_urls" {
  description = "Per-environment Prefect server/UI Cloud Run URLs."
  value       = { for env, mod in module.prefect : env => mod.service_url }
}

output "prefect_runtime_service_accounts" {
  description = "Per-environment service accounts running Prefect."
  value       = { for env, mod in module.prefect : env => mod.service_account_email }
}

output "prefect_work_pools" {
  description = "Per-environment Prefect Cloud Run work pools."
  value       = { for env, mod in module.prefect : env => mod.work_pool_name }
}

output "prefect_database_connection_names" {
  description = "Per-environment Cloud SQL instance connection names used by Prefect."
  value       = { for env, mod in module.prefect : env => mod.database_connection_name }
}

output "prefect_database_secrets" {
  description = "Secret Manager IDs containing Prefect database URLs."
  value       = { for env, mod in module.prefect : env => mod.database_secret_id }
}
