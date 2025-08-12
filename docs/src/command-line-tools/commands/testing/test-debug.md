# wheels test debug (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Debug test execution with detailed diagnostics and troubleshooting tools.

## Synopsis

```bash
wheels test debug [spec] [options]
```

## Description

The `wheels test debug` command provides advanced debugging capabilities for your test suite. It helps identify why tests are failing, diagnose test environment issues, and provides detailed execution traces for troubleshooting complex test problems.

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `type` | Type of tests to run: app, core, or plugin | `app` |
| `spec` | Specific test spec to run (e.g., models.user) | |
| `servername` | Name of server to reload | (current server) |
| `--reload` | Force a reload of wheels (boolean flag) | `false` |
| `--break-on-failure` | Stop test execution on first failure (boolean flag) | `true` |
| `output-level` | Output verbosity: 1=minimal, 2=normal, 3=verbose | `3` |

## Examples

### Debug all app tests
```bash
wheels test debug
```

### Debug specific test spec
```bash
wheels test debug spec=models.user
```

### Debug with minimal output
```bash
wheels test debug output-level=1
```

### Debug without stopping on failure
```bash
wheels test debug --break-on-failure=false
```

### Debug core framework tests
```bash
wheels test debug type=core --reload
```

### Enable remote debugging
```bash
wheels test debug --inspect port=9229
```

### Debug slow tests
```bash
wheels test debug slow=500 verbose=2
```

## Debug Output

### Basic Debug Info
```
🔍 Test Debug Session Started
================================

Environment: testing
Debug Level: 1
Test Framework: TestBox 5.0.0
CFML Engine: Lucee 5.3.9.141

Running: UserModelTest.testValidation
Status: RUNNING

[DEBUG] Setting up test case...
[DEBUG] Creating test user instance
[DEBUG] Validating empty user
[DEBUG] Assertion: user.hasErrors() = true ✓
[DEBUG] Test completed in 45ms
```

### Verbose Trace Output
With `--trace verbose=3`:
```
🔍 Test Execution Trace
======================

▶ UserModelTest.setup()
  └─ [0.5ms] Creating test database transaction
  └─ [1.2ms] Loading test fixtures
  └─ [0.3ms] Initializing test context

▶ UserModelTest.testValidation()
  ├─ [0.1ms] var user = model("User").new()
  │   └─ [2.1ms] Model instantiation
  │   └─ [0.5ms] Property initialization
  ├─ [0.2ms] user.validate()
  │   └─ [5.3ms] Running validations
  │   ├─ [1.2ms] Checking required fields
  │   ├─ [2.1ms] Email format validation
  │   └─ [2.0ms] Custom validations
  ├─ [0.1ms] expect(user.hasErrors()).toBe(true)
  │   └─ [0.3ms] Assertion passed ✓
  └─ [0.1ms] Test completed

Total Time: 10.2ms
Memory Used: 2.3MB
```

## Interactive Debugging

### Step Mode
With `--step`:
```
▶ Entering step mode for UserModelTest.testLogin

[1] user = model("User").findOne(where="email='test@example.com'")
    > (n)ext, (s)tep into, (c)ontinue, (v)ariables, (q)uit: v

Variables:
- arguments: {}
- local: { user: [undefined] }
- this: UserModelTest instance

    > n

[2] expect(user.authenticate("password123")).toBe(true)
    > v

Variables:
- arguments: {}
- local: { user: User instance {id: 1, email: "test@example.com"} }

    > s

  [2.1] Entering: user.authenticate("password123")
       Parameters: { password: "password123" }
```

### Breakpoints
Set breakpoints in code:
```cfml
// In test file
function testComplexLogic() {
    var result = complexCalculation(data);
    
    debugBreak(); // Execution pauses here
    
    expect(result).toBe(expectedValue);
}
```

Or via command line:
```bash
wheels test debug breakpoint=OrderTest.testCalculateTotal:25
```

## Test Context Inspection

### Dump Test Context
With `--dump-context`:
```
Test Context Dump
================

Test: UserModelTest.testPermissions
Phase: Execution

Application Scope:
- wheels.version: 2.5.0
- wheels.environment: testing
- Custom settings: { ... }

Request Scope:
- cgi.request_method: "GET"
- url: { testMethod: "testPermissions" }

Test Data:
- Fixtures loaded: users, roles, permissions
- Test user: { id: 999, email: "test@example.com" }
- Database state: Transaction active

Component State:
- UserModelTest properties: { ... }
- Inherited properties: { ... }
```

## Performance Analysis

