# Testing Commands

The Wheels CLI provides robust tools for testing your application, including running tests, generating code coverage reports, and debugging test failures.

## Test

Runs tests for your application.

### Usage

```bash
wheels test [type] [servername] [reload] [debug]
```

### Parameters

- `type`: Type of tests to run (core, app, plugin) (default: app)
- `servername`: Name of server to reload (optional)
- `reload`: Force a reload of the application (default: false)
- `debug`: Show debug information (default: false)

### Examples

```bash
# Run application tests
wheels test

# Run core framework tests
wheels test core

# Run tests with debug information
wheels test app true true
```

## Test Coverage

Generate code coverage reports for tests to identify untested areas of your code.

### Usage

```bash
wheels test:coverage [type] [--servername=] [--reload=false] [--debug=false] [--outputDir=tests/coverageReport]
```

### Parameters

- `type`: Type of tests to run (app, core, or plugin) (default: app)
- `servername`: Name of server to reload (default: current)
- `reload`: Force a reload of wheels (default: false)
- `debug`: Show debug info (default: false)
- `outputDir`: Directory to output the coverage report (default: tests/coverageReport)

### Examples

```bash
# Generate coverage report for application tests
wheels test:coverage

# Generate coverage report for core tests with debug information
wheels test:coverage core --debug=true

# Specify a custom output directory
wheels test:coverage --outputDir=reports/coverage
```

## Test Debug

Run tests with interactive debugging capabilities to help diagnose test failures.

### Usage

```bash
wheels test:debug [type] [--spec=] [--servername=] [--reload=false] [--breakOnFailure=true] [--outputLevel=3]
```

### Parameters

- `type`: Type of tests to run (app, core, or plugin) (default: app)
- `spec`: Specific test spec to run (e.g., models.user) (optional)
- `servername`: Name of server to reload (default: current)
- `reload`: Force a reload of wheels (default: false)
- `breakOnFailure`: Stop test execution on first failure (default: true)
- `outputLevel`: Output verbosity (1=minimal, 2=normal, 3=verbose) (default: 3)

### Examples

```bash
# Debug application tests
wheels test:debug

# Debug a specific test
wheels test:debug --spec=models.user

# Debug with minimal output and continue on failures
wheels test:debug --outputLevel=1 --breakOnFailure=false
```

## Understanding Test Results

### Test Coverage

The test coverage report includes:

- **Total Coverage**: Percentage of code that is covered by tests
- **Files Analyzed**: Number of files included in the coverage analysis
- **Detailed Coverage**: Coverage breakdown by file and function
- **Uncovered Areas**: Code sections that are not tested

The report is generated as HTML and can be viewed in a browser for a detailed graphical representation of code coverage.

### Debug Output

The debug output includes:

- **Test Results Summary**: Total tests, passed, failed, errors, skipped
- **Duration**: Total time taken to execute tests
- **Detailed Failures**: Information about failed tests including:
  - Test name
  - Failure message
  - Stack trace showing where the failure occurred
  - Context information to help understand the failure

## Writing Testable Code

To get the most out of the testing tools, follow these best practices:

1. **Isolate Logic**: Keep business logic separate from presentation code
2. **Dependency Injection**: Use dependency injection to make components testable in isolation
3. **Small, Focused Components**: Break down complex functionality into smaller, testable units
4. **Meaningful Names**: Use clear, descriptive names for tests to document expected behavior
5. **Test Edge Cases**: Include tests for boundary conditions and error scenarios

## Integrating with Continuous Integration

The testing commands can be integrated with CI/CD pipelines:

```bash
# Example CI command for testing with coverage
wheels test:coverage --outputDir=artifacts/coverage
```

This allows you to automatically run tests and generate coverage reports during your build process.