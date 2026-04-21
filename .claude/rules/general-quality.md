---
paths:
  - "**/*"
---

# Universal Code Quality Standards

These standards apply to all code in every project. They are the immutable baseline — even if `.claude/CLAUDE.md` is customized per project, these rules persist.

## Error Handling

- All errors must be handled explicitly. Never swallow errors silently.
- Log errors with sufficient context: what operation, what input, what failed.
- Use structured error types/classes appropriate to the language.

## Code Hygiene

- No TODO comments without a ticket reference (e.g., `TODO(PROJ-123): ...`).
- No commented-out code in commits. Delete it; version control remembers.
- No magic numbers — use named constants with descriptive names.

## Function Design

- Each function has a single, clear responsibility.
- Functions must stay under 50 lines.
- Prefer composition over inheritance.

## Configuration & Secrets

- No hardcoded secrets, credentials, API keys, or environment-specific values.
- All sensitive configuration comes from environment variables or secret managers.
- All environment-specific values (URLs, ports, feature flags) come from config, never inline.

## File Size

- Files must not exceed 500 lines. Extract modules when approaching this limit.
