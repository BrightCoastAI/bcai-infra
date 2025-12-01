provider "google" {
  region = var.default_region
}

provider "google-beta" {
  region = var.default_region
}

locals {
  base_labels = {
    owner = "platform"
    org   = "brightcoast"
  }
}

module "projects" {
  source = "./projects"

  organization_id        = var.organization_id
  billing_account_id     = var.billing_account_id
  dev_folder_id          = var.dev_project_folder_id
  prod_folder_id         = var.prod_project_folder_id
  base_labels            = local.base_labels
  platform_owner_account = var.platform_owner_account
  core_admin_account     = var.core_admin_account
  dev_additional_admins  = var.dev_additional_admins
  prod_additional_admins = var.prod_additional_admins
}

module "buildkite" {
  source = "./buildkite"

  organization_id        = var.organization_id
  billing_account_id     = var.billing_account_id
  folder_id              = var.ci_project_folder_id
  project_id             = var.buildkite_project_id
  project_name           = var.buildkite_project_name
  region                 = var.default_region
  base_labels            = local.base_labels
  core_admin_account     = var.core_admin_account
  platform_owner_account = var.platform_owner_account
  additional_admins      = var.ci_additional_admins

  buildkite_organization_slug    = var.buildkite_organization_slug
  stack_name                     = var.buildkite_stack_name
  buildkite_queue                = var.buildkite_queue
  agent_token_secret_id          = var.buildkite_agent_token_secret_id
  source_agent_secret_project_id = var.buildkite_source_secret_project_id
  source_agent_secret_name       = var.buildkite_source_agent_secret_name
  seed_agent_secret              = var.buildkite_seed_agent_secret
  target_service_accounts        = module.projects.environment_service_accounts
}

module "prefect" {
  source = "./prefect"

  for_each = module.projects.project_ids

  project_id  = each.value
  environment = each.key
  region      = var.default_region
  labels = merge(
    local.base_labels,
    {
      environment = each.key
      cost_center = each.key
    }
  )
}

resource "google_project_iam_member" "ci_admin_access" {
  for_each = module.projects.project_ids

  project = each.value
  role    = "roles/owner"
  member  = "serviceAccount:${module.buildkite.agent_service_account_email}"
}
