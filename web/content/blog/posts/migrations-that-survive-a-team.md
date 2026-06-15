---
title: 'Migrations That Survive a Team: the Wheels 4.0 Migrator'
slug: migrations-that-survive-a-team
publishedAt: '2026-06-15T14:00:00.000Z'
updatedAt: '2026-06-14T15:53:10.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - migrations
  - migrator
  - cli
  - database
categories: []
excerpt: >-
  A broad how-to on the Wheels 4.0 migrator: write up()/down() migrations,
  drive the TableDefinition column builder (including the three-column
  timestamps() and the columnNames-preferred helpers), seed with inline SQL,
  and run the migrate CLI — including the doctor/info/forget/pretend commands
  that keep a shared dev database honest.
coverImage: null
---

A migration that works perfectly on your laptop is not the bar. The bar is the migration that still works three weeks later, on a teammate's checkout, against a dev database that four people have been writing to, after someone rebased a branch where the file numbering shuffled. That's the migration that survives a team — and it's the one most ORMs make surprisingly hard to write.

Wheels 4.0's migrator is built around that second bar. The mechanics are familiar — a `Migration.cfc` per file with `up()` and `down()`, an in-memory table builder you chain columns onto, a CLI that walks the files forward and backward. What's new is everything around the edges: each migration runs in its own transaction so a failure leaves you somewhere consistent, the column helpers all speak the same `columnNames` argument so you stop guessing, and there's a `doctor`/`forget`/`pretend` trio that exists specifically because shared dev databases drift.

This post walks the whole thing end to end — write a migration, drive the builder, seed data, run the commands, and reconcile a database that's gotten out of sync. Everything here is the real surface; nothing's invented.

## The shape of a migration

A migration is a CFC under `app/migrator/migrations/` that extends `wheels.migrator.Migration` and implements `up()` (apply) and `down()` (roll back). The filename carries the version: a 3-to-14-digit prefix, an underscore, and a name. `wheels generate` stamps a 14-digit `yyyymmddHHMMSS` timestamp; legacy `001_`, `002_` numbering still works too.

```cfm
// app/migrator/migrations/20260419130000_create_posts.cfc
component extends="wheels.migrator.Migration" hint="create posts table" {

    function up() {
        transaction {
            t = createTable(name="posts");          // id PK auto-added (id=true)
            t.string(columnNames="title,slug");      // two VARCHARs in one call
            t.text(columnNames="body", allowNull=true);
            t.boolean(columnNames="published", default=false);
            t.references(columnNames="author");      // author_id (or authorid) + FK
            t.timestamps();                          // createdAt, updatedAt, deletedAt
            t.create();                              // <-- emits the CREATE TABLE
        }
    }

    function down() {
        transaction {
            dropTable("posts");
        }
    }
}
```

The filename regex (`^([\d]{3,14})_([^\.]*)\.cfc$`) matters more than it looks. A file that doesn't match — say you dropped the underscore, or named it `create-posts.cfc` — is **silently ignored**. It won't error; it just won't show up in `migrate info` and won't run. When a migration "isn't running," check the filename first.

The two halves are not symmetric in cost. Your `up()` is where the work happens; your `down()` is your insurance policy. Write both. A migration with an empty `down()` is a migration you can't safely roll back on a teammate's machine, which means it's not a migration that survives a team.

## createTable returns a builder — nothing happens until create()

Here's the single most important thing to internalize about the table builder, and it trips up everyone once.

`createTable()` does not create a table. It returns a `TableDefinition` — an in-memory builder. Every `t.string(...)`, `t.references(...)`, `t.timestamps()` call mutates that builder and returns it again so you can chain. **No DDL has run.** The `CREATE TABLE` statement only gets emitted when you call the terminal method:

```cfm
t = createTable(name="posts");
t.string(columnNames="title");
// ... if you stop here, NOTHING happened. No table. No error. No table.
t.create();   // <-- THIS is the line that talks to the database
```

Forget `t.create()` and your migration "succeeds," records itself as applied, and leaves you with no table. The builder is lazy by design — it lets the adapter assemble one statement with all the columns and foreign keys — but laziness means the terminal call is mandatory.

