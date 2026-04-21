# Initialize Project from Seed

Read `.claude/project_seed.md` and populate all template placeholder files to fully initialize this project.

## Prerequisites

- `.claude/project_seed.md` has been populated with the seed generated during the claude.ai brainstorming session
- This is a fresh repo created from the AI Code Template — placeholder files still contain `{{PLACEHOLDER}}` markers

## Instructions

You are initializing a project from a seed file. Follow these steps precisely. Do NOT skip steps or reorder them.

### Step 1 — Read the Seed

Read `.claude/project_seed.md` thoroughly. This file contains every decision made during brainstorming. Internalize:

- **Project Identity** — name, description, team lead
- **Project Thesis** — problem, goals, features, subsystems, roadmap, out of scope
- **Tech Stack** — language, framework, database, infrastructure, additional tools
- **Architecture** — pattern, components, data flow, diagram, external dependencies, security model
- **Project Structure** — directory layout
- **Workflow** — issue tracking, branching model (may be "TBD")
- **Project-Specific Conventions** (may be "TBD" or "No additional conventions")
- **Design Decisions** (may be "TBD")
- **Constraints** (may be "TBD" or "No specific constraints")
- **Environment** — prerequisites, setup steps, env vars, run locally, verify setup (may be "TBD")
- **Deployment** — environments, deploy process, rollback, monitoring, secrets storage (may be "TBD" or "Not yet defined")
- **Additional Rules** (may be "N/A" or absent)
- **Infrastructure Conventions** (may be "N/A" or absent)

### Step 2 — Handle Null Cases

For any section marked "TBD", "N/A", empty, or absent, apply this derivation hierarchy:

1. **Derive from Tech Stack** — commands (lint, test, build, type check), CI config, naming conventions, setup steps, permissions
2. **Synthesize from Architecture** — diagrams, data flow, security model, component descriptions
3. **Write valid null statements** — "No additional conventions beyond framework standards", "Not yet defined", "No specific constraints identified", "No external service dependencies"

The init validator (`.claude/scripts/init-project.sh`) only checks that `{{PLACEHOLDER}}` markers are gone. Every placeholder MUST be replaced — either with seed content, derived content, or a valid null statement.

### Step 3 — Populate Files

Process each file below. Read the file first, then replace all `{{PLACEHOLDER}}` markers with content from the seed (or derived/null content per Step 2). Preserve the file structure — only replace the placeholders and remove the HTML instruction comments.

#### 3a. `.claude/CLAUDE.md`

| Placeholder | Source |
|-------------|--------|
| `{{PROJECT_NAME}}` | Project Identity > Name |
| `{{PROJECT_DESCRIPTION}}` | Project Identity > Description |
| `{{TECH_STACK}}` | Tech Stack — format as a concise bulleted list (language, framework, database, infra, tools) |
| `{{PROJECT_STRUCTURE}}` | Project Structure — the directory tree verbatim |
| `{{WORKFLOW}}` | Workflow section. If TBD: "GitHub Issues for tracking. GitHub Flow: feature branches off main, PR required, squash merge." |
| `{{NAMING_CONVENTIONS}}` | **Derive from Tech Stack language.** Write language-appropriate conventions (e.g., Python: snake_case files/functions, PascalCase classes; TypeScript: camelCase functions, PascalCase components; Go: camelCase unexported, PascalCase exported). |
| `{{PROJECT_CONVENTIONS}}` | Project-Specific Conventions. If TBD/none: "No additional project-specific conventions beyond framework standards." |

Remove all HTML comments (`<!-- ... -->`) from `.claude/CLAUDE.md` after populating.

#### 3b. `.claude/PLANNING.md`

