# Structured Logging

Demonstrates structured key-value logging with appropriate levels, correlation IDs, and clear boundaries on what to log.

## Log Levels

| Level | When to Use |
|-------|-------------|
| `DEBUG` | Detailed diagnostic info, disabled in production |
| `INFO` | Significant business events (request served, job completed, user action) |
| `WARNING` | Unexpected but recoverable situations (retry triggered, deprecated feature used) |
| `ERROR` | Failures that need investigation (unhandled exception, external service down) |
| `CRITICAL` | System-level failures requiring immediate action (database unreachable, out of memory) |

## Structured Key-Value Format

Use structured fields, not string interpolation. Structured logs are searchable and parseable by log aggregators.

```python
import structlog

logger = structlog.get_logger()

# Good — structured fields are searchable
logger.info("order_processed", order_id=order.id, customer_id=order.customer_id, total=order.total, item_count=len(order.items))

# Bad — string interpolation defeats structured search
logger.info(f"Processed order {order.id} for customer {order.customer_id}")
```

## Correlation IDs

Attach a correlation ID to every log line within a request so distributed traces can be followed across services.

```python
import uuid
from contextvars import ContextVar

correlation_id: ContextVar[str] = ContextVar("correlation_id", default="")

def middleware(request, call_next):
    req_id = request.headers.get("X-Correlation-ID", str(uuid.uuid4()))
    correlation_id.set(req_id)
    logger.info("request_started", method=request.method, path=request.path, correlation_id=req_id)
    response = call_next(request)
    logger.info("request_completed", status=response.status_code, correlation_id=req_id)
    return response
```

## What to Log

- Entry and exit of significant operations (API requests, background jobs, transactions)
- Errors with full context (what failed, input that caused it, upstream response)
- Security events (login attempts, permission denials, token refresh)
- State transitions (order status changes, deployment stages)

## What NOT to Log

- **PII** — names, emails, addresses, phone numbers, government IDs
- **Credentials** — passwords, API keys, tokens, connection strings
- **Full request/response bodies in production** — log a summary or hash instead
- **High-frequency noise** — per-iteration logs in tight loops, health check pings

## Rationale

- **Structured logging** enables filtering by any field in log aggregators (Datadog, Splunk, ELK) without regex.
- **Correlation IDs** are essential for debugging in distributed systems — without them, tracing a request across services is guesswork.
- **Explicit what-not-to-log rules** prevent security incidents. Logging PII or credentials can erode user trust and create liability.
