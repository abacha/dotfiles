# AI Config

Central directory that explains what each AI folder is for and where to look next.

## Folder Roles
- `guidelines/` — lightweight index listing every tooling or policy doc; does **not** duplicate content. Open it when you need to know “which directory holds the answer.”
- `routing-policy.md` — global model routing, escalation, and channel-specific behavior (keep this linked in guideline indexes).
- `conventions/` — tone, formatting, and general behavior rules that apply across all interactions.
- `prompt-templates/` — reusable prompt patterns for orchestrating multi-step workflows.
- `models/` — model-specific notes, overrides, and preference summaries (when you need to choose or tune Gemini vs Codex, read here).
- `tooling/` — each tool has its own folder; keep the instructions inside that folder (README per tooling) and refer to them via `guidelines/README.md`.
- `projects/<project>/rules.md` — project-specific overrides that only apply when working inside that project.

## How to navigate
1. Start from `guidelines/README.md` to find the tooling link you need (e.g., Spotify control, GitHub workflow).
2. Follow the pointer to the specific tooling folder inside `tooling/` or the policy file (`routing-policy.md`).
3. When unsure about tone/format, check `conventions/`; when you need a prompt pattern, open `prompt-templates/`.
4. If you touch a tool or policy, update its own README instead of writing a new one under `guidelines/`.

## Current projects with rules
- `projects/aioma/rules.md`
- `projects/chess_memory_tester/rules.md`
- `projects/climate-risk-analysis/rules.md`
- `projects/hubstaff-server/rules.md`
- `projects/trag-web/rules.md`
- `projects/tiao/rules.md`
