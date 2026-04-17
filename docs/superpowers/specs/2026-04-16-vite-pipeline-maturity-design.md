# Vite Pipeline Maturity — Approach D Design

**Date:** 2026-04-16
**Status:** Approved (Approach D decided in prior brainstorming session; this document captures the design for implementation.)
**Author:** Peter Amiri + Claude

## Problem

`docs/wheels-vs-frameworks.md` lists asset-pipeline maturity as the last remaining gap after Wheels 4.0 closes most parity rows against Rails 8 / Laravel 12 / Django 5. Specifically:

1. **No transitive modulepreload.** `viteScriptTag()` emits only the entry's own script. Vite's build output lists transitive chunk imports in `manifest.imports`, and Rails/Laravel's Vite integrations emit `<link rel="modulepreload">` for each. Missing this is a real production-perf miss — the browser can't start fetching shared chunks until the entry script parses.
2. **No transitive CSS.** `viteScriptTag()` and `viteStyleTag()` emit CSS only from the entry's own `css` array. If a shared chunk contributes CSS (common with CSS-in-JS or shared stylesheets in component libraries), that CSS is dropped from the document.
3. **Silent failure in production.** When `showErrorInformation=false` (typical prod), a missing manifest entry returns the raw entrypoint string or empty string. This turns a deploy-time misconfiguration into a runtime mystery — links to `/build/src/main.js` load 404s with no useful error.
4. **No explicit preload helper.** Turbo Drive (shipped in Wheels 4.0 via the Hotwire package) uses hover-preload — on `mouseenter`, fetch the next page and its assets. Without a dedicated `vitePreloadTag(entrypoint)`, views can't declare "I know we'll navigate here soon — start fetching its JS now."

Post-4.0 asset-pipeline maturity is a stated goal in the 4.0 audit's follow-ups list (`docs/releases/wheels-4.0-audit.md`, "Vite pipeline maturity").

## Solution (Approach D — "C lite")

Extract a private `$viteResolveAssets(entrypoint)` function inside `vendor/wheels/view/vite.cfc` that walks the manifest once and returns a resolved asset set. Existing helpers become thin callers; a new `vitePreloadTag()` reuses the same seam. Keep everything in `vite.cfc` — no separate CFC.

**Why not full Approach C (dedicated CFC):** the resolver is ~40 lines of logic; a separate CFC adds component-file ceremony, mixin wiring, and test-scaffolding burden for a private surface. Leaving the helper in `vite.cfc` gives us the internal seam without any user-visible structural change.

**Why not Approach A (inline in each helper):** duplication. The transitive-imports walker is the same in `viteScriptTag()`, `viteStyleTag()`, and `vitePreloadTag()`. Inlining it three times invites drift.

**Why not Approach B (CFC per entry type — scripts/styles/preloads):** over-engineered. Vite's manifest is one data structure; one resolver walks it.

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Public API shape | Add `vitePreloadTag(entrypoint)`; `viteScriptTag()` and `viteStyleTag()` remain with additive behavior | Backward-compatible; new helper is opt-in |
| Resolver location | Private `$viteResolveAssets()` inside `vite.cfc` | Minimal structural change; fits the existing `$vite*` helper convention |
| Resolver return shape | `{scripts: [...], styles: [...], preloads: [...]}` | Mirrors Rails' `ViteRails::Manifest::Entry` expanded output; each caller picks what it needs |
| Transitive walk | Recursive with visited-set for cycle safety | Manifests can have circular imports in rare dev-time states; defensive programming for prod |
| `preloads` semantics | Transitive `imports` chain from the manifest (chunk keys) — the entry itself is NOT in this list | Matches Rails' modulepreload behavior; `viteScriptTag()` emits the entry as `<script>`, preloads as `<link>` |
| Modulepreload emission | Via `$htmlhead()` so preloads land in `<head>` regardless of where `viteScriptTag()` was called from | Preloads in `<body>` are effectively useless — the parser has already found the entry script |
| Strict mode default | New setting `viteStrictManifest` defaults to `true` | Consistent with Wheels 4.0's deny-by-default security posture. Missing entries are deployment bugs, not runtime fallbacks |
| Strict mode opt-out | `set(viteStrictManifest=false)` restores 3.x silent behavior | Legacy apps and Legacy Compatibility Adapter users have an escape hatch |
| Dev-mode behavior | `$viteResolveAssets()` is called only in prod (non-dev) mode | Dev mode has no manifest; Vite handles chunk resolution |
| Cycle handling | Visited-set + recursive walk; revisit skipped | Simple, covers the rare self-referential case that can appear in source-map-enabled dev builds |
| Test fixture strategy | Fixture manifests inline in `viteSpec.cfc` beforeEach blocks, simulating `imports` trees up to 3 levels deep | No file-system fixtures; keeps tests hermetic and fast |

## Architecture

### Current helper graph (3.x / early 4.0)

```
viteAsset()     → reads manifest, returns file URL
viteScriptTag() → reads manifest, emits entry CSS links + entry <script>
viteStyleTag()  → reads manifest, emits one <link rel=stylesheet>
```

