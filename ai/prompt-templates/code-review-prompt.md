# Code Review Prompt Template

## Context
You are performing a strict code review.  
Repository: {{repo}}  
Branch/PR: {{branch_or_pr}}  
Scope: {{scope}}  
Language/stack: {{stack}}

## Review Goals
1. Find correctness bugs and regressions
2. Identify security risks
3. Check performance risks
4. Check maintainability/readability
5. Validate tests and coverage for changed behavior

## What to Review
- Diff: {{diff_or_files}}
- Relevant requirements/spec: {{requirements}}
- Runtime constraints: {{constraints}}

## Review Rules
- Be objective and direct
- Prioritize high-impact issues
- Do not suggest speculative refactors outside scope
- For each issue, include:
  - Severity: Critical / High / Medium / Low
  - File + line(s)
  - Why this is a problem
  - Concrete fix suggestion

## Output Format

### Summary
- Overall risk: {{low|medium|high}}
- Merge recommendation: {{approve|request_changes|block}}

### Findings
1. [Severity] Title
   - Location: file:line
   - Problem:
   - Impact:
   - Suggested fix:

(repeat)

### Tests/Validation
- Missing tests:
- Flaky/risky tests:
- Suggested test cases:

### Nice-to-have (optional)
- Minor improvements within scope only.
