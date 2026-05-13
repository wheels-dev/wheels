---
title: 'Upgrading from Wheels 3.x'
slug: upgrading-from-wheels-3x
publishedAt: '2026-05-09T07:00:00.000Z'
updatedAt: null
author: Peter Amiri
tags:
  - wheels-4
  - upgrade
  - migration
categories: []
excerpt: >-
  Wheels 4.0 lands with eleven breaking changes and a Legacy Compatibility
  Adapter for teams that cannot touch every call site this quarter. This post
  is the honest map: what breaks, how to detect it, how to fix it, and when
  the adapter is the right answer instead.
coverImage: null
---

# Upgrading from Wheels 3.x

_Peter Amiri, Wheels Core Team_

---

If you run a 3.x Wheels app in production, 4.0 is the first release in years with hard breaks. Not many — eleven — but they are real, and pretending otherwise does not help anyone.

The good news: the breakers are concentrated. Several are renames or CLI changes that `grep` will find for you in an afternoon. Several are security defaults that used to be permissive and are now strict, which is the direction you wanted them to go anyway. And for the team that inherited a 3.x monolith with spotty test coverage and no appetite for a sprint-long migration, there is the Legacy Compatibility Adapter — one flag that re-enables most of the old surface area while you migrate on your own schedule.

This post is the map: what changed, how to detect each break, how to fix it, and where the adapter fits.

## The two-path upgrade

Pick one, then stick with it.

**Path A — clean upgrade.** You fix the eleven breaking changes directly, update your code, and run on 4.0 behavior. This is the recommended path for any app with reasonable test coverage. Most teams finish in an afternoon. Every new Wheels feature — middleware pipeline, chainable query builder, route model binding, WheelsTest BDD, `wheels deploy` — is available immediately and works as documented.

