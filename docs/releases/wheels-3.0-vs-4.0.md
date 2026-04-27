# Wheels 3.0 → 4.0 — Ground Made Up

A category-by-category comparison showing how Wheels 4.0 closed framework-maturity gaps that existed in 3.0. Only **capabilities that changed** between the 3.0.0 stable release (2026-01-10) and 4.0 are shown here; rows that were already present and unchanged are omitted for clarity.

**Companion docs:**
- [docs/wheels-vs-frameworks.md](../wheels-vs-frameworks.md) — Wheels 4.0 parity comparison against Rails 8, Laravel 12, Django 5.
- [docs/releases/wheels-4.0-audit.md](wheels-4.0-audit.md) — full 260+ PR audit of everything shipped between 3.0.0 and 4.0.

**Sources:** CHANGELOG.md `[3.0.0]` section (what 3.0 shipped) + 4.0 feature audit (what 4.0 adds). "Formalized" means the feature may have had partial/undocumented precedent but became production-ready with tests and official docs in 4.0.

---

## At a glance

| | Count |
|---|---|
| New capabilities added | ~40 |
| Capabilities formalized (tests + docs, made official) | ~11 |
| Breaking defaults hardened | 7 |
| Security-hardening passes | 40+ PRs grouped by theme |
| Legacy surfaces removed | 4 |

---

## 1. ORM & Data Layer

