---
status: skeleton
slot: post 2 (existing-user focus; publish in week 1 alongside lead)
target_length: 1400–1800 words
---

# Upgrading from Wheels 3.x

**Subhead / dek:** *Ten breaking changes, one Legacy Compatibility Adapter, and an honest map of what you'll have to touch.*

**Target audience:**
- Existing Wheels 3.x users planning a 4.0 upgrade
- Teams evaluating whether the upgrade fits a sprint or a quarter
- Ops/SRE reviewers who want to know which defaults changed in production

**Lead paragraph intent:**
- Most 3.x apps will upgrade with minimal code changes.
- But there are 10 specific places where behavior changed and you need to look.
- This post walks each of them with detect / fix / opt-out guidance.
- Links to the full upgrade guide for the complete reference.

## Sections

### 1. "The two-path upgrade"
- **Path A — clean upgrade:** fix the 10 breaking items directly. Recommended for apps that want to stay on the golden path.
- **Path B — Legacy Compatibility Adapter** ([#2015](https://github.com/wheels-dev/wheels/pull/2015)): enable it and most 3.x code continues to work while you migrate on your own schedule.
- Frame the post around Path A with LCA callouts.

### 2. The 10 breaking items (the heart of the post)

Use a consistent 4-part micro-template per item: **What changed / How to detect / How to fix / Opt-out.**

1. **CORS default: wildcard → deny-all** ([#2039](https://github.com/wheels-dev/wheels/pull/2039)).
2. **HSTS default-on in production** ([#2081](https://github.com/wheels-dev/wheels/pull/2081)).
3. **CSRF key required in production; JWT algorithm validation** ([#2079](https://github.com/wheels-dev/wheels/pull/2079)).
4. **`allowEnvironmentSwitchViaUrl` default false in prod; reload password required** ([#2076](https://github.com/wheels-dev/wheels/pull/2076), [#2082](https://github.com/wheels-dev/wheels/pull/2082)).
5. **`wheels snippets` → `wheels generate snippets`** ([#1852](https://github.com/wheels-dev/wheels/pull/1852)).
6. **Test base class: `wheels.Test` → `wheels.WheelsTest`** ([#1889](https://github.com/wheels-dev/wheels/pull/1889)).
7. **Tests directory rename: `tests/specs/functions/` → `tests/specs/functional/`** ([#1872](https://github.com/wheels-dev/wheels/pull/1872)).
8. **Legacy RocketUnit removed from core** ([#1925](https://github.com/wheels-dev/wheels/pull/1925)) — existing RocketUnit specs still run; WheelsTest BDD mandatory for new.
9. **RateLimiter `trustProxy` default false + proxy strategy `last`** ([#2024](https://github.com/wheels-dev/wheels/pull/2024), [#2088](https://github.com/wheels-dev/wheels/pull/2088)).
10. **CFWheels → Wheels rebrand** ([#2064](https://github.com/wheels-dev/wheels/pull/2064)) — callers referencing old namespaces must update; most user code unaffected.

### 3. The Legacy Compatibility Adapter
- One-flag opt-in; documented surface; intended as a bridge, not a permanent layer.
- When to use it (inherited monolith with unclear test coverage) vs when not (new code, small apps).
- Link to LCA docs.

### 4. Deprecations to address (not breakers, but don't sleep on them)
- **Legacy `plugins/` folder** ([#1995](https://github.com/wheels-dev/wheels/pull/1995)) — still works, warns on load. Plan a migration to `packages/` → `vendor/`.
- **Monolithic `paginationLinks()`** ([#1930](https://github.com/wheels-dev/wheels/pull/1930)) — retained for back-compat; new code should use `paginationNav()` or the composable helpers.
- **`wheels.Test` extension** — retained; new specs extend `wheels.WheelsTest`.

### 5. Recommended (not required) migrations
- **Adopt the middleware pipeline** ([#1924](https://github.com/wheels-dev/wheels/pull/1924)) for cross-cutting concerns previously done with filters/plugins.
- **Turn on route model binding** ([#1929](https://github.com/wheels-dev/wheels/pull/1929)) — cuts boilerplate `findByKey()` in every `show`/`edit`/`update`.
- **Use the chainable QueryBuilder** for any place you were concatenating WHERE strings ([#1922](https://github.com/wheels-dev/wheels/pull/1922)).
- **Adopt WheelsTest BDD** for new tests, even if old specs stay on RocketUnit/xUnit.
- **Replace Redis-backed job queues with the built-in job worker** ([#1934](https://github.com/wheels-dev/wheels/pull/1934)) — tease post #4.

### 6. Testing your upgrade
- **Enable the test client** ([#2099](https://github.com/wheels-dev/wheels/pull/2099)) — write a smoke test that hits every top-level route and asserts 200/redirect.
- **Run the parallel runner** ([#2100](https://github.com/wheels-dev/wheels/pull/2100)) — in 4.0 you should expect a noticeable speed-up regardless of upgrade path.
- **Browser-test your critical-path flow** ([#2113](https://github.com/wheels-dev/wheels/pull/2113)) — login → do-the-thing → log out. 15 minutes of setup, lifetime of regression coverage.

### 7. Production deploy checklist
- Set `allowOrigins` explicitly (not `*`).
- Set a non-empty CSRF encryption key.
- Set a non-empty reload password.
- If behind a proxy/load balancer, configure RateLimiter `trustProxy` + proxy strategy intentionally.
- Confirm HSTS is what you want (max-age, includeSubDomains).
- Run the framework's own test suite against your DB adapter if you've extended it.

## Code / config snippets to include (pick 3)

```cfm
// Before 4.0: wildcard CORS, nothing to configure.
// After 4.0: explicit allowOrigins required.
set(middleware = [
    new wheels.middleware.Cors(allowOrigins="https://myapp.com,https://admin.myapp.com")
]);
```

```cfm
// Before: legacy test base
component extends="wheels.Test" { ... }

// After: WheelsTest BDD
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

```cfm
// Opt-in soft landing: Legacy Compatibility Adapter
// config/settings.cfm
set(legacyCompatibilityAdapter=true);
```

## Suggested visuals

- **Lead table:** compact 10-row before/after grid — one line per breaking item ("CORS: `*` → deny-all", "HSTS: off → on in prod", etc.). Screenshot-friendly; makes the scope tangible.
- **Decision tree:** "Should you enable the LCA?" — 3 yes/no nodes, terminal recommendations. Two-color inline SVG.

## Outro / CTA

- "Most upgrades take an afternoon, not a sprint."
- Point to the upgrade guide for the canonical reference.
- Invite issues with the `upgrade` label for stuck teams.
- Mention [#2131](https://github.com/wheels-dev/wheels/issues/2131) for GA tag status.

## Citations (must link in final post)

- [Upgrade guide](https://github.com/wheels-dev/wheels/blob/develop/docs/src/introduction/upgrading-to-4.0.md)
- [3.0 → 4.0 comparison](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md) (for the Breaking defaults hardened rows)
- [Feature audit — Breaking changes section](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md#breaking-changes)
- Legacy Compatibility Adapter PR [#2015](https://github.com/wheels-dev/wheels/pull/2015)
- All 10 Breaking PRs linked inline in section 2
