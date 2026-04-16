# Wheels Testing Quick Start

This directory contains the test suite for your Wheels application using WheelsTest.

## Quick Start

### 1. Generate a Test

```bash
# Model test
wheels generate test model User

# Controller test with CRUD
wheels generate test controller Users --crud

# API test
wheels generate test api v1.users
```

### 2. Run Tests

```bash
# Run all tests
wheels test run

# Run specific directory
wheels test run --directory=tests/specs/unit

# Watch mode for TDD
wheels test watch
```

Or visit: `http://localhost/tests/runner.cfm`

### 3. Write Your First Test

```cfc
component extends="wheels.WheelsTest" {
    
    function run() {
        describe("My Feature", () => {
            
            it("should work as expected", () => {
                expect(true).toBeTrue();
            });
            
        });
    }
}
```

## Directory Structure

- `BaseSpec.cfc` - Base test class with Wheels helpers
- `runner.cfm` - Web-based test runner
- `specs/` - Test specifications
  - `unit/` - Isolated unit tests
  - `integration/` - Integration tests
  - `functional/` - End-to-end tests
- `fixtures/` - Test data and fixtures
- `support/` - Test utilities and factories

## Common Test Patterns

### Testing Models

```cfc
describe("User Model", () => {
    beforeEach(() => {
        variables.user = model("User").new();
    });
    
    it("should validate email", () => {
        user.email = "invalid";
        expect(user.valid()).toBeFalse();
        assertHasErrors(user, "email");
    });
});
```

### Testing Controllers

```cfc
describe("UsersController", () => {
    it("should list users", () => {
        var result = processRequest(
            route = "users",
            method = "GET"
        );
        expect(result.status).toBe(200);
    });
});
```

### Using Factories

```cfc
// Create and save
var user = create("user", {role: "admin"});

// Build without saving
var product = build("product");

// Create multiple
var orders = createList("order", 5);
```

## Test Helpers

- `model(name)` - Get a model instance
- `controller(name)` - Get a controller instance
- `create(factory, attributes)` - Create test data
- `build(factory, attributes)` - Build without saving
- `processRequest(route, method, params)` - Process HTTP request
- `loginAs(userId)` - Login as user for testing
- `assertHasErrors(model, property)` - Assert validation errors

## Migrating from RocketUnit

```bash
# Migrate a single file
wheels test migrate path/to/test.cfc

# Migrate all tests
wheels test migrate tests --recursive
```

## Tips

1. Tests run in transactions that roll back automatically
2. Use descriptive test names that explain the behavior
3. Follow the AAA pattern: Arrange, Act, Assert
4. Run tests before committing code
5. Use `fit()` to focus on a single test during development

## Documentation

For comprehensive documentation, see:
- [Wheels Testing Guide](https://wheels.dev/3.1.0/guides/working-with-wheels/testing-your-application)
- [BDD syntax reference (upstream TestBox docs)](https://testbox.ortusbooks.com/) — WheelsTest inherits the same BDD syntax as upstream Ortus TestBox