There are two terminal methods, one per builder entry point:

| You started with | Terminal call | What it emits |
|---|---|---|
| `createTable(name="x")` | `t.create()` | `CREATE TABLE` (drops first if `force=true`), plus any registered FKs |
| `changeTable("x")` | `t.change()` | `ALTER TABLE ...` for the new/changed columns, plus any registered FKs |

`createTable(name="posts")` also gives you a free autoincrement `id` primary key, because `id=true` is the default. That's why the example above never declares one. If you want to suppress it — composite keys, a natural key, a join table — pass `id=false`.

```cfm
createTable(name="posts")                  // gets an `id` PK for free
createTable(name="posts", primaryKey="postId")   // PK named postId instead
createTable(name="memberships", id=false) // no auto PK at all
createTable(name="posts", force=true)     // DROP then CREATE — destructive, dev only
```

## The column helpers all speak columnNames

Every column helper on the builder takes the same argument shape, and the preferred name is **`columnNames`** — plural. The singular `columnName` still works as an alias (resolved internally by `$combineArguments`), but new code should reach for the plural, because most helpers let you add several columns in one call:

```cfm
t.string(columnNames="firstName,lastName,email");   // three VARCHARs at once
t.integer(columnNames="viewCount,shareCount", default=0);
```

The full type surface:

| Helper | Adds | Notes |
|---|---|---|
| `t.string(columnNames=…)` | VARCHAR | comma-list adds several |
| `t.text(columnNames=…, size=…)` | TEXT | `size="mediumtext"`/`"longtext"` on MySQL; ignored elsewhere |
| `t.integer(columnNames=…)` | INTEGER | also `bigInteger` |
| `t.boolean(columnNames=…)` | BOOLEAN | |
| `t.datetime(columnNames=…)` | DATETIME | also `date`, `time`, `timestamp` |
| `t.decimal` / `t.float` / `t.char` / `t.binary` / `t.uniqueidentifier` | as named | |
| `t.references(columnNames=…)` | FK integer column + constraint | the association helper |
| `t.primaryKey(columnNames=…)` | PK column | special — see below |
| `t.timestamps()` | createdAt, updatedAt, deletedAt | **three** columns |

Two argument conventions hold across all of them. The nullable flag is always **`allowNull`** — never `null`. And there's a `default` for literal column defaults. Note that `default` takes a literal value baked into the DDL, not a SQL function — for dynamic defaults you set values at insert time (more on that under seeding).

### timestamps() adds THREE columns

This is the gotcha that bites people migrating from other frameworks. `t.timestamps()` does **not** add two columns. It adds three:

- `createdAt`
- `updatedAt`
- `deletedAt` — the soft-delete marker

The names come from the `timeStampOnCreateProperty`, `timeStampOnUpdateProperty`, and `softDeleteProperty` settings (those are the defaults). Wheels treats a non-null `deletedAt` as "this row is soft-deleted" and filters it out of normal finds automatically. So:

```cfm
// WRONG — you'll end up with duplicate columns and a confused soft-delete
t.datetime(columnNames="createdAt");
t.datetime(columnNames="updatedAt");
t.datetime(columnNames="deletedAt");

// RIGHT — one call, all three, correctly named
t.timestamps();
```

Never hand-roll `createdAt`/`updatedAt`/`deletedAt`. Call `timestamps()` and let the framework own those three names.

### references() builds the foreign key

`t.references(columnNames="author")` does two things: adds an integer column for the foreign key, and (unless you opt out) registers a matching FK constraint pointing at the pluralized table's `id`. The column name is where apps differ:

```cfm
t.references(columnNames="author");
// useUnderscoreReferenceColumns = false (framework default)  -> column `authorid`
// useUnderscoreReferenceColumns = true  (wheels-new default)  -> column `author_id`
```

That setting is read at **runtime**, per migration. A `wheels new` app defaults it to `true` so the column matches what Wheels models expect from `belongsTo`. The bare framework default is `false`. The practical consequence: the *same migration code* can produce `authorid` in one app and `author_id` in another. Already-applied migrations are untouched — only the next migration's generated name changes — but if you're copying a migration between projects, check the setting before you assume the column name.

