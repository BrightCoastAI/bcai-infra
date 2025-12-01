# Brightcoast.ai Infrastructure

This repository defines the Infrastructure-as-Code (IaC) for Brightcoast.ai using **OpenTofu** on Google Cloud Platform. It manages the core project structure, CI/CD pipeline infrastructure (Buildkite), and application runtime environments (Prefect/Cloud Run).

## Repository Structure

- **`src/`**: The root OpenTofu module. Orchestrates the entire stack.
  - **`projects/`**: Creates the `dev` and `prod` GCP projects and base IAM.
  - **`buildkite/`**: Deploys the self-hosted CI agents in a dedicated `ci` project.
  - **`prefect/`**: Deploys Prefect Server and Workers in `dev` and `prod`.
  - **`vendor/`**: Contains locally modified (vendored) modules (e.g., Buildkite).
- **`deploy.py`**: A Python wrapper script for running OpenTofu commands safely and consistently.

## Key Components

### 1. Project Factory (`src/projects`)
Creates the foundational `bc-dev-brightcoast` and `bc-prod-brightcoast` projects. It sets up:
- Billing association.
- Core API enablement.
- Environment Service Accounts (`env-dev-sa`, `env-prod-sa`) used by CI to deploy code.

### 2. CI/CD (`src/buildkite`)
Deploys an autoscaling fleet of Buildkite Agents in `bc-ci-brightcoast`.
- **Customization**: The agents use a custom `pre-command` hook (injected via a vendored module) to automatically install `uv` and the `bcai-cli` tool for every job.
- **Security**: Agents authenticate via Google Secret Manager and use Impersonation to deploy to target environments.

### 3. Orchestration (`src/prefect`)
Deploys a self-hosted Prefect 3 server and Cloud Run workers.
- **Server**: A Cloud Run service hosting the Prefect UI and API.
- **Worker**: A Cloud Run service that polls for flow runs and executes them as Cloud Run Jobs.

## Getting Started

### Prerequisites
- **OpenTofu** (`tofu`) installed.
- **uv** (Python package manager) installed.
- **Google Cloud SDK** (`gcloud`) installed and authenticated.

### Installation
1.  **Install `uv` and dependencies**:
    ```bash
    curl -LsSf https://astral.sh/uv/install.sh | sh
    uv sync
    ```
2.  **Authenticate**:
    ```bash
    gcloud auth login
    gcloud auth application-default login
    ```

### Deployment
We use `deploy.py` to manage OpenTofu operations. This script ensures the correct backend configuration and handles arguments.

**Plan all changes:**
```bash
uv run deploy.py --plan-only
```

**Apply all changes:**
```bash
uv run deploy.py --auto-approve
```

**Target a specific module (e.g., Buildkite):**
```bash
uv run deploy.py --auto-approve -- -target=module.buildkite
```

## Documentation
- [Project Setup Details](src/projects/README.md)
- [Buildkite Stack & Vendoring](src/buildkite/README.md)
- [Prefect Setup](src/prefect/README.md)