**Path B — Legacy Compatibility Adapter.** You flip one setting ([#2015](https://github.com/wheels-dev/wheels/pull/2015)), and most 3.x code continues to work. The adapter is a bridge, not a permanent layer: it restores old defaults and re-registers removed aliases so the app boots, but it is not the long-term supported configuration. Use it when you need 4.0 in production now and cannot schedule the migration work yet. Plan to remove the flag before 4.x reaches end-of-life.

```cfm
// config/settings.cfm — one line, soft landing
set(legacyCompatibilityAdapter=true);
```

Either way, start by reading the [full upgrade guide](https://guides.wheels.dev/v4-0-0-snapshot/upgrading/3x-to-4x/) and skimming the eleven breaking changes below. Knowing what is in the blast radius is half the battle.

## The eleven breaking changes

| # | Change | PR | Detection |
|---|---|---|---|
| 1 | `wheels snippets` renamed to `wheels generate snippets` | [#1852](https://github.com/wheels-dev/wheels/pull/1852) | Scripts calling bare `wheels snippets` |
| 2 | CORS default changed from wildcard to deny-all | [#2039](https://github.com/wheels-dev/wheels/pull/2039) | Browser preflight failures from cross-origin clients |
| 3 | `wheels.Test` → `wheels.WheelsTest` (test base class) | [#1889](https://github.com/wheels-dev/wheels/pull/1889) | Test `extends=` clauses containing `wheels.Test` |
| 4 | `tests/specs/functions/` → `tests/specs/functional/` | [#1872](https://github.com/wheels-dev/wheels/pull/1872) | Directory name in your test tree |
| 5 | HSTS defaults on in production | [#2081](https://github.com/wheels-dev/wheels/pull/2081) | `Strict-Transport-Security` in all production responses |
| 6 | CSRF key required in production; JWT algorithm validated | [#2079](https://github.com/wheels-dev/wheels/pull/2079), [#2086](https://github.com/wheels-dev/wheels/pull/2086) | CSRF token rotation on every deploy; JWT with `alg: none` rejected |
| 7 | `allowEnvironmentSwitchViaUrl` off in prod; reload password required | [#2076](https://github.com/wheels-dev/wheels/pull/2076), [#2082](https://github.com/wheels-dev/wheels/pull/2082) | `?reload=true` returns 403 in production |
| 8 | RateLimiter `trustProxy` and proxy strategy defaults hardened | [#2024](https://github.com/wheels-dev/wheels/pull/2024), [#2088](https://github.com/wheels-dev/wheels/pull/2088) | Rate limiter counting all requests from proxy IP, not per-client |
| 9 | CSRF cookie `SameSite` attribute set | [#2035](https://github.com/wheels-dev/wheels/pull/2035) | Cross-site form submissions from third-party frames |
| 10 | `application.wirebox` renamed to `application.wheelsdi` | [#1888](https://github.com/wheels-dev/wheels/pull/1888) | Direct container references in application code |
| 11 | Vite manifest strictness — missing entries throw in production | [#2133](https://github.com/wheels-dev/wheels/pull/2133) | `Wheels.ViteAssetNotFound` on first request after deploy |

### 1. `wheels snippets` renamed

The top-level `wheels snippets` command moved under the generator group and is now `wheels generate snippets`. This aligns it with the rest of the scaffolding surface (`wheels generate model`, `wheels generate controller`) and removes a one-off command at the CLI root.

Detect it by searching your `Makefile`, `package.json` scripts, CI pipelines, and `.sh` files for `wheels snippets`. A build that ran yesterday fails with "unknown command" as the only signal. Fix by renaming the call site. The adapter re-registers the old alias if you need it.

### 2. CORS default: wildcard to deny-all

The `wheels.middleware.Cors` middleware used to default to `allowOrigins="*"` — any origin gets a permissive response. That was a footgun: apps that added the middleware without reading the reference ended up broadcasting CORS for any origin in production. The 4.0 default is deny-all: if you do not configure `allowOrigins`, no cross-origin requests pass.

If you have a JS client, a mobile app, or a webhook source that talks to your API from a different origin, browser preflights will now fail with a CORS error visible in the browser console. Set `allowOrigins` explicitly to the list of origins that should be permitted:

```cfm
// config/settings.cfm — explicit allow-list
set(middleware = [
    new wheels.middleware.Cors(allowOrigins="https://myapp.com,https://admin.myapp.com")
]);
```

### 3. Test base class renamed: `wheels.Test` → `wheels.WheelsTest`

The RocketUnit-era test base class (`wheels.Test`) is renamed to `wheels.WheelsTest`. The old class still loads in 4.0 — existing specs keep running — but every `extends=` clause pointing to `wheels.Test` should be updated to `wheels.WheelsTest`.

The rename is to the Wheels test base class itself, not to any external test harness namespace. Detect it with `grep -r "extends=\"wheels.Test\"" tests/`. Fix by changing the extends clause and adopting BDD syntax:

```cfm
// 3.x — RocketUnit style (still loads in 4.0, legacy only)
component extends="wheels.Test" {
    function test_user_requires_email() {
        var u = model("User").new();
        assert("NOT u.valid()");
    }
}
```

```cfm
// 4.0 — WheelsTest BDD style
component extends="wheels.WheelsTest" {
    function run() {
        describe("User", () => {
            it("requires an email", () => {
                var u = model("User").new();
                expect(u.valid()).toBeFalse();
            });
        });
    }
}
```

The adapter re-aliases `wheels.Test` → `wheels.WheelsTest` so existing specs continue to load without code changes. New tests should extend `wheels.WheelsTest` and use BDD syntax.

### 4. Tests directory rename

`tests/specs/functions/` becomes `tests/specs/functional/`. The old name was a typo that stuck. Detect by filesystem inspection; fix by renaming the directory and updating any explicit `directory=tests.specs.functions` arguments in CI runner calls.

### 5. HSTS defaults on in production

Responses now carry `Strict-Transport-Security: max-age=31536000; includeSubDomains` by default when the app is in production mode. If you have a subdomain that serves plain HTTP, or a load balancer that already sets HSTS, confirm the `includeSubDomains` and `max-age` defaults match your topology before real users see it. Pass `hsts=false` to `SecurityHeaders` ([#2195](https://github.com/wheels-dev/wheels/pull/2195)) to suppress framework-level HSTS emission when your proxy handles it.

### 6. CSRF key required; JWT algorithm validated

Two related security changes shipped together. First: the CSRF encryption key is auto-generated if empty ([#2054](https://github.com/wheels-dev/wheels/pull/2054)), which means cookies rotate on every deploy. Set a stable key in production config:

```cfm
set(csrfEncryptionKey = env("WHEELS_CSRF_KEY"));
```

Second: JWT verification now validates the `alg` claim and uses constant-time signature comparison ([#2079](https://github.com/wheels-dev/wheels/pull/2079), [#2086](https://github.com/wheels-dev/wheels/pull/2086)). Tokens forged with `alg: none` or mismatched algorithms are rejected outright.

### 7. URL environment switch off in prod; reload password required

Two related production defaults flipped. `allowEnvironmentSwitchViaUrl` used to default `true`, which meant `?environment=production` could switch modes on a live production host. It now defaults `false` in production. At the same time, `?reload=true` requires a non-empty `reloadPassword` — the empty-string default was an all-access pass and has been removed.

Production `?reload=true` requests return 403; automation that relied on URL-based env switching no longer switches. Set a non-empty `reloadPassword` in production config. If you genuinely need URL-based environment switching — most teams do not — flip `allowEnvironmentSwitchViaUrl` back on explicitly for the environments that need it.

### 8. RateLimiter defaults hardened

The rate limiter no longer trusts `X-Forwarded-For` by default (`trustProxy` changed from `true` to `false`). The proxy strategy default also changed to `last` for security. If your app sits behind a reverse proxy or load balancer, set `trustProxy=true` and configure the strategy — otherwise every request appears to come from the proxy's IP and the limiter is effectively disabled per-client.

```cfm
// config/settings.cfm — explicit proxy configuration
set(middleware = [
    new wheels.middleware.RateLimiter(
        maxRequests=100,
        windowSeconds=60,
        trustProxy=true,
        proxyStrategy="last"
    )
]);
```

### 9. CSRF SameSite cookie default

The CSRF token cookie now sets `SameSite=Lax`. Cross-site form submissions that worked in 3.x will start failing; usually the fix is that they should have been same-origin all along.

### 10. `application.wirebox` renamed to `application.wheelsdi`

The DI container moved in-house (replacing WireBox), and the application-scope key changed with it. Code that reached into `application.wirebox` directly must be updated to `application.wheelsdi`. The recommended path is to use the new `service()` global helper instead:

```cfm
// 3.x
var svc = application.wirebox.getInstance("emailService");
// 4.0 — direct reference
var svc = application.wheelsdi.getInstance("emailService");
// 4.0 — preferred
var svc = service("emailService");
```

### 11. Vite manifest strictness — missing entries throw in production

`viteScriptTag()`, `viteStyleTag()`, and `vitePreloadTag()` now throw `Wheels.ViteAssetNotFound` in production when the manifest doesn't contain the requested entrypoint. The 3.x behavior was silent fallback to the raw source path. The most common failure mode is a deploy that ships new CFML code without rebuilding the Vite bundle.

Fix: rebuild assets as part of your deploy pipeline before pushing. If you can't rebuild during the upgrade window, `set(viteStrictManifest=false)` restores the 3.x fallback until your pipeline is updated.

```bash
# In your deploy step — run before pushing CFML changes
npm run build
```

## Other active-code changes to verify

These are not in the canonical eleven but are commonly encountered when upgrading real apps.

**CFWheels → Wheels rebrand in active code ([#2064](https://github.com/wheels-dev/wheels/pull/2064)).** Module names and event prefixes using old `cfwheels`-namespaced identifiers will fail to resolve. Detect with `grep -ri cfwheels app/ config/`. Most references are cosmetic (log lines, comments), but any event listener or module reference using the old name needs updating to `wheels`.

**Legacy RocketUnit removed from core ([#1925](https://github.com/wheels-dev/wheels/pull/1925)).** Existing `test_`-prefixed specs still execute — the RocketUnit runner ships in the `wheelstest` package and loads when it finds specs that need it. The change is that it is no longer bundled in the framework core path. Only relevant if you had custom tooling that depended on the core loader having RocketUnit present.

## The Legacy Compatibility Adapter

The adapter is a single flag: `set(legacyCompatibilityAdapter=true)`. Turning it on restores the 3.x behavior for the items that can be restored — renamed aliases, permissive defaults on CORS and the reload password, legacy directory fallbacks. It cannot resurrect code that was deleted (the RocketUnit core shim is gone regardless), but it buys you time on everything else.

Use it when: you inherited an app with ambiguous test coverage, you need 4.0 in production for a specific reason (a CVE fix, a dependency constraint, a feature your team is already depending on), and you cannot plan the migration work this quarter. Turn it on, ship, schedule the migration for the next planning cycle.

Do not use it for: new apps, small apps, or apps where you are already touching the breakers to add a feature. The adapter exists to buy time, not to avoid work that is cheaper to do now.

## Deprecations and recommended migrations

Not breaking, but worth scheduling after the upgrade lands.

- Legacy `plugins/` folder ([#1995](https://github.com/wheels-dev/wheels/pull/1995), [#2252](https://github.com/wheels-dev/wheels/pull/2252)) still loads in 4.x with a deprecation warning — scheduled for removal in v5.0. Migrate to the `packages/` → `vendor/` activation model before upgrading to 5.x.
- Monolithic `paginationLinks()` ([#1930](https://github.com/wheels-dev/wheels/pull/1930)) still works; new code should use `paginationNav()` plus the individual helpers.
- `wheels.Test` base class still works for existing specs; new tests extend `wheels.WheelsTest`.
- Adopt the [middleware pipeline](https://guides.wheels.dev/v4-0-0-snapshot/core-concepts/middleware-pipeline/) ([#1924](https://github.com/wheels-dev/wheels/pull/1924)) for cross-cutting concerns you currently do in `beforeFilter`.
- Turn on [route model binding](https://guides.wheels.dev/v4-0-0-snapshot/core-concepts/how-routing-works/) ([#1929](https://github.com/wheels-dev/wheels/pull/1929)) — it kills the first three lines of most show/edit/update actions.
- Use the [chainable query builder](https://guides.wheels.dev/v4-0-0-snapshot/basics/query-builder-and-scopes/) ([#1922](https://github.com/wheels-dev/wheels/pull/1922)) instead of raw `where` strings for anything user-supplied.
- Replace Redis-backed job queues with the [built-in daemon](https://guides.wheels.dev/v4-0-0-snapshot/digging-deeper/background-jobs/) ([#1934](https://github.com/wheels-dev/wheels/pull/1934)) if the dependency is more than you need.

## Testing and deploying

Before you declare the upgrade done, exercise it. Enable `TestClient` ([#2099](https://github.com/wheels-dev/wheels/pull/2099)) and write a smoke-test spec that hits every top-level route you care about. Turn on the parallel runner ([#2100](https://github.com/wheels-dev/wheels/pull/2100)). Write one browser test ([#2113](https://github.com/wheels-dev/wheels/pull/2113)) for your critical-path flow — login, do the main thing, log out.

Before pushing 4.0 to production: set `allowOrigins` explicitly on every CORS middleware, set a non-empty CSRF encryption key, set a non-empty `reloadPassword`, configure RateLimiter `trustProxy` and proxy strategy intentionally if you are behind a proxy or load balancer, confirm HSTS settings match your subdomain topology, rebuild Vite assets before the first production deploy, and decide explicitly whether the Legacy Compatibility Adapter is on and document why.

Here is what a migrated spec looks like in 4.0:

```cfm
// tests/specs/models/UserSpec.cfc
component extends="wheels.WheelsTest" {
    function run() {
        describe("User", () => {
            it("validates email", () => {
                expect(model("User").new(email="bad").valid()).toBeFalse();
            });
        });
    }
}
```

One extends change, one BDD block, one `expect` instead of `assert`. The old RocketUnit specs sitting next to it keep running until you come back for them.

## The shape of the release

For context as you plan timeline: 4.0 is roughly 260 pull requests over fifteen weeks, with more than forty dedicated to security hardening. Contributors include @bpamiri, @zainforbjs, @chapmandu, @mlibbe, @MukundaKatta, and Dependabot. Eleven of those PRs are the breakers above; the rest is additive.

## Where to go next

- [Upgrading to 4.0](https://guides.wheels.dev/v4-0-0-snapshot/upgrading/3x-to-4x/) — the authoritative guide with every breaker, every default flip, and every adapter flag documented in one place.
- [Middleware](https://guides.wheels.dev/v4-0-0-snapshot/core-concepts/middleware-pipeline/), [route model binding](https://guides.wheels.dev/v4-0-0-snapshot/core-concepts/how-routing-works/), [query builder](https://guides.wheels.dev/v4-0-0-snapshot/basics/query-builder-and-scopes/) — the three adoptions that pay off fastest.
- [Packages](https://guides.wheels.dev/v4-0-0-snapshot/digging-deeper/packages/) — the replacement for the legacy `plugins/` folder.
- [Wheels vs other frameworks](https://github.com/wheels-dev/wheels/blob/develop/docs/wheels-vs-frameworks.md) — context for what 4.0 now offers compared to Rails, Laravel, and the rest.

Most upgrades take an afternoon, not a sprint. If yours takes longer, open an issue on [wheels-dev/wheels](https://github.com/wheels-dev/wheels/issues) with the `upgrade` label — 4.0 is the first release in a long time with real breaks, and the team wants to hear where the map does not match the terrain.
