# Error Handling

Demonstrates structured error handling: custom exceptions, consistent error responses, logging on catch, and retry for transient failures.

## Custom Exception Classes

Define domain-specific exceptions rather than throwing generic errors. This enables callers to handle different failure modes distinctly.

```python
class AppError(Exception):
    def __init__(self, message: str, code: str, status: int = 500):
        super().__init__(message)
        self.code = code
        self.status = status

class NotFoundError(AppError):
    def __init__(self, resource: str, identifier: str):
        super().__init__(f"{resource} not found: {identifier}", "NOT_FOUND", 404)

class ValidationError(AppError):
    def __init__(self, field: str, reason: str):
        super().__init__(f"Validation failed on '{field}': {reason}", "VALIDATION_ERROR", 400)
```

## Structured Error Responses

Return errors in a consistent shape so consumers can parse them reliably.

```python
def handle_error(error: AppError) -> dict:
    # Log with full context — the response to the caller is intentionally less detailed
    logger.error("request_failed", code=error.code, message=str(error))
    return {"error": {"code": error.code, "message": str(error)}}
```

## Logging on Catch

Never catch and swallow. Every catch block must log or re-raise.

```python
try:
    result = external_service.fetch(resource_id)
except ConnectionError as exc:
    # What failed, why, and what identifier was involved
    logger.error("external_fetch_failed", resource_id=resource_id, error=str(exc))
    raise AppError("Upstream service unavailable", "SERVICE_UNAVAILABLE", 503) from exc
```

## Retry for Transient Failures

Retry only when the failure is transient (network timeouts, rate limits). Never retry validation errors or auth failures.

```python
import time

MAX_RETRIES = 3
BACKOFF_BASE = 0.5  # seconds

def fetch_with_retry(url: str) -> dict:
    for attempt in range(MAX_RETRIES):
        try:
            return http_client.get(url)
        except TransientError as exc:
            if attempt == MAX_RETRIES - 1:
                raise
            wait = BACKOFF_BASE * (2 ** attempt)
            logger.warning("retrying_request", url=url, attempt=attempt + 1, wait_seconds=wait, error=str(exc))
            time.sleep(wait)
```

## Rationale

- **Custom exceptions** make error handling explicit and prevent broad `except Exception` blocks that mask bugs.
- **Structured responses** give API consumers a predictable contract to code against.
- **Logging on catch** ensures no failure goes unobserved — silent swallowing is the #1 source of "it just stopped working" incidents.
- **Exponential backoff** prevents retry storms from overwhelming already-stressed upstream services.
