## Approval Preferences (global)

- Default to no approval for routine read/edit commands inside the workspace.
- Ask for approval only on potentially destructive or sensitive actions: `rm`/deletions, `git commit`/`push`/force operations, resets, mass moves, or commands that write outside the workspace.
- Treat network access and external directories as allowed by default; only ask if a command is high-risk/destructive or explicitly blocked.
- Request approval only when a command requires escalated permissions (e.g., `sudo`) or sandbox restrictions block a needed command.
- Otherwise proceed without prompting; surface a short justification only when asking for approval.
- Never commit without explicit approval

## Project-Specific Agent Instructions

- Check `~/dotfiles/ai/projects/` for project-specific instructions when working in a repository.
- Match the current project to the corresponding rules file and follow its guidelines for build commands, coding style, testing conventions, and commit/PR standards.

## Routing & Review Guardrails

- Always load and follow `~/dotfiles/ai/routing-policy.md` before model/task routing.
- For deep/thorough code review requests, delegate review to Claude first.
- Do not deviate from these routing/review guardrails unless explicitly instructed by the user.
