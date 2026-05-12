# Implementation Plan — Vite Pipeline Maturity (Approach D)

**Date:** 2026-04-16
**Spec:** [2026-04-16-vite-pipeline-maturity-design.md](../specs/2026-04-16-vite-pipeline-maturity-design.md)
**Branch:** `peter/vite-pipeline-maturity`
**Commit prefix:** `feat(view):` (for the main change) and `test(view):` / `docs:` as appropriate.

## Approach

Test-Driven Development throughout. Write a failing test first, implement the minimum change to pass, refactor if needed. Run the full `view` test subset after each step; run the full core suite before pushing.

## Files touched

1. `vendor/wheels/view/vite.cfc` — main implementation: add `$viteResolveAssets`, `$viteMissingEntry`, `$viteHtmlHead`, `vitePreloadTag`; update `viteScriptTag`, `viteStyleTag`, `viteAsset` to call the resolver and respect strict mode.
2. `vendor/wheels/events/init/views.cfm` — register `viteStrictManifest = true` default.
3. `vendor/wheels/tests/specs/view/viteSpec.cfc` — new describe blocks for `$viteResolveAssets`, `vitePreloadTag`, strict mode; additive assertions for `viteScriptTag`/`viteStyleTag`.
4. `CHANGELOG.md` — Added + Changed entries under `[Unreleased]`.
5. `docs/src/introduction/upgrading-to-4.0.md` — short callout about the strict-manifest default and how to opt out.

## Steps

### Step 1 — Register the `viteStrictManifest` setting

**Why first:** other code will read this via `$get("viteStrictManifest")`; having it registered from the start avoids false failures.

- Edit `vendor/wheels/events/init/views.cfm`: add `application.$wheels.viteStrictManifest = true;` in the Vite block.
- Edit `vendor/wheels/tests/specs/view/viteSpec.cfc` `beforeAll`: add `viteStrictManifest = true` to the defaults struct.
- No new tests yet — this is scaffolding.

### Step 2 — TDD `$viteMissingEntry`

