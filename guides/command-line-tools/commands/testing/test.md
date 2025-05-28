# wheels test

Run Wheels framework tests (core, app, or plugin tests).

## Synopsis

```bash
wheels test [type] [servername] [options]
```

## Description

The `wheels test` command runs the built-in Wheels framework test suite. This is different from `wheels test run` which runs your application's TestBox tests. Use this command to verify framework integrity or test Wheels plugins.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `type` | Test type: `core`, `app`, or `plugin` | `app` |
| `servername` | CommandBox server name | Current server |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--reload` | Reload before running tests | `true` |
| `--debug` | Show debug output | `false` |
| `--format` | Output format | `simple` |
| `--adapter` | Test adapter | `testbox` |
| `--help` | Show help information | |

## Test Types

### Core Tests
```bash
wheels test core
```
- Tests Wheels framework functionality
- Verifies framework integrity
- Useful after framework updates

### App Tests
```bash
wheels test app
```
- Runs application-level framework tests
- Tests Wheels configuration
- Verifies app-specific framework features

### Plugin Tests
```bash
wheels test plugin
```
- Tests installed Wheels plugins
- Verifies plugin compatibility
- Checks plugin functionality

## Examples

### Run app tests (default)
```bash
wheels test
```

### Run core framework tests
```bash
wheels test core
```

### Run tests on specific server
```bash
wheels test app myserver
```

### Run with debug output
```bash
wheels test --debug
```

### Skip reload
```bash
wheels test --reload=false
```

## Output Example

```
╔═══════════════════════════════════════════════╗
║           Running Wheels Tests                ║
╚═══════════════════════════════════════════════╝

Test Type: app
Server: default
Reloading: Yes

Initializing test environment...
✓ Environment ready

Running tests...

Model Tests
  ✓ validations work correctly (15ms)
  ✓ associations load properly (23ms)
  ✓ callbacks execute in order (8ms)

Controller Tests
  ✓ filters apply correctly (12ms)
  ✓ caching works as expected (45ms)
  ✓ provides correct formats (5ms)

View Tests
  ✓ helpers render correctly (18ms)
  ✓ partials include properly (9ms)
  ✓ layouts apply correctly (11ms)

Plugin Tests
  ✓ DBMigrate plugin loads (7ms)
  ✓ Scaffold plugin works (22ms)

╔═══════════════════════════════════════════════╗
║              Test Summary                     ║
╚═══════════════════════════════════════════════╝

Total Tests: 11
Passed: 11
Failed: 0
Errors: 0
Time: 173ms

✓ All tests passed!
```

## Framework Test Categories

### Model Tests
- Validations
- Associations
- Callbacks
- Properties
- Calculations

### Controller Tests
- Filters
- Caching
- Provides/formats
- Redirects
- Rendering

### View Tests
- Helper functions
- Form helpers
- Asset helpers
- Partials
- Layouts

### Dispatcher Tests
- Routing
- URL rewriting
- Request handling
- Parameter parsing

## Configuration

### Test Settings
In `/config/settings.cfm`:
```cfm
<cfset set(testEnvironment=true)>
<cfset set(testDataSource="myapp_test")>
```

### Test Database
Create separate test database:
```sql
CREATE DATABASE myapp_test;
```

## Debugging Failed Tests

### Enable debug mode
```bash
wheels test --debug
```

### Check specific test file
```
Failed: Model Tests > validations work correctly
File: /tests/framework/model/validations.cfc
Line: 45
Expected: true
Actual: false
```

### Common issues
1. **Database not configured**: Check test datasource
2. **Reload password wrong**: Verify settings
3. **Plugin conflicts**: Disable plugins and retest
4. **Cache issues**: Clear cache and retry

## Continuous Integration

### GitHub Actions
```yaml
- name: Run Wheels tests
  run: |
    box install
    box server start
    wheels test core
    wheels test app
```

### Jenkins
```groovy
stage('Framework Tests') {
    steps {
        sh 'wheels test core'
        sh 'wheels test app'
    }
}
```

## Custom Framework Tests

Add tests in `/tests/framework/`:

```cfc
component extends="wheels.Test" {

    function test_custom_framework_feature() {
        // Test custom framework modification
        actual = customFrameworkMethod();
        assert(actual == expected);
    }

}
```

## Performance Testing

Run with timing:
```bash
wheels test --debug | grep "Time:"
```

Monitor slow tests:
```
✓ complex query test (523ms) ⚠️ SLOW
✓ simple validation (8ms)
```

## Test Isolation

Tests run in isolation:
- Separate request for each test
- Transaction rollback (if enabled)
- Clean application state

## Troubleshooting

### Tests won't run
```bash
# Check server is running
box server status

# Verify test URL
curl http://localhost:3000/wheels/tests
```

### Reload issues
```bash
# Manual reload first
wheels reload

# Then run tests
wheels test --reload=false
```

### Memory issues
```bash
# Increase heap size
box server set jvm.heapSize=512
box server restart
```

## Best Practices

1. Run before deployment
2. Test after framework updates
3. Verify plugin compatibility
4. Use CI/CD integration
5. Keep test database clean

## Difference from TestBox Tests

| Feature | `wheels test` | `wheels test run` |
|---------|--------------|-------------------|
| Purpose | Framework tests | Application tests |
| Framework | Wheels Test | TestBox |
| Location | `/wheels/tests/` | `/tests/` |
| Use Case | Framework integrity | App functionality |

## See Also

- [wheels test run](test-run.md) - Run TestBox application tests
- [wheels test coverage](test-coverage.md) - Generate coverage reports
- [wheels test debug](test-debug.md) - Debug test execution
- [wheels reload](../core/reload.md) - Reload application