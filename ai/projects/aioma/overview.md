# AIOMA — Overview & Structure
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

## Related Documentation
- [development.md](./development.md): Architecture, setup, run & deploy recipes.
- [api.md](./api.md): Detailed API contracts and endpoint documentation.

## Environment
- `CDSAPI_KEY` (and optional `CDSAPI_URL`/`CDS_MAX_WORKERS`) go in `.env` for local Docker runs; the pipeline job expects the same variables via Kubernetes secrets.
- `DATA_DIR` and `APP_DIR` default to `/app/data` and `/app` inside containers—only override if you change the Docker/K8s manifests.

## Notes
- Downloads happen from `seasonal-original-single-levels`; converting dewpoint or other derived fields should happen in `aioma/conversions.py` or `ensemble.py` before the ensemble is saved.
- Generated assets (PNG/JSON/NetCDF) live in `data/` and are read-only for the web container; pipeline writes to them.
- If modifying server code, remember the FastAPI app caches the latest NetCDF via `ForecastDataManager`—touching the file on disk (even with the same name) forces it to reload.
- Use pt-br messaging in user-facing docs; keep code/logs in English per existing conventions.
