---
description: Run native CFML browser tests using Playwright.
---

# wheels browser:test

Run browser test specs that extend `wheels.wheelstest.BrowserTest`. Verifies Playwright is installed before hitting the test runner URL.

## Usage

```bash
wheels browser:test [options]
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--format` | string | `text` | Output format: `text` or `json` |
| `--verbose` | boolean | `false` | Show full spec names and failure details |
| `--directory` | string | `wheels.tests.specs.wheelstest` | Test directory (dot-notation) |

## Examples

### Run all browser tests

```bash
wheels browser:test
```

### JSON output for CI

```bash
wheels browser:test --format=json
```

### Verbose output

```bash
wheels browser:test --verbose
```

### Run a specific test directory

```bash
wheels browser:test --directory=tests.specs.browser
```

## Pre-flight Check

Before running tests, this command verifies that all Playwright JARs are installed and SHA-256 hashes match. If anything is missing, it prints instructions to run `wheels browser:install`.

## Requirements

- A running Wheels server (the command auto-detects the host and port from CommandBox)
- Playwright installed via `wheels browser:install`

## See Also

- [`wheels browser:install`](browser-install.md) — Install Playwright
- [Browser Testing Guide](../../working-with-wheels/browser-testing.md) — Full browser testing guide
