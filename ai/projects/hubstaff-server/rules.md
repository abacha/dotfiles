# Repository Guidelines
> Project path: `~/projects/hubstaff/hubstaff-server`

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
- For hash-like results, favor `its([:key]) { is_expected.to ... }` over separate `describe` blocks with `subject { hash[:key] }`.
- Use `context` blocks for conditional branches (`when ...`), not `describe`.
- For UI work, add Vitest + Testing Library specs near the component to cover rendering, interactions, and edge cases; mock network calls where possible.
- Update fixtures/seeds only when necessary and document significant test data changes in PR descriptions.
- Aim to keep suites green locally before pushing; partial runs are fine if scoped to the touched areas plus smoke tests.


## Experiment Guidance

### Experiment Structure & Implementation
- **Experiments use Statsig, NOT feature flags.** Code lives in `lib/experiments/` and inherits from `Experiments::Base`.
- Define constants per experiment:
  - `EXPERIMENT_KEY`
  - `DYNAMIC_CONFIG_KEY`
  - `LAYER_KEY` (if layer-based)
- Prefer `config_value` for Dynamic Config-driven UI/content values.
- Use `check_param` only when you intentionally want assignment/layer behavior.
- `meets_criteria?` is optional. If targeting is fully in Statsig, keep Ruby criteria minimal.
- Set `statsig_organization_id` when org targeting is needed.

### Dynamic Configs on Statsig (Critical)
- Keep key names **exactly** aligned between Ruby and Statsig.
  - If Ruby reads `config_value(:plan_name)`, Statsig must use `plan_name` (not prefixed variants).
- Prefer a single `features` array over `feature_1..feature_n` keys.
- Avoid hardcoded defaults in experiment classes for production behavior; use `nil`/empty defaults and set real values in Statsig.
- For card-style pricing UIs, keep explicit keys for display text (e.g., `max_seats_text`, `platform_fee_details_text`, `primary_cta_text`).

### Frontend Integration (Slim + Plans)
- Experiment JS controllers: `app/assets/javascripts/controllers/experiments/00xx_*.js`.
- Views/partials: `app/views/experiments/exp_00xx_*/`.
- For Hubstaff SGT plans, integrate in `app/views/organizations/ab_testing/hubstaff_sgt/_default.html.slim`.
- Use the correct backend plan key for CTA actions (`hubstaff_sgt_starter_monthly` for Starter Monthly in SGT).
- **Slim syntax caution:** multiline inline hashes in helper args can break parsing (`Expected tag`). Keep helper arg hashes compact/safe and sanity-check templates after edits.

### Analytics Pattern
- Track events via POST `/analytics` with CSRF token.
- Keep event names stable and prefixed by experiment id.
- Do not block primary CTA flow just for analytics failures.

### Rollout & Cleanup
- Disable experiment in Statsig first, then remove code/assets.
- Treat experiment code as temporary; remove dead support code when sunsetted.
- If experiment becomes permanent, migrate code/assets out of experiment namespaces.
- Keep tests aligned with final stable paths and behavior.
## Commit & Pull Request Guidelines
- Commit messages follow Conventional Commits with sentence-case subjects (types allowed: chore, ci, docs, feat, fix, gemfile, migration, perf, refactor, revert, style, test, package) and a <=100 character header.
- PRs should include a concise summary, linked issue/ticket, screenshots or recordings for UI changes, and notes on migrations or background jobs. List the commands you ran (e.g., `bundle exec rspec`, `pnpm test`, `bundle exec rubocop`) in the description so reviewers can trust the state.
