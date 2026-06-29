---
title: Seeding Your Database the Idempotent Way
slug: idempotent-database-seeding
publishedAt: '2026-06-29T14:00:00.000Z'
updatedAt: '2026-06-19T15:10:00.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - seeding
  - database
  - cli
categories: []
excerpt: >-
  Wheels 4.0 ships a convention-based seeder built around seedOnce() — an
  idempotent helper that creates a record only if a matching one doesn't
  already exist, wrapped in a transaction that rolls the whole run back on any
  failure. This is the worked guide: file conventions, the CLI, composite
  uniqueness, and the sharp edges.
coverImage: null
---

Here's the seed script every Wheels app eventually grows. It starts as three `INSERT` statements in a migration — an `admin` role, a `member` role, a `site.name` setting — because you need them in the database before the app does anything useful. Then a teammate runs the migration on their machine, the rows land, and a week later someone re-runs the whole migration suite on a fresh checkout and you get a primary-key collision because the `admin` role already exists. So you wrap each insert in a `SELECT ... WHERE NOT EXISTS`. Then the settings table grows a column and you go edit eight near-identical `WHERE NOT EXISTS` blocks. Then you need different data in development than in production and there's no clean place to put the split.

Seed data has the same shape everywhere: *make sure this row exists; if it already does, leave it alone; do it the same way in every environment, every time, without blowing up on the second run.* That property has a name — idempotency — and Wheels 4.0 ships a seeder built entirely around it.

The whole thing is two file conventions and one helper function. The helper is `seedOnce()`. The convention is `app/db/seeds.cfm` plus `app/db/seeds/<environment>.cfm`. This post walks both end-to-end, shows the CLI that runs them, and is honest about where the sharp edges are.

## seedOnce, the one function that matters

`seedOnce()` is the idempotent seed helper. Its signature:

```cfm
seedOnce(modelName="Role", uniqueProperties="name", properties={
    name: "admin", description: "Administrator with full access"
});
```

Three arguments, all named:

| Argument | Type | What it does |
|---|---|---|
| `modelName` | string | The model to seed — `"Role"`, `"User"`, `"Setting"`. |
| `uniqueProperties` | string | Comma-delimited list of property names that define "already exists". |
| `properties` | struct | *All* properties for the new record — including the unique ones. |

The mechanics are deliberately boring, which is what you want from data infrastructure. Internally, `seedOnce()` builds a SQL `WHERE` clause from `uniqueProperties` — `name = 'admin'` — and calls `model("Role").findOne(where=...)`. If that finds a row, the seed is a no-op: it bumps a `totalSkipped` counter and returns `{model, action: "skipped", uniqueProperties}`. If nothing matches, it runs `model("Role").new(properties).save()`. On success it bumps `totalCreated` and returns `{model, action: "created", key}`. On a validation failure it bumps `totalFailed` and returns `{model, action: "failed", errors}`.

Run the same `seedOnce()` call twice and the second run does nothing but a `findOne()`. Run it a hundred times and you still have exactly one `admin` role. That's the entire value proposition — the helper is safe to run whenever, as many times as you like.

One detail that surprises people, so let's say it up front: **idempotency here is an existence check, not an upsert.** `seedOnce()` checks whether a matching row exists and skips creation if it does. It never *updates* the existing record. If you change `description` on a re-run, the matching `admin` row keeps its old description and the call is counted as skipped. The helper guarantees the row is there; it does not reconcile the row's contents with your latest `properties` struct. If you need to change existing data, that's a migration, not a re-seed.

## The file convention

The seeder runs two files, in a fixed order, every time:

```
app/db/seeds.cfm                  <- shared seeds, runs first in EVERY environment
app/db/seeds/development.cfm      <- development-only, runs after seeds.cfm
app/db/seeds/production.cfm       <- production-only, runs after seeds.cfm
```

