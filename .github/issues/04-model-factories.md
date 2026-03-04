# [Feature] Model Factories for Testing

**Priority:** #4 — Testing productivity multiplier
**Labels:** `enhancement`, `feature-request`, `testing`, `priority-medium`

## Summary

Add a model factory system that provides a fluent API for generating test data — eliminating boilerplate in test setup and making tests more readable, maintainable, and focused on behavior rather than data construction.

## Justification

### Testing without factories is painful

Currently, every Wheels test that needs model instances must manually construct them:

```cfm
// Current approach — verbose, brittle, repetitive
function setup() {
    user = model("User").create(
        email="test@example.com",
        firstName="John",
        lastName="Doe",
        password="password123",
        passwordConfirmation="password123",
        role="member",
        status="active",
        emailVerifiedAt=Now()
    );
    order = model("Order").create(
        userId=user.id,
        status="pending",
        total=99.99,
        shippingAddress="123 Main St",
        billingAddress="123 Main St"
    );
}
```

Problems with this approach:
- **Verbose** — 10+ lines just to set up one test scenario
- **Brittle** — Adding a required column breaks every test
- **Duplicated** — Same setup code copied across dozens of test files
- **Obscures intent** — Hard to see what's being tested vs. what's boilerplate

### Every major framework has solved this

| Framework | Solution | Key Feature |
|-----------|----------|-------------|
| **Laravel** | Eloquent Factories | `User::factory()->count(3)->create()` — built into framework |
| **Rails** | FactoryBot | `create(:user, :admin)` — de facto standard gem |
| **Django** | Factory Boy / Model Bakery | `baker.make(User)` — auto-generates valid data |
| **AdonisJS** | Lucid Factories | `UserFactory.merge({role: 'admin'}).create()` |
| **Phoenix** | ExMachina | `insert(:user, role: :admin)` — standard community lib |
| **Wheels** | **Nothing** | Manual `model("X").create()` with all fields |

### Factories make TDD practical

Without factories, writing tests feels like a chore. With factories, test setup becomes a one-liner, which dramatically increases test coverage because developers actually enjoy writing tests.

## Specification

### Factory Definition

```cfm
// tests/factories/UserFactory.cfc
component extends="wheels.Factory" {

    function definition() {
        return {
            email: fake("email"),
            firstName: fake("firstName"),
            lastName: fake("lastName"),
            password: "password123",
            passwordConfirmation: "password123",
            role: "member",
            status: "active",
            emailVerifiedAt: Now()
        };
    }

    // Named states — override specific attributes
    function admin() {
        return { role: "admin" };
    }

    function unverified() {
        return { emailVerifiedAt: "" };
    }

    function suspended() {
        return { status: "suspended" };
    }

    // Relationship: auto-create associated records
    function withOrders(numeric count=3) {
        return { _after: function(user) {
            factory("Order").count(arguments.count).create(userId=user.id);
        }};
    }
}
```

### Factory Usage in Tests

```cfm
component extends="wheels.WheelsTest" {
    function run() {
        describe("Order Processing", function() {

            it("calculates total for active users", function() {
                // Create a single user with defaults
                var user = factory("User").create();

                // Create with specific overrides
                var admin = factory("User").admin().create();

                // Create multiple
                var users = factory("User").count(5).create();

                // Create without persisting (for unit tests)
                var unsaved = factory("User").make();

                // Create with relationships
                var userWithOrders = factory("User").withOrders(3).create();

                // Override specific attributes
                var vip = factory("User").create(
                    email="vip@example.com",
                    role="vip"
                );

                // Combine states
                var suspendedAdmin = factory("User").admin().suspended().create();

                expect(user.id).toBeGT(0);
                expect(admin.role).toBe("admin");
                expect(users.recordCount).toBe(5);
            });

            it("sends welcome email to verified users", function() {
                var verified = factory("User").create();
                var unverified = factory("User").unverified().create();

                // Test focuses on behavior, not data setup
                expect(shouldSendWelcome(verified)).toBeTrue();
                expect(shouldSendWelcome(unverified)).toBeFalse();
            });
        });
    }
}
```

### Fake Data Generators

```cfm
// Built-in fake data helpers (used inside factory definitions)
fake("email")          // "john.doe42@example.com"
fake("firstName")      // "Sarah"
fake("lastName")       // "Johnson"
fake("fullName")       // "Michael Chen"
fake("sentence")       // "The quick brown fox..."
fake("paragraph")      // Multi-sentence text
fake("number", 1, 100) // Random integer 1-100
fake("decimal", 0, 999.99)  // Random decimal
fake("date", -365, 0)  // Random date within last year
fake("boolean")        // true or false
fake("uuid")           // UUID string
fake("phone")          // "(555) 123-4567"
fake("address")        // "123 Oak Street"
fake("city")           // "Springfield"
fake("state")          // "CA"
fake("zip")            // "90210"
fake("url")            // "https://example.com/page"
fake("ipAddress")      // "192.168.1.42"
fake("color")          // "#3a7bd5"
fake("pick", ["a","b","c"])  // Random element from list
```

### Sequence Support (Unique Values)

```cfm
// Ensure unique values across factory calls in a test
function definition() {
    return {
        email: sequence(function(n) { return "user#n#@example.com"; }),
        username: sequence("user_"),  // user_1, user_2, user_3...
        employeeId: sequence(1000)    // 1000, 1001, 1002...
    };
}
```

### Generator Command

```bash
# Generate a factory for an existing model
wheels generate factory User

# Auto-detects columns from model/migration and generates sensible defaults
# Output: tests/factories/UserFactory.cfc
```

### Files Generated / Modified

| Component | File | Purpose |
|-----------|------|---------|
| **Base class** | `wheels/Factory.cfc` | Factory DSL, `create()`, `make()`, `count()`, states |
| **Fake data** | `wheels/testing/Faker.cfc` | Fake data generators |
| **Sequence** | `wheels/testing/Sequence.cfc` | Unique value sequences |
| **Test helper** | `wheels/testing/FactoryHelper.cfc` | `factory()` global function |
| **Generator** | `wheels generate factory` | CLI to scaffold factories |
| **Directory** | `tests/factories/` | Convention for factory files |

### Transaction Cleanup

```cfm
// Factories automatically wrap test data in transactions
// that roll back after each test — no manual cleanup needed
component extends="wheels.WheelsTest" {
    function run() {
        // Each `it()` block gets a clean database automatically
        // factory-created records are rolled back after each test
    }
}
```

## Impact Assessment

- **Testing velocity:** 3-5x faster test writing — setup becomes one-liners
- **Test coverage:** Developers write more tests when it's easy
- **Maintainability:** Adding a column only requires updating one factory, not 50 tests
- **Readability:** Tests clearly show what's being tested vs. what's just setup

## References

- Laravel Factories: https://laravel.com/docs/eloquent-factories
- Rails FactoryBot: https://github.com/thoughtbot/factory_bot
- Django Factory Boy: https://factoryboy.readthedocs.io/
- AdonisJS Factories: https://docs.adonisjs.com/guides/model-factories
