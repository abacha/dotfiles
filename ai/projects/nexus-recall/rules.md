# nexus-recall — Agent Instructions
> Project path: `~/projects/nexus-recall`

## Scope
- Project: `~/projects/nexus-recall`
- Purpose: Private “ChatGPT with memory” over exported ChatGPT history.
- Stack:
  - Backend: FastAPI + SQLite (FTS5) + FAISS
  - Web: React + Vite + TypeScript
  - Runtime: Docker Compose (`api` + `web`)

## Core Product Rules
1. Preserve retrieval quality and source traceability (search/chat responses must keep source snippets coherent).
2. Do not break ingest pipeline compatibility for `.json` and `.zip` ChatGPT exports.
3. Keep UI behavior clear for imported data vs local saved interactions (avoid confusing “recent” with DB history).
4. Maintain auth/CORS safety defaults; never silently weaken API protection.
5. Keep changes scoped; avoid mixing unrelated backend + UI refactors in one pass.

## Critical Workflow Rule (User Preference)
- **After any code/config/documentation change in this project, always rebuild and restart the stack yourself**:
  - `docker compose up -d --build`
- Do not leave “please rebuild/restart” as a manual follow-up when the agent can do it.
- Only skip rebuild/restart when the user explicitly says to skip it.

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

## Required Checks Before Finishing
### Backend
- Run targeted tests for touched backend areas:
  - `cd backend && python -m pytest tests/test_api.py`
- Run full backend tests when backend surface area is broad:
  - `cd backend && python -m pytest`

### Web
- Always run lint on web changes:
  - `cd web && npm run lint`
- Run tests when UI behavior/components are changed:
  - `cd web && npm test`
- Build for integration-sensitive UI changes:
  - `cd web && npm run build`

### Runtime validation
- For every change in this project, run:
  - `docker compose up -d --build`
- Confirm containers are healthy before handoff.
- When backend config/settings change, prefer running the backend tests inside the API container:
  ```
  docker compose exec api pytest backend/tests
  ```
  This ensures the Docker environment mirrors production dependencies (FastAPI, FAISS, OpenAI client, etc.).

## API Change Guardrails
- Keep endpoint behavior explicit and backward compatible when possible.
- For new endpoints:
  - add or update tests in `backend/tests/`
  - include pagination/limit constraints for list endpoints
  - keep auth dependency consistent with existing protected routes
- Avoid expensive unbounded queries; default to sensible `limit/offset` patterns.

## UI Change Guardrails
- Keep dark theme consistency and responsive behavior.
- Prefer additive UI (new tab/panel/filter) over replacing existing user flows unless requested.
- Persist only lightweight UI state in localStorage; avoid storing large payloads client-side.

## Definition of Done
- Relevant backend/web checks pass.
- Stack rebuilt + restarted by agent for every change (unless user explicitly waived it).
- Feature is manually validated in UI/API path touched.
- Final report includes:
  - changed files
  - commands run
  - test/lint/build results
  - any known limitations/risks

## Commit/PR Hygiene
- Keep commits objective-focused (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`).
- Document why the change exists, not only what changed.
- Do not commit or push unless explicitly requested.
