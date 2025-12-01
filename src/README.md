# Root OpenTofu Module

This is the entry point for the entire Brightcoast.ai infrastructure stack. It ties together the sub-modules (`projects`, `buildkite`, `prefect`) into a single cohesive state.

## Configuration (`main.tf`)
The root module is responsible for:
1.  **Provider Setup**: Configures the `google` and `google-beta` providers (defaulting to `us-central1`).
2.  **State Management**: Uses a GCS backend (`bc-prod-brightcoast-tfstate`) to store the state file.
3.  **Module Orchestration**:
    - Calls `module "projects"` to create the environment containers.
    - Calls `module "buildkite"` to set up the CI stack, passing in the service accounts created by `projects`.
    - Calls `module "prefect"` to deploy the application runtime, iterating over the project IDs returned by `projects`.

## Variables (`variables.tf`)
The root module exposes high-level variables that control the entire stack, such as:
- `organization_id` & `billing_account_id`: Core GCP organizational details.
- `platform_owner_account` & `core_admin_account`: Global admins.
- `buildkite_...`: Configuration for the CI stack (token secret IDs, repo slugs).

## Terraform Graph
1.  **Projects** are created first.
2.  **Buildkite** depends on `projects` (needs the target service accounts to allow impersonation).
3.  **Prefect** depends on `projects` (needs the project IDs to deploy resources into).

## Working with State
The state is stored remotely. To initialize the local environment:
```bash
uv run deploy.py --plan-only
```
(The script automatically handles `tofu init`).