| Capability | 3.0 | 4.0 | Delta |
|---|---|---|---|
| Chainable query builder | ~~undocumented / limited~~ | `where().orderBy().limit().get()` with `whereNull`, `whereBetween`, `whereIn`, `whereNotIn`, `orWhere` | **Formalized** ([#1922](https://github.com/wheels-dev/wheels/pull/1922)) |
| Named scopes | ~~undocumented~~ | `scope(name, where / handler)` — composable and chainable | **Formalized** ([#1920](https://github.com/wheels-dev/wheels/pull/1920)) |
| Enums | ~~absent~~ | `enum(property, values)` with auto-generated `is*()` checkers, auto-scopes, inclusion validation | **New** ([#1921](https://github.com/wheels-dev/wheels/pull/1921)) |
| Batch processing | ~~absent~~ | `findEach(batchSize, callback)` / `findInBatches` | **New** ([#1919](https://github.com/wheels-dev/wheels/pull/1919)) |
| Bulk insert/upsert | ~~absent~~ | `insertAll(records)` / `upsertAll(records, uniqueBy)` with per-adapter native UPSERT | **New** ([#2101](https://github.com/wheels-dev/wheels/pull/2101)) |
| Polymorphic associations | ~~absent~~ | `belongsTo(polymorphic=true)` + `hasMany(as=...)` | **New** ([#2104](https://github.com/wheels-dev/wheels/pull/2104)) |
| Advisory locks | ~~absent~~ | `withAdvisoryLock(name, callback)` with try/finally release | **New** ([#2103](https://github.com/wheels-dev/wheels/pull/2103)) |
| Pessimistic locking | ~~absent~~ | `.forUpdate()` on QueryBuilder for `SELECT ... FOR UPDATE` | **New** ([#2103](https://github.com/wheels-dev/wheels/pull/2103)) |
| CockroachDB support | ~~not supported~~ | Full adapter with `RETURNING` clause identity select, `unique_rowid()` PK | **New** ([#1876](https://github.com/wheels-dev/wheels/pull/1876), [#1986](https://github.com/wheels-dev/wheels/pull/1986), [#1993](https://github.com/wheels-dev/wheels/pull/1993), [#1999](https://github.com/wheels-dev/wheels/pull/1999)) |
| CockroachDB bulk-ops + locking test parity | ~~adapter present but bulk-ops / `.forUpdate()` failing in compat matrix~~ | All bulk-insert/upsert and pessimistic-locking tests pass on CockroachDB | **Fixed** ([#2206](https://github.com/wheels-dev/wheels/pull/2206)) |
| Reserved-word identifier quoting | ~~manual~~ | Automatic quoting of reserved words in table/column names | **New** ([#1874](https://github.com/wheels-dev/wheels/pull/1874)) |
| Strict unknown-column detection | ~~silently tolerant~~ | `set(throwOnColumnNotFound=true)` opt-in strictness | **New** ([#1938](https://github.com/wheels-dev/wheels/pull/1938)) |
| Calculated property SQL validation | ~~lazy (runtime error)~~ | Validated at model config time | **Hardened** ([#2067](https://github.com/wheels-dev/wheels/pull/2067)) |
| GROUP BY dot-notation | ~~parser gap~~ | Parity with ORDER BY dot-notation parser | **Hardened** ([#2084](https://github.com/wheels-dev/wheels/pull/2084)) |

## 2. Migrations

| Capability | 3.0 | 4.0 | Delta |
|---|---|---|---|
| Auto-migrations from models | ~~absent~~ | `AutoMigrator.diff(model)` compares properties vs DB schema; generates CFC with `up()`/`down()` | **New** ([#2102](https://github.com/wheels-dev/wheels/pull/2102)) |
| Rename detection in auto-migrations | ~~absent~~ | Explicit hints + heuristic suggestions (normalized-token + Levenshtein); new `wheels dbmigrate diff` CLI | **New** ([#2112](https://github.com/wheels-dev/wheels/pull/2112)) |
| Gap migration detection | ~~endpoint-only~~ | `migrateTo()` detects and runs previously-skipped migrations in range | **Fixed** ([#1928](https://github.com/wheels-dev/wheels/pull/1928)) |
| SQLite `changeColumn` | ~~unsupported~~ | Implemented via recreate-table pattern; SQLite migrations can now alter columns through the standard API | **New** ([#2218](https://github.com/wheels-dev/wheels/pull/2218)) |

## 3. Routing

| Capability | 3.0 | 4.0 | Delta |
|---|---|---|---|
| Route groups | ~~absent~~ | `group()` helper for shared path/middleware/constraints | **New** ([#1891](https://github.com/wheels-dev/wheels/pull/1891)) |
| Typed constraints | ~~regex-only~~ | `whereNumber`, `whereAlpha`, `whereUuid`, `whereSlug`, `whereIn` | **New** ([#1891](https://github.com/wheels-dev/wheels/pull/1891)) |
| API versioning | ~~manual~~ | `.version(1)` first-class versioning | **New** ([#1891](https://github.com/wheels-dev/wheels/pull/1891)) |
| Performance | ~~linear lookup~~ | Indexed lookup structure | **Hardened** ([#1891](https://github.com/wheels-dev/wheels/pull/1891)) |
| Route model binding | ~~absent~~ | `binding=true` on resource routes auto-resolves model instance; throws `Wheels.RecordNotFound` (404) on miss | **New** ([#1929](https://github.com/wheels-dev/wheels/pull/1929)) |

## 4. Controllers

| Capability | 3.0 | 4.0 | Delta |
|---|---|---|---|
| Path traversal hardening | ~~basic~~ | Hardened against encoded-bypass attempts | **Hardened** ([#2089](https://github.com/wheels-dev/wheels/pull/2089)) |
| CSRF key enforcement | ~~optional~~ | Required in production; fails fast on empty | **Breaking** ([#2079](https://github.com/wheels-dev/wheels/pull/2079)) |
| JWT algorithm validation | ~~trust the token header~~ | Algorithm claim validated; constant-time signature verification | **Hardened** ([#2079](https://github.com/wheels-dev/wheels/pull/2079), [#2086](https://github.com/wheels-dev/wheels/pull/2086)) |
| `renderText` / `renderWith` + subsequent partial rendering | ~~broken view lookup~~ | Fixed | **Fixed** ([#1991](https://github.com/wheels-dev/wheels/pull/1991)) |
| Session fixation on login | ~~session reused~~ | Session regenerated on login | **Hardened** ([#2034](https://github.com/wheels-dev/wheels/pull/2034)) |
| Open redirect in `redirectTo()` | ~~unguarded~~ | Blocked | **Hardened** ([#2038](https://github.com/wheels-dev/wheels/pull/2038)) |

## 5. Middleware pipeline

| Capability | 3.0 | 4.0 | Delta |
|---|---|---|---|
| Middleware pipeline (core) | ~~no first-class middleware layer~~ | Closure-based chain: global `set(middleware=[...])` or route-scoped `.scope(middleware=[...])`; implements `MiddlewareInterface` | **New** ([#1924](https://github.com/wheels-dev/wheels/pull/1924)) |
| Rate limiting | ~~absent~~ | `wheels.middleware.RateLimiter` with fixed-window, sliding-window, token-bucket strategies; memory or DB storage | **New** ([#1931](https://github.com/wheels-dev/wheels/pull/1931)) |
| Security headers | ~~absent~~ | `SecurityHeaders` middleware emits CSP, HSTS, Permissions-Policy | **New** ([#2036](https://github.com/wheels-dev/wheels/pull/2036)) |
| CORS default | ~~wildcard (`*`)~~ | Deny-all; must explicitly set `allowOrigins` | **Breaking** ([#2039](https://github.com/wheels-dev/wheels/pull/2039)) |
| HSTS default | ~~off~~ | On in production | **Breaking** ([#2081](https://github.com/wheels-dev/wheels/pull/2081)) |
| CSRF cookie SameSite | ~~unset~~ | Default set | **Breaking** ([#2035](https://github.com/wheels-dev/wheels/pull/2035)) |
| CSRF encryption key | ~~required pre-set~~ | Auto-generated if empty (apps should still set explicitly) | **Changed** ([#2054](https://github.com/wheels-dev/wheels/pull/2054)) |
| RateLimiter `trustProxy` default | — | `false` (was `true` during dev) | **Breaking** ([#2024](https://github.com/wheels-dev/wheels/pull/2024)) |
| RateLimiter proxy strategy default | — | `last` for security | **Breaking** ([#2088](https://github.com/wheels-dev/wheels/pull/2088)) |
| RateLimiter fail-closed on lock timeout | — | Now fails closed instead of open | **Hardened** ([#2069](https://github.com/wheels-dev/wheels/pull/2069)) |
| HSTS off-switch | ~~default-on in prod, no opt-out~~ | Explicit opt-out for environments behind TLS-terminating proxies that own HSTS | **New** ([#2195](https://github.com/wheels-dev/wheels/pull/2195)) |

## 6. Views & Templates

| Capability | 3.0 | 4.0 | Delta |
|---|---|---|---|
| Composable pagination helpers | ~~monolithic `paginationLinks()`~~ | `paginationNav()`, `paginationInfo()`, `firstPageLink()`, `previousPageLink()`, `pageNumberLinks()`, `nextPageLink()`, `lastPageLink()` (legacy retained) | **New** ([#1930](https://github.com/wheels-dev/wheels/pull/1930)) |
| XSS helpers | ~~partial / scattered~~ | `h()`, `hAttr()`, `stripTags()`, `stripLinks()` formalized in `view/sanitize.cfc` | **Formalized** ([#2097](https://github.com/wheels-dev/wheels/pull/2097)) |
| Partial path traversal | ~~`includePartial("../…")` unblocked~~ | Validated | **Hardened** ([#2071](https://github.com/wheels-dev/wheels/pull/2071)) |
| Pagination XSS via prependToPage / anchorDivider / appendToPage | ~~bypassable~~ | Sanitized; HTML-entity-encoding bypass closed | **Hardened** ([#2042](https://github.com/wheels-dev/wheels/pull/2042), [#2057](https://github.com/wheels-dev/wheels/pull/2057), [#2060](https://github.com/wheels-dev/wheels/pull/2060)) |
| Scaffolded-app landing page | ~~CFWheels-era splash~~ | Redesigned 4.0 congratulations page | **Refreshed** ([#2098](https://github.com/wheels-dev/wheels/pull/2098)) |
| Vite asset pipeline | ~~basic entry-point resolution~~ | Transitive `modulepreload` + CSS resolution for multi-entry Vite builds | **New** ([#2133](https://github.com/wheels-dev/wheels/pull/2133)) |

## 7. Dependency Injection

| Capability | 3.0 | 4.0 | Delta |
|---|---|---|---|
| DI framework | WireBox (Ortus) | In-house `wheelsdi` with same surface, lighter core | **Changed** ([#1883](https://github.com/wheels-dev/wheels/pull/1883), [#1888](https://github.com/wheels-dev/wheels/pull/1888)) |
| Request-scoped services | ~~absent~~ | `.asRequestScoped()` for per-request instances | **New** ([#1933](https://github.com/wheels-dev/wheels/pull/1933)) |
| `service()` global helper | ~~absent~~ | Global resolution anywhere | **New** ([#1933](https://github.com/wheels-dev/wheels/pull/1933)) |
| Declarative controller injection | ~~manual~~ | `inject()` in controller `config()` | **New** ([#1933](https://github.com/wheels-dev/wheels/pull/1933)) |
| Interface binding | ~~absent~~ | `bind()` for interface→implementation | **New** ([#1933](https://github.com/wheels-dev/wheels/pull/1933)) |
| `init()` auto-wiring | ~~absent~~ | Auto-resolves matching args | **New** ([#1933](https://github.com/wheels-dev/wheels/pull/1933)) |
| Service registration config file | ~~absent~~ | `config/services.cfm` | **New** ([#1933](https://github.com/wheels-dev/wheels/pull/1933)) |

## 8. Background Jobs & Real-time

| Capability | 3.0 | 4.0 | Delta |
|---|---|---|---|
| Job worker daemon | ~~absent~~ | `wheels jobs work/status/retry/purge/monitor` CLI with optimistic locking, timeout recovery, live dashboard | **New** ([#1934](https://github.com/wheels-dev/wheels/pull/1934)) |
| Configurable job backoff | ~~fixed~~ | `this.baseDelay` + `this.maxDelay` with `Min(baseDelay * 2^attempt, maxDelay)` | **New** ([#1934](https://github.com/wheels-dev/wheels/pull/1934)) |
| SSE pub/sub channels | ~~raw SSE only~~ | `subscribeToChannel()`, `publish()`, `poll()` with DatabaseAdapter + in-memory; `wheels_events` table | **New** ([#1940](https://github.com/wheels-dev/wheels/pull/1940)) |
| SSE newline injection | ~~possible~~ | Event-field sanitization | **Hardened** ([#2051](https://github.com/wheels-dev/wheels/pull/2051)) |

## 9. Testing

| Capability | 3.0 | 4.0 | Delta |
|---|---|---|---|
| HTTP integration test client | ~~absent~~ | `TestClient.visit()` with `.assertOk()`, `.assertSee()`, `.assertJson()`, `.assertJsonPath()`, cookie tracking, session support | **New** ([#2099](https://github.com/wheels-dev/wheels/pull/2099)) |
| Parallel test runner | ~~serial~~ | `ParallelRunner` with `cfthread` workers; round-robin bundle partition | **New** ([#2100](https://github.com/wheels-dev/wheels/pull/2100)) |
| Browser testing | ~~absent~~ | `BrowserTest` base class + ~60-method fluent DSL wrapping Playwright Java; `wheels browser setup` | **New** ([#2113](https://github.com/wheels-dev/wheels/pull/2113), [#2115](https://github.com/wheels-dev/wheels/pull/2115), [#2116](https://github.com/wheels-dev/wheels/pull/2116), [#2121](https://github.com/wheels-dev/wheels/pull/2121)) |
| Test base class namespace | `wheels.Test` (RocketUnit-era) | `wheels.WheelsTest` (BDD style); old retained during 4.0 | **Changed** ([#1889](https://github.com/wheels-dev/wheels/pull/1889)) |
| Primary test style | RocketUnit + TestBox co-existed | WheelsTest (BDD) only for new tests | **Deprecated** ([#1925](https://github.com/wheels-dev/wheels/pull/1925)) |
| Tests directory layout | `tests/specs/functions/` | `tests/specs/functional/` | **Renamed** ([#1872](https://github.com/wheels-dev/wheels/pull/1872)) |

## 10. CLI & LuCLI

| Capability | 3.0 | 4.0 | Delta |
|---|---|---|---|
| Dev inner-loop | Docker-required for tests | Zero-Docker LuCLI + SQLite (`tools/test-local.sh`) | **New** ([#2063](https://github.com/wheels-dev/wheels/pull/2063)) |
| CI engine matrix | 42 jobs across engines × DBs | 8 jobs via engine-grouped testing | **Streamlined** ([#1939](https://github.com/wheels-dev/wheels/pull/1939)) |
| CI pipeline | Docker-based | LuCLI-native Lucee 7 + SQLite | **Changed** ([#2032](https://github.com/wheels-dev/wheels/pull/2032)) |
| `wheels snippets` command | Existed | Renamed to `wheels generate snippets` | **Breaking** ([#1852](https://github.com/wheels-dev/wheels/pull/1852)) |
| LuCLI tier-1 commands | ~~absent~~ | Ported as a LuCLI module; WheelsTest suite | **New** ([#2092](https://github.com/wheels-dev/wheels/pull/2092), [#2093](https://github.com/wheels-dev/wheels/pull/2093)) |
| LuCLI phase 3-4 | ~~absent~~ | Scaffold, seed, in-process services | **New** ([#2065](https://github.com/wheels-dev/wheels/pull/2065)) |
| Scaffolded-app boot | ~~broken post-flatten~~ | Fixed | **Fixed** ([#2096](https://github.com/wheels-dev/wheels/pull/2096)) |
| Playwright CLI commands | ~~absent~~ | Config + test helpers | **New** ([#2013](https://github.com/wheels-dev/wheels/pull/2013), [#2021](https://github.com/wheels-dev/wheels/pull/2021)) |
| MCP endpoint | Existed | Hardened: auth gate, path-traversal guards, structural allowlist for commands, CSRNG session tokens, error suppression | **Hardened** ([#2049](https://github.com/wheels-dev/wheels/pull/2049), [#2050](https://github.com/wheels-dev/wheels/pull/2050), [#2062](https://github.com/wheels-dev/wheels/pull/2062), [#2083](https://github.com/wheels-dev/wheels/pull/2083), [#2087](https://github.com/wheels-dev/wheels/pull/2087)) |
| CLI shell-arg sanitization | ~~weak~~ | Structural allowlist; blocks command injection via db shell / deploy | **Hardened** ([#2040](https://github.com/wheels-dev/wheels/pull/2040), [#2068](https://github.com/wheels-dev/wheels/pull/2068), [#2073](https://github.com/wheels-dev/wheels/pull/2073)) |
| `wheels deploy` | ~~absent~~ | First-class Dockerized deploy via SSH; byte-compatible with Basecamp Kamal's `config/deploy.yml`, on-server conventions, and `kamal-proxy` for zero-downtime rollover | **New** ([#2187](https://github.com/wheels-dev/wheels/pull/2187)) |
| MCP surface | HTTP endpoint at `/wheels/mcp` (in-dev-server) | LuCLI stdio MCP (`wheels mcp wheels`) is canonical; HTTP endpoint deprecated with warning, scheduled for removal | **Changed** ([#2140](https://github.com/wheels-dev/wheels/pull/2140)) |

## 11. Package/Plugin Ecosystem

| Capability | 3.0 | 4.0 | Delta |
|---|---|---|---|
| First-party module system | Legacy `plugins/` folder | `packages/` → `vendor/` activation model via `PackageLoader` with per-package `package.json` and error isolation | **New** ([#1995](https://github.com/wheels-dev/wheels/pull/1995)) |
| Dependency graph | ~~absent~~ | Topological sort via `requires` / `replaces` / `suggests` | **New** ([#2017](https://github.com/wheels-dev/wheels/pull/2017)) |
| Lazy loading | ~~absent~~ | Opt-in per package | **New** ([#2017](https://github.com/wheels-dev/wheels/pull/2017)) |
| LuCLI module distribution | ~~N/A~~ | `wheels-cli-lucli` external repo | **New** ([#2018](https://github.com/wheels-dev/wheels/pull/2018)) |
| Legacy `plugins/` folder | Primary system | Deprecated; still works with warning | **Deprecated** ([#1995](https://github.com/wheels-dev/wheels/pull/1995)) |

## 12. Infrastructure & DevOps

| Capability | 3.0 | 4.0 | Delta |
|---|---|---|---|
| Multi-tenancy | ~~external package~~ | Per-request datasource switching in-core | **New** ([#1951](https://github.com/wheels-dev/wheels/pull/1951)) |
| Legacy compatibility adapter | ~~N/A~~ | 3.x → 4.0 soft-landing adapter | **New** ([#2015](https://github.com/wheels-dev/wheels/pull/2015)) |
| Engine adapters | Inline per-engine conditionals scattered | Dedicated adapter modules for Lucee, Adobe CF, BoxLang | **Refactored** ([#2016](https://github.com/wheels-dev/wheels/pull/2016)) |
| Interface contracts | ~~absent~~ | Interface-driven design for key extension points (middleware, strategies, adapters) | **New** ([#2014](https://github.com/wheels-dev/wheels/pull/2014)) |
| Environment switching URL | Default `true` in prod | Default `false` in prod; reload password required | **Breaking** ([#2076](https://github.com/wheels-dev/wheels/pull/2076), [#2082](https://github.com/wheels-dev/wheels/pull/2082)) |
| `allowEnvironmentSwitchViaUrl` | — | See above | **Breaking** |
| Reload password comparison | String equality | Hash-based, constant-time | **Hardened** ([#2022](https://github.com/wheels-dev/wheels/pull/2022), [#2077](https://github.com/wheels-dev/wheels/pull/2077)) |
| Debug panel | CFWheels-era | Redesigned (W-001, W-002) | **Refreshed** ([#2000](https://github.com/wheels-dev/wheels/pull/2000), [#2001](https://github.com/wheels-dev/wheels/pull/2001)) |
| `env()` helper | ~~absent~~ | Cross-scope environment-variable access | **New** ([#1985](https://github.com/wheels-dev/wheels/pull/1985)) |
| Pre-request logging | ~~absent~~ | Built in | **New** ([#1895](https://github.com/wheels-dev/wheels/pull/1895)) |
| Railo compatibility | Shimmed | Removed (not a target) | **Removed** ([#1987](https://github.com/wheels-dev/wheels/pull/1987)) |
| `server.cfc` | Present | Removed | **Removed** ([#1902](https://github.com/wheels-dev/wheels/pull/1902)) |
| Repo structure | Monorepo | Flattened to clone-and-run | **Refactored** ([#1885](https://github.com/wheels-dev/wheels/pull/1885)) |
| Version marker | `v3.0.0+N` build snapshots | `v4.0.0-SNAPSHOT+N` | **Changed** ([#2066](https://github.com/wheels-dev/wheels/pull/2066)) |

---

## Security posture — 40+ hardening PRs in 4.0

Not a per-capability table — the entire security surface was tightened. Summary of areas:

| Area | 3.0 baseline | 4.0 hardening |
|---|---|---|
| SQL injection | Basic parameter binding | QueryBuilder validation; `$quoteValue` escaping; scope handler sanitization; geography/WKT/index-hint guards; ORDER BY + enum scope + UPDATE include-param closures ([#2023](https://github.com/wheels-dev/wheels/pull/2023), [#2025](https://github.com/wheels-dev/wheels/pull/2025), [#2026](https://github.com/wheels-dev/wheels/pull/2026), [#2033](https://github.com/wheels-dev/wheels/pull/2033), [#2043](https://github.com/wheels-dev/wheels/pull/2043), [#2044](https://github.com/wheels-dev/wheels/pull/2044), [#2045](https://github.com/wheels-dev/wheels/pull/2045), [#2047](https://github.com/wheels-dev/wheels/pull/2047), [#2055](https://github.com/wheels-dev/wheels/pull/2055), [#2056](https://github.com/wheels-dev/wheels/pull/2056), [#2058](https://github.com/wheels-dev/wheels/pull/2058), [#2061](https://github.com/wheels-dev/wheels/pull/2061), [#2070](https://github.com/wheels-dev/wheels/pull/2070), [#2090](https://github.com/wheels-dev/wheels/pull/2090)) |
| Path traversal | Basic checks | Partial templates, `guideImage`, MCP docs, encoded-bypass attempts ([#2037](https://github.com/wheels-dev/wheels/pull/2037), [#2049](https://github.com/wheels-dev/wheels/pull/2049), [#2062](https://github.com/wheels-dev/wheels/pull/2062), [#2071](https://github.com/wheels-dev/wheels/pull/2071), [#2089](https://github.com/wheels-dev/wheels/pull/2089)) |
| Session / CSRF | Standard CSRF | SameSite cookie, auto-gen encryption key, session fixation prevention, open-redirect closure ([#2027](https://github.com/wheels-dev/wheels/pull/2027), [#2034](https://github.com/wheels-dev/wheels/pull/2034), [#2035](https://github.com/wheels-dev/wheels/pull/2035), [#2038](https://github.com/wheels-dev/wheels/pull/2038), [#2054](https://github.com/wheels-dev/wheels/pull/2054), [#2079](https://github.com/wheels-dev/wheels/pull/2079)) |
| Console / reload | String equality, no rate limit | POST-only, constant-time, rate-limited, IPv6-aware, hardened console REPL ([#2022](https://github.com/wheels-dev/wheels/pull/2022), [#2046](https://github.com/wheels-dev/wheels/pull/2046), [#2059](https://github.com/wheels-dev/wheels/pull/2059), [#2077](https://github.com/wheels-dev/wheels/pull/2077)) |
| CORS | Wildcard default | Deny-all default; rejects wildcard+credentials ([#2039](https://github.com/wheels-dev/wheels/pull/2039), [#2053](https://github.com/wheels-dev/wheels/pull/2053)) |
| Rate limiter | — | Memory-exhaustion + IP-spoofing + per-key exhaustion mitigations ([#2041](https://github.com/wheels-dev/wheels/pull/2041), [#2048](https://github.com/wheels-dev/wheels/pull/2048), [#2069](https://github.com/wheels-dev/wheels/pull/2069), [#2080](https://github.com/wheels-dev/wheels/pull/2080), [#2088](https://github.com/wheels-dev/wheels/pull/2088)) |
| SSE | Newline injection possible | Event-field sanitization ([#2051](https://github.com/wheels-dev/wheels/pull/2051)) |
| MCP | Open endpoint | Auth gate, input validation, structural allowlist, CSRNG tokens, error suppression, port validation ([#2050](https://github.com/wheels-dev/wheels/pull/2050), [#2072](https://github.com/wheels-dev/wheels/pull/2072), [#2074](https://github.com/wheels-dev/wheels/pull/2074), [#2075](https://github.com/wheels-dev/wheels/pull/2075), [#2083](https://github.com/wheels-dev/wheels/pull/2083), [#2087](https://github.com/wheels-dev/wheels/pull/2087)) |
| XSS (pagination) | Bypassable via HTML entities | Closed ([#2042](https://github.com/wheels-dev/wheels/pull/2042), [#2057](https://github.com/wheels-dev/wheels/pull/2057), [#2060](https://github.com/wheels-dev/wheels/pull/2060)) |
| JWT | Header-trusted algorithm | Algorithm claim validated; constant-time signature verification ([#2079](https://github.com/wheels-dev/wheels/pull/2079), [#2086](https://github.com/wheels-dev/wheels/pull/2086)) |
| CLI shell args | Quote-sensitive | Quote blocking + structural allowlist + db-shell command-injection guard ([#2040](https://github.com/wheels-dev/wheels/pull/2040), [#2068](https://github.com/wheels-dev/wheels/pull/2068), [#2073](https://github.com/wheels-dev/wheels/pull/2073)) |

Known limitations documented ([#2078](https://github.com/wheels-dev/wheels/pull/2078)).

---

## Peer-framework context — where 4.0 closed gaps

These are the rows where 3.0 trailed peer frameworks and 4.0 closed the gap. Reference the [parity comparison](../wheels-vs-frameworks.md) for full context.

| Capability | Rails 8 | Laravel 12 | Django 5 | Wheels 3.0 | Wheels 4.0 |
|---|---|---|---|---|---|
| Bulk insert/upsert | Yes (`insert_all` / `upsert_all`) | Yes (`upsert`) | Yes (`bulk_create`) | **No** | **Yes** |
| Polymorphic associations | Yes | Yes (`morphTo`) | Via contrib | **No** | **Yes** |
| Advisory locks | Via gem | No native | No native | **No** | **Yes** |
| Pessimistic locking | Yes (`.lock`) | Yes (`lockForUpdate`) | Yes (`select_for_update`) | **No** | **Yes** |
| Route model binding | Yes | Yes | No | **No** | **Yes** |
| First-class middleware pipeline | Yes (Rack) | Yes | Yes | **No** | **Yes** |
| Rate limiting | Yes (`Rack::Attack`-style via gem) | Yes (`RateLimiter`) | Via package | **No** | **Yes (built-in)** |
| Security headers (CSP/HSTS/Permissions) | Via gem / defaults | Via config | Via middleware | **No** | **Yes (built-in)** |
| Browser testing | Yes (Capybara) | Yes (Dusk) | Yes (Selenium) | **No** | **Yes (Playwright Java)** |
| Parallel test runner | Yes | Yes | Via package | **No** | **Yes** |
| HTTP integration test client | Yes | Yes | Yes | **No** | **Yes** |
| Request-scoped DI | Yes (via Rack middleware) | Yes (container scopes) | N/A (function-based) | **No** | **Yes** |
| Auto-migrations from models | No (manual) | No (manual) | Yes (`makemigrations`) | **No** | **Yes** |
| SSE pub/sub channels | Via gem (ActionCable is WebSocket) | Via Broadcasting | Via channels | **No** | **Yes (built-in)** |
| Multi-tenancy | Via gem | Via package | Via package | **External** | **Built-in** |

Where Wheels still trails 4.0 vs peers: ecosystem size, community size, bidirectional WebSocket (intentional non-goal — Wheels uses SSE as the cross-engine-uniform real-time primitive), asset-pipeline maturity (Vite integration is newer than Rails' / Laravel's Vite tooling).

---

## How to read this doc

- **New** — capability did not exist in 3.0; added in 4.0.
- **Formalized** — capability had partial or undocumented precedent; became production-ready with tests + docs in 4.0.
- **Hardened** — capability existed; security-tightened in 4.0.
- **Fixed** — bug that made the 3.0 capability unreliable; resolved in 4.0.
- **Breaking** — default behavior changed in a way that requires user action when upgrading (see the Upgrade Guide, forthcoming).
- **Deprecated** — 3.0 surface retained but marked for removal.
- **Removed** — 3.0 surface removed entirely.
- **Renamed / Refactored / Refreshed / Streamlined / Changed** — shape-change without functional parity loss.

For the complete PR list, see [docs/releases/wheels-4.0-audit.md](wheels-4.0-audit.md).
