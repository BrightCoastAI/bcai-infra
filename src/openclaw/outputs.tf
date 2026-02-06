output "instance_name" {
  description = "Name of the OpenClaw VM instance."
  value       = google_compute_instance.openclaw.name
}

output "instance_internal_ip" {
  description = "Internal IP address of the OpenClaw VM."
  value       = google_compute_instance.openclaw.network_interface[0].network_ip
}

output "instance_external_ip" {
  description = "External IP address of the OpenClaw VM (if enabled)."
  value       = try(google_compute_instance.openclaw.network_interface[0].access_config[0].nat_ip, null)
}

output "service_account_email" {
  description = "Service account email used by the OpenClaw VM."
  value       = google_service_account.openclaw.email
}

output "app_token_secret_id" {
  description = "Secret Manager ID for the Slack app token."
  value       = google_secret_manager_secret.slack_app_token.secret_id
}

output "bot_token_secret_id" {
  description = "Secret Manager ID for the Slack bot token."
  value       = google_secret_manager_secret.slack_bot_token.secret_id
}

output "network_name" {
  description = "VPC network name created for OpenClaw."
  value       = google_compute_network.openclaw.name
}

output "subnet_name" {
  description = "Subnet name created for OpenClaw."
  value       = google_compute_subnetwork.openclaw.name
}
