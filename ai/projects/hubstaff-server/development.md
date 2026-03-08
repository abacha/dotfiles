# Hubstaff Server — Development & Testing
> Project path: `~/projects/hubstaff/hubstaff-server`

## Build, Test, and Development Commands
- Run all commands inside the `hs-server` container (e.g., `docker exec hs-server bundle exec rspec`).
- First-time setup: `bin/setup`, then `pnpm install` (Node 22.14 via Volta).
- Run locally: `bundle exec rails s`, `bundle exec sidekiq`, `VITE_RUBY_HOST='0.0.0.0' bin/vite dev`.
- Backend tests: `bundle exec rspec`. Lint Ruby: `bundle exec rubocop -A` on changed files.
- Frontend tests: `pnpm test`. Lint JS/Vue: `pnpm lint`.
- Optional checks: `bin/brakeman`, `bin/test_asset_compile.sh`.

## Testing Guidelines
- Add RSpec coverage for new endpoints, services, jobs, and policies; prefer factories and `let_it_be`.
- Avoid `update_columns` in specs.
- Prefer stubbing high-level services (e.g., `CustomerIOManager.send_email`).
- Prefer implicit RSpec syntax when possible.
- Use `context` blocks for conditional branches (`when ...`).
- For UI work, add Vitest + Testing Library specs near the component.

## Commit & Pull Request Guidelines
- Commit messages follow Conventional Commits (<=100 character header).
- PRs should include summary, linked issue, screenshots/recordings, and notes on migrations/jobs.
- List commands run in the PR description.
