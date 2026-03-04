# AIOMA — Agent Instructions
> Project path: `~/projects/trag/AIOMA`

## Project Overview
Seasonal climate forecast ensemble pipeline. Downloads data from 8+ global forecast centers via Copernicus CDS API, computes a multi-model ensemble mean, and generates visualizations + JSON export for an interactive map.

## Project structure
```
AIOMA/
  aioma/               # Python package & FastAPI app
  Dockerfile           # Multi-stage: base → pipeline → web
  docker-compose.yml   # Services: pipeline (batch) + web (API + static UI)
  data/                # Shared volume (gitignored) to hold netCDF, PNGs, JSON
  scripts/             # Helpers (setup, run_app, deploy/update pipeline/web)
  k8s/                 # Manifests for GKE deployment + pipeline job/cron
  README.md            # High-level user guide (map, API contract, docs)
  DEVELOPMENT.md       # Architecture, config knobs, run & deploy recipes
```

Read both `README.md` and `DEVELOPMENT.md` before touching the project—those are the source of truth for run/deploy flows, networking, and API expectations. Keep them in sync with any functional change you make.

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

## API contract (updated)
- `/health` — simple health check.
- `/api/status` and `/api/forecast/latest` — return metadata about the latest `ensemble_daily_*.nc` (variables, dates, grid bounds, filename).
- `/api/forecast/data` — single entry point now:
  - If `date` (and optionally repeated `var`) your response includes `date`, `variables`, `lats`, `lons`, and `data[var]` as 2D arrays (rounded values, `null` for NaN).
  - If `lat`+`lon` (without `date`) you get `lat`, `lon`, `dates`, `variables`, and `data[var]` as time series for the nearest grid point (can request a single `var` or multiple via repeated query parameters).
  - Invalid variable names or out-of-range dates return 400; missing data (before pipeline runs) returns 503.
- `/docs` exposes the swagger UI (useful for quick cURL checks).
- `/api/forecast/timeseries` and `/api/forecast/spatial-mean` have been retired—everything routes through `/api/forecast/data` now.

## Deployment
- **Web service:** follow `scripts/update_app.sh` (build/push web image, grant IAM roles, ensure GCS bucket, apply `k8s/deployment.yaml`, watch rollout). Use `PATH=/opt/google-cloud-sdk/bin:$PATH scripts/update_app.sh` in this environment so `gcloud` resolves correctly.
- **Pipeline job:** use `scripts/run_pipeline.sh`; set `BUILD=true` to regenerate the pipeline image before triggering the job. On GKE the cronjob in `k8s/cronjob.yaml` runs monthly — edit PRs accordingly if changing schedule or volumes.
- **Initial deploy:** `scripts/deploy_gke.sh` (sets up clusters, services, ingress, CDN certs). Only rerun if cluster/infra changes.

## Environment
- `CDSAPI_KEY` (and optional `CDSAPI_URL`/`CDS_MAX_WORKERS`) go in `.env` for local Docker runs; the pipeline job expects the same variables via Kubernetes secrets.
- `DATA_DIR` and `APP_DIR` default to `/app/data` and `/app` inside containers—only override if you change the Docker/K8s manifests.

## Documentation & consistency
- Whenever you change API outputs, README and DEVELOPMENT must reflect the new contract (endpoints, parameters, response shape). The UI (`map-logic.js`, `gallery-logic.js`) relies on the documented JSON shape—update tests to match if you tweak data structures.
- Keep `map.html`/`viewer.html` consistent with the frontend JS; they are real assets tracked in git and break easily if JS expects different selectors.

## Notes
- Downloads happen from `seasonal-original-single-levels`; converting dewpoint or other derived fields should happen in `aioma/conversions.py` or `ensemble.py` before the ensemble is saved.
- Generated assets (PNG/JSON/NetCDF) live in `data/` and are read-only for the web container; pipeline writes to them.
- If modifying server code, remember the FastAPI app caches the latest NetCDF via `ForecastDataManager`—touching the file on disk (even with the same name) forces it to reload.
- Use pt-br messaging in user-facing docs; keep code/logs in English per existing conventions.