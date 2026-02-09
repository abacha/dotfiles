## Approval Preferences (global)

- Default to no approval for routine read/edit commands inside the workspace.
- Ask for approval only on potentially destructive or sensitive actions: `rm`/deletions, `git commit`/`push`/force operations, resets, mass moves, or commands that write outside the workspace.
- Treat network access and external directories as allowed by default; only ask if a command is high-risk/destructive or explicitly blocked.
- Request approval only when a command requires escalated permissions (e.g., `sudo`) or sandbox restrictions block a needed command.
- Otherwise proceed without prompting; surface a short justification only when asking for approval.
- Never commit without explicit approval
