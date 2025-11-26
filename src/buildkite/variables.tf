variable "organization_id" {
  description = "Organization ID for the CI hub project."
  type        = string
}

variable "billing_account_id" {
  description = "Billing account ID to link to the CI project."
  type        = string
}

variable "folder_id" {
  description = "Optional folder ID for the CI project."
  type        = string
  default     = null
}

variable "project_id" {
  description = "Project ID for the Buildkite CI hub."
  type        = string
}

variable "project_name" {
  description = "Display name for the Buildkite CI hub project."
  type        = string
}

variable "region" {
  description = "Region for regional resources."
  type        = string
}

variable "base_labels" {
  description = "Common labels applied to the CI project."
  type        = map(string)
  default     = {}
}

variable "core_admin_account" {
  description = "Email for the core admin owner of the CI project."
  type        = string
}

variable "platform_owner_account" {
  description = "Email for the primary platform owner."
  type        = string
}

variable "additional_admins" {
  description = "Additional IAM member strings to grant owner access in the CI project."
  type        = list(string)
  default     = []
}

variable "buildkite_organization_slug" {
  description = "Buildkite organization slug for the Elastic CI stack."
  type        = string
}

variable "stack_name" {
  description = "Name prefix for the Elastic CI stack."
  type        = string
  default     = "buildkite"
}

variable "buildkite_queue" {
  description = "Buildkite agent queue name for the CI stack."
  type        = string
  default     = "default"
}

variable "agent_machine_type" {
  description = "Machine type for the Buildkite agent VMs."
  type        = string
  default     = "e2-standard-4"
}

variable "agent_min_replicas" {
  description = "Minimum number of agent VMs."
  type        = number
  default     = 0
}

variable "agent_max_replicas" {
  description = "Maximum number of agent VMs."
  type        = number
  default     = 2
}

variable "agent_token_secret_id" {
  description = "Secret Manager secret ID used for the Buildkite agent token in the CI project."
  type        = string
  default     = "buildkite-agent-token"
}

variable "source_agent_secret_project_id" {
  description = "Project ID containing the existing Buildkite agent secret to seed the CI project's secret."
  type        = string
}

variable "source_agent_secret_name" {
  description = "Secret Manager secret name holding the Buildkite agent token in the source project."
  type        = string
  default     = "buildkite-agent-token"
}

variable "seed_agent_secret" {
  description = "Whether to copy the existing Buildkite agent secret into the CI project automatically."
  type        = bool
  default     = true
}

variable "target_service_accounts" {
  description = "Map of environment name to service account email that Buildkite agents can impersonate."
  type        = map(string)
  default     = {}
}
