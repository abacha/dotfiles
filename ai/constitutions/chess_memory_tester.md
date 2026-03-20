# Chess Memory Tester — Constitution
# Chess Memory Tester — UX & UI Conventions
> Project path: `~/projects/trag/chess_memory_tester`

## Core UX Rules
- Moves are made by click/drag only; no text input for moves.
- Wrong move: board border turns red. Only show the correct move after "Hint".
- Comments from PGN should be shown in the move list with clear association.
- Line completion panel should sit below board + list (no overlay).
- Replay supports buttons + keyboard:
  - ArrowRight/ArrowLeft: step
  - ArrowUp: first move
  - ArrowDown: last move
  - Space: play/pause

## i18n
- All user-visible strings must go through `apps/web/src/i18n/index.js`.
- EN is default, PT-BR available. Store locale in localStorage.
- Avoid hardcoded strings in JSX.

## Visual/Layout Notes
- Keep the move list and board same height; move list scrolls internally.
- CTA buttons should not wrap in a way that breaks layout.
- Avoid over-padding and extra vertical scroll.

## Agent Responsibilities
- Keep the project running through Docker at all times unless the user requests otherwise.
- Run all tests after major changes or when switching contexts.
# Chess Memory Tester — Development & Testing
> Project path: `~/projects/trag/chess_memory_tester`

## Dev Commands
- Web dev: `npm run dev` in `apps/web`
- API dev: `npm run dev` in `apps/api`
- Docker dev (background): `docker compose -f docker-compose.dev.yml up -d` (web: 5174, api: 5175)
- Tests: `npm test` in `apps/web` and `apps/api`

## Testing Rules
- Do not match by text; always use `data-testid` or semantic roles.
- When adding UI, include stable `data-testid` for tests.
- After significant changes, run:
  - `npm test` in `apps/web`
  - `npm test` in `apps/api`


# Project Overview & Domain Logic

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
