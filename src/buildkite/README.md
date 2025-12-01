# Brightcoast.ai Buildkite CI Stack

This module deploys a **self-hosted Buildkite Agent stack** in a dedicated CI project (`bc-ci-brightcoast`). These agents are responsible for running CI/CD pipelines for Brightcoast applications, including deploying to the `dev` and `prod` environments.

## Architecture
- **Dedicated Project**: All CI resources live in `bc-ci-brightcoast` to isolate build permissions from production data.
- **Elastic Stack**: Uses a Managed Instance Group (MIG) that autoscales based on the Buildkite job queue depth.
- **Service Account Impersonation**: The agents run as `elastic-ci-agent`. They are granted `roles/iam.serviceAccountTokenCreator` on the target environment service accounts (e.g., `env-dev-sa@bc-dev...`) to deploy resources.

## Vendored Module & Custom Hooks
**⚠️ Important:** This module uses a **vendored copy** of the upstream `buildkite-elastic-ci-stack-for-gcp` module, located at `src/vendor/buildkite_stack`.

### Why Vendoring?
The upstream module did not natively support injecting the custom logic we required for our agent startup process (specifically, a clean way to install per-job hooks without baking a custom image). We vendored the module to modify the `startup.sh` template directly.

### Customizations
The `src/vendor/buildkite_stack/modules/compute/templates/startup.sh` file has been modified to:
1.  **Create a `pre-command` Hook**: Instead of installing tools globally, the startup script writes a script to `/etc/buildkite-agent/hooks/pre-command`.
2.  **Hook Logic**: This hook runs before every job and:
    - Checks if `uv` (Python package manager) is installed for the `buildkite-agent` user.
    - Checks if `bcai-cli` is installed.
    - Installs or updates them using `uv tool install` if missing.
    - Ensures `PATH` is correctly configured.

This approach ensures that:
- Tools are installed in the user context, not root.
- Tool updates can be applied by simply restarting the pipeline (triggering the hook again), rather than replacing the VM.

## Usage
To deploy or update the stack:
```bash
uv run deploy.py --auto-approve -- -target=module.buildkite
```

## Key Variables
- `buildkite_agent_token_secret_id`: The Secret Manager secret containing the agent token.
- `buildkite_queue`: The queue these agents listen to (default: `default`).
- `ssh_key_secret_id`: (Native feature) The Secret Manager secret containing the SSH private key for git cloning.

## Maintenance
If you need to update the underlying Buildkite infrastructure code:
1.  Check the [upstream repository](https://github.com/buildkite/terraform-buildkite-elastic-ci-stack-for-gcp) for changes.
2.  Manually apply relevant changes to `src/vendor/buildkite_stack`.
3.  **Do not** revert the changes to `modules/compute/templates/startup.sh` unless you have moved the hook logic to a Packer image.
