# Testing Guide

Comprehensive guide to testing in Wheels applications using the CLI.

## Overview

Wheels CLI provides robust testing capabilities through TestBox integration, offering:
- Unit and integration testing
- BDD-style test writing
- Watch mode for continuous testing
- Code coverage reporting
- Parallel test execution
- Docker-based testing across multiple engines and databases

## Test Structure

### Directory Layout

```
/tests/
├── Application.cfc          # Test suite configuration
├── specs/                   # Test specifications (alternative to folders below)
├── unit/                    # Unit tests
│   ├── models/             # Model tests
│   ├── controllers/        # Controller tests
│   └── services/           # Service tests
├── integration/            # Integration tests
├── fixtures/               # Test data files
└── helpers/                # Test utilities
```

### Test File Naming

Follow these conventions:
- Model tests: `UserTest.cfc` or `UserSpec.cfc`
- Controller tests: `UsersControllerTest.cfc`
- Integration tests: `UserFlowTest.cfc`

## Writing Tests

### Basic Test Structure

```cfc
// tests/unit/models/UserTest.cfc
component extends="testbox.system.BaseSpec" {

    function run() {
        describe("User Model", function() {

            beforeEach(function() {
                // Setup before each test
                variables.user = model("User").new();
            });

            afterEach(function() {
                // Cleanup after each test
            });

            it("validates email presence", function() {
                variables.user.email = "";
                expect(variables.user.valid()).toBeFalse();
                expect(variables.user.errors).toHaveKey("email");
            });

            it("validates email format", function() {
                variables.user.email = "invalid-email";
                expect(variables.user.valid()).toBeFalse();
                expect(variables.user.errors.email).toInclude("valid email");
            });

        });
    }

}
```

### Model Testing

```cfc
component extends="testbox.system.BaseSpec" {

    function run() {
        describe("Product Model", function() {

            describe("Validations", function() {
                it("requires a name", function() {
                    var product = model("Product").new();
                    expect(product.valid()).toBeFalse();
                    expect(product.errors).toHaveKey("name");
                });

                it("requires price to be positive", function() {
                    var product = model("Product").new(
                        name = "Test Product",
                        price = -10
                    );
                    expect(product.valid()).toBeFalse();
                    expect(product.errors.price).toInclude("greater than 0");
                });
            });

            describe("Associations", function() {
                it("has many reviews", function() {
                    var product = model("Product").findOne();
                    expect(product).toHaveKey("reviews");
                    expect(product.reviews()).toBeQuery();
                });
            });

            describe("Scopes", function() {
                it("filters active products", function() {
                    // Create test data
                    model("Product").create(name="Active", active=true);
                    model("Product").create(name="Inactive", active=false);

                    var activeProducts = model("Product").active().findAll();
                    expect(activeProducts.recordCount).toBe(1);
                    expect(activeProducts.name).toBe("Active");
                });
            });

        });
    }

}
```

### Controller Testing

```cfc
component extends="testbox.system.BaseSpec" {

    function beforeAll() {
        // Setup test request context
        variables.mockController = prepareMock(createObject("component", "controllers.Products"));
    }

    function run() {
        describe("Products Controller", function() {

            describe("index action", function() {
                it("returns all products", function() {
                    // Setup
                    var products = queryNew("id,name", "integer,varchar", [
                        [1, "Product 1"],
                        [2, "Product 2"]
                    ]);

                    mockController.$("model").$args("Product").$returns(
                        mockModel.$("findAll").$returns(products)
                    );

                    // Execute
                    mockController.index();

                    // Assert
                    expect(mockController.products).toBe(products);
                    expect(mockController.products.recordCount).toBe(2);
                });
            });

            describe("create action", function() {
                it("creates product with valid data", function() {
                    // Setup params
                    mockController.params = {
                        product: {
                            name: "New Product",
                            price: 99.99
                        }
                    };

                    // Mock successful save
                    var mockProduct = createEmptyMock("models.Product");
                    mockProduct.$("save").$returns(true);
                    mockProduct.$("id", 123);

                    mockController.$("model").$args("Product").$returns(
                        createMock("models.Product").$("new").$returns(mockProduct)
                    );

                    // Execute
                    mockController.create();

                    // Assert
                    expect(mockController.flashMessages.success).toInclude("created successfully");
                    expect(mockController.redirectTo.action).toBe("show");
                    expect(mockController.redirectTo.key).toBe(123);
                });
            });

        });
    }

}
```

