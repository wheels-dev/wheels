---
title: Why We Rebuilt Our CI Pipeline
slug: why-we-rebuilt-our-ci-pipeline
publishedAt: '2026-04-09T07:00:00.000Z'
updatedAt: '2026-04-09T13:23:39.918Z'
author: Peter Amiri
tags:
  - ci
categories: []
excerpt: >-
  Why We Rebuilt Our CI Pipeline From 40 Minutes to 82 Seconds April 9, 2026 —
  Peter Amiri, Wheels Core Team --- For years, the Wheels CI pipeline ran every
  commit through a gauntlet: five CFML engin...
coverImage: null
legacyId: '1165378763664687105'
---
# Why We Rebuilt Our CI Pipeline From 40 Minutes to 82 Seconds

*April 9, 2026 — Peter Amiri, Wheels Core Team*

---

For years, the Wheels CI pipeline ran every commit through a gauntlet: five CFML engines, seven databases, Docker Compose orchestrating it all. It was thorough. It was comprehensive. And it was killing our velocity.

Today we shipped a fundamentally different approach. Our primary CI now runs in **82 seconds**. No Docker. No CommandBox. Just LuCLI, Lucee 7, and SQLite — the same tools a developer uses on their laptop.

This post explains the reasoning behind the change, what we learned, and why we think this pattern applies to any framework project fighting its own CI.

## The Problem We Were Solving

Our previous CI pipeline tested every push to `develop` against this matrix:

| | MySQL | PostgreSQL | SQL Server | H2 | CockroachDB | Oracle | SQLite |
|---|---|---|---|---|---|---|---|
| **Lucee 5** | | | | | | | |
| **Lucee 6** | | | | | | | |
| **Lucee 7** | | | | | | | |
| **Adobe 2023** | | | | | | | |
| **Adobe 2025** | | | | | | | |
| **BoxLang** | | | | | | | |

That's up to 42 engine-database combinations. Each engine needed a Docker image built from `ortussolutions/commandbox`, which downloads CommandBox, installs Lucee or Adobe CF, warms up the server, installs dependencies, and then starts. The database containers needed their own startup time — Oracle alone takes 2-3 minutes to accept connections.

A typical CI run took **30-45 minutes**. On a bad day with flaky Oracle connections or BoxLang compilation issues, it could take over an hour.

More critically, this matrix had become a **development tax**. Every feature branch had to pass every engine. Every refactor had to work identically on Lucee, Adobe CF, and BoxLang. The cross-engine differences weren't just slowing CI — they were slowing the design of the framework itself.

## The Cost of Universal Compatibility

When you maintain compatibility across three fundamentally different CFML engines, every abstraction carries hidden weight. Here are real examples from the weeks before this change:

**The `invoke()` BIF**: Adobe ColdFusion requires positional arguments for `invoke()`. Lucee accepts named arguments. BoxLang requires extracting the method reference and calling it directly. A single line of code — "call this method on this object" — needed an engine adapter with three implementations.

**The `interface` keyword**: We added a CFML `interface` file for documentation. It compiled fine on Lucee and Adobe. BoxLang's CFC scanner choked on it during directory traversal, crashing the entire application before a single test could run.

**Oracle TIMESTAMP coercion**: Oracle's JDBC driver returns `oracle.sql.TIMESTAMP` objects instead of standard dates. BoxLang needed these coerced to CFML dates. Adobe CF didn't — until we added a unified adapter, which then broke Adobe's timestamp comparison tests. Fixing Adobe broke BoxLang's `hasChanged()` method. Each fix for one engine destabilized another.

**The `$wheels` lifecycle**: During application startup, the framework stores configuration in `application.$wheels`, then copies it to `application.wheels` at the end of initialization. Code that runs mid-initialization needs to check both locations. This was invisible for years until the engine adapter PR introduced a function that was called during route loading — before the copy happened. Every engine crashed, but each with a different error message.

