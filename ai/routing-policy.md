# Model Routing Policy (Token-Aware)

Priority by budget:
1. Gemini
2. OpenAI/Codex
3. Claude Code

## Default Routing
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
