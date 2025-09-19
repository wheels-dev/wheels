# Advanced Testing Commands

The Wheels CLI provides advanced testing capabilities through integration with TestBox. These commands offer specialized test runners for different testing scenarios.

## Available Commands

### test:all - Run All Tests

Runs all tests in your application using TestBox CLI.

```bash
wheels test:all
```

#### Options

- `--type` - Type of tests to run: (app, core, plugin) - default: app
- `--format` - Output format (txt, json, junit, html) - default: txt
- `--coverage` - Generate coverage report
- `--coverageReporter` - Coverage reporter format (html, json, xml)
- `--coverageOutputDir` - Directory for coverage output
- `--verbose` - Verbose output
- `--failFast` - Stop on first test failure
- `--directory` - Test directory to run (default: tests/specs)
- `--recurse` - Recurse into subdirectories
- `--bundles` - Comma-delimited list of test bundles to run
- `--labels` - Comma-delimited list of test labels to run
- `--excludes` - Comma-delimited list of test labels to exclude
- `--filter` - Test filter pattern

#### Examples

```bash
# Run all app tests
wheels test:all

# Run with JSON format
wheels test:all --format=json

# Run with coverage
wheels test:all --coverage --coverageReporter=html

# Filter tests by name
wheels test:all --filter=UserTest --verbose

# Run core tests
wheels test:all --type=core

# Run specific bundles
wheels test:all --bundles=tests.specs.unit.models,tests.specs.unit.controllers
```

### test:unit - Run Unit Tests

Runs only unit tests located in the `tests/specs/unit` directory.

```bash
wheels test:unit
```

#### Options

- `--type` - Type of tests to run: (app, core, plugin) - default: app
- `--format` - Output format (txt, json, junit, html) - default: txt
- `--verbose` - Verbose output
- `--failFast` - Stop on first test failure
- `--bundles` - Comma-delimited list of test bundles to run
- `--labels` - Comma-delimited list of test labels to run
- `--excludes` - Comma-delimited list of test labels to exclude
- `--filter` - Test filter pattern
- `--directory` - Unit test directory (default: tests/specs/unit)

#### Examples

```bash
# Run unit tests
wheels test:unit

# Run with JSON format
wheels test:unit --format=json

# Filter specific tests
wheels test:unit --filter=UserModelTest

# Verbose output with fail fast
wheels test:unit --verbose --failFast

# Run core unit tests
wheels test:unit --type=core
```

### test:integration - Run Integration Tests

Runs only integration tests located in the `tests/specs/integration` directory.

```bash
wheels test:integration
```

#### Options

Same as `test:unit` but defaults to `tests/specs/integration` directory.

#### Examples

```bash
# Run integration tests
wheels test:integration

# Run specific workflow tests
wheels test:integration --filter=UserWorkflowTest

# With verbose output and JUnit format
wheels test:integration --verbose --format=junit

# Run plugin integration tests
wheels test:integration --type=plugin
```

### test:watch - Watch Mode

Watches for file changes and automatically reruns tests.

```bash
wheels test:watch
```

#### Options

- `--type` - Type of tests to run: (app, core, plugin) - default: app
- `--directory` - Test directory to watch (default: tests/specs)
- `--format` - Output format (txt, json, junit, html) - default: txt
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
wheels test:watch --directory=tests/specs/unit

# Watch with custom delay and JSON format
wheels test:watch --delay=500 --format=json

# Watch additional paths
wheels test:watch --watchPaths=models,controllers

