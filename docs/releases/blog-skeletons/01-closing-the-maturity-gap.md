---
title: 'Wheels 4.0: Closing the Maturity Gap'
slug: wheels-4-closing-the-maturity-gap
publishedAt: '2026-05-09T07:00:00.000Z'
updatedAt: null
author: Peter Amiri
tags:
  - wheels-4
  - release-notes
  - frameworks
categories: []
excerpt: >-
  For years, the same rows showed up red in every framework comparison:
  no bulk ops, no polymorphic associations, no advisory locks, no middleware,
  no browser testing. Wheels 4.0 closes those gaps. This is a guided tour
  of what changed and where the framework still trails.
coverImage: null
---

# Wheels 4.0: Closing the Maturity Gap

_Peter Amiri, Wheels Core Team_

---

If you have evaluated Wheels in the last five years and walked away, you probably walked away for reasons that were true at the time. The comparison tables were not kind. Rails had bulk operations, polymorphic associations, advisory locks, a first-class middleware pipeline, and a mature testing story. Laravel had the same. Django had its own version. Wheels had "no", "no", "via plugin", and "manual" spread across every row.

Those gaps were real. They are now closed. Between Wheels 3.0.0 and 4.0 we merged over 260 PRs across roughly 15 weeks, landing around 75 distinct user-visible features, 40+ security-hardening changes, and 7 deliberate breaking changes. This post is a guided tour of what closed, organized around what you actually do with a web framework.

## The comparison table problem

Every framework-comparison blog post written in the CFWheels 2.x era landed on the same verdict: Wheels was a capable MVC framework with ActiveRecord-style models and sensible conventions, but the feature list trailed its peers by years on the parts that mature production apps lean on hardest. Bulk database operations. Polymorphic associations. First-class middleware. Browser tests driven by a real browser. Background jobs without standing up Redis. A deploy story that did not begin with "write a shell script."

