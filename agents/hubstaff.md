# Repository Guidelines

## Project Structure & Module Organization
- Ruby on Rails application lives in `app/` (controllers, models, services, jobs, policies, mailers, widgets), with shared utilities in `lib/` and configuration in `config/`.
- Vue 2 frontend code is under `app/javascript` (plus legacy assets in `app/assets/javascripts`); shared styles are driven by Tailwind via `tailwind.config.js`.
- Specs are in `spec/` (RSpec for backend) with JS unit specs alongside components or in `spec/javascript`. Database schema and seeds sit in `db/`.
- Docs and internal guidelines reside in `docs/` and `documentation/` for deeper background.

## Build, Test, and Development Commands
- Run all commands inside the `hs-server` container (e.g., `docker compose exec hs-server bundle exec rspec` or `docker exec -it hs-server pnpm test` if it is already running).
- First-time setup: `bin/setup` to install gems and prepare the database, then `pnpm install` (Node 22.14 via Volta) for frontend dependencies.
- Run locally with `bundle exec rails s -b 0.0.0.0 -p 3000` plus `bundle exec sidekiq` for workers; start assets with `VITE_RUBY_HOST='0.0.0.0' bin/vite dev` (mirrors `Procfile.local`).
- Backend tests: `bundle exec rspec` (scope with `bundle exec rspec spec/path/to/file_spec.rb`); lint Ruby with `bundle exec rubocop`.
- Always run `bundle exec rubocop -A` on changed Ruby files after making code changes.
- If you change any spec, run that spec (do not ask whether to run it).
- Frontend tests: `pnpm test` or `pnpm test:watch`; lint JS/Vue with `pnpm lint`.
- Optional checks: `bin/brakeman` for security scanning; `bin/test_asset_compile.sh` to verify asset builds.

## Coding Style & Naming Conventions
- Follow the repository’s RuboCop and styleguide rules for Ruby and RSpec.
- Ruby code follows RuboCop defaults (2-space indent, single quotes, expressive predicate names). Place new service objects in `app/services` with verb-driven names, jobs in `app/jobs` ending in `_job.rb`, and policies in `app/policies`.
- Specs follow RSpec naming (`*_spec.rb`) and live near the code they cover; reuse helpers in `spec/support`.
- Vue components use PascalCase filenames, camelCase props/methods, and rely on ESLint + Prettier (`.eslintrc.js`, `.prettierrc.js`). Keep shared UI primitives colocated in `app/javascript/components`.
- Favor small, focused pull requests that align with existing directory patterns rather than introducing new top-level folders.

## Testing Guidelines
- Add RSpec coverage for new endpoints (request/controller specs), services, jobs, and policies; prefer factories and `let_it_be` helpers to keep tests fast and deterministic.
- Avoid `update_columns`/`update_column` in specs unless unavoidable; prefer factory setup and related records to drive counters (e.g., create `user_organizations` instead of manually setting `active_user_organizations_count`).
- Prefer stubbing high-level services (e.g., `CustomerIOManager.send_email`) instead of internal client objects unless a test requires lower-level behavior.
- Prefer implicit RSpec syntax when possible (e.g., `it { is_expected.to ... }`, `its_block { is_expected.to ... }`).
- For UI work, add Vitest + Testing Library specs near the component to cover rendering, interactions, and edge cases; mock network calls where possible.
- Update fixtures/seeds only when necessary and document significant test data changes in PR descriptions.
- Aim to keep suites green locally before pushing; partial runs are fine if scoped to the touched areas plus smoke tests.

## Commit & Pull Request Guidelines
- Commit messages follow Conventional Commits with sentence-case subjects (types allowed: chore, ci, docs, feat, fix, gemfile, migration, perf, refactor, revert, style, test, package) and a <=100 character header.
- PRs should include a concise summary, linked issue/ticket, screenshots or recordings for UI changes, and notes on migrations or background jobs. List the commands you ran (e.g., `bundle exec rspec`, `pnpm test`, `bundle exec rubocop`) in the description so reviewers can trust the state.
