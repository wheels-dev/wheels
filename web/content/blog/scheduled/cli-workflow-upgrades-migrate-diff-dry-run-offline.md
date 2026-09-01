---
title: 'CLI upgrades in 4.1: migrate diff, generate --dry-run, and offline mode'
slug: cli-workflow-upgrades-migrate-diff-dry-run-offline
publishedAt: '2026-09-06T14:00:00.000Z'
updatedAt: null
author: Peter Amiri
tags:
  - wheels-4
  - CLI
  - wheels-cli
categories:
  - CLI
excerpt: >-
  Wheels 4.1 gives the CLI three workflow tools that used to require
  guesswork: migrate diff previews the schema changes the AutoMigrator would
  make, generate --dry-run prints generated files without writing them, and
  offline mode keeps CI and air-gapped builds from hanging on network calls.
coverImage: null
---

The Wheels CLI grew up around scaffolding — `wheels generate`, `wheels migrate`, `wheels deploy`. What it was missing was the *what-will-this-do* half of those commands. 4.1 fills that gap with three additions, plus a batch of honesty fixes that make the CLI fail loudly when something is wrong instead of exiting zero.

## `wheels migrate diff`

The AutoMigrator has always been able to reconcile your model definitions with the database. What it couldn't do was *show* you the reconciliation before applying it. Now:

```sh
wheels migrate diff            # print the diff, change nothing
wheels migrate diff --write    # apply it
```

(There's a `dbmigrate diff` alias if your muscle memory predates the rename.)

The diff lists what the migrator would do to each table — new columns, type changes, indexes — and accepts the same knobs the AutoMigrator does, including `--rename` hints for when a column was renamed rather than dropped-and-added (the migrator can't know that on its own), a `--threshold` for how aggressively it matches changed columns, and `--hints` for the comparison settings. The useful workflow this enables:

```sh
wheels migrate diff           # review in code review
wheels migrate diff --write   # apply after the review approves
```

For teams that version migrations by hand, `diff` is a review tool, not a replacement — but for apps living the AutoMigrator life, it turns "trust the magic" into "read the plan."

## `wheels generate --dry-run`

Generators write files. Before 4.1, the only way to see what a generator would write was to run it in a scratch copy and diff. Now every generator accepts `--dry-run`:

```sh
wheels generate scaffold Post title:string body:text --dry-run
```

It prints the would-be file list — model, controller, views, migration, tests — and writes nothing. No partial state to clean up, no "wait, it created the migration already?" moment. It's the same mechanism under every generator (`model`, `controller`, `scaffold`, and the rest), so the flag behaves identically everywhere instead of being bolted onto one command.

## Offline mode

CI runners, Docker builds, and air-gapped servers share one failure mode: the CLI reaches for the network and hangs, or fails twenty minutes into a build. 4.1 adds:

```sh
wheels migrate --offline
# or, per-environment:
WHEELS_OFFLINE=1 wheels migrate latest
```

Two behaviors change: the CLI's update check is skipped entirely, and the package registry fails fast with a clear "offline" message instead of timing out on a socket. Accepted on `migrate` and `db` commands, so your database setup step works identically on a laptop with Wi-Fi and a build server with none.

## Honesty fixes in the same release

Smaller, but they'll save you a bad deploy:

- **`wheels test` now exits non-zero** when the runner reports `directoryRejected`, `bundlesDiscovered=0`, or unloadable specs — a "green" run that silently tested nothing is no longer reported as success. `wheels browser test` similarly exits non-zero on Fail/Error.
- **`wheels doctor` learned new checks** — legacy `wheels.Test` (RocketUnit) specs in your app, non-empty `plugins/` directories from the deprecated plugin system, and raw `params.` mass assignment into `create`/`update`/`save`. All warn-only, comment-stripped scans, so they're safe to run in CI.
- **`wheels destroy view` rejects path-join escapes** (`../x` and friends), so deletes stay under `app/views/`.

## The deploy side

One more thing for the `wheels deploy` users: the deploy config now supports a `boot` block — Kamal-compatible `limit` and `wait` settings for how many containers boot at once and how long the healthcheck waits. If you've been deploying with the default boot strategy, this is the knob you've been missing for zero-downtime rolls.

Everything here is documented in the CLI reference in the guides; the `--dry-run` and `--offline` flags in particular are the kind of thing you want in your muscle memory *before* the next incident, not after.
