# Nexus Recall — Agent Guide
> Project path: `~/projects/nexus-recall`

## Project

Private single-user "ChatGPT with memory" system. Hybrid search (FTS5 + FAISS) over
ingested ChatGPT exports, WhatsApp chats, coding agent sessions (Claude Code, Codex, Gemini CLI, OpenClaw), and local files.
LLM-powered answers with multi-provider fallback (OpenAI, Anthropic, Gemini).

Stack: FastAPI, SQLite (WAL mode + FTS5), FAISS (HNSW), Pydantic v2.
Runtime: Docker Compose. Single container, single user, single SQLite database.

---

## Commands

| Task | Command |
|------|---------|
| Run backend (dev) | `cd backend && uv run uvicorn src.app.main:app --reload --port 18080` |
| Run tests | `cd backend && uv run pytest tests/ -v` |
| Run single test | `cd backend && uv run pytest tests/test_foo.py::test_bar -v` |
| Run with coverage | `cd backend && uv run pytest --cov=app --cov-report=term-missing` |
| Run eval harness | `cd backend && uv run eval-pipeline <chat.txt>` |
| Lint | `cd backend && uv run ruff check src/ tests/` |
| Type check | `cd backend && uv run mypy src/` |
| Docker build+run | `docker compose up -d --build` |
| Ports | API :18080 (host) → 8000 (container), Web :15173 |

---

## Architecture

```
backend/src/app/
├── aichat/           ← Interactive chat domain: chat, conversations, search, artifacts, settings, ingest.
│     router_*.py, service.py, conversations.py, messages.py, search.py,
│     queries_*.py, artifacts/, ingest/, models/, tools/, resources/config.yaml
│
├── whatsapp/         ← WhatsApp transport + profiling domain: export ingest, live events, chat state, groups, people.
│     router.py, service.py, realtime.py, distillation.py, tasks.py,
│     queries.py, queries_groups.py, ingest/, people/, models/, resources/config.yaml
│
├── coding_agents/    ← Coding agent session ingest + retrieval domain (Claude Code, Codex, Gemini CLI, OpenClaw).
│     router.py, service.py, queries.py, distillation.py,
│     ingest/, models/
│
├── documents/        ← Document ingest + deferred formatting domain.
│     router.py, service.py, pipeline.py, jobs.py, queries.py,
│     ingest/, models/, resources/config.yaml
│
├── admin/            ← Operations/admin surface: health, jobs, evidence, assets, runtime config.
│     router.py, router_assets.py, router_config.py, router_evidence.py,
│     router_memories.py, service.py, queries_*.py
│
├── foundation/       ← Pure infrastructure: no business logic, used by all packages.
│     db.py, settings.py, errors.py, dependencies.py, rate_limit.py,
│     migrations.py, backup.py, models/common.py, util/
│
├── kernel/           ← Shared domain logic used by multiple feature packages.
│     cleaner.py, memory_policy.py, memory_lifecycle.py,
│     router_ingest.py, router_memories.py, queries_ingest.py,
│     chunks/, evidence/, ingest/, jobs/, llm/, memories/, models/admin.py,
│     observability/, projects/, retrieval/, tags/, resources/
│
├── mcp/              ← MCP server entrypoints and tool wrappers.
│
├── main.py           ← FastAPI app assembly: middleware, exception mapping, router inclusion.
├── lifespan.py       ← Startup reconciliation, FAISS consistency, scheduled backups, WhatsApp polling.
├── middleware.py     ← Request logging + HTTP hardening middleware.
├── schema.sql        ← SQLite DDL source of truth.
└── observability.py  ← Legacy top-level observability helpers; prefer `kernel/observability/`.
```

### Layer Rules

