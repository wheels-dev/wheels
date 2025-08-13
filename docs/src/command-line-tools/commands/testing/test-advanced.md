# Advanced Testing Commands (Coming Soon)
*These commands may not work as expected. A complete and stable version is **coming soon**.*

The Wheels CLI provides advanced testing capabilities through integration with TestBox CLI. These commands offer specialized test runners for different testing scenarios.

## Prerequisites

Before using these commands, you must install TestBox CLI:

```bash
box install commandbox-testbox-cli
```

## Available Commands

### test:all - Run All Tests

Runs all tests in your application using TestBox CLI.

```bash
wheels test:all
```

#### Options

- `--reporter` - Test reporter format (simple, spec, junit, json, tap, min, doc)
- `--coverage` - Generate coverage report
- `--coverageReporter` - Coverage reporter format (html, json, xml)
- `--coverageOutputDir` - Directory for coverage output
- `--verbose` - Verbose output
- `--failFast` - Stop on first test failure
- `--directory` - Test directory to run (default: tests)
- `--recurse` - Recurse into subdirectories
- `--bundles` - Comma-delimited list of test bundles to run
- `--labels` - Comma-delimited list of test labels to run
- `--excludes` - Comma-delimited list of test bundles to exclude
- `--filter` - Test filter pattern

#### Examples

```bash
# Run with spec reporter
wheels test:all --reporter=spec

# Run with coverage
wheels test:all --coverage --coverageReporter=html

# Filter tests by name
wheels test:all --filter=UserTest --verbose

# Run specific bundles
wheels test:all --bundles=tests.unit.models,tests.unit.controllers
```

### test:unit - Run Unit Tests

Runs only unit tests located in the `tests/unit` directory.

```bash
wheels test:unit
```

#### Options

- `--reporter` - Test reporter format (simple, spec, junit, json, tap, min, doc)
- `--verbose` - Verbose output
- `--failFast` - Stop on first test failure
- `--bundles` - Comma-delimited list of test bundles to run
- `--labels` - Comma-delimited list of test labels to run
- `--excludes` - Comma-delimited list of test bundles to exclude
- `--filter` - Test filter pattern
- `--directory` - Unit test directory (default: tests/unit)

#### Examples

```bash
# Run with spec reporter
wheels test:unit --reporter=spec

# Filter specific tests
wheels test:unit --filter=UserModelTest

# Verbose output with fail fast
wheels test:unit --verbose --failFast
```

### test:integration - Run Integration Tests

Runs only integration tests located in the `tests/integration` directory.

```bash
wheels test:integration
```

#### Options

Same as `test:unit` but defaults to `tests/integration` directory.

#### Examples

```bash
# Run integration tests
wheels test:integration

# Run specific workflow tests
wheels test:integration --filter=UserWorkflowTest

# With verbose output
wheels test:integration --verbose
```

### test:watch - Watch Mode

Watches for file changes and automatically reruns tests.

```bash
wheels test:watch
```

#### Options

- `--directory` - Test directory to watch (default: tests)
- `--reporter` - Test reporter format
- `--verbose` - Verbose output
- `--delay` - Delay in milliseconds before rerunning tests (default: 1000)
- `--watchPaths` - Additional paths to watch (comma-separated)
- `--excludePaths` - Paths to exclude from watching (comma-separated)
- `--bundles` - Test bundles to run
- `--labels` - Test labels to run
- `--excludes` - Test bundles to exclude
- `--filter` - Test filter pattern

#### Examples

```bash
# Watch all tests
wheels test:watch

# Watch unit tests only
wheels test:watch --directory=tests/unit

# Watch with custom delay
wheels test:watch --delay=500

# Watch additional paths
wheels test:watch --watchPaths=models,controllers

# Exclude paths from watching
wheels test:watch --excludePaths=logs,temp
```

### test:coverage - Code Coverage

Runs tests with code coverage analysis.

```bash
wheels test:coverage
```

#### Options

- `--directory` - Test directory to run (default: tests)
- `--reporter` - Coverage reporter format (html, json, xml, simple)
- `--outputDir` - Directory to output the coverage report
- `--threshold` - Coverage percentage threshold (0-100)
- `--pathsToCapture` - Paths to capture for coverage (comma-separated)
- `--whitelist` - Whitelist paths for coverage (comma-separated)
- `--blacklist` - Blacklist paths from coverage (comma-separated)
- `--bundles` - Test bundles to run
- `--labels` - Test labels to run
- `--excludes` - Test bundles to exclude
- `--filter` - Test filter pattern
- `--verbose` - Verbose output

#### Examples

```bash
# Basic coverage
wheels test:coverage

# JSON reporter with threshold
wheels test:coverage --reporter=json --threshold=80

# Coverage for specific directories
wheels test:coverage --pathsToCapture=models,controllers

# Unit tests only with coverage
wheels test:coverage --directory=tests/unit

# With whitelist
wheels test:coverage --whitelist=app/models,app/controllers
```

## Test Organization

### Directory Structure

The recommended test directory structure:

```
tests/
├── unit/           # Unit tests
│   ├── models/     # Model unit tests
│   ├── controllers/# Controller unit tests
│   └── helpers/    # Helper unit tests
├── integration/    # Integration tests
│   ├── workflows/  # User workflow tests
│   └── api/        # API integration tests
└── results/        # Test results and coverage
    └── coverage/   # Coverage reports
```

### Sample Tests

When you run `test:unit` or `test:integration` for the first time and the directories don't exist, sample test files are created automatically.

## Best Practices

1. **Separate Unit and Integration Tests**
   - Keep unit tests fast and isolated
   - Integration tests can interact with databases and external services

2. **Use Labels for Test Organization**
   ```cfc
   it("should process payments", function() {
       // test code
   }).labels("critical", "payments");
   ```

3. **Set Coverage Thresholds**
   - Aim for at least 80% code coverage
   - Use `--threshold` to enforce minimum coverage

4. **Watch Mode for TDD**
   - Use `test:watch` during development
   - Keep tests running in a separate terminal

5. **CI/CD Integration**
   - Use `--reporter=junit` for CI systems
   - Generate coverage reports with `--reporter=xml`

## Troubleshooting

### TestBox CLI Not Found

If you get an error about TestBox CLI not being installed:

```bash
box install commandbox-testbox-cli
box reload
```

### No Tests Found

Make sure your test files:
- Are in the correct directory
- Have the `.cfc` extension
- Extend `testbox.system.BaseSpec`

### Coverage Not Working

Ensure:
- Tests are actually executing code
- Paths to capture are correctly specified
- No syntax errors in tested code

## Related Commands

- `wheels test run` - Modern test runner (not a TestBox wrapper)
- `box testbox run` - Direct TestBox CLI usage
- `wheels g test` - Generate test files