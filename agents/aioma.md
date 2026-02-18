# AIOMA — Agent Instructions

## Project Overview
Seasonal climate forecast ensemble pipeline. Downloads data from 8+ global forecast centers via Copernicus CDS API, computes a multi-model ensemble mean, and generates visualizations + JSON export for an interactive map.

## Project Structure
```
AIOMA/
  aioma/               # Python package
    cli.py             # Entry point (python -m aioma.cli)
    config.py          # Loads config.ini into dataclasses
    models.py          # Dataclasses (CenterConfig, PipelineConfig, etc.)
    download.py        # CDS API download (parallel, with retries)
    ensemble.py        # Load, interpolate, convert, average, export
    conversions.py     # Unit conversions (cumulative->daily, K->C, wind)
    visualize.py       # Spatial maps + city time series PNGs
    export.py          # JSON export for map.html
    pipeline.py        # Orchestrator (download -> ensemble -> viz -> export)
  config.ini           # All tunables (centers, grid, variables, cities)
  Dockerfile           # Python 3.11-slim + system deps
  docker-compose.yml   # Single service, mounts ./data as /app/data
  map.html             # Interactive Leaflet map (loads data/ensemble_data.json)
  viewer.html          # Static PNG viewer (loads data/*.png)
  tests/               # pytest suite
  data/                # Generated outputs (volume-mounted, gitignored)
```

## Build & Run
- Everything runs inside Docker. The image bakes in the code and `config.ini`.
- **Run pipeline**: `docker compose run --rm aioma`
- **Rebuild after code/config changes**: `docker compose build` (or `--no-cache` if cached layers mask changes)
- **Run a shell inside the container**: `docker compose run --rm aioma bash`
- **Data files are root-owned** (created by Docker). To rename/delete data files, do it inside Docker: `docker compose run --rm aioma bash -c '...'`
- `config.ini` is COPIED into the image at build time, NOT volume-mounted. Any config change requires a rebuild.

## Testing
- Run tests locally (not in Docker): `pytest tests/`
- Run a single test file: `pytest tests/test_ensemble.py`
- Tests use synthetic xarray datasets; no CDS API calls.
- Always run relevant tests after making changes. Run the full suite before committing.

## Coding Style
- Python 3.11+, f-strings, type hints on function signatures.
- All code and variable names in English. README and user-facing docs in Brazilian Portuguese (pt-BR).
- Log messages in English.
- No blanket `warnings.filterwarnings('ignore')`.
- Prefer small functions with single responsibility (see ensemble.py for the pattern).
- Dataclasses in `models.py` for configuration; avoid dicts for structured data.
- All magic numbers belong in `config.ini`, not in Python files.

## Key Conventions
- File naming for data: `{center}_daily_{year}_{month}.nc` (per-center), `ensemble_daily_{YYYYMMDD}_{YYYYMMDD}.nc` (output).
- Centers are configured in `config.ini [centers]`. Comment with `#` to disable a center.
- Conversions (cumulative->daily, K->C) run **per-model before** ensemble averaging (this is meteorologically correct and was a critical fix — L1).
- Grid interpolation runs on **all models** that differ from the target grid, not just specific ones (L2 fix).
- The `number` dimension is used for member averaging for most centers; NCEP uses `forecast_reference_time`.

## Environment
- `COPERNICUS_API_KEY` in `.env` (mounted via docker-compose)
- `CDS_MAX_WORKERS` env var overrides `config.ini` max_workers (default: 3)
- CDS API can be slow (hours). Some centers (e.g., JMA) may timeout or be temporarily unavailable — comment them out in config.ini if blocking.

## Commit Style
- Sentence-case subject, imperative mood.
- Body explains "why" not "what".
- Keep commits focused; don't mix unrelated changes.

## Known Issues / Notes
- JMA is currently commented out in config.ini (CDS download was timing out).
- `xarray` emits `FutureWarning` about `Dataset.dims` return type — cosmetic, will resolve in a future xarray version.
- The HTML files (map.html, viewer.html) are tracked in git. They need an HTTP server to work (`python3 -m http.server`) due to `fetch()` calls.
- See `TODO.md` for the full roadmap (Phase 1 refactor is mostly done; Phase 2 web interface and Phase 3 cloud deployment are next).
