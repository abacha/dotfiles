# Nexus Recall — Constitution
# Nexus Recall — Rules & Conventions
> Project path: `~/projects/nexus-recall`

## Core Product Rules
1. Preserve retrieval quality and source traceability (search/chat responses must keep source snippets coherent).
2. Do not break ingest pipeline compatibility for `.json` and `.zip` ChatGPT exports.
3. Keep UI behavior clear for imported data vs local saved interactions (avoid confusing “recent” with DB history).
4. Maintain auth/CORS safety defaults; never silently weaken API protection.
5. Keep changes scoped; avoid mixing unrelated backend + UI refactors in one pass.

## Backend & Configuration Guardrails
- **Config over Hardcode:** Never hardcode prompts, keyword lists, or project domains in Python. Use `backend/src/app/resources/system_config.yaml`.
- **Pre-Storage Cleaning:** All message content must be sanitized via `cleaner.py` before being saved to the database to maintain index quality.
- **Selective Ingestion:** Avoid importing technical noise (e.g., `tool` role messages) that degrades the human-readable memory history.

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
# Nexus Recall — Development & Workflow
> Project path: `~/projects/nexus-recall`

## Critical Workflow Rule (User Preference)
- **Always ensure backend code is synced to the container**:
  - The `docker-compose.yml` should mount `./backend/src/app:/app/app` to allow live code updates.
  - If a change isn't reflected, check the mount point or force a rebuild.
- **After any code/config/documentation change in this project, always rebuild and restart the stack yourself**:
  - `docker compose up -d --build`
- Do not leave “please rebuild/restart” as a manual follow-up when the agent can do it.
- Only skip rebuild/restart when the user explicitly says to skip it.

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
- When backend config/settings (`system_config.yaml`) change, prefer running the backend tests inside the API container:
  ```
  docker compose exec api pytest backend/tests
  ```

## Operational script safety
- For backend operational scripts, prefer running them against the live container runtime DB, not the host-side `backend/data/app.db`.
- Example safe retag usage:
  ```bash
  cat backend/scripts/ops/retag.py | docker compose exec -T api python - --id <conversation_id>
  cat backend/scripts/ops/retag.py | docker compose exec -T api python - --all
  ```
- Only target the host DB intentionally, and only with an explicit override such as `FORCE_HOST_DB=1` when the script supports it.

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


# Project Overview & Domain Logic

# Nexus Recall — Overview
> Project path: `~/projects/nexus-recall`

## Scope
- **Purpose:** Private “ChatGPT with memory” over exported ChatGPT history.
- **Stack:**
  - **Backend:** FastAPI + SQLite (FTS5) + FAISS (HNSW) + PyYAML.
  - **Configuration:** Centralized in `backend/src/app/resources/system_config.yaml`.
  - **Web:** React + Vite + TypeScript + Lucide + react-virtuoso.
  - **Runtime:** Docker Compose (`api` + `web`).

## Ingestion Pipeline
The system processes data in three main stages: Ingest -> Clean -> Tag.

### 1. Ingest (`parse_export.py`)
- Supports `.zip` (ChatGPT Export) or raw `.json` (conversations.json).
- Extracts hierarchy (Conversations -> Messages).
- Standardizes roles (`user`, `assistant`, `system`). **Note:** `tool` role messages are ignored during ingest as they contain internal ChatGPT noise.

### 2. Clean (`cleaner.py`)
- **Sanitization before storage:** Every message passes through the cleaner before hitting the database.
- **Noise Removal:** Automatically strips technical JSON (IDs, width/height), voice metadada (audio_start_timestamp), and redundant system instructions.
- **Token Replacement:** Custom tokens like `\uE200product` are replaced with human-readable labels.
- **Durable Records:** Since cleaning happens during ingest, the database contains only readable text, improving search quality.

### 3. Tagging (`tagging.py`)
- **LLM-Based Classification:** Uses `gpt-4o-mini` to categorize conversations.
- **Smart Sampling:** Samples 5 messages from the beginning (Head) and 5 from the end (Tail) of a conversation to provide context for the classifier.
- **Dimensions:**
  - **Domain:** Primary project (coding, wellness, recipes, gaming, etc.).
  - **Frequency:** Occurrence pattern (recurring, one-off, long-running).
  - **Orthogonal:** Cross-cutting concerns (guide, tutorial, data-tracking).
- **Forced Overrides:** Rules in `system_config.yaml` can force domains based on keywords (e.g., "Ikariam" -> Gaming).

## Configuration & Parametrization
Most system behaviors are decoupled from code and live in `backend/src/app/resources/system_config.yaml`:
- List of allowed domains and tags.
- Regex and keywords for classification.
- Prompts for LLM tagging and reranking.
- Fallback strings for noise detection.

## Search & Retrieval
- **Hybrid Search:** Combines BM25 (SQLite FTS5) with Vector Search (FAISS + OpenAI/Gemini Embeddings).
- **Reranking:** Post-retrieval reranking via LLM to ensure the most relevant context is provided for the final answer.

## Environment & Data Rules
- **Live runtime DB:** When running via Docker Compose, the live SQLite DB used by the UI/API is `/app/data/app.db` inside the container, backed by the Docker volume `nexus_data`.
- **Host-side DB caution:** Do **not** assume `backend/data/app.db` on the host reflects the live runtime state. Host DB mutations may not affect the running app.
- **Vector Index:** Live runtime index is `/app/data/faiss.index` in the container volume.
- **HMR Support:** Frontend source is volume-mapped to the container in dev mode to allow Hot Module Replacement.
- **Port Mapping:** API runs on `:19080`, Web on `:15173`.

## Related Documentation
- [development.md](./development.md): Setup, build, and deployment workflows.
- [conventions.md](./conventions.md): Code style and pattern guidelines.
