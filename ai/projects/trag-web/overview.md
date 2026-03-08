# Trag-Web — Overview & Context
> Project path: `~/projects/trag/trag-web`

## Scope
- Stack: Next.js + TypeScript + Jest + Cypress
- Backend Target: Staging (`https://api.stg.trag.agr.br/`)

## Recent Work Context
- Trigger optimizer feature was added and iterated.
- Hotspots: `src/utils/triggersOptimizer/`, `src/template/operations/triggerDefinition/analysis.tsx`, `__tests__/utils/triggersOptimizer.spec.ts`.
- UI status logic: `src/components/common/actionTable/index.tsx`, `src/pages/*`.

## Backend Environment Rule (Critical)
- Default backend target is staging: `https://api.stg.trag.agr.br/`.
- `next.config.js` should rewrite `/api/graphql` to staging.
- Confirm requests are hitting staging before debugging/testing.

## Debugging the API (staging)
- Hit GraphQL API with `curl` (include `--http1.1` if needed).
- Staging Authorization token is a naked string (no "Bearer"/"Token" prefix).
  ```
## Related Documentation
- [development.md](./development.md): Build workflows, testing (unit/E2E), and staging deployment.
