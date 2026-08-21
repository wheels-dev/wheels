---
title: 'Wheels 4 Without the Tooling: Two Zips, Zero Dependencies'
slug: wheels-4-without-the-tooling
publishedAt: '2026-07-09T14:00:00.000Z'
updatedAt: '2026-07-06T05:06:04.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - installation
  - no-cli
  - deployment
categories: []
excerpt: >-
  The manual install that took the community two days to reverse-engineer in
  Wheels 3 is now two zip files and zero external dependencies. How to
  install, migrate, test, seed, and upgrade a Wheels 4 app with no CLI, no
  CommandBox, and no package manager — plus the new guides that document every
  step.
coverImage: null
---

A few days ago, a long-time Wheels developer posted something in [GitHub discussion #1838](https://github.com/wheels-dev/wheels/discussions/1838) that stung because it was true: his team had built a twelve-term glossary — CommandBox, ForgeBox, LuCLI, Homebrew, Scoop, buckets, binaries, JARs — just to be able to *read* our Getting Started guide. They'd been shipping Wheels apps since 2.5 on their own IIS servers with their own git-based deploy workflow, and everything in the 4.0 docs assumed a tooling stack they had deliberately chosen not to adopt.

The thread goes back to the 3.0 release, and it documents, comment by comment, what installing Wheels without tooling used to require: download `wheels-base-template`, download `wheels-core`, download WireBox, download TestBox, then discover TestBox silently needs four more modules (Globber, cbMockData, CBStreams, cbproxies), each extracted into an exactly-named folder, one of them nested inside another one. Two full working days to reverse-engineer. Community members eventually posted working recipes *in the thread* because the docs didn't have them.

Here's the thing that thread deserves to have said back to it, loudly: **in Wheels 4, all of that is gone.** The manual install is two zip files and zero external dependencies. This post is the whole story — how to install, run, migrate, test, seed, and upgrade a Wheels 4 app without the `wheels` CLI, CommandBox, or any package manager touching your machine.

## Two zips. That's the list.

Every release publishes its artifacts on the [GitHub releases page](https://github.com/wheels-dev/wheels/releases). For a new app you need exactly two:

| File | What it is | Where it goes |
|---|---|---|
| `wheels-base-template-4.0.5.zip` | The app skeleton: `app/`, `config/`, `public/`, `tests/`, an empty `vendor/` | Extract as your app root |
| `wheels-core-4.0.5.zip` | The framework — a single `wheels/` folder | Extract into `vendor/`, so it becomes `vendor/wheels/` |

No WireBox. No TestBox. No module scavenger hunt. Wheels 4 ships its own dependency-injection container (`vendor/wheels/Injector.cfc`) and its own test framework (`vendor/wheels/wheelstest/` — the `wheels.WheelsTest` BDD base class), so the framework's complete dependency list is: *the framework*.

If you're wondering whether we're sure — we assembled and booted an app from the actual 4.0.5 release zips while writing the new guides, and the base template's `box.json` declares exactly one dependency: `wheels-core`. Even that only matters if you use CommandBox; on a manual install it's inert metadata.

## The contract: point a web server at `public/`

Extract the base template, drop the core into `vendor/`, and the layout looks like this:

```
myapp/
  app/          your models, controllers, views
  config/       settings.cfm, routes.cfm, environment.cfm
  db/           SQLite files, if you use SQLite
  public/       THE WEB ROOT — the only folder a browser can reach
  tests/        your specs
  vendor/
    wheels/     the framework
  .env          copied from env.example
```

The entire wiring contract lives in one file, `public/Application.cfc`, and it's six mappings:

```cfm
this.mappings["/app"]     = expandPath("../app/");
this.mappings["/vendor"]  = expandPath("../vendor/");
this.mappings["/wheels"]  = expandPath("../vendor/wheels/");
this.mappings["/tests"]   = expandPath("../tests");
this.mappings["/config"]  = expandPath("../config");
this.mappings["/plugins"] = expandPath("../plugins");
```

Everything is relative to `public/`, so the app runs from any disk location under any server — IIS site, nginx root, Apache DocumentRoot, a bare Lucee webroot. And because the web root is `public/` and *only* `public/`, your models, config, `.env`, and the framework itself are unreachable from a browser by construction.

Three setup steps after extraction:

1. **Copy `env.example` to `.env`** and set `WHEELS_RELOAD_PASSWORD`. The template's `Application.cfc` reads this file itself at startup — no dotenv tooling involved.
2. **Create a datasource named `wheels`** in your engine's admin (Lucee admin or ColdFusion Administrator), or change `set(dataSourceName="wheels")` in `config/settings.cfm` to a datasource you already have. On Adobe ColdFusion, register it in the CF Administrator — that's the reliable path.
3. **Decide on URL rewriting.** The template defaults to `URLRewriting="On"`, which expects a server rewrite rule (`/posts/1` → `/index.cfm/posts/1`). The shipped `urlrewrite.xml` only works on Tuckey-based servers — the [URL Rewriting guide](https://guides.wheels.dev/v4-0-0/deployment/url-rewriting/) has the equivalent rule for nginx, Apache, and IIS. Or set `URLRewriting="Partial"` and skip server config entirely: URLs take the `/index.cfm/posts/1` form and everything works.

Load the site. Congratulations page. Done.

## "But the CLI does things" — every one of them has an in-framework equivalent

The objection we heard for two years: the docs describe framework tasks as CLI commands, so opting out of the CLI reads like opting out of the framework. It never was — the CLI is a *client* of surfaces the framework exposes to everyone — but we did a poor job saying so. Here's the map.

| Task | With the wheels CLI | Without it |
|---|---|---|
| Reload after config changes | `wheels reload` | `?reload=true&password=<your-reload-password>` on any URL |
| Run migrations | `wheels migrate latest` | `/wheels/migrator` GUI in the browser, or `application.wheels.migrator.migrateToLatest()` from any server-side code |
| Migration status | `wheels migrate info` | Same GUI, or `application.wheels.migrator.getCurrentMigrationVersion()` |
| Write a migration | `wheels g migration CreatePosts` | It's a plain CFC in `app/migrator/migrations/` named `YYYYMMDDHHMMSS_description.cfc` with `up()`/`down()` — copy an existing one |
| Run app tests | `wheels test` | `/wheels/app/tests` in a browser; `?format=json` for machine-readable output (that URL is literally what the CLI calls) |
| Seed data | `wheels seed` | `application.wheels.seeder.runSeeds()` — callable from a deploy hook or admin action |
| Install a package | `wheels packages add wheels-sentry` | Extract the package release into `vendor/wheels-sentry/` and reload — packages are auto-discovered from `vendor/*/package.json` |
| Upgrade the framework | `wheels upgrade apply` | Swap `vendor/wheels/` with the new core zip (back up the old one first) |

One honest asterisk on availability: the browser surfaces under `/wheels/*` — the migrator GUI, the test runner, routes and info pages — are **development-only**. Since 4.0.4 they sit behind a hard environment allowlist ([#2903](https://github.com/wheels-dev/wheels/pull/2903)) and return 404 in every other environment, and no setting opens them in production. That's deliberate: they expose schema and internals no production app should serve. The production-safe equivalents are the programmatic calls — `migrateToLatest()` and `runSeeds()` from a protected code path — plus the password-gated URL reload, which works everywhere precisely because it demands the `reloadPassword` from your `.env`.

Two of those programmatic surfaces deserve a closer look, because they change how no-CLI deployment feels.

**Migrations at boot.** Set `set(autoMigrateDatabase=true)` in `config/production/settings.cfm` and pending migrations apply when the application starts — which turns "deploy new code, then run migrations" into just "deploy new code and restart." On a single node this is the simplest correct pipeline there is. (Think twice on multi-node setups, where every node would race to migrate at boot.)

**Seeding as a function call.** `application.wheels.seeder.runSeeds()` is the exact call `wheels seed` makes — same transaction wrapper, same `seeds.cfm` → `seeds/<environment>.cfm` order, same `seedOnce()` idempotency. Call it from an authenticated admin action and your ops story needs no shell access at all.

## Upgrading without the CLI is a folder swap

The framework is `vendor/wheels/`. Upgrading is replacing that folder — which is precisely what `wheels upgrade apply` automates, backup included. By hand:

1. Move `vendor/wheels/` aside (e.g. `vendor/wheels-4.0.4.bak/`). Moving it back is the entire rollback.
2. Extract the new `wheels-core` zip into `vendor/` — fresh, not over the top, because releases delete files as well as add them.
3. Hit `?reload=true&password=…` and confirm the new version in the debug bar (development) or by outputting `application.$wheels.version`.
4. Run your suite at `/wheels/app/tests`.

If you deploy from git and commit `vendor/wheels/` — common for deliberate-workflow teams, and completely reasonable — the swap happens on a branch and rides your normal review pipeline like any other change.

For the 3.x → 4.0 jump there's required reading first (eleven breaking changes, all enumerated with remediations in the [upgrade guide](https://guides.wheels.dev/v4-0-0/upgrading/3x-to-4x/)), and one pleasant surprise: your 3.x `vendor/` probably contains `wirebox/` and `testbox/` folders. Wheels 4 needs neither. Delete them if they existed only for Wheels.

## The docs now say all of this

This post condenses a set of guides that shipped this week, built directly from the #1838 feedback — including having testers walk the documentation cold, in character as the people in that thread:

- [Manual Installation (zip / GitHub)](https://guides.wheels.dev/v4-0-0/start-here/manual-installation/) — the two-zip install, written against the real release artifacts
- [Choosing Your Tooling](https://guides.wheels.dev/v4-0-0/start-here/choosing-your-tooling/) — the decision page, grown from the glossary that community team wrote for themselves; it answers "do CommandBox shops have to switch?" (no) and "is a GitHub download supported?" (yes) in bold
- [Working Without the CLI](https://guides.wheels.dev/v4-0-0/start-here/working-without-the-cli/) — the equivalents table above, maintained, with per-environment availability
- [Upgrading Without the CLI](https://guides.wheels.dev/v4-0-0/upgrading/manual-upgrades/) — the folder-swap recipe in full
- [Anatomy of a Wheels App](https://guides.wheels.dev/v4-0-0/start-here/app-structure/) — the six-mapping contract and every directory explained
- [IIS and Windows Deployment](https://guides.wheels.dev/v4-0-0/deployment/iis-and-windows/) — the IIS walkthrough, assembled from the working CF2025 + IIS + MySQL 8 recipe the community proved out in the thread itself

And the guides landing page now routes by situation — "I don't use CLI tooling" is a front door, not an archaeology project.

## Why this matters beyond the no-CLI crowd

If you *love* the CLI, nothing changed for you — `wheels new` to first request is still the fastest path, and the tutorial still assumes it. What changed is the framework's posture: every capability now has a documented life outside the tooling, which means the tooling is an accelerator rather than a dependency. That's healthier for everyone. Tools come and go; a framework that installs from a zip file and runs on any CFML engine pointed at a folder is the thing that lasts twenty years. Wheels has been that framework since 2005. Now the docs act like it again.

If you hit anything that doesn't match this post on your setup — IIS corners especially — [say so in the discussions](https://github.com/wheels-dev/wheels/discussions). The fastest way to get a page fixed is to tell us exactly where it's wrong.