These aren't exotic edge cases. They're the daily reality of cross-engine CFML development. Every one of them turned a 30-minute feature into a multi-day debugging session, with CI as the bottleneck for each iteration.

## The Strategic Decision: Pick a Primary Platform

We made a deliberate choice: **Lucee 7 and SQLite are the primary supported platform for Wheels going forward.**

This doesn't mean we're dropping support for other engines or databases. It means we're changing the relationship between primary and secondary platforms:

- **Primary (Lucee 7 + SQLite)**: Hard CI gate. Every PR. Every merge. Must pass to ship.
- **Secondary (everything else)**: Monitored weekly. Failures are tracked and addressed, but they don't block development.

This mirrors how most successful open-source projects operate. Rails doesn't block releases on JRuby compatibility. Django doesn't require every commit to pass on MySQL, PostgreSQL, and SQLite simultaneously. They pick a reference platform, optimize the inner loop for it, and run broader compatibility checks on a separate cadence.

### Why Lucee 7

Lucee is where Wheels development happens. It's the engine the core team runs locally. It's the engine most Wheels applications deploy on. And with LuCLI — our new Lucee-native CLI — it's the engine we're investing in for the AI-native development experience (MCP tools, code generation, interactive REPL).

Lucee 7 specifically because it's the current mainline release with active development and the best performance characteristics.

### Why SQLite

SQLite eliminates external dependencies entirely. No Docker container to start. No connection pooling to configure. No 3-minute Oracle startup to wait for. The SQLite JDBC driver is a single JAR file.

For a framework test suite that exercises ORM behavior, query building, migrations, and data validation, SQLite covers the vast majority of code paths. Database-specific behavior (stored procedures, vendor-specific SQL) is tested in the weekly compatibility matrix.

## The New Architecture

### Primary CI: LuCLI Native (82 seconds)

```
checkout -> setup JDK 21 -> install LuCLI binary (38MB download)
  -> create SQLite test databases
  -> lucli server run (starts Lucee 7 natively on the runner)
  -> install SQLite JDBC into Lucee classpath
  -> run 2,482 tests via curl
  -> parse results, generate JUnit XML
  -> upload artifacts
```

No Docker. No CommandBox. LuCLI downloads as a single Linux binary from GitHub Releases. It starts Lucee Express directly on the GitHub Actions runner JVM. The test suite runs against localhost.

The total job time is **82 seconds**, including JDK setup, Lucee download (cached after first run), server startup, and running all 2,482 tests.

### Develop Pipeline: Fast Test Gates Release

```
fast-test (82s) -> build snapshot (ForgeBox publish) -> sync docs (wheels.dev)
```

The snapshot release to ForgeBox only happens if the fast test passes. This is the same gate that existed before — it just runs 30x faster.

### Compatibility Matrix: Weekly + Manual

The full 5-engine x 7-database Docker Compose matrix now runs on a weekly schedule (Sunday 02:00 UTC) and via manual dispatch. It uses the exact same `tests.yml` workflow that was previously the primary CI. Nothing was deleted — it was relocated.

This gives us:
- **Early drift detection**: If Adobe CF 2025 breaks on a Wheels change, we'll know within a week.
- **No noise on every push**: Developers don't see red badges for BoxLang compilation issues they can't fix.
- **On-demand deep testing**: Before a release, anyone can trigger the full matrix manually.

## What LuCLI Means for CI

LuCLI is more than a CommandBox replacement — it's a statement about where Wheels is headed. By using LuCLI in CI, the pipeline validates the same tool developers use locally:

- `lucli server start` starts the same Lucee instance in CI and on your laptop
- `lucli server stop` cleanly shuts it down
- The `lucee.json` configuration file is the single source of truth for server config

When CI and local development use the same tools, "works on my machine" and "works in CI" converge. There's one mental model, one set of troubleshooting steps, one path from code change to verification.

