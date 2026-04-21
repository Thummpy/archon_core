# Examples Directory

This directory is the AI agent's **style guide through concrete code**. When writing new code, the agent pattern-matches against examples here to maintain consistency across the project.

## Structure

```
.claude/examples/
├── patterns/              # Annotated code snippets showing approved approaches
│   ├── python-expression-style.md
│   ├── error-handling.md
│   ├── logging.md
│   ├── api-endpoint.md
│   ├── database-query.md
│   ├── test-unit.md
│   └── test-integration.md
└── reference-implementations/
    └── _README.md         # Starts empty; populated during project init
```

## `patterns/`

Short, focused examples demonstrating a single approved pattern. Each file contains:

1. **Header** — what pattern this demonstrates and when to use it
2. **Code** — minimal Python examples with inline annotations
3. **Rationale** — why this pattern, not an alternative

Pattern files contain Python examples matching the project's dense, typed style (see `python-expression-style.md` for the canonical reference).

## `reference-implementations/`

Complete working examples demonstrating the project's architecture patterns end-to-end. This folder ships empty and is populated during project initialization with at least one example covering a full stack slice (API → logic → data → tests).

See `reference-implementations/_README.md` for guidelines on what makes a good reference implementation.

## Maintenance Rules

- **Update examples when standards change.** Stale examples cause drift.
- **Remove examples for deprecated patterns.** Dead examples are worse than no examples.
- **Keep examples minimal.** Show the pattern, not a full feature. If an example exceeds 200 lines, it probably belongs in `reference-implementations/`.
- **Annotate the why.** Code shows the what; comments must explain why this approach was chosen over alternatives.
- **One pattern per file.** Do not combine unrelated patterns in a single example.
