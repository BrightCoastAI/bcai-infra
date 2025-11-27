# Brightcoast.ai Environment Projects

This module creates the fundamental Google Cloud Projects for Brightcoast.ai environments (`dev` and `prod`). It establishes the baseline security, IAM, and API configuration required for all downstream infrastructure.

## What this Module Builds
- **GCP Projects**:
  - `bc-dev-brightcoast`: The development environment.
  - `bc-prod-brightcoast`: The production environment.
- **Baseline Configuration**:
  - Links projects to the Brightcoast billing account.
  - Enables a standard set of Google Cloud APIs (IAM, Compute, Run, Secret Manager, etc.).
- **IAM & Access**:
  - Grants project ownership to platform owners (`core@`, `ben@`).
  - Configures "Environment Service Accounts" (`env-dev-sa`, `env-prod-sa`) used by CI/CD to deploy into these projects.
  - Sets up additional admins via variables.
- **Outputs**: Exports project IDs, numbers, and service account emails for use by the `buildkite` and `prefect` modules.

## Key Variables
- `organization_id`: The Google Cloud Organization ID.
- `billing_account_id`: The Billing Account ID to attach.
- `dev_project_folder_id` / `prod_project_folder_id`: (Optional) Folders to place the projects in.
- `platform_owner_account` / `core_admin_account`: The primary human admins.
- `dev_additional_admins` / `prod_additional_admins`: Lists of extra users to grant access to.

## Outputs
- `project_ids`: Map of environment name to Project ID.
- `project_numbers`: Map of environment name to Project Number.
- `environment_service_accounts`: Map of environment name to the Service Account email that has admin rights in that project.
