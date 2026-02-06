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

variable "openclaw_zone" {
  description = "Zone for the OpenClaw VM."
  type        = string
  default     = "australia-southeast1-a"
}

variable "openclaw_machine_type" {
  description = "Machine type for the OpenClaw VM."
  type        = string
  default     = "e2-small"
}

variable "openclaw_disk_size_gb" {
  description = "Boot disk size (GB) for the OpenClaw VM."
  type        = number
  default     = 30
}

variable "openclaw_subnet_cidr" {
  description = "CIDR block for the OpenClaw subnet."
  type        = string
  default     = "10.60.0.0/24"
}

variable "openclaw_ssh_source_ranges" {
  description = "Source ranges allowed to SSH into the OpenClaw VM."
  type        = list(string)
  default     = ["35.235.240.0/20"]
}

variable "openclaw_enable_external_ip" {
  description = "Whether to assign a public IP to the OpenClaw VM."
  type        = bool
  default     = true
}

variable "openclaw_app_token_secret_id" {
  description = "Secret Manager secret ID storing the Slack app token."
  type        = string
  default     = "openclaw-slack-app-token"
}

variable "openclaw_bot_token_secret_id" {
  description = "Secret Manager secret ID storing the Slack bot token."
  type        = string
  default     = "openclaw-slack-bot-token"
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
