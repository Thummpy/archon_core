# Review

Self-review changes against project standards before committing.

## Instructions

### Step 1 — Understand Intent

Read these to understand what the changes are supposed to accomplish:

1. Run `gh issue list --state open` to check for active work items.
2. Check `.claude/prps/` for a relevant PRP if one exists.
3. If neither provides context, infer intent from the changes themselves.

### Step 2 — Gather Changes

Run `git diff` and `git diff --cached` to collect all staged and unstaged changes since the last commit.

If a specific commit range is relevant, use `git diff <range>` instead.

### Step 3 — Check Against Standards

Review every changed file against the following checklists. Use sub-agents to parallelize reviews across files.

**Coding Standards** (from `.claude/CLAUDE.md`):
- [ ] Files under 500 lines
- [ ] Functions under 50 lines, single responsibility
- [ ] No hardcoded secrets, credentials, or environment-specific values
- [ ] Errors handled explicitly, never swallowed
- [ ] Structured logging, no print statements
- [ ] Public functions have docstrings/JSDoc
- [ ] No magic numbers — named constants used
- [ ] No commented-out code
- [ ] No TODOs without ticket references

**Rule Compliance** (from `.claude/rules/`):
- Read the rule files whose `paths:` patterns match the changed files.
- Verify each changed file complies with the applicable rules.

**Pattern Compliance** (from `.claude/examples/patterns/`):
- If the changes involve error handling, logging, API endpoints, database queries, or tests, check the relevant pattern file.
- Flag deviations from approved patterns.

**Security**:
- [ ] No secrets, API keys, or credentials in code or config
- [ ] No SQL injection vectors (parameterized queries used)
- [ ] No XSS vectors (user input escaped/sanitized)
- [ ] Authentication and authorization checks present where required
- [ ] Sensitive data not logged or exposed in error messages

**Error Handling**:
- [ ] All error paths handled
- [ ] Errors logged with sufficient context
- [ ] External failures handled gracefully (timeouts, retries, fallbacks)

**Test Coverage**:
- [ ] New code has corresponding tests
- [ ] Tests cover expected, edge, and failure cases
- [ ] Modified code has updated tests if behavior changed

### Step 4 — Output Review Report

Structure the report as:

```
## Review: {summary of what was reviewed}

### PASS
- item (file:line — what was verified)

### WARN
- item (file:line — suggestion and why)

### FAIL
- item (file:line — what must be fixed and how)
```

**PASS** — Meets standards, no action needed.
**WARN** — Suggestions for improvement, not blocking.
**FAIL** — Must be fixed before committing. Include a specific fix suggestion for each.

### Step 5 — Summary

Report the counts: X pass, Y warnings, Z failures.

If there are FAIL items, do not suggest committing. List the fixes needed.
If all items pass (with optional warnings), indicate the changes are ready for `/commit-close`.
