variable "organization_id" {
  description = "Organization ID for assigning the project parent."
  type        = string
}

variable "billing_account_id" {
  description = "Billing account ID to link to each project."
  type        = string
}

variable "dev_folder_id" {
  description = "Optional folder ID for the development project."
  type        = string
  default     = null
}

variable "prod_folder_id" {
  description = "Optional folder ID for the production project."
  type        = string
  default     = null
}

variable "base_labels" {
  description = "Common labels applied to all projects."
  type        = map(string)
  default     = {}
}

variable "platform_owner_account" {
  description = "Email for the primary platform owner."
  type        = string
}

variable "core_admin_account" {
  description = "Email for the core admin."
  type        = string
}

variable "dev_additional_admins" {
  description = "Additional IAM member strings to grant owner access in the dev project."
  type        = list(string)
  default     = []
}

variable "prod_additional_admins" {
  description = "Additional IAM member strings to grant owner access in the prod project."
  type        = list(string)
  default     = []
}
