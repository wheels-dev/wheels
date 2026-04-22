# Issue #2135: Internal routes present in application-level files

## Verdict
FIX NOW

## Summary
Browser-test fixture routes, controllers, and views are living in app-level files (`config/routes.cfm`, `app/controllers/BrowserTest*.cfc`, `app/views/browsertest*/`) in the wheels repo. These are framework-internal test infrastructure and should not appear in an app's editable surface. A developer who scaffolds from this repo (or reads it as reference) sees `/_browser/*` routes they did not write and cannot cleanly own.

## Root cause
Browser tests (PR #2116, "browser testing foundation") need to drive a real HTTP server, and CFML routes/controllers/views are resolved from `app/` + `config/` at runtime — not from `vendor/wheels/tests/_assets/`. So fixtures were dropped into the dogfood app alongside the framework source to make browser specs work. That was expedient but leaks framework-internal surface into every developer's app layer.

Specifically:

- `config/routes.cfm:10-18` — `/_browser` scope with six routes (`browserTestHome`, `browserTestLogin`, `browserTestAuthenticate`, `browserTestDashboard`, `browserTestLogout`, `browserTestLoginAs`).
- `app/controllers/BrowserTestHome.cfc`, `app/controllers/BrowserTestLogin.cfc`, `app/controllers/BrowserTestSessions.cfc` — fixture controllers (duplicates of `vendor/wheels/tests/_assets/controllers/BrowserTest*.cfc`).
- `app/views/browsertesthome/`, `app/views/browsertestlogin/`, `app/views/browsertestsessions/` — fixture views (duplicates of `vendor/wheels/tests/_assets/views/browsertest*/`).

Confirmation this is framework-internal and not app-intended:

- The CLI scaffold template (`cli/lucli/templates/app/config/routes.cfm`) is CLEAN — no `_browser` scope. So `wheels new` ships correct routes, but the wheels repo itself is broken.
- The `BrowserTest.cfc` base class already re-includes `/wheels/tests/routes.cfm` in `beforeAll` (`vendor/wheels/wheelstest/BrowserTest.cfc:69`) — so the framework already knows how to mount these routes from within `vendor/` — the app copy is unnecessary when tests run via `TestRunner.cfc`.
- The framework's internal route loader (`vendor/wheels/Global.cfc:1250-1254` — `$lockedLoadRoutes()`) auto-includes `/wheels/public/routes.cfm` BEFORE `/config/routes.cfm`. That established pattern is exactly how `/wheels/info`, `/wheels/mcp`, `/wheels/app/tests` etc. stay out of `config/routes.cfm`. Browser fixtures should ride the same rail.
- The `loginAs` controller (`app/controllers/BrowserTestLogin.cfc:7-12`) already has an environment gate (`testing`/`development`), proving these were always intended as test-only fixtures.
- A `TODO: skip this if mode != development|testing?` comment already exists at `Global.cfc:1251` for the framework GUI route include — same gating question applies here.

Why the app copies exist at all (without them, browser specs that hit `http://localhost:8080/_browser/home` via a real Chromium would 404): browser tests fire **real HTTP** at the running dev server. That server uses `config/routes.cfm` + `app/controllers/` — not the test-asset swap that `TestRunner.cfc` sets up. So simply deleting the app copies breaks browser tests. The fix must both remove the app-level copies AND give the framework a way to auto-mount the fixtures under `testing`/`development`.

## Files to change

### Framework (add internal fixture routes, move fixture code into framework)

- **New: `vendor/wheels/public/browser-fixtures.cfm`** — new mapper include holding the `/_browser` scope (copy of lines 10-18 of current `config/routes.cfm`). Named routes stay identical (`browserTestHome`, `browserTestLogin`, `browserTestAuthenticate`, `browserTestDashboard`, `browserTestLogout`, `browserTestLoginAs`) so existing specs that use `visitRoute(route="browserTestLogin")` keep working.

- **Edit: `vendor/wheels/Global.cfc` around line 1250-1254 (`$lockedLoadRoutes`)** — after the existing `$include("/wheels/public/routes.cfm")` and before `$include("/config/routes.cfm")`, conditionally include the browser fixture routes when `application.wheels.environment` is `testing` or `development` AND a new opt-in setting (e.g., `application.wheels.loadBrowserTestFixtures`) is true. Default that setting to false in production, true for the wheels dogfood app via `config/settings.cfm`.

- **Move: `app/controllers/BrowserTestHome.cfc` → `vendor/wheels/public/browser-fixtures/controllers/BrowserTestHome.cfc`** (and `BrowserTestLogin.cfc`, `BrowserTestSessions.cfc`). Delete from `app/controllers/`.

- **Move: `app/views/browsertesthome/` → `vendor/wheels/public/browser-fixtures/views/browsertesthome/`** (and `browsertestlogin/`, `browsertestsessions/`). Delete from `app/views/`.

- **Edit `vendor/wheels/Global.cfc` (or a helper) once more** — when fixture routes are active, append the fixture controller + view paths to Wheels' controller/view resolution search path (similar to how `TestRunner.cfc` swaps `controllerPath`/`viewPath`). Alternative: keep `controllerPath`/`viewPath` alone and instead use `controller="wheels.public.browser-fixtures.BrowserTestHome"` style dotted paths in the new `browser-fixtures.cfm` mapper so the routes dispatch into `vendor/` directly without needing a search-path change. Prefer the second approach — it's a smaller, localized change that mirrors how `wheels##public##tests` works today at `vendor/wheels/public/routes.cfm:40`.

### App (clean up)

- **Edit: `config/routes.cfm`** — remove lines 10-18 (the `/_browser` scope block). Keep `.wildcard()` and `.root()`.

- **Edit: `config/settings.cfm`** — add `set(loadBrowserTestFixtures=true);` so the dogfood app still mounts fixtures for its own browser specs. (Or document that `environment=testing` alone is enough; see open question.)

- **Delete: `app/controllers/BrowserTestHome.cfc`, `BrowserTestLogin.cfc`, `BrowserTestSessions.cfc`** (moved to `vendor/`).

- **Delete: `app/views/browsertesthome/`, `app/views/browsertestlogin/`, `app/views/browsertestsessions/`** (moved to `vendor/`).

### Tests (keep functional paths)

- `vendor/wheels/tests/routes.cfm` — can be trimmed: the `/_browser` scope block (lines 12-19) becomes redundant if `$lockedLoadRoutes` mounts fixtures on testing/development. Leave for now if the include path runs before environment is fully set; revisit in a follow-up.

- `vendor/wheels/wheelstest/BrowserTest.cfc:69` — the `application.wo.$include(template="/wheels/tests/routes.cfm")` re-include stays as-is (guards against specs that `$clearRoutes()`).

- `vendor/wheels/tests/_assets/controllers/BrowserTest*.cfc` and `vendor/wheels/tests/_assets/views/browsertest*/` — keep as-is. These serve the `TestRunner.cfc` path-swap flow. The new `vendor/wheels/public/browser-fixtures/` copies serve the real-HTTP browser flow. (Follow-up: de-dupe by having `_assets` symlink or re-export from `public/browser-fixtures/`.)

## Implementation steps

1. Create `vendor/wheels/public/browser-fixtures/controllers/` and move `app/controllers/BrowserTestHome.cfc`, `BrowserTestLogin.cfc`, `BrowserTestSessions.cfc` there. Verify the three files are byte-identical to `vendor/wheels/tests/_assets/controllers/BrowserTest*.cfc` before moving — if not, reconcile and use the app version (it's what browser specs were hitting).
2. Create `vendor/wheels/public/browser-fixtures/views/` and move `app/views/browsertesthome/`, `app/views/browsertestlogin/`, `app/views/browsertestsessions/` there. Same byte-identical check against `vendor/wheels/tests/_assets/views/`.
3. Create `vendor/wheels/public/browser-fixtures.cfm` with a `mapper()` block that registers the six `/_browser` routes, using fully-qualified controllers (e.g. `to="wheels##public##browser-fixtures##BrowserTestHome##index"` or whatever the dotted-lookup form is; confirm against how `wheels##public##tests` resolves at `vendor/wheels/public/routes.cfm:40`).
4. Add a setting `loadBrowserTestFixtures` (default false) in `vendor/wheels/global/Internal.cfc` or wherever framework defaults live; document under `config/settings.cfm` patterns.
5. Edit `vendor/wheels/Global.cfc::$lockedLoadRoutes` — between lines 1252 and 1254, add:
   ```cfml
   if (application.wheels.loadBrowserTestFixtures && ListFindNoCase("testing,development", application.wheels.environment)) {
       $include(template = "/wheels/public/browser-fixtures.cfm");
   }
   ```
6. Delete the `/_browser` scope block (lines 10-18) from `config/routes.cfm`.
7. Delete the now-migrated `app/controllers/BrowserTest*.cfc` and `app/views/browsertest*/` directories.
8. Add `set(loadBrowserTestFixtures=true);` to `config/settings.cfm` so the dogfood app's browser specs still work.
9. Run the browser test spec suite (`BrowserLoginSpec`, `BrowserRouteSpec`, `BrowserDialogSpec`, `BrowserTestLifecycleSpec`) — verify all green.
10. Run full test suite via `bash tools/test-local.sh` — verify no regressions.
11. Run `wheels routes` / `wheels_routes()` MCP — verify `/_browser/*` shows up under "Internal" bucket (needs a small patch to `vendor/wheels/public/views/routes.cfm:11-17` so the internal-route detector treats `wheels.public.browser-fixtures.*` as internal too).
12. Verify `wheels new testapp` still produces a clean `config/routes.cfm` with no browser-test pollution. (Should already be the case — CLI template is clean — but confirm.)

## Testing

- **Browser specs green**: `bash tools/test-local.sh browser` (or targeted: run `BrowserLoginSpec`, `BrowserRouteSpec`, `BrowserDialogSpec`, `BrowserTestLifecycleSpec`). `loginAs`, `logout`, `/_browser/dashboard` redirects, etc. must all still pass.
- **Core suite green**: `bash tools/test-local.sh` against Lucee 6 and Adobe 2025 at minimum (cross-engine rule from CLAUDE.md).
- **Fresh app check**: `cd /tmp && wheels new test-app-2135 && cat test-app-2135/config/routes.cfm` — assert no `/_browser` scope is present.
- **Routes inspector**: Start the dogfood app, hit `/wheels/routes`, confirm the six `_browser` routes appear in the "Internal" tab and NOT the "App" tab. Also run `wheels_routes()` MCP tool — same assertion.
- **Production safety**: Set `environment=production` in `config/settings.cfm` and `$loadRoutes()` — verify the fixtures do NOT get registered (hit `/_browser/home` — should 404).
- **Opt-out**: Default `loadBrowserTestFixtures=false` means even `environment=development` doesn't mount them unless the dogfood app explicitly opts in. Verify by temporarily commenting `set(loadBrowserTestFixtures=true)` in `config/settings.cfm` and confirming `/_browser/home` 404s.

## Risk & dependencies

- **Breaking change (low)** — No public surface removed. `/_browser/*` URLs are framework-internal and documented as such in CLAUDE.md + `.ai/wheels/testing/browser-testing.md`. No 3.x app relies on these (they were added in 4.0 via PR #2116).
- **Cross-version migration (none needed for 3.x→4.0)** — 3.x had no browser testing. Apps upgrading to 4.0 never saw these routes in a stable release.
- **Cross-engine risk** — The `$include` in `$lockedLoadRoutes` is already Lucee+Adobe tested; adding one more conditional include follows the same pattern. Verify dotted controller lookup (`wheels##public##browser-fixtures##...`) resolves on Adobe 2018/2021/2023/2025 — hyphens in path segments may need escaping or a rename to `browserfixtures` (no hyphen, matches existing convention — `wheelstest`, `browsertesthome`).
- **Name collision** — if a user already has an app route named `browserTestLogin` etc., adding framework routes with the same name at load time (before `config/routes.cfm`) means the app route would override (framework registers first, app registers second). That's the desired semantics; worst case a developer opting into `loadBrowserTestFixtures=true` in a real app and defining their own `browserTestLogin` route would clobber the fixture, which is fine.
- **Related (out of scope)**:
  - `/wheels/mcp` deprecation per CLAUDE.md — unaffected; separate issue.
  - `/wheels/app/tests` and `/wheels/core/tests` — already correctly framework-internal.
  - The duplicate fixture copies in `vendor/wheels/tests/_assets/` vs new `vendor/wheels/public/browser-fixtures/` — follow-up task to consolidate (spawn as separate issue after this lands).
- **Dogfood-app-only setting** — `loadBrowserTestFixtures` exists mostly for this one repo. If that feels too bespoke, alternative: drop the setting, key solely on `environment=testing`, and set `environment=testing` in the dogfood app's dev config. Either works; call it out in the PR for reviewer preference.

## Effort estimate
M — straightforward file moves + one framework loader conditional + one new mapper include + settings wiring. Bulk of the work is verifying cross-engine route resolution of the dotted controller path and confirming browser specs still pass against the real HTTP server. ~3-5 hours including test-matrix verification.

## Unresolved questions

- Prefer the new `loadBrowserTestFixtures` setting, or key solely on `environment=testing`?
- Dotted-controller path naming: `wheels.public.browserfixtures` (no hyphen, matches `wheelstest`) or `wheels.public.browser-fixtures`? Pick based on Adobe CF compatibility check.
- Should `vendor/wheels/tests/_assets/controllers/BrowserTest*.cfc` be deleted in this PR, or left for a follow-up de-dup?
