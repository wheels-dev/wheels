# Advanced Testing Commands

The Wheels CLI provides advanced testing capabilities through integration with TestBox. These commands offer specialized test runners for different testing scenarios.

## Available Commands

### test:all - Run All Tests

Runs all tests in your application using TestBox CLI.

```bash
wheels test:all
```

#### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--type` | string | app | Type of tests to run: (app, core) |
| `--format` | string | txt | Output format (txt, json, junit, html) |
| `--coverage` | boolean | false | Generate coverage report |
| `--coverageReporter` | string | - | Coverage reporter format (html, json, xml) |
| `--coverageOutputDir` | string | - | Directory for coverage output |
| `--verbose` | boolean | true | Display extra details including passing and skipped tests |
| `--directory` | string | tests/specs | The directory to use to discover test bundles and specs to test. Mutually exclusive with `bundles`. Example: `directory=tests.specs` |
| `--recurse` | boolean | true | Recurse the directory mapping or not |
| `--bundles` | string | - | The path or list of paths of the spec bundle CFCs to run and test ONLY |
| `--labels` | string | - | The list of labels that a suite or spec must have in order to execute |
| `--excludes` | string | - | The list of labels that a suite or spec must not have in order to execute |
| `--filter` | string | - | Test filter pattern |

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

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--type` | string | app | Type of tests to run: (app, core) |
| `--format` | string | txt | Output format (txt, json, junit, html) |
| `--verbose` | boolean | true | Display extra details including passing and skipped tests |
| `--bundles` | string | - | The path or list of paths of the spec bundle CFCs to run and test ONLY |
| `--labels` | string | - | The list of labels that a suite or spec must have in order to execute |
| `--excludes` | string | - | The list of labels that a suite or spec must not have in order to execute |
| `--filter` | string | - | Test filter pattern |
| `--directory` | string | tests/specs/unit | The directory to use to discover test bundles and specs to test. Mutually exclusive with `bundles`. Example: `directory=tests.specs` |

#### Examples

```bash
# Run unit tests
wheels test:unit

# Run with JSON format
wheels test:unit --format=json

# Filter specific tests
wheels test:unit --filter=UserModelTest

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

# Run integration tests
wheels test:integration --type=app
```

### test:watch - Watch Mode

Watches for file changes and automatically reruns tests.

```bash
wheels test:watch
```

#### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--type` | string | app | Type of tests to run: (app, core) |
| `--directory` | string | tests/specs | The directory to use to discover test bundles and specs to test. Mutually exclusive with `bundles`. Example: `directory=tests.specs` |
| `--format` | string | txt | Output format (txt, json, junit, html) |
| `--verbose` | boolean | true | Display extra details including passing and skipped tests |
| `--delay` | integer | 1000 | Delay in milliseconds before rerunning tests |
| `--watchPaths` | string | - | Additional paths to watch (comma-separated) |
| `--excludePaths` | string | - | Paths to exclude from watching (comma-separated) |
| `--bundles` | string | - | The path or list of paths of the spec bundle CFCs to run and test ONLY |
| `--labels` | string | - | The list of labels that a suite or spec must have in order to execute |
| `--excludes` | string | - | The list of labels that a suite or spec must not have in order to execute |
| `--filter` | string | - | Test filter pattern |

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

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--type` | string | app | Type of tests to run: (app, core) |
| `--directory` | string | tests/specs | The directory to use to discover test bundles and specs to test. Mutually exclusive with `bundles`. Example: `directory=tests.specs` |
| `--format` | string | txt | Output format (txt, json, junit, html) |
| `--outputDir` | string | tests/results/coverage | Directory to output the coverage report |
| `--threshold` | integer | - | Coverage percentage threshold (0-100) |
| `--pathsToCapture` | string | /app | Paths to capture for coverage |
| `--whitelist` | string | *.cfc | Whitelist paths for coverage |
| `--blacklist` | string | *Test.cfc,*Spec.cfc | Blacklist paths from coverage |
| `--bundles` | string | - | The path or list of paths of the spec bundle CFCs to run and test ONLY |
| `--labels` | string | - | The list of labels that a suite or spec must have in order to execute |
| `--excludes` | string | - | The list of labels that a suite or spec must not have in order to execute |
| `--filter` | string | - | Test filter pattern |
| `--verbose` | boolean | true | Display extra details including passing and skipped tests |

#### Examples

```bash
# Basic coverage
wheels test:coverage

# With threshold and specific directory
wheels test:coverage --threshold=80 --directory=tests/specs/unit

# Coverage for specific paths
wheels test:coverage --pathsToCapture=/models,/controllers

# With JUnit output
wheels test:coverage --format=json --outputDir=coverage-reports
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