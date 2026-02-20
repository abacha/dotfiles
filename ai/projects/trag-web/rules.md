# trag-web — Agent Instructions

## Scope
- Project: `~/projects/trag/trag-web`
- Stack: Next.js + TypeScript + Jest + Cypress
- Use these instructions for Codex/Claude/Gemini work on this repo.

## Recent Work Context (from AI history + git log)
- Trigger optimizer feature was added and iterated (`feat: add trigger optimizer` + fixups).
- Important related files:
  - `src/utils/triggersOptimizer/index.ts`
  - `src/utils/triggersOptimizer/types.ts`
  - `src/template/operations/triggerDefinition/analysis.tsx`
  - `__tests__/utils/triggersOptimizer.spec.ts`
- UI status logic was recently changed (`adding new status`, `adding red status`, page-based status behavior).
  - Main hotspot: `src/components/common/actionTable/index.tsx`
  - Related pages under `src/pages/*` for consultores/matrizes/operacoes/organizacoes/produtores.

## Working Rules
1. Keep changes small and scoped.
2. Prefer explicit data filtering over control flags when possible.
   - Example from prior discussions: avoid unnecessary `shouldSkip...` flags if preprocessing input is clearer.
3. Any change touching trigger calculations must validate slope/index behavior.
4. Do not regress first-year handling logic for calculations.
5. If touching status UI, validate behavior across all affected page contexts.
6. For backend data integration in local/dev work, always use the **staging API**.

## Backend Environment Rule (Critical)
- Default backend target for this project is staging:
  - `https://api.stg.trag.agr.br/`
- Known working pattern (from project stashes) in `next.config.js`:
  - add rewrite from `/api/graphql` to `https://api.stg.trag.agr.br/`
- Before backend-related debugging/testing, confirm requests are hitting staging and not production.

## Debugging the API (staging)
- You can hit the GraphQL API directly with `curl`—include `--http1.1` if HTTP/2 causes issues—and mirror whatever query the UI is sending (InsurancePolicyExport is a good starting point).
- The staging Authorization token is a naked string (no "Bearer"/"Token" prefix). Set the header exactly like:
  ```
  Authorization: <TOKEN>
  ```

## Required Checks Before Finishing
- Always run lint:
  - `npm run lint`
- For trigger logic changes, run targeted tests at minimum:
  - `npm test -- __tests__/utils/triggersOptimizer.spec.ts`
- For broader behavior changes, run full tests when feasible:
  - `npm test`

## Definition of Done (for PR-ready output)
- Code compiles and lint passes.
- Relevant tests pass (at least targeted tests for changed domain).
- No unintended behavior changes in trigger calculations or status rendering.
- Final report includes:
  - changed files
  - commands run
  - test/lint results
  - known risks (if any)

## Commit/PR Hygiene
- Use clear commit messages (`feat:`, `fix:`, `refactor:`).
- Avoid stacking many `fixup!` commits in final branch; squash before merge when possible.
- Keep branch focused on one objective.
