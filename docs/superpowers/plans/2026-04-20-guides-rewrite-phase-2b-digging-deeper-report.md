# Guides Rewrite — Phase 2b-Advanced (Digging Deeper) Completion Report

**Date:** 2026-04-20
**Branch:** `claude/lucid-thompson-b8c121` (draft PR [#2169](https://github.com/wheels-dev/wheels/pull/2169))
**Spec:** [../specs/2026-04-18-guides-rewrite-v4-design.md](../specs/2026-04-18-guides-rewrite-v4-design.md)
**Plan:** [./2026-04-20-guides-rewrite-phase-2b-digging-deeper.md](./2026-04-20-guides-rewrite-phase-2b-digging-deeper.md)
**Prior phase:** [Phase 2a report](./2026-04-20-guides-rewrite-phase-2a-report.md)

## Shipped

**17 commits** on top of Phase 2a head `0882d169c` — 14 content pages + 3 integration commits.

| SHA | What |
|-----|------|
| `08de789b1` | digging-deeper/authentication-patterns — Session/JWT/Token strategies |
| `8fde7a5ae` | digging-deeper/authorization-and-filters — filter + authz patterns |
| `dc58f9a98` | digging-deeper/background-jobs — queue/worker/retries |
| `1661a4778` | digging-deeper/caching — action + fragment + view + query + programmatic |
| `0dfc2dc12` | digging-deeper/sending-email — rewrite (Phase 0 sample was mostly fabricated API) |
| `554250bcf` | digging-deeper/file-uploads-and-downloads — `sendFile` + Lucee-native uploads |
| `482e6461d` | digging-deeper/server-sent-events — renderSSE + streaming |
| `0518e9c09` | digging-deeper/internationalization — manual pattern (framework ships none) |
| `3397123f7` | i18n — point at existing wheels-dev/wheels-i18n plugin |
| `82395fed7` | digging-deeper/multi-tenancy — TenantResolver + three strategies |
| `cab386481` | digging-deeper/packages — activation + authoring + manifest |
| `06b5bbd17` | digging-deeper/route-model-binding — per-resource/global/scope + dev warning |
| `5ff8b4d6d` | digging-deeper/cors — Cors middleware with fail-closed default |
| `ff30be873` | digging-deeper/rate-limiting — three strategies + storage + keying |
| `f0799c10d` | digging-deeper/dependency-injection-usage — test doubles + resolvers + factories |
| `9a32440a9` | task 15 .ai/ audit + CLAUDE.md reconciliations |
| `ca3f3191c` | digging-deeper/index — section landing with 14 LinkCards |

### Deliverables checklist (14 pages)

- [x] Authentication Patterns
- [x] Authorization & Filters
- [x] Background Jobs
- [x] Caching
- [x] Sending Email (rewrite of Phase 0 sample — nearly total)
- [x] File Uploads & Downloads
- [x] Server-Sent Events
- [x] Internationalization (manual pattern + wheels-i18n plugin reference)
- [x] Multi-tenancy
- [x] Packages
- [x] Route Model Binding
- [x] CORS
- [x] Rate Limiting
- [x] Dependency Injection Usage

### Integration

- [x] Digging Deeper section landing (index) rewritten with CardGrid of 14 pages
- [x] Sidebar populated with all 14 entries in order
- [x] Framework gap tracker updated with 5 new items surfaced during Phase 2b-Advanced

## Verification

- **`pnpm verify:docs`** — **236/236 tagged blocks pass** across 57 files. Runtime ~60-80s.
- **`pnpm test:docs-harness`** — 29/29 unit tests pass. Runtime ~30s.
- **`pnpm build`** — **303 pages** build clean, no broken-link errors.
- Compile driver in `fallback` mode still (LuCLI #56 not yet merged). Once it merges, every compile block promotes to real parse-checking with no harness changes.

## What changed from the plan

Phase 2b-Advanced continued the Phase 2a pattern: subagents cross-check every API against `vendor/wheels/` source before writing, and flag drifts. The rate of drift caught per page was high — consistent with "the `.ai/` reference material was often invented, never verified against reality."

### Major drifts caught (and corrected in user docs)

**Sending Email (Task 5) — Phase 0 sample was nearly entirely fabricated.** This was the biggest single catch:
- No `wheels.Mailer` base class exists
- No `sendMail()` function — real API is `sendEmail()` on every controller
- No `mailerSettings` struct — real form is `set(functionName="sendEmail", server=..., ...)`
- No `this.from` / `this.to` / `this.contentType` / `this.attachments` instance properties — everything is per-call arguments
- Multi-part via `templates="path/html,path/text"` + `detectMultipart`, not `contentType="multipart"`
- Attachments via `file=` / `files=` (paths, resolved relative to `application.wheels.filePath`), not struct array
- No `wheels generate mailer` command; only a broken snippet (see framework gap #17)

**Caching (Task 4) — Wheels does NOT use Lucee cache regions.** Plan's "cache stores (ram/ehcache/redis/memcached) table" was wrong. Real implementation is a plain `application.wheels.cache[category]` struct with cull-based eviction. Also: `cacheRemove()` / `cacheRemoveAll()` don't exist — real API is `$removeFromCache()` / `$clearCache()`. Query caching via `findAll(cache=N)` ships; fragment caching is `includePartial(cache=N)`.

**Multi-tenancy (Task 9) — TenantResolver ships THREE strategies.** Plan knew two (`custom`, `header`); `subdomain` also ships. More importantly:
- `$performQuery()` auto-routes queries by `request.wheels.tenant.dataSource` — zero code needed in model `config()` to switch datasources per tenant
- `sharedModel()` helper exists for cross-tenant opt-out (cleaner than manual scope override)
- `tenant()`, `$tenantDataSource()`, `switchTenant()` accessors all ship
- Unmatched tenants don't 404 — middleware returns `{}` and request proceeds tenant-free with default datasource
- `config.*` overrides have a security denylist — certain keys like `reloadPassword` are silently rejected

**Route Model Binding (Task 11) — `bindBy=` custom binding field does NOT ship.** Plan invented it from Rails/Laravel convention. Subagent dropped the section rather than fabricate API. Binding always uses `findByKey(params.key)` against the primary key. Tracked as framework gap #19.

**Dependency Injection Usage (Task 14) — `toFactory()` callback registration does NOT ship.** Plan invented it. Subagent documented the plain-wrapper-CFC pattern as the workaround. Tracked as framework gap #20.

**CORS (Task 12) — `maxAge` default is 86400 (24h), not 3600.** Also `exposeHeaders` arg doesn't exist. Reject path is "omit Allow headers" — NOT an HTTP 403. Plan's description would have misled.

**Rate Limiting (Task 13) — more constructor args than plan knew.** Real API includes `trustProxy`, `proxyStrategy`, `maxStoreSize`, `maxTimestampsPerKey`, `maxKeyLength`, `failOpen`, `headerPrefix`. Strategies are camelCase (`fixedWindow`, `slidingWindow`, `tokenBucket`). Storage auto-creates `wheels_rate_limits` table — no manual migration.

**Packages (Task 10) — `provides.mixins` default is `"none"`, not `"global"`.** Important — this is the explicit-opt-in model. Also: `ModuleGraph.cfc` for topological-sort dependency resolution, per-method mixin overrides via `GetMetadata()`, `ServiceProviderInterface` with `register(container)` + `boot(app)` hooks.

**Background Jobs (Task 3) — `wheels_jobs` table auto-creates** via `Job.cfc::$ensureJobTable()`. CLAUDE.md and `.ai/` both wrongly claimed a migration is required. CLAUDE.md updated. Also: `wheels jobs work` defaults to 5s interval (CLAUDE.md implied 3s), `wheels jobs retry` doesn't take `--older-than` or status flags.

**File Uploads (Task 6) — `sendFile()` ships (real helper) but uploads are pure Lucee-native.** No `params.user.avatar` struct magic — `<cffile action="upload" filefield="user.avatar" ...>` is the path. Documented honestly; didn't fabricate a wrapper.

### Deletions from `.ai/`

- `.ai/wheels/patterns/authentication.md`, `.ai/wheels/models/user-authentication.md` (Task 1)
- `.ai/wheels/patterns/crud.md` (Task 2)
- `.ai/wheels/jobs/overview.md` (Task 3)
- `.ai/wheels/files/downloads.md` (Task 6)
- `.ai/wheels/controllers/sse.md` (Task 7)
- `.ai/wheels/configuration/multi-tenancy.md`, `.ai/wheels/models/shared-models.md` (Task 9)
- `.ai/wheels/packages/overview.md`, `.ai/wheels/integration/modern-frontend-stack.md` (Task 10)
- `.ai/wheels/patterns/validation-templates.md` (Task 15)

**`.ai/wheels/` down to 25 files** (was 36 at end of Phase 2a). Remaining are Phase 2b-Testing targets, Phase 2b-CLI targets, Phase 2c Security Hardening + Contributing targets.

### Preserved for Phase 2c

- `.ai/wheels/security/csrf-protection.md` — `protectsFromForgery()` is real framework API; Security Hardening page will absorb
- `.ai/wheels/security/https-detection.md` — `isSecure()` + `requireHTTPS` filter pattern; Security Hardening
- `.ai/wheels/configuration/security.md` — production hardening checklist

### CLAUDE.md reconciliations

- Background Jobs "Requires migration" line removed — replaced with accurate "auto-created by `Job.cfc::$ensureJobTable()`"

## Framework gaps tracked (Phase 2b-Advanced additions)

5 new items added to [docs/superpowers/plans/2026-04-19-framework-gaps-from-guides-phase-1.md](./2026-04-19-framework-gaps-from-guides-phase-1.md):

- **#17** — `cli/lucli/templates/snippets/user-mailer.txt` references nonexistent `wheels.Mailer` base class. Anyone running `wheels snippet install user-mailer` gets broken code.
- **#18** — Promote `wheels-dev/wheels-i18n` plugin to first-party package alongside hotwire/basecoat/sentry/legacyadapter.
- **#19** — Route model binding lacks `bindBy=` custom field (slug/alt-column binding not possible today).
- **#20** — DI container lacks `toFactory()` callback registration.
- **#21** — First-class i18n primitives (CLDR pluralization, locale-aware `errorMessagesFor`, `LocaleResolver` middleware, locale-to-Lucee-locale mapping).

## Architectural notes worth preserving

### The subagent cross-check pattern scales

20 subagents in Phase 2a, 14 in Phase 2b-Advanced — 34 total content dispatches. Every one of them cross-checked plan claims against `vendor/wheels/` source before writing. The drift rate has not gone down: Phase 2b-Advanced caught roughly as many API inaccuracies per page as Phase 2a did. This suggests:

1. The historical `.ai/` docs were drafted WITHOUT source verification, and the inaccuracies propagated through every subsequent draft (plans, CLAUDE.md anti-patterns, etc.)
2. Consolidation + verification is a one-time correction opportunity — once a user doc lands with source-verified API, subsequent docs that cross-link to it inherit the accuracy
3. By end of Phase 2c, the drift-catch rate should drop significantly, because there won't be stale `.ai/` source material to draft against

### Phase 0 sample pages were uniformly inaccurate

Of the four Phase 0 sample pages (tutorial/01-hello-wheels, digging-deeper/sending-email, core-concepts/request-lifecycle, cli-reference/info):
- **Tutorial Part 1** — full rewrite during Phase 1 (Tasks 7+)
- **Request Lifecycle** — full rewrite during Phase 2a Task 1
- **Sending Email** — full rewrite during Phase 2b-Advanced Task 5 (this phase) — the most egregious drift
- **CLI Reference Info** — still unverified; Phase 2b-CLI will audit

This is a pattern: any doc drafted before subagent-driven source verification is suspect. When Phase 2b-CLI starts, the CLI reference Info page should be the first thing audited.

### The bcrypt / wheels-i18n / user-mailer pattern

Three distinct "the framework doesn't ship this properly" findings have emerged:
1. **bcrypt** (gap #4) — the tutorial ships SHA-256 as a stopgap with a caveat
2. **wheels-i18n** (gap #18) — the plugin exists in 3.x form; needs package conversion
3. **user-mailer snippet** (gap #17) — ships a broken template

Pattern: Wheels 4.0 has infrastructure in place (bcrypt-as-helper, package system, snippet install) but specific integrations weren't completed. Fixing these three unblocks concrete reader paths ("I want to add auth," "I want i18n," "I want a mailer").

## Open decisions for Phase 2b-Testing (next sub-phase)

1. **Testing detail pages** — 8 pages per original spec (model tests, controller tests, view/form tests, integration, functional, browser, fixtures, running locally, CI integration). All are how-to type. Same rhythm as Phase 2a Basics + this phase. Estimated 12-15 tasks.

2. **`.ai/wheels/testing/*` and `.ai/wheels/controllers/testing.md` + `.ai/wheels/models/testing.md` + `.ai/wheels/views/testing.md`** — four testing-related `.ai/` files remaining. Phase 2b-Testing consolidates them.

3. **Compile driver mode** — if LuCLI PR #56 merges before Phase 2b-Testing starts, compile blocks upgrade to real parse checking automatically. No harness changes needed.

## Next moves

Phase 2b-Testing scope per Phase 1 plan: 8 Testing detail pages.

Before Phase 2b-Testing starts:
- **Rebuild + reinstall `wheels` CLI** to pick up Phase 2a gap fixes (framework-gaps-batch-1 merged as [wheels#2168](https://github.com/wheels-dev/wheels/pull/2168))
- **Chase [LuCLI #56](https://github.com/cybersonic/LuCLI/pull/56)** for the compile driver auto-upgrade
- **Optionally**: file GitHub issues from the 5 new gap tracker items (#17-21) for async work by other contributors

When you're ready: I'll draft the Phase 2b-Testing plan the same way I scoped 2b-Advanced. Same cadence expected.
