---
description: Upgrade guide for Wheels 3.x → 4.0
---

# Upgrading to Wheels 4.0

This guide walks you through upgrading a Wheels 3.x application to Wheels 4.0. It is organized so you can scan the 5-minute checklist first, decide if your upgrade is simple, and walk each breaking change in detail only if it affects you.

For the full picture of what is new in 4.0, see the [Wheels 4.0 Feature Audit](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md) (185-PR inventory) and the [3.0 → 4.0 Comparison](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md) (row-by-row breakdown of what changed).

## Before you start

1. **Semver.** Wheels 4.0 is a major version bump. Breaking changes are expected. We have kept them narrow — 6 security-hardening default flips (each with an opt-out), 1 CLI rename, and 3 namespace / directory renames.
2. **Backup.** Take a full backup of your app code, your database, and your `config/settings.cfm`. Commit all in-flight changes to version control first.
3. **Test environment.** Upgrade in a staging environment before production. Resolve all warnings before flipping the switch.
4. **Read the CHANGELOG.** The Wheels 4.0 section of `CHANGELOG.md` lists 185 changes. Many are security-hardening and bug fixes you will want.

## The short version — 5-minute upgrade checklist

If every row in this table looks fine for your app, your upgrade is probably straightforward. Walk the detailed section below for any row you are unsure about.

| # | What changed | Fix if affected |
|---|---|---|
| 1 | CORS default: wildcard → deny-all | Set `allowOrigins=[...]` explicitly on `wheels.middleware.Cors()` |
| 2 | `allowEnvironmentSwitchViaUrl` default `false` in production | Set explicitly + non-empty `reloadPassword` |
| 3 | HSTS header default-on in production | Fine for HTTPS-only apps; pass `hsts=false` if you have mixed HTTP clients |
| 4 | CSRF cookie `SameSite=Lax` default | Fine for most apps; pass `SameSite=None` only for cross-site flows |
| 5 | RateLimiter `trustProxy=false` default | Pass `trustProxy=true, proxyHopCount=N` behind a proxy |
| 6 | RateLimiter proxy strategy `last` default | Fine for most proxy setups; `first` only if you own the full chain |
| 7 | `wheels snippets` → `wheels code` CLI rename | Grep your scripts and CI configs for `wheels snippets` |
| 8 | Test base `wheels.Test` → `wheels.WheelsTest` | Required for new tests only; old base still works for existing tests |
| 9 | `tests/specs/functions/` → `tests/specs/functional/` (framework) | Apps that mirrored the old layout can rename for consistency |
| 10 | `application.wirebox` → `application.wheelsdi` | Prefer the `service()` global helper instead of direct scope access |

## Breaking changes — detailed

Each item below follows the same four-part structure: **What changed**, **How to detect**, **How to fix**, **Opt-out** (where one is available).

### 1. CORS middleware default: wildcard → deny-all