# Exclude paths from watching
wheels test:watch --excludePaths=logs,temp
```

### test:coverage - Code Coverage

Runs tests with code coverage analysis (requires FusionReactor).

```bash
wheels test:coverage
```

#### Options

- `--type` - Type of tests to run: (app, core, plugin) - default: app
- `--directory` - Test directory to run (default: tests/specs)
- `--format` - Output format (txt, json, junit, html) - default: txt
- `--outputDir` - Directory to output the coverage report (default: tests/results/coverage)
- `--threshold` - Coverage percentage threshold (0-100)
- `--pathsToCapture` - Paths to capture for coverage (default: /app)
- `--whitelist` - Whitelist paths for coverage (default: *.cfc)
- `--blacklist` - Blacklist paths from coverage (default: *Test.cfc,*Spec.cfc)
- `--bundles` - Test bundles to run
- `--labels` - Test labels to run
- `--excludes` - Test bundles to exclude
- `--filter` - Test filter pattern
- `--verbose` - Verbose output

#### Examples

```bash
# Basic coverage
wheels test:coverage

# With threshold and specific directory
wheels test:coverage --threshold=80 --directory=tests/specs/unit

# Coverage for specific paths
wheels test:coverage --pathsToCapture=/models,/controllers

# With JUnit output
wheels test:coverage --format=junit --outputDir=coverage-reports
```

## Test Organization

### Directory Structure

The standard test directory structure for Wheels applications:

```
tests/
├── specs/             # Main test directory (default for type=app)
│   ├── unit/          # Unit tests
│   │   ├── models/    # Model unit tests
│   │   ├── controllers/ # Controller unit tests
│   │   └── helpers/   # Helper unit tests
│   ├── integration/   # Integration tests
│   │   ├── workflows/ # User workflow tests
│   │   └── api/       # API integration tests
│   └── functions/     # Function-specific tests
└── results/           # Test results and reports
    └── coverage/      # Coverage reports
```

### Test Types

The `--type` parameter determines which test suite to run:

- **app** (default): Runs tests in `/wheels/app/tests` route, uses `tests/specs` directory
- **core**: Runs tests in `/wheels/core/tests` route, for framework tests

### Sample Tests

When you run `test:unit` or `test:integration` for the first time and the directories don't exist, sample test files are created automatically in the correct locations:
- Unit tests: `tests/specs/unit/SampleUnitTest.cfc`
- Integration tests: `tests/specs/integration/SampleIntegrationTest.cfc`

## Output Formats

All test commands support multiple output formats via the `--format` parameter:

- **txt** (default): Human-readable text output
- **json**: JSON format for parsing and automation
- **junit**: JUnit XML format for CI/CD integration
- **html**: HTML format for browser viewing

## Best Practices

1. **Organize Tests by Type**
   - Keep unit tests in `tests/specs/unit/`
   - Keep integration tests in `tests/specs/integration/`
   - Use subdirectories for better organization

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
   - Use `--format=junit` for CI systems
   - Generate coverage reports with `--coverageReporter=xml`
   - Use `--failFast` for faster feedback

## Coverage Requirements

Code coverage requires FusionReactor 8.0+ to be installed and configured:

1. Install FusionReactor
2. Enable Code Coverage in FusionReactor settings
3. Restart your ColdFusion/Lucee server
4. Run `wheels test:coverage`

## Troubleshooting

### TestBox CLI Not Found

If you get an error about TestBox CLI not being installed:

```bash
box install testbox-cli
box reload
```

### No Tests Found

Make sure your test files:
- Are in the correct directory (`tests/specs/` or subdirectories)
- Have the `.cfc` extension
- Extend `wheels.Testbox`

### Coverage Not Working

If coverage shows as disabled:
- Verify FusionReactor is installed
- Check that Code Coverage is enabled in FusionReactor settings
- Ensure you've restarted the server after enabling coverage

### Test Routes Not Working

The test commands use these routes:
- App tests: `http://localhost:port/wheels/app/tests`
- Core tests: `http://localhost:port/wheels/core/tests`

Ensure these routes are accessible and properly configured.

## Related Commands

- `wheels test run` - Modern test runner (not a TestBox wrapper)
- `box testbox run` - Direct TestBox CLI usage
- `wheels g test` - Generate test files