`app/db/seeds.cfm` runs first, in every environment. Then `app/db/seeds/<environment>.cfm` runs after it, where `<environment>` is whatever environment you're seeding. The environment file is a sibling `seeds/` *directory*, not a suffix on the filename — it's `seeds/development.cfm`, not `seeds-development.cfm`. Get that wrong and your environment seeds silently don't run, because the file the seeder looks for isn't there.

Shared things — roles, settings, lookup tables — go in `seeds.cfm`. Things that differ per environment — a dev admin user, a pile of fake test records — go in the environment file. Here's a real `seeds.cfm`:

```cfm
<!--- app/db/seeds.cfm --->
<!--- Shared seeds: run in all environments --->
<cfscript>

// Roles
seedOnce(modelName="Role", uniqueProperties="name", properties={
    name: "admin", description: "Administrator with full access"
});
seedOnce(modelName="Role", uniqueProperties="name", properties={
    name: "member", description: "Regular member"
});

// Settings
seedOnce(modelName="Setting", uniqueProperties="key", properties={
    key: "site.name", value: "My Wheels App"
});
seedOnce(modelName="Setting", uniqueProperties="key", properties={
    key: "site.perPage", value: "25"
});

</cfscript>
```

And the development-only companion:

```cfm
<!--- app/db/seeds/development.cfm --->
<!--- Development-only seeds: test data --->
<cfscript>

// Dev admin user
seedOnce(modelName="User", uniqueProperties="email", properties={
    firstName: "Dev", lastName: "Admin",
    email: "admin@example.com", roleId: 1
});

// Sample records for development
for (var i = 1; i <= 10; i++) {
    seedOnce(modelName="User", uniqueProperties="email", properties={
        firstName: "Test", lastName: "User #i#",
        email: "user#i#@example.com", roleId: 2
    });
}

</cfscript>
```

Two things to notice about that second file. First, the loop. Because every `seedOnce()` is independently idempotent, you can wrap them in any control flow you like — a loop, a conditional, a call out to another model — and re-running stays safe. The tenth `user10@example.com` either exists or it doesn't; the loop body doesn't care which run it's on. Second, you call `seedOnce()` as a bare, unscoped function inside these files. No `application.`, no `this.`, no prefix at all. That works because the seeder includes these `.cfm` files from *inside* the Seeder component, so `seedOnce` resolves to the component's own method. Don't prefix it. (In test or programmatic code, where you're not inside an included seed file, you call it on the instance instead — more on that below.)

## Composite uniqueness

`uniqueProperties` is a comma-delimited list, and it can name more than one property. When it does, *every* listed property goes into the `WHERE` check with `AND`, and *every* one of them must appear in the `properties` struct:

```cfm
// A record is unique on the (firstName, lastName) pair.
// First run creates; an identical re-run finds the match and skips.
seedOnce(
    modelName = "Author",
    uniqueProperties = "firstName,lastName",
    properties = { firstName: "Ada", lastName: "Lovelace", bio: "Pioneer" }
);
// Resulting action: "created" first time, "skipped" thereafter.
```

That builds `firstName = 'Ada' AND lastName = 'Lovelace'` and matches on the pair. Use composite uniqueness when no single column identifies the record — a join row, a per-tenant setting, a person with no natural unique key. The rule is mechanical: whatever you list in `uniqueProperties`, you must also supply in `properties`. Leave one out and you get a `Wheels.Seeder.MissingProperty` error rather than a silent partial check.

## The whole run is one transaction

This is the design decision that makes the seeder trustworthy, and it's worth understanding before you write your first seed file.

`runSeeds()` wraps both files — `seeds.cfm` and the environment file — in a *single* database transaction. If anything goes wrong, the whole thing rolls back. "Anything" includes a thrown error, but it also includes the quieter failure: if even one `seedOnce()` entry fails validation (`totalFailed > 0`), the entire transaction rolls back — including records that already saved successfully earlier in the same run — and the call returns `success: false` with the failed entries named in the message.

