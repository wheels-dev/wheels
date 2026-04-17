---
status: skeleton
slot: lead post (publish first)
target_length: 1200–1600 words
---

# Wheels 4.0 — Closing the Maturity Gap

**Subhead / dek:** *Fourteen weeks, 185 PRs, and the features that finally put Wheels shoulder-to-shoulder with Rails 8, Laravel 12, and Django 5.*

**Target audience:**
- Current Wheels users wondering whether 4.0 is "just a point release"
- CFML developers evaluating whether to stay on the platform
- Framework watchers outside CFML who last looked at CFWheels 2.x and moved on
- Engineering leads deciding whether Wheels can be a safe default for new projects

**Lead paragraph intent (3–4 sentences, NOT prose):**
- Frame: for years, framework comparisons listed the same CFWheels gaps — no bulk ops, no polymorphic assocs, no advisory locks, no first-class middleware, no browser testing.
- Pivot: those gaps were real, and they're now closed.
- Scope: 185 PRs between 3.0.0 (Jan 10) and 4.0 (Apr 16) — roughly 14 weeks.
- Promise of the post: a guided tour of *the gaps that closed*, organized by what users actually do with the framework.

## Sections

### 1. "The comparison table problem"
- Every framework-comparison blog post from the last five years had the same CFWheels rows: *no*, *no*, *via plugin*, *manual*.
- [`docs/wheels-vs-frameworks.md`](https://github.com/wheels-dev/wheels/blob/develop/docs/wheels-vs-frameworks.md) used to look a certain way. Here's what changed.
- Hand-off to the next section: show the gaps, then show how they closed.

### 2. Data layer — bulk ops, polymorphism, advisory locks
- **Bulk insert / upsert** ([#2101](https://github.com/wheels-dev/wheels/pull/2101)) — per-adapter native UPSERT for MySQL, PostgreSQL, SQL Server, SQLite, H2, CockroachDB, Oracle.
- **Polymorphic associations** ([#2104](https://github.com/wheels-dev/wheels/pull/2104)) — `belongsTo(polymorphic=true)` + `hasMany(as=)`.
- **Advisory locks + pessimistic locking** ([#2103](https://github.com/wheels-dev/wheels/pull/2103)) — `withAdvisoryLock(name, callback)` and `.forUpdate()` on QueryBuilder.
- **Chainable query builder, scopes, enums, batch processing** ([#1919](https://github.com/wheels-dev/wheels/pull/1919)–[#1922](https://github.com/wheels-dev/wheels/pull/1922)) — Rails-idiom parity.
- **CockroachDB adapter** ([#1876](https://github.com/wheels-dev/wheels/pull/1876) + follow-ups) — seventh supported DB.

### 3. Migrations — auto-diff from models
- **Auto-migrations** ([#2102](https://github.com/wheels-dev/wheels/pull/2102)) + **rename detection** ([#2112](https://github.com/wheels-dev/wheels/pull/2112)) — Django's `makemigrations` energy with CLI + MCP surface.
- Beats Rails and Laravel on this specific axis (both still require manual migrations).

### 4. Routing and controllers — middleware + model binding
- **First-class middleware pipeline** ([#1924](https://github.com/wheels-dev/wheels/pull/1924)).
- **Route model binding** ([#1929](https://github.com/wheels-dev/wheels/pull/1929)).
- **Typed route constraints + API versioning** ([#1891](https://github.com/wheels-dev/wheels/pull/1891)).

### 5. Real-time and background work
- **Background jobs without Redis** ([#1934](https://github.com/wheels-dev/wheels/pull/1934)) — tease post #4.
- **SSE pub/sub channels** ([#1940](https://github.com/wheels-dev/wheels/pull/1940)).
- **Multi-tenancy in-core** ([#1951](https://github.com/wheels-dev/wheels/pull/1951)) — tease post #7.

### 6. Testing — the category that was most embarrassing, now most complete
- **HTTP TestClient** ([#2099](https://github.com/wheels-dev/wheels/pull/2099)).
- **Parallel test runner** ([#2100](https://github.com/wheels-dev/wheels/pull/2100)).
- **Browser testing via Playwright Java** ([#2113](https://github.com/wheels-dev/wheels/pull/2113) + series).
- Tease post #6.

### 7. DI and core
- **Expanded DI container** ([#1933](https://github.com/wheels-dev/wheels/pull/1933)) — request-scoped services, auto-wiring.
- **Package system** ([#1995](https://github.com/wheels-dev/wheels/pull/1995) + [#2017](https://github.com/wheels-dev/wheels/pull/2017)).

### 8. Security and developer experience (brief, tease post #3)
- 40+ security-hardening PRs.
- Deny-all CORS default, HSTS default-on in prod, CSRF key required in prod.

### 9. Where Wheels still trails — be honest
- **Ecosystem size** — smaller than Rails/Laravel/Django communities.
- **Bidirectional WebSocket** — intentional non-goal; SSE is the cross-engine-uniform primitive.
- **Asset-pipeline maturity** — Vite integration is newer than Rails' / Laravel's tooling. (Follow-on work underway.)

### 10. What this means for your 3.x app
- Point to post #2 ("Upgrading from Wheels 3.x") and the upgrade guide.
- Mention the Legacy Compatibility Adapter ([#2015](https://github.com/wheels-dev/wheels/pull/2015)) for the soft landing.

## Code / config snippets to include (pick 3)

```cfm
// Bulk upsert (adapter-native UPSERT syntax)
model("Product").upsertAll(records, uniqueBy="sku");

// Polymorphic association
hasMany(name="comments", as="commentable", polymorphic=true);

// Advisory lock
application.wo.withAdvisoryLock("payroll-run", () => {
    processPayroll();
});
```

```cfm
// Middleware pipeline + route-scoped rate limiting
mapper()
    .scope(path="/api", middleware=[
        new wheels.middleware.RateLimiter(maxRequests=100, windowSeconds=60)
    ])
        .resources("users")
    .end()
.end();
```

```cfm
// Auto-migration diff
var am = CreateObject("component", "wheels.migrator.AutoMigrator");
var d = am.diff("User", {renames: {"full_name": "fullName"}});
am.writeMigration(d, "rename_name_field");
```

## Suggested visuals

- **Hero:** radar/spider chart — Rails 8, Laravel 12, Django 5, Wheels 3.0, Wheels 4.0 across 8 axes (ORM, migrations, middleware, real-time, testing, DI, security, jobs). Show the Wheels 3.0 line as conspicuously smaller; Wheels 4.0 overlaps the others.
- **Secondary:** the closed-gap table from [`wheels-3.0-vs-4.0.md`](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md) — "Peer-framework context — where 4.0 closed gaps" — as a screenshot or re-rendered embed.

## Outro / CTA (1 paragraph)

- Thank contributors: @bpamiri, @zainforbjs, @chapmandu, @mlibbe.
- Link to the upgrade guide.
- Link to the full audit for the obsessive readers.
- Subtle call for testers / feedback on the release candidate.

## Citations (must link in final post)

- [Feature audit](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md)
- [3.0 → 4.0 comparison](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md)
- [Wheels vs. frameworks](https://github.com/wheels-dev/wheels/blob/develop/docs/wheels-vs-frameworks.md)
- [Upgrade guide](https://github.com/wheels-dev/wheels/blob/develop/docs/src/introduction/upgrading-to-4.0.md)
- CHANGELOG entry for 4.0 (once tagged)
