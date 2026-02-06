variable "project_id" {
  description = "Project ID to host the OpenClaw VM."
  type        = string
}

variable "region" {
  description = "Region for networking resources."
  type        = string
}

variable "zone" {
  description = "Zone for the OpenClaw VM."
  type        = string
}

variable "labels" {
  description = "Labels applied to OpenClaw resources."
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "Prefix used for OpenClaw resource names."
  type        = string
  default     = "openclaw"
}

variable "machine_type" {
  description = "Machine type for the OpenClaw VM."
  type        = string
  default     = "e2-small"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size (GB) for the OpenClaw VM."
  type        = number
  default     = 30
}

variable "subnet_cidr" {
  description = "CIDR block for the OpenClaw subnet."
  type        = string
  default     = "10.60.0.0/24"
}

variable "ssh_source_ranges" {
  description = "Source ranges allowed to SSH into the OpenClaw VM."
  type        = list(string)
  default     = ["35.235.240.0/20"]
}

variable "enable_external_ip" {
  description = "Whether to assign a public IP to the OpenClaw VM."
  type        = bool
  default     = true
}

variable "app_token_secret_id" {
  description = "Secret Manager secret ID storing the Slack app token (Socket Mode)."
  type        = string
  default     = "openclaw-slack-app-token"
}

variable "bot_token_secret_id" {
  description = "Secret Manager secret ID storing the Slack bot token."
  type        = string
  default     = "openclaw-slack-bot-token"
}

variable "boot_image" {
  description = "Source image for the OpenClaw VM."
  type        = string
  default     = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
}
