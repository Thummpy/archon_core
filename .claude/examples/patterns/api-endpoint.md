# API Endpoint Structure

Demonstrates the standard request-handling flow: validate → authenticate → execute → respond → handle errors.

This file is a `[PLACEHOLDER]`. Replace `{{FRAMEWORK}}` markers with your project's actual framework during initialization.

## Generic Flow

Every endpoint follows this sequence:

1. **Validate input** — reject malformed requests before any business logic runs
2. **Check authorization** — verify the caller has permission for this operation
3. **Execute business logic** — call domain services, not raw data access
4. **Format response** — return a consistent response envelope
5. **Handle errors** — catch and translate exceptions to appropriate HTTP status codes

## Endpoint Template

### {{FRAMEWORK}} — Replace with your framework (FastAPI, Express, Spring Boot, etc.)

```
{{FRAMEWORK_SPECIFIC}}
# Replace this block with a complete endpoint example in your framework.
# It should demonstrate:
#   - Request validation (path params, query params, body)
#   - Auth/permission check
#   - Service call (not direct DB access)
#   - Structured JSON response with consistent envelope
#   - Error handling returning appropriate status codes
#
# Example frameworks:
#   FastAPI:     @app.post("/items") with Pydantic models
#   Express:     router.post("/items", validate, authorize, handler)
#   Spring Boot: @PostMapping with @Valid and ResponseEntity
#   Go net/http:  handler with middleware chain
```

## Response Envelope

All endpoints return a consistent shape:

```json
{
  "data": { },
  "error": null,
  "meta": {
    "request_id": "abc-123",
    "timestamp": "2025-01-15T10:30:00Z"
  }
}
```

On error:

```json
{
  "data": null,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Field 'email' is required"
  },
  "meta": {
    "request_id": "abc-123",
    "timestamp": "2025-01-15T10:30:00Z"
  }
}
```

## Input Validation

Validate at the handler boundary. Business logic should receive pre-validated data.

```
{{FRAMEWORK_SPECIFIC}}
# Replace with your framework's validation approach:
#   FastAPI:     Pydantic model as parameter type
#   Express:     Joi/Zod schema in validation middleware
#   Spring Boot: @Valid annotation with Jakarta Bean Validation
#   Go:          validator library or manual checks in handler
```

## Rationale

- **Validate-first** prevents invalid data from reaching business logic, reducing the surface area for bugs.
- **Consistent response envelope** lets API consumers write generic parsing code instead of per-endpoint handling.
- **Service-layer calls** (not direct DB access) keep endpoints thin and business logic testable in isolation.
