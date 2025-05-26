# Testing Commands

The Wheels CLI provides comprehensive testing commands that integrate with TestBox to run unit tests, generate coverage reports, and debug test failures. These commands streamline your test-driven development workflow.

## Overview

Testing commands help you:
- Run application, core framework, and plugin tests
- Generate test coverage reports
- Debug failing tests
- Filter tests by bundles or specific specs
- Integrate testing into CI/CD pipelines

## wheels test

Run tests for your Wheels application, framework core, or plugins.

### Syntax

```bash
wheels test [type] [options]
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| type | string | No | app | Test type (app/core/plugin) |
| --servername | string | No | Current | Server name |
| --reload | boolean | No | false | Force reload before testing |
| --debug | boolean | No | false | Show debug output |
| --reporter | string | No | simple | Test reporter format |
| --testBundles | string | No | - | Specific test bundles |
| --testSpecs | string | No | - | Specific test specs |

### Test Types

- `app` - Application tests in /tests directory
- `core` - Wheels framework core tests
- `plugin` - Plugin-specific tests

### Description

The main test command runs your test suite and displays results. It integrates with TestBox to provide comprehensive test execution with various output formats and filtering options.

### Examples

Run all application tests:
```bash
wheels test app
```

Run with specific bundles:
```bash
wheels test app --testBundles=models
```

Run specific test spec:
```bash
wheels test app --testBundles=models --testSpecs=UserTest
```

Run with debug output:
```bash
wheels test app --debug
```

### Reporter Formats

- `simple` - Basic text output (default)
- `json` - JSON format for parsing
- `junit` - JUnit XML for CI integration
- `tap` - TAP (Test Anything Protocol)
- `dot` - Minimal dot notation
- `doc` - Documentation format

### Output Example

```
Running Application Tests...
================================

TestBox v5.0.0
================================

models.UserTest
  ✓ should validate email format (15ms)
  ✓ should hash password on save (8ms)
  ✓ should authenticate with valid credentials (12ms)
  ✗ should prevent duplicate emails
    Expected: true
    Received: false
    at models/UserTest.cfc:45

controllers.ProductsTest  
  ✓ index should return product list (22ms)
  ✓ show should return single product (10ms)
  
================================
Tests: 6 | Passed: 5 | Failed: 1
Time: 87ms
================================
```

### Notes

- Requires test controller and views to be set up
- Tests run in isolated transactions by default
- Environment is automatically set to 'testing'
- Database is rolled back after each test

---

## wheels test run

Run specific test files or methods with granular control.

### Syntax

```bash
wheels test run [path] [options]
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| path | string | No | - | Test file path or pattern |
| --method | string | No | - | Specific test method |
| --bundle | string | No | - | Test bundle name |

### Description

Provides fine-grained control over test execution, allowing you to run:
- Individual test files
- Specific test methods
- Tests matching patterns

### Examples

Run single test file:
```bash
wheels test run tests/models/UserTest.cfc
```

Run specific test method:
```bash
wheels test run tests/models/UserTest.cfc --method=testEmailValidation
```

Run tests matching pattern:
```bash
wheels test run **/Product*.cfc
```

Run specific bundle:
```bash
wheels test run --bundle=integration
```

### Notes

- Useful for debugging specific failures
- Faster than running full test suite
- Supports glob patterns for file matching

---

## wheels test coverage

Generate code coverage reports for your test suite.

### Syntax

```bash
wheels test coverage [options]
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| --format | string | No | html | Report format |
| --output | string | No | ./coverage | Output directory |
| --threshold | number | No | 80 | Coverage threshold % |

### Formats

- `html` - Interactive HTML report
- `json` - JSON data for processing
- `lcov` - LCOV format for CI tools
- `text` - Console text summary

### Description

Analyzes code coverage by tracking which lines of code are executed during test runs. Helps identify untested code paths and maintain coverage standards.

### Examples

Generate HTML coverage report:
```bash
wheels test coverage
```

Generate with specific threshold:
```bash
wheels test coverage --threshold=90
```

Generate multiple formats:
```bash
wheels test coverage --format=html,json,lcov
```

Output to custom directory:
```bash
wheels test coverage --output=./reports/coverage
```

### Coverage Report Example

```
Code Coverage Report
====================