1. **Feature packages own their HTTP surface.** Routers live next to the domain they serve (`aichat/router_*.py`, `whatsapp/router.py`, `documents/router.py`, `admin/router*.py`, `kernel/projects/router.py`). There is no central `routers/` package anymore.
2. **Routers stay thin.** They parse request state, open a DB connection through `foundation.dependencies.get_conn()`, call domain services, and return serialized results. They should not carry business logic.
3. **Service/orchestration modules receive `sqlite3.Connection` first.** This applies to domain services like `aichat/service.py`, `documents/service.py`, `whatsapp/service.py`, `kernel/memories/service.py`, and `kernel/projects/service.py`.
4. **Services never depend on FastAPI response semantics.** Prefer raising domain errors from `foundation/errors.py`. `HTTPException` is only acceptable in router-layer validation or when translating a genuinely HTTP-specific concern.
5. **SQL lives in domain query modules.** Use `queries.py`, `queries_<domain>.py`, or package-level query modules beside the feature they support. Do not reintroduce a shared catch-all `queries/` directory.
6. **Pure infrastructure (database, configuration, exceptions, dependency injection, utilities) belongs in `foundation/`.** Shared business logic and domain features used by multiple packages belong in `kernel/`. New auth middleware → `foundation/`. New shared LLM feature → `kernel/`.
7. **Dependency direction is package-first.** `main.py` / `lifespan.py` wire the app, routers depend on same-package services plus `foundation`/`kernel`, query modules stay low-level, and cross-feature imports should be rare and explicit. Avoid recreating the old flat-layer import graph.
8. Global `AppError` handler in `main.py` maps domain exceptions to HTTP responses:
   - `NotFoundError` → 404
   - `ForbiddenError` → 403
   - `ConflictError` → 409
   - `ValidationError` → 422
   - `CapExceededError` → 429
   - `ProviderError` → 503

---

## Coding Conventions

### Style
- Python 3.10+. Use `X | Y` union syntax, not `Optional[X]`.
- Ruff for linting (line-length 120, rules: E, F, I, B, UP). No `# noqa` unless truly unavoidable.
- Type hints on all function signatures. Avoid `Any` — use specific types or generics.
- No docstrings on obvious functions. Add docstrings only where the *why* isn't clear from the name + types.

### Naming
- Files: `snake_case.py`. Router files use the current package conventions: `router.py` or `router_<capability>.py`.
- Functions: `snake_case`. Private helpers prefixed with `_`.
- Classes: `PascalCase`. Services are plain functions/modules, not singletons.
- Constants: `UPPER_SNAKE_CASE`. Magic numbers go in `kernel/settings.py`.

### Error Handling
- Services raise domain exceptions (`NotFoundError`, `ForbiddenError`, `ConflictError`, `ValidationError`, `CapExceededError`, `ProviderError`).
- Routers do **not** catch domain exceptions. The global `AppError` handler in `main.py` converts them to JSON automatically.
- Routers may catch domain exceptions only when they need to add HTTP-specific context (rare).
- Never use bare `except Exception`. Catch specific exceptions or `AppError`.

### Comments
- No commented-out code. Ever. Git has history.
- No obvious comments. No TODO/FIXME without a linked issue.
- Comments explain *why*, not *what*.

### API Responses
- List endpoints: `{"items": [...], "total": N}`
- Mutations: return the created/updated resource or `{"id": "...", "status": "..."}`
- Errors: `{"error": {"code": "NOT_FOUND", "message": "..."}}`
- All endpoints have OpenAPI summary + description + response_model.

### Date / Timestamp Standard
- **Backend → DB:** All timestamps stored as **Unix seconds integers** (`int(time.time())`). Column names: `created_at`, `updated_at`, `started_at`, `finished_at`, etc.
- **Backend → API:** Timestamp fields in JSON responses are **Unix seconds integers** (`int`). Never ISO strings, never milliseconds.
- **Frontend TypeScript:** Timestamp fields typed as `number`. Convert to `Date` with `new Date(ts * 1000)`. Never `new Date(ts)` directly.
- **Exception:** External data that arrives as ISO strings (e.g., backup metadata from filesystem) stays as `string` — label these fields clearly in the interface.
- Never mix formats. If a field name ends in `_at` it is a Unix seconds integer unless explicitly noted otherwise.

---

## Testing

### Standards
- Framework: pytest + pytest-asyncio + httpx (AsyncClient).
- Coverage target: 100% on service/orchestration and utility modules, ≥90% overall.
- Every service method has at least one unit test. Every endpoint has at least one integration test.

### File Naming
- Unit tests: `test_<module>.py` (e.g., `test_chat_service.py`)
- E2E tests: `tests/e2e/test_<flow>.py` (e.g., `test_e2e_chat_flow.py`)
- No phase numbers, no codenames, no abbreviations in test file names.

### Function Naming
- `test_<action>_<scenario>` (e.g., `test_search_returns_empty_for_unknown_query`)
- Use `@pytest.mark.parametrize` for input variations instead of copy-pasting tests.

### Fixtures & Factories
- Shared test data via `tests/factories.py`: `create_conversation()`, `create_message()`, `create_chunk()`.
- Single `FakeProvider` in `tests/fake_provider.py` — no duplicating mock providers per test file.
- Database isolation via autouse `_isolate_paths` fixture in `conftest.py`.
- Use `db` fixture for unit tests (raw connection), `client` fixture for integration tests (AsyncClient).

