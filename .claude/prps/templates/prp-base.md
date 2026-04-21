# PRP: [Feature Name]

## Objective

<!-- One paragraph: what this feature does and why it matters. -->

## Ticket Reference

<!-- Link to Jira, Linear, GitHub Issue, or ADO ticket. Leave blank if none. -->

## MUST READ

<!-- Context the implementing agent must read before starting.
     Use prefixes to indicate source type. -->

- `file: .claude/PLANNING.md` — `why: architecture and constraints for this project`
- `file: path/to/relevant/module` — `why: explanation of relevance`
- `doc: .claude/docs/filename.md` — `why: reference material needed`
- `url: https://docs.example.com/api` — `why: external API documentation`
- `docfile: path/to/external/spec` — `why: specification or schema`

## CRITICAL

<!-- Library gotchas, known pitfalls, project-specific constraints, or
     non-obvious technical details discovered during planning.
     Each item should prevent a likely implementation mistake. -->

- ...

## Security Considerations

<!-- Authentication, authorization, input validation, data sensitivity,
     encryption requirements, logging considerations. -->

- ...

## External Constraints

<!-- Requirements or limitations imposed by external factors:
     stakeholder requirements, platform limitations, performance targets,
     approved libraries, deployment restrictions. -->

- ...

## Data Models

<!-- New or modified data structures, schemas, types, or database changes.
     Include field names, types, constraints, and relationships.
     Skip this section if the feature involves no data model changes. -->

```
# Example:
# UserPreference:
#   user_id: UUID (FK → users.id, NOT NULL)
#   key: VARCHAR(255) (NOT NULL)
#   value: JSONB (NOT NULL)
#   created_at: TIMESTAMP (NOT NULL, DEFAULT NOW())
```

## Implementation Tasks

<!-- Numbered steps using directive verbs. Each step must be specific and
     actionable. Order so each step leaves the codebase in a working state.

     Directive verbs: CREATE, MODIFY, FIND, ADD, REMOVE, PRESERVE, MIRROR, VERIFY -->

1. FIND — ...
2. CREATE — ...
3. MODIFY — ...
4. ADD — ...
5. VERIFY — ...

## Validation Commands

<!-- Specific commands to run that prove the implementation works.
     Include lint, type check, unit tests, integration tests as applicable. -->

```bash
# Lint / format
# {{LINT_COMMAND}}

# Type check
# {{TYPE_CHECK_COMMAND}}

# Unit tests
# {{UNIT_TEST_COMMAND}}

# Integration tests
# {{INTEGRATION_TEST_COMMAND}}

# Full validation
# .claude/scripts/validate.sh
```

## Acceptance Criteria

<!-- Bulleted list of conditions that must all be true when the feature is complete. -->

- [ ] ...
- [ ] All existing tests continue to pass
- [ ] No new lint or type errors introduced
- [ ] Corresponding GitHub Issue closed (if applicable)

## Confidence Score

<!-- Rate 1-10 how confident you are this plan enables one-pass implementation.
     If below 8, explain what specific information or decisions would raise the score. -->

**Score:** /10

**Justification:**
