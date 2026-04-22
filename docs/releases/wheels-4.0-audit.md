# Wheels 4.0 — Full Feature Audit

**Purpose:** Canonical inventory of every user-visible change merged into `develop` between the 3.0.0 stable release and today. Source of truth for blog posts, release notes, and the 3.0 → 4.0 comparison narrative.

**Baseline:** `v3.0.0+33` — Wheels 3.0.0 stable release, tagged 2026-01-10 ([CHANGELOG entry](../../CHANGELOG.md)).
**Audit range:** 2026-01-12 → 2026-04-16 (approx. 14 weeks).
**Audit date:** 2026-04-16.

## Methodology

1. Extracted all PRs merged to `develop` in the window via `gh pr list --base develop --state merged --search "merged:>=2026-01-10" --limit 250`.
2. Cross-referenced against `git log --merges v3.0.0+33..origin/develop`.
3. Compared against the `[Unreleased]` section of [CHANGELOG.md](../../CHANGELOG.md).
4. Bucketed each PR by subsystem; dedupe'd multi-PR features into single entries with all PR links.
5. Flagged CHANGELOG gaps — the `[Unreleased]` section captured ~10 items; ~60 additional user-visible changes were not recorded.

## Summary stats

- **Total merged PRs:** 185
- **Distinct user-visible features / changes:** ~70 (after grouping multi-PR features)
- **Security-hardening PRs:** 40+ (see Security Hardening section)
- **Breaking changes:** 7 (see Breaking Changes section)
- **Contributors:** @bpamiri (Peter Amiri), @zainforbjs, @chapmandu, @mlibbe, plus Dependabot
- **CHANGELOG coverage gap:** `[Unreleased]` missed ~60 user-visible items — blog + CHANGELOG catch-up work recommended.

---

## Features by category

### 1. ORM & Data Layer

**New capabilities:**

