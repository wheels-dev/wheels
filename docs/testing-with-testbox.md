# Testing with TestBox in Wheels 3.0

Wheels 3.0 has transitioned from RocketUnit to TestBox as its testing framework, providing a modern BDD (Behavior-Driven Development) testing experience with powerful features and better integration.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Test Structure](#test-structure)
3. [Writing Tests](#writing-tests)
4. [Running Tests](#running-tests)
5. [Test Helpers](#test-helpers)
6. [Migrating from RocketUnit](#migrating-from-rocketunit)
7. [Best Practices](#best-practices)
8. [Advanced Features](#advanced-features)

## Getting Started

### Test Directory Structure

```
tests/
├── BaseSpec.cfc          # Base test class with Wheels integration
├── runner.cfm            # TestBox runner with parallel execution support
├── specs/
│   ├── unit/            # Unit tests for isolated components
│   │   ├── models/
│   │   ├── helpers/
│   │   └── libraries/
│   ├── integration/     # Integration tests for component interactions
│   │   ├── controllers/
│   │   ├── routing/
│   │   └── api/
│   └── functional/      # End-to-end workflow tests
│       ├── features/
│       └── workflows/
├── fixtures/            # Test data and mocks
│   ├── data/
│   └── mocks/
└── support/            # Test utilities
    ├── factories/
    └── helpers/
```

### Creating Your First Test

Use the Wheels CLI to generate a test:

```bash
# Generate a model test
wheels generate test model User

# Generate a controller test with CRUD examples
wheels generate test controller Users --crud

# Generate an API test with mocks
wheels generate test api v1.users --mock
```

## Test Structure

### Basic Test Structure

All tests extend `BaseSpec.cfc` which provides Wheels-specific helpers:

```cfc
component extends="tests.BaseSpec" {
    
    function run() {
        
        describe("User Model", () => {
            
            beforeEach(() => {
                variables.user = model("User").new();
            });
            
            it("should validate email presence", () => {
                user.email = "";
                expect(user.valid()).toBeFalse();
                assertHasErrors(user, "email");
            });
            
        });
    }
}
```

### Lifecycle Methods

TestBox provides lifecycle hooks for setup and teardown:

```cfc
describe("Feature", () => {
    
    beforeAll(() => {
        // Runs once before all tests in this describe block
    });
    
    afterAll(() => {
        // Runs once after all tests in this describe block
    });
    
    beforeEach(() => {
        // Runs before each test
    });
    
    afterEach(() => {
        // Runs after each test
    });
    
    // Tests go here
});
```

## Writing Tests

### Model Tests

```cfc
describe("Product Model", () => {
    
    beforeEach(() => {
        variables.product = build("product");
    });
    
    describe("Validations", () => {
        
        it("should require a name", () => {
            product.name = "";
            expect(product.valid()).toBeFalse();
            assertHasErrors(product, "name");
        });
        
        it("should validate price is numeric", () => {
            product.price = "not a number";
            expect(product.valid()).toBeFalse();
            assertHasErrors(product, "price");
        });
        
    });
    
    describe("Methods", () => {
        
        it("should calculate discount price", () => {
            product.price = 100;
            product.discountPercent = 20;
            expect(product.getDiscountPrice()).toBe(80);
        });
        
    });
    
    describe("Associations", () => {
        
        it("should belong to a category", () => {
            expect(product).toHaveMethod("category");
        });
        
        it("should have many reviews", () => {
            expect(product).toHaveMethod("reviews");
        });
        
    });
});
```

### Controller Tests

```cfc
describe("ProductsController", () => {
    
    beforeEach(() => {
        // Login as admin user
        variables.admin = create("user", {role: "admin"});
        loginAs(admin.id);
    });
    
    afterEach(() => {
        logout();
    });
    
    describe("index action", () => {
        
        it("should return a list of products", () => {
            // Create test data
            createList("product", 3);
            
            var result = processRequest(
                route = "products",
                method = "GET"
            );
            
            expect(result.status).toBe(200);
            expect(result.output).toInclude("Products");
        });
        
        it("should paginate results", () => {
            createList("product", 25);
            
            var result = processRequest(
                route = "products",
                method = "GET",
                params = {page: 2, perPage: 10}
            );
            
            expect(result.status).toBe(200);
            // Assert pagination is working
        });
        
    });
    
    describe("create action", () => {
        
        it("should create a new product", () => {
            var params = {
                product: {
                    name: "Test Product",
                    price: 99.99,
                    categoryId: create("category").id
                }
            };
            
            var result = processRequest(
                route = "products",
                method = "POST",
                params = params
            );
            
            expect(result.status).toBe(302); // Redirect on success
            
            var created = model("Product").findOne(where="name='Test Product'");
            expect(created).toBeInstanceOf("app.models.Product");
        });
        
        it("should handle validation errors", () => {
            var params = {
                product: {name: ""} // Invalid
            };
            
            var result = processRequest(
                route = "products",
                method = "POST",
                params = params
            );
            
            expect(result.status).toBe(200); // Re-render form
            expect(result.output).toInclude("error");
        });
        
    });
});
```

### API Tests

```cfc
describe("Products API v1", () => {
    
    beforeEach(() => {
        variables.apiKey = create("apiKey");
        variables.headers = {
            "Authorization": "Bearer #apiKey.token#",
            "Content-Type": "application/json"
        };
    });
    
    describe("GET /api/v1/products", () => {
        
        it("should return paginated products", () => {
            createList("product", 5);
            
            var result = apiRequest(
                route = "api/v1/products",
                method = "GET",
                headers = variables.headers
            );
            
            expect(result.status).toBe(200);
            expect(result.json.data).toBeArray();
            expect(arrayLen(result.json.data)).toBe(5);
            expect(result.json).toHaveKey("pagination");
        });
        
        it("should filter by category", () => {
            var electronics = create("category", {name: "Electronics"});
            create("product", {categoryId: electronics.id});
            create("product", {categoryId: create("category").id});
            
            var result = apiRequest(
                route = "api/v1/products",
                method = "GET",
                data = {categoryId: electronics.id},
                headers = variables.headers
            );
            
            expect(result.status).toBe(200);
            expect(arrayLen(result.json.data)).toBe(1);
        });
        
    });
    
    describe("POST /api/v1/products", () => {
        
        it("should create a product", () => {
            var data = {
                name: "API Product",
                price: 149.99,
                sku: "API-001"
            };
            
            var result = apiRequest(
                route = "api/v1/products",
                method = "POST",
                data = data,
                headers = variables.headers
            );
            
            expect(result.status).toBe(201);
            expect(result.json.data).toHaveKey("id");
            expect(result.json.data.name).toBe("API Product");
        });
        
        it("should validate required fields", () => {
            var result = apiRequest(
                route = "api/v1/products",
                method = "POST",
                data = {name: ""}, // Invalid
                headers = variables.headers
            );
            
            expect(result.status).toBe(422);
            expect(result.json).toHaveKey("errors");
        });
        
    });
});
```

## Running Tests

### Command Line

```bash
# Run all tests
box testbox run

# Run specific directory
box testbox run --directory=tests/specs/unit

# Run with coverage (requires FusionReactor)
box testbox run --coverage

# Run specific test bundle
box testbox run --testBundles=UserSpec.cfc

# Watch mode for TDD
box testbox watch
```

### Web Runner

Access the test runner at: `http://localhost/tests/runner.cfm`

Options:
- `?reporter=json` - JSON output
- `?reporter=junit` - JUnit XML output
- `?coverage=true` - Enable code coverage
- `?parallel=false` - Disable parallel execution

### CI/CD Integration

Example GitHub Actions workflow:

```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        cfengine: ["lucee@5", "adobe@2021"]
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup CommandBox
        uses: Ortus-Solutions/setup-commandbox@v2
        
      - name: Install Dependencies
        run: box install
        
      - name: Start Server
        run: box server start cfengine=${{ matrix.cfengine }}
        
      - name: Run Tests
        run: box testbox run --reporter=junit --outputFile=test-results.xml
        
      - name: Upload Test Results
        uses: actions/upload-artifact@v3
        with:
          name: test-results-${{ matrix.cfengine }}
          path: test-results.xml
```

## Test Helpers

BaseSpec.cfc provides numerous helpers for Wheels testing:

### Model Helpers

```cfc
// Get a model instance
var user = model("User");

// Create and save test data
var product = create("product", {name: "Test Product"});

// Build without saving
var order = build("order");

// Create multiple
var users = createList("user", 5);
```

### Controller Helpers

```cfc
// Get controller instance
var controller = controller("Products");

// Set request params
params({id: 1, format: "json"});

// Process a request
var result = processRequest(
    route = "products/1",
    method = "GET"
);
```

### Authentication Helpers

```cfc
// Login as user
loginAs(userId);

// Check login status
if (isLoggedIn()) {
    // ...
}

// Logout
logout();
```

### Request Helpers

```cfc
// Make API request
var result = apiRequest(
    route = "api/products",
    method = "POST",
    data = {name: "New Product"},
    headers = {"X-API-Key": "secret"}
);

// Access JSON response
expect(result.json.success).toBeTrue();
```

### Assertion Helpers

```cfc
// Model assertions
assertHasErrors(model);
assertHasErrors(model, "email");
assertNoErrors(model);

// Controller assertions
assertRedirected(controller);
assertRedirected(controller, "/products");
assertRendered(controller);
assertRendered(controller, "edit");
```

## Migrating from RocketUnit

### Automated Migration

Use the CLI to migrate existing tests:

```bash
# Migrate a single file
wheels test migrate tests/models/UserTest.cfc

# Migrate a directory
wheels test migrate tests/models --recursive

# Dry run to preview changes
wheels test migrate tests --dry-run

# Generate migration report
wheels test migrate tests --report
```

### Manual Migration Guide

#### 1. Update Component Extends

```cfc
// Old
component extends="tests.Test" {

// New
component extends="tests.BaseSpec" {
```

#### 2. Wrap Tests in run() and describe()

```cfc
// Old
function testUserValidation() {
    // test code
}

// New
function run() {
    describe("User", () => {
        it("should validate", () => {
            // test code
        });
    });
}
```

#### 3. Convert Assertions

```cfc
// Old
assert("user.valid()");
assert("len(user.email) > 0");
assert("user.age == 25");

// New
expect(user.valid()).toBeTrue();
expect(len(user.email)).toBeGT(0);
expect(user.age).toBe(25);
```

#### 4. Update Lifecycle Methods

```cfc
// Old
function setup() {
    // setup code
}

// New
beforeEach(() => {
    // setup code
});
```

### Common Assertion Mappings

| RocketUnit | TestBox |
|------------|---------|
| `assert("expression")` | `expect(expression).toBeTrue()` |
| `assert("!expression")` | `expect(expression).toBeFalse()` |
| `assert("a == b")` | `expect(a).toBe(b)` |
| `assert("a != b")` | `expect(a).notToBe(b)` |
| `assert("a > b")` | `expect(a).toBeGT(b)` |
| `assert("a < b")` | `expect(a).toBeLT(b)` |
| `assert("isArray(x)")` | `expect(x).toBeArray()` |
| `assert("structKeyExists(s, 'key')")` | `expect(s).toHaveKey("key")` |

## Best Practices

### 1. Use Descriptive Test Names

```cfc
// Bad
it("test1", () => {});

// Good
it("should validate email format", () => {});
it("should return 404 for non-existent product", () => {});
```

### 2. Follow AAA Pattern

```cfc
it("should calculate total with tax", () => {
    // Arrange
    var order = create("order", {subtotal: 100});
    var taxRate = 0.08;
    
    // Act
    var total = order.calculateTotal(taxRate);
    
    // Assert
    expect(total).toBe(108);
});
```

### 3. Use Factories for Test Data

```cfc
// Define factory in FactoryService
define("user", function(factory) {
    return {
        firstName: factory.fake().firstName(),
        lastName: factory.fake().lastName(),
        email: factory.fake().email(),
        password: factory.fake().password()
    };
});

// Use in tests
var user = create("user");
var admin = create("user", {role: "admin"});
```

### 4. Isolate Tests with Transactions

Tests automatically run in transactions that roll back, ensuring test isolation:

```cfc
it("should not affect other tests", () => {
    // This will be rolled back
    create("user", {email: "test@example.com"});
    
    // Test something
    expect(model("User").count()).toBe(1);
});

it("should start with clean database", () => {
    // Previous test's data is gone
    expect(model("User").count()).toBe(0);
});
```

### 5. Test Edge Cases

```cfc
describe("Price Calculation", () => {
    
    it("should handle zero quantity", () => {
        var item = build("orderItem", {quantity: 0, price: 10});
        expect(item.getTotal()).toBe(0);
    });
    
    it("should handle negative prices gracefully", () => {
        var item = build("orderItem", {quantity: 1, price: -10});
        expect(() => {
            item.getTotal();
        }).toThrow("InvalidPriceException");
    });
    
});
```

## Advanced Features

### Data Providers

Use data providers for parameterized tests:

```cfc
function emailProvider() {
    return [
        {email: "valid@example.com", valid: true},
        {email: "invalid.email", valid: false},
        {email: "@example.com", valid: false},
        {email: "test@", valid: false}
    ];
}

it("should validate various email formats", (data) => {
    var user = model("User").new(email: data.email);
    expect(user.valid()).toBe(data.valid);
}, emailProvider());
```

### Mocking

```cfc
// Create a mock
var mockService = createMock("app.services.EmailService");

// Define behavior
mockService.$("send", true); // Always return true

// Inject into component
controller.setEmailService(mockService);

// Verify interactions
expect(mockService.$count("send")).toBe(1);
expect(mockService.$callLog().send[1].to).toBe("user@example.com");
```

### Custom Matchers

```cfc
// Define custom matcher
function toBeWithinRange(actual, expected, range) {
    return abs(actual - expected) <= range;
}

// Register matcher
addMatchers({
    toBeWithinRange: toBeWithinRange
});

// Use in tests
expect(calculatePi()).toBeWithinRange(3.14159, 0.00001);
```

### Performance Testing

```cfc
it("should complete within performance threshold", () => {
    var startTime = getTickCount();
    
    // Run operation 100 times
    for (var i = 1; i <= 100; i++) {
        processLargeDataSet();
    }
    
    var duration = getTickCount() - startTime;
    expect(duration).toBeLT(1000); // Less than 1 second
});
```

### Focused and Skipped Tests

```cfc
// Run only this test
fit("should run in isolation", () => {
    // This test runs alone
});

// Skip this test
it("should be implemented later", () => {
    skip("Waiting for API to be ready");
});
```

## VS Code Integration

Install the Wheels test snippets by copying `.vscode/wheels-test.code-snippets` to your project.

Available snippets:
- `tbspec` - Create a TestBox spec
- `tbmodel` - Create a model test
- `tbcontroller` - Create a controller test
- `it` - Create an it() block
- `expect` - Create an expectation
- `processrequest` - Process a request
- `create` - Create test data with factory

## Troubleshooting

### Common Issues

1. **Tests not found**: Ensure your test files end with `Spec.cfc` or `Test.cfc`
2. **Transaction errors**: Some operations can't run in transactions. Use `transaction action="commit"` if needed
3. **Async issues**: Use `waitFor()` or increase timeout for async operations
4. **Memory issues**: Reduce parallel threads or split large test suites

### Debugging Tests

```cfc
// Output debug information
debug("Current user: #user.email#");

// Dump variables
writeDump(var=result, abort=true);

// Check test context
expect(getCurrentContext()).toBe("tests.specs.unit.UserSpec");
```

## Additional Resources

- [TestBox Documentation](https://testbox.ortusbooks.com/)
- [Wheels Testing Guide](https://guides.cfwheels.org/docs/testing)
- [Example Test Suite](https://github.com/cfwheels/cfwheels/tree/develop/tests)

## Contributing

When contributing to Wheels:

1. Write tests for new features
2. Ensure all tests pass on multiple CFML engines
3. Follow the existing test patterns
4. Include integration tests for complex features
5. Update test documentation as needed