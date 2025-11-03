# wheels test run

Run TestBox tests for your Wheels application using the TestBox CLI integration.

> **Note:** This command replaces the deprecated `wheels test` command.

## Prerequisites

### Install TestBox CLI

```bash
box install testbox-cli --global
```

## Synopsis

```bash
wheels test run [spec] [options]
```

## CommandBox Parameter Syntax

This command supports multiple parameter formats:

- **Named parameters**: `name=value` (e.g., `format=json`, `filter="User"`)
- **Flag parameters**: `--flag` equals `flag=true` (e.g., `--coverage` equals `coverage=true`)
- **Flag with value**: `--flag=value` equals `flag=value` (e.g., `--format=json`)

**Parameter Mixing Rules:**

✅ **ALLOWED:**
- All named: `wheels test run format=json verbose=true`
- All flags: `wheels test run --verbose --coverage`
- Named + flags: `wheels test run format=json --coverage`

❌ **NOT ALLOWED:**
- Positional + named: Not applicable for this command (no positional parameters)

**Recommendation:** Use named parameters for specific values, flags for boolean options: `wheels test run format=json --coverage`

## Description

The `wheels test run` command executes your application's TestBox test suite with support, filtering, and various output formats. This is the primary command for running your application tests (as opposed to framework tests).

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `type` | string | app | Type of tests to run |
| `format` | string | txt | Test output format: txt, junit, json |
| `bundles` | string | - | The path or list of paths of the spec bundle CFCs to run and test ONLY |
| `directory` | string | - | The directory to use to discover test bundles and specs to test |
| `recurse` | boolean | true | Recurse the directory mapping or not |
| `verbose` | boolean | true | Display extra details including passing and skipped tests |
| `servername` | string | - | Server name for test execution |
| `filter` | string | - | Filter tests by pattern or name |
| `labels` | string | - | The list of labels that a suite or spec must have in order to execute |
| `coverage` | boolean | false | Enable code coverage with FusionReactor |

## Examples

### Run all tests
```bash
wheels test run
```

### Filter tests by pattern
```bash
# Named parameter (recommended for string values)
wheels test run filter="User"
wheels test run filter="test_user_validation"
```

### Run specific bundles
```bash
# Named parameter (recommended)
wheels test run bundles="tests.models"
wheels test run bundles="tests.models,tests.controllers"
```

### Run tests with specific labels
```bash
# Named parameter (recommended)
wheels test run labels="unit"
wheels test run labels="critical,auth"
```

### Generate coverage report
```bash
# Flag (recommended for boolean)
wheels test run --coverage

# OR named
wheels test run coverage=true
```

### Use different output format
```bash
# Named (recommended)
wheels test run format=json
wheels test run format=junit

# OR flag with value
wheels test run --format=json
```

### Run tests from specific directory
```bash
# Named parameters (recommended)
wheels test run directory="tests/specs"
wheels test run directory="tests/specs/unit" recurse=false
```

### Verbose output with coverage
```bash
# Flags + named (recommended)
wheels test run --verbose --coverage format=txt

# OR all named
wheels test run verbose=true coverage=true format=txt
```

### Run tests for different type
```bash
# Named (recommended)
wheels test run type=core
wheels test run type=app
```

## Test Structure

Standard test directory layout:
```
/tests/
├── Application.cfc      # Test configuration
├── models/             # Model tests
│   ├── UserTest.cfc
│   └── ProductTest.cfc
├── controllers/        # Controller tests
│   ├── UsersTest.cfc
│   └── ProductsTest.cfc
├── views/             # View tests
├── integration/       # Integration tests
└── helpers/          # Test helpers
```

## Writing Tests

### Model Test Example
```cfc
component extends="wheels.Testbox" {

    function run() {
        describe("User Model", function() {

            beforeEach(function() {
                // Reset test data
                application.wirebox.getInstance("User").deleteAll();
            });

            it("validates required fields", function() {
                var user = model("User").new();
                expect(user.valid()).toBeFalse();
                expect(user.errors).toHaveKey("email");
                expect(user.errors).toHaveKey("username");
            });

            it("saves with valid data", function() {
                var user = model("User").new(
                    email="test@example.com",
                    username="testuser",
                    password="secret123"
                );
                expect(user.save()).toBeTrue();
                expect(user.id).toBeGT(0);
            });

            it("prevents duplicate emails", function() {
                var user1 = model("User").create(
                    email="test@example.com",
                    username="user1"
                );

                var user2 = model("User").new(
                    email="test@example.com",
                    username="user2"
                );

                expect(user2.valid()).toBeFalse();
                expect(user2.errors.email).toContain("already exists");
            });

        });
    }

}
```