Useful `references()` options, all named:

```cfm
t.references(columnNames="author");                          // FK column + constraint
t.references(columnNames="author", foreignKey=false);        // column only, no constraint
t.references(columnNames="commentable", polymorphic=true);   // adds *id AND *type, no FK
t.references(columnNames="author", onDelete="CASCADE");      // ON DELETE behavior
```

### primaryKey() does NOT split on commas

Every other helper treats `columnNames` as a comma-list. `primaryKey()` is the deliberate exception. It always makes exactly **one** column, so `columnNames="a,b"` gives you a single column literally named `a,b` — almost certainly not what you meant. For a composite key, call it once per column:

```cfm
function up() {
    transaction {
        t = createTable(name="memberships", id=false);  // suppress the auto id PK
        t.primaryKey(columnNames="userId");              // one PK column
        t.primaryKey(columnNames="groupId");             // second PK column (composite)
        t.datetime(columnNames="joinedAt", allowNull=true);
        t.create();
    }
}
```

`primaryKey()` forces `allowNull=false` (a PK can't be null) and throws if you try to mark a second column `autoIncrement=true` — you get exactly one autoincrementing key per table.

## Altering an existing table

To add or change columns on a table that already exists, start from `changeTable()` instead of `createTable()`. You get a builder bound to the existing table (no free `id` PK this time), add your columns, and call `t.change()`:

```cfm
component extends="wheels.migrator.Migration" hint="add status to posts" {

    function up() {
        transaction {
            t = changeTable("posts");
            t.string(columnNames="status", default="draft");
            t.change(addColumns=true);   // <-- emits the ALTER
        }
    }

    function down() {
        transaction {
            removeColumn(table="posts", columnNames="status");
        }
    }
}
```

`change(addColumns=true)` adds the columns that aren't present yet. Without `addColumns=true`, `change()` issues `ALTER ... CHANGE COLUMN` for existing columns instead — that's the path for altering a column's type or constraints rather than adding new ones.

For one-off alterations you don't need a builder for, there are standalone Migration methods that execute immediately: `addColumn`, `changeColumn`, `removeColumn`, `addIndex`, `addReference`, `dropReference`, `addForeignKey`. They all accept the same modern `columnNames`/`columnName` arguments as the builder (and `columnNames` aliasing the legacy `referenceName` for the reference variants), and they run the DDL the moment you call them — no terminal `.create()`/`.change()` needed:

```cfm
addColumn(table="posts", columnType="string", columnNames="subtitle");
addIndex(table="posts", columnNames="slug", unique=true);
removeColumn(table="posts", columnNames="subtitle");
```

## Seeding inside a migration: inline SQL only

Migrations sometimes need to seed a row — a default role, a settings record. The method for raw SQL is `execute()`, and it has exactly one argument: `sql`. A string. That's it.

There is **no `parameters` argument**. None. If you write `execute(sql="...", parameters=[...])`, the `parameters` key is silently ignored — the signature doesn't accept it, so binding is impossible through `execute()`. Use fully inline SQL, and use `NOW()` for dates because it's portable across MySQL, PostgreSQL, MSSQL, H2, and SQLite:

```cfm
function up() {
    transaction {
        t = changeTable("posts");
        t.string(columnNames="status", default="draft");
        t.change(addColumns=true);
    }
    // INLINE SQL only — NOW() works on every supported engine
    execute("INSERT INTO roles (name, createdAt, updatedAt) VALUES ('admin', NOW(), NOW())");
}

function down() {
    transaction {
        removeColumn(table="posts", columnNames="status");
    }
    execute("DELETE FROM roles WHERE name = 'admin'");
}
```

If you genuinely need parameter binding — user-derived values, anything where inline string-building makes you nervous — `execute()` is the wrong tool. The Migration base class has `addRecord()` and `updateRecord()`, which build parameterized `INSERT`/`UPDATE` statements internally. Reach for those when binding matters; reach for `execute()` for fixed, known-safe SQL.

## Running migrations

The CLI is the day-to-day surface. Four commands move the database:

```bash
wheels migrate latest   # apply every pending migration, in order
wheels migrate up        # apply the next single pending migration
wheels migrate down      # roll back the most recent applied migration
wheels migrate info      # list every migration and its state
```

If you're driving the framework from an AI editor over MCP, the same operations are exposed as the `migrate` tool with `action="latest|up|down|info|doctor"` — same engine underneath.

The thing worth knowing about how these run: **each migration's `up()` or `down()` executes in its own transaction.** If a migration fails, that single migration rolls back and the loop *stops* — later pending migrations don't run. The tracking row is only written (on `up`) or removed (on `down`) inside the transaction that succeeded. So a failure leaves you in a defined state: everything before the failure is applied and recorded, the failing migration is fully rolled back and not recorded, and everything after it is untouched. You fix the broken migration and re-run; you don't get a half-applied table with a tracking table that lies about it.

`wheels migrate info` is your map. It leads with a summary header (current version, totals, per-state counts), then prints one indented line per migration. The `[x]`/`[ ]` marker carries the state — there's no extra "(applied)"/"(pending)" text:

```text
Current version: 20260419131500
Total migrations: 3
  applied: 2
  pending: 1

Migrations (newest last):
  [x] 20260419130000 create_posts
  [x] 20260419131500 add_status_to_posts
  [ ] 20260420090000 add_comments
```

`[x]` applied, `[ ]` pending. There's a third marker — `[?]` — and that's where the team part of the story begins.

## When the database drifts: orphans, doctor, forget, pretend

Here's the scenario the migrator was hardened for. You and a teammate share one dev database. They write a migration, apply it, and their `up()` runs against the shared DB — recording version `20260419130000` in the tracking table. But their migration *file* is on a branch you haven't pulled. Now your checkout has a tracking-table row for a version with **no matching file in `app/migrator/migrations/`**.

That's an **orphan**. It's not corruption — it's the normal, expected consequence of sharing a database across branches. The migrator detects it and refuses to do anything dumb about it.

`wheels migrate info` flags orphans with `[?]`, adds an `orphan:` count to the summary, and renders the row inline in version order:

```text
  [x] 20260419120000 create_posts
  [?] 20260419130000 ********** NO FILE **********
  [ ] 20260420090000 add_comments
```

(On a freshly upgraded install the orphan may show version-only until the next migration runs — the enriched name/timestamp columns are populated lazily. More on that in the gotchas.)

The orphan-aware behavior that saves you: `migrate latest` checks *why* the database sits "above" your latest local file. If it's above only because of orphan rows, it **suppresses the down branch** — it won't roll anything back, won't print a misleading "migrating from X down to Y." It applies any genuinely pending local migrations (with a warning about the orphans) or tells you there's nothing to do. Without this, a naive migrator would see "DB version > my latest file" and try to roll back to "catch up," which is exactly backwards.

For inspecting the situation, `doctor` is the one-command health report — and it's a pure read, it mutates nothing:

```bash
wheels migrate doctor
```

It reports the current version, the orphan list, pending local migrations, the applied count, and a one-line human summary. `healthy` is true only when there are zero orphans *and* zero pending migrations. Run it when `info` looks weird and you want the structured picture.

Two commands actually reconcile, and both require `--yes` on the CLI:

```bash
# Peer applied a migration whose FILE isn't in your branch, and never will be
# (it got squashed, renamed, abandoned). Drop the stale tracking row:
wheels migrate forget 20260419130000 --yes

# Peer applied a migration via direct SQL; the file IS in your branch now and
# you just need the tracking table to agree it's already applied:
wheels migrate pretend 20260419130000 --yes
```

They're mirror images, and each has a guard that keeps you honest:

- **`forget`** deletes a tracking row *without* running `down()`. It refuses if the version isn't actually in the tracking table, and — importantly — it refuses if a matching local file *does* exist. If the file is there, you don't want `forget`; you want `migrate down`, which actually reverses the schema change. `forget` is strictly for orphan rows whose files are gone.
- **`pretend`** inserts a tracking row *without* running `up()`. It refuses if the version is already applied, and refuses if there's no matching local file. Use it only to make the tracking table agree with a schema change that already physically happened.

This whole reconciliation story has its own deep treatment — the [Wheels 4.0.2 release notes](https://blog.wheels.dev/posts/wheels-4-0-2-released) cover the shared-database reconciliation work in full. For the purposes of writing migrations, the takeaway is short: orphans are normal on a shared DB, `info`/`doctor` show them, and `forget`/`pretend` clean them up with guardrails so you can't reconcile the wrong way.

## Sharp edges

The factsheet-backed list of things that will bite you, collected:

- **The terminal call is mandatory.** Building columns on a `TableDefinition` runs no DDL. `createTable(...)` needs `.create()`; `changeTable(...)` needs `.change()`. Forget it and the migration "succeeds" with no table or no ALTER — and records itself applied.
- **`timestamps()` adds three columns**, not two: `createdAt`, `updatedAt`, `deletedAt`. Don't add separate datetime columns for these and don't assume there are only two.
- **`execute()` takes only `sql`** — there is no `parameters`/binding argument. A `parameters=[...]` key is ignored. Use inline SQL with `NOW()` for portable dates, or `addRecord()`/`updateRecord()` when you truly need binding.
- **`primaryKey()` does not comma-split `columnNames`.** `columnNames="a,b"` makes one column named `a,b`. Call `primaryKey()` once per column for composite keys, and remember only one PK may be `autoIncrement=true`.
- **`references()` column naming is runtime-dependent.** `useUnderscoreReferenceColumns` (framework default `false` → `userid`; `wheels new` default `true` → `user_id`) is read per migration. The same code yields different column names in different apps. Already-applied migrations are unaffected.
- **Filename must match `^([\d]{3,14})_([^\.]*)\.cfc$`.** A 3–14-digit version, an underscore, a name. Non-matching files are silently ignored — no error, no listing, no run.
- **A failed migration stops the loop.** Each `up()`/`down()` runs in its own transaction; on failure that one rolls back and later pending migrations don't run. The DB stays consistent, but "I ran `migrate latest` and only some applied" usually means an earlier one failed — check the output.
- **Enriched tracking columns populate lazily.** The `name`/`applied_at` columns are added only on a *mutating* migrator call (`latest`/`up`/`down`/`pretend`), never on a pure read (`info`/`doctor`). Right after an upgrade, orphan rows may show version-only until your next real migration runs. Legacy rows stay NULL — there's no backfill. (SQLite stores `applied_at` as TEXT and writes the timestamp explicitly at insert time, because it can't `DEFAULT` a TIMESTAMP on `ALTER ADD`.)
- **Orphans aren't errors.** A `[?]` row is a normal shared-DB situation, not corruption. Don't "fix" it by force-rolling-back — `migrate latest` is already orphan-aware. Reconcile deliberately with `forget`/`pretend`.

## Putting it together

The discipline that makes a migration survive a team isn't complicated, it's just consistent:

1. One change per migration, with a real `down()`.
2. `createTable`/`changeTable`, chain the `columnNames` helpers, **call the terminal method**.
3. `timestamps()` for the three audit columns — never roll your own.
4. `references()` for associations; check `useUnderscoreReferenceColumns` if you're moving code between apps.
5. Seed with inline SQL and `NOW()`; reach for `addRecord()` when you need binding.
6. `wheels migrate latest`, then `wheels migrate info` to confirm.
7. When a shared DB looks weird, `wheels migrate doctor` before you touch anything — then `forget`/`pretend` with `--yes` to reconcile.

The migrator's specs live under `vendor/wheels/tests/specs/migrator/` (`referencesSpec`, `primaryKeySpec`, `migrationSpec`, `OrphanDetectionSpec`, `MigratorInfoSpec`, `MigratorReconciliationSpec`), and you can run them locally with `bash tools/test-local.sh migrator`. If you're extending the builder, that's the contract to read first.

Write the `down()`. Call `.create()`. Run `doctor` when in doubt. That's a migration that survives a team.
