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
| `paginationLinks()` | `paginationNav()` | Old method still works; nav is composable |

## Migration Scanner Patterns

The scanner detects these patterns and provides guidance:

| Pattern | Severity | Description |
|---------|----------|-------------|
| `renderPage()` | Critical | Must be replaced |
| `renderPageToString()` | Critical | Must be replaced |
| `this.version =` | Warning | Plugin version — move to package.json |
| `this.dependency =` | Warning | Plugin deps — move to package.json |
| `extends="wheels.Test"` | Warning | Use `wheels.WheelsTest` for TestBox |
| `application.wheels.*` access | Info | Consider DI container |
| `extends="Model"` (short) | Info | Future-proof to full path |
| `extends="Controller"` (short) | Info | Future-proof to full path |
| Raw WHERE strings | Info | Consider query builder |

## Deactivating

```bash
rm -rf vendor/legacyadapter
```

No other changes needed. The adapter is purely additive.
