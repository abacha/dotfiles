# AIOMA — Development & Deployment
> Project path: `~/projects/trag/AIOMA`

## Quick commands
- Rebuild both Docker images: `docker compose build` (changes to Python code or `config.ini` require this). `config.ini` is copied into the image—not volume-mounted—so config edits always need a rebuild.
- Run the web server locally: `docker compose up web -d` (serves `/api`, `/map.html`, `/viewer.html`, `/data` volume).
- Run the pipeline locally: `docker compose run --rm pipeline` (downloads from CDS, computes ensemble, renders PNGs/JSON).
- Alternative local dev (without Docker): `scripts/setup.sh`, `scripts/run_app.sh web`, `scripts/run_app.sh pipeline`, `pytest`.
- For pipeline jobs on GKE: `scripts/run_pipeline.sh` (set `BUILD=true` to rebuild & use new image).

## Testing
- Fastest smoke: `pytest tests/test_api.py` (uses synthetic NetCDFs, no CDS calls).
- Full suite: `pytest` (loads all unit/integration tests).
- Always run the relevant slice after touching API logic, downloads, or conversions.

## Deployment
- **Web service:** follow `scripts/update_app.sh` (build/push web image, grant IAM roles, ensure GCS bucket, apply `k8s/deployment.yaml`, watch rollout). Use `PATH=/opt/google-cloud-sdk/bin:$PATH scripts/update_app.sh` in this environment so `gcloud` resolves correctly.
- **Pipeline job:** use `scripts/run_pipeline.sh`; set `BUILD=true` to regenerate the pipeline image before triggering the job. On GKE the cronjob in `k8s/cronjob.yaml` runs monthly — edit PRs accordingly if changing schedule or volumes.
- **Initial deploy:** `scripts/deploy_gke.sh` (sets up clusters, services, ingress, CDN certs). Only rerun if cluster/infra changes.
