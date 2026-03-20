# Climate Risk Analysis — Constitution
# Climate Risk Analysis — Development & Deployment
> Project path: `~/projects/trag/climate-risk-analysis`

## Working Agreement
- Never create a git commit without explicit user approval.
- Run minimal relevant tests and report failures with hypotheses.
- Do not run backend tests after frontend‑only changes.
- Prefer small, incremental changes.
- Always run targeted tests, then full suite, then linter before committing.

## Deployment
- **Deploy:** `scripts/update_app.sh` rebuilds/pushes image and rollouts GKE.
- Deployment uses RollingUpdate with readiness/liveness probes at `/healthz`.

## Batch Processing
- Batch outputs include `aggregated_metrics.csv`, `simulations_summary.csv`, and `yield_index_by_year.csv`.

## Scripts (Purpose & Usage)
- `scripts/geocode_cidades.sh` — Geocode a CSV with a `CIDADE` header (Brazil only).
- `scripts/split_batch_csv.sh` — Split a large batch CSV into chunks.
- `scripts/run_batch_jobs_parallel.sh` — Run multiple batch chunks via Kubernetes jobs in parallel.


# Project Overview & Domain Logic

# Climate Risk Analysis — Overview & Architecture
> Project path: `~/projects/trag/climate-risk-analysis`

## Business Context (Plain English)
- Report evaluates **climate risk exposure** for a farm/crop/planting date.
- **Score de Risco Agro-Climático** (0–100 scale) summarizes historical risk.
- Highlights **critical drought/heat windows** and yield losses.

## Current Architecture Notes
- Web UI: Flask in `app.py`, routes in `web/routes.py`, `web/api.py`, templates in `web/templates/`.
- Backend: `src/` (analysis, simulation_core, services, CLI).
- Storage: GCS is **single source of truth** for outputs (`OUTPUT_GCS_BUCKET`).
- Cache: `/simulations` reads `simulation_inputs.json` from GCS and caches locally under `Output/.cache_inputs/`.
- **v1.0 Architecture Upgrade**: The system now uses an asynchronous queue architecture with PostgreSQL for job state and RabbitMQ for orchestration. See `tech_spec.md` in this directory for the full canonical implementation spec.

## KML Notes
- KML coordinate order is `longitude,latitude[,alt]`.
## Related Documentation
- [development.md](./development.md): Development setup, GCS usage, and deployment.