Each helper walks the manifest independently; each handles the missing-entry case independently. CSS and preloads from transitive imports are dropped.

### Target helper graph (Approach D)

```
$viteResolveAssets(entrypoint)
    └── walks manifest.imports transitively, dedup via visited set
    └── returns {scripts, styles, preloads}

viteAsset()         → (unchanged semantics; adds strict-mode path)
viteScriptTag()     → calls $viteResolveAssets()
                      → emits styles as <link rel=stylesheet>
                      → emits entry as <script type=module>
                      → emits preloads as <link rel=modulepreload> via $htmlhead()
viteStyleTag()      → calls $viteResolveAssets()
                      → emits every style as <link rel=stylesheet>
                      → (ignores scripts/preloads)
vitePreloadTag()    → calls $viteResolveAssets()
                      → emits entry + preloads as <link rel=modulepreload>
                      → (no scripts, no styles)
```

### Resolver algorithm

```
$viteResolveAssets(entrypoint):
    manifest = $viteManifest()
    if entrypoint not in manifest:
        $viteMissingEntry(entrypoint)        # strict-mode gate
        return {scripts: [], styles: [], preloads: []}

    entry = manifest[entrypoint]
    scripts = [entry.file]                    # always first
    styles  = list copy of entry.css (or empty)
    preloads = []
    visited = {entrypoint}

    walk(importKeys = entry.imports or []):
        for key in importKeys:
            if key in visited: continue
            visited.add(key)
            if key not in manifest: continue  # defensive; shouldn't happen
            chunk = manifest[key]
            preloads.append(chunk.file)        # for modulepreload
            for css in (chunk.css or []):
                styles.append(css)             # transitive CSS
            walk(chunk.imports or [])          # recurse

    return {scripts, styles, preloads}
```

### Missing-entry gate

```
$viteMissingEntry(entrypoint):
    strict = $get("viteStrictManifest") default true
    showErr = $get("showErrorInformation")
    if strict or showErr:
        Throw(type="Wheels.ViteAssetNotFound", ...)
    # non-strict + non-showErr: silent (3.x behavior)
```

### Setting registration

Add to `vendor/wheels/events/init/views.cfm`:
```cfm
application.$wheels.viteStrictManifest = true;
```

No environment-specific default — the whole point is "deploy bugs should be visible." Apps that need 3.x behavior set `viteStrictManifest=false` explicitly.

## Public API additions

### `vitePreloadTag(entrypoint, [head=true])`

```cfm
/**
 * Returns <link rel="modulepreload"> tags for a Vite entrypoint and its
 * transitive chunk imports. Useful for Turbo Drive hover-preload patterns
 * or for explicit warming of assets a subsequent navigation will need.
 *
 * In development mode, returns an empty string — Vite handles module
 * resolution dynamically and modulepreload is unnecessary.
 *
 * [section: View Helpers]
 * [category: Asset Functions]
 *
 * @entrypoint The source entrypoint path (e.g. "src/main.js").
 * @head Set to `false` to return the markup for inline placement;
 *       default true emits via `$htmlhead()` so tags land in <head>.
 */
public string function vitePreloadTag(
    required string entrypoint,
    boolean head = true
)
```

Behavior:
- Dev mode: returns empty string.
- Prod mode, strict-miss: throws `Wheels.ViteAssetNotFound`.
- Prod mode, non-strict miss: returns empty string.
- Prod mode, hit: emits `<link rel="modulepreload" href="...entry.file" />` for the entry, then one for each transitive chunk in `preloads`. By default (`head=true`), emits via `$htmlhead()` and returns empty string.

### `viteScriptTag(entrypoint, [head=false])` — new behavior

Additive, backward-compatible:
1. Still emits CSS links (now from `styles`, which is entry CSS + transitive CSS).
2. Still emits the entry `<script type="module">`.
3. **Newly emits** `<link rel="modulepreload">` for each transitive chunk in `preloads`, always via `$htmlhead()` (regardless of the `head` argument), so preloads always land in `<head>` where they're useful.

### `viteStyleTag(entrypoint, [head=false])` — new behavior

Additive:
1. Still emits a `<link rel="stylesheet">` for the entrypoint's own file.
2. **Newly emits** additional `<link rel="stylesheet">` tags for every CSS in transitive chunks.

### Strict manifest — new setting

`viteStrictManifest` (boolean, default `true`):
- `true`: missing entry throws `Wheels.ViteAssetNotFound` regardless of `showErrorInformation`.
- `false`: restores 3.x silent behavior (only throws when `showErrorInformation=true`).

## Test plan

Tests extend `vendor/wheels/tests/specs/view/viteSpec.cfc`. Fixtures are inline manifest structs with three-level import trees.

### Fixture — transitive imports manifest

