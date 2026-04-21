# Tier 2 Rules — Auto-Loaded by File Path

Rule files in this directory are **automatically loaded by Claude Code** when you work on files matching their `paths:` patterns. They provide targeted conventions without bloating the always-loaded `.claude/CLAUDE.md`.

## How It Works

Each rule file starts with YAML frontmatter containing glob patterns:

```yaml
---
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/tests/**"
---
```

When Claude Code opens or edits a file matching any listed pattern, the rule file's contents are loaded into context automatically. No slash command or manual loading needed.

## When to Create a Rule File vs. Adding to .claude/CLAUDE.md

**Add to `.claude/CLAUDE.md`** when the rule applies to **every file in the project** — universal standards like file size limits, error handling policy, or commit conventions.

**Create a rule file** when the rule applies only to **specific file types or directories** — testing conventions, frontend patterns, infrastructure standards, API design rules.

Rule of thumb: if the convention is irrelevant when working on unrelated files, it belongs in a rule file scoped to the relevant paths.

## File Naming

Use descriptive, lowercase names: `testing.md`, `infrastructure.md`, `api-design.md`, `data-pipeline.md`. The name should make it obvious what conventions the file contains without opening it.

## Minimal Example

```markdown
---
paths:
  - "**/api/**"
  - "**/routes/**"
---

# API Conventions

- All endpoints return structured JSON responses with `data`, `error`, and `meta` fields.
- Validate request input at the handler boundary before passing to business logic.
- Return appropriate HTTP status codes — do not use 200 for errors.
```

## Guidelines

- Keep rule files focused. One domain per file.
- Avoid duplicating content from `.claude/CLAUDE.md` — reference it instead. Exception: `general-quality.md` and `testing.md` intentionally mirror `.claude/CLAUDE.md` as an immutable baseline. `.claude/CLAUDE.md` is regenerated per project and may be incomplete; these rule files are not modified during initialization and serve as a safety net.
- Use glob patterns that match your actual project structure.
- If a rule file exceeds 200 lines, consider moving the detailed reference material to `.claude/docs/` and keeping only the actionable rules here.
