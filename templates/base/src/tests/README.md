# Wheels Testing Quick Start

This directory contains the test suite for your Wheels application using TestBox.

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
box testbox run

# Run specific directory
box testbox run --directory=tests/specs/unit

# Watch mode for TDD
box testbox watch
```

Or visit: `http://localhost/tests/runner.cfm`

### 3. Write Your First Test

```cfc
component extends="tests.BaseSpec" {
	function beforeAll(){
			// setup test data
	}
	function afterAll(){
			// clean up test data
	}
    
    function run() {
        describe("My Feature", function() {
            
            it("should work as expected", function() {
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
describe("User Model", function() {
    beforeEach() {
        variables.user = model("User").new();
    });
    
    it("should validate email", function() {
        user.email = "invalid";
        expect(user.valid()).toBeFalse();
        assertHasErrors(user, "email");
    });
});
```

### Testing Controllers

```cfc
describe("UsersController", function() {
    it("should list users", function() {
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
- [Testing with TestBox Guide](/docs/testing-with-testbox.md)
- [TestBox Documentation](https://testbox.ortusbooks.com/)
- [Wheels Testing Guide](https://wheels.dev/3.0.0/guides/working-with-wheels/testing-your-application)