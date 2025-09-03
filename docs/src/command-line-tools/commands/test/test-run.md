# wheels test run

Run TestBox tests for your CFWheels application using the TestBox CLI integration.

> **Note:** This command replaces the deprecated `wheels test` command.

## Prerequisites

### Install TestBox CLI

```bash
box install testbox-cli --global
```

## Synopsis

```bash
wheels test run [options]
```

## Description

Executes TestBox tests through CFWheels' controller-based test runners.

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `type` | Type of tests: app, core,  | `app` |
| `recurse` | Recurse into subdirectories | `true` |
| `reporter` | Reporter format (see below) | `json` |
| `options` | Adhoc options (key:value;key2:value2) | |
| `--verbose` | Verbose output | `true` |
| `servername` | Name of server to use | |

### Coverage Options

| Option | Description |
|--------|-------------|
| `coverageSonarQubeXMLOutputPath` | Path for SonarQube XML |
| `coveragePathToCapture` | Path to capture for coverage |
| `coverageWhitelist` | Coverage whitelist |
| `coverageBlacklist` | Coverage blacklist |

### Available Reporters

- `json` - JSON format (Default)
- `text` - Plain text output
- `junit` - JUnit XML format
- `antjunit` - ANT-compatible JUnit
- `tap` - Test Anything Protocol
- `codexwiki` - CodexWiki format

## Examples

### Basic Usage
```bash
# Run tests (Default type=app)
wheels test run

# Run specific type
wheels test run type=core
```


### Output Options
```bash
# Different reporters
wheels test run reporter=json
wheels test run reporter=junit
```

```bash

# Coverage
wheels test run --coverage
wheels test run --coverage coveragePathToCapture=/models

# Verbose
wheels test run --verbose

# Combined
wheels test run bundles=UserTest --coverage --verbose reporter=json
```

## Test URL Structure

- **App tests**: `?controller=wheels.public&action=testbox&view=runner&cli=true&format=json`
- **Core tests**: `?controller=wheels.public&action=tests_testbox&view=runner&cli=true&format=json`

## Troubleshooting

### TestBox CLI Not Found
```bash
box install testbox-cli --global
```

### Server Not Running
```bash
box server start
wheels test run
```

### Wrong Test Path
```bash
# Verify test type
wheels test run type=app    # For /tests/
wheels test run type=core   # For /wheels/tests/
wheels test run type=plugin # For /plugins/tests/
```

## See Also

- [TestBox Documentation](https://testbox.ortusbooks.com/)
- [CommandBox TestBox CLI](https://www.forgebox.io/view/testbox-cli)