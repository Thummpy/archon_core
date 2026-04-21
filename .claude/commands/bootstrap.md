# Bootstrap Project

Set up initial tasks and GitHub Issues after project initialization.

## Prerequisites

1. Run `/init` first to populate all template files from `.claude/project_seed.md`.
2. Run `.claude/scripts/init-project.sh` and confirm all validation checks pass — placeholders resolved, `.claude/CLAUDE.md` populated, `.claude/PLANNING.md` filled in.
3. The `gh` CLI must be installed and authenticated. Verify with `gh auth status`. If not installed, see https://cli.github.com/.

## Instructions

You are bootstrapping a newly initialized project. Follow these steps precisely.

### Step 1 — Understand the Project

Read these files thoroughly:

1. `.claude/CLAUDE.md` — project identity, tech stack, coding standards
2. `.claude/PLANNING.md` — architecture, constraints, design decisions, tech stack
3. `.claude/docs/architecture.md` — system overview, components, data flow, infrastructure
4. `.claude/docs/setup.md` — prerequisites, environment configuration

### Step 2 — Plan Infrastructure Tasks

Based on the architecture and tech stack, identify infrastructure setup work:

- **CI/CD pipeline** — GitHub Actions workflow (`validate.yml`), branch protection, required checks
- **Development environment** — Docker compose, local dev scripts, environment variable templates
- **Database/storage setup** — Schema migrations, seed data, connection configuration
- **Deployment pipeline** — Staging and production deployment configuration
- **Monitoring/observability** — Logging infrastructure, health checks, alerting

Only include tasks relevant to the project's actual tech stack and architecture. Do not invent infrastructure the project doesn't need.

### Step 3 — Plan Initial Development Tasks

Identify the first development milestones that prove the architecture works end-to-end:

- **Vertical slice** — One complete feature path from API/UI to data layer, demonstrating the chosen patterns
- **Reference implementation** — A working example for `.claude/examples/reference-implementations/` based on the vertical slice

### Step 4 — Create GitHub Issues

For each task identified in Steps 2 and 3, create a GitHub Issue using `gh issue create`:

- **Title** — Clear, actionable (e.g., "Set up GitHub Actions CI pipeline", "Implement user authentication vertical slice")
- **Labels** — Apply appropriate labels:
  - `infrastructure` for infra tasks
  - `feature` for development tasks
  - `documentation` for docs tasks
  - `priority:high` for tasks that block other work
- **Body** — Include:
  - What needs to be done and why
  - Acceptance criteria (bulleted list)
  - Dependencies on other issues (reference by number after creation)
  - Relevant files or directories to modify
- **Milestone** — Group into logical phases:
  - Phase 1: Infrastructure & CI/CD
  - Phase 2: Vertical slice & reference implementation
  - Phase 3: Documentation & polish

Create issues in dependency order so earlier issues can be referenced by later ones.

### Step 5 — Report

Summarize what was created:

1. Total number of GitHub Issues created
2. Breakdown by category (infrastructure, feature, documentation)
3. Recommended order of execution
4. Any decisions that need human input before work begins (e.g., "Which cloud provider for deployment?" or "Is there an existing database schema to migrate?")

Do not begin implementation. Use `/plan-feature` to plan individual features and `/execute` to implement them.
