# Chess Memory Tester — Overview
> Project path: `~/projects/trag/chess_memory_tester`

This project is a single-page app with a small API. Use this guide to keep changes consistent.

## Stack and Layout
- Frontend: React (Vite) in `apps/web`
- Backend: Express in `apps/api`
- Tests: `tests/web` (Vitest + Testing Library), `tests/server` (Jest)
- Assets: `apps/web/public/assets` (piece SVGs, icons)
- PGN source folder: `pgn` (no directory selector in UI)
- Ruby implementation removed; do not reintroduce Ruby files.

## Key Frontend Files
- `apps/web/src/App.jsx`: main flow, session state, replay controls, i18n toggle.
- `apps/web/src/components/Board.jsx`: board rendering, click/drag, highlights.
- `apps/web/src/components/MoveLog.jsx`: PGN move list + highlights.
- `apps/web/src/domain/trainingEngine.js`: state machine and move validation.

## API + Engine
- API endpoints live in `apps/api`.
## Related Documentation
- [development.md](./development.md): Build, test, and deployment workflows.
- [conventions.md](./conventions.md): Code style, project structure, and pattern guidelines.
