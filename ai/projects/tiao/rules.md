# tiao — Agent Instructions

## Scope
- Project: `~/projects/trag/tiao`
- Purpose: WhatsApp bot for TRAG (climate + insurance conversational agents), Twilio-based.
- Stack: Node.js (CommonJS), Express, Twilio, Vertex AI/Gemini, Google Speech, Google Maps.

## Core Product Rules
1. Keep Portuguese (PT-BR) conversational quality high; avoid robotic responses.
2. Preserve role-based behavior:
   - Admins: full capabilities (including CLI route).
   - Standard users: only specialized agents.
3. Do not break session continuity and timeout behavior.
4. Respect Twilio transport constraints (message size and format).
5. Maintain safe webhook handling (signature validation + payload limits).

## Recent Critical Areas (from AI history + git log)
- Twilio migration and stability hardening.
- Message chunking for Twilio size constraints.
- Climate reference doc fetch flow (external URL + optional auth + caching).
- Climate agent output handling refactors (API output list reliance, zip fallback removal).
- Ingress/domain ops updates (`tiao.trag.agr.br`, static ingress IP).

Main hotspots:
- `src/services/message-handler.js`
- `src/services/twilio-service.js`
- `src/services/format-service.js`
- `src/agents/climate-agent.js`
- `src/services/climate-reference.js`
- `index.js`, `deployment.yaml`, `ingress.yaml`

## Environment & Endpoint Rules
- Prefer **staging** endpoints for integration/debug unless explicitly told to use production.
- Keep URLs/config centralized in `config.json`, `.env`, and deployment manifests.
- For webhook-related changes, ensure `PUBLIC_BASE_URL` and Twilio webhook path remain consistent.

## Required Checks Before Finishing
- Run smoke tests:
  - `npm run test:smoke`
- If code touched command/agent/service flow, run test suite too:
  - `npm test`
- For ingress/deploy changes, validate manifests syntactically before handoff.

## Definition of Done
- No regression in climate/insurance routing and conversation flow.
- Twilio message send/receive path works and respects size limits.
- Relevant tests pass (smoke minimum, plus targeted/full as needed).
- Final report includes:
  - changed files
  - commands run
  - test results
  - rollout/config risks

## Commit/PR Hygiene
- Keep commits scoped and readable (`feat:`, `fix:`, `refactor:`, `chore:`).
- Avoid mixing ops manifest changes with unrelated agent logic unless strictly coupled.
- If touching deployment/security settings, document exact env vars impacted.
