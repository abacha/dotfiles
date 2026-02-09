# AGENTS.md

## Working Agreement
- Never create a git commit without explicit user approval. If unsure, ask.
- When asked to run tests, run the minimal relevant suite and report failures with hypotheses.
- Do not run backend tests after frontend‑only changes unless explicitly requested.
- Prefer small, incremental changes; keep each change scoped to the current request.
- Always run targeted tests for the change, then run the full suite (including smoke tests) and the linter before committing.

## Current Architecture Notes
- Web UI: Flask in `app.py`, routes in `web/routes.py` and `web/api.py`, templates in `web/templates/`.
- Backend: `src/` contains analysis, simulation_core, services, and CLI (`src/main.py`).
- Storage: if `OUTPUT_GCS_BUCKET` is set, GCS is the **single source of truth** for outputs.
  - Outputs are uploaded to `gs://<bucket>/<prefix>/<sim_id>/...`.
  - Local output folders are removed after upload (except while batch aggregation is running).
  - `OUTPUT_GCS_PREFIX` defaults to `Output`.
  - `GOOGLE_APPLICATION_CREDENTIALS=/app/Resources/gcp-service-account.json` is used in deploy.
- Cache: when GCS is enabled, `/simulations` reads `simulation_inputs.json` from GCS and caches it locally under `Output/.cache_inputs/` (no TTL).

## Batch Processing
- Batch outputs include aggregated summaries and can generate additional derived files when needed.

## Deploy / GKE
- `scripts/update_app.sh`:
  - Ensures GCS bucket exists
  - Ensures IAM for node service account
  - Injects `OUTPUT_GCS_BUCKET` and `OUTPUT_GCS_PREFIX`
- Deployment uses RollingUpdate with readiness and liveness probes at `/healthz`.

## KML Notes
- KML coordinate order is `longitude,latitude[,alt]`.
- Supported geometries: Point and Polygon (centroid).