That's deliberate (issue #2973). The alternative — commit what worked, report what didn't — was explicitly rejected. The reasoning: a half-applied seed run must never look identical to a fully-applied one. If you seed 40 rows, the 41st fails a validation, and the framework commits the first 40, your next `findOne()`-based health check sees rows and assumes the seed succeeded. Now you've got 40 of 41 rows and nothing tells you. Rollback makes failure loud and total. And because `seedOnce()` is idempotent, the recovery is trivial: fix the broken entry and re-run. Everything that already existed gets skipped, everything that didn't gets created, and you end up in the same place you'd have been if the first run had succeeded.

So the failure model is: all-or-nothing per run, but safe to re-run on the way to all. That's the best of both worlds — you never get a confusing partial state, and you never have to manually clean up before retrying.

## Running it: the CLI

The command is `wheels seed`. Not `wheels db:seed` — that's not a command and it errors. `wheels seed`.

```bash
# Run seeds against the running dev server. Auto-detects the current environment.
wheels seed

# Target a specific environment explicitly
wheels seed --environment=production
```

A few things the command does that are worth knowing:

It **requires a running, project-bound dev server.** Seeds execute over the dev-server HTTP bridge (a `POST` to `/wheels/cli` with `command=dbSeed`), so the server has to be up. With no server, `wheels seed` errors out with a hint to set the port and run `wheels start` first. Run your server, then seed.

Its default mode is **`auto`.** In auto mode the CLI asks the framework whether convention seed files exist (`hasSeedFiles()` — true if `app/db/seeds.cfm` exists, or if `app/db/seeds/` contains at least one `.cfm`). If they do, it runs convention seeding through `seedOnce()`. If they don't, it falls back to the legacy generated-data path. All the options are **named** — there are no positional arguments to `wheels seed`.

That legacy path is worth a warning of its own:

```bash
# Legacy: random generated test data (NOT idempotent)
wheels seed --generate
```

`--generate` (shorthand for `--mode=generate`) seeds *random* test data for every model — 10 records each by default — and it bypasses `seedOnce()` and idempotency entirely. Run it twice and you get duplicate junk. It exists for quick throwaway dev data, nothing more. It is not convention seeding, and you should not point it at anything you care about.

## Scaffolding the files

You don't have to write `seeds.cfm` from a blank page. There's a scaffolder — exactly one — and it's a `snippets` generator:

```bash
# Scaffold starter seed files (the ONLY seed scaffolder)
wheels generate snippets seed-data
#   writes app/snippets/seeds.cfm and app/snippets/seeds-development.cfm
```

That writes two starter files full of working `seedOnce()` examples — the same examples shown above, in fact. The catch: they land in `app/snippets/`, not in `app/db/`. Snippets are reference templates, not active files. To activate them, move or copy them into place:

```bash
# Move/copy them into place to activate:
#   app/snippets/seeds.cfm            -> app/db/seeds.cfm
#   app/snippets/seeds-development.cfm -> app/db/seeds/development.cfm
```

Note the rename on the second one: `seeds-development.cfm` (snippet name) becomes `seeds/development.cfm` (the real convention — sibling directory, not hyphenated suffix). The demo app ships no `app/db/` directory at all, so this whole convention is opt-in; the scaffolder is how you opt in.

And one more non-command to file away: **`wheels generate seed` is not a generator.** That token doesn't match anything in the generate switch and throws `Wheels.InvalidArguments`. The only seed scaffolder is `wheels generate snippets seed-data`.

## Seeding from code

The CLI is a thin wrapper over a framework object. At application start — when `application.wheels.enableMigratorComponent` is true — Wheels constructs a Seeder singleton and parks it at `application.wheels.seeder`. That's the same object the CLI drives over the bridge, and you can call it directly from app code, a scheduled task, or a test:

```cfm
// Run seeds from app code / a task. Equivalent to `wheels seed`.
result = application.wheels.seeder.runSeeds();              // current environment
result = application.wheels.seeder.runSeeds(environment="staging");

// result = { success, message, environment, results,
//            totalCreated, totalSkipped, totalFailed }
if (!result.success) {
    // a failed entry rolled the WHOLE run back; result.message names the failures
    throw(message=result.message);
}
```

