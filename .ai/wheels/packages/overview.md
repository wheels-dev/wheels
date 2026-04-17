# Wheels Packages

Packages are first-party optional modules that ship in the Wheels monorepo. They replace the legacy `plugins/` folder introduced pre-3.0 with a cleaner activation model: packages live in `packages/` (not auto-loaded) and are copied or symlinked to `vendor/` to activate.

## Directory layout

```
packages/              ← source / staging (never auto-loaded)
  sentry/              ← wheels-sentry package
  hotwire/             ← wheels-hotwire package
  basecoat/            ← wheels-basecoat package
vendor/                ← runtime auto-discovery at app startup
  wheels/              ← framework core (excluded from package discovery)
  sentry/              ← activated package (copied from packages/sentry)
plugins/               ← DEPRECATED; legacy plugins still load with warning
```

On startup, Wheels's `PackageLoader.cfc` scans `vendor/*/package.json` and activates each discovered package in its own try/catch (so a broken package is logged and skipped rather than crashing the app).

## Activating a package

```bash
# Copy
cp -r packages/sentry vendor/sentry

# Or symlink (easier for development)
ln -s ../../packages/sentry vendor/sentry
```

Then restart or reload the app. Deactivate by removing the `vendor/<package>` directory.

## `package.json` manifest

Every package declares a `package.json` at its root:

```json
{
    "name": "wheels-sentry",
    "version": "1.0.0",
    "author": "PAI Industries",
    "description": "Sentry error tracking for Wheels",
    "wheelsVersion": ">=3.0",
    "provides": {
        "mixins": "controller",
        "services": [],
        "middleware": []
    },
    "dependencies": {}
}
```

**`provides.mixins`** determines which framework components receive the package's public methods:

- `controller` — mix into controllers
- `view` — mix into views
- `model` — mix into models
- `global` — mix into all three
- `none` (default) — no mixin; the package provides services/middleware only

The default is `none` (explicit opt-in). Legacy plugins defaulted to `global`, which was part of why they were hard to reason about.

## First-party packages shipping with Wheels

| Package | Purpose |
|---|---|
| `sentry/` | Error tracking — captures exceptions with framework context and ships to Sentry |
| `hotwire/` | Turbo + Stimulus integration for server-driven UI |
| `basecoat/` | UI component library (forms, buttons, layouts) styled for Wheels conventions |

Each has its own `CLAUDE.md` with usage instructions. Check `packages/<name>/CLAUDE.md` for package-specific details.

## Error isolation

Each package loads inside its own try/catch. Common failure modes:

- **Missing `package.json`**: the package is silently skipped
- **Invalid JSON**: logged to `wheels` log, package skipped
- **Wheels version mismatch** (`wheelsVersion` range fails): logged, package skipped
- **Exception during load**: logged with stack, package skipped

A broken package never crashes the host app.

## Testing a package

Once a package is activated in `vendor/`, run its tests via:

```bash
curl "http://localhost:60007/wheels/core/tests?db=sqlite&format=json&directory=vendor.sentry.tests"
```

The `directory` parameter names the package under `vendor/` and scopes the TestBox run to that subdirectory.

## Legacy plugins

The `plugins/` folder still works, but emits a deprecation warning on app startup. New work should use `packages/`. Existing plugins continue to function but should be migrated to the package format when touched.

## See also

- `packages/<name>/CLAUDE.md` — per-package documentation
- `vendor/wheels/PackageLoader.cfc` — implementation of the discovery + activation logic
