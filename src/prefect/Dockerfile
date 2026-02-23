# Prefect 3 runtime image with GCP extras baked in.
FROM prefecthq/prefect:3-latest

# Install GCP worker extras so Cloud Run worker is available without runtime pip install.
RUN pip install --no-cache-dir "prefect-gcp>=0.6.0" "httpx"

# Prefect listens on 8080 by default.
EXPOSE 8080