### E2E tests that must keep passing
- `test_e2e_coding_agents_ingest.py` — coding agent session ingest (Claude Code → search)
- `test_e2e_context_retrieval.py` — context retrieval with DM scope
- `test_e2e_search_scoping.py` — search with source_channel filtering
- `test_e2e_edge_cases.py` — edge cases (empty queries, malformed input)

### What NOT to Do
- No `unittest.mock.patch` spaghetti. Prefer dependency injection + fake implementations.
- No polling loops (`for _ in range(20): sleep(0.05)`). Use async utilities or deterministic fakes.
- No test data hardcoded as multi-line SQL strings. Use factories.
- No test files at project root. All tests live in `backend/tests/`.

---

## Core Product Rules

1. Preserve retrieval quality and source traceability (search/chat responses must keep source snippets coherent).
2. Do not break ingest pipeline compatibility for `.json` and `.zip` ChatGPT exports.
3. Keep UI behavior clear for imported data vs local saved interactions (avoid confusing "recent" with DB history).
4. Maintain auth/CORS safety defaults; never silently weaken API protection.
5. Keep changes scoped; avoid mixing unrelated backend + UI refactors in one pass.

## Backend & Configuration Guardrails
- **Config over Hardcode:** Never hardcode prompts, keyword lists, or taxonomy vocabulary in Python. Resource YAML now lives under package-local `resources/` directories (`aichat/resources/config.yaml`, `documents/resources/config.yaml`, `whatsapp/resources/config.yaml`, `kernel/resources/taxonomy.yaml`) and is merged through the shared loader. Projects are managed via the DB (`/projects` CRUD).
- **All LLM prompts must live under the `prompts:` key in a resource YAML.** Load them via `get_prompt("prompt_name")` from `kernel/util/config_loader.py`. Never define prompt strings inline in Python source files.
- **Pre-Storage Cleaning:** All message content must be sanitized via `kernel/cleaner.py` before being saved to the database.
- **Selective Ingestion:** Avoid importing technical noise (e.g., `tool` role messages) that degrades the memory history.

## API Change Guardrails
- Keep endpoint behavior explicit and backward compatible when possible.
- For new endpoints: add tests, include pagination for list endpoints, keep auth consistent.
- Avoid expensive unbounded queries; default to sensible `limit/offset` patterns.

## UI Change Guardrails
- Keep dark theme consistency and responsive behavior.
- Prefer additive UI (new tab/panel/filter) over replacing existing user flows unless requested.
- Persist only lightweight UI state in localStorage; avoid storing large payloads client-side.

---

## Development & Workflow

### Ports
| Service | Host port | Container port |
|---------|-----------|----------------|
| API     | **18080** | 8000           |
| Web     | **15173** | 5173           |
| Swagger | http://localhost:18080/docs | — |

### Critical Workflow Rule
- `docker-compose.yml` mounts `./backend/src/app:/app/app` for live reloads.
- After any code/config change, rebuild and restart: `docker compose up -d --build`
- Do not leave rebuild/restart as a manual follow-up — the agent does it.

### Required Checks Before Finishing

**Backend:**
```bash
cd backend && uv run pytest tests/ -v
cd backend && uv run pytest tests/ --cov=app --cov-report=term-missing
```
Coverage requirements: 100% on service/orchestration and utility modules, ≥90% overall. Never merge a PR that drops coverage below baseline.
**Web (when UI changes):**
```bash
cd web && npm run lint
cd web && npm test
cd web && npm run build
```

**Runtime validation:**
```bash
docker compose up -d --build
docker compose exec api python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8000/health').read())"
```

### Operational DB Safety
- Live runtime DB: `/app/data/app.db` inside the container (Docker volume `nexus_data`). Never mutate `backend/data/app.db` on the host.
- All operational scripts were removed in Phase 1 of the refactor. Operations are now API endpoints.

---

## Definition of Done
- Relevant backend/web checks pass.
- Stack rebuilt + restarted for every change (unless user explicitly waived).
- Coverage did not drop.
- Final report includes: changed files, commands run, test/lint/build results, any known limitations.