| Placeholder | Source |
|-------------|--------|
| `{{PROJECT_OVERVIEW}}` | Synthesize from Project Identity (name, description) + Project Thesis (problem statement, goals, target users). 2-3 sentences. |
| `{{ARCHITECTURE}}` | Architecture > Overview |
| `{{TECH_STACK}}` | Tech Stack — same content as `.claude/CLAUDE.md` |
| `{{DESIGN_DECISIONS}}` | Design Decisions section. If TBD: synthesize key decisions implicit in the tech stack and architecture choices. |
| `{{CONSTRAINTS}}` | Constraints section. If TBD: "No specific constraints identified beyond standard security and code quality practices." |
| `{{STYLE_CONVENTIONS}}` | Project-Specific Conventions (same source as `{{PROJECT_CONVENTIONS}}`). If TBD/none: "No additional style conventions beyond framework standards." |
| `{{OUT_OF_SCOPE}}` | Project Thesis > Out of Scope |

Remove all HTML comments after populating.

#### 3c. `.claude/docs/architecture.md`

| Placeholder | Source |
|-------------|--------|
| `{{SYSTEM_OVERVIEW}}` | Synthesize from Project Thesis + Architecture > Overview |
| `{{ARCHITECTURE_DIAGRAM}}` | Architecture > Diagram (Mermaid content only, no fences). If absent: generate from Architecture > Components. |
| `{{COMPONENT_DESCRIPTIONS}}` | Architecture > Components — expand each into a paragraph with responsibility, technology, and interfaces |
| `{{DATA_FLOW}}` | Architecture > Data Flow. If absent: synthesize from Components. |
| `{{EXTERNAL_DEPENDENCIES}}` | Architecture > External Dependencies. If none: "No external service dependencies." |
| `{{INFRASTRUCTURE_DEPLOYMENT}}` | Tech Stack > Infrastructure + Deployment section. If deployment TBD: "Deployment model not yet defined. See `.claude/docs/deployment.md`." |
| `{{SECURITY_ARCHITECTURE}}` | Architecture > Security Model. If absent: write generic security practices for the chosen framework. |

Remove all HTML comments after populating.

#### 3d. `.claude/docs/setup.md`

| Placeholder | Source |
|-------------|--------|
| `{{PREREQUISITES}}` | Environment > Prerequisites. If TBD: derive from Tech Stack (language runtime, package manager, database). |
| `{{CLONE_AND_INSTALL_COMMANDS}}` | Environment > Setup Steps. If TBD: derive standard commands from Tech Stack. |
| `{{ENVIRONMENT_CONFIGURATION}}` | Environment > Environment Variables table. If TBD: "See `.env.example` for required environment variables (created during setup)." Include all credentials and secrets identified in the seed — this is the authoritative location for what env vars are needed, where to obtain values, and how to configure them locally. Do not reference scripts that `/init` does not generate. |
| `{{LOCAL_DEV_COMMANDS}}` | Environment > Run Locally. If TBD: derive from Tech Stack framework. |
| `{{VERIFY_SETUP_COMMANDS}}` | Environment > Verify Setup. If TBD: derive a health check from the framework (e.g., `curl localhost:8000/health`). |

Remove all HTML comments after populating.

#### 3e. `.claude/docs/deployment.md`

| Placeholder | Source |
|-------------|--------|
| `{{ENVIRONMENTS}}` | Deployment > Environments. If TBD: "Not yet defined." |
| `{{DEPLOYMENT_PROCESS}}` | Deployment > Deploy Process. If TBD: "Not yet defined." |
| `{{ROLLBACK_PROCEDURE}}` | Deployment > Rollback. If TBD: "Not yet defined." |
| `{{MONITORING_ALERTS}}` | Deployment > Monitoring. If TBD: "Not yet defined." |
| `{{ACCESS_CREDENTIALS}}` | Deployment > Secrets Storage + Environment > Environment Variables. If TBD: "Not yet defined." This is the authoritative location for how credentials are managed in production (secrets manager, rotation schedule, access contacts). Instructions must be self-contained — do not reference scripts that `/init` does not generate. |

Remove all HTML comments after populating.

#### 3f. `.claude/scripts/validate.sh`

**Derive all commands from Tech Stack.** Do not modify the script structure — only replace placeholders.

