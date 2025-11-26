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

output "buildkite_project_id" {
  description = "Project ID for the Buildkite CI hub."
  value       = module.buildkite.project_id
}

output "buildkite_project_number" {
  description = "Project number for the Buildkite CI hub."
  value       = module.buildkite.project_number
}

output "buildkite_agent_service_account" {
  description = "Service account email used by Buildkite agents."
  value       = module.buildkite.agent_service_account_email
}

output "buildkite_agent_token_secret" {
  description = "Secret Manager ID that will store the Buildkite agent token."
  value       = module.buildkite.agent_token_secret_id
}

output "buildkite_network" {
  description = "Buildkite VPC network and subnet used by the agent stack."
  value = {
    network   = module.buildkite.network
    subnetwork = module.buildkite.subnetwork
    router    = module.buildkite.router
    nat       = module.buildkite.nat
  }
}
