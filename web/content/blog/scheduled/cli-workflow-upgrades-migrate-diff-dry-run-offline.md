---
title: 'The CLI that stopped guessing: diff, dry-run, and offline'
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
  A deploy pipeline went green while doing nothing to the database, and a
  code review approved a generator run that had already written files. Both
  were "the CLI guessed wrong." 4.1 adds diff, dry-run, and offline mode —
  and the honesty fixes that make a green build mean something.
coverImage: '/blog-images/4-1/cli-workflow-upgrades-migrate-diff-dry-run-offline.png'
---

Two incidents. Both were "the CLI guessed," and both were only caught because someone looked closely at a diff.

The first: a deploy pipeline ran `wheels migrate latest`, exited zero, went green, and changed nothing. The database still had the old schema; the migration quietly did nothing because the AutoMigrator couldn't reconcile a renamed column. Nobody noticed until production. "The build succeeded" turned out to mean "the migrate command ran," not "the schema is right."

The second: a developer ran `wheels generate scaffold` in a review branch to show what it would produce, and it wrote forty files. The branch was already dirty. In review, the "just checking" run had become part of the PR — files nobody intended, attributed to nobody.

Both are the same disease: **a CLI that can only act, never show its work.** You can't dry-run what you can't preview. You can't review what you can't see. You can't trust exit-zero when zero is the default.

Wheels 4.1 treats that as a feature gap, not a documentation problem.

## `wheels migrate diff` — show before you write

The AutoMigrator has always reconciled your models with the database. What it couldn't do is *show* the reconciliation before applying it:

```sh
wheels migrate diff            # print the diff, change nothing
wheels migrate diff --write    # apply it
```

(`dbmigrate diff` works too, if your muscle memory predates the rename.)

The diff lists what would happen to each table — new columns, type changes, indexes — and accepts the knobs the AutoMigrator does, including `--rename` hints (the migrator can't know a column was renamed rather than dropped-and-added), a `--threshold` for how aggressively it matches changed columns, and `--hints` for the comparison settings.

The workflow becomes:

```sh
wheels migrate diff           # review the plan
wheels migrate diff --write   # apply it after review approves
```

That's the fix for incident one. The migrate step now has a "review" half that lives in code review, so the renamed column that used to be invisible becomes a line in a diff you actually read.

## `wheels generate --dry-run` — print, don't write

Every generator accepts `--dry-run` now:

```sh
wheels generate scaffold Post title:string body:text --dry-run
```

It prints the would-be file list — model, controller, views, migration, tests — and writes nothing.

That's the fix for incident two. "What would this generate" becomes an answerable question instead of a destructive experiment. Same mechanism under every generator (`model`, `controller`, `scaffold`, and the rest), so the flag behaves identically everywhere instead of being bolted onto one command.

## Offline mode — don't hang

CI runners, Docker builds, and air-gapped servers share a failure mode: the CLI reaches for the network and hangs, or fails twenty minutes into a build because a registry call timed out. 4.1 adds:

```sh
wheels migrate --offline
# or per-environment:
WHEELS_OFFLINE=1 wheels migrate latest
```

Two behaviors change: the update check is skipped entirely, and the package registry fails fast with a clear "offline" message instead of waiting on a socket. Accepted on `migrate` and `db` commands, so your database setup step behaves the same on a laptop with Wi-Fi and a build server with none.

## The honesty fixes

The same release makes "green" mean something again. The theme: **exit non-zero when you didn't do the thing you were asked to do.**

- **`wheels test` now exits non-zero** when the runner reports `directoryRejected`, `bundlesDiscovered=0`, or unloadable specs. A run that silently tested nothing is no longer reported as success. `wheels browser test` likewise exits non-zero on Fail/Error.
- **`wheels doctor` gained checks** — legacy `wheels.Test` specs, a non-empty `plugins/` directory, and raw `params.` mass assignment into `create`/`update`/`save`. All warn-only, comment-stripped scans, safe for CI.
- **`wheels destroy view` rejects path-join escapes** (`../x`), so deletes stay under `app/views/`.

The pattern is worth calling out: this release makes the CLI *fail closed*. "I couldn't do what you asked" is now a nonzero exit, not a silent pass. That's the difference between a tool that reports and a tool that lies politely.

## And the deploy side

One more for `wheels deploy`: the config now supports a `boot` block — Kamal-compatible `limit` and `wait` settings for how many containers boot at once and how long the healthcheck waits. If you've been rolling out with the default boot strategy, this is the knob for zero-downtime deploys.

## The lesson

Neither incident was a bug in the framework. Both were the CLI being *too confident* — acting where it should have asked, succeeding where it should have reported. The fix wasn't more documentation; it was giving every command a preview and teaching them an honest exit code.

Build pipelines will still go green sometimes when the world is broken. But "I ran migrate and here's the diff you approved" is a much better sentence than "it said it worked," and 4.1 is where the CLI learned to say the first one.

Next up in the series: read the next post — the full performance story, which starts with a bug report we spent a while not believing. (See the [series index](https://blog.wheels.dev/posts/wheels-4-1-coming/).)
