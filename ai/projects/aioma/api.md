# AIOMA — API & Documentation
> Project path: `~/projects/trag/AIOMA`

## API contract (updated)
- `/health` — simple health check.
- `/api/status` and `/api/forecast/latest` — return metadata about the latest `ensemble_daily_*.nc` (variables, dates, grid bounds, filename).
- `/api/forecast/data` — single entry point now:
  - If `date` (and optionally repeated `var`) your response includes `date`, `variables`, `lats`, `lons`, and `data[var]` as 2D arrays (rounded values, `null` for NaN).
  - If `lat`+`lon` (without `date`) you get `lat`, `lon`, `dates`, `variables`, and `data[var]` as time series for the nearest grid point (can request a single `var` or multiple via repeated query parameters).
  - Invalid variable names or out-of-range dates return 400; missing data (before pipeline runs) returns 503.
- `/docs` exposes the swagger UI (useful for quick cURL checks).
- `/api/forecast/timeseries` and `/api/forecast/spatial-mean` have been retired—everything routes through `/api/forecast/data` now.

## Documentation & consistency
- Whenever you change API outputs, README and DEVELOPMENT must reflect the new contract (endpoints, parameters, response shape). The UI (`map-logic.js`, `gallery-logic.js`) relies on the documented JSON shape—update tests to match if you tweak data structures.
- Keep `map.html`/`viewer.html` consistent with the frontend JS; they are real assets tracked in git and break easily if JS expects different selectors.
