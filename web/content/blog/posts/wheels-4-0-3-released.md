---
title: 'Wheels 4.0.3: rebuilt CLI argument parsing, honest exit codes, and wrong-database guardrails'
slug: wheels-4-0-3-released
publishedAt: '2026-06-10T00:00:00.000Z'
updatedAt: '2026-06-10T20:56:50.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - release-notes
  - frameworks
categories:
  - Releases
excerpt: >-
  Wheels 4.0.3 is the third patch on the 4.0 line, focused on making the
  `wheels` CLI trustworthy in scripts and CI: argument parsing is rebuilt
  end-to-end (`--no-*` negations and named-only flags finally reach every
  command), failures exit non-zero, and write-side commands refuse to attach
  to a different project's server. Plus PostgreSQL/CockroachDB foreign-key
  migration fixes, pre-23c Oracle support, preserved column casing in model
  output, and a fix that stops framework helpers from being URL-invokable as
  controller actions.
coverImage: null
---

Wheels 4.0.3 ships today, two weeks after [4.0.2](https://blog.wheels.dev/posts/wheels-4-0-2-released). Like the two patches before it, it's a patch release in the SemVer sense — no new public APIs to learn — but it has the clearest center of gravity of the three: **the `wheels` CLI**. If 4.0.2 was about trusting your migrations, 4.0.3 is about trusting the tool that runs them — from a terminal, from a script, from CI, or from an AI agent driving it over MCP.

There are also two fixes everyone should read before upgrading — one that affects PostgreSQL users running migrations, and one security fix in the controller dispatch path. Both are covered below.

## The argument-parsing rebuild

Here's a bug report that kicked this whole effort off: `wheels new blog --no-sqlite` scaffolded a SQLite database anyway ([#2855](https://github.com/wheels-dev/wheels/issues/2855)). The flag wasn't misspelled, and the code that *should* have honored it was right there. So where did it go?

The answer was structural. LuCLI (the runtime under the `wheels` binary) parses your command line and hands each command a **structured argument map** — positionals as `arg1, arg2, ...`, options as `key=value`, and `--no-key` normalized to `key=false`. But the CLI module historically flattened that map *back* into a flat argv array so that each of ~18 subcommands could re-parse it with its own hand-rolled token loop. That round trip was lossy in two ways:

- The flatten step **silently dropped every `false` value** — so `--no-sqlite`, `--no-routes`, `--no-test-db`, and `--no-open-browser` never survived to the commands that documented them.
- The rebuild only ran when a *positional* argument was present — so **named-only invocations were dropped entirely**. `wheels seed --environment=production` seeded the development environment. `wheels doctor --verbose` was never verbose. The defaults just won, silently.

4.0.3 completes the fix that landed incrementally on the bleeding-edge channel: a typed argument-spec builder, `ArgSpec`, that consumes LuCLI's structured handoff directly — declare your positionals, flags, and options up front, get a typed result back, no flatten, no re-parse ([#2861](https://github.com/wheels-dev/wheels/issues/2861)). Every one of the CLI's commands now parses through it, and the deprecated round-trip shim is **deleted**, so the bug class can't quietly come back. The `--no-sqlite` case is also pinned end-to-end in the onboarding test harness — real CLI, real LuCLI handoff, real scaffolder.

```bash
# all of these previously half-worked or silently ran with defaults
wheels new blog --no-sqlite
wheels seed --environment=production
wheels generate admin Product --no-routes
wheels doctor --verbose
```

One deliberate behavioral note: space-separated option values (`wheels test --filter models`) are gone in favor of the `--key=value` form (`wheels test --filter=models`) — LuCLI delivers a space-separated value as a bare flag plus an unrelated positional, so the old form was never reliably parseable in the first place.

## Failures exit non-zero now

The companion fix for scripting: several commands printed a friendly red error message and then returned success — exit code 0 — because of how their error paths returned to the runtime ([#2890](https://github.com/wheels-dev/wheels/pull/2890)). A typo'd subcommand, an unknown generator type, or a **failed migration** all looked green to CI pipelines, deploy scripts, and pre-commit hooks.

In 4.0.3, `wheels generate <unknown>`, `wheels create <unknown>`, `wheels migrate <unknown>`, `wheels db <unknown>`, a failed `wheels migrate latest|up|down|info|doctor`, and an unparseable `wheels routes` response all exit non-zero — while still printing the same human-friendly diagnostic first. Over MCP these surface as proper tool errors instead of empty results, so an AI agent can tell the difference between "done" and "didn't happen" too.

> **Heads-up:** if you have a script that depended on these failure paths exiting 0, it will now see a non-zero exit. That's the intended fix, but it is a behavior change.

## The 24-command audit

With the parsing layer trustworthy, we audited every one of the CLI's 24 commands end to end and repaired what the audit surfaced ([#2882](https://github.com/wheels-dev/wheels/pull/2882), [#2883](https://github.com/wheels-dev/wheels/pull/2883), [#2884](https://github.com/wheels-dev/wheels/pull/2884), [#2885](https://github.com/wheels-dev/wheels/pull/2885), with tail-end polish in [#2888](https://github.com/wheels-dev/wheels/pull/2888)). A sampling:

- `wheels g` works as a true `generate` alias again, and `wheels <cmd> --help` gains per-command help rendered from each command's own metadata ([#2886](https://github.com/wheels-dev/wheels/pull/2886) — the rendering lights up fully with the next LuCLI runtime update).
- `wheels console` accepts `--password=<value>`, and `wheels reload` gained the same override for parity.
- `wheels generate api-resource` registers its resource route, and both `scaffold` and `api-resource` now honor `--hasOne` ([#2889](https://github.com/wheels-dev/wheels/pull/2889)).
- `wheels validate` strips CFML comments before source-scanning, so a commented-out `// component extends="Model"` can't satisfy (or trip) a check.
- The generators emit `enum()` definitions again, warn on view-generation failures instead of continuing silently, and the duplicate-route message names the offending route.
- `wheels start` warns when its pinned port is already taken instead of failing opaquely, and `wheels info` reports the framework version again.

## Your migrations can no longer hit someone else's database

This one deserves its own section because the failure mode is so nasty. The repro from [#2876](https://github.com/wheels-dev/wheels/issues/2876)/[#2878](https://github.com/wheels-dev/wheels/issues/2878): scaffold `app_a`, start its server, then `cd ../app_b` and run `wheels migrate latest` — and **app_b's migrations run against app_a's database.**

The cause: when a project had no port configured yet, the CLI's server detection fell back to probing a list of common ports (`8080`, `60000`, `3000`, `8500`) and attached to whatever answered — which on a developer machine is frequently a *different* project's server. For a read-only command that's a wrong answer; for `migrate` it's wrong DDL applied to the wrong schema.

In 4.0.3, every write-side command — `migrate` (all subcommands), `seed`, `reload`, and `generate admin` (which writes scaffolding based on the attached server's schema) — **requires a project-bound port** from `lucee.json` or `.env`. With none configured, they refuse with a clear diagnostic — set `port` in `lucee.json` (or `PORT` in `.env`), then `wheels start` — instead of guessing. Read-only commands (`info`, `routes`, `console`) keep the convenience fallback; they can't damage anything.

## Adapter fixes: PostgreSQL foreign keys, and Oracle before 23c

**Every PostgreSQL foreign-key migration was broken** ([#2876](https://github.com/wheels-dev/wheels/issues/2876)). Anything `wheels generate scaffold post title:string --belongsTo=author` produces — an inline FK constraint — crashed `wheels migrate latest` with `Component [PostgreSQLMigrator] has no function with name [addForeignKeyOptions]`: the PostgreSQL adapter was simply missing a method every sibling adapter implements. It's there now, CockroachDB inherits it automatically, and the "works on my machine" reports finally make sense — the `wheels new` default is SQLite, so only PostgreSQL/CockroachDB targets ever hit it.

**Oracle 19c/21c can drop tables again** ([#2869](https://github.com/wheels-dev/wheels/pull/2869)). The migrator emitted `DROP TABLE IF EXISTS ... CASCADE CONSTRAINTS`, but Oracle only added `IF EXISTS` in 23c — on anything older it's a hard parse error, which broke `migrate down`, rollbacks, and `force`-create. Both `dropTable()` and `dropView()` now emit the classic version-agnostic PL/SQL idiom (run the bare `DROP`, swallow ORA-00942), preserving drop-if-exists semantics on every supported Oracle version.

## Model properties keep their column casing

A long-standing 3.0-line regression, reported by a 2.x upgrader: auto-derived model property names were being **force-lowercased on every engine**, so an `isHidden` column surfaced as `ishidden` in serialized output (`returnAs="structs"`, `renderWith()`, `serializeJSON()`) on SQL Server, MySQL, and SQLite — silently breaking case-sensitive JSON consumers that worked fine on CFWheels 2.5 ([#2852](https://github.com/wheels-dev/wheels/pull/2852)). The lowercasing was only ever meant to normalize Oracle's fixed-case identifiers.

4.0.3 preserves the database's reported casing by default and lowercases only on adapters whose database folds unquoted identifiers to a meaningless UPPERCASE (Oracle, H2), via a new adapter capability. Models that explicitly declare `property(name="isHidden", column="isHidden")` were never affected.

> **Heads-up:** if your app *adapted* to the lowercased names — client code expecting `{"ishidden": 1}` — that output reverts to the declared casing (`{"isHidden": 1}`) on SQL Server / MySQL / SQLite after this patch. Review serialized-output consumers before upgrading.

## Security: framework helpers are no longer URL-invokable

Wheels mixes its global helpers (`env()`, `model()`, `redirectTo()`, `linkTo()`, …) into every controller, and the dispatch allow-list that was supposed to keep them from being *routed to* was initialized empty — a no-op. The result: an unauthenticated `GET /<anyController>/env` invoked the global `env()` helper directly (surfacing as a 500), and other helper names dispatched into unintended code paths ([#2844](https://github.com/wheels-dev/wheels/issues/2844)).

The allow-list is now populated at application start from the framework's actual mixin surface, so it stays in sync automatically. Reaching a helper name as an action returns a 404 like any other non-existent action.

> **Migration note:** if your app defined a controller action with the same name as a public framework helper (an action literally named `env`, `model`, or `redirectTo`), it now 404s instead of dispatching — rename it. The standard REST action names (`index`, `show`, `new`, `edit`, `create`, `update`, `delete`) are not helpers and are unaffected.

## Scaffolded secrets stay out of git

`wheels new` used to hard-code the generated reload password as a literal in `config/settings.cfm` — a tracked file — and repeat it in a comment ([#2857](https://github.com/wheels-dev/wheels/pull/2857)). New apps now read `set(reloadPassword=env("WHEELS_RELOAD_PASSWORD", ""))`, with the random value living only in the git-ignored `.env`. The Lucee Server Admin password is decoupled into its own generated `WHEELS_LUCEE_ADMIN_PASSWORD` secret ([#2860](https://github.com/wheels-dev/wheels/pull/2860)), resolved from `.env` at server start — so no committed file carries either one. The CLI still accepts the legacy unprefixed `RELOAD_PASSWORD` key, so existing apps keep working; if you adopt the new settings snippet in an older app, rename the key in your `.env` to match.

## Smaller fixes

- **The installed distribution loads again** ([#2873](https://github.com/wheels-dev/wheels/pull/2873)). The CLI's service classes were instantiated via a source-tree-only path that doesn't exist in the packaged module layout, so `wheels new` failed from the installed snapshot build while source-tree CI stayed green. The smoke-test gap that let it slip is closed too.
- **Fresh Windows installs work** ([#2835](https://github.com/wheels-dev/wheels/pull/2835)). `wheels new` on a Scoop install crashed with `there is no Resource provider available with the name [c]` — a mixed-slash path (`C:\Users\cy/blog`) tripping Lucee's URI scheme detection into treating `c:` as a resource provider. Paths are normalized before they reach Lucee.
- **Bare `wheels` prints help** instead of `has no function with name [main]` ([#2842](https://github.com/wheels-dev/wheels/pull/2842)).
- **The CLI test suite told the truth and got fixed** ([#2829](https://github.com/wheels-dev/wheels/issues/2829)). The BDD runner's `-1` error sentinel could arithmetically cancel real failures into a green summary; fixing the sentinel unmasked 13 pre-existing CLI spec failures, which were then repaired, and the CI runner now fails explicitly on a negative error count so this masking class is dead.
- **Browser-test login fixture is overridable** ([#2830](https://github.com/wheels-dev/wheels/issues/2830)). Apps with richer session shapes can point `/_browser/login-as` at their own controller##action via `set(browserLoginAsHandler=...)` — env-gating moves to middleware so the guard still applies.
- **RustCFML is recognized as an engine** ([#2837](https://github.com/wheels-dev/wheels/pull/2837)) — best-effort support for the young JVM-free CFML interpreter, with graceful cache degradation where `cfcache` doesn't exist yet.
- **wheels-bot reviews fork PRs** ([#2871](https://github.com/wheels-dev/wheels/pull/2871)) — external contributors get the same automated review loop, via a hardened `pull_request_target` flow that never executes fork-controlled code.
- **The apt install instructions actually work** ([#2846](https://github.com/wheels-dev/wheels/pull/2846)): the published key is ASCII-armored and needs `gpg --dearmor` before landing in the keyring — the docs now say so — and a bleeding-edge publish can no longer clobber the stable apt index ([#2838](https://github.com/wheels-dev/wheels/issues/2838)).
- **One docs tree per minor** ([#2827](https://github.com/wheels-dev/wheels/pull/2827)): the version switcher now reads "v4.0 (current)" and the vestigial pre-GA snapshot tree is gone, with redirects covering the old paths.

## Upgrading

One command, depending on how you installed:

```bash
brew upgrade wheels          # macOS
scoop update wheels          # Windows
sudo apt upgrade wheels      # Debian / Ubuntu
sudo dnf upgrade wheels      # Fedora / RHEL / Rocky
```

Three behavior changes to scan your app for, all covered above: CLI failures now exit non-zero (fix any script that relied on the old always-0 exit), serialized model output reverts to real column casing on SQL Server/MySQL/SQLite, and controller actions named after framework helpers now 404 (rename them).

The [4.0.3 release notes](https://github.com/wheels-dev/wheels/releases/tag/v4.0.3) on GitHub have the full PR list, and the [CHANGELOG](https://github.com/wheels-dev/wheels/blob/develop/CHANGELOG.md) carries the longer-form rationale for each entry.

A particular thank-you this release to everyone who filed CLI issues with exact command lines and exact output — the argument-parsing rebuild started from one well-written report about a flag that didn't stick. As always, the bleeding-edge channel (`brew install wheels-dev/wheels/wheels-be`, the Scoop `wheels-be` manifest, or the `bleeding-edge` suite on apt/yum) tracks `develop` if you want to ride ahead of the next patch.

Onward to 4.0.4.
