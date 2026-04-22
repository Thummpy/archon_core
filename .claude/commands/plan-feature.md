# Plan Feature: $ARGUMENTS

Generate a detailed implementation plan (PRP) for the specified feature.

## Instructions

You are planning the feature: **$ARGUMENTS**

Follow these steps precisely. Do not skip steps or combine them.

### Step 0 — Create Feature Branch

If `$ARGUMENTS` is a number (a GitHub issue number), create or checkout a feature branch:

1. Fetch remote branches so the check includes work started in other sessions:
   ```
   git fetch origin
   ```
2. Check if a feature branch already exists for this issue (local or remote):
   ```
   git branch -a --list "*feat/issue-$ARGUMENTS-*"
   ```
3. If a matching branch exists, check it out:
   ```
   git checkout feat/issue-$ARGUMENTS-<existing-slug>
   ```
4. If no branch exists, create one:
   a. Fetch the issue title: `gh issue view $ARGUMENTS --json title --jq .title`
   b. Slugify the title: lowercase, replace spaces and special characters with hyphens, remove consecutive hyphens, truncate to 50 characters, trim trailing hyphens.
   c. Create and checkout the branch:
      ```
      git checkout -b feat/issue-$ARGUMENTS-<slug>
      ```
   d. Push to remote with tracking so the branch exists on both local and remote:
      ```
      git push -u origin feat/issue-$ARGUMENTS-<slug>
      ```
5. If `$ARGUMENTS` is not a number (e.g., a feature name string), skip this step entirely and proceed to Step 1. The developer is responsible for branch management in this case.

### Step 1 — Gather Context

Read these files to understand the project:

1. `.claude/PLANNING.md` — architecture, constraints, design decisions
2. `gh issue list --state open` — current work items and backlog
3. `.claude/CLAUDE.md` — coding standards and conventions

### Step 2 — Explore the Codebase

Spawn sub-agents to research in parallel. Keep exploration noise out of the main context.

- **Agent 1:** Explore the project directory structure. Identify top-level modules, key entry points, and how code is organized.
- **Agent 2:** Search for code related to "$ARGUMENTS" — existing implementations, interfaces, tests, or configuration that the feature will touch or extend.
- **Agent 3:** Read any relevant `.claude/rules/` files that apply to the directories this feature will likely modify.

### Step 3 — Study Existing Patterns

Check `.claude/examples/patterns/` and `.claude/examples/reference-implementations/` for approved patterns this feature should follow. If examples exist, the implementation plan must conform to them.

### Step 4 — External Research (if needed)

If the feature involves external APIs, unfamiliar libraries, or integration with third-party services:

1. Use WebFetch or WebSearch to find relevant SDK documentation, known gotchas, or version-specific issues.
2. Look for community patterns solving similar problems.
3. Document specific findings that affect the implementation approach — these go in the PRP's CRITICAL section.

Skip this step if the feature is purely internal.

### Step 5 — Think Before Writing

Before generating the PRP, reason through:

- **Architecture fit** — Where does this logic belong? Does it extend existing modules or need a new one?
- **Interface impact** — Does this change any public APIs, data models, or contracts?
- **Risk assessment** — What's the blast radius if the implementation has a bug? What's the rollback path?
- **Dependencies** — Does this depend on work not yet completed? Are there ordering constraints?

### Step 6 — Write the PRP

Create the PRP file at `.claude/prps/$ARGUMENTS.md` (slugify the feature name: lowercase, hyphens for spaces, no special characters).

Use the template at `.claude/prps/templates/prp-base.md` as the structure. Fill in every section:

- **Objective** — One paragraph describing what this feature does and why it matters.
- **Ticket Reference** — Leave blank or reference a GitHub Issue number if one exists.
- **MUST READ** — List files and documentation the implementing agent must read before starting. Use the format:
  - `file: path/to/file` — `why: explanation`
  - `doc: .claude/docs/filename.md` — `why: explanation`
- **CRITICAL** — Known gotchas, library quirks, external constraints, or pitfalls discovered during exploration.
- **Security Considerations** — Authentication, authorization, data validation, and sensitive data handling relevant to this feature.
- **External Constraints** — Any external requirements from `.claude/PLANNING.md` that affect this feature.
- **Data Models** — New or modified data structures, schemas, or types.
- **Implementation Tasks** — Numbered steps using directive verbs:
  - CREATE, MODIFY, FIND, ADD, REMOVE, PRESERVE, MIRROR, VERIFY
  - Each task is specific and actionable. No vague steps.
  - Order tasks so each leaves the codebase in a working state.
- **Validation Commands** — Specific commands to run that prove the implementation works. Include lint, type check, unit tests, and integration tests.
- **Acceptance Criteria** — Bulleted list of conditions that must be true when the feature is complete.
- **Confidence Score** — Rate 1-10 how confident you are this plan enables one-pass implementation. If below 8, explain what would raise the score.

### Step 7 — Identify Ambiguities

List any questions or ambiguities that need human resolution before `/execute` can succeed. Be specific:

- Missing requirements (e.g., "The error format for this endpoint is unspecified")
- Architectural choices that could go either way (e.g., "Should this be synchronous or event-driven?")
- Dependencies on work not yet completed

Present these as a numbered list at the end of your response.

### Step 7a — RESEARCH Ambiguities

For each ambiguity identified in Step 7, attempt to resolve it through research:

- Use Grep to search for relevant code patterns and implementations
- Use Read to examine related files and configuration
- Check `.claude/examples/patterns/` for existing patterns that answer the question
- Use WebSearch or WebFetch for external library documentation if needed
- Document your findings for each ambiguity—what you learned and whether it's resolved

If an ambiguity cannot be resolved through research (requires user decision, missing requirements, architectural choice), keep it in your list of remaining ambiguities.

### Step 7b — Update PRP with Research Findings

Based on your research in Step 7a, edit the PRP file to incorporate new information:

- Use the Edit tool to modify implementation tasks that were clarified by research
- Add findings to the CRITICAL section if they represent important constraints or gotchas
- Update the confidence score if ambiguities were resolved (explain the increase in justification)
- Preserve all sections—only make surgical edits based on what you learned

### Step 8 — Report

Summarize what you planned:

1. The PRP file path
2. The confidence score with a brief justification
3. The number of implementation tasks
4. The number of ambiguities resolved during research (if any)
5. Any remaining ambiguities that could not be resolved through research

Do not begin implementation. The `/execute` command handles that separately.