- Add a failing test: `viteAsset` throws `Wheels.ViteAssetNotFound` when entry missing AND `viteStrictManifest=true` AND `showErrorInformation=false` (this is the 3.x quiet case that's now loud).
- Implement `$viteMissingEntry(entrypoint)` that reads both flags and throws when `strict OR showErr`.
- Refactor `viteAsset`, `viteScriptTag`, `viteStyleTag` to call `$viteMissingEntry` instead of inlining the `showErrorInformation` check. All three currently have the same 5-line block; DRY it up in this step.
- Add a test for non-strict silent behavior: `viteAsset` with `viteStrictManifest=false` and `showErrorInformation=false` returns the entrypoint string unchanged.

### Step 3 — TDD `$viteResolveAssets` — leaf entry

- Add a failing test: resolver returns `{scripts: [entry.file], styles: [entry.css...], preloads: []}` for an entry with no imports.
- Implement the happy path: read the entry, seed `scripts`/`styles`, return with `preloads=[]`.
- Note: this is the "leaf" case; no tree walking yet.

### Step 4 — TDD `$viteResolveAssets` — transitive imports

- Add a failing test with the three-level fixture from the spec: `main.js` → `_chunk-SHARED` → `_chunk-VENDOR`. Expect preloads `["assets/chunk-SHARED.js", "assets/chunk-VENDOR.js"]` (order: depth-first) and styles including all three CSS files.
- Implement the recursive walker with a visited set. Use a `local.visited` struct keyed by chunk key.
- Add a diamond-dependency test: two chunks both import the same third chunk. Verify no duplicate in `preloads`.
- Add a cycle test: A → B → A. Verify termination and both chunks appear exactly once.

### Step 5 — TDD `$viteResolveAssets` — missing-entry gate

- Add a failing test: `$viteResolveAssets("src/missing.js")` throws under strict mode.
- Add a test: under non-strict mode, returns `{scripts: [], styles: [], preloads: []}`.
- The resolver's first line calls `$viteMissingEntry(entrypoint)`; non-strict path returns the empty shape.

### Step 6 — Refactor `viteScriptTag` to use the resolver

- Add a failing test: `viteScriptTag` output includes `<link rel="modulepreload">` for each transitive chunk.
- Add the `$viteHtmlHead(text)` pass-through helper and a test-stubbable capture (for tests, check the output via a test-only buffer or a stubbed function).
- Refactor `viteScriptTag`:
  - In prod mode, call `$viteResolveAssets()`.
  - Emit each `styles[]` as `<link rel="stylesheet">` — this already gains transitive CSS.
  - Emit `scripts[0]` as `<script type="module">`.
  - Emit each `preloads[]` as `<link rel="modulepreload">` via `$viteHtmlHead()` (always to `<head>`, regardless of the `head` arg).
- Verify existing tests still pass.

### Step 7 — Refactor `viteStyleTag` to use the resolver

- Add a failing test: `viteStyleTag` emits stylesheet links for transitive chunk CSS.
- Refactor: call `$viteResolveAssets()`, emit one `<link rel="stylesheet">` per entry in `styles[]`.
- Existing "single entry CSS" test should still pass since the resolver's `styles[]` starts with the entry's own `file`.

### Step 8 — Add `vitePreloadTag`

- Add failing tests:
  - Returns empty string in dev mode.
  - With `head=false`, returns `<link rel="modulepreload">` for entry.file AND each preload.
  - With `head=true` (default), emits via `$viteHtmlHead()` and returns empty.
  - Throws under strict mode when entry missing.
- Implement `vitePreloadTag(entrypoint, head=true)`:
  - Dev mode: return "".
  - Prod mode: call `$viteResolveAssets()`. Build markup with the entry's file first, then each preload. Emit via `$viteHtmlHead()` if `head`, else return.

### Step 9 — Docstrings and CHANGELOG

- Ensure every new/changed public function has a CFDoc comment following the existing `[section: View Helpers]` / `[category: Asset Functions]` convention.
- Update `CHANGELOG.md` `[Unreleased]`:
  - **Added:** `vitePreloadTag()` view helper for emitting `<link rel="modulepreload">` tags, useful for Turbo Drive hover-preload patterns. Transitive modulepreload and CSS resolution in `viteScriptTag()` and `viteStyleTag()` via a new internal `$viteResolveAssets()` resolver.
  - **Added:** `viteStrictManifest` setting (default `true`) — missing manifest entries now throw `Wheels.ViteAssetNotFound` in production. Set to `false` to restore 3.x silent behavior.
- Add a short callout to `docs/src/introduction/upgrading-to-4.0.md` under a "Vite asset pipeline" heading: strict-manifest default, with the opt-out.

### Step 10 — Local verification

- `bash tools/test-local.sh view` — all view tests green on Lucee 7 + SQLite.
- `bash tools/test-local.sh` — full core suite green.
- Spot-check under Lucee 6 via Docker (see CLAUDE.md "Running Tests Locally (Docker — Legacy)").
- Spot-check under Adobe CF 2025 via Docker.

### Step 11 — Commit & PR

- Commit structure:
  - `feat(view): add $viteResolveAssets resolver and strict manifest default` (step 1 + 2 + 3-5 + 7 core)
  - `feat(view): add vitePreloadTag helper and modulepreload in viteScriptTag` (step 6 + 8)
  - `test(view): cover transitive imports tree and strict manifest` (step 4 diamond/cycle test if not bundled above)
  - `docs: document vite strict manifest and preload helper` (step 9 doc parts)

  In practice, bundling into 1–2 commits is fine if the test-per-feature discipline is preserved in the work itself — reviewers care about the implementation being correct, not the commit count. Target 2 commits: one `feat(view)` with the full implementation + tests, one `docs:` with CHANGELOG + upgrade-guide callout.

- PR: base `develop`, title `feat(view): transitive modulepreload and css resolution for vite pipeline`.
- PR body links the spec and the plan, summarizes the three user-visible changes (transitive modulepreload, transitive CSS, strict manifest default, new helper), and calls out the opt-out path.

## Risk / blast radius

- **Behavior change for apps with a missing manifest entry in prod.** Previously silent; now throws under default strict mode. Mitigated by the explicit upgrade-guide callout and the `viteStrictManifest=false` opt-out.
- **Additional `<link rel="modulepreload">` tags in `<head>`.** Browsers that don't support modulepreload ignore the rel; no backward-compat risk. Byte overhead is small (one link tag per chunk).
- **`$htmlhead` calls inside `viteScriptTag` regardless of the `head` arg.** This is a new side effect — `viteScriptTag("main.js", head=false)` used to emit only inline markup; now it also emits modulepreload links via `$htmlhead`. This is correct behavior (preloads must be in `<head>`), and the modulepreload links are the only side effect. Call out in the CHANGELOG.

## Rollback

The change is contained to one CFC, one init file, and one test spec. Revert commit, redeploy — fully reversible.

## Unresolved questions

- Should `viteScriptTag(head=false)` still push modulepreload into `<head>` unconditionally? (Spec says yes; preloads in `<body>` are useless.) Confirmed yes during design — document prominently.
