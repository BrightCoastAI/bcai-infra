variable "organization_id" {
  description = "The numeric organization ID for brightcoast.ai."
  type        = string
}

variable "billing_account_id" {
  description = "The billing account ID (e.g. 000000-000000-000000) to associate with projects."
  type        = string
}

variable "dev_project_folder_id" {
  description = "Optional folder ID for the development project. Leave null to attach directly to the organization."
  type        = string
  default     = null
}

variable "prod_project_folder_id" {
  description = "Optional folder ID for the production project. Leave null to attach directly to the organization."
  type        = string
  default     = null
}

variable "ci_project_folder_id" {
  description = "Optional folder ID for the CI/Buildkite project. Leave null to attach directly to the organization."
  type        = string
  default     = null
}

variable "default_region" {
  description = "Primary region for resources and CMEK."
  type        = string
  default     = "australia-southeast1"
}

variable "core_admin_account" {
  description = "Email for the core admin owner of the organization."
  type        = string
  default     = "core@brightcoast.ai"
}

variable "platform_owner_account" {
  description = "Email for the primary platform owner."
  type        = string
  default     = "ben@brightcoast.ai"
}

variable "dev_additional_admins" {
  description = "Extra IAM member strings that should have owner access in the dev project."
  type        = list(string)
  default     = []
}

variable "prod_additional_admins" {
  description = "Extra IAM member strings that should have owner access in the prod project."
  type        = list(string)
  default     = []
}

variable "ci_additional_admins" {
  description = "Extra IAM member strings that should have owner access in the CI project."
  type        = list(string)
  default     = []
}

variable "buildkite_project_id" {
  description = "Project ID to create for the Buildkite CI hub."
  type        = string
  default     = "bc-ci-brightcoast"
}

variable "buildkite_project_name" {
  description = "Display name for the Buildkite CI hub project."
  type        = string
  default     = "bc-ci"
}

variable "buildkite_organization_slug" {
  description = "Buildkite organization slug for the Elastic CI stack."
  type        = string
}

variable "buildkite_stack_name" {
  description = "Name prefix for the Buildkite Elastic CI stack."
  type        = string
  default     = "buildkite"
}

variable "buildkite_source_secret_project_id" {
  description = "Project ID that already holds the buildkite-agent secret to seed into the CI project."
  type        = string
  default     = "bc-prod-brightcoast"
}

variable "buildkite_source_agent_secret_name" {
  description = "Secret Manager name holding the Buildkite agent token (in the source project)."
  type        = string
  default     = "buildkite-agent-token"
}

variable "buildkite_agent_token_secret_id" {
  description = "Secret ID to create in the CI project for the Buildkite agent token."
  type        = string
  default     = "buildkite-agent-token"
}

variable "buildkite_seed_agent_secret" {
  description = "Whether to copy the existing Buildkite agent secret into the CI project automatically."
  type        = bool
  default     = true
}

variable "buildkite_queue" {
  description = "Queue name Buildkite agents should register against."
  type        = string
  default     = "self-hosted"
}

variable "quota_project_id" {
  description = "Project ID to use for client-side quota when working with admin APIs."
  type        = string
  default     = null
}
