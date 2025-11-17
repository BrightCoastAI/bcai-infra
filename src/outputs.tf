output "project_ids" {
  description = "Map of created project IDs."
  value       = module.projects.project_ids
}

output "environment_service_accounts" {
  description = "Per-environment service account emails for automations."
  value       = module.projects.environment_service_accounts
}
