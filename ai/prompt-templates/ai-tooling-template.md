# AI Tooling Creation Template

Use this template whenever you are asked to build or document a new AI tooling. It keeps the scope focused on the user’s workflow, clarifies the environment, and captures how to validate the result.

## 1. Tooling Overview
- **Name:** (Proposed tool name)
- **Primary purpose:** What user goal it solves
- **Key capabilities:** List the high-level features (e.g., control Spotify playback, summarize PR review comments)
- **Trigger phrases:** User requests that should signal this tooling

## 2. Environment & Dependencies
- **Location:** Where the tooling lives (e.g., `~/dotfiles/ai/tooling/<tooling-name>/`)
- **Entry point:** Script name, CLI, or workflow file
- **Dependencies:** GitHub CLI, npm packages, model preferences, etc.
- **Symlinks:** Mention any workspace symlinks that must exist

## 3. Inputs & Outputs
- **Inputs:** CLI arguments, environment variables, user instructions, repo context
- **Outputs:** Files created/edited, console messages, final response text
- **Validation:** How you confirm success (e.g., running `npm run control -- status` or verifying `gh pr list` output)

## 4. Step-by-step Plan
1. (Setup directories or tool files)
2. (Implement functionality)
3. (Test with representative commands)
4. (Document how to use it)

## 5. Post-work Notes
- **README location:** Where to store usage instructions
- **Index updates:** Mention if `~/dotfiles/ai/guidelines/README.md` needs a new link
- **Future ideas:** Painted scope for additional subcommands or integrations