### Controller Test Example
```cfc
component extends="wheels.Testbox" {

    function run() {
        describe("Products Controller", function() {

            it("lists all products", function() {
                // Create test data
                var product = model("Product").create(name="Test Product");

                // Make request
                var event = execute(
                    event="products.index",
                    renderResults=true
                );

                // Assert response
                expect(event.getRenderedContent()).toInclude("Test Product");
                expect(event.getValue("products")).toBeArray();
            });

            it("requires auth for create", function() {
                var event = execute(
                    event="products.create",
                    renderResults=false
                );

                expect(event.getValue("relocate_URI")).toBe("/login");
            });

        });
    }

}
```

## Test Configuration

### /tests/Application.cfc
```cfc
component {
    this.name = "WheelsTestingSuite" & Hash(GetCurrentTemplatePath());

    // Use test datasource
    this.datasources["wheelstestdb"] = {
        url = "jdbc:h2:mem:wheelstestdb;MODE=MySQL"
    };
    this.datasource = "wheelstestdb";

    // Test settings
    this.testbox = {
        testBundles = "tests",
        recurse = true,
        format = "simple",
        labels = "",
        options = {}
    };
}
```

## Reporters

### txt (Default)
```bash
wheels test run format=txt
```
- Plain txt output
- Good for CI systems
- No colors

### JSON
```bash
wheels test run format=json
```
```
√ tests.specs.functions.Example (3 ms)
[Passed: 1] [Failed: 0] [Errors: 0] [Skipped: 0] [Suites/Specs: 1/1]

    √ Tests that DummyTest
        √ is Returning True (1 ms)
╔═════════════════════════════════════════════════════════════════════╗
║ Passed  ║ Failed  ║ Errored ║ Skipped ║ Bundles ║ Suites  ║ Specs   ║
╠═════════════════════════════════════════════════════════════════════╣
║ 1       ║ 0       ║ 0       ║ 0       ║ 1       ║ 1       ║ 1       ║
╚═════════════════════════════════════════════════════════════════════╝
```

### JUnit
```bash
wheels test run format=junit
```
- JUnit XML format
- For CI integration
- Jenkins compatible


## Filtering Tests

### By Bundle
```bash
# Run only model tests
wheels test run bundles=tests.models

# Run multiple bundles
wheels test run bundles=tests.models,tests.controllers
```

### By Label
```cfc
component extends="wheels.Testbox" labels="label title"
```

```bash
# Run only critical tests
wheels test run labels="label title"

# Run auth OR api tests
wheels test run labels=auth,api
```

### By Name Filter
```bash
# Run tests matching pattern
wheels test run filter="user"
wheels test run filter="validate*"
```


Benefits:
- Faster execution
- Better CPU utilization
- Finds concurrency issues

## Code Coverage

Generate coverage reports:
```bash
wheels test run --coverage coverageOutputDir=coverage/
```

View report:
```bash
open coverage/index.html
```

## Test Helpers

Create reusable test utilities:

```cfc
// /tests/helpers/TestHelper.cfc
component {

    function createTestUser(struct overrides={}) {
        var defaults = {
            email: "test#CreateUUID()#@example.com",
            username: "user#CreateUUID()#",
            password: "testpass123"
        };

        return model("User").create(
            argumentCollection = defaults.append(arguments.overrides)
        );
    }

    function loginAs(required user) {
        session.userId = arguments.user.id;
        session.isAuthenticated = true;
    }

}
```

## Database Strategies

### Transaction Rollback
```cfc
function beforeAll() {
    transaction action="begin";
}

function afterAll() {
    transaction action="rollback";
}
```

### Database Cleaner
```cfc
function beforeEach() {
    queryExecute("DELETE FROM users");
    queryExecute("DELETE FROM products");
}
```

### Fixtures
```cfc
function loadFixtures() {
    var users = deserializeJSON(
        fileRead("/tests/fixtures/users.json")
    );

    for (var userData in users) {
        model("User").create(userData);
    }
}
```

## CI/CD Integration

### GitHub Actions
```yaml
- name: Run tests
  run: |
    wheels test run  format=junit outputFile=test-results.xml

- name: Upload results
  uses: actions/upload-artifact@v4
  with:
    name: test-results
    path: test-results.xml
```

### Pre-commit Hook
```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running tests..."
wheels test run labels=unit

if [ $? -ne 0 ]; then
    echo "Tests failed. Commit aborted."
    exit 1
fi
```

## Common Issues

### Out of Memory
```bash
# Increase memory
box server set jvm.heapSize=1024
box server restart
```

### Test Pollution
- Use `beforeEach`/`afterEach`
- Reset global state
- Use transactions

### Flaky Tests
- Avoid time-dependent tests
- Mock external services
- Use fixed test data

## See Also

- [wheels test](test.md) - Run framework tests
- [wheels test coverage](test-coverage.md) - Generate coverage
- [wheels test debug](test-debug.md) - Debug tests
- [wheels generate test](../generate/test.md) - Generate test files