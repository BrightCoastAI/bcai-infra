variable "project_id" {
  description = "Target project for Prefect resources."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, prod)."
  type        = string
}

variable "region" {
  description = "Region for Cloud Run and Cloud SQL."
  type        = string
}

variable "labels" {
  description = "Labels to apply to Prefect resources."
  type        = map(string)
  default     = {}
}

variable "prefect_image" {
  description = "Container image to run Prefect server and worker (Prefect 3 recommended)."
  type        = string
  default     = "prefecthq/prefect:3-latest"
}

variable "cloud_run_cpu" {
  description = "vCPU allocation for the Prefect service."
  type        = string
  default     = "1"
}

variable "cloud_run_memory" {
  description = "Memory allocation for the Prefect service."
  type        = string
  default     = "2Gi"
}

variable "sql_tier" {
  description = "Cloud SQL machine tier."
  type        = string
  default     = "db-f1-micro"
}

variable "db_disk_size_gb" {
  description = "Disk size for the Prefect Cloud SQL instance."
  type        = number
  default     = 20
}

variable "min_instances" {
  description = "Minimum instances to keep Prefect service warm."
  type        = number
  default     = 1
}
