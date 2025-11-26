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
  description = "Region for regional resources (NAT, subnet)."
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

variable "target_service_accounts" {
  description = "Map of environment name to service account email that Buildkite agents can impersonate."
  type        = map(string)
  default     = {}
}

variable "network_name" {
  description = "Name for the Buildkite VPC network."
  type        = string
  default     = "buildkite-ci"
}

variable "subnet_cidr" {
  description = "CIDR range for the Buildkite subnet."
  type        = string
  default     = "10.20.0.0/24"
}