## The Datasource Pattern: Engine-Level to App-Level

The move from CommandBox to LuCLI surfaced an important architectural shift in how datasources are configured.

In the CommandBox/Docker world, datasources lived at the **engine level**. CommandBox supports CFConfig — a JSON file that injects datasource definitions directly into Lucee's server configuration before the application starts. Our Docker Compose files used `CFConfig.json` to define all seven database connections (MySQL, PostgreSQL, SQL Server, H2, CockroachDB, Oracle, SQLite) at the engine layer. The application never needed to know how those connections were established — it just referenced them by name.

LuCLI doesn't support CFConfig. Rather than building a compatibility shim, we took this as an opportunity to move datasource definitions where they arguably belong: **at the application level**. CFML has supported `this.datasources` in `Application.cfc` for years, but the ecosystem's reliance on engine-level admin panels and CFConfig meant most developers never used it.

In Wheels, `config/app.cfm` is the recommended place for Application-level configuration — it's included by `Application.cfc` and keeps the framework file clean:

```cfm
// config/app.cfm
if (server.system.environment.WHEELS_CI ?: "" == "true") {
    this.datasources["wheelstestdb_sqlite"] = {
        class: "org.sqlite.JDBC",
        connectionString: "jdbc:sqlite:#expandPath('../')#wheelstestdb.db"
    };
}
```

This is a better pattern for several reasons. App-level datasources are version-controlled with your code. They're portable across engines without engine-specific admin tools. They're visible in code review. And they work identically whether you're running LuCLI locally, deploying to a server, or running in CI — no separate configuration layer to keep in sync.

The `WHEELS_CI` environment variable gates the test datasources so they only activate in CI. Production applications define their real datasources in the same file, ungated, or read connection strings from environment variables.

## Lessons Learned

### 1. Comprehensive doesn't mean fast

A 42-combination test matrix is comprehensive. It's also 42x slower than testing one combination. For the inner development loop — where a developer pushes a commit and wants to know if it works — comprehensive is the enemy of productive.

### 2. Engine differences are architectural, not incidental

The differences between Lucee, Adobe CF, and BoxLang aren't bugs to be papered over. They're fundamental architectural differences in how these engines handle compilation, class loading, struct member functions, and Java interop. Treating them as incidental (just add an `if` statement) leads to an ever-growing thicket of conditional code. Treating them as architectural (pick a primary, adapt others) leads to cleaner abstractions.

### 3. CI time is developer time multiplied

If your CI takes 40 minutes and your team pushes 10 times a day, that's nearly 7 hours of CI time daily. Even if developers context-switch during that time, the cognitive cost of interrupted flow is real. At 82 seconds, the feedback is practically synchronous — push, grab a coffee, see results.

### 4. The legacy matrix is still valuable — just not as a gate

We didn't delete the compatibility matrix. We decoupled it from the critical path. The weekly run still catches drift. The manual trigger is available before releases. But it no longer holds every commit hostage to Oracle startup times and BoxLang compilation quirks.

## What's Next

This CI change is part of a larger strategic shift toward Lucee 7 as the reference platform for Wheels:

- **LuCLI as the recommended CLI**: Replacing CommandBox for Wheels-specific workflows (generation, testing, migration, MCP)
- **Engine adapters**: The adapter pattern from the W-004 PR centralizes cross-engine behavior, making it easier to maintain secondary engine support without polluting the main codebase
- **Docker simplification**: Local development moves to `lucli server start` instead of `docker compose up`. Docker stays for the compatibility matrix and production deployment

The goal is a development experience where the distance between idea and verified code is measured in seconds, not minutes.

---

*The CI pipeline changes are in [PR #2032](https://github.com/wheels-dev/wheels/pull/2032). The compatibility matrix runs weekly and is available via manual dispatch at [Actions > Wheels Compatibility Matrix](https://github.com/wheels-dev/wheels/actions/workflows/compat-matrix.yml).*
