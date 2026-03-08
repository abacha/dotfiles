# Hubstaff Server — Experiments (Statsig)
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
