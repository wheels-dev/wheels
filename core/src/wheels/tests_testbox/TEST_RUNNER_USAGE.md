# Wheels Core Test Runner Usage

This document describes how to use the Wheels core test runners.

## Test Runners

There are two test runners available:

1. **core-runner.cfm** - Full test runner that executes all tests
2. **minimal-runner.cfm** - Lightweight runner that only loads and validates test files (does not execute tests)

## Running Tests

Tests can be accessed via the `/wheels/testbox` URL endpoint. The runner used depends on the `minimal` URL parameter.

### Full Test Runner (Default)

```
http://localhost:60006/wheels/testbox
http://localhost:60006/wheels/testbox?format=json
```

### Minimal Test Runner

```
http://localhost:60006/wheels/testbox?minimal=true
http://localhost:60006/wheels/testbox?minimal=true&format=json
```

## Output Formats

Both runners support multiple output formats via the `format` URL parameter:

### HTML (Default)
- **URL**: `/wheels/testbox` or `/wheels/testbox?format=html`
- **Description**: Interactive HTML interface with test results
- **Use Case**: Development and manual testing

### JSON
- **URL**: `/wheels/testbox?format=json`
- **Description**: Machine-readable JSON output
- **HTTP Status**: 200 for success, 417 for failures
- **Use Case**: CI/CD pipelines, automated testing

### Text
- **URL**: `/wheels/testbox?format=text` or `/wheels/testbox?format=txt`
- **Description**: Plain text summary with failure details
- **Use Case**: Command-line tools, log files

### Simple
- **URL**: `/wheels/testbox?format=simple`
- **Description**: One-line summary of test results
- **Use Case**: Quick status checks

### JUnit/XML
- **URL**: `/wheels/testbox?format=junit` or `/wheels/testbox?format=xml`
- **Description**: JUnit-compatible XML format
- **Use Case**: Integration with test reporting tools

## URL Parameters

### Core Runner Parameters

- **format** - Output format (html, json, text, txt, simple, junit, xml)
- **db** - Database to use for tests (mysql, sqlserver, sqlserver_cicd, postgres, h2)
- **populate** - Whether to populate test database (true/false, default: true)
- **reporter** - Custom TestBox reporter class (default: wheels.core_tests.Reporter)
- **only** - Filter results (e.g., "failure,error")

### Minimal Runner Parameters

- **format** - Output format (html, json, text, txt, simple, junit, xml)

## Examples

### CI Pipeline Usage
```bash
# Run tests with JSON output and filter failures
curl "http://localhost:60006/wheels/testbox?db=mysql&format=json&only=failure,error"
```

### Quick Test Check
```bash
# Check if tests are loading correctly
curl "http://localhost:60006/wheels/testbox?minimal=true&format=simple"
```

### Full Test Run with Text Output
```bash
# Run all tests and get plain text results
curl "http://localhost:60006/wheels/testbox?format=text"
```

## Test Environment

The core runner sets up a complete test environment including:

- Test-specific routes
- Test database with migrations
- CSRF token configuration
- Test-specific application settings
- Isolated test assets (controllers, models, views)

The minimal runner only:
- Loads test files
- Verifies they have a `run` method
- Reports loading status

## Troubleshooting

### Common Issues

1. **404 Errors for Formats**: Ensure you're using the correct format parameter value
2. **Database Errors**: Check that the test datasource is configured
3. **Module Loading Errors**: The runners avoid TestBox module system to prevent BINDER errors
4. **Timeout Issues**: Tests have a 30-minute timeout (1800 seconds)

### HTTP Status Codes

- **200 OK**: All tests passed (or minimal runner loaded successfully)
- **417 Expectation Failed**: Test failures or errors occurred (JSON format only)
- **500 Internal Server Error**: Runner encountered an error
