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
  Wheels 4.0 lands with seven breaking changes and a Legacy Compatibility
  Adapter for teams that cannot touch every call site this quarter. This post
  is the honest map: what breaks, how to detect it, how to fix it, and when
  the adapter is the right answer instead.
coverImage: null
---

# Upgrading from Wheels 3.x

_Peter Amiri, Wheels Core Team_

---

If you run a 3.x Wheels app in production, 4.0 is the first release in years with hard breaks. Not many — seven — but they are real, and pretending otherwise does not help anyone.

The good news: the breakers are concentrated. Five are renames or default flips that `grep` will find for you in an afternoon. Two are security defaults that used to be permissive and are now strict, which is the direction you wanted them to go anyway. And for the team that inherited a 3.x monolith with spotty test coverage and no appetite for a sprint-long migration, there is the Legacy Compatibility Adapter — one flag that re-enables most of the old surface area while you migrate on your own schedule.

This post is the map: what changed, how to detect each break, how to fix it, and where the adapter fits.

## The two-path upgrade

Pick one, then stick with it.

**Path A — clean upgrade.** You fix the seven breakers directly, update your code, and run on 4.0 behavior. This is the recommended path for any app with reasonable test coverage. Most teams finish in an afternoon. Every new Wheels feature — middleware pipeline, chainable query builder, route model binding, WheelsTest BDD, `wheels deploy` — is available immediately and works as documented.

