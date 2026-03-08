# Nexus Recall — Overview
> Project path: `~/projects/nexus-recall`

## Scope
- Purpose: Private “ChatGPT with memory” over exported ChatGPT history.
- Stack:
  - Backend: FastAPI + SQLite (FTS5) + FAISS
  - Web: React + Vite + TypeScript
  - Runtime: Docker Compose (`api` + `web`)

## Project Structure Hotspots
- Backend API entrypoint: `backend/src/app/main.py`
- Ingest logic: `backend/src/app/ingest/`
- Retrieval/ranking: `backend/src/app/retrieval/`
- Schema/DB bootstrap: `backend/src/app/schema.sql`, `backend/src/app/db.py`
- Web app: `web/src/ui/App.tsx`, `web/src/api.ts`, `web/src/ui/app.css`

## Environment & Data Rules
- Main user DB path (local/dev): `backend/data/app-user.db`
- **Docker Volume Data:** The running app uses a Docker named volume (`nexus_data`), NOT the host `backend/data/app.db`.
  - **Migration Scripts:** MUST be run inside the container to target the correct database.
  - Example: `docker cp script.py api:/app/ && docker exec api python script.py`
- FAISS index path: `backend/data/faiss.index`
- Keep DB/index persistence behavior intact when editing compose or settings.
- For local debugging, verify API/Web URLs match README defaults (API `:18080`, Web `:15173`).
- Keep in sync with the `.env` / `.env.example` pair whenever you revise backend or frontend settings.
- When you tweak CORS origins (e.g., to cover Vite on 5173) or other environment variables, document the change here, update `.env.example`, and note why so future agents can safely rebuild.

## Related Documentation
- [development.md](./development.md): Setup, build, and deployment workflows.
- [conventions.md](./conventions.md): Code style, project structure, and pattern guidelines.
