---
title: 'Wheels 4.1.1 is out — a CLI security fix and the 4.1.0 papercuts'
slug: wheels-4-1-1-released
publishedAt: '2026-09-28T17:00:00.000Z'
updatedAt: null
author: Peter Amiri
tags:
  - wheels-4
  - release-notes
  - security
categories:
  - Releases
excerpt: >-
  Wheels 4.1.1 fixes a CLI security issue (GHSA-x3cm-2j3q-jgg4), makes the first
  request after a restart work on Adobe ColdFusion, stops multi-database
  migrations from stalling, and clears out the rough edges people hit in
  4.1.0. Every compatibility-matrix leg passed, test by test, before it shipped.
coverImage: '/blog-images/4-1/wheels-4-1-1-released.png'
announcement:
  discussionUrl: 'https://github.com/wheels-dev/wheels/discussions/3776'
  title: 'Wheels 4.1.1 is out'
  body: |
    **[Wheels 4.1.1 is released](https://blog.wheels.dev/blog/wheels-4-1-1-released)**: a CLI security fix, Adobe ColdFusion first-request fixes, multi-database migrations that no longer stall, and the rough edges people hit in 4.1.0.

    - **Security:** [GHSA-x3cm-2j3q-jgg4](https://github.com/wheels-dev/wheels/security/advisories/GHSA-x3cm-2j3q-jgg4) (medium). The CLI now only sends state-changing commands, console code and the reload password to this project's own verified server, and the reload password travels in a header instead of the URL. There's also an open-redirect fix in `redirectTo()` and the CSRF check.
    - **Adobe CF 2023/2025:** the first request after a restart no longer returns HTTP 500.
    - **Migrations:** steps that use raw SQL, including against a second datasource, are recorded again, so the queue doesn't stall.
    - **Fixes:** Oracle, SQL Server, H2, pagination, the query builder's `offset()`, strict CLI argument checking, `wheels test` exit codes, and more. See the [CHANGELOG](https://github.com/wheels-dev/wheels/blob/main/CHANGELOG.md).

    **Upgrade:** `brew upgrade wheels` / `scoop update wheels` / `apt upgrade wheels` / `dnf upgrade wheels`, then `wheels upgrade check` and `wheels upgrade apply`.

    **One manual step:** copy the `X-Wheels-Reload-Password` block from the current `public/Application.cfc` template into your own. The blog post explains where it goes.

    **Known issue (apt only):** if `wheels` fails with `UnsupportedClassVersionError`, your `JAVA_HOME` points to a JDK older than 21. Run `unset JAVA_HOME` or point it at Java 21. The fix ships in 4.1.2.

    Questions or anything that doesn't behave as described: reply here or [open an issue](https://github.com/wheels-dev/wheels/issues/new/choose).
---

Wheels 4.1.1 is out. It's a point release, so there are no new headline features. It does three things you'll want: it closes a security issue in the CLI, it fixes the problems people hit after upgrading to 4.1.0, and it's the first release we held until **every test on every engine and database passed**, checked test by test rather than job by job.

Full notes: [GitHub Release v4.1.1](https://github.com/wheels-dev/wheels/releases/tag/v4.1.1) · [CHANGELOG](https://github.com/wheels-dev/wheels/blob/main/CHANGELOG.md) · [Security advisory GHSA-x3cm-2j3q-jgg4](https://github.com/wheels-dev/wheels/security/advisories/GHSA-x3cm-2j3q-jgg4)

## The security fix: the CLI now checks which server it's talking to

Commands like `wheels migrate`, `wheels reload`, `wheels console` and `wheels test` talk to your app's running server over HTTP. Up to 4.1.0 the CLI trusted whatever answered on the project's port, or on a common development port such as 8080, 60000, 3000 or 8500. If a *different* application was listening there, the CLI could send it state-changing commands, console code, and your app's reload password.

In 4.1.1:

- **State-changing commands need this project's own server,** the one `wheels start` (or `wheels engines rustcfml start`) launched. The CLI checks that the server is the registered process, that it's the only thing listening on its port, and, on every request, that the connection is to that process before sending anything. Otherwise it refuses and names the port.
- **The reload password moves out of the URL** into an `X-Wheels-Reload-Password` request header, so it stays out of access logs and proxy logs.
- `console` never falls back to probing ports, and read-only commands that end up on a server they couldn't verify now tell you so. Set `WHEELS_SERVER_FALLBACK=false` to turn that read-only fallback off entirely.

It's rated **medium**, and it's local: the other application has to be running on your machine. Details, affected versions and workarounds are in the [advisory](https://github.com/wheels-dev/wheels/security/advisories/GHSA-x3cm-2j3q-jgg4).

4.1.1 also fixes an open redirect: `redirectTo()` and `startFormTag()`'s CSRF check accepted a URL such as `https://your-host:x@evil.com/`. Browsers read the part before the `@` as credentials, so the redirect, and the CSRF token, went to another host.

**One manual step for existing apps:** copy the `X-Wheels-Reload-Password` header block from the current `public/Application.cfc` template into the top of `onRequestStart()` in your own `public/Application.cfc`, before the reload lock. Until you do, the CLI falls back to the query string, only for your project's own verified server, and prints a notice.

## Adobe ColdFusion: the first request after a restart works

On Adobe ColdFusion 2023 and 2025, the first request after every server start could return HTTP 500. Health checks usually hid it, and load-balanced deployments didn't: each new instance served a 500 before it warmed up. Three separate causes, all fixed:

- an Adobe engine bug (`EmptyStackException` in `popSuperScope`) hit while creating an internal framework component during `onApplicationStart`;
- Adobe 2025's startup notice when the optional `graphqlclient` package isn't installed, which reached the app's `onError`;
- `request.wheels` keys that `onError` could leave half-initialized.

A new CI smoke test boots a cold server with the health check disabled, so this can't come back quietly.

## Migrations against a second database no longer stall

If a migration's `up()` did its work with raw `queryExecute()` or `cfquery`, for example DDL against a second datasource, and then called `announce()`, 4.1.0 decided it was a placeholder and never recorded it. The migration ran again on every `migrate`. When the re-run failed, say on `CREATE TABLE` for a table that already exists, every migration queued behind it stopped.

4.1.1 records every migration step that completes, as 4.0.x did. The only exception is a migration that still has the inherited `NOT IMPLEMENTED` placeholder `up()`/`down()`, and the migrator now logs a warning when it skips one. After upgrading, a migration 4.1.0 left unrecorded runs once more and is then recorded. If that re-run fails because its work already exists, mark it applied with `wheels migrate pretend <version> --yes`.

Failed migrations during application-start auto-migrate are no longer silent either: they're written to `wheels.log`.

## Everything else

**Database fixes**
- **Oracle** works across engines: `insertAll()` on Lucee and BoxLang, datetime columns returned as real dates on BoxLang and Adobe, and timestamp handling on Adobe.
- **SQL Server:** `create()` with an explicit primary key no longer fails on identity columns.
- **H2:** `offset()` without `limit()` returns rows in the right order.
- **Table names with `$`** work again. Thanks to [@mikegrogan](https://github.com/mikegrogan) for [#3669](https://github.com/wheels-dev/wheels/issues/3669).

**Model and query builder**
- The query builder's `offset()` is now actually applied.
- `updateAll(instantiate=true, validate=false)` skips validations as documented.
- `upsertAll()` keeps an existing row's `createdAt`.
- Compound `condition`/`unless` validation expressions (`&&`, `||`, a leading `!`) work, with CFML precedence.
- A `transaction="none"` call that throws no longer disables transactions for the rest of the request.
- `where` clauses no longer split on `AND`/`OR` inside an identifier.

**Routing and views**
- `paginationLinks()` works on wildcard-routed `index` actions. Thanks to [@mlibbe](https://github.com/mlibbe) for [#3638](https://github.com/wheels-dev/wheels/issues/3638).
- Other pagination fixes: `params` are kept when `pageNumberAsParam=false`, and `prependOnFirst=false` no longer mangles the first link.
- Typed route constraints apply to every optional-segment variant, and route variables aren't double-encoded when URL rewriting is off.
- `linkTo(method="delete")` emits `rel="nofollow"`, spelled correctly.
- `singularize()` leaves `api`, `safari` and `spaghetti` alone.

**CLI and MCP**
- **Arguments are validated strictly.** Unknown named arguments, bad boolean values (`--force=yes`) and out-of-range choices now fail instead of being guessed at.
- **`wheels test`:**
  - it exits non-zero when nothing ran;
  - `--test-timeout` sets the run's time budget;
  - it finds your server when the directory name differs from `lucee.json`;
  - an immediate re-run after a timeout no longer collides with the abandoned run.
- **`wheels stop`** forwards `--name`, `--config` and `--all`.
- **Generators:** `generate model --belongsTo` adds the foreign-key column; plain controllers get plain views; `wheels destroy` writes a migration that runs.
- **MCP:** `deploy` is no longer exposed as an MCP tool.

**Performance**
- Flash locking is per session instead of application-wide, so users no longer queue behind each other on every request.

**Startup errors**
- When Wheels fails to initialize, the real root cause now goes to `wheels.log` instead of the error page pointing at a log entry that didn't exist.

## What "every test passed" means this time

We've always run the full engine × database matrix: Lucee 6 and 7, Adobe 2023 and 2025, and BoxLang, against SQLite, H2, MySQL, PostgreSQL, SQL Server, CockroachDB and Oracle. For 4.1.1 we tightened what "green" means.

- **Oracle no longer passes by default.** Its legs used to be allowed to fail, and one could look green while running zero tests. They now fail the build like any other database, and all five ran more than 5,800 tests each.
- **Release PRs run the full matrix.** A release PR into `main` now runs the whole matrix automatically, and a readiness check blocks it until every open issue and PR is resolved or explicitly deferred.
- **Every result was audited, test by test.** Before we released, we reconciled each leg's raw results. One CockroachDB leg failed a rate-limiter test that happened to run across a minute boundary (16:16:59.948 to 16:17:00.010). We confirmed that was the cause, re-ran that leg on identical code, and scheduled the test fix for 4.1.2 instead of calling it a flake and moving on.

## Upgrading

```sh
brew upgrade wheels                           # macOS / Linux (Homebrew)
scoop update wheels                           # Windows
sudo apt update && sudo apt upgrade wheels    # Debian / Ubuntu
sudo dnf upgrade wheels                       # RHEL / Rocky / Fedora

wheels upgrade check
wheels upgrade apply
```

The CLI now runs on LuCLI 0.6.2.1 on every channel.

Three things to check:

1. **Copy the reload-password header block** into your `public/Application.cfc`, as described above.
2. **Scripts that pass loose CLI flags** (`--force=yes`, unknown options) now fail; switch them to `true`/`false` and remove unknown flags.
3. **Multi-database migrations:** after upgrading, watch for one extra run of any migration 4.1.0 left unrecorded, and use `wheels migrate pretend` if one fails.

**Known issue (apt):** the Debian/Ubuntu `wheels` launcher uses `JAVA_HOME` even when it points to a JDK older than 21, and LuCLI needs Java 21. If `wheels` fails with `UnsupportedClassVersionError`, run `unset JAVA_HOME` or point it at a Java 21 JDK. The launcher fix ([#3766](https://github.com/wheels-dev/wheels/pull/3766)) is merged and ships in 4.1.2.

## Thanks

Thanks to [@mikegrogan](https://github.com/mikegrogan) and [@mlibbe](https://github.com/mlibbe) for the reports above. Thanks to everyone who told us what broke after 4.1.0. And thanks to the RustCFML maintainers, who fixed the include-exception bug we reported ([RustCFML#431](https://github.com/RustCFML/RustCFML/issues/431)) the same day, so our experimental RustCFML lane now runs with no expected failures.

If something in 4.1.1 doesn't behave the way this post says, [file it](https://github.com/wheels-dev/wheels/issues/new/choose).
