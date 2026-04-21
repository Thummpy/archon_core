---
paths:
  - "**/*.md"
  - "**/README*"
---

# Documentation Standards

## README Files

Every README includes at minimum:

- **Purpose** — what this module/service/directory does and why it exists.
- **Setup** — how to get it running locally.
- **Usage** — primary commands or API surface.

## Architecture Decision Records

Use the ADR template at `.claude/docs/adr/_template.md` for any significant architectural decision. An ADR is warranted when the decision affects multiple components, is hard to reverse, or involves trade-offs the team should understand.

## Inline Comments

- Comments explain **WHY**, not **WHAT**. The code shows what; comments explain the reasoning.
- Docstrings only when domain context is non-obvious. A well-typed signature is self-documenting. When a docstring is warranted, explain WHY, not WHAT.
- Do not describe obvious code. Comment on non-obvious intent, constraints, or gotchas.

## API Documentation

- Every endpoint is documented with: HTTP method, path, request format, response format, error codes.
- Include at least one request/response example per endpoint.
- Document authentication requirements and rate limits where applicable.
