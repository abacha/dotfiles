# Project Context: tiao
> Project path: `~/projects/trag/tiao`

This file serves as the **master instruction set** for AI agents working on the `tiao` project. It combines behavioral rules, operational commands (runbook), and troubleshooting context.

## 1. Core Guidelines & Product Rules

**Goal:** Maintain the WhatsApp bot for TRAG (climate + insurance conversational agents).

1.  **Language Quality:** Keep Portuguese (PT-BR) conversational quality high; avoid robotic responses.
2.  **Role Security:** Preserve strict role-based behavior.
    *   Admins: Full capabilities + CLI route.
    *   Standard users: Specialized agents only.
3.  **Session Stability:** Respect session continuity and timeouts.
4.  **Transport Constraints:** Respect Twilio message size limits (chunking) and formatting.
5.  **Security:** Maintain safe webhook handling (signature validation + payload limits).

## 2. Operational Runbook (AI Commands)

Use these commands to build, run, and test the project.

### Development & Execution
*   **Install:** `npm install`
*   **Local Run:** `node index.js` (Requires `.env`)
*   **Docker Run:**
    ```bash
    docker build -t tiao .
    docker run -d --env-file .env -p 8080:8080 --name tiao tiao
    ```

### Testing
*   **Smoke Test (Required):** `npm run test:smoke` (Run this before finishing any task).
*   **Full Suite:** `npm test` (Run if logic/services were modified).

### Environment Rules
*   **Target:** Default to **staging** for all integration/debug work unless explicitly targeting production.
*   **Config:** URLs are in `config.json` or `.env`. Do not hardcode.
*   **Webhooks:** Ensure `PUBLIC_BASE_URL` matches the active environment (Staging vs Prod).

## 3. Critical Areas & Hotspots

Focus attention here when debugging or refactoring:
*   **Twilio Migration:** Stability and chunking logic (`src/services/twilio-service.js`, `message-handler.js`).
*   **Climate Reference:** Doc fetch flow, auth, and caching (`src/services/climate-reference.js`).
*   **Agent Output:** API list formatting and fallback removal (`src/agents/climate-agent.js`).
*   **Ops:** Ingress/domain config (`tiao.trag.agr.br`, static IP).

## 4. Workflow & Hygiene

*   **Commits:** Use semantic prefixes (`feat:`, `fix:`, `chore:`). Do not mix unrelated ops/agent changes.
*   **Definition of Done:**
    *   [ ] No regression in climate/insurance routing.
    *   [ ] Twilio send/receive path verified.
    *   [ ] `npm run test:smoke` passed.
    *   [ ] Config/Env changes documented.

## 5. Troubleshooting Checklist

If issues arise, check these first:

*   **Webhook Silent?** Verify `POST https://<PUBLIC_BASE_URL>/twilio/webhook` is reachable and `TWILIO_AUTH_TOKEN` is valid.
*   **Replies Truncated?** Check message chunking logic and Twilio API logs (4xx/5xx).
*   **Routing Fail?** Verify `prompts/` router config and user role (admin vs standard).
*   **Doc Fetch Fail?** Check `CLIMATE_REFERENCE_URL` reachability and `CLIMATE_REFERENCE_AUTH_SECRET`.
*   **Ingress Error?** Validate `ingress.yaml` host/class and DNS resolution.

## 6. Reference: Environment Variables

**Core:** `WHITELISTED_NUMBERS`, `ADMIN_NUMBERS`, `GCLOUD_PROJECT_ID`, `GOOGLE_MAPS_API_KEY`, `API_EMAIL`, `API_PASSWORD`
**Twilio:** `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_WHATSAPP_NUMBER`, `PUBLIC_BASE_URL`
**Climate:** `CLIMATE_REFERENCE_URL`, `CLIMATE_REFERENCE_AUTH_SECRET`
