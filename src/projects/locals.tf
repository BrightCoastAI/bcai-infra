locals {
  base_services = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "servicemanagement.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "oslogin.googleapis.com",
    "storage.googleapis.com",
    "run.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudkms.googleapis.com",
    # Google Workspace APIs used by n8n nodes
    "admin.googleapis.com",
    "chat.googleapis.com",
    "docs.googleapis.com",
    "drive.googleapis.com",
    "forms.googleapis.com",
    "gmail.googleapis.com",
    "people.googleapis.com",
    "sheets.googleapis.com",
    "slides.googleapis.com",
    "tasks.googleapis.com",
  ]

  project_definitions = {
    dev = {
      name        = "bc-dev"
      project_id  = "bc-dev-brightcoast"
      environment = "dev"
    }
    prod = {
      name        = "bc-prod"
      project_id  = "bc-prod-brightcoast"
      environment = "prod"
    }
  }

  dev_owner_members = distinct(
    compact(
      concat(
        [
          "user:${var.core_admin_account}",
          "user:${var.platform_owner_account}",
        ],
        var.dev_additional_admins,
      )
    )
  )

  prod_owner_members = distinct(
    compact(
      concat(
        [
          "user:${var.core_admin_account}",
          "user:${var.platform_owner_account}",
        ],
        var.prod_additional_admins,
      )
    )
  )
}
