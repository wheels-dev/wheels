---
description: Install Playwright JARs and browser binaries for native CFML browser testing.
---

# wheels browser:install

Install Playwright Java JARs and browser binaries for native CFML browser testing. Downloads 7 JARs from Maven Central (~200 MB), verifies SHA-256 hashes, then installs the Chromium browser binary (~170 MB).

## Usage

```bash
wheels browser:install [options]
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--force` | boolean | `false` | Re-download JARs even if SHA-256 hashes match |
| `--browser` | string | `chromium` | Which browser to install (`chromium`, `firefox`, `webkit`) |

## Examples

### Standard installation

```bash
wheels browser:install
```

### Force re-download

```bash
wheels browser:install --force
```

### Install Firefox instead

```bash
wheels browser:install --browser=firefox
```

## What Gets Installed

**JARs** (~200 MB) are downloaded to `~/.wheels/browser/lib/`:
- `playwright-1.52.0.jar` — Playwright client API
- `driver-1.52.0.jar` — Driver class
- `driver-bundle-1.52.0.jar` — Bundled Node runtime (~191 MB)
- `gson-2.12.1.jar` — JSON library
- `Java-WebSocket-1.6.0.jar` — WebSocket transport
- `slf4j-api-2.0.17.jar` — Logging API
- `slf4j-simple-2.0.17.jar` — Logging implementation

**Browser binary** (~170 MB) is installed to the Playwright cache:
- macOS: `~/Library/Caches/ms-playwright/`
- Linux: `~/.cache/ms-playwright/`

## Idempotent

Re-running is a no-op when all JARs pass SHA-256 verification and the browser is already installed. Use `--force` to re-download regardless.

## Environment Variables

| Variable | Description |
|----------|-------------|
| `WHEELS_BROWSER_HOME` | Override install directory (default: `~/.wheels/browser`) |

## Manifest

JAR URLs and SHA-256 hashes are defined in `vendor/wheels/browser-manifest.json`. This file is version-controlled and determines which Playwright version is used.

## See Also

- [`wheels browser:test`](browser-test.md) — Run browser tests
- [Browser Testing Guide](../../working-with-wheels/browser-testing.md) — Full browser testing guide