File                        | % Stmts | % Branch | % Funcs | % Lines |
---------------------------|---------|----------|---------|---------|
models/                    |   85.2  |   78.4   |   92.0  |   85.2  |
  User.cfc                 |   92.5  |   88.0   |  100.0  |   92.5  |
  Product.cfc              |   78.0  |   70.0   |   85.0  |   78.0  |
controllers/               |   76.8  |   65.2   |   88.5  |   76.8  |
  Products.cfc             |   82.0  |   75.0   |   90.0  |   82.0  |
  Users.cfc                |   71.5  |   55.5   |   87.0  |   71.5  |
---------------------------|---------|----------|---------|---------|
All files                  |   81.0  |   71.8   |   90.2  |   81.0  |

✓ Coverage threshold met: 81.0% >= 80%
```

### Notes

- Requires code instrumentation
- May slow down test execution
- HTML reports include line-by-line coverage
- Integrates with CI/CD pipelines

---

## wheels test debug

Debug test execution with enhanced output and breakpoints.

### Syntax

```bash
wheels test debug [test] [options]
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| test | string | Yes | - | Test to debug |
| --breakpoint | number | No | - | Line number for breakpoint |

### Description

Provides enhanced debugging capabilities for test development:
- Step through test execution
- Inspect variables at breakpoints
- View detailed error traces
- Debug test setup/teardown

### Examples

Debug specific test:
```bash
wheels test debug models/UserTest::testAuthentication
```

Debug with breakpoint:
```bash
wheels test debug models/UserTest --breakpoint=45
```

### Debug Output Example

```
Debugging: models/UserTest::testAuthentication
================================================

[SETUP] Creating test user...
  user = {id: 123, email: "test@example.com", name: "Test User"}

[LINE 42] Attempting authentication...
  credentials = {email: "test@example.com", password: "******"}

[BREAKPOINT 45] Paused at assertion
  Variables in scope:
    - result: true
    - user: {id: 123, email: "test@example.com", name: "Test User"}
    - authToken: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
  
  Continue? (y/n/s/v) > 

[ASSERTION] assert(result == true) ✓ PASSED

[TEARDOWN] Cleaning up test data...

Test completed successfully.
```

### Interactive Commands

During debugging:
- `y` - Continue execution
- `n` - Stop execution
- `s` - Step to next line
- `v` - View all variables

### Notes

- Only available in development environment
- Requires interactive terminal
- Cannot be used in CI environments
- Helpful for complex test failures

---

## Test Organization

### Directory Structure

Organize tests to mirror your application structure:

```
tests/
├── models/
│   ├── UserTest.cfc
│   ├── ProductTest.cfc
│   └── OrderTest.cfc
├── controllers/
│   ├── UsersTest.cfc
│   ├── ProductsTest.cfc
│   └── OrdersTest.cfc
├── views/
│   └── HelperTest.cfc
├── integration/
│   ├── AuthenticationTest.cfc
│   └── CheckoutProcessTest.cfc
└── Test.cfc (base test class)
```

### Writing Tests

#### Model Test Example

```cfm
component extends="Test" {
    
    function setup() {
        super.setup();
        // Create test data
        testUser = model("User").new();
    }
    
    function teardown() {
        super.teardown();
        // Clean up test data
    }
    
    function testEmailValidation() {
        testUser.email = "invalid-email";
        assert(!testUser.valid());
        assert(testUser.errors.email.message contains "valid email");
    }
    
    function testPasswordHashing() {
        testUser.password = "secretpass";
        testUser.save();
        assert(testUser.passwordHash != "secretpass");
        assert(testUser.authenticate("secretpass"));
    }
}
```

#### Controller Test Example

```cfm
component extends="Test" {
    
    function testIndexAction() {
        result = processRequest(route="products", method="GET");
        assert(result.status == 200);
        assert(result.response contains "Products");
        assert(isArray(result.products));
    }
    
    function testCreateAction() {
        params = {
            product: {
                name: "Test Product",
                price: 29.99
            }
        };
        
        result = processRequest(
            route="products", 
            method="POST",
            params=params
        );
        
        assert(result.status == 302);
        assert(result.redirect contains "/products/");
    }
}
```

