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

## KML Notes
- KML coordinate order is `longitude,latitude[,alt]`.
## Related Documentation
- [development.md](./development.md): Development setup, GCS usage, and deployment.
