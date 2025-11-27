# Vendored Module: Buildkite Elastic CI Stack for GCP

This directory contains a **modified copy** of the [buildkite-elastic-ci-stack-for-gcp](https://github.com/buildkite/terraform-buildkite-elastic-ci-stack-for-gcp) Terraform module.

## Why is this vendored?
We required custom logic to be injected into the agent startup process to support our specific tooling (`uv` and `bcai-cli`). The upstream module's inputs for startup scripts/metadata were insufficient for our "Agent Hook" injection strategy without modifying the internal `startup.sh` template.

## Modifications
- **File**: `modules/compute/templates/startup.sh`
- **Change**: Added logic to write a `pre-command` hook to `/etc/buildkite-agent/hooks/pre-command` that installs `uv` and `bcai-cli` for the `buildkite-agent` user.

## Upgrading
To upgrade this module:
1.  Clone the upstream repository.
2.  Diff the changes against this directory.
3.  Apply upstream updates carefully, preserving the custom `startup.sh` logic.