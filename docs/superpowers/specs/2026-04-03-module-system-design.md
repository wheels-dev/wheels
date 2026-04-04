# Wheels 4.0 Module System Design

**Issue:** #1966
**Task:** W-006
**Date:** 2026-04-03

## Summary

Extend the existing `PackageLoader.cfc` into a full module system with dependency declarations, dependency graph compilation with topological sort, lazy loading, and CLI tooling. Keep `package.json` as the manifest format (not `box.json`) since the current ecosystem already uses it.

## Scope Decisions

The reviewer identified 6 capabilities from Issue #1966. Here's what's in scope:

| # | Capability | Status | Rationale |
|---|-----------|--------|-----------|
| 1 | Dependency declarations (`requires`, `replaces`, `suggests`) | **In scope** | Core of the module system |
| 2 | CLI commands (`module:search`, `module:install`, `module:create`) | **Deferred** | CLI commands live in the `cli/` directory which uses CommandBox. Registry-dependent commands (`search`, `install`) need the registry first. `module:create` is useful but is a scaffolding concern, not a runtime concern. |
| 3 | Module registry | **Deferred** | Requires external infrastructure (API server, index). Out of scope for framework core. |
| 4 | Lazy loading | **In scope** | Deferred instantiation until first use |
| 5 | Dependency graph (topological sort, cycle detection) | **In scope** | Required for correct load ordering |
| 6 | Manifest format (`box.json` vs `package.json`) | **Keep `package.json`** | Three packages already ship with `package.json`. The existing `PackageLoader` reads `package.json`. `box.json` is CommandBox-specific; Wheels is moving toward LuCLI/engine-independence. No benefit to switching. |

### Why defer CLI and registry?

The module system's runtime capabilities (dependency resolution, lazy loading, graph compilation) are independent of CLI tooling and registry infrastructure. CLI commands can be added in a follow-up task once the manifest schema is stable. The registry requires decisions about hosting, API design, and community governance that are out of scope for framework core.

## Architecture

### Manifest Schema Extension

The `package.json` manifest gains three new fields under `provides`:

```json
{
    "name": "wheels-audit-log",
    "version": "1.2.0",
    "description": "Audit logging for model changes",
    "wheelsVersion": ">=4.0",
    "provides": {
        "mixins": "model",
        "services": [],
        "middleware": []
    },
    "requires": {
        "wheels-events": ">=1.0.0"
    },
    "replaces": {
        "wheels-simple-audit": "*"
    },
    "suggests": {
        "wheels-sentry": ">=1.0.0"
    }
}
```

**Field semantics:**

- **`requires`** (struct, keys = package names, values = semver constraints): Hard dependencies. The package will not load unless all required packages are present in `vendor/` and satisfy version constraints. Missing requires = error logged, package skipped.

- **`replaces`** (struct): Declares that this package replaces another. If both are in `vendor/`, the replacing package wins and the replaced one is skipped with a log message. Version constraint applies to the replaced package's version.

- **`suggests`** (struct): Soft dependencies. If present, load before this package. If absent, no error. The package can check at runtime whether a suggested package is loaded.

**Version constraint format:** Simple semver ranges — `>=1.0.0`, `>=1.0.0 <2.0.0`, `*` (any version), exact version `1.2.3`. Implemented with a lightweight `$satisfiesVersion()` function (no npm-level complexity needed).

### Dependency Graph

A new `ModuleGraph.cfc` component handles dependency resolution:

1. **Build phase:** Reads all discovered manifests, builds adjacency list (package → its requirements)
2. **Conflict detection:** Checks `replaces` declarations, marks replaced packages as excluded
3. **Cycle detection:** DFS-based cycle detection. If a cycle is found, all packages in the cycle are marked as failed with a descriptive error.
4. **Topological sort:** Kahn's algorithm produces a load order where dependencies load before dependents
5. **Suggest handling:** Suggested packages add soft edges — they influence order but don't block loading

**Output:** An ordered array of package directory names, plus a set of excluded (replaced) packages.

### Lazy Loading

Current behavior: `$discover()` eagerly instantiates every package CFC via `CreateObject().init()`.

New behavior: Two-phase loading.

1. **Phase 1 — Manifest discovery** (always eager): Scan `vendor/`, parse all `package.json` files, build the dependency graph. This is fast (file reads only, no CFC compilation).

2. **Phase 2 — CFC instantiation** (lazy or eager): 
   - **Eager mode** (default for packages declaring mixins): CFC is instantiated during startup, mixins collected immediately.
   - **Lazy mode** (for packages declaring `"lazy": true` in manifest, or packages with `mixins: "none"` and no middleware): CFC instantiation is deferred. A proxy struct is stored in `variables.packages[name]` that instantiates the real CFC on first access.

The lazy proxy is a simple struct with an `$getInstance()` method that does the actual `CreateObject().init()` on first call and caches the result. ServiceProvider `register()` and `boot()` calls trigger instantiation.

**Why not make everything lazy?** Mixin collection requires introspecting the CFC's methods, which requires instantiation. Packages that provide mixins must be eagerly loaded. Only service-only or suggest-only packages benefit from lazy loading.

### Integration with Existing PackageLoader

`PackageLoader.cfc` is extended (not replaced):

1. `$discover()` is refactored into two steps:
   - `$discoverManifests()` — scans vendor/, parses manifests, returns array of manifest structs
   - `$resolveAndLoad()` — builds graph via `ModuleGraph.cfc`, loads in topological order

2. New `$loadPackageLazy()` method stores a lazy proxy instead of a live CFC instance

3. Existing public API (`getPackages()`, `getMixins()`, etc.) is unchanged — backwards compatible

4. `$loadPackage()` gains a `lazy` boolean parameter

### New Components

| Component | Location | Purpose |
|-----------|----------|---------|
| `ModuleGraph.cfc` | `vendor/wheels/ModuleGraph.cfc` | Dependency graph building, cycle detection, topological sort |
| `SemVer.cfc` | `vendor/wheels/SemVer.cfc` | Semver parsing and constraint matching |

### Error Handling

- **Missing required dependency:** Package is added to `failedPackages` with error "Required package 'X' not found". Other packages that don't depend on it continue loading.
- **Version mismatch:** Same as missing — package fails with "Required package 'X' version Y.Z does not satisfy constraint >=A.B"
- **Cycle detected:** All packages in the cycle are failed with "Circular dependency detected: A → B → C → A"
- **Replaced package:** Not an error — logged as info: "Package 'X' replaced by 'Y'"

## Testing Strategy

New test fixtures in `vendor/wheels/tests/_assets/packages/`:

- `depA/` — requires depB (tests ordering)
- `depB/` — no dependencies (loads first)
- `cycleA/` — requires cycleB (cycle detection)
- `cycleB/` — requires cycleA
- `replacer/` — replaces goodpkg
- `suggestpkg/` — suggests goodpkg (soft dependency)
- `lazypkg/` — lazy: true, mixins: none

Test specs:
- `ModuleGraphSpec.cfc` — graph building, topological sort, cycle detection, replacement
- `SemVerSpec.cfc` — version parsing and constraint matching
- Extended `PackageLoaderSpec.cfc` — lazy loading, dependency ordering, replacement behavior

## What This Does NOT Do

- No CLI commands (deferred to follow-up task)
- No registry/search infrastructure (requires external service)
- No `box.json` support (staying with `package.json`)
- No automatic download/install of dependencies
- No runtime hot-reloading of modules
- No breaking changes to existing `package.json` manifests (new fields are optional)