| Placeholder | Derivation |
|-------------|------------|
| `{{LINT_COMMAND}}` | Tech Stack language → standard linter (Python: `ruff check .`, Node/TS: `npx eslint .`, Go: `golangci-lint run`, Java: `mvn checkstyle:check`) |
| `{{TYPE_CHECK_COMMAND}}` | Tech Stack language → type checker (Python: `mypy src/`, TS: `npx tsc --noEmit`, Go: `go vet ./...`, Java: `echo 'Type checking handled by compiler'`) |
| `{{UNIT_TEST_COMMAND}}` | Tech Stack language → test runner (Python: `pytest tests/unit/ -v`, Node/TS: `npx vitest run`, Go: `go test ./... -short`, Java: `mvn test`) |
| `{{UNIT_TEST_DIR}}` | The directory containing unit tests (Python: `tests/unit`, Node/TS: `src/__tests__` or `tests`, Go: `.` — for Go, also change `run_step_if` to `run_step` since Go tests are co-located, Java: `src/test`). This is used by `run_step_if` to skip the step gracefully when the directory doesn't exist yet. |
| `{{INTEGRATION_TEST_COMMAND}}` | Tech Stack language → integration tests (Python: `pytest tests/integration/ -v`, Node/TS: `npx vitest run --config vitest.integration.config.ts`, Go: `go test ./... -run Integration`, Java: `mvn verify -pl integration-tests`) |
| `{{INTEGRATION_TEST_DIR}}` | The directory containing integration tests (Python: `tests/integration`, Node/TS: `tests/integration`, Go: `.` — for Go, also change `run_step_if` to `run_step`, Java: `src/integration-test`). Same graceful-skip behavior as unit tests. |
| `{{BUILD_COMMAND}}` | Tech Stack language → build (Python: `python -m build`, Node/TS: `npm run build`, Go: `go build ./...`, Java: `mvn package -DskipTests`) |

Verify commands are appropriate for the specific framework/tooling in the seed, not just the language defaults.

#### 3g. `.claude/settings.local.json`

Read the file. It contains permission blocks for Python, Node/TS, Java, and Go.

1. Remove the `_readme` key entirely
2. Keep ONLY the permission entries relevant to the project's Tech Stack
3. Remove all permission entries for languages/tools the project does NOT use
4. Add any project-specific tool permissions needed (e.g., `Bash(docker-compose:*)` if using Docker)
5. The `{{TECH_STACK_PERMISSIONS}}` marker is in the `_readme` value — removing the key resolves it

#### 3h. `.github/CODEOWNERS`

Replace every `{{TEAM_LEAD_HANDLE}}` with the GitHub handle from Project Identity > Team > Lead (e.g., `@janedoe`).

#### 3i. `.github/workflows/validate.yml`

Uncomment and populate the language setup block based on Tech Stack:

- `{{LANGUAGE_SETUP}}` → the appropriate `actions/setup-*` action
- `{{LANGUAGE_VERSION_KEY}}` → the version key name (e.g., `python-version`, `node-version`, `go-version`, `java-version`)
- `{{LANGUAGE_VERSION}}` → the version from Tech Stack
- `{{INSTALL_COMMAND}}` → the dependency install command

Uncomment the `- name: Set up runtime` and `- name: Install dependencies` blocks.

#### 3j. `.claude/examples/patterns/api-endpoint.md`

Replace `{{FRAMEWORK}}` with the API/web framework from Tech Stack.
Replace `{{FRAMEWORK_SPECIFIC}}` blocks with complete, working code examples in that framework demonstrating:
- Request validation
- Auth/permission check
- Service call
- Structured JSON response
- Error handling

#### 3k. `.claude/examples/patterns/database-query.md`

Replace `{{ORM_SPECIFIC}}` blocks with complete, working code examples using the ORM/driver from Tech Stack demonstrating:
- Connection pool configuration
- Eager loading / N+1 avoidance

#### 3l. `.claude/rules/infrastructure.md`

