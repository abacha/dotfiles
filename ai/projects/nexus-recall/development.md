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
