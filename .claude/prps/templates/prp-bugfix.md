# PRP: Bug Fix — [Bug Title]

## Ticket Reference

<!-- Link to Jira, Linear, GitHub Issue, or ADO ticket. -->

## Bug Description

### Observed Behavior

<!-- What actually happens. Include error messages, stack traces, or screenshots. -->

### Expected Behavior

<!-- What should happen instead. -->

### Reproduction Steps

<!-- Numbered steps to reproduce the bug reliably. -->

1. ...
2. ...
3. ...

### Environment

<!-- Where the bug occurs: OS, runtime version, environment (dev/staging/prod),
     relevant configuration. -->

## Root Cause Analysis

<!-- Investigate BEFORE proposing a fix. Explain:
     - Where the bug originates in the code
     - Why the current code produces incorrect behavior
     - What conditions trigger it -->

## Fix Tasks

<!-- Numbered steps using directive verbs. Each step must be specific and actionable.

     Directive verbs: CREATE, MODIFY, FIND, ADD, REMOVE, PRESERVE, MIRROR, VERIFY -->

1. FIND — ...
2. MODIFY — ...
3. ADD — ...
4. VERIFY — ...

## Regression Considerations

<!-- What else could break as a result of this fix?
     - Related code paths that share the affected logic
     - Edge cases the fix must handle
     - Existing tests that may need updating -->

- ...

## Validation Commands

<!-- Specific commands to run that prove the fix works and nothing regressed. -->

```bash
# Run targeted test for the fix
# {{TEST_COMMAND}}

# Run related test suites
# {{RELATED_TEST_COMMAND}}

# Full validation
# .claude/scripts/validate.sh
```

## Acceptance Criteria

- [ ] Bug no longer reproducible via the steps above
- [ ] Regression test added covering this specific case
- [ ] All existing tests continue to pass
- [ ] Corresponding GitHub Issue closed (if applicable)
