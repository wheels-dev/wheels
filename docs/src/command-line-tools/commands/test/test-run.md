# wheels test run

Run TestBox tests for your CFWheels application using the TestBox CLI integration.

> **Note:** This command replaces the deprecated `wheels test` command. The new version leverages CommandBox's native TestBox CLI for better performance and reliability.

## Prerequisites

### Install TestBox CLI

The TestBox CLI module is required for this command to work. Install it globally in CommandBox:

```bash
# Install TestBox CLI
box install testbox-cli

# Or install globally
box install testbox-cli --global

# Verify installation
box testbox help
```

## Synopsis

```bash
wheels test run [options]
```

## Description

The `wheels test run` command executes your application's TestBox test suite through CFWheels' controller-based test runners. It supports three test types: application tests, core framework tests, and plugin tests.

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `type` | Type of tests to run: app, core, or plugin | `app` |
| `bundles` | Comma-separated list of test bundles to run | |
| `directory` | Directory of tests to run | |
| `recurse` | Recurse into subdirectories | `true` |
| `labels` | Comma-separated list of test labels to include | |
| `excludes` | Comma-separated list of patterns to exclude | |
| `reporter` | Test reporter format | `simple` |
| `reportpath` | Path to save test reports | |
| `--coverage` | Generate coverage report | `false` |
| `--verbose` | Verbose output | `false` |
| `servername` | Name of server to use | |

### Available Reporters

- `simple` - Colored console output with progress (default)
- `text` - Plain text output
- `json` - JSON format
- `junit` - JUnit XML format
- `tap` - Test Anything Protocol
- `antjunit` - ANT-compatible JUnit
- `console` - Console reporter
- `doc` - Documentation format
- `dot` - Dot notation
- `min` - Minimal output
- `raw` - Raw TestBox output

## Examples

### Run all application tests
```bash
wheels test run
```

### Run core framework tests
```bash
wheels test run type=core
```

### Run plugin tests
```bash
wheels test run type=plugin
```

### Run specific test bundles
```bash
wheels test run bundles=UserTest
wheels test run bundles=UserTest,ProductTest
```

### Run tests from specific directory
```bash
wheels test run directory=tests/models
```

### Run tests with specific labels
```bash
wheels test run labels=unit
wheels test run labels=unit,critical
```

### Exclude certain tests
```bash
wheels test run excludes="*slow*,*integration*"
```

### Generate coverage report
```bash
wheels test run --coverage
wheels test run --coverage coveragePathToCapture=/models
```

### Use different reporter
```bash
wheels test run reporter=json
wheels test run reporter=junit reportpath=test-results/
```

### Verbose output
```bash
wheels test run --verbose
```

### Combine options
```bash
wheels test run type=app bundles=UserTest --coverage --verbose reporter=json
```

## Test URL Structure

The command builds URLs based on the test type:

- **App tests**: `?controller=wheels.public&action=testbox&view=runner`
- **Core tests**: `?controller=wheels.public&action=tests_testbox&view=runner`
- **Plugin tests**: `?controller=tests&action=runner&view=runner&type=plugin`

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

### Basic Test Example
```cfc
component extends="testbox.system.BaseSpec" {

    function run() {
        describe("User Model", function() {

            beforeEach(function() {
                // Setup test data
            });

            it("validates required fields", function() {
                var user = model("User").new();
                expect(user.valid()).toBeFalse();
                expect(user.errors).toHaveKey("email");
            });

            it("saves with valid data", function() {
                var user = model("User").new(
                    email="test@example.com",
                    username="testuser"
                );
                expect(user.save()).toBeTrue();
            });

        });
    }

}
```

## Migration from Legacy Command

### Old Command (Deprecated)
```bash
# Old syntax - no longer recommended
wheels test
wheels test package=app
```

### New Command
```bash
# New syntax - use this instead
wheels test run
wheels test run type=app
```

### Key Differences

1. **TestBox CLI Integration**: The new command uses TestBox CLI directly for better performance
2. **Simplified Parameters**: Parameters now match TestBox CLI conventions
3. **Better Error Handling**: Improved error messages and debugging
4. **Consistent Output**: All TestBox reporters are fully supported

## Coverage Reports

Generate code coverage reports:

```bash
# Basic coverage
wheels test run --coverage

# Coverage with specific path
wheels test run --coverage coveragePathToCapture=/models

# Coverage with SonarQube output
wheels test run --coverage coverageSonarQubeXMLOutputPath=coverage/sonar.xml

# Coverage with whitelist
wheels test run --coverage coverageWhitelist="*.cfc"

# Coverage with blacklist
wheels test run --coverage coverageBlacklist="*Test.cfc"
```

## Server Configuration

The command automatically detects your running server configuration. To use a specific server:

```bash
# Use named server
wheels test run servername=myapp

# Server must be running
box server start name=myapp
wheels test run servername=myapp
```

## CI/CD Integration

### GitHub Actions
```yaml
- name: Install dependencies
  run: |
    box install
    box install testbox-cli --global

- name: Start server
  run: box server start

- name: Run tests
  run: box wheels test run reporter=junit reportpath=test-results/

- name: Upload results
  uses: actions/upload-artifact@v4
  with:
    name: test-results
    path: test-results/
```

### GitLab CI
```yaml
test:
  script:
    - box install
    - box install testbox-cli --global
    - box server start
    - box wheels test run reporter=junit reportpath=test-results/
  artifacts:
    reports:
      junit: test-results/*.xml
```

## Troubleshooting

### TestBox CLI Not Found
```bash
# Error: TestBox CLI is not installed
# Solution:
box install testbox-cli --global
```

### Server Not Running
```bash
# Error: Could not connect to server
# Solution:
box server start
wheels test run
```

### Out of Memory
```bash
# Increase heap size before running tests
box server set jvm.heapSize=1024
box server restart
wheels test run
```

### Wrong Test Path
```bash
# Verify test type matches your structure
wheels test run type=app    # For /tests/
wheels test run type=core   # For /wheels/tests/
wheels test run type=plugin # For /plugins/tests/
```

## Performance Tips

1. **Run specific bundles** for faster feedback
   ```bash
   wheels test run bundles=UserTest
   ```

2. **Use labels** to group related tests
   ```bash
   wheels test run labels=unit  # Fast unit tests
   wheels test run labels=integration  # Slower integration tests
   ```

3. **Exclude slow tests** during development
   ```bash
   wheels test run excludes="*integration*,*slow*"
   ```

4. **Use simple reporter** for development
   ```bash
   wheels test run reporter=simple  # Fastest output
   ```

## Common Issues

### Tests Not Found
- Verify test directory structure
- Check bundle names match file names
- Ensure tests extend `testbox.system.BaseSpec`

### Database Issues
- Use test datasource in test Application.cfc
- Reset database between tests
- Use transactions for isolation

### Session/Request Scope
- Mock session/request data in tests
- Use TestBox's `prepareMock()` for dependencies

## See Also

- [wheels generate test](../generate/test.md) - Generate test files
- [TestBox Documentation](https://testbox.ortusbooks.com/) - Complete TestBox guide
- [CommandBox TestBox CLI](https://www.forgebox.io/view/testbox-cli) - TestBox CLI module