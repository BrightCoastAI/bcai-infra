locals {
  dev_labels = merge(
    var.base_labels,
    {
      environment = "dev"
      cost_center = "dev"
    }
  )
}

resource "google_project" "dev" {
  name                = local.project_definitions["dev"].name
  project_id          = local.project_definitions["dev"].project_id
  org_id              = var.dev_folder_id == null ? var.organization_id : null
  folder_id           = var.dev_folder_id
  billing_account     = var.billing_account_id
  labels              = local.dev_labels
  auto_create_network = false

}

resource "google_project_service" "dev" {
  for_each = toset(local.base_services)

  project = google_project.dev.project_id
  service = each.key

  disable_on_destroy         = false
  disable_dependent_services = true
}

resource "google_project_iam_member" "dev_owner_members" {
  for_each = toset(local.dev_owner_members)

  project = google_project.dev.project_id
  role    = "roles/owner"
  member  = each.key
}

resource "google_project_iam_member" "dev_service_account_admins" {
  for_each = toset(local.dev_owner_members)

  project = google_project.dev.project_id
  role    = "roles/iam.serviceAccountAdmin"
  member  = each.key
}
