output "project_id" {
  description = "ID of the Buildkite CI project."
  value       = google_project.ci.project_id
}

output "project_number" {
  description = "Numeric ID of the Buildkite CI project."
  value       = google_project.ci.number
}

output "agent_service_account_email" {
  description = "Service account used by Buildkite agents."
  value       = module.buildkite_stack.agent_service_account_email
}

output "agent_token_secret_id" {
  description = "Secret Manager ID that stores the Buildkite agent token."
  value       = google_secret_manager_secret.buildkite_agent_token.id
}

output "buildkite_queue" {
  description = "Queue name Buildkite agents listen to."
  value       = var.buildkite_queue
}

output "network_name" {
  description = "Name of the VPC network created for the stack."
  value       = module.buildkite_stack.network_name
}

output "instance_group_manager_name" {
  description = "Name of the managed instance group running agents."
  value       = module.buildkite_stack.instance_group_manager_name
}
