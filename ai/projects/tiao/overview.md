# Tiao — Overview & Hotspots
> Project path: `~/projects/trag/tiao`

## Goal
Maintain the WhatsApp bot for TRAG (climate + insurance conversational agents).

## Core Guidelines & Product Rules
1. **Language Quality:** Keep Portuguese (PT-BR) conversational quality high; avoid robotic responses.
2. **Role Security:** Preserve strict role-based behavior.
   - Admins: Full capabilities + CLI route.
   - Standard users: Specialized agents only.
3. **Session Stability:** Respect session continuity and timeouts.
4. **Transport Constraints:** Respect Twilio message size limits (chunking) and formatting.
5. **Security:** Maintain safe webhook handling (signature validation + payload limits).

## Critical Areas & Hotspots
Focus attention here when debugging or refactoring:
- **Twilio Migration:** Stability and chunking logic (`src/services/twilio-service.js`, `message-handler.js`).
- **Climate Reference:** Doc fetch flow, auth, and caching (`src/services/climate-reference.js`).
- **Agent Output:** API list formatting and fallback removal (`src/agents/climate-agent.js`).
- **Ops:** Ingress/domain config (`tiao.trag.agr.br`, static IP).

## Reference: Environment Variables
- **Core:** `WHITELISTED_NUMBERS`, `ADMIN_NUMBERS`, `GCLOUD_PROJECT_ID`, `GOOGLE_MAPS_API_KEY`, `API_EMAIL`, `API_PASSWORD`
- **Twilio:** `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_WHATSAPP_NUMBER`, `PUBLIC_BASE_URL`
## Related Documentation
- [development.md](./development.md): Setup, webhook testing, and deployment guide.