### Integration Testing

```cfc
component extends="testbox.system.BaseSpec" {

    function run() {
        describe("User Registration Flow", function() {

            it("allows new user to register", function() {
                // Visit registration page
                var event = execute(event="users.new", renderResults=true);
                expect(event.getRenderedContent()).toInclude("Register");

                // Submit registration form
                var event = execute(
                    event = "users.create",
                    eventArguments = {
                        user: {
                            email: "test@example.com",
                            password: "SecurePass123!",
                            passwordConfirmation: "SecurePass123!"
                        }
                    }
                );

                // Verify user created
                var user = model("User").findOne(where="email='test@example.com'");
                expect(user).toBeObject();

                // Verify logged in
                expect(session.userId).toBe(user.id);

                // Verify redirect
                expect(event.getValue("relocate_URI")).toBe("/dashboard");
            });

        });
    }

}
```

## Test Helpers

### Creating Test Factories

```cfc
// tests/helpers/Factories.cfc
component {

    function createUser(struct overrides = {}) {
        var defaults = {
            email: "user#createUUID()#@test.com",
            password: "password123",
            firstName: "Test",
            lastName: "User"
        };

        defaults.append(arguments.overrides);
        return model("User").create(defaults);
    }

    function createProduct(struct overrides = {}) {
        var defaults = {
            name: "Product #createUUID()#",
            price: randRange(10, 100),
            stock: randRange(0, 50)
        };

        defaults.append(arguments.overrides);
        return model("Product").create(defaults);
    }

}
```

### Test Data Management

```cfc
// tests/helpers/TestDatabase.cfc
component {

    function setUp() {
        // Start transaction
        transaction action="begin";
    }

    function tearDown() {
        // Rollback transaction
        transaction action="rollback";
    }

    function clean() {
        // Clean specific tables
        queryExecute("DELETE FROM users WHERE email LIKE '%@test.com'");
        queryExecute("DELETE FROM products WHERE name LIKE 'Test%'");
    }

    function loadFixtures(required string name) {
        var fixtures = deserializeJSON(
            fileRead("/tests/fixtures/#arguments.name#.json")
        );

        for (var record in fixtures) {
            queryExecute(
                "INSERT INTO #arguments.name# (#structKeyList(record)#)
                 VALUES (#structKeyList(record, ':')#)",
                record
            );
        }
    }

}
```

## Running Tests

### Basic Commands

```bash
# Run all tests
wheels test run

# Run specific test file
wheels test run tests/unit/models/UserTest.cfc

# Run tests in directory
wheels test run tests/unit/models/

# Run with specific reporter
wheels test run --reporter=json
wheels test run --reporter=junit --outputFile=results.xml
```

### Watch Mode

```bash
# Watch for changes and rerun tests
wheels test run --watch

# Watch specific directory
wheels test run tests/models --watch

# Watch with custom debounce
wheels test run --watch --watchDelay=1000
```

### Filtering Tests

```bash
# Run by test bundles
wheels test run --bundles=models,controllers

# Run by labels
wheels test run --labels=critical

# Run by test name pattern
wheels test run --filter="user"

# Exclude patterns
wheels test run --excludes="slow,integration"
```

## Code Coverage

### Generate Coverage Report

```bash
# Generate HTML coverage report
wheels test coverage

# With custom output directory
wheels test coverage --outputDir=coverage-reports

# Include only specific paths
wheels test coverage --includes="models/,controllers/"
```