Replace `{{INFRA_CONVENTIONS}}` with Infrastructure Conventions from the seed. If the seed section is "N/A" or absent: "No project-specific infrastructure conventions."

#### 3m. `README.md`

**Replace the entire file.** The template README.md describes the AI Dev Framework itself — it is NOT the project's README. Generate a new README.md for the actual project using the seed content:

- **Project name** as the H1 heading
- **Description** from Project Identity
- **Tech Stack** summary
- **Getting Started** — link to `.claude/docs/setup.md`
- **Architecture** — brief overview with link to `.claude/docs/architecture.md`
- **Development** — link to development workflow commands (`/plan-feature`, `/execute`, etc.)
- **Team** table from Project Identity

Keep it concise. The detailed docs live in `.claude/docs/`.

#### 3n. `.claude/rules/` — Additional Rules

If the seed's Additional Rules section has content (not "N/A" or absent), create new rule files in `.claude/rules/` for each distinct domain-specific convention described. Each rule file must:

1. Have YAML frontmatter with `paths:` globs targeting the relevant file types
2. Follow the format described in `.claude/rules/_README.md`
3. NOT duplicate or override the template's existing rule files (`general-quality.md`, `testing.md`, `documentation.md`, `infrastructure.md`)

If Additional Rules is "N/A" or absent, skip this step.

### Step 4 — Configure Git Hooks

Enable the pre-commit hook that ships with the template:

```bash
git config core.hooksPath .githooks
```

This configures git to use `.githooks/pre-commit` for commit-time validation. The hook runs `validate.sh --skip-integration` before every commit — even outside Claude Code. It handles null cases gracefully (placeholder commands and missing directories are skipped, not failures).

Developers can bypass the hook when needed: `SKIP_VALIDATE=1 git commit -m "message"`

### Step 5 — Validate

Run the init validator:

```bash
./.claude/scripts/init-project.sh
```

If any checks fail, fix the unresolved placeholders and re-run until all checks pass.

### Step 6 — Bootstrap

Run `/bootstrap` now. This plans infrastructure and initial development tasks, then creates GitHub Issues with labels, phased milestones, and dependency ordering.

**Prerequisite:** The `gh` CLI must be installed and authenticated (`gh auth status`). If not available, warn the user and skip to Step 7.

### Step 7 — Audit Seed and Rewrite README

Review `.claude/project_seed.md` one final time against every file populated in Step 3. Identify any residual information that has not been placed — informative context, explanations, workflow guidance, background, constraints, or any other content that doesn't map to a specific template placeholder but is still valuable.

Then rewrite `README.md` as the project's README (the template README was already replaced in Step 3m). Ensure it includes:

- **Project name** as H1
- **Description** from Project Identity
- **Tech Stack** summary
- **Getting Started** — link to `.claude/docs/setup.md`
- **Architecture** — brief overview with link to `.claude/docs/architecture.md`
- **Any residual seed content** — fold in context, background, or guidance that didn't land elsewhere
- **Workflow** section at the bottom — list each development command with a one-line explanation:
  - `/research` — iterative pre-plan research to resolve unknowns
  - `/plan-feature` — research codebase and generate an implementation plan
  - `/execute` — implement the plan step-by-step with validation
  - `/review` — self-review changes against standards
  - `/commit-close` — validate, commit, push, create PR, and close issue
  - `/handoff` — save session state when context is heavy but task is not done
  - `/compact` — compress context for long-running sessions
- **Team** table from Project Identity

### Step 8 — Delete Seed

At this point all information from the seed has been disseminated. Delete `.claude/project_seed.md`.

```bash
rm .claude/project_seed.md
```

### Step 9 — Report

Summarize what was done:

1. Number of files populated
2. Any sections where you derived content (not directly from seed) — list what you derived and from what
3. Any sections where you wrote null statements — list them
4. Any residual seed content folded into README
5. Any warnings or issues discovered during population
6. Number of GitHub Issues created by bootstrap

### Step 10 — Commit

Run `/commit-close --skip-validate` to commit the fully initialized project.
