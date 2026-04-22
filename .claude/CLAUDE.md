# archon-setup

Wrapper repository for a version-pinned local Archon installation with custom workflows, OAuth authentication, portable data via host-path volumes, and team-friendly documentation for developers with minimal Docker experience.

## Read These First

Before starting any work:

1. Read `.claude/PLANNING.md` for architecture, constraints, and design decisions.
2. Run `gh issue list --state open` for current work items and backlog.
3. If `.claude/HANDOFF.md` has content, read it — a previous session left context for you.

## Tech Stack

- **Language:** Bash (scripts), YAML (Docker Compose, workflow definitions), Markdown (command files, documentation)
- **Framework:** Docker Compose v2 (container orchestration)
- **Database:** SQLite (Archon's default, zero config, stored at `~/archon-data/archon.db`)
- **Infrastructure:** Docker, Docker Compose — local only
- **Tools:** `claude` CLI (OAuth token generation), `rclone` (cross-machine sync), `gh` CLI (optional, GitHub integration), `jq` (optional, JSON processing)

## Project Structure

```
archon-setup/
├── docker-compose.yml          # Pinned Archon image, host-path volume, optional Postgres profile
├── .env.example                # Template: CLAUDE_CODE_OAUTH_TOKEN, PORT, RCLONE_REMOTE
├── .archon/
│   ├── config.yaml             # Archon configuration overrides
│   ├── workflows/              # Custom workflow YAML files (shared via git)
│   │   ├── atyeti-pev.yaml     # Standard Plan-Execute-Validate workflow
│   │   └── ...
│   └── commands/               # Custom command Markdown files (shared via git)
│       ├── plan.md
│       ├── execute.md
│       ├── review.md
│       └── ...
├── scripts/
│   ├── setup-oauth.sh          # Install claude CLI if needed, run setup-token, write to .env
│   ├── sync-up.sh              # docker compose down → rclone sync ~/archon-data → remote
│   ├── sync-down.sh            # rclone sync remote → ~/archon-data → docker compose up
│   ├── upgrade.sh              # Backup DB → bump tag → pull → restart → validate health
│   ├── backup.sh               # Copy ~/archon-data/archon.db to backups/ with timestamp
│   └── health.sh               # Check container status + /api/health endpoint
├── backups/                    # .gitignore'd — timestamped SQLite backups
├── docs/
│   ├── SETUP.md                # Step-by-step first-time setup (Docker install → running Archon)
│   ├── DAILY-USE.md            # Running workflows, checking status, using Web UI
│   ├── SHARING-WORKFLOWS.md    # git pull → docker compose restart to get new workflows
│   ├── SYNC-BETWEEN-MACHINES.md # rclone setup, sync-up, sync-down, gotchas
│   ├── UPGRADING.md            # Version bump procedure with backup safety
│   └── TROUBLESHOOTING.md      # Common errors and fixes
├── .gitignore                  # .env, backups/
└── README.md                   # Quick-start pointing to docs/SETUP.md
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

GitHub Issues with labels: `ops`, `workflow`, `docs`, `upgrade`. GitHub Flow: feature branches off `main`, PR required, squash merge.

## Naming Conventions

- **Script files:** lowercase-with-hyphens (e.g., `setup-oauth.sh`, `sync-up.sh`)
- **Shell functions:** `lower_snake_case` (e.g., `check_docker`, `run_backup`)
- **Shell variables (local):** `lower_snake_case`
- **Environment variables / constants:** `UPPER_SNAKE_CASE` (e.g., `CLAUDE_CODE_OAUTH_TOKEN`, `RCLONE_REMOTE`)
- **YAML files:** lowercase-with-hyphens (e.g., `atyeti-pev.yaml`, `docker-compose.yml`)
- **Markdown doc files:** `UPPER-CASE.md` for top-level guides (e.g., `SETUP.md`, `DAILY-USE.md`)
- **Docker Compose services:** lowercase-with-hyphens (e.g., `archon-app`, `archon-postgres`)
- **Directories:** lowercase-with-hyphens (e.g., `archon-data`, `archon-setup`)

## Project-Specific Conventions

- **Version pin is the source of truth.** The GHCR image tag in `docker-compose.yml` is the single definition of which Archon version is running. Never use `latest` or track a branch.
- **Custom workflows override by filename.** A file in `.archon/workflows/` with the same name as an Archon default replaces it. Use distinct names for additive workflows.
- **All scripts are idempotent and narrate.** Every script prints what it's about to do before doing it, handles "already done" gracefully, and exits non-zero on failure with a human-readable message.
- **Docs assume zero Docker knowledge.** Every doc explains what each command does and why, not just what to type. Include "what you should see" after each step.
- **Workflow YAML files must include a `description:` field** at the top level for discoverability by Archon's skill system and the vscode-archon extension.
