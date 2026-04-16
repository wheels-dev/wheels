# wheels-legacyadapter

Backward compatibility adapter for migrating Wheels 3.x applications to 4.0. Provides deprecation logging, API shims, and a migration scanner for a smooth, progressive upgrade path.

## Quick Start

```bash
# Activate the adapter
cp -r packages/legacyadapter vendor/legacyadapter

# Restart or reload your app
```

That's it. Your 3.x code continues to work unchanged.

## Migration Stages

### Stage 1: Install & Go

Install the adapter. All existing 3.x code works without modification. Deprecation warnings are logged whenever legacy patterns are used, helping you identify what needs updating.

### Stage 2: Migrate

Run the migration scanner to get a full report of legacy patterns in your application:

```cfml
// In a controller action or script
var report = $runMigrationScan();
WriteDump(report);
```

Update code incrementally. The adapter provides dual-mode support — both old and new APIs work simultaneously.

Increase visibility by changing the mode:

```cfml
// config/settings.cfm
set(legacyAdapterMode = "warn");
```

### Stage 3: Remove

Set mode to `error` to catch any remaining legacy calls:

```cfml
set(legacyAdapterMode = "error");
```

Once your app runs cleanly with no deprecation errors, remove the adapter:

```bash
rm -rf vendor/legacyadapter
```

## Configuration

| Setting | Values | Default | Description |
|---------|--------|---------|-------------|
| `legacyAdapterMode` | `silent`, `log`, `warn`, `error` | `log` | Controls deprecation logging behavior |

## Compatibility Shims

| Legacy Method | Replacement | Notes |
|---|---|---|
| `renderPage()` | `renderView()` | Renamed in Wheels 3.0 |
| `renderPageToString()` | `renderView(returnAs="string")` | Removed in Wheels 3.0 |

## Plugin Diagnostics

The adapter includes `$legacyPluginInfo()` — a diagnostic function that identifies legacy plugins still active in the `plugins/` directory. It reports plugin names and versions to help you inventory what needs conversion to the modern package system. The actual migration from plugin to package is a manual process.

## Migration Scanner Patterns

The scanner detects these patterns and provides guidance:

| Pattern | Severity | Scope | Description |
|---------|----------|-------|-------------|
| `renderPage()` | Critical | All files | Must be replaced |
| `renderPageToString()` | Critical | All files | Must be replaced |
| `this.version =` | Warning | `plugins/` only | Plugin version — move to package.json |
| `this.dependency =` | Warning | `plugins/` only | Plugin deps — move to package.json |
| `extends="wheels.Test"` | Warning | All files | Use `wheels.WheelsTest` (BDD) |
| `application.wheels.*` access | Info | All files | Consider DI container |
| `extends="Model"` (short) | Info | All files | Future-proof to full path |
| `extends="Controller"` (short) | Info | All files | Future-proof to full path |
| Raw WHERE strings | Info | All files | Consider query builder |

Note: `this.version` and `this.dependency` are only flagged in files within the `plugins/` directory to avoid false positives on model CFCs, services, or other components that legitimately use version properties.

## Deactivating

```bash
rm -rf vendor/legacyadapter
```

No other changes needed. The adapter is purely additive.
