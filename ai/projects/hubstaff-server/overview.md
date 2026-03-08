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
