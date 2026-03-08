# Guidelines Index

This folder is a lightweight directory that points you toward the actual documentation inside each tooling or policy folder. Don’t duplicate instructions here; use the READMEs that live alongside the tooling.

## Quick jump list
- **General workspace instructions** — read `GENERAL_INSTRUCTIONS.md` for the mandatory session/subagent checklist, navigation hints, and the updated role of the dotfiles tree.
- **Spotify control** — see `~/dotfiles/ai/tooling/spotify-control/README.md` for auth, status checks, and playback commands. Always run the tooling before answering Spotify requests.
- **GitHub workflows** — see `~/dotfiles/ai/tooling/github-workflows/README.md` for examples of `github-workflow.sh` subcommands. Expand that README whenever you add new capabilities.
- **Routing policy** — see `~/dotfiles/ai/routing-policy.md` (already symlinked at `/home/abacha/.openclaw/workspace/routing-policy.md`). That is the single source of routing rules, channel formatting, and escalation.
- **Tool catalog** — browse `~/dotfiles/ai/tooling/` directly for other tooling READMEs; add new entries there and link to them from this index when necessary.

## Project documentation
- Always start by reading the `overview.md` of the project you are working on. These are located in `~/dotfiles/ai/projects/`:
    - **Nexus Recall** — `~/dotfiles/ai/projects/nexus-recall/overview.md`
    - **Hubstaff Server** — `~/dotfiles/ai/projects/hubstaff-server/overview.md`
    - **AIOMA** — `~/dotfiles/ai/projects/aioma/overview.md`
    - **Climate Risk Analysis** — `~/dotfiles/ai/projects/climate-risk-analysis/overview.md`
    - **Trag-Web** — `~/dotfiles/ai/projects/trag-web/overview.md`
    - **Chess Memory Tester** — `~/dotfiles/ai/projects/chess_memory_tester/overview.md`
    - **Tiao** — `~/dotfiles/ai/projects/tiao/overview.md`

When new tooling or policies appear, add a single row above that references the canonical README path. Keep this file focused on navigation rather than repeating behavior guidance.