### Test Helpers

Common test utilities and assertions:

```cfm
// Custom assertions
function assertEmailSent(to, subject) {
    emails = getEmailLog();
    found = false;
    for (email in emails) {
        if (email.to == arguments.to && email.subject == arguments.subject) {
            found = true;
            break;
        }
    }
    assert(found, "Email to #arguments.to# with subject '#arguments.subject#' was not sent");
}

// Factory methods
function createTestUser(overrides={}) {
    defaults = {
        email: "test#createUUID()#@example.com",
        password: "testpass123",
        name: "Test User"
    };
    structAppend(defaults, overrides);
    return model("User").create(defaults);
}

// Database helpers
function resetDatabase() {
    // Truncate all tables
    tables = ["users", "products", "orders"];
    for (table in tables) {
        queryExecute("TRUNCATE TABLE #table#");
    }
}
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup CommandBox
      run: |
        curl -fsSL https://downloads.ortussolutions.com/debs/gpg | sudo apt-key add -
        echo "deb https://downloads.ortussolutions.com/debs/noarch /" | sudo tee -a /etc/apt/sources.list.d/commandbox.list
        sudo apt-get update && sudo apt-get install commandbox
        
    - name: Install dependencies
      run: box install
      
    - name: Run tests
      run: box wheels test app --reporter=junit
      
    - name: Generate coverage
      run: box wheels test coverage --format=lcov --threshold=80
      
    - name: Upload coverage
      uses: codecov/codecov-action@v2
      with:
        file: ./coverage/lcov.info
```

### GitLab CI Example

```yaml
stages:
  - test

test:
  stage: test
  image: ortussolutions/commandbox:latest
  script:
    - box install
    - box wheels test app --reporter=junit
    - box wheels test coverage --format=lcov
  artifacts:
    reports:
      junit: test-results.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura.xml
  coverage: '/All files\s+\|\s+(\d+\.\d+)/'
```

## Best Practices

### Test Design

1. **Follow AAA Pattern**
   - Arrange: Set up test data
   - Act: Execute the code
   - Assert: Verify results

2. **Keep Tests Isolated**
   - Each test should be independent
   - Use setup/teardown for consistency
   - Avoid test order dependencies

3. **Test One Thing**
   - Each test method should verify one behavior
   - Use descriptive test names
   - Keep tests simple and focused

### Performance

1. **Use Test Databases**
   - In-memory databases for speed
   - Separate test data from development
   - Reset between test runs

2. **Mock External Services**
   - Avoid network calls in unit tests
   - Use stubs for third-party APIs
   - Test integrations separately

3. **Parallelize When Possible**
   - Run independent test suites concurrently
   - Use test bundles for organization
   - Balance test distribution

### Maintenance

1. **Keep Tests Updated**
   - Update tests when changing code
   - Remove obsolete tests
   - Refactor tests like production code

2. **Monitor Coverage**
   - Set coverage thresholds
   - Review uncovered code
   - Focus on critical paths

3. **Fix Flaky Tests**
   - Investigate intermittent failures
   - Remove timing dependencies
   - Ensure deterministic results

## Troubleshooting

### Common Issues

**Test Environment Not Found**
```
Error: Testing environment not configured
```
Solution: Ensure config/testing/settings.cfm exists

**Database Connection Failed**
```
Error: Could not connect to test database
```
Solution: Verify test datasource configuration

**Test Controller Missing**
```
Error: Test runner not found at /tests/runner.cfm
```
Solution: Ensure test UI components are installed

**Coverage Tool Not Found**
```
Error: Coverage instrumentation not available
```
Solution: Install coverage dependencies via box install

### Debugging Tips

1. **Use --debug flag** for verbose output
2. **Run single tests** to isolate issues
3. **Check test logs** in logs/test.log
4. **Verify test data** setup and teardown
5. **Review stack traces** for exact failure points

## Summary

The Wheels testing commands provide a complete testing toolkit:

- **Run tests** at various granularities
- **Generate coverage** reports with thresholds
- **Debug failures** with enhanced output
- **Integrate with CI/CD** pipelines
- **Maintain quality** through automated testing

Remember: Good tests are the foundation of maintainable applications. Write tests first, run them often, and keep them clean.