**Path B — Legacy Compatibility Adapter.** You flip one setting ([#2015](https://github.com/wheels-dev/wheels/pull/2015)), and most 3.x code continues to work. The adapter is a bridge, not a permanent layer: it restores old defaults and re-registers removed aliases so the app boots, but it is not the long-term supported configuration. Use it when you need 4.0 in production now and cannot schedule the migration work yet. Plan to remove the flag before 4.x reaches end-of-life.

```cfm
// config/settings.cfm — one line, soft landing
set(legacyCompatibilityAdapter=true);
```

Either way, start by reading the [full upgrade guide](https://guides.wheels.dev/v4-0-0-snapshot/upgrading/3x-to-4x/) and skimming the seven breakers below. Knowing what is in the blast radius is half the battle.

## The seven breaking changes

| # | Change | PR | Detection |
|---|---|---|---|
| 1 | `wheels snippets` renamed to `wheels generate snippets` | [#1852](https://github.com/wheels-dev/wheels/pull/1852) | Scripts calling bare `wheels snippets` |
| 2 | `cfwheels` → `wheels` namespace in active code | [#2064](https://github.com/wheels-dev/wheels/pull/2064) | `grep -r cfwheels app/` |
| 3 | `testbox` → `wheelstest` namespace | [#1889](https://github.com/wheels-dev/wheels/pull/1889) | Test imports and extends clauses |
| 4 | `tests/specs/functions/` → `tests/specs/functional/` | [#1872](https://github.com/wheels-dev/wheels/pull/1872) | Directory name in your test tree |
| 5 | Legacy RocketUnit removed from core | [#1925](https://github.com/wheels-dev/wheels/pull/1925) | New test runs still work; core shim gone |
| 6 | CORS default flips from wildcard to deny-all | [#2039](https://github.com/wheels-dev/wheels/pull/2039) | Browser preflight failures from cross-origin clients |
| 7 | `allowEnvironmentSwitchViaUrl` off in prod; reload password required | [#2076](https://github.com/wheels-dev/wheels/pull/2076), [#2082](https://github.com/wheels-dev/wheels/pull/2082) | `?reload=true` returns 403 in production |

### 1. `wheels snippets` renamed

The top-level `wheels snippets` command moved under the generator group and is now `wheels generate snippets`. This aligns it with the rest of the scaffolding surface (`wheels generate model`, `wheels generate controller`) and removes a one-off command at the CLI root.

Detect it by searching your `Makefile`, `package.json` scripts, CI pipelines, and `.sh` files for `wheels snippets`. A build that ran yesterday fails with "unknown command" as the only signal. Fix by renaming the call site. The adapter re-registers the old alias if you need it.

### 2. CFWheels → Wheels rebrand in active code

The project is named Wheels. It has been since 3.0, but 3.x kept `cfwheels`-prefixed identifiers in active namespaces for compatibility. 4.0 completes the rename in the code paths that actually run — module names, event prefixes, CLI namespace.

Detect with `grep -ri cfwheels app/ config/`. Most references are cosmetic (log lines, comments), but any event listener or module reference using the old name will fail to resolve. Rename to `wheels`.

### 3. `testbox` → `wheelstest` namespace rename

The bundled test harness was historically called `testbox` to signal its TestBox-inspired BDD surface. It is now `wheelstest`, which is accurate (it is a Wheels-specific runner with TestBox-style syntax, not TestBox itself) and removes the brand ambiguity.

Every test CFC has an `extends=` clause. If yours say `extends="testbox.system.BaseSpec"` or similar, change to `wheels.WheelsTest` for the standard BDD base, or to the specific base under `wheels.wheelstest.*` if you need a specialized runner (browser, system). The adapter re-aliases the old namespace.

### 4. Tests directory rename

`tests/specs/functions/` becomes `tests/specs/functional/`. The old name was a typo that stuck. Detect by filesystem inspection; fix by renaming the directory and updating any explicit `directory=tests.specs.functions` arguments in CI runner calls.

### 5. Legacy RocketUnit removed from core

The original Wheels test syntax — `test_` prefixed functions with `assert()` calls — was maintained in core through 3.x for the pre-TestBox test estate. In 4.0, the RocketUnit runner is no longer bundled with the core distribution. Existing `test_`-style specs still execute, because the runner lives in the `wheelstest` package and loads when specs that need it are present; the change is that it is no longer in the framework core path.

Only relevant if you had custom tooling that depended on the core loader having RocketUnit loaded. Day-to-day test runs keep working. Write new specs in WheelsTest BDD; leave the old specs alone until you need to touch them.

### 6. CORS default: wildcard to deny-all

The `wheels.middleware.Cors` middleware used to default to `allowOrigins="*"` — any origin gets a permissive response. That was a footgun: apps that added the middleware without reading the reference ended up broadcasting CORS for any origin in production. The 4.0 default is deny-all: if you do not configure `allowOrigins`, no cross-origin requests pass.

If you have a JS client, a mobile app, or a webhook source that talks to your API from a different origin, browser preflights will now fail with a CORS error visible in the browser console. Set `allowOrigins` explicitly to the list of origins that should be permitted:

```cfm
// config/settings.cfm — explicit allow-list
set(middleware = [
    new wheels.middleware.Cors(allowOrigins="https://myapp.com,https://admin.myapp.com")
]);
```

### 7. URL environment switch off in prod; reload password required

Two related production defaults flipped. `allowEnvironmentSwitchViaUrl` used to default `true`, which meant `?environment=design` would switch modes on a live production host. It now defaults `false` in production. At the same time, `?reload=true` requires a non-empty `reloadPassword` — the empty-string default was an all-access pass and has been removed.

Production `?reload=true` requests return 403; automation that relied on URL-based env switching no longer switches. Set a non-empty `reloadPassword` in production config. If you genuinely need URL-based environment switching — most teams do not — flip `allowEnvironmentSwitchViaUrl` back on explicitly for the environments that need it.

## The Legacy Compatibility Adapter

The adapter is a single flag: `set(legacyCompatibilityAdapter=true)`. Turning it on restores the 3.x behavior for the items that can be restored — renamed aliases, permissive defaults on CORS and the reload password, legacy directory fallbacks. It cannot resurrect code that was deleted (the RocketUnit core shim is gone regardless), but it buys you time on everything else.

Use it when: you inherited an app with ambiguous test coverage, you need 4.0 in production for a specific reason (a CVE fix, a dependency constraint, a feature your team is already depending on), and you cannot plan the migration work this quarter. Turn it on, ship, schedule the migration for the next planning cycle.

Do not use it for: new apps, small apps, or apps where you are already touching the breakers to add a feature. The adapter exists to buy time, not to avoid work that is cheaper to do now.

## Security-hardening defaults to audit

These are not on the canonical breaker list, but they change visible behavior. 4.0 shipped with more than forty security-hardening PRs; these three are the most likely to surface when you turn the app on in production.

**HSTS default-on in production ([#2081](https://github.com/wheels-dev/wheels/pull/2081)).** Responses now carry `Strict-Transport-Security` by default when the app is in production mode. If you have a subdomain that serves plain HTTP, confirm the `includeSubDomains` and `max-age` defaults match your topology before real users see it.

**RateLimiter `trustProxy=false` and proxy strategy `last` ([#2024](https://github.com/wheels-dev/wheels/pull/2024), [#2088](https://github.com/wheels-dev/wheels/pull/2088)).** The rate limiter no longer trusts `X-Forwarded-For` by default. If your app sits behind a reverse proxy or load balancer, set `trustProxy=true` and configure the strategy — otherwise every request appears to come from the proxy's IP and the limiter is effectively disabled per-client.

**CSRF SameSite cookie default ([#2035](https://github.com/wheels-dev/wheels/pull/2035)).** The CSRF token cookie now sets `SameSite=Lax`. Cross-site form submissions that worked in 3.x will start failing; usually the fix is that they should have been same-origin all along.

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

Before pushing 4.0 to production: set `allowOrigins` explicitly on every CORS middleware, set a non-empty CSRF encryption key, set a non-empty `reloadPassword`, configure RateLimiter `trustProxy` and proxy strategy intentionally if you are behind a proxy or load balancer, confirm HSTS settings match your subdomain topology, and decide explicitly whether the Legacy Compatibility Adapter is on and document why.

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

For context as you plan timeline: 4.0 is roughly 260 pull requests over fifteen weeks, with more than forty dedicated to security hardening. Contributors include @bpamiri, @zainforbjs, @chapmandu, @mlibbe, @MukundaKatta, and Dependabot. Seven of those PRs are the breakers above; the rest is additive.

## Where to go next

- [Upgrading to 4.0](https://guides.wheels.dev/v4-0-0-snapshot/upgrading/3x-to-4x/) — the authoritative guide with every breaker, every default flip, and every adapter flag documented in one place.
- [Middleware](https://guides.wheels.dev/v4-0-0-snapshot/core-concepts/middleware-pipeline/), [route model binding](https://guides.wheels.dev/v4-0-0-snapshot/core-concepts/how-routing-works/), [query builder](https://guides.wheels.dev/v4-0-0-snapshot/basics/query-builder-and-scopes/) — the three adoptions that pay off fastest.
- [Packages](https://guides.wheels.dev/v4-0-0-snapshot/digging-deeper/packages/) — the replacement for the legacy `plugins/` folder.
- [Wheels vs other frameworks](https://github.com/wheels-dev/wheels/blob/develop/docs/wheels-vs-frameworks.md) — context for what 4.0 now offers compared to Rails, Laravel, and the rest.

Most upgrades take an afternoon, not a sprint. If yours takes longer, open an issue on [wheels-dev/wheels](https://github.com/wheels-dev/wheels/issues) with the `upgrade` label — 4.0 is the first release in a long time with real breaks, and the team wants to hear where the map does not match the terrain.
