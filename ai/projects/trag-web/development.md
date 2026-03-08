# Trag-Web — Development & Workflow
> Project path: `~/projects/trag/trag-web`

## Working Rules
1. Keep changes small and scoped.
2. Prefer explicit data filtering over control flags when possible.
3. Any change touching trigger calculations must validate slope/index behavior.
4. Do not regress first-year handling logic for calculations.
5. If touching status UI, validate behavior across all affected page contexts.
6. For backend data integration in local/dev work, always use the **staging API**.

## Required Checks Before Finishing
- Always run lint: `npm run lint`.
- For trigger logic changes, run targeted tests:
  - `npm test -- __tests__/utils/triggersOptimizer.spec.ts`
- For broader behavior changes, run full tests: `npm test`.

## Definition of Done (for PR-ready output)
- Code compiles and lint passes.
- Relevant tests pass.
- No unintended behavior changes in trigger calculations or status rendering.
- Final report includes:
  - changed files
  - commands run
  - test/lint results
  - known risks (if any)

## Commit/PR Hygiene
- Use clear commit messages (`feat:`, `fix:`, `refactor:`).
- Avoid stacking many `fixup!` commits in final branch; squash before merge.
- Keep branch focused on one objective.
