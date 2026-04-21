# Init Subsystem: $ARGUMENTS

Generate a prime command for a specific subsystem to enable focused context loading.

## Instructions

You are analyzing the subsystem: **$ARGUMENTS**

### Step 1 — Locate the Subsystem

Find the directory or directories that contain the `$ARGUMENTS` subsystem. Common locations:

- `src/$ARGUMENTS/`
- `packages/$ARGUMENTS/`
- `services/$ARGUMENTS/`
- `apps/$ARGUMENTS/`
- A top-level `$ARGUMENTS/` directory

If the subsystem cannot be found, report this and ask the developer to specify the path.

### Step 2 — Explore Structure

Spawn a sub-agent to explore the subsystem directory. Identify:

- **Key files** — Entry points, main modules, configuration files
- **Internal structure** — How the code is organized (by feature, by layer, etc.)
- **Dependencies** — What this subsystem imports from other parts of the codebase
- **Dependents** — What other parts of the codebase import from this subsystem
- **Test locations** — Where tests for this subsystem live
- **Patterns** — Recurring code patterns, naming conventions, architectural style

### Step 3 — Generate Prime Command

Create a new command file at `.claude/commands/prime-$ARGUMENTS.md` with this structure:

```markdown
# Prime: $ARGUMENTS

Load focused context for the $ARGUMENTS subsystem.

## Instructions

Read these files to understand the $ARGUMENTS subsystem:

### Architecture
- {list key files and what they do}

### Entry Points
- {list entry points and their purpose}

### Dependencies
- {list internal and external dependencies}

### Patterns
- {list the coding patterns used in this subsystem}

### Relevant Rules
- {list .claude/rules/ files that apply}

### Test Locations
- {list where tests live and how to run them}

After reading, you have sufficient context to work on the $ARGUMENTS subsystem.
Do not explore unrelated parts of the codebase unless a task requires it.
```

Fill in the template with the actual findings from Step 2. The generated file should contain real paths and descriptions, not placeholders.

### Step 4 — Report

Summarize:

1. Where the subsystem was found
2. The number of key files and dependencies identified
3. The path to the generated prime command
4. How to use it: `/prime-$ARGUMENTS`
