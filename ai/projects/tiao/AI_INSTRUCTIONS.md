# Tião - AI Instructions

This document provides specialized instructions for AI agents working on the Tião project. Read this before making changes to the codebase.

## 1. High-Impact Areas & Architecture
When debugging or refactoring, pay special attention to these hotspots:
- **WhatsApp/Twilio Bot Behavior:** Stability, message chunking, and formatting (`src/services/twilio-service.js`, `message-handler.js`).
- **Climate Reference Flow:** Document fetching, authentication, and caching (`src/services/climate-reference.js`).
- **Agent Output:** API list formatting, fallback removal, and PT-BR conversational quality (`src/agents/climate-agent.js`).
- **Ingress & Ops:** Domain configuration (`tiao.trag.agr.br`), static IP mapping, and Kubernetes deployment settings.

## 2. Environment & Configuration Cues
Do not hardcode configuration. Look for these variables in `.env` and `config.json`:
- **Twilio & Routing:** `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_WHATSAPP_NUMBER`, `PUBLIC_BASE_URL` (must match the active environment for webhooks).
- **Climate Services:** `CLIMATE_API_URL` (e.g., `https://climate-risk-analisys.trag.agr.br/api/simulations`), `CLIMATE_REFERENCE_URL`, `INSURANCE_GRAPHQL_URL`.
- **Core/Auth:** `WHITELISTED_NUMBERS`, `ADMIN_NUMBERS`, `GCLOUD_PROJECT_ID`, `GOOGLE_MAPS_API_KEY`.

## 3. Operational Runbook
- **Target Environment:** Default to **staging** for all integration and debug work.
- **Install:** `npm install`
- **Run Locally:** `node index.js`
- **Run Tests:** 
  - Smoke test (Required): `npm run test:smoke`
  - Full suite: `npm test`
- **Deploy (Docker):**
  ```bash
  docker build -t tiao .
  docker run -d --env-file .env -p 8080:8080 --name tiao tiao
  ```

## 4. Branch Policy & Release/1.0 Style
- **Docs-First Changes:** Always update relevant documentation (e.g., `TECH_SPEC.md`, `docs/`) before or alongside code changes.
- **Semantic Commits:** Use strict semantic prefixes (`feat:`, `fix:`, `chore:`, `docs:`).
- **Testing:** Tests must be updated and pass (`npm run test:smoke`) as defined by the branch policy before any deployment.

## 5. Recent Context & Stateful Info
- **WhatsApp Gateway:** The WhatsApp gateway credentials (`~/.openclaw/credentials/whatsapp*`) were recently dropped. **The next connection will require fresh pairing/QR scan.**
- **Routing & Prefixes:** Gateway was re-linked and prefix removal was implemented. Ensure the webhook payload handles prefix-less messages correctly.
- **Funnel State Machine:** The bot now handles Ack → Diagnóstico → Budget discovery with specific delays (1s before missing data, 5s before budget). Monetary masking applies to DIAGNOSIS and INSURANCE_OFFER, but BUDGET_DISCOVERY is unmasked.

## 6. Definition of Done (DoD) Checklist
Before completing a task, verify:
- [ ] No regression in climate/insurance routing.
- [ ] Twilio send/receive paths are fully verified.
- [ ] `npm run test:smoke` passes successfully.
- [ ] Configuration and environment variable changes are documented.
- [ ] Appropriate delays and masking (e.g., compliance guard) are maintained.