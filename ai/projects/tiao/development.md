# Tiao — Development & Workflow
> Project path: `~/projects/trag/tiao`

## Operational Runbook (AI Commands)
### Development & Execution
- **Install:** `npm install`
- **Local Run:** `node index.js` (Requires `.env`)
- **Docker Run:**
  ```bash
  docker build -t tiao .
  docker run -d --env-file .env -p 8080:8080 --name tiao tiao
  ```

### Testing
- **Smoke Test (Required):** `npm run test:smoke`.
- **Full Suite:** `npm test`.

### Environment Rules
- **Target:** Default to **staging** for all integration/debug work.
- **Config:** URLs are in `config.json` or `.env`. Do not hardcode.
- **Webhooks:** Ensure `PUBLIC_BASE_URL` matches the active environment.

## Troubleshooting Checklist
- **Webhook Silent?** Verify `POST https://<PUBLIC_BASE_URL>/twilio/webhook` is reachable.
- **Replies Truncated?** Check message chunking logic and Twilio API logs.
- **Routing Fail?** Verify `prompts/` router config and user role (admin vs standard).
- **Doc Fetch Fail?** Check `CLIMATE_REFERENCE_URL` reachability.
- **Ingress Error?** Validate `ingress.yaml` host/class and DNS resolution.

## Workflow & Hygiene
- **Commits:** Use semantic prefixes (`feat:`, `fix:`, `chore:`).
- **Definition of Done:**
  - [ ] No regression in climate/insurance routing.
  - [ ] Twilio send/receive path verified.
  - [ ] `npm run test:smoke` passed.
  - [ ] Config/Env changes documented.