```cfm
{
  "src/main.js": {
    file: "assets/main-ABC.js",
    isEntry: true,
    imports: ["_chunk-SHARED-XYZ.js"],
    css: ["assets/main-MAIN.css"]
  },
  "_chunk-SHARED-XYZ.js": {
    file: "assets/chunk-SHARED-XYZ.js",
    imports: ["_chunk-VENDOR-DEF.js"],
    css: ["assets/chunk-SHARED.css"]
  },
  "_chunk-VENDOR-DEF.js": {
    file: "assets/chunk-VENDOR-DEF.js",
    imports: [],
    css: ["assets/chunk-VENDOR.css"]
  }
}
```

### New tests

**`$viteResolveAssets` (new describe block):**
1. Returns scripts=[entry.file], styles=[entry.css], preloads=[] for a leaf entry.
2. Returns preloads with all transitive chunks for a nested imports tree.
3. Dedupes when two chunks import the same third chunk (diamond dependency).
4. Does not infinite-loop on a cyclic imports graph.
5. Aggregates CSS from entry + all transitive chunks.
6. Honors strict mode: throws `Wheels.ViteAssetNotFound` when entry missing and `viteStrictManifest=true`.
7. Non-strict mode returns empty resolved set when entry missing and `showErrorInformation=false`.

**`viteScriptTag` additive:**
8. Emits `<link rel="modulepreload">` for each transitive chunk (verify via `$htmlhead`-captured output; Lucee/Adobe need a test shim since `cfhtmlhead` is not easy to inspect — alternative: verify by checking the helper's side effect through a test-only capture).
9. Emits stylesheet links for transitive chunk CSS (verify inline output contains each chunk CSS file).

**`viteStyleTag` additive:**
10. Emits stylesheet links for transitive chunk CSS.

**`vitePreloadTag` (new describe block):**
11. Returns empty string in dev mode.
12. Emits modulepreload for entry.file in prod mode with `head=false`.
13. Emits modulepreload for each transitive chunk in addition to entry.
14. With `head=true` (default), emits via `$htmlhead()` and returns empty.
15. Throws on missing entry under strict mode.

**Strict-mode behavior (existing helpers):**
16. `viteAsset` throws on missing entry when `viteStrictManifest=true`, regardless of `showErrorInformation`.
17. `viteAsset` returns entrypoint silently when `viteStrictManifest=false` and `showErrorInformation=false` (3.x behavior).

### `$htmlhead` testing shim

`$htmlhead()` is CFML's mechanism for injecting HTML into `<head>`. Testing it across engines is awkward. Two options:

- **Option A (preferred):** add a test-scope `$viteHtmlHead(text)` pass-through that `viteScriptTag`/`vitePreloadTag` call. Tests can stub this via a shared struct. No shim in production behavior; just an extraction for testability.
- **Option B:** inspect side-effects through a Lucee/Adobe engine-specific mechanism. Fragile, engine-coupled.

Go with A.

### Cross-engine verification

Run the full spec file under:
- Lucee 7 + SQLite (local, via `bash tools/test-local.sh view`)
- Lucee 6 + SQLite (Docker: `docker compose up -d lucee6 && curl ...`)
- Adobe CF 2025 + SQLite (Docker: `docker compose up -d adobe2025 && curl ...`)

Spot-check on BoxLang if CI catches it. No new engine-specific code is introduced, so the risk surface is low.

## Out of scope (deliberately deferred)

- **SRI (Subresource Integrity) hashes.** Not shipped in Vite's default manifest; requires a build plugin or post-build hash computation. Approach D leaves a seam (`$viteResolveAssets()`) where a future `integrity` field on each resolved asset can plug in.
- **CSP nonce integration.** Similar — leave the seam; separate spec.
- **Legacy-bundle fallback (`viteLegacyScriptTag`).** Adds another helper; not required for modern browsers which are the Wheels 4.x baseline.
- **Vue/React-specific refresh helpers (`viteReactRefresh`).** Framework-specific; lives in per-framework wheels packages if needed.

## Rollout

1. Land changes on `develop` behind the new `viteStrictManifest=true` default.
2. Upgrade guide (`docs/src/introduction/upgrading-to-4.0.md`) adds a note: "If a previously-silent missing Vite entrypoint now throws, either fix the missing entry (recommended) or `set(viteStrictManifest=false)`."
3. CHANGELOG entry under `[Unreleased]`:
   - **Added:** `vitePreloadTag()` helper; transitive modulepreload and CSS resolution in `viteScriptTag()`/`viteStyleTag()`; `viteStrictManifest` setting.
   - **Changed:** `viteStrictManifest` default `true` — missing manifest entries now throw `Wheels.ViteAssetNotFound` in production.
4. `wheels-vs-frameworks.md` "Where Wheels Trails" update: asset-pipeline maturity row loses the "trailing" asterisk.

## Unresolved questions

- **`viteHmrPreload()` / hover-preload integration.** Worth shipping a view helper that emits `<link data-turbo-track="reload" rel="preload" as="fetch">`? — deferred to Turbo integration PR.
- **Manifest fingerprint for cache-busting.** Consider reading manifest mtime as an application-scope cache key so reloads after a new `vite build` auto-clear the cache. — low priority; `?reload=true` already covers it.
