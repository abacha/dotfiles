# GitHub Workflows Tooling

Use `github-workflow.sh` for common GitHub tasks:

* `github-workflow.sh prs list-mine` — list your open PRs. Uses `gh api search/issues` for user-based results.
* `github-workflow.sh comments list-unresolved <repo> <pr>` — displays reviews in the `CHANGES_REQUESTED` state with cleaned bodies.

If you add commands for issues, CI, or other workflows, update this README with descriptions and examples. The CLI parser uses categories (`prs`, `comments`, `issues`, `ci`) so follow that pattern.
