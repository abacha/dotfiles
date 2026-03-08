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
