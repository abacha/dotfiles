# tiao — Project AI Runbook

## Quick Runbook

### Local run
```bash
cd ~/projects/trag/tiao
npm install
node index.js
```

### Tests
```bash
npm run test:smoke
npm test
```

### Docker run
```bash
docker build -t tiao .
docker run -d --env-file .env -p 8080:8080 --name tiao tiao
```

## Required Environment Variables

Core:
- `WHITELISTED_NUMBERS`
- `ADMIN_NUMBERS`
- `GCLOUD_PROJECT_ID`
- `GOOGLE_MAPS_API_KEY`
- `API_EMAIL`
- `API_PASSWORD`

Twilio:
- `TWILIO_ACCOUNT_SID`
- `TWILIO_AUTH_TOKEN`
- `TWILIO_WHATSAPP_NUMBER`
- `PUBLIC_BASE_URL`

Climate reference (if enabled):
- `CLIMATE_REFERENCE_URL` (or equivalent configured URL)
- `CLIMATE_REFERENCE_AUTH_SECRET` (when protected endpoint is used)

## Common Failure Checklist

### 1) Twilio webhook not receiving messages
- Confirm Twilio webhook points to:
  - `POST https://<PUBLIC_BASE_URL>/twilio/webhook`
- Check service exposure and ingress routes.
- Validate `TWILIO_AUTH_TOKEN` and signature verification logic.

### 2) Twilio replies failing or truncated
- Confirm message chunking is active for long responses.
- Check logs for 4xx/5xx from Twilio API.
- Verify `TWILIO_WHATSAPP_NUMBER` and sender format.

### 3) Agent responses inconsistent or routing wrong
- Verify router prompt/config in `prompts/`.
- Confirm session manager behavior (timeouts/resets).
- Validate user role filtering (admin vs standard).

### 4) Climate reference document not loading
- Confirm URL is reachable from runtime environment.
- If protected, verify auth secret env is set and correct.
- Check cache behavior and fetch-size logs.

### 5) Ingress/DNS issues
- Validate `ingress.yaml` host and class values.
- Confirm static IP binding if required (`tiao-ingress-ip`).
- Check DNS points to current ingress IP.

## Working Policy
- Default integrations/debug should target staging unless explicitly told otherwise.
- Do not mix unrelated ops and agent logic changes in one commit.
