---
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/test_*"
  - "**/tests/**"
---

# Testing Standards

## Structure

Every test file follows the **Arrange / Act / Assert** (AAA) pattern:

```
// Arrange: set up test data and dependencies
// Act: call the function under test
// Assert: verify the result
```

## Coverage Pattern

Every test file covers three categories:

1. **Expected cases** — the happy path works correctly.
2. **Edge cases** — boundary values, empty inputs, large inputs, concurrent access.
3. **Failure cases** — invalid input is rejected, errors propagate correctly, dependency failures are handled.

## Naming

- Test names describe behavior, not method names.
- Good: `test_returns_empty_list_when_no_results`
- Bad: `test_get_results`

## Isolation

- Each test tests one thing.
- No test interdependencies — each test runs in isolation.
- Tests must be deterministic. No flaky tests.

## Mocking

- Mock external dependencies (APIs, databases, file systems, network).
- Do not mock internal logic — test it directly.
