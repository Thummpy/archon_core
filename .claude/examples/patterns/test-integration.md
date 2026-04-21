# Integration Test Patterns

Demonstrates test database setup/teardown, API test clients, external service mocking, and test isolation strategies.

## Test Database Setup and Teardown

Integration tests use a real database, not mocks. Each test starts with a known state and cleans up after itself.

### Per-Test Transaction Rollback

The fastest approach: wrap each test in a transaction that rolls back. No data persists between tests.

```python
import pytest

@pytest.fixture
async def db(test_database_pool):
    async with test_database_pool.acquire() as conn:
        transaction = conn.transaction()
        await transaction.start()
        yield conn
        await transaction.rollback()

async def test_create_order_persists_to_database(db):
    user_id = await seed_user(db, email="buyer@example.com")
    order_id = await create_order(db, user_id=user_id, items=[{"product_id": "SKU-1", "quantity": 2}])
    row = await db.fetchrow("SELECT * FROM orders WHERE id = $1", order_id)
    assert row["user_id"] == user_id
    assert row["status"] == "pending"
```

### Shared Test Database Configuration

```python
@pytest.fixture(scope="session")
async def test_database_pool():
    pool = await create_pool(dsn="postgresql://localhost/testdb")
    await run_migrations(pool)
    yield pool
    await pool.close()
```

## API Test Client

Test endpoints through the HTTP layer to exercise routing, middleware, serialization, and validation.

```python
import pytest
from httpx import AsyncClient

@pytest.fixture
async def client(app, db):
    app.state.db = db
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client

async def test_create_item_returns_201_with_location(client):
    response = await client.post("/api/items", json={"name": "Widget", "price": 9.99})
    assert response.status_code == 201
    data = response.json()["data"]
    assert data["name"] == "Widget"
    assert "id" in data
```

## External Service Mocking

Mock external HTTP services at the network boundary, not at the function level. This exercises your HTTP client configuration, serialization, and error handling.

```python
import respx

@respx.mock
async def test_payment_processes_successfully():
    respx.post("https://api.payment-gateway.com/v1/charges").mock(
        return_value=httpx.Response(200, json={"id": "ch_123", "status": "succeeded", "amount": 5000})
    )
    result = await payment_service.charge(amount=50.00, token="tok_test")
    assert result.charge_id == "ch_123"
    assert result.status == "succeeded"

@respx.mock
async def test_payment_handles_gateway_error():
    respx.post("https://api.payment-gateway.com/v1/charges").mock(
        return_value=httpx.Response(502, json={"error": "Bad Gateway"})
    )
    with pytest.raises(PaymentGatewayError):
        await payment_service.charge(amount=50.00, token="tok_test")
```

## Test Isolation Strategies

| Strategy | Speed | Isolation | Best For |
|----------|-------|-----------|----------|
| Transaction rollback | Fast | Per-test | Most integration tests |
| Truncate tables | Medium | Per-test | Tests that commit (triggers, sequences) |
| Separate database per suite | Slow | Per-suite | Parallel test execution |
| Docker container per run | Slowest | Per-run | CI pipelines, full isolation |

**Rules for isolation:**
- Tests must not depend on execution order
- Tests must not share mutable state (rows inserted by another test)
- Tests must clean up external side effects (files, cache entries, queue messages)
- Use unique identifiers (UUIDs, timestamps) when shared resources can't be isolated

## Rationale

- **Real database tests** catch issues that mocks hide: constraint violations, migration errors, query syntax, transaction behavior.
- **HTTP-level mocking** validates your actual client code (headers, retries, timeouts) rather than bypassing it.
- **Transaction rollback** is the fastest isolation strategy because it avoids DDL and truncation overhead.
- **Test isolation** prevents the most frustrating class of bugs: tests that pass individually but fail when run together.
