locals {
  prod_labels = merge(
    var.base_labels,
    {
      environment = "prod"
      cost_center = "prod"
    }
  )
}

resource "google_project" "prod" {
  name                = local.project_definitions["prod"].name
  project_id          = local.project_definitions["prod"].project_id
  org_id              = var.prod_folder_id == null ? var.organization_id : null
  folder_id           = var.prod_folder_id
  billing_account     = var.billing_account_id
  labels              = local.prod_labels
  auto_create_network = false

}

resource "google_project_service" "prod" {
  for_each = toset(local.base_services)

  project = google_project.prod.project_id
  service = each.key

  disable_on_destroy         = false
  disable_dependent_services = true
}

resource "google_project_iam_member" "prod_owner_members" {
  for_each = toset(local.prod_owner_members)

  project = google_project.prod.project_id
  role    = "roles/owner"
  member  = each.key
}

resource "google_project_iam_member" "prod_service_account_admins" {
  for_each = toset(local.prod_owner_members)

  project = google_project.prod.project_id
  role    = "roles/iam.serviceAccountAdmin"
  member  = each.key
}
