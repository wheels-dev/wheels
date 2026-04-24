# wheels-packages Phase 4 — Discovery UI

**Status:** in progress — wheels.dev portion deferred (see "Revision" below)
**Date:** 2026-04-23
**Issue:** [#2271](https://github.com/wheels-dev/wheels/issues/2271) (Phase 4 of [#2243](https://github.com/wheels-dev/wheels/issues/2243))
**Depends on:** [#2233](https://github.com/wheels-dev/wheels/issues/2233) (production gating, already closed)

## Revision — 2026-04-23

Initial draft assumed `wheels.dev` was a live CFML app (legacy `wheels-dev/wheels.dev` repo). It is not. The site was migrated to four Astro static sites in this repo under `web/sites/{landing,guides,api,blog}/`, deployed to Cloudflare Pages via `.github/workflows/web-deploy.yml`.

**Scope split:**
- **In-app surface (Component 1)** — ships first, captured in full by this spec and the companion plan at `docs/superpowers/plans/2026-04-23-wheels-packages-phase4-inapp.md`.
- **wheels.dev surface (Components 2 + 3)** — **deferred**. Will be redesigned against the Astro architecture in a follow-up spec before implementation. The CFML `RegistryClient` + `PackagesController` described below are superseded and should be treated as historical context only. The replacement approach will be build-time data fetching in Astro frontmatter (`getStaticPaths()`), with a `repository_dispatch` trigger from `wheels-dev/wheels-packages` → this repo's `web-deploy.yml` so manifest merges rebuild the landing site automatically.

Issue #2271 will not close on the in-app PR. It stays open to track the deferred wheels.dev work.

## Summary

Ship the discovery UI for the `wheels-packages` ecosystem on two surfaces:

1. **`wheels.dev/packages`** — public listing + detail pages (Astro static site, deferred — see Revision above).
2. **`/wheels/packages`** — in-app developer page, already shows *installed* packages; Phase 4 adds a **"Browse registry"** section so developers can discover installable packages without leaving their app.

Both surfaces read the same GitHub-hosted registry (`wheels-dev/wheels-packages`). The in-app surface reuses the CLI's `Registry.cfc` with a 24-hour app-scope cache. There is no install-via-browser action; installation remains a CLI operation (`wheels packages install <name>`).

## Current state (pre-Phase-4)

| Surface | Status |
|---|---|
| `wheels-dev/wheels-packages` registry | ✅ Live. 4 packages: sentry, hotwire, basecoat, legacy-adapter. Manifests + mirrored tarballs as GH Release assets. |
| `cli/lucli/services/packages/Registry.cfc` | ✅ Live. GH contents API + raw.githubusercontent.com, 24h file-based cache, env-var override (`WHEELS_PACKAGES_REGISTRY`). |
| `vendor/wheels/Public.cfc` → `packagelist()` / `packageentry()` | ✅ Wired. `$blockInProduction()` gate applied (per #2233). |
| `vendor/wheels/public/views/packagelist.cfm` + `packageentry.cfm` | ✅ Show **installed** packages from `application.wheels.packageMeta`. Gated by `enablePackagesComponent`. |
| `wheels.dev/packages` + detail page | ❌ No controller, no views, no routes. |
| Registry "browse" section on in-app page | ❌ Not implemented. |

## Design decisions

### D1. Data architecture — separate fetchers, same endpoints (Option A)

Each surface runs its own registry client pointed at the same GitHub endpoints:

- **CLI**: existing `cli.lucli.services.packages.Registry` — file-based 24h cache under `~/.wheels/cache/packages/`.
- **In-app `/wheels/packages`**: reuses the **CLI's** `Registry.cfc` directly (it's on the classpath of every Wheels app). Cached in `application.wheels.$packageRegistry` (app-scope memo).
- **wheels.dev**: new `app/models/services/RegistryClient.cfc` — sibling implementation, application-scope cache, same endpoints, same TTL.

Rejected alternatives:
- **Aggregated `index.json`** committed by CI — adds a CI job for minimal benefit at 4 packages.
- **Shared client component** across CLI and wheels.dev — premature DRY; the wheels.dev app lives in a separate repo and can't cleanly consume a CLI-bundled component without introducing a dependency edge that doesn't exist today.

### D2. In-app page — "dual view" (Option B)

Keep the existing installed-packages table. Add a **"Browse registry"** section below it:

- Per-package row: name (→ `https://wheels.dev/packages/<name>`), description, tags, latest version, copy-to-clipboard `wheels packages install <name>` snippet.
- Rows where the package is already installed render a muted `✓ Installed` badge instead of the install snippet.
- No install button. CLI is the only install path (security + simplicity).

Rejected alternatives:
- **Installed-only** (link out to wheels.dev for discovery): misses the value of in-context browsing while coding.
- **Full parity with wheels.dev/packages in-app**: duplicates UI without adding functionality, since you still can't install via HTTP.

### D3. wheels.dev detail content — enriched with README (Option 3b-ii)

The detail page (`/packages/[name]`) renders:
- Header: name, latest version, homepage link, tags
- Copy-to-clipboard install snippets (latest + version-pinned)
- Version history table
- Rendered README (Markdown → HTML via existing `markdownToHtml()` helper)

No per-version deep-link URLs in Phase 4. Added later only if demand materializes.

## Architecture

```
                      wheels-dev/wheels-packages (GitHub)
                       ├─ GH contents API: /packages dir listing
                       └─ raw.githubusercontent.com: manifests + READMEs
                                    │
                   ┌────────────────┴────────────────┐
                   │                                 │
          ┌────────▼────────┐               ┌────────▼────────┐
          │  CLI Registry   │               │ wheels.dev      │
          │  (existing)     │               │ RegistryClient  │
          │  24h file cache │               │ 24h app-scope   │
          └─────────────────┘               │ cache           │
                                            └────────┬────────┘
                                                     │
                                    ┌────────────────┴──────────────┐
                                    │                               │
                             PackagesController             /wheels/packages
                             /packages (index)              (Public.cfc
                             /packages/[name] (show)        packagelist())
                                                            adds "Browse
                                                            registry" section
```

## Components to build

### Component 1 — wheels repo: in-app registry lookup

**Files touched:**
- `vendor/wheels/public/views/packagelist.cfm` — extend with "Browse registry" section
- `vendor/wheels/global/packages.cfm` — **new** file. Adds `$getRegistryClient()` helper. Keeping it in its own file (rather than appending to `events/functions.cfm`) isolates the new dependency on `cli.lucli.services.packages.Registry` and makes the helper trivial to remove if the package system is ever unbundled from core.

**New helper (pseudocode):**
```cfml
public any function $getRegistryClient() {
    if (!StructKeyExists(application.wheels, "$packageRegistry")) {
        application.wheels.$packageRegistry =
            new cli.lucli.services.packages.Registry();
    }
    return application.wheels.$packageRegistry;
}
```

**View additions (above existing guard, with env-gate):**
```cfml
local.registryPackages = [];
local.registryError = "";
local.registryStale = false;
if (application.wheels.environment != "production") {
    try {
        local.reg = $getRegistryClient();
        local.registryPackages = local.reg.listAll();
        local.registryStale = local.reg.isStale();
    } catch (Wheels.Packages.RegistryUnavailable e) {
        local.registryError = e.message;
    } catch (any e) {
        local.registryError = "Registry lookup failed: " & e.message;
    }
}
```

**Registry.cfc additions required:**
- `public array function listAll()` — returns `[{name, description, tags, latestVersion, homepage}, ...]`. Reuses existing `listPackageNames()` + per-package `fetchManifest()` internally.
- `public boolean function isStale()` — true if last fetch was served from cache after an upstream failure.

If `listAll()` does not yet exist on `Registry.cfc`, add it. Keep the shape symmetrical with the new wheels.dev `RegistryClient`.

### Component 2 — wheels.dev: RegistryClient service [DEFERRED — see Revision]

**File:** `app/models/services/RegistryClient.cfc` (~100 lines).

**Responsibilities:**
- Fetch `/packages` directory listing from `https://api.github.com/repos/{repo}/contents/packages?ref={branch}`
- Fetch per-package manifest from `https://raw.githubusercontent.com/{repo}/{branch}/packages/{name}/manifest.json`
- Fetch per-package README from `https://raw.githubusercontent.com/{repo}/{branch}/packages/{name}/README.md`
- Cache all three in `application` scope with 24h TTL
- Env-var override: `WHEELS_PACKAGES_REGISTRY` (default `wheels-dev/wheels-packages`)
- Stale-on-error: if GitHub returns 5xx/403, serve cached value and flag `stale=true`

**Constructor signature (testable):**
```cfml
RegistryClient init(
    any httpClient = "",     // wrapper; defaults to cfhttp-based impl
    string registryRepo = "",
    string branch = "main"
)
```

**Registration** in `config/services.cfm`:
```cfml
di.map("registryClient").to("app.models.services.RegistryClient").asSingleton();
```

### Component 3 — wheels.dev: PackagesController + views + routes [DEFERRED — see Revision]

**Controller:** `app/controllers/web/PackagesController.cfc`

```cfml
component extends="web.Controller" {
    function config() {
        filters(through = "loadRegistry");
    }

    private function loadRegistry() {
        registry = service("registryClient");
    }

    function index() {
        packages = registry.listAll();
        q = params.q ?: "";
        if (Len(q)) packages = $filterByQuery(packages, q);
        // $filterByQuery: case-insensitive substring match against name,
        // description, and tags. Controller-private helper, trivial impl.
        registryStale = registry.isStale();
    }

    function show() {
        pkg = registry.getPackage(params.name);
        if (!StructKeyExists(pkg, "name")) {
            redirectTo(controller="errorController", action="error404");
            return;
        }
        readmeHtml = markdownToHtml(registry.getReadme(params.name));
        registryStale = registry.isStale();
    }
}
```

**Routes** (insert in `config/routes.cfm` above the `.namespace("admin")` block, after existing `.get(name="api_docs", ...)`):
```cfml
.get(name = "packages", pattern = "packages", to = "web.PackagesController##index")
.get(name = "package-detail", pattern = "packages/[name]", to = "web.PackagesController##show")
```

**Admin refresh endpoint** (inside existing `admin` namespace):
```cfml
.post(name = "packages-refresh", pattern = "packages/refresh", to = "PackagesController##refresh")
```
(The admin `PackagesController` lives under `app/controllers/admin/PackagesController.cfc` and calls `registry.flushCache()`.)

**Views:**
- `app/views/web/PackagesController/index.cfm` — listing. Top bar: `searchField(name="q")`. Table columns: name (→ detail link), description, tags (chips), latest version. Stale/error banner when applicable.
- `app/views/web/PackagesController/show.cfm` — header, install snippet (copy-to-clipboard), version history table, rendered README below.

**Install snippet template** (inline JS for copy button, identical pattern across both surfaces):
```html
<pre><code id="install-#name#">wheels packages install #name#</code>
  <button onclick="navigator.clipboard.writeText(document.getElementById('install-#name#').innerText)">Copy</button>
</pre>
```

Package name is constrained to `^[a-z0-9][a-z0-9-]*$` by `manifest.schema.json`, and is additionally HTML-escaped during render.

## Error handling

| Condition | Behavior |
|---|---|
| GitHub 200 | Serve + cache for 24h |
| GitHub 403 (rate-limit) / 5xx, cache present | Serve cached, `isStale=true`, show warning banner |
| GitHub 403 / 5xx, cache empty | Show "Registry temporarily unavailable" card; no 500 to user |
| Malformed manifest JSON | Skip that package, log warning, others render normally |
| Package not in registry (detail page) | 404 via `errorController.error404` |

## Security

- Only the hardcoded registry repo is contacted by `cfhttp`. Env-var override allows different repos (for forks/mirrors/tests) but the value is a repo slug, never a full URL.
- README rendering uses the existing `markdownToHtml()` helper. During impl, verify the sanitizer strips `<script>` and `on*=` attributes; reuse whatever the blog/guide views already do.
- Copy-to-clipboard snippet: package name is the only variable and is pattern-constrained by the registry schema. HTML-escape on render anyway.
- In-app registry lookup is gated by both `$blockInProduction()` (handler level) and a view-level `environment != "production"` check (defense in depth).

## Testing

### wheels.dev
- `tests/specs/services/RegistryClientSpec.cfc` — BDD, uses `FakeHttpClient` fixture. Covers: list success, manifest success, README success, 5xx → stale-cache fallback, 403 → stale-cache fallback, cache TTL respected, hardcoded repo default, env-var override, malformed JSON skipped.
- `tests/specs/controllers/PackagesControllerSpec.cfc` — routes resolve, 404 on unknown package, README renders in show view, install snippet present, search query filters list.
- No live-network tests.

### wheels (in-app)
- `vendor/wheels/tests/specs/packages/PackageListViewSpec.cfc` — asserts "Browse registry" section renders in dev; does NOT render when `environment = production`; shows cached data when registry throws; renders `✓ Installed` badge when a registry name matches `packageMeta`.
- Existing `PackagesRegistryCliSpec.cfc` / `PackagesMainCliSpec.cfc` continue to cover the `Registry.cfc` fetch/cache path — no duplication needed.

### Manual verification (before PR)
- `wheels.dev/packages` renders all 4 packages against live registry
- `/packages/wheels-sentry` renders README + version history + install snippet
- `/wheels/packages` in a dev Wheels app shows "Browse registry" section below installed list
- Set `environment = production` in a test harness → confirm in-app registry section does not render (and Public.cfc handler already 404s)
- `WHEELS_PACKAGES_REGISTRY=bpamiri/test-registry` → both surfaces honor the override

## Build sequence

Each item is independently shippable:

1. **wheels repo — in-app "Browse registry"** (PR against `develop`)
   - Add `$getRegistryClient()` helper + `listAll()` / `isStale()` on `Registry.cfc`
   - Extend `packagelist.cfm` with new section
   - Spec coverage for env gating + installed-badge collision

2. **wheels.dev repo — RegistryClient + PackagesController** (single PR — service without a caller is noise)
   - `RegistryClient.cfc` + `FakeHttpClient` fixture
   - DI registration in `config/services.cfm`
   - Controller (public + admin refresh), 2 views, 2+1 route entries
   - Spec coverage: service fetch/cache/stale/override, controller routes + 404 path

Steps 1 and 2 are independent (different repos) and can land in either order.

## Out of scope (explicit YAGNI)

- Admin UI for managing packages (add/approve/reject). PRs to the registry repo remain the contribution path.
- Download counts, stars, "popular this week" metrics.
- Per-version deep-link URLs (`/packages/[name]/[version]`). Added later on demand.
- Dependency graph visualization.
- Server-side search index. Client-side filter is fine for 4–40 packages.
- RSS/Atom feed for new versions.
- Install-via-browser action. CLI-only by design.
- Unified `index.json` aggregation across the registry. Each surface fetches its own data.

## Open items (non-blocking, resolve during impl)

- Confirm which Markdown sanitizer the wheels.dev blog/guide views use; reuse for `/packages/[name]`.
- Confirm admin auth filter pattern for the cache-refresh endpoint; match existing `AdminController` behavior.
