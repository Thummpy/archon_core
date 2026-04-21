# Unit Test Patterns

Demonstrates the AAA pattern, fixtures, mocking strategies, and assertion best practices.

## AAA Pattern (Arrange / Act / Assert)

Every test has exactly three phases, marked by AAA comments. This makes tests scannable and failures easy to locate.

```python
def test_calculate_discount_applies_percentage_to_subtotal():
    # Arrange
    order = Order(items=[OrderItem(price=100.00, quantity=2), OrderItem(price=50.00, quantity=1)])
    discount = PercentageDiscount(rate=0.10)
    # Act
    result = discount.apply(order)
    # Assert
    assert result.total == 225.00  # (200 + 50) * 0.90
    assert result.discount_amount == 25.00
```

## Descriptive Test Names

Test names describe **behavior**, not method names. A reader should understand what broke from the test name alone.

```python
# Good — describes expected behavior
def test_expired_token_returns_unauthorized(): ...
def test_empty_cart_raises_validation_error(): ...
def test_duplicate_email_is_rejected_on_registration(): ...

# Bad — names the method, not the behavior
def test_validate_token(): ...
def test_checkout(): ...
def test_register(): ...
```

## Fixtures and Setup

Extract shared setup into fixtures/factories. Keep setup close to the test when it's test-specific.

```python
def make_user(overrides: dict = None) -> User:
    defaults = {"name": "Test User", "email": "test@example.com", "role": "member"}
    return User(**(defaults | (overrides or {})))

def test_admin_can_delete_other_users():
    admin, target = make_user({"role": "admin"}), make_user({"email": "other@example.com"})
    result = delete_user(actor=admin, target=target)
    assert result.success is True

def test_member_cannot_delete_other_users():
    member, target = make_user({"role": "member"}), make_user({"email": "other@example.com"})
    with pytest.raises(PermissionError):
        delete_user(actor=member, target=target)
```

## Mocking Strategy

Mock **external dependencies** (HTTP clients, databases, message queues). Do not mock internal logic — if you need to mock an internal function, the design likely needs refactoring.

```python
def test_payment_service_handles_gateway_timeout(mocker):
    mocker.patch("services.payment.gateway_client.charge", side_effect=TimeoutError("Gateway timeout"))
    result = payment_service.process_payment(order_id="123", amount=50.00)
    assert result.status == "failed"
    assert result.error_code == "GATEWAY_TIMEOUT"
```

## One Assertion Per Concept

Each test verifies one behavior. Multiple `assert` statements are fine when they verify facets of a single outcome.

```python
# Good — multiple asserts, one concept (the response shape after creation)
def test_create_user_returns_complete_profile():
    result = create_user(name="Alice", email="alice@example.com")
    assert result.id is not None
    assert result.name == "Alice"
    assert result.email == "alice@example.com"
    assert result.created_at is not None

# Bad — testing two unrelated behaviors in one test
def test_user_operations():
    user = create_user(name="Alice", email="alice@example.com")
    assert user.id is not None
    updated = update_user(user.id, name="Bob")
    assert updated.name == "Bob"  # This is a separate behavior
```

## Rationale

- **AAA separation** makes it obvious where a failure originates — was the setup wrong, the action broken, or the expectation incorrect?
- **Behavioral names** turn test output into documentation. When CI fails, the test name should tell you what's broken without opening the file.
- **Mock boundaries at external deps** keeps tests fast and reliable while still exercising your actual logic paths.
