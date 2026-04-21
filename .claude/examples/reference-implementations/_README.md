# Reference Implementations

This folder starts empty. It is populated during project initialization with at least one complete, working example that demonstrates the project's architecture patterns end-to-end.

## What Belongs Here

A reference implementation is a small but complete vertical slice: a single feature that exercises every layer of the stack (API → business logic → data access → tests). The AI agent uses it as a template when building new features.

## Guidelines

- **Under 500 lines total** across all files in the implementation
- **Self-contained** — the example should be understandable without reading the rest of the codebase
- **Full stack slice** — cover the path from request to response to persistence to test
- **Annotated** — comments explain architectural choices, not just what the code does
- **Working** — the example must pass its own tests; a broken reference is worse than none

## Suggested Structure

```
reference-implementations/
└── feature-name/
    ├── README.md           # What this demonstrates, how to run it
    ├── handler.*           # API/entry layer
    ├── service.*           # Business logic layer
    ├── repository.*        # Data access layer
    └── tests/
        ├── test_unit.*     # Unit tests for service logic
        └── test_integration.*  # Integration tests through API
```

## When to Add One

- **During project init** — create at least one reference that matches your stack
- **When introducing a new architectural pattern** — a reference implementation is the most effective way to propagate it
- **When onboarding new team members** — point them here before the full codebase

## When NOT to Add One

- Do not add a reference for every feature — this is a style guide, not a mirror of the codebase
- Do not let references go stale — if the architecture changes, update or remove them
