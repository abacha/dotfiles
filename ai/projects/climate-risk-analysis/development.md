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
