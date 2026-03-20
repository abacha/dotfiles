# Hubstaff Server — Constitution
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

> Project path: `~/projects/hubstaff/hubstaff-server`

## Experiment Structure & Implementation
- **Experiments use Statsig, NOT feature flags.** Code lives in `lib/experiments/` and inherits from `Experiments::Base`.
- Define constants per experiment: `EXPERIMENT_KEY`, `DYNAMIC_CONFIG_KEY`, `LAYER_KEY`.
- Prefer `config_value` for Dynamic Config-driven UI/content values.
- Use `check_param` only when you intentionally want assignment/layer behavior.

## Dynamic Configs on Statsig (Critical)
- Keep key names **exactly** aligned between Ruby and Statsig.
- Prefer a single `features` array over `feature_1..feature_n` keys.
- Avoid hardcoded defaults in experiment classes for production behavior.

## Frontend Integration (Slim + Plans)
- Experiment JS controllers: `app/assets/javascripts/controllers/experiments/00xx_*.js`.
- Views/partials: `app/views/experiments/exp_00xx_*/`.
- For Hubstaff SGT plans, integrate in `app/views/organizations/ab_testing/hubstaff_sgt/_default.html.slim`.
- Use the correct backend plan key for CTA actions (`hubstaff_sgt_starter_monthly`).
- **Slim syntax caution:** multiline inline hashes in helper args can break parsing.

## Analytics Pattern
- Track events via POST `/analytics` with CSRF token.
- Keep event names stable and prefixed by experiment id.
- Do not block primary CTA flow just for analytics failures.

## Rollout & Cleanup
- Disable experiment in Statsig first, then remove code/assets.
- Treat experiment code as temporary; remove dead support code when sunsetted.
- If experiment becomes permanent, migrate code/assets out of experiment namespaces.


This doc explains the `hs-local` stack and `.sre-toolkit` helpers that spin up Hubstaff’s development services (Postgres, Traefik, etc.) so you can keep it alongside your other AI projects.

## Running the stack
The core helper is located inside `~/.sre-toolkit/bin/hs-local`. It delegates to Docker Compose files that live under `~/.sre-toolkit/local`. The usual startup sequence is:

1. `hs-local services start` – boots the shared infrastructure (Postgres, Redis, ClickHouse, Traefik, etc.).
2. `hs-local account start <repo>` – boots the account-specific Rails app and sidecars (you may need to run it once per repo).
3. `hs-local server start <repo>` – runs the server process if you prefer it separately.

Each command simply calls `docker compose -f <compose file>` from the toolkit directory, so you can open that YAML manually to understand what services are configured.

## Port collisions & overrides
The Compose file at `~/.sre-toolkit/local/compose.services.yml` is the only place the stack exposes host ports (see `ports:` sections for Postgres, Redis, Traefik, etc.). To avoid collisions when you run another project that also uses 5432/80/8080:

- Edit `compose.services.yml` locally before running `hs-local services start` and change the left-hand side of the `ports:` entries (e.g., `"5433:5432"`, `"9080:80"`).
- These edits are outside your tracked repos, so they stay uncommitted. You can keep a personal copy or script that rewrites the file before launching, or run `docker compose -f local/compose.services.yml -f local/compose.override.yml up` manually if you need persistent overrides.
- Alternatively, stop/pause one stack while the other is running, or use network isolation (WSL distro, Podman machine) so each stack has its own namespace.

## Tips
- When you need to bring up the Hubstaff stack for short-lived debugging, edit the ports immediately before `hs-local services start` and rerun `hs-local services restart` once you’re done.
- Document the custom ports you’re using in this file so you remember them later.
- Since the toolkit scripts already call `docker compose` with that base file, there’s no extra command-line flag—just edit the YAML directly and restart the service.

Keep this file updated if you discover any new quirks or additional helpers.



# Project Overview & Domain Logic

# Hubstaff Server — Overview & Organization
> Project path: `~/projects/hubstaff/hubstaff-server`

## Project Structure & Module Organization
- Ruby on Rails application lives in `app/` (controllers, models, services, jobs, policies, mailers, widgets), with shared utilities in `lib/` and configuration in `config/`.
- Vue 2 frontend code is under `app/javascript` (plus legacy assets in `app/assets/javascripts`); shared styles are driven by Tailwind via `tailwind.config.js`.
- Specs are in `spec/` (RSpec for backend) with JS unit specs alongside components or in `spec/javascript`. Database schema and seeds sit in `db/`.
- Docs and internal guidelines reside in `docs/` and `documentation/` for deeper background.

## Coding Style & Naming Conventions
- Follow the repository’s RuboCop and styleguide rules for Ruby and RSpec.
- Ruby code follows RuboCop defaults (2-space indent, single quotes, expressive predicate names). Place new service objects in `app/services` with verb-driven names, jobs in `app/jobs` ending in `_job.rb`, and policies in `app/policies`.
- Specs follow RSpec naming (`*_spec.rb`) and live near the code they cover; reuse helpers in `spec/support`.
- Vue components use PascalCase filenames, camelCase props/methods, and rely on ESLint + Prettier (`.eslintrc.js`, `.prettierrc.js`). Keep shared UI primitives colocated in `app/javascript/components`.
- Favor small, focused pull requests that align with existing directory patterns rather than introducing new top-level folders.
## Related Documentation
- [development.md](./development.md): Environment setup, running tests, and build workflows.
- [experiments.md](./experiments.md): Managing A/B tests and experimentation flags.