## Commit/PR Hygiene
- Keep commits objective-focused (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`).
- Document why the change exists, not only what changed.
- Do not commit or push unless explicitly requested.

---

## Do NOT

- Add backwards-compatibility shims, re-exports, or `# removed` comments. Delete cleanly.
- Keep one-off scripts in the codebase. Operations are API endpoints with job tracking.
- Add a message queue, ORM, or external cache. SQLite + FAISS + async jobs is the stack.
- Create abstractions for things used once. Three similar lines > premature abstraction.
- Add emoji to code, comments, logs, or error messages.

---

## Domain Logic Reference

### Ingestion Pipeline
Five stages: Ingest → Clean → Format (Document-only) → Tag → Vectorize.

1. **Ingest** (`aichat/ingest/`, `whatsapp/ingest/`, `documents/ingest/`, `coding_agents/ingest/`): Supports `.zip` (ChatGPT Export), raw `.json`, WhatsApp `.txt`, live WhatsApp transport events, coding agent sessions (Claude Code `.jsonl`, Codex `.jsonl`, Gemini CLI `.json`, OpenClaw `.jsonl`), and Documents (PDF, MD, DOCX, etc). Standardizes roles (`user`, `assistant`, `system`). `tool` role messages are ignored.
2. **Clean** (`kernel/cleaner.py`): Every message/chunk passes through the cleaner before being saved. Strips technical JSON, voice metadata, and custom tokens.
3. **Format (Deferred)** (`documents/ingest/` + `documents/jobs.py`): Uploaded documents are first ingested as raw text. A background job then uses the LLM to format the text into clean Markdown (fixing headers, tables, etc.) for better retrieval quality.
4. **Tag** (`kernel/tags/classifier.py`): LLM-based classification producing `continuity` (one-off/long-running/recurring), open-ended `topics`, and validated `signals` (planning/review/debugging…). Taxonomy vocabulary is defined in `kernel/resources/taxonomy.yaml`. Project assignment is separate and DB-validated.
5. **Vectorize** (`kernel/retrieval/vector.py`): Generates embeddings via OpenAI/Gemini for semantic search.

### WhatsApp Live Transport
- Live WhatsApp transport is now split from historical export ingest.
- The live path depends on the external `wacli` service in `~/projects/wacli-service/`, reached over HTTP rather than shelling out to a local subprocess.
- Durable live state is tracked through `raw_message_log`, `ingest_cursor`, `pending_chat_trigger`, `chat_progress_cursor`, and `whatsapp_distillation_batch`.
- Accepted steady-state topology is `wacli` plus Baileys coexistence. Do not model current work as a required migration to single transport.
- Key routes for this path are:
  - `POST /whatsapp/admin/pre-seed`
  - `POST /whatsapp/admin/catch-up`
  - `POST /whatsapp/ingest/whatsapp-events`
  - `GET /whatsapp/context/{chat_id}/state`
  - `POST /whatsapp/admin/distill`
  - `GET /whatsapp/admin/migration-status`

### Coding Agent Sessions
- Sessions are scanned from filesystem roots configured via settings (`coding_agents_claude_root`, `coding_agents_codex_root`, `coding_agents_gemini_root`, `coding_agents_openclaw_root`).
- **Workflow:** Sessions are placed in a **staging queue** upon ingestion with status `pending`. They must be **approved** (manually or via staging API) to be distilled and indexed.
- **Distillation:** Once approved, a session is distilled into a plain-text summary via LLM (`coding_agents/distillation.py`), then chunked and vectorized for retrieval. Chunks are only visible in search if the session has an assigned `project_id`.
- Chunks are stored with `source_domain='coding_agents'` and `source_channel='coding_agents:<source>'` (e.g., `coding_agents:claude_code`).
- Key routes: `POST /coding-agents/ingest`, `GET /coding-agents/sessions`, `GET /coding-agents/project-staging`, `POST /coding-agents/project-staging/{id}/approve`.
- Background scanner runs on `coding_agents_scan_interval_seconds` cadence (default 1800 s).

### Search & Retrieval
- **Intent-Aware Retrieval:** The system detects if the query is about a person or a general topic and balances the source distribution (WhatsApp vs. Documents vs. AI Chats) accordingly.
- **Hybrid Search:** Combines BM25 (SQLite FTS5) with Vector Search (FAISS).
- **Reranking:** Post-retrieval LLM scoring to select the top context candidates for the final prompt.

### Environment & Data Rules
- **Live runtime DB:** `/app/data/app.db` inside the container (Docker volume `nexus_data`).
- **Host-side DB:** `backend/data/app.db` — may not reflect live state. Never assume parity.
- **Vector Index:** `/app/data/faiss.index` in the container volume.
- **HMR:** Frontend source is volume-mapped for Hot Module Replacement in dev.