### Slow Test Detection
With `slow=500`:
```
⚠️ Slow Tests Detected
=====================

1. OrderModelTest.testLargeOrderProcessing - 2,345ms 🐌
   - Database queries: 45 (1,234ms)
   - Model operations: 892ms
   - Assertions: 219ms

2. UserControllerTest.testBulkImport - 1,567ms 🐌
   - File I/O: 623ms
   - Validation: 512ms
   - Database inserts: 432ms

3. ReportTest.testGenerateYearlyReport - 987ms ⚠️
   - Data aggregation: 654ms
   - PDF generation: 333ms
```

## Remote Debugging

### Enable Inspector
```bash
wheels test debug --inspect
```

Connect with Chrome DevTools:
1. Open Chrome/Edge
2. Navigate to `chrome://inspect`
3. Click "Configure" and add `localhost:9229`
4. Click "inspect" on the target

### Debug Protocol
```bash
wheels test debug --inspect-brk port=9230
```
- `--inspect`: Enable debugging
- `--inspect-brk`: Break on first line
- Custom port for multiple sessions

## Failure Analysis

### Pause on Failure
With `--pause-on-failure`:
```
✗ Test Failed: UserModelTest.testUniqueEmail

Test paused at failure point.

Failure Details:
- Expected: true
- Actual: false
- Location: UserModelTest.cfc:45

Debug Options:
(i) Inspect variables
(s) Show stack trace
(d) Dump database state
(r) Retry test
(c) Continue
(q) Quit

> i

Local Variables:
- user1: User { email: "test@example.com", id: 1 }
- user2: User { email: "test@example.com", errors: ["Email already exists"] }
```

### Stack Trace Analysis
```
Stack Trace:
-----------
1. TestBox.expectation.toBe() at TestBox/system/Expectation.cfc:123
2. UserModelTest.testUniqueEmail() at tests/models/UserModelTest.cfc:45
3. TestBox.runTest() at TestBox/system/BaseSpec.cfc:456
4. Model.validate() at wheels/Model.cfc:789
5. Model.validatesUniquenessOf() at wheels/Model.cfc:1234
```

## Test Replay

### Replay Failed Tests
```bash
wheels test debug --replay
```

Replays last failed tests with debug info:
```
Replaying 3 failed tests from last run...

1/3 UserModelTest.testValidation
    - Original failure: Assertion failed at line 23
    - Replay status: PASSED ✓
    - Possible flaky test

2/3 OrderControllerTest.testCheckout
    - Original failure: Database connection timeout
    - Replay status: FAILED ✗
    - Consistent failure
```

## Configuration

### Debug Configuration
`.wheels-test-debug.json`:
```json
{
  "debug": {
    "defaultLevel": 1,
    "slowThreshold": 1000,
    "breakpoints": [
      "UserModelTest.testComplexScenario:45",
      "OrderTest.testEdgeCase:78"
    ],
    "trace": {
      "includeFramework": false,
      "maxDepth": 10
    },
    "output": {
      "colors": true,
      "timestamps": true,
      "saveToFile": "./debug.log"
    }
  }
}
```

## Debugging Strategies

### 1. Isolate Failing Test
```bash
# Run only the failing test
wheels test debug UserModelTest.testValidation --trace
```

### 2. Check Test Environment
```bash
# Dump environment and context
wheels test debug --dump-context > test-context.txt
```

### 3. Step Through Execution
```bash
# Interactive debugging
wheels test debug FailingTest --step --pause-on-failure
```

### 4. Compare Working vs Failing
```bash
# Debug working test
wheels test debug WorkingTest --trace > working.log

# Debug failing test
wheels test debug FailingTest --trace > failing.log

# Compare outputs
diff working.log failing.log
```

## Common Issues

### Test Pollution
Debug test isolation:
```bash
wheels test debug --trace verbose=3 | grep -E "(setup|teardown|transaction)"
```

### Race Conditions
Debug timing issues:
```bash
wheels test debug slow=100 --trace
```

### Database State
```bash
wheels test debug --dump-context | grep -A 20 "Database state"
```

## Best Practices

1. **Start Simple**: Use basic debug before advanced options
2. **Isolate Issues**: Debug one test at a time
3. **Use Breakpoints**: Strategic breakpoints save time
4. **Check Environment**: Ensure test environment is correct
5. **Save Debug Logs**: Keep logs for complex issues

## Notes

- Debug mode affects test performance
- Some features require specific CFML engine support
- Remote debugging requires network access
- Verbose output can be overwhelming - filter as needed

## See Also

- [wheels test](test.md) - Run tests normally
- [wheels test run](test-run.md) - Run specific tests
- [wheels test coverage](test-coverage.md) - Coverage analysis
- [Debugging Guide](../../debugging/guide.md)