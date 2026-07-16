---
title: Running Wheels 4 the CommandBox Way
slug: wheels-4-the-commandbox-way
publishedAt: '2026-07-16T14:00:00.000Z'
updatedAt: '2026-07-06T05:14:40.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - commandbox
  - tooling
  - ci
categories: []
excerpt: >-
  CommandBox teams do not have to switch. The complete box-native workflow for
  Wheels 4 — install from ForgeBox, engine selection with cfengine,
  datasources via CFConfig, every framework task's in-app equivalent, CI with
  setup-commandbox, and an honest accounting of what the wheels CLI adds if
  you ever want it.
coverImage: null
---

If your team has used CommandBox for years — `box install` for packages, `box server start` for engines, `server.json` in every repo — Wheels 4's arrival with its own CLI probably read as a question mark over your whole setup. We've heard the wariness directly in [the discussions](https://github.com/wheels-dev/wheels/discussions/1838): *do we have to switch?*

No. This post is the complete CommandBox-native workflow for Wheels 4 — install, serve, engines, datasources, framework tasks, CI, packages — with the support contract stated precisely, because "it mostly works" is not a contract.

## The contract, stated precisely

In Wheels 4, CommandBox is supported as a **server manager and package fetcher** — indefinitely. That means:

| You want to… | CommandBox? | How |
|---|---|---|
| Install the framework | **Yes** | `box install wheels-base-template` |
| Vendor the core into an existing app | **Yes** | `box install wheels-core` |
| Run a server — Lucee, Adobe CF, or BoxLang | **Yes** | `box server start` (with `cfengine=` to pick) |
| Manage datasources per project | **Yes** | CFConfig in `server.json` — the scaffold ships the module |
| Scaffold, generate, migrate, test, seed, deploy from a terminal | **No** | those are `wheels` CLI commands — but every one has an in-app equivalent that works under CommandBox (below) |

That last row is the one that used to feel like a wall, and isn't. The `wheels` CLI is a *client* of surfaces the framework exposes to every app regardless of what serves it. Your CommandBox-served app has all of them.

## Install and serve

```bash
box
mkdir myapp --cd
install wheels-base-template
server start
```

`wheels-base-template` pulls `wheels-core` into `vendor/wheels/` automatically via its install path — the resulting app is structurally identical to what `wheels new` produces, because it's the same skeleton published to ForgeBox. `server start` reads the shipped `server.json`, and the shipped `public/urlrewrite.xml` gives you pretty URLs out of the box, because CommandBox's underlying server uses the same Tuckey rewrite filter the wheels CLI does.

Engine selection is the CommandBox you already know:

```bash
server start cfengine=lucee@7
server start cfengine=adobe@2023
```

(BoxLang rides the same `cfengine=` mechanism — check `box server start help` on your CommandBox version for the current slug.)

This is genuinely a CommandBox *advantage*: the wheels CLI's dev server runs its bundled Lucee, while `cfengine=` gives you the exact engine and version production runs — Adobe shops especially should develop on the engine they deploy to.

## Datasources, the cfconfig way

The scaffolded `box.json` already lists `commandbox-cfconfig` in its dev dependencies, so the blessed path for per-project datasources is a `cfconfig` block in `server.json`:

```json
"cfconfig": {
    "datasources": {
        "myapp_dev": {
            "dbdriver": "MySQL",
            "host": "localhost", "port": 3306,
            "database": "myapp",
            "username": "wheels", "password": "${DB_PASSWORD}"
        }
    }
}
```

CFConfig applies it at server start, on whichever engine you picked. Point `set(dataSourceName="myapp_dev")` in `config/settings.cfm` at it and you're wired. The [Database and Multiple Datasources guide](https://guides.wheels.dev/v4-0-0/basics/database-and-multiple-datasources/#registering-a-datasource) shows this shape next to the lucee.json and engine-admin variants.

## Framework tasks without the wheels CLI

Here's the map your team actually needs — every `wheels` command you'd see in the docs, translated to what a CommandBox-served app does instead:

- **Reload** after config changes: `?reload=true&password=<your-reload-password>` on any URL. The password comes from `.env`, which the app reads itself.
- **Run migrations**: the browser migrator GUI at `/wheels/migrator` in development, or `application.wheels.migrator.migrateToLatest()` programmatically in any environment — or `set(autoMigrateDatabase=true)` and migrations apply at startup.
- **Write migrations**: they're plain CFCs in `app/migrator/migrations/` named `YYYYMMDDHHMMSS_description.cfc` — the generator only saves boilerplate.
- **Run tests**: `/wheels/app/tests` in a browser; add `?format=json` for machine-readable results. This URL is literally what `wheels test` calls under the hood.
- **Seed**: `application.wheels.seeder.runSeeds()` from any server-side code path.
- **Generators**: no runtime equivalent — they just write files. The patterns live in [The Basics](https://guides.wheels.dev/v4-0-0/basics/), and honestly, most CommandBox teams we know have their own scaffolding habits anyway.

Two fine points. First, the `/wheels/*` browser surfaces are development-only — a hard allowlist since 4.0.4, no setting opens them in production; the programmatic calls are the production path. Second, the `<datasource>_test` auto-swap during test runs is a wheels-CLI convenience — the raw runner uses whatever datasource the app is configured with, so point your dev datasource somewhere you're happy to let `tests/populate.cfm` rebuild.

Every task page in the guides now shows this as a first-class labeled path — "Without the wheels CLI" — next to the CLI one. That's your column.

## CI with the setup-commandbox action

Ortus publishes a GitHub Action, and the whole test job is four steps:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    env:
      WHEELS_CI: "true"
    steps:
      - uses: actions/checkout@v4
      - uses: Ortus-Solutions/setup-commandbox@v2
      - run: box install && box server start
      - run: |
          curl -s --max-time 600 -o results.json \
            "http://localhost:8080/wheels/app/tests?format=json"
          python3 -c "import json; d=json.load(open('results.json')); \
            raise SystemExit(0 if d.get('totalFail',0)==0 and d.get('totalError',0)==0 else 1)"
```

And because engine selection is a `server start` argument, a cross-engine matrix is just `strategy.matrix.cfengine: ["lucee@7", "adobe@2023", "adobe@2025"]` with `fail-fast: false`. The [CI Integration guide](https://guides.wheels.dev/v4-0-0/testing/ci-integration/) has the full version including browser-test gating and caching.

## Packages: mind the two registries

One naming collision to keep straight, because both registries matter to a CommandBox shop:

- **ForgeBox** is where the *framework* lives — `wheels-base-template`, `wheels-core`. That's what `box install` talks to.
- **The Wheels packages registry** (`wheels-dev/wheels-packages` on GitHub) is where *framework packages* live — `wheels-sentry`, `wheels-hotwire`, `wheels-basecoat`, `wheels-i18n`. That's what `wheels packages add` talks to.

A package listed in one is not necessarily in the other. Without the wheels CLI, installing a package is: download its release, extract into `vendor/<name>/`, reload. The loader auto-discovers everything under `vendor/*/package.json` and doesn't care how the files arrived — `box install`, git submodule, unzip, rsync; all the same to it.

## What you'd be giving up (an honest accounting)

Staying CommandBox-only, the wheels CLI features you genuinely don't get are: the generators, `wheels console` (the REPL against your running app), `wheels upgrade check` (the breaking-change scanner — though you can run it once on a laptop without adopting anything on your servers), the `wheels deploy` deployer, and the MCP server for AI-assisted development. None gate the framework; all are reasons you might someday install the CLI *alongside* CommandBox — which works fine, since they don't fight over anything.

The point of Wheels 4's tooling posture isn't that everyone should use the wheels CLI. It's that the framework runs identically no matter what installed it and what serves it — and that your team's decade of CommandBox muscle memory is an asset, not technical debt. Start at [Installing with CommandBox](https://guides.wheels.dev/v4-0-0/start-here/installing-with-commandbox/); the support-tier table there is the durable version of this post's contract.