**PR:** [#2039](https://github.com/wheels-dev/wheels/pull/2039)

**What changed**

The default `allowOrigins` value on `wheels.middleware.Cors()` changed from `*` (wildcard — allow any origin) to an empty list (deny-all). Apps that relied on the wildcard default will now reject cross-origin requests through CORS.

**How to detect**

Grep your middleware registration for `Cors(` with no explicit `allowOrigins`:

```bash
grep -r "Cors(" config/ app/
```

If any site has `new wheels.middleware.Cors()` with no arguments, you were relying on the wildcard default.

**How to fix**

Pass your allowed origins explicitly:

```cfm
// Before — relied on wildcard default in 3.x
set(middleware=[
    new wheels.middleware.Cors()
]);

// After — 4.0 requires explicit origins
set(middleware=[
    new wheels.middleware.Cors(allowOrigins=["https://yourapp.com", "https://admin.yourapp.com"])
]);
```

If you genuinely need wildcard behavior (uncommon and usually an anti-pattern), pass `*` explicitly:

```cfm
set(middleware=[
    new wheels.middleware.Cors(allowOrigins=["*"])
]);
```

**Opt-out**

There is no separate opt-out setting — the fix is to pass `allowOrigins` explicitly. Note that wildcard + credentials is rejected in 4.0 (separate hardening, [#2053](https://github.com/wheels-dev/wheels/pull/2053)).

### 2. `allowEnvironmentSwitchViaUrl` defaults to `false` in production

**PRs:** [#2076](https://github.com/wheels-dev/wheels/pull/2076), [#2082](https://github.com/wheels-dev/wheels/pull/2082)

**What changed**

The `allowEnvironmentSwitchViaUrl` setting now defaults to `false` in production. Additionally, `reloadPassword` must be non-empty for environment switching. In 3.x, URL-based environment switching was enabled in production by default.

**How to detect**

Pre-upgrade, grep your config for explicit references:

```bash
grep -rn "allowEnvironmentSwitchViaUrl\|reloadPassword" config/
```

If neither is set, you were relying on the 3.x default and will be blocked in production after upgrading. Post-upgrade, visiting `/?reload=true&environment=development` (adjusted for your rewrite config) will silently not change the environment — that's the block in action.

**How to fix**

If you use URL-based environment switching in production (generally not recommended), set it explicitly and ensure a non-empty reload password:

```cfm
// config/production/settings.cfm
set(allowEnvironmentSwitchViaUrl=true);
set(reloadPassword="choose-a-long-random-value");
```

Recommended: remove production environment switching entirely and use deployment tooling to flip environments.

**Opt-out**

Set `allowEnvironmentSwitchViaUrl=true` explicitly in `config/production/settings.cfm`. The reload-password requirement cannot be bypassed.

### 3. HSTS header default-on in production

**PR:** [#2081](https://github.com/wheels-dev/wheels/pull/2081)

**What changed**

When the `SecurityHeaders` middleware is active in production, HSTS (`Strict-Transport-Security`) is emitted by default. In 3.x, HSTS required explicit opt-in.

**How to detect**

Inspect response headers in production:

```bash
curl -sI https://yourapp.com | grep -i strict-transport-security
```

If you see `Strict-Transport-Security: max-age=...`, HSTS is active.

**How to fix**

For HTTPS-only apps, no action needed — this is a security improvement. For apps that serve some traffic over HTTP (or mixed environments where HSTS will break clients):

```cfm
set(middleware=[
    new wheels.middleware.SecurityHeaders(hsts=false)
]);
```

**Opt-out**

Pass `hsts=false` on the middleware as shown above.

### 4. CSRF cookie `SameSite=Lax` default

**PR:** [#2035](https://github.com/wheels-dev/wheels/pull/2035)

**What changed**

CSRF cookies now set the `SameSite=Lax` attribute by default. In 3.x, no `SameSite` attribute was set.

**How to detect**

Check your CSRF cookie in browser devtools (Application → Cookies). Look at the `SameSite` column.

**How to fix**

For most apps, the `Lax` default is correct and more secure — no action needed. For apps that rely on cross-site CSRF cookie behavior (e.g., third-party form POSTs, uncommon and usually an anti-pattern):

```cfm
set(csrfCookieSameSite="None");  // requires Secure attribute — HTTPS only
```

**Opt-out**

Set `csrfCookieSameSite` explicitly to `None`, `Strict`, or a custom value. Note that browsers reject `SameSite=None` cookies without the `Secure` attribute.

### 5. RateLimiter `trustProxy` default `true` → `false`

**PR:** [#2024](https://github.com/wheels-dev/wheels/pull/2024)

**What changed**

`wheels.middleware.RateLimiter` no longer trusts `X-Forwarded-For` headers by default. In 3.x, proxy-supplied client IPs were used for rate-limit buckets — which is vulnerable to spoofing if the app has no proxy.

**How to detect**

If your app sits behind a reverse proxy (nginx, Cloudflare, AWS ALB, etc.) and uses rate limiting, users will now share a rate-limit bucket per proxy IP (not per real client IP) after the upgrade. Symptom: requests rate-limited earlier than expected because many users look like the same IP to the limiter.

**How to fix**

If you have a trusted proxy:

```cfm
set(middleware=[
    new wheels.middleware.RateLimiter(
        trustProxy=true,
        proxyHopCount=1  // number of known-trusted hops between client and app
    )
]);
```

Set `proxyHopCount` to the exact number of proxies in front of your app. One proxy = 1. CDN plus load-balancer = 2.

**Opt-out**

Pass `trustProxy=true` on the middleware. Only do this with a known, trusted proxy — otherwise clients can spoof their IP via `X-Forwarded-For`.

### 6. RateLimiter proxy strategy default: `first` → `last`

**PR:** [#2088](https://github.com/wheels-dev/wheels/pull/2088)

**What changed**

When `trustProxy=true`, the strategy for picking which IP in the `X-Forwarded-For` chain to use as the rate-limit key changed from `first` (left-most, client-supplied) to `last` (right-most, proxy-supplied). In 3.x, the client-supplied IP was used — which is spoofable.

**How to detect**

If your rate limiter behaves unexpectedly after upgrade (either more aggressive or less), the strategy change is the likely cause. Specifically, spoofing attempts (`X-Forwarded-For: 1.2.3.4`) no longer win over the real proxy-supplied IP.

**How to fix**

This is a security-hardening change — the `last` strategy is correct for almost every deployment. No action needed unless you explicitly need the old behavior:

```cfm
set(middleware=[
    new wheels.middleware.RateLimiter(
        trustProxy=true,
        proxyStrategy="first"  // only if you own the entire proxy chain
    )
]);
```

**Opt-out**

Pass `proxyStrategy="first"` on the middleware. Do not do this unless you control every proxy in the chain and trust all of them.

### 7. CLI: `wheels snippets` → `wheels code`

**PR:** [#1852](https://github.com/wheels-dev/wheels/pull/1852)

**What changed**

The `wheels snippets` CLI command is renamed to `wheels code`. Shell scripts, CI pipelines, deploy hooks, and personal aliases calling `wheels snippets` must be updated.

**How to detect**

```bash
grep -r "wheels snippets" .github/ scripts/ bin/ Makefile 2>/dev/null
```

**How to fix**

Replace every occurrence:

```bash
# Before
wheels snippets list
wheels snippets add MyTemplate

# After
wheels code list
wheels code add MyTemplate
```

**Opt-out**

None — this is a CLI rename. The old command prints a helpful error pointing to the new name.

### 8. Test base class: `wheels.Test` → `wheels.WheelsTest`

**PR:** [#1889](https://github.com/wheels-dev/wheels/pull/1889)

**What changed**

The TestBox-compatible test base class was renamed from `wheels.Test` to `wheels.WheelsTest`. New test specs should extend `wheels.WheelsTest`. Existing `wheels.Test` specs continue to work during 4.0 as a deprecation path.

**How to detect**

```bash
grep -rn 'extends="wheels.Test"' tests/
```

**How to fix**

For RocketUnit-style specs being rewritten in BDD, or for any new specs:

```cfm
// Before (legacy RocketUnit)
component extends="wheels.Test" {
    function test_something() {
        assert("1 == 1");
    }
}

// After (WheelsTest BDD)
component extends="wheels.WheelsTest" {
    function run() {
        describe("something", () => {
            it("works", () => {
                expect(true).toBeTrue();
            });
        });
    }
}
```

**Opt-out**

No migration required for existing specs — `wheels.Test` remains available through 4.x as a deprecation path. The rename only applies to new specs going forward.

### 9. Tests directory rename: `tests/specs/functions/` → `tests/specs/functional/`

**PR:** [#1872](https://github.com/wheels-dev/wheels/pull/1872)

**What changed**

The framework's own test directory at `vendor/wheels/tests/specs/functions/` was renamed to `vendor/wheels/tests/specs/functional/`. Apps that mirrored this convention in their own `tests/specs/` directory should rename for consistency.

**How to detect**

```bash
ls -d tests/specs/functions/ 2>/dev/null && echo "renamable"
```

**How to fix**

```bash
git mv tests/specs/functions tests/specs/functional
```

Update any explicit test-runner directory references that hardcode the old name.

**Opt-out**

None at the framework level — the framework's own directory is renamed. Apps can keep their own naming, but consistency with the framework convention is recommended.

### 10. `application.wirebox` → `application.wheelsdi`

**PR:** [#1888](https://github.com/wheels-dev/wheels/pull/1888)

**What changed**

The DI container's application-scope variable was renamed from `application.wirebox` (from the WireBox-era) to `application.wheelsdi` (in-house DI container, [#1883](https://github.com/wheels-dev/wheels/pull/1883)). Direct accesses to the old variable will fail.

**How to detect**

```bash
grep -rn 'application\.wirebox' app/ config/
```

**How to fix**

Prefer the `service()` global helper over direct scope access:

```cfm
// Before
var emailer = application.wirebox.getInstance("EmailService");

// After — recommended
var emailer = service("EmailService");

// After — only if you must touch the scope directly
var emailer = application.wheelsdi.getInstance("EmailService");
```

**Opt-out**

None — this is a straight rename. Apps rarely touch this directly in practice; the `service()` helper (available since 4.0) is the idiomatic replacement.

### Security-hardening defaults — quick reference

For operators coordinating a staged production rollout, the six default flips above reduce to one-line `set(...)` calls in `config/production/settings.cfm`. Here they are as a single reference block:

| Setting | 3.x default | 4.0 default | Opt-out |
|---|---|---|---|
| `allowOrigins` on `wheels.middleware.Cors()` | `*` | `[]` (deny-all) | Pass explicit origins array |
| `allowEnvironmentSwitchViaUrl` | `true` | `false` | `set(allowEnvironmentSwitchViaUrl=true)` + non-empty `reloadPassword` |
| HSTS emission on `wheels.middleware.SecurityHeaders()` | off | on (production) | Pass `hsts=false` |
| CSRF cookie SameSite | unset | `Lax` | `set(csrfCookieSameSite="None")` (HTTPS only) |
| `trustProxy` on `wheels.middleware.RateLimiter()` | `true` | `false` | Pass `trustProxy=true, proxyHopCount=N` |
| `proxyStrategy` on `wheels.middleware.RateLimiter()` | `first` | `last` | Pass `proxyStrategy="first"` |

If none of the affected middleware is active in your app, these changes have no effect on your upgrade.

## Legacy Compatibility Adapter — the soft landing

**PR:** [#2015](https://github.com/wheels-dev/wheels/pull/2015)

The Legacy Compatibility Adapter is a first-party package that detects deprecated patterns in your 3.x code and emits warnings (not errors) at dev time. It is designed as a low-friction bridge while you migrate.

### What it handles

- `extends="wheels.Test"` extensions — warns with guidance to use `wheels.WheelsTest`
- Legacy plugin patterns (`this.version = ...`, `this.dependency = ...`) — warns with guidance to move metadata to `package.json`
- Direct `application.wirebox.*` access — warns with guidance to use `service()` or `application.wheelsdi`
- Deprecated view helpers (`renderPage`, `renderPageToString`) — warns with guidance to use current helpers

### Installation

Copy the package from `packages/` into `vendor/`:

```bash
cp -r packages/legacyadapter vendor/legacyadapter
```

Then reload your app (`?reload=true&password=...`). The adapter scans your code on boot and prints a report of deprecated patterns with file locations and suggested fixes.

### What it does not help with

- **CLI renames.** The adapter does not scan shell scripts. `wheels snippets` in a script stays broken until you update it manually.
- **Security-hardening defaults.** The 6 default flips (CORS, HSTS, RateLimiter, etc.) are not reverted by the adapter — you must set them explicitly via config if you want the old behavior.
- **CSRF / CORS / HSTS / RateLimiter settings.** These are configured via `set(...)` in `config/settings.cfm` — the adapter does not touch middleware config.
- **Datasource / database config.** Out of scope.

### Deprecation path

The adapter is available through 4.x. Plan to address its warnings before upgrading to 5.0 — the warnings become errors in the next major version.

## Recommended (not required) migrations

These changes are not required for your app to run on 4.0, but adopting them unlocks 4.0 capabilities and removes patterns that are deprecated or suboptimal. Treat this as a menu — migrate at your own pace.

- **WheelsTest (replacing RocketUnit).** Rewrite test specs in BDD style using `describe()` / `it()` / `expect()`. See [Testing Your Application](../working-with-wheels/testing-your-application.md) for the migration mapping. Legacy RocketUnit specs continue to run.
- **Composable pagination helpers.** Replace monolithic `paginationLinks()` with `paginationNav()` or individual helpers (`firstPageLink`, `previousPageLink`, `pageNumberLinks`, `nextPageLink`, `lastPageLink`, `paginationInfo`). The old helper still works.
- **SecurityHeaders middleware.** Add `new wheels.middleware.SecurityHeaders()` to your middleware pipeline for Content-Security-Policy, HSTS, and Permissions-Policy headers in one shot.
- **Chainable query builder.** Migrate raw-WHERE queries to the fluent builder for injection safety: `.where("col", val).orderBy(col, dir).get()`.
- **Rate Limiting middleware.** Protect public-facing endpoints with `new wheels.middleware.RateLimiter()` — fixed-window, sliding-window, and token-bucket strategies, in-memory or database-backed.
- **Job worker daemon.** For apps with background work, `wheels jobs work/status/retry/purge/monitor` replaces ad-hoc scheduled tasks with a persistent, optimistic-locked queue.
- **Packages instead of plugins.** New first-party extensions should use the `packages/<name>/` convention with a `package.json` manifest. Legacy `plugins/` still load but are deprecated.
- **Expanded DI container.** Use `inject("service1, service2")` in controller `config()` and register services in `config/services.cfm`. Request-scoped services via `.asRequestScoped()`.
- **Route model binding.** Pass `binding=true` on `.resources()` to auto-resolve `params.key` into a model instance at dispatch. Eliminates boilerplate in every show/edit/update/destroy action.
- **Multi-tenancy.** If your app serves multiple tenants, per-request datasource switching is now in-core (no external package needed).

## Still stuck?

- [Wheels 4.0 Feature Audit](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md) — every PR merged since 3.0.0, grouped by subsystem
- [3.0 → 4.0 Comparison](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md) — row-by-row breakdown of what changed
- [Legacy Compatibility Adapter README](https://github.com/wheels-dev/wheels/blob/develop/packages/legacyadapter/README.md) — package docs
- [GitHub Discussions](https://github.com/wheels-dev/wheels/discussions) — community Q&A
- [GitHub Issues](https://github.com/wheels-dev/wheels/issues/new) — if you hit a genuine upgrade bug