- **Chainable query builder** (#1922) — `where()`, `orWhere()`, `whereNull()`, `whereBetween()`, `whereIn()`, `orderBy()`, `limit()`, `get()`. Injection-safe fluent queries as an alternative to raw WHERE strings. Composes with scopes.
- **Enum support** (#1921) — `enum(property="status", values="draft,published,archived")` auto-generates `isDraft()`/`isPublished()` checkers, `draft()`/`published()` scopes, and inclusion validation. Supports ordered lists and value maps.
- **Query scopes** (#1920) — `scope(name="active", where="...")` and dynamic scope handlers. Composable and chainable: `model("User").active().recent().findAll()`.
- **Batch processing** (#1919) — `findEach(batchSize, callback)` and `findInBatches()` for memory-efficient iteration. Works with scopes.
- **Bulk insert / upsert** (#2101) — `insertAll(records)` and `upsertAll(records, uniqueBy)` with per-adapter native UPSERT syntax (MySQL, PostgreSQL, SQL Server, SQLite, H2, CockroachDB, Oracle).
- **Polymorphic associations** (#2104) — `belongsTo(polymorphic=true)` and `hasMany(as=)` with type-discriminator JOINs.
- **Advisory locks + pessimistic locking** (#2103) — `withAdvisoryLock(name, callback)` with try/finally release; `.forUpdate()` on QueryBuilder for `SELECT ... FOR UPDATE`.
- **CockroachDB adapter** (#1876, #1986, #1993, #1999) — seventh supported database. Full SQL generation, `RETURNING` clause identity select, `unique_rowid()` PK convention, test matrix inclusion.
- **`throwOnColumnNotFound` setting** (#1938) — opt-in strictness for unknown columns in WHERE clauses (helps catch typos at dev time).

**Hardening / fixes:**

- **SQL identifier quoting for reserved words** (#1874) — prevents reserved-word conflicts in table/column names.
- **Calculated-property SQL validated at config time** (#2067) — catches broken SQL before request time.
- **GROUP BY validation with dot-notation** (#2084) — parity with ORDER BY parser.

### 2. Migrations

- **Auto-migrations from models** (#2102) — `AutoMigrator.diff(modelName)` compares model property definitions against the current DB schema and returns add/remove/change column lists. `generateMigrationCFC()` produces a migration CFC with `up()`/`down()`.
- **Auto-migration rename detection** (#2112) — explicit hints (`renames={"old": "new"}`) plus heuristic suggestions (normalized-token + Levenshtein, configurable threshold). New `wheels dbmigrate diff` CLI command and MCP `wheels_migrate(action="diff")`.
- **Gap migration detection** (#1928) — `migrateTo()` now detects and runs any previously-skipped migrations in the target range, not just the endpoint.

### 3. Routing

- **Router modernization** (#1891 / #1894) — `group()` helper for route grouping, typed constraints (`whereNumber`, `whereAlpha`, `whereUuid`, `whereSlug`, `whereIn`), API versioning via `.version(1)`, performance indexes for faster route lookup.
- **Route model binding** (#1929) — `binding=true` on resource routes or `set(routeModelBinding=true)` globally. Auto-resolves `params.key` into `params.<modelName>` before the controller action runs. Throws `Wheels.RecordNotFound` (404) on miss.

### 4. Controllers

- **View lookup fix after renderText/renderWith** (#1991) — fixes #1961; prevents `renderWith` from breaking subsequent view lookups.
- **CSRF key enforced in production + JWT algorithm validation** (#2079) — fails fast in production when CSRF key is empty; validates JWT `alg` claim to prevent algorithm-confusion attacks.
- **Path traversal check hardened against encoded bypass** (#2089).

### 5. Views & Templates

- **Composable pagination view helpers** (#1930) — `paginationNav()`, `paginationInfo()`, `firstPageLink()`, `previousPageLink()`, `pageNumberLinks()`, `nextPageLink()`, `lastPageLink()`. Replaces monolithic `paginationLinks()` as the idiomatic pattern for building custom pagination UIs. Old helper retained for back-compat.
- **Architecture hardening: XSS helpers, error hooks, interface verification** (#2097) — adds `h()`, `hAttr()`, `stripTags()`, `stripLinks()` formally; interface verification ensures helper contracts; error-rendering hooks.
- **Redesigned congratulations page** (#2098) — new landing page for `wheels new` scaffolded apps.
- **Path traversal validation in partial rendering** (#2071) — blocks `includePartial("../../secrets.cfm")`-style attacks.
- **XSS pagination hardening** (#2042, #2057, #2060) — sanitize `prependToPage`, `anchorDivider`, `appendToPage`; prevent HTML-entity-encoding bypasses.

### 6. Middleware pipeline

- **Middleware pipeline** (#1924) — core framework: closure-based middleware chain, runs at dispatch level before controller instantiation, route-scoped via `.scope(middleware=[...])`, global via `set(middleware=[...])`. Implements `MiddlewareInterface` (`handle(request, next)`).
- **Rate limiting middleware** (#1931) — `wheels.middleware.RateLimiter` with three strategies: `fixedWindow`, `slidingWindow`, `tokenBucket`. Storage backends: in-memory (default) and database-backed (auto-creates `wheels_rate_limits` table). Emits `X-RateLimit-*` headers and `Retry-After` on 429.
- **CORS middleware** (built into middleware pipeline) — hardened defaults (deny-all instead of wildcard, #2039), rejects wildcard origin with credentials (#2053).
- **Security headers middleware** — CSP, HSTS, Permissions-Policy (#2036); HSTS default-on in production (#2081).
- **CSRF cookie hardening** (#2027, #2035, #2054, #2079) — SameSite attribute, auto-generated encryption key when empty, key required in production.
- **Session fixation prevention** (#2034) — regenerate session on login.
- **Open-redirect prevention in `redirectTo()`** (#2038).

**Rate-limiter hardening follow-ups:** #2024 (trustProxy default false), #2041 (memory exhaustion + IP spoofing), #2048 (per-key exhaustion), #2069 (fail-closed on lock timeout), #2080 (cleanup throttle, key length limit), #2088 (proxy strategy default = last).

### 7. Background jobs

- **Job worker daemon** (#1934) — `wheels jobs work/status/retry/purge/monitor` CLI commands. Persistent background job processing with optimistic locking, timeout recovery, live dashboard. Configurable exponential backoff via `this.baseDelay` and `this.maxDelay` in job `config()`. Auto-creates `wheels_jobs` table.

### 8. Real-time / SSE

- **Pub/sub channels for SSE** (#1940) — channel subscription model on top of SSE: publish to channel → all subscribers receive events. Database-backed event persistence with `wheels_events` table. `subscribeToChannel()`, `publish()`, `poll()`, cleanup of old events. Dual implementation (DatabaseAdapter + in-memory).
- **SSE newline injection hardening** (#2051) — sanitizes event field and data values to prevent injection into the SSE stream.

### 9. Multi-tenancy

- **Multi-tenant support** (#1951) — per-request datasource switching. Built-in (no external package). Supports tenant-aware background jobs natively.

### 10. DI Container

- **Expanded DI container** (#1933) — `asRequestScoped()` for per-request service instances, global `service()` helper, declarative `inject()` in controller `config()`, `bind()` interface binding, auto-wiring of `init()` arguments from registered names, `config/services.cfm` for service registration at app startup. Scope support: transient, singleton, request-scoped.

### 11. Package system

- **PackageLoader + `packages/` → `vendor/` model** (#1995) — optional first-party modules ship in `packages/`, activated by copying to `vendor/`. Auto-discovered on startup via `PackageLoader.cfc`. Each package has a `package.json` with `provides.mixins` targets (`controller`, `view`, `model`, `global`, `none`). Per-package error isolation (a broken package is logged and skipped; app continues).
- **Module system with dependency graph** (#2017) — dependency resolution via topological sort (`requires`/`replaces`/`suggests`), lazy loading opt-in per package.
- **Plugin component paths logged on load** (#2085) — improves debugging.
- Deprecation path for legacy `plugins/` folder (still works, warns on load).

### 12. Testing infrastructure

- **HTTP test client (`TestClient`)** (#2099) — fluent integration-testing DSL: `TestClient.visit("/users").assertOk().assertSee("John")`. Assertions for status codes, body content (`assertSee`/`assertDontSee`/`assertSeeInOrder`), JSON responses (`assertJson`/`assertJsonPath` with dot notation), redirects, headers, cookies (tracked across requests for session support).
- **Parallel test runner (`ParallelRunner`)** (#2100) — discovers test bundles, partitions them across N workers via round-robin, fires parallel HTTP requests through `cfthread`, aggregates JSON results. Configurable worker count and timeout.
- **Browser testing via Playwright Java** (#2113, #2115, #2116, #2121, #2122) — `BrowserTest` base class with fluent DSL wrapping Playwright Java. Methods: navigation (`visit`, `visitRoute`, `back`, `forward`), interaction (`click`, `fill`, `type`, `select`, `check`, `attach`, `dragAndDrop`), keyboard (`keys`, `pressEnter`, `pressTab`, `pressEscape`), waiting (`waitFor`, `waitForText`, `waitForUrl`), scoping (`within`), cookies (`setCookie`, `cookie`, `clearCookies`), auth (`loginAs`, `logout`), dialogs (`acceptDialog`, `dismissDialog`, `dialogMessage`), viewport (`resize`, `resizeToMobile`, `resizeToTablet`, `resizeToDesktop`), script (`script`, `pause`), screenshots, full assertion suite. `wheels browser:install` downloads JARs + Chromium (~370MB). CI workflow runs browser specs across pr.yml and snapshot.yml.
- **`testbox` → `wheelstest` namespace rename** (#1889) — `extends="wheels.WheelsTest"` replaces `extends="wheels.Test"` (legacy still works during 4.0).
- **`tests/specs/functions/` → `tests/specs/functional/` rename** (#1872).
- **Legacy RocketUnit removal** (#1925) — WheelsTest (BDD syntax) is the only supported style for new tests in 4.0. Existing RocketUnit specs continue to run; no new ones.
- **RocketUnit wildcard filter** (#1857) — improves test selection for the remaining legacy specs.

### 13. CLI (Wheels CLI) + LuCLI

**CLI UX & generators:**

- **`wheels snippets` → `wheels generate snippets` command rename** (#1852) — breaking; aligns with the "code snippets" concept.
- **Scaffold, seed, in-process services** (#2065) — Phase 3-4 of LuCLI migration. In-process service invocation removes external process overhead for generators.
- **Playwright CLI commands** (#2013, #2021) — configuration, test helpers.
- **Oracle admin privilege check for DB creation** (#1843).
- **Docker command status messages** (#1844, #1897, #2095).

**LuCLI (strategic direction — zero-Docker, faster inner loop):**

- **Phase 2: local testing without Docker** (#2063) — `tools/test-local.sh` runs the test suite on LuCLI + SQLite. ~60s for full core suite.
- **Phase 2 service layer, generators, MCP annotations** (#1941).
- **LuCLI-native CI pipeline** (#2032) — Lucee 7 + SQLite in CI, matching local inner loop.
- **LuCLI module distribution via wheels-cli-lucli repo** (#2018).
- **Tier 1 commands ported to LuCLI** (#2092) + WheelsTest test suite for the module (#2093).

**CLI security hardening:**

- **Shell argument sanitization in deploy commands** (#2068, #2073).
- **Command injection prevention in db shell** (#2040).
- **MCP hardening:** path traversal (#2049, #2062), auth gate + input validation (#2050), error suppression (#2072), port validation (#2075), structural allowlist (#2083), CSRNG session tokens (#2087).

### 14. MCP integration

- **`/wheels/mcp` endpoint** — Wheels tools exposed to AI coding assistants. Pre-existing but substantially hardened in 4.0 (see CLI security hardening section).
- **Documentation-reader path traversal hardening** (#2049).
- **Auth gate and input validation** (#2050).

### 15. Engine adapters & cross-engine compatibility

- **Engine adapter modules** (#2016) — W-004 project. Lucee, Adobe CF, BoxLang each get a dedicated adapter module encapsulating engine-specific behavior (struct member function idioms, scope handling, closure semantics).
- **Engine adapter startup + cross-engine compatibility fixes** (#2028, #2030, #2031).
- **Railo compatibility workaround removed** (#1987) — Railo is no longer a target; cleanup.
- **Adobe Oracle coercion** — removed (#2030) then restored (#2031) — net: preserved.
- **Malformed percent-encoding crash fix** (#2006) — `$canonicalize` catches `IllegalArgumentException` instead of propagating.

### 16. Interface-driven design

- **Interface contracts** (#2014) — W-005 project. Formal contracts for key framework extension points. Middleware, strategies, adapters all have verifiable interfaces.

### 17. Legacy compatibility

- **Legacy compatibility adapter for 3.x → 4.0 migration** (#2015) — W-003 project. Soft-landing for apps upgrading from 3.x.

### 18. Configuration & developer experience

- **`env()` helper** (#1985) — cross-scope environment variable access.
- **Pre-request logging** (#1895).
- **Debug panel redesign** (#2000, #2001) — W-001, W-002. Modernized dev-panel UI.
- **Congratulations page redesign** (#2098) — W landing.
- **`allowEnvironmentSwitchViaUrl` defaults to false in production** (#2076).
- **Non-empty reload password required for env switching** (#2082).

### 19. Security hardening (cross-cutting)

Beyond the middleware and controller items above, 40+ PRs hardened security across SQL generation, path handling, CORS/CSRF, console endpoints, and MCP:

**SQL injection:**
- QueryBuilder property + operator validation (#2025).
- ORDER BY clause (#2026).
- `$quoteValue` single-quote escaping (#2033).
- Scope handler argument sanitization (#2043, #2045, #2056, #2061, #2070, #2090).
- Geography property detection (#2044).
- WKT handling (#2055).
- Enum scope WHERE clauses (#2023, #2056, #2070).
- `include` param in UPDATE queries (#2047).
- Index hints via `$indexHint` (#2058).

**Path traversal:**
- Partial template rendering (#2071).
- `guideImage` endpoint (#2037).
- MCP documentation reader (#2049).
- Encoded-bypass attempts (#2089).

**Console / reload:**
- `consoleeval` hardened: POST-only, robust IPv6, Content-Type checks (#2059), constant-time comparison and rate-limiting on reload (#2077), hash-based password comparison (#2022).

**Documentation:**
- Known security limitations documented (#2078).

### 20. Internal refactors & infrastructure

- **WireBox replaced + TestBox replaced + init decomposed** (#1883) — W rim modernization.
- **`application.wirebox` → `application.wheelsdi`** (#1888).
- **Monorepo flattened to clone-and-run structure** (#1885).
- **CFWheels → Wheels rebrand in active code/metadata** (#2064).
- **Version bump to 4.0.0-SNAPSHOT** (#2066).
- **AI infrastructure modernized: 15→5 skills, lean CLAUDE.md, focused commands** (#1871).

### 21. CI / tooling

- **Engine-grouped testing (42 jobs → 8)** (#1939) — major CI speedup.
- **LuCLI-native Lucee 7 + SQLite CI pipeline** (#2032).
- **Focused Lucee 7 + MySQL test workflow** (#1887).
- **Workflow results committed back to `claude/*` branches** (#1892).
- **Auto-label job fails gracefully on fork PRs** (#2007).
- **Claude Code runtime artifacts ignored** (#2111).
- **PR template and Definition of Done** (#1918).

### 22. Dependencies

Dependabot bumps (dev/CI infrastructure — not user-facing): #1898 (basic-ftp), #1899 (rollup), #1900 (minimatch), #1992 (picomatch), #2020 (vite), #2091 (basic-ftp).

---

## Breaking changes

Items that require migration notes for users upgrading from 3.x. These should have top billing in the upgrade guide and blog posts.

1. **`wheels snippets` command renamed to `wheels generate snippets`** (#1852) — CLI breaking. Scripts/aliases calling `wheels snippets` must update.
2. **CFWheels → Wheels rebrand in active code** (#2064) — callers referencing old namespaces (e.g., `cfwheels.*`) must update. Most user code unaffected; internal reference.
3. **`testbox` → `wheelstest` namespace** (#1889) — test CFCs should extend `wheels.WheelsTest` (old `wheels.Test` continues to work but is legacy).
4. **Tests directory `tests/specs/functions/` → `tests/specs/functional/`** (#1872).
5. **Legacy RocketUnit removed from core** (#1925) — existing RocketUnit specs in app repos continue to run; WheelsTest (BDD syntax) is mandatory for new tests.
6. **CORS default: wildcard → deny-all** (#2039) — apps relying on the wildcard default must explicitly configure `allowOrigins`.
7. **`allowEnvironmentSwitchViaUrl` default: true → false in production** (#2076) — and reload password must be non-empty for env switching in production (#2082).

Additionally, **security-hardening defaults** (rate limiter `trustProxy=false`, HSTS default-on in production, CSP/HSTS/Permissions-Policy emitted by SecurityHeaders, CSRF cookie SameSite) may produce visible behavior differences; compatibility-oriented apps may need to tune settings.

The **Legacy compatibility adapter** (#2015) softens many of these for upgrade.

---

## CHANGELOG coverage gap

The `[Unreleased]` section in [CHANGELOG.md](../../CHANGELOG.md) currently has 10 Added bullets and no Changed/Deprecated/Removed/Fixed/Security subsections. The following significant user-visible items should be added:

**Missing from Added:**
- Middleware pipeline (#1924)
- Router modernization (#1891)
- CockroachDB adapter (#1876 + follow-ups)
- Bulk insert/upsert (#2101)
- Polymorphic associations (#2104)
- Advisory locks + SELECT FOR UPDATE (#2103)
- Auto-migrations + rename detection (#2102, #2112)
- Multi-tenant support (#1951)
- HTTP test client (#2099)
- Parallel test runner (#2100)
- Browser testing (Playwright Java) (#2113 + series)
- Pub/sub channels for SSE (#1940)
- Package system / PackageLoader (#1995)
- Module system with dependency graph (#2017)
- LuCLI module distribution (#2018)
- Legacy compatibility adapter (#2015)
- Interface-driven design contracts (#2014)
- Engine adapter modules (#2016)
- XSS helpers / hAttr / stripTags formalized (#2097)
- Security headers middleware (CSP/HSTS/Permissions-Policy) (#2036)
- Debug panel redesign (#2000, #2001)
- `env()` helper (#1985)
- `throwOnColumnNotFound` setting (#1938)

**Missing Changed / Breaking:** see Breaking Changes section above.

**Missing Security:** the 40+ security-hardening PRs deserve a dedicated Security section under 4.0 — see section 19.

**Missing Fixed:** `renderText/renderWith` view lookup (#1991), gap migrations (#1928), Adobe Oracle coercion (#2030/#2031), many others.

Recommended: before 4.0 GA, do a CHANGELOG catch-up PR that adds the missing items above under the appropriate Keep-a-Changelog subsections, with PR links.

---

## Themes for blog / release communications

When blog posts are drafted on top of this audit, these are the natural story arcs:

1. **"Wheels 4.0: the release that closes the framework-maturity gap"** — lead with bulk ops, polymorphic assocs, advisory locks, auto-migrations, browser testing. Pair with updated [docs/wheels-vs-frameworks.md](../wheels-vs-frameworks.md).
2. **"Background jobs without Redis"** — the job worker daemon is genuinely differentiated (zero-dependency, DB-backed, multi-tenant aware). Comparable articles in Rails/Laravel/Django presuppose Redis or Celery.
3. **"Security hardening in 4.0"** — 40+ security PRs deserve a dedicated post. Frames Wheels as a secure-by-default framework.
4. **"From WireBox to wheelsdi: the framework gets leaner"** — the internal rim modernization story (decomposed init, WireBox/TestBox replacement, engine adapter modules).
5. **"LuCLI and the zero-Docker developer experience"** — LuCLI adoption arc, phase 1 → phase 4, CI pipeline migration.
6. **"Upgrading from Wheels 3.x"** — practical migration guide centered on the Breaking Changes list and the Legacy compatibility adapter (#2015).
7. **"Testing in Wheels 4.0"** — HTTP test client + parallel runner + browser testing + BDD-only posture.
8. **"Multi-tenancy built in"** — Wheels is now one of the few frameworks with first-class per-request datasource switching.

---

## Follow-ups discovered during audit

- **CHANGELOG catch-up PR** — add the missing items above under Keep-a-Changelog sections. High priority before GA.
- **Vite pipeline maturity** — known gap (see `docs/wheels-vs-frameworks.md` "Where Wheels Trails"). Candidate for a 4.0.x or 4.1 follow-on spec. Brainstormed 2026-04-16; deferred pending this audit.
- **`stripTags` / `stripLinks` encoding default** — out of scope for the view auto-encoding discussion; candidate for separate review.
- **3.0-vs-4.0 comparison doc** — net-new document to produce now that this audit exists; show row-by-row how the framework comparison shifted between 3.0 and 4.0.
- **Missing release tags on develop** — no `v3.0.0` clean tag; only `v3.0.0+N` build markers. A clean `v4.0.0` tag at GA time would be clearer.
- **PR #1891 / #1894 appear to be duplicates** (identical titles, same-day) — verify whether both are intentional or whether one should have been closed.
