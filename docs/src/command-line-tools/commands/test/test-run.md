# wheels test run (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Run TestBox tests for your application with advanced features.

## Synopsis

```bash
wheels test run [spec] [options]
```

## Description

The `wheels test run` command executes your application's TestBox test suite with support, filtering, and various output formats. This is the primary command for running your application tests (as opposed to framework tests).


## Examples

### Run all tests
```bash
wheels test run
```

## Writing Tests

### Model Test Example
```cfc
component extends="testbox.system.BaseSpec" {

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
component extends="testbox.system.BaseSpec" {

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
        reporter = "simple",
        labels = "",
        options = {}
    };
}
```

## Reporters

### Simple (Default)
```bash
wheels test run reporter=simple
```
- Colored console output
- Shows progress dots
- Summary at end

### Text
```bash
wheels test run reporter=text
```
- Plain text output
- Good for CI systems
- No colors

### JSON
```bash
wheels test run reporter=json
```
```json
{
    "totalDuration": 523,
    "totalSpecs": 25,
    "totalPass": 24,
    "totalFail": 1,
    "totalError": 0,
    "totalSkipped": 0
}
```

### JUnit
```bash
wheels test run reporter=junit outputFile=results.xml
```
- JUnit XML format
- For CI integration
- Jenkins compatible

### TAP
```bash
wheels test run reporter=tap
```
- Test Anything Protocol
- Cross-language format

## Filtering Tests

### By Bundle
```bash
# Run only model tests
wheels test run bundles=models

# Run multiple bundles
wheels test run bundles=models,controllers
```

### By Label
```cfc
it("can authenticate", function() {
    // test code
}).labels("auth,critical");
```

```bash
# Run only critical tests
wheels test run labels=critical

# Run auth OR api tests
wheels test run labels=auth,api
```

### By Name Filter
```bash
# Run tests matching pattern
wheels test run filter="user"
wheels test run filter="validate*"
```

### Exclude Patterns
```bash
# Skip slow tests
wheels test run excludes="*slow*,*integration*"
```

## Parallel Execution

Run tests in parallel threads:
```bash
wheels test run threads=4
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
    wheels test run reporter=junit outputFile=test-results.xml

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

## Performance Tips

1. **Use labels** for fast feedback
   ```bash
   wheels test run labels=unit  # Fast
   wheels test run labels=integration  # Slow
   ```

2. **Parallel execution**
   ```bash
   wheels test run threads=4
   ```


4. **Skip slow tests during development**
   ```bash
   wheels test run excludes="*integration*"
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
