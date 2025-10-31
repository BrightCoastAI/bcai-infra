# Brightcoast.ai GCP Foundation

This repository uses OpenTofu (an open-source Terraform alternative) to stand up the two Brightcoast.ai Google Cloud projects (`bc-dev-brightcoast` and `bc-prod-brightcoast`). It enables the core APIs those projects need on day one and makes sure the Brightcoast platform owners have the right IAM roles.

## What is OpenTofu?

OpenTofu is a drop-in replacement for Terraform that is fully open-source and community-driven. It was created as a fork of Terraform 1.5.x after HashiCorp changed Terraform's license to the Business Source License (BUSL). OpenTofu maintains 100% compatibility with Terraform configurations and state files, so existing Terraform code works without modification. The `tofu` command works identically to the `terraform` command.

## What OpenTofu Builds
- Creates the `bc-dev` and `bc-prod` projects and links them to the Brightcoast billing account.
- Enables baseline Google Cloud services (IAM, Service Usage, Logging, Monitoring, Cloud KMS, and more) plus all Google Workspace APIs n8n nodes require.
- Grants `core@brightcoast.ai` and `ben@brightcoast.ai` project ownership plus service account admin access, with room for additional admins in each environment.
- Exposes OpenTofu outputs with project IDs and project numbers for downstream modules.

## Repository Layout
- `src/` – root OpenTofu module. The nested `projects/` module actually creates and configures the dev/prod projects.
- `src/terraform.tfvars` – example values for organization and billing IDs; extend this file with any extra admins.
- `deploy.py` – friendly wrapper that runs `tofu init`, `plan`, and `apply` with nice output.
- `pyproject.toml` / `uv.lock` – ensure the `deploy.py` script installs with `uv run`.
- `docs/operations.md` – step-by-step how-to guide for common tasks (adding IAM admins, enabling new services, etc.).

## Prerequisites
- OpenTofu `1.10.x` (or compatible version) and the Google Cloud SDK installed. Using [`uv`](https://docs.astral.sh/uv/) keeps the Python wrapper isolated.
- Brightcoast.ai organization ID and a billing account that the deploying user can attach to projects.
- Access to `gs://bc-prod-brightcoast-tfstate/terraform/root`, the remote state bucket defined in `src/backend.tf`.
- Organization-level permissions (`resourcemanager.projects.create`, billing admin, storage access to the state bucket).

## Installation

### macOS (via Homebrew)
```bash
brew install opentofu
brew install google-cloud-sdk
```

### Linux/Other Platforms
See the [official OpenTofu installation guide](https://opentofu.org/docs/intro/install/) for instructions on other platforms.

### Verify Installation
```bash
tofu version  # Should show OpenTofu v1.10.x or later
```

## Deploy OpenTofu
1. **Install tooling** (see Installation section above)
2. **Authenticate with Google Cloud**
   ```bash
   gcloud auth login --account=core@brightcoast.ai
   gcloud auth application-default login --account=core@brightcoast.ai
   ```
   If `GOOGLE_CLOUD_QUOTA_PROJECT` is required for admin APIs, set it to `bc-prod-brightcoast` before running OpenTofu.
3. **Run the wrapper**
   ```bash
   uv run deploy.py --plan-only      # tofu init + plan
   uv run deploy.py --auto-approve   # tofu apply
   ```
   Pass through extra OpenTofu arguments after `--`, for example `uv run deploy.py --plan-only -- -target=google_project.dev`.

## Remote State
OpenTofu stores state in the `bc-prod-brightcoast-tfstate` bucket under `terraform/root`. If initialization fails with permission errors, double-check the deploying account has read/write access to that bucket. To inspect state objects:

```bash
gcloud storage ls gs://bc-prod-brightcoast-tfstate/terraform/root
```

## Troubleshooting
- `PERMISSION_DENIED`: the user likely lacks storage access to the remote state bucket or required organization permissions.
- API enablement failures: confirm the billing account is linked to the organization and the deploying user is a billing admin.
- Backend changes: delete any local `.terraform` directories before re-running OpenTofu if you edit the backend configuration.

## Common Tasks
- **Add new project admins**, **enable extra APIs**, and other day-two operations are documented in `docs/operations.md`.
- For the fastest way to inspect IAM policies, run:
  ```bash
  gcloud projects get-iam-policy bc-dev-brightcoast
  gcloud projects get-iam-policy bc-prod-brightcoast
  ```

Feel free to extend this foundation with networking, logging, SCC, or CI automation by layering additional OpenTofu modules once these baseline projects are in place.
