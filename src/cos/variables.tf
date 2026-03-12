variable "project_id" {
  description = "Target GCP project for COS resources."
  type        = string
}

variable "environment" {
  description = "Environment name (dev or prod)."
  type        = string
}

variable "region" {
  description = "Region for Cloud Run and Cloud SQL."
  type        = string
}

variable "labels" {
  description = "Labels to apply to COS resources."
  type        = map(string)
  default     = {}
}

# ── Profile / secrets ────────────────────────────────────────────────────

variable "cos_profile" {
  description = "COS profile name. Also the secret-name prefix in Secret Manager (e.g. 'dev', 'adam')."
  type        = string
}

# ── Container ────────────────────────────────────────────────────────────

variable "cos_image" {
  description = "Container image for the COS service."
  type        = string
  default     = "python:3.11-slim"
}

variable "cloud_run_cpu" {
  description = "vCPU allocation for the COS Cloud Run service."
  type        = string
  default     = "1"
}

variable "cloud_run_memory" {
  description = "Memory allocation for the COS Cloud Run service."
  type        = string
  default     = "1Gi"
}

variable "min_instances" {
  description = "Minimum Cloud Run instances (1 = always-on for Telegram polling)."
  type        = number
  default     = 1
}

# ── Cloud SQL ────────────────────────────────────────────────────────────

variable "sql_tier" {
  description = "Cloud SQL machine tier."
  type        = string
  default     = "db-f1-micro"
}

variable "db_disk_size_gb" {
  description = "Disk size (GB) for the COS Cloud SQL instance."
  type        = number
  default     = 10
}
