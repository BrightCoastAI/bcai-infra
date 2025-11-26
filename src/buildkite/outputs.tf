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
  value       = google_service_account.buildkite_agents.email
}

output "agent_token_secret_id" {
  description = "Secret Manager secret ID that will store the Buildkite agent token."
  value       = google_secret_manager_secret.buildkite_agent_token.id
}

output "network" {
  description = "Buildkite VPC network name."
  value       = google_compute_network.buildkite.name
}

output "subnetwork" {
  description = "Buildkite subnet self link."
  value       = google_compute_subnetwork.buildkite.self_link
}

output "router" {
  description = "Cloud Router name for Buildkite NAT."
  value       = google_compute_router.buildkite.name
}

output "nat" {
  description = "Cloud NAT name for Buildkite egress."
  value       = google_compute_router_nat.buildkite.name
}
