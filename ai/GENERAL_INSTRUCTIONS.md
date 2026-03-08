# GENERAL_INSTRUCTIONS.md

## Purpose
Workspace-level checklist and navigation guide for all sessions and subagents.

## Startup checklist (run before any task)
1. Read `AGENTS.md`.
2. Read `SOUL.md`.
3. Read `USER.md`.
4. Read `GENERAL_INSTRUCTIONS.md`.
5. Read `guidelines/README.md`.
6. Read `memory/YYYY-MM-DD.md` for today and yesterday.
7. If in main session (direct human chat), also read `MEMORY.md`.

For subagents: follow the Subagent Spawn Policy in `AGENTS.md` (including sending the short “rules understood” summary and continuing in the same run).

## Documentation navigation
- `GENERAL_INSTRUCTIONS.md`: global checklist + workflow rules.
- `guidelines/README.md`: index to detailed guides.
- `prompt-templates/`: canonical folder for reusable prompt templates.
- Detailed instructions should live in their own canonical docs; this file should stay short.

## Scope boundaries
- Put general, cross-project instructions in this workspace.
- Project-specific guidelines are located in `~/dotfiles/ai/projects/<name>/`. Always start by reading `overview.md`, which provides the primary project context and references sibling files (like `development.md` or `api.md`) as needed.
- Treat the project's `overview.md` as a mandatory pre-read before starting work on that project.
- Keep `~/dotfiles/ai/` focused on project/tooling specifics, not global policy.

## Maintenance rules
- Avoid duplicate instructions across multiple files.
- Add new global rules here and add/update one pointer in `guidelines/README.md`.
- Keep this document stateless and evergreen (no migration/change-log language).

## Output rule (mandatory)
Every response must include a visible model tag in square brackets (example: `[gpt-codex]`).
Subagents follow the same rule.