# Prefect (self-hosted)

This module provisions a self-hosted Prefect server/UI and a single Cloud Run worker per environment. It keeps costs low (1 min instance) while enabling Cloud Run job-based flow execution.

## What gets created
- Cloud SQL Postgres (small tier, auto-resizable) plus Secret Manager secret holding the connection URL.
- Prefect runtime service account with broad access (Editor + Cloud Run, Cloud SQL, Secret Manager, Artifact Registry).
- Artifact Registry repo (`prefect`) in each project for custom Prefect images.
- Cloud Run service for Prefect server/UI (minScale=1 to stay warm).
- Separate Cloud Run service for the Prefect Cloud Run worker (minScale=0 for on-demand).

## How it works
- The server container runs `prefect server start` on port 8080. IAM auth is required (`allAuthenticatedUsers` Cloud Run invoker) for UI/API.
- The worker container bootstraps the work pool if missing, then runs `prefect worker start --type cloud-run` pointing to the server URL.
- `prefect-gcp` is installed (baked in if you build the provided Dockerfile, otherwise installed at startup) to supply the Cloud Run worker type.
- Cloud SQL is connected via the Cloud SQL connector (`run.googleapis.com/cloudsql-instances` annotation); the DB URL is pulled from Secret Manager.

## Custom image (Prefect 3 + GCP)
- A Dockerfile is provided at `src/prefect/Dockerfile` (Prefect 3 + `prefect-gcp>=0.6.0`). Build and push to the per-project Artifact Registry repo (`prefect`) for faster starts and clearer provenance:
  ```bash
  REGION="australia-southeast1"
  PROJECT_ID="<your_project_id>"  # bc-dev-brightcoast or bc-prod-brightcoast
  REPO="prefect"
  IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/prefect:3"

  gcloud auth configure-docker "${REGION}-docker.pkg.dev"
  docker build -t "${IMAGE}" -f src/prefect/Dockerfile .
  docker push "${IMAGE}"
  ```
- Set `prefect_image` (module input) to the pushed image to avoid runtime `pip install` and keep the version pinned.

## Usage / follow-ups
- Register flows against the created work pool: `${environment}-cloud-run-pool`.
- Adjust the `prefect_image` input to point at your pushed image (recommended) or a pinned upstream tag.
- If you need more UI/worker capacity, increase `min_instances` and/or remove the maxScale cap in `src/prefect/main.tf`.
- Cloud Run IAM is set to `allAuthenticatedUsers` invoker; tighten to specific principals if preferred.
