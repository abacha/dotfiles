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
