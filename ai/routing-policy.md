# Model Routing Policy (Token-Aware)

Priority by budget:
1. Gemini
2. OpenAI/Codex
3. Claude Code

## Operational Routing Stack
1. **Primary (in-chat)** — `claude-sonnet` handles general questions, doc summaries, and sensitive responses. Every reply begins with `[claude-sonnet]` unless another model is explicitly requested or triggered.
2. **Heavy Programming / Automation** — spawn a subagent running `gemini-pro` (tag `[gemini-pro]`) when the prompt requests code changes, scripts, debugging, or technical review. The subagent works inside the relevant repo/project and returns a summary + diff.
3. **Heartbeats / Quick Checks** — use `gemini-2.0-flash` (tag `[gemini-2.0-flash]`) for polling, reminders, or lightweight yes/no status checks.
4. **Opus Fallback** — only when instructed explicitly ("use Opus") run `claude-opus` with tag `[claude-opus]` for multimodal or conversational flows.

## Detailed Recommendations by Activity
| Task Type | Recommended Model | Notes |
| --- | --- | --- |
| Quick summaries / doc reading | `gemini-2.0-flash` | For immediate decisions and short excerpt summaries. |
| Brainstorming / Planning | `gemini-pro` | Maintains multiple ideas with consistency. |
| Heavy Coding / Review | `gpt-codex` or `gemini-pro` | Use Gemini subagent for isolation; otherwise, gpt-codex for tests. |
| Creativity / Storytelling | `claude-sonnet` or `gemini-2.5-flash` | Claude delivers smooth tone; Gemini gives short bursts of energy. |
| High Precision / Math | `gpt-codex` | Better reasoning and numerical accuracy. |
| Fast Tasks (commands, WhatsApp) | `gpt-mini` or `gemini-2.0-flash` | Use the lightest model that resolves the issue. |

## Cache and Transparency
- Keep the last 5–10 prompts in cache and mention when reusing context ("using cache from last heartbeat").
- Always inform the model before responding (e.g., "I'll use [claude-sonnet] for this").
- When a subagent is triggered, log the warning and the result.

## Default Routing (Legacy)
- **Gemini first:** discovery, brainstorming, summarization, doc digestion, option comparison.
- **Codex second:** implementation, code edits, tests, refactors, bug fixes.
- **Claude third:** targeted deep review for risky/critical changes only.

## Escalation Rules
- Start with Gemini unless code changes are required.
- Move to Codex when files must change or commands/tests must run.
- Use Claude only when one of these is true:
  - security-sensitive change
  - architecture-level refactor
  - high-blast-radius production change
  - Codex output is uncertain/conflicted

## Cost Control
- Do not run all 3 on the same task by default.
- Max pattern: 1 implementer + 1 reviewer.
- Keep prompts short with explicit scope and acceptance criteria.

## Standard Task Pipeline
1. Gemini: clarify scope + produce execution plan.
2. Codex: implement and run checks.
3. Claude (optional): review diff and flag risks.
4. Final: concise merge recommendation.
