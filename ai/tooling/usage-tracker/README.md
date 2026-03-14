# Usage Tracker

Tools for checking Claude Code and OpenAI Codex usage from the workspace.

## ai-usage-tracker.sh

- **Purpose:** replicates CodexBar by refreshing Claude OAuth tokens and hitting the hidden usage endpoint, plus reading Codex auth mode.
- **Requirements:** `curl`, `jq`, `date` (GNU or BSD).
- **Credentials:**
  - Claude: expects `~/.claude/.credentials.json` with `claudeAiOauth.refreshToken`.
  - Codex: expects `~/.codex/auth.json`.
- **Usage:**
  1. `cd ~/workspace/tooling/usage-tracker`
  2. Run `bash ai-usage-tracker.sh`
  3. Script prints current 5h/7d Claude utilization and Codex auth mode notes.

Handle the refreshed Claude OAuth tokens carefully—the script writes them back to `~/.claude/.credentials.json` to keep the CLI logged in.
