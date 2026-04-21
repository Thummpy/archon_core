# PRP: Refactor — [Refactor Title]

## Current State

<!-- Describe what exists today and why it is problematic.
     Be specific: name the files, modules, or patterns that need changing
     and explain the concrete pain they cause (bugs, slowness, confusion,
     duplication, difficulty extending). -->

## Target State

<!-- Describe what the code should look like after the refactor.
     Focus on the structural and behavioral outcomes, not implementation details. -->

## Constraints

<!-- What must NOT change. These are the guardrails preventing the refactor
     from becoming a rewrite. -->

- **Public APIs:** ...
- **External behavior:** ...
- **Data formats / schemas:** ...
- **Performance characteristics:** ...

## Refactoring Steps

<!-- Numbered, incremental steps. CRITICAL: each step must leave the codebase
     in a working state with all tests passing. No "big bang" rewrites.

     Directive verbs: CREATE, MODIFY, FIND, ADD, REMOVE, PRESERVE, MIRROR, VERIFY -->

1. VERIFY — Run the full test suite to establish a green baseline.
2. ...
3. ...
4. VERIFY — Run the full test suite to confirm behavior is preserved.

## Validation Commands

<!-- Specific commands to run after each step and at the end.
     The refactor succeeds only if behavior is identical before and after. -->

```bash
# Baseline (run before starting)
# .claude/scripts/validate.sh

# After each step
# {{UNIT_TEST_COMMAND}}

# Final validation
# .claude/scripts/validate.sh
```

## Acceptance Criteria

- [ ] All existing tests pass without modification (unless test was testing an internal detail that changed)
- [ ] No new lint or type errors introduced
- [ ] Public APIs and external behavior unchanged
- [ ] Code meets the Target State description above
- [ ] Corresponding GitHub Issue closed (if applicable)
