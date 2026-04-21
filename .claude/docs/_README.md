# Tier 3 Docs — On-Demand Reference Material

Files in this directory are **never auto-loaded**. They are Tier 3 context — heavy reference documentation consulted only when needed, keeping the main context window lean.

## How It Works: The Scout Pattern

When a task might benefit from deep reference material, a sub-agent (scout) reads **only the header block** of candidate docs to decide relevance. If relevant, the scout loads the full document and returns a summary. The main session never sees the full document unless it's needed.

This keeps 1,000+ lines of reference material out of the context window entirely.

## Required Header Block

Every doc file must start with a structured header so scouts can evaluate relevance without loading the full content:

```markdown
---
title: "Client API v2 Reference"
purpose: "Complete endpoint reference for the client's REST API including auth, pagination, and error codes"
when_to_consult: "When implementing or modifying any API integration with the client system"
---
```

The `when_to_consult` field is critical — it tells the scout under what circumstances this document is worth loading.

## When to Use Docs vs. Rules

| Use `.claude/rules/` when... | Use `.claude/docs/` when... |
|---|---|
| Content is under 200 lines | Content exceeds 200 lines |
| It's an actionable convention or standard | It's reference material to look things up in |
| It applies every time a matching file is touched | It's needed only for specific tasks |
| It fits in context without crowding other work | Loading it would displace useful context |

Rule of thumb: if the content is a set of rules to follow, it belongs in `rules/`. If it's a reference you consult when stuck or implementing something specific, it belongs here.

## Examples of Appropriate Content

- **Client API reference** — endpoint details, auth flows, rate limits, error codes
- **Data model documentation** — entity relationships, field constraints, migration history
- **Domain-specific requirements** — rules, constraints, or policies specific to the project's domain
- **Complex library usage guides** — non-obvious configuration, known pitfalls, version-specific behavior
- **Infrastructure runbooks** — deployment procedures, incident response, environment details

## File Naming

Use descriptive, lowercase names: `client-api-v2.md`, `data-model-reference.md`, `domain-requirements.md`. The name should make the document's scope obvious without opening it.

## Guidelines

- Keep each doc focused on one domain. Split large documents by topic.
- Always include the YAML header block — docs without headers cannot be scouted.
- Update docs when the underlying systems change. Stale reference material is worse than none.
- If a doc shrinks below 200 lines and contains actionable conventions, consider moving it to `rules/` instead.