### Coverage Configuration

In `tests/Application.cfc`:

```cfc
this.coverage = {
    enabled: true,
    includes: ["models", "controllers"],
    excludes: ["tests", "wheels"],
    outputDir: expandPath("/tests/coverage/"),
    reportFormats: ["html", "json"]
};
```

## Test Configuration

### Test Suite Configuration

```cfc
// tests/Application.cfc
component {

    this.name = "WheelsTestSuite" & Hash(GetCurrentTemplatePath());

    // Test datasource
    this.datasources["test"] = {
        url: "jdbc:h2:mem:test;MODE=MySQL",
        driver: "org.h2.Driver"
    };
    this.datasource = "test";

    // TestBox settings
    this.testbox = {
        bundles: ["tests"],
        recurse: true,
        reporter: "simple",
        reportpath: "/tests/results",
        runner: ["tests/runner.cfm"],
        labels: [],
        options: {}
    };

}
```

### Environment Variables

```bash
# Set test environment
export WHEELS_ENV=testing

# Set test datasource
export WHEELS_TEST_DATASOURCE=myapp_test

# Enable verbose output
export TESTBOX_VERBOSE=true
```

## Testing Best Practices

### 1. Test Organization

```
tests/
├── unit/              # Fast, isolated tests
│   ├── models/       # One file per model
│   └── services/     # Service layer tests
├── integration/      # Tests with dependencies
└── e2e/             # End-to-end tests
```

### 2. Test Isolation

```cfc
describe("User Model", function() {

    beforeEach(function() {
        // Fresh instance for each test
        variables.user = model("User").new();

        // Clear caches
        application.wheels.cache.queries = {};
    });

    afterEach(function() {
        // Clean up test data
        if (isDefined("variables.user.id")) {
            variables.user.delete();
        }
    });

});
```

### 3. Descriptive Tests

```cfc
// Good: Descriptive test names
it("validates email format with standard RFC 5322 regex", function() {
    // test implementation
});

it("prevents duplicate email addresses case-insensitively", function() {
    // test implementation
});

// Bad: Vague test names
it("works", function() {
    // test implementation
});
```

### 4. AAA Pattern

```cfc
it("calculates order total with tax", function() {
    // Arrange
    var order = createOrder();
    var item1 = createOrderItem(price: 100, quantity: 2);
    var item2 = createOrderItem(price: 50, quantity: 1);
    order.addItem(item1);
    order.addItem(item2);

    // Act
    var total = order.calculateTotal(taxRate: 0.08);

    // Assert
    expect(total).toBe(270); // (200 + 50) * 1.08
});
```

## Continuous Integration

### GitHub Actions

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2

    - name: Setup CommandBox
      uses: Ortus-Solutions/setup-commandbox@v2.0.0

    - name: Install dependencies
      run: box install

    - name: Run tests
      run: |
        box server start
        wheels test run --reporter=junit --outputFile=test-results.xml

    - name: Upload test results
      uses: actions/upload-artifact@v4
      with:
        name: test-results
        path: test-results.xml

    - name: Generate coverage
      run: wheels test coverage

    - name: Upload coverage
      uses: codecov/codecov-action@v1
```

### Pre-commit Hooks

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running tests..."
wheels test run --labels=unit

if [ $? -ne 0 ]; then
    echo "Tests failed! Commit aborted."
    exit 1
fi

echo "Running linter..."
wheels analyze code

if [ $? -ne 0 ]; then
    echo "Code quality check failed!"
    exit 1
fi
```

## Debugging Tests

### Using Debug Output

```cfc
it("processes data correctly", function() {
    var result = processData(testData);

    // Debug output
    debug(result);
    writeDump(var=result, abort=false);

    // Conditional debugging
    if (request.debug ?: false) {
        writeOutput("Result: #serializeJSON(result)#");
    }

    expect(result.status).toBe("success");
});
```

