# AI Config

Central directory for all AI/agent settings.

## Structure
- `routing-policy.md` — global model routing and escalation rules
- `conventions/global-rules.md` — global behavior rules
- `prompt-templates/` — reusable task prompts
- `models/` — model-specific notes and defaults
- `tooling/` — tool-specific conventions and runbooks
- `projects/<project>/rules.md` — project-specific rules

## Current Project Rules
- `projects/aioma/rules.md`
- `projects/chess_memory_tester/rules.md`
- `projects/climate-risk-analysis/rules.md`
- `projects/hubstaff-server/rules.md`
- `projects/trag-web/rules.md`
- `projects/tiao/rules.md`

## Usage
- Keep this as the source of truth.
- Global defaults in root structure.
- Project overrides only under `projects/`.
- Tool integrations use symlink-based auto-apply to `~/dotfiles/ai`.