We maintained an internal tracker of those gaps — it lived at [`docs/wheels-vs-frameworks.md`](https://github.com/wheels-dev/wheels/blob/develop/docs/wheels-vs-frameworks.md) and it was a depressing read. Not because the framework was bad, but because the pattern was familiar: good bones, shipping steadily, always a version behind on the features that made framework evaluators click "next."

The point of the 4.0 cycle was to stop being a version behind. Not on every axis — Rails has a decade-plus of ecosystem momentum that no amount of framework work closes — but on the feature-list axes that appear in comparison tables, and that real users hit in real projects. This is what landed.

## Data layer

Most of the oldest comparison-table "no"s lived here. They are now "yes".

**Bulk insert and upsert** ([#2101](https://github.com/wheels-dev/wheels/pull/2101)) land as `model.insertAll()` and `model.upsertAll()`, with per-adapter native UPSERT syntax for MySQL, PostgreSQL, SQL Server, SQLite, H2, CockroachDB, and Oracle. This is the feature that turns an "insert 50,000 rows from a CSV" script from a five-minute loop into a one-second statement.

```cfm
// Bulk upsert — native per-adapter UPSERT syntax under the hood
model("Product").upsertAll(records, uniqueBy="sku");
```

**Polymorphic associations** ([#2104](https://github.com/wheels-dev/wheels/pull/2104)) arrive with the idiomatic `belongsTo(polymorphic=true)` and `hasMany(as=...)` pair. A `Comment` model can now belong to a `Post` or a `Photo` or anything else without a discriminator table or a plugin.

**Advisory locks and pessimistic locking** ([#2103](https://github.com/wheels-dev/wheels/pull/2103)) give you `withAdvisoryLock(name, callback)` for coordinating across processes and `.forUpdate()` on the chainable query builder for row-level locking inside a transaction. The first one is the pattern you reach for when you have a cron job running on three web nodes and you only want one of them to actually run it.

The **chainable query builder, scopes, enums, and batch processing** ([#1919](https://github.com/wheels-dev/wheels/pull/1919) through [#1922](https://github.com/wheels-dev/wheels/pull/1922)) brought the Rails idioms that Wheels users had been hand-rolling for years. `model("User").active().recent().where("role", "admin").get()` now works, with values auto-quoted. `findEach(batchSize=1000, callback=...)` processes a million rows without blowing up the heap.

And **CockroachDB** ([#1876](https://github.com/wheels-dev/wheels/pull/1876) and its follow-ups) joined the adapter family, bringing the supported-database count to seven.

## Migrations

This is the axis where 4.0 beats Rails and Laravel outright.

**Auto-migrations** ([#2102](https://github.com/wheels-dev/wheels/pull/2102)) and **rename detection** ([#2112](https://github.com/wheels-dev/wheels/pull/2112)) give you Django's `makemigrations` energy: diff a model against the current DB schema, emit a migration CFC with the right `addColumn` / `removeColumn` / `renameColumn` / `changeColumn` calls, including heuristic rename suggestions via normalized-token Levenshtein matching. It is also the only corner of the framework with both a CLI surface and an MCP surface.

```cfm
// Auto-migration diff with an explicit rename hint
var am = CreateObject("component", "wheels.migrator.AutoMigrator");
var d = am.diff("User", {renames: {"full_name": "fullName"}});
am.writeMigration(d, "rename_name_field");
```

Rails still expects you to write migrations by hand. Laravel does too. Django generates them, and so does Wheels now.

## Routing and controllers

**First-class middleware** ([#1924](https://github.com/wheels-dev/wheels/pull/1924)) lands at the dispatch level, before controller instantiation. Built-ins ship for request IDs, CORS, security headers, and rate limiting — the last with fixed-window, sliding-window, and token-bucket strategies, memory or database-backed. Custom middleware implements `wheels.middleware.MiddlewareInterface` and drops into `app/middleware/`.

```cfm
// Route-scoped rate limiting via the middleware pipeline
mapper()
    .scope(path="/api", middleware=[
        new wheels.middleware.RateLimiter(maxRequests=100, windowSeconds=60)
    ])
        .resources("users")
    .end()
.end();
```

**Route model binding** ([#1929](https://github.com/wheels-dev/wheels/pull/1929)) means `params.user` arrives at your controller as a resolved model instance, not an ID you have to look up. A missing record throws `Wheels.RecordNotFound` (404) before your action runs. Opt in per-resource, per-scope, or globally.

**Typed route constraints and API versioning** ([#1891](https://github.com/wheels-dev/wheels/pull/1891)) round out the routing work.

## Real-time and background work

**Background jobs without Redis** ([#1934](https://github.com/wheels-dev/wheels/pull/1934)) is the headline here. The `wheels_jobs` table auto-creates on first enqueue, and `wheels jobs work` is a persistent worker daemon with configurable backoff, priority queues, and a monitor dashboard. For projects that do not want to stand up a separate job-queue service, this is a path to production background work with zero extra infrastructure.

**Server-sent events** ([#1940](https://github.com/wheels-dev/wheels/pull/1940)) arrive as view-layer helpers — `renderSSE()`, `initSSEStream()`, `sendSSEEvent()` — plus a pub/sub channel abstraction for fan-out. SSE over bidirectional WebSocket is a deliberate pick, and the next section gets into why.

**Multi-tenancy in-core** ([#1951](https://github.com/wheels-dev/wheels/pull/1951)) brings tenant resolution middleware and per-tenant connection routing into the framework itself, rather than as a plugin.

## Testing

This was the most embarrassing category in the pre-4.0 comparison tables. It is now arguably the most complete corner of the framework.

**HTTP TestClient** ([#2099](https://github.com/wheels-dev/wheels/pull/2099)) gives you in-process HTTP tests — `client.get("/users")`, `client.post("/users", data=...)` — without spinning up a server. Cookies, sessions, and redirects all work.

**Parallel test runner** ([#2100](https://github.com/wheels-dev/wheels/pull/2100)) turns a serial 8-minute suite into a parallel 2-minute suite on a modern laptop, with worker-scoped database isolation handled automatically.

**Browser testing via Playwright Java** ([#2113](https://github.com/wheels-dev/wheels/pull/2113) and its series, including [#2115](https://github.com/wheels-dev/wheels/pull/2115) and [#2116](https://github.com/wheels-dev/wheels/pull/2116)) lets you drive a real Chromium against your app from CFML. `this.browser.visit("/login").fill("email", "...").press("Log in").assertSee("Welcome")` runs end-to-end through a real browser. Playwright installs via `wheels browser:install` and caches through CI via a JAR manifest hash.

The testing ecosystem around Wheels went from "what tests" to "full HTTP-plus-browser suite in one framework" in a single release.

## DI and core

**The expanded DI container** ([#1933](https://github.com/wheels-dev/wheels/pull/1933)) adds request-scoped services, auto-wiring based on init-arg names, and declarative injection inside controller `config()`. You register services in `config/services.cfm`, resolve them with `service("emailService")`, and stop hand-wiring dependencies into constructors.

**The package system** ([#1995](https://github.com/wheels-dev/wheels/pull/1995) and [#2017](https://github.com/wheels-dev/wheels/pull/2017)) replaces the legacy `plugins/` directory with a `packages/` → `vendor/` activation model. Packages declare a `package.json` manifest, load through per-package error isolation, and ship first-party — `wheels-sentry`, `wheels-hotwire`, `wheels-basecoat` — with third-party packages using the same protocol.

## Deploy

`wheels deploy` ([#2187](https://github.com/wheels-dev/wheels/pull/2187)) is a byte-compatible port of Basecamp's Kamal into the Wheels CLI. Zero-downtime rolling Docker deploys to Linux servers over SSH, with no Ruby runtime required. A server managed by Ruby Kamal can be taken over by `wheels deploy` without cleanup, and vice versa. The [dedicated deploy article](/posts/wheels-deploy-kamal-port/) covers the port strategy, the one deliberate divergence from Kamal, and the commands-are-strings invariant that makes the whole thing testable offline.

## Security and developer experience

The 40+ security-hardening PRs are a story of their own, but the defaults that changed are worth naming up front. CORS defaults to deny-all. HSTS is on by default in production. The CSRF secret key is required in production — missing it refuses to boot rather than silently running with a weak default. Console-eval is hardened. SQL injection audits swept the model layer. If you are upgrading a 3.x app, the [upgrade guide](https://guides.wheels.dev/v4-0-0-snapshot/upgrading/) walks through the breaking defaults.

## Where Wheels still trails

This section is the one to read carefully if you are weighing 4.0 against Rails or Laravel for a new project.

**Ecosystem size.** The Rails, Laravel, and Django communities are each orders of magnitude larger than the Wheels community. That means more third-party packages, more blog posts, more Stack Overflow answers, more people who have already hit the bug you are hitting. This is not something a release cycle closes. Wheels runs on CFML, and CFML is a niche. The package system makes it easier to ship third-party code, and the first-party packages (sentry, hotwire, basecoat) help with the common cases, but the long tail of "there is a gem for that" is not going to match Rails any time soon.

**Bidirectional WebSocket.** Wheels ships SSE, not WebSocket. This is deliberate — SSE is uniformly supported across every CFML engine (Lucee, Adobe CF, BoxLang) and every Java servlet container Wheels runs on top of. WebSocket support varies by engine in ways that would either require engine-specific paths in user code or a lowest-common-denominator wrapper. The trade is: if your app genuinely needs bidirectional real-time (multiplayer games, collaborative editing), Wheels is not the right choice. If you need server-to-client streaming (notifications, dashboards, progress bars), SSE is a better primitive anyway.

**Asset-pipeline maturity.** The Vite integration is solid, but it is newer than Rails' importmap-plus-Propshaft story and newer than Laravel's Mix-then-Vite evolution. The common paths work. The edge cases have fewer worked examples.

None of these are blockers for the kinds of apps most teams build. They are the honest answer to "is Wheels as mature as Rails," and the honest answer is "closer than it was, still not quite, and here is specifically where."

## What this means for your 3.x app

The 7 breaking changes in 4.0 are mostly security defaults (CORS, HSTS, CSRF, console-eval) plus a few deprecated surfaces being removed. The [upgrade guide](https://guides.wheels.dev/v4-0-0-snapshot/upgrading/) walks through each one, and the **Legacy Compatibility Adapter** ([#2015](https://github.com/wheels-dev/wheels/pull/2015)) gives you a soft-landing path for the surfaces that shifted. Most 3.x apps upgrade cleanly; the ones that do not usually hit exactly one of the security defaults and fix it in a single commit.

If you are evaluating Wheels for a new project, the comparison table you last saw is out of date. The gaps you remember are gone. The gaps that remain are named above, and they are specific enough to decide against.

## Where to go next

- [The upgrade guide](https://guides.wheels.dev/v4-0-0-snapshot/upgrading/3x-to-4x/) walks through every breaking change with a worked example.
- [Wheels vs. other frameworks](https://github.com/wheels-dev/wheels/blob/develop/docs/wheels-vs-frameworks.md) is the refreshed comparison table with the 4.0 rows filled in.
- [The full release audit](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md) covers each feature in depth, linked to the PR and the documentation.
- [Porting Kamal to CFML](/posts/wheels-deploy-kamal-port/) covers `wheels deploy` specifically — worth reading if production deployment is one of the pieces you were waiting on.

A huge thank-you to the contributors who made this cycle happen: @bpamiri, @zainforbjs, @chapmandu, @mlibbe, @MukundaKatta, and Dependabot for the unglamorous-but-essential dependency work. If you are kicking the tires on 4.0 — upgrading a 3.x app, starting something new, or coming back to Wheels after a long time away — we would love to hear what holds up and what does not.
