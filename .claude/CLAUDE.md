# {{PROJECT_NAME}}

<!-- Replace {{PROJECT_NAME}} with the actual project name during initialization. -->

{{PROJECT_DESCRIPTION}}

<!-- Replace {{PROJECT_DESCRIPTION}} with a 1-2 sentence summary of what this project does. -->

## Read These First

Before starting any work:

1. Read `.claude/PLANNING.md` for architecture, constraints, and design decisions.
2. Run `gh issue list --state open` for current work items and backlog.
3. If `.claude/HANDOFF.md` has content, read it — a previous session left context for you.

## Tech Stack

<!-- Replace {{TECH_STACK}} with the project's languages, frameworks, databases, and infrastructure. -->

{{TECH_STACK}}

## Project Structure

<!-- Replace {{PROJECT_STRUCTURE}} with the actual directory layout after initialization. -->

```
{{PROJECT_STRUCTURE}}
```

## DLC
The development lifecycle intended, per github issue. New threads automatically pull general information and handoff at the start.

**OPTIONAL** `/prime-` — primes context with focused notes reguarding one root level folder
**OPTIONAL** `/research` — iterative pre-plan research to build shared understanding before planning
1. `/plan-feature` — research and write a PRP (implementation plan)
2. `/execute` — implement the PRP step-by-step, then prompts `/review`
3. `/review` — self-review against standards, then prompts `/commit-close`
4. `/commit-close` — terminal step: handoff, commit, push, PR, and close issue
**OPTIONAL** `/handoff` — save session state mid-session when context is heavy but task is not done
**OPTIONAL** `/init-subsystem` — IF distinct subsystem built or expanded this session, creates focused read-in context. SCOPE: folder of same name at root level

## Coding Standards

These are universal standards. They apply to every file in every project.

### File & Function Size

- Files must not exceed 500 lines. Extract modules when approaching this limit.
- Functions must stay under 50 lines. Each function has a single, clear responsibility.

### Security

- No hardcoded secrets, credentials, API keys, or environment-specific values. Ever.
- All sensitive configuration comes from environment variables or secret managers.

### Error Handling

- All errors must be handled explicitly. Never swallow errors silently.
- Log errors with sufficient context for debugging (what operation, what input, what failed).
- Use structured error types/classes appropriate to the language.

### Logging

- Use structured logging (key-value pairs), not print statements or string interpolation.
- Include correlation/request IDs where applicable.
- Never log PII, credentials, or full request/response bodies in production.

### Documentation

- Docstrings only when domain context is non-obvious — a well-typed signature documents itself. When a docstring is warranted, explain WHY, not WHAT.
- Comments explain WHY, not WHAT. The code shows what; comments explain the reasoning.

### Code Quality

- Prefer composition over inheritance.
- No magic numbers — use named constants.
- No commented-out code in commits.
- No TODO comments without a ticket reference (e.g., `TODO(PROJ-123): ...`).

## Testing Standards

Every test file follows the expected/edge/failure pattern:

1. **Expected cases** — the happy path works correctly.
2. **Edge cases** — boundary values, empty inputs, large inputs, concurrent access.
3. **Failure cases** — invalid input is rejected, errors propagate correctly, dependencies failing is handled.

Test structure uses Arrange/Act/Assert (AAA):

```
// Arrange: set up test data and dependencies
// Act: call the function under test
// Assert: verify the result
```

Additional rules:

- Test names describe behavior, not method names. `test_returns_empty_list_when_no_results` not `test_get_results`.
- Each test tests one thing.
- Mock external dependencies, not internal logic.
- Tests must be deterministic — no flaky tests.
- No test interdependencies — each test runs in isolation.

## Task Completion Protocol

After completing any task:

1. Run `/commit-close` — this validates, commits, writes handoff, pushes, creates a PR, and closes the associated issue. Use `/commit-close --skip-validate` to bypass validation for WIP or documentation-only commits.

## AI Behavior Rules

- Never assume missing context. If information is needed and not available, ask.
- Never hallucinate dependencies, APIs, or configuration. Verify they exist first.
- Never overwrite a file without reading it first.
- Never guess on ambiguous requirements. Ask for clarification.
- Read existing code before proposing changes. Understand, then modify.
- When exploring unfamiliar parts of the codebase, use sub-agents to keep the main context clean.
- Prefer minimal, focused changes over broad refactors unless explicitly asked.

## Available Commands

| Command | Purpose |
|---------|---------|
| `/init` | Read `.claude/project_seed.md` and populate all template files |
| `/research` | Iterative pre-plan research to resolve unknowns before planning |
| `/plan-feature` | Research codebase and generate a PRP for a new feature |
| `/execute` | Implement a PRP step-by-step with validation |
| `/handoff` | Save session progress to .claude/HANDOFF.md for the next session |
| `/commit-close` | Full lifecycle close: validate, commit, handoff, push, create PR, and close issue (`--skip-validate` to bypass validation) |
| `/compact` | Compress context for long-running sessions |
| `/review` | Self-review changes against standards before committing |
| `/init-subsystem` | Generate a prime command for a specific subsystem |
| `/bootstrap` | Plan infrastructure and initial tasks, create GitHub Issues |

## Workflow

<!-- Replace {{WORKFLOW}} with the team's issue tracking and branching workflow.
     Examples: GitHub Issues, Jira, Linear; branch naming; how to reference tickets in commits;
     how to move issues through statuses (in progress, review, done). -->

{{WORKFLOW}}

## Naming Conventions

<!-- Replace {{NAMING_CONVENTIONS}} with project-specific naming rules for files, classes,
     functions, constants, and variables. These are language/framework dependent.
     Examples: snake_case for Python files, PascalCase for React components. -->

{{NAMING_CONVENTIONS}}

## Project-Specific Conventions

<!-- Replace {{PROJECT_CONVENTIONS}} with any additional project-specific patterns,
     architectural rules, or standards not covered by the sections above.
     Examples: API versioning strategy, state management approach, data access patterns. -->

{{PROJECT_CONVENTIONS}}