### Interactive Debugging

```bash
# Run specific test with debugging
wheels test debug tests/unit/models/UserTest.cfc

# Enable verbose mode
wheels test run --verbose

# Show SQL queries
wheels test run --showSQL
```

## Performance Testing

### Load Testing

```cfc
describe("Performance", function() {

    it("handles 1000 concurrent users", function() {
        var threads = [];

        for (var i = 1; i <= 1000; i++) {
            arrayAppend(threads, function() {
                var result = model("Product").findAll();
                return result.recordCount;
            });
        }

        var start = getTickCount();
        var results = parallel(threads);
        var duration = getTickCount() - start;

        expect(duration).toBeLT(5000); // Less than 5 seconds
        expect(arrayLen(results)).toBe(1000);
    });

});
```

## Common Testing Patterns

### Testing Private Methods

```cfc
it("tests private method", function() {
    var user = model("User").new();

    // Use makePublic() for testing
    makePublic(user, "privateMethod");

    var result = user.privateMethod();
    expect(result).toBe("expected");
});
```

### Mocking External Services

```cfc
it("sends email on user creation", function() {
    // Mock email service
    var mockMailer = createEmptyMock("services.Mailer");
    mockMailer.$("send").$returns(true);

    // Inject mock
    var user = model("User").new();
    user.$property("mailer", mockMailer);

    // Test
    user.save();

    // Verify
    expect(mockMailer.$times("send")).toBe(1);
    expect(mockMailer.$callLog().send[1].to).toBe(user.email);
});
```

## Docker-Based Testing

Wheels provides a comprehensive Docker environment for testing across multiple CFML engines and databases.

### Quick Start with Docker

```bash
# Start the TestUI and all test containers
docker compose --profile all up -d

# Access the TestUI
open http://localhost:3000
```

### TestUI Features

The modern TestUI provides:
- **Visual Test Runner**: Run and monitor tests in real-time
- **Container Management**: Start/stop containers directly from the UI
- **Multi-Engine Support**: Test on Lucee 5/6 and Adobe ColdFusion 2018/2021/2023
- **Multi-Database Support**: MySQL, PostgreSQL, SQL Server, H2, and Oracle
- **Pre-flight Checks**: Ensures all services are running before tests
- **Test History**: Track test results over time

### Container Management

The TestUI includes an API server that allows you to:
1. Click on any stopped engine or database to start it
2. Monitor container health and status
3. View real-time logs
4. No terminal required for basic operations

### Docker Profiles

Use profiles to start specific combinations:

```bash
# Just the UI
docker compose --profile ui up -d

# Quick test setup (Lucee 5 + MySQL)
docker compose --profile quick-test up -d

# All Lucee engines
docker compose --profile lucee up -d

# All Adobe engines
docker compose --profile adobe up -d

# All databases
docker compose --profile db up -d
```

### Running Tests via Docker

```bash
# Using the CLI inside a container
docker exec -it wheels-lucee5-1 wheels test run

# Direct URL access
curl http://localhost:60005/wheels/core/tests?format=json&db=mysql
```

### Database Testing

Test against different databases by using the `db` parameter:

```bash
# MySQL
wheels test run --db=mysql

# PostgreSQL
wheels test run --db=postgres

# SQL Server
wheels test run --db=sqlserver

# H2 (Lucee only)
wheels test run --db=h2

# Oracle
wheels test run --db=oracle
```

## See Also

- [wheels test run](../commands/testing/test-run.md) - Test execution command
- [wheels test coverage](../commands/testing/test-coverage.md) - Coverage generation
- [wheels generate test](../commands/generate/test.md) - Generate test files
- [TestBox Documentation](https://testbox.ortusbooks.com/) - Complete TestBox guide
- [Docker Testing Guide](/tools/docker/testui/README.md) - Detailed Docker testing documentation