`runSeeds()` returns the full result struct so you can branch on it. `success` is the boolean to check; `message` is human-readable and, on failure, names the entries that broke; `totalCreated` / `totalSkipped` / `totalFailed` give you the counts. On a successful run `totalFailed` is always `0` — by the rollback rule above, a run with any failures isn't a successful run.

Note the call site difference. Inside a seed `.cfm` file you call `seedOnce()` bare, because you're executing inside the Seeder component. Here, in app code, you're *outside* it, so you reach the helper through the instance — `application.wheels.seeder.seedOnce(...)` — or, more usually, you just call `runSeeds()` and let it include the convention files for you.

## Sharp edges

The seeder is small, but it has a handful of edges that will cost you an afternoon if you don't know about them. All of these are real, all of them are in the code.

**It's a skip, never an update.** Worth repeating because it's the most common wrong assumption. `seedOnce()` does a `findOne()` existence check and skips creation if a row matches. It does not update. Changing the non-unique properties on a re-run has no effect — the matching row is left exactly as it was and counted as skipped. The helper keeps a row present; it does not keep a row current.

**Every unique property must be present and simple.** Each name in `uniqueProperties` has to exist in `properties` (omit one and you get `Wheels.Seeder.MissingProperty`) and has to be a simple value — string, number, date, boolean. Pass a struct or array or object as a unique value and you get `Wheels.Seeder.InvalidUniqueValue`. Pass an empty `uniqueProperties` and you get `Wheels.Seeder.EmptyUniqueProperties` — that one exists specifically because an empty `WHERE` clause would match an arbitrary row and silently skip your seed, which is the worst possible failure mode (looks fine, does nothing).

**The unique-value WHERE clause is string-interpolated, not parameter-bound.** The value goes into the `WHERE` clause directly, with single quotes escaped (`'` → `''`), as `prop = '<value>'`. This is the same "direct SQL only" posture as the migrator's seed-data rule. Keep `uniqueProperties` values to simple strings, numbers, dates, and booleans — which the type check already enforces — and you're fine. Don't try to be clever with the unique values.

**The environment name is regex-validated.** Because the environment name gets interpolated into the include path for `seeds/<environment>.cfm`, `runSeeds()` validates it against `^[A-Za-z0-9_-]+$` and throws `Wheels.Seeder.InvalidEnvironment` on anything else. That's a path-traversal guard — you can't slip `../../../something` into it. Stick to ordinary environment names and you'll never see it.

**The result struct shape varies by action.** `result.key` exists only on the `created` path. On `skipped` the struct carries `uniqueProperties`; on `failed` it carries `errors` (the model's `allErrors()`). If you're reading `seedOnce()` return values directly — say, logging keys of created records — guard for the action first. Don't assume `result.key` is there for a skipped or failed entry.

**`--generate` is not seeding.** Said it above, saying it again because the flag is one keystroke away from being a mistake. `wheels seed --generate` produces random data, ignores `seedOnce()`, ignores idempotency, and duplicates on every run. It's a dev-convenience toy, not a seeding strategy.

## The shape of it

Strip away the details and the seeder is one idea applied consistently. Data that should exist gets declared once, idempotently, in a convention location, and the framework makes it exist — safely, repeatably, in the right environment, rolled back cleanly if anything's wrong.

The payoff is that seeding stops being a thing you're nervous about. You don't audit the database before running seeds. You don't keep a "have I already run this?" note. You don't write `WHERE NOT EXISTS` by hand for the fortieth time. You write `seedOnce()`, you run `wheels seed`, and you run it again next week without a second thought. That's the whole point of building the idempotency in at the bottom: everything above it gets to stop worrying about it.

Scaffold the files with `wheels generate snippets seed-data`, move them into `app/db/`, and run `wheels seed`. That's the loop.
