---
title: 'Wheels 4.0.2: shared-database migration reconciliation and native apt/yum repos'
slug: wheels-4-0-2-released
publishedAt: '2026-05-27T20:13:01.000Z'
updatedAt: '2026-05-28T03:20:32.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - release-notes
  - frameworks
categories:
  - Releases
excerpt: >-
  Wheels 4.0.2 is the second patch on the 4.0 line. It teaches the migrator
  how to cope with a database that more than one developer shares —
  orphan-version detection, a `migrate doctor` health report, and `forget` /
  `pretend` reconciliation commands — fixes a class of silent migration
  rollbacks on MSSQL, makes the migrator's column-name helpers consistent, and
  ships native signed apt.wheels.dev / yum.wheels.dev package repositories so
  Linux installs and upgrades are a one-liner.
coverImage: null
---

Wheels 4.0.2 ships today, a week after [4.0.1](https://github.com/wheels-dev/wheels/releases/tag/v4.0.1). Like 4.0.1 it is a patch release in the SemVer sense — no breaking changes, no new public APIs you have to learn — but where 4.0.1 was a broad post-GA shakeout, 4.0.2 has a center of gravity: the migrator, and specifically what happens to migrations when more than one developer points at the same development database.

If you work solo against your own database, most of this release is invisible to you (the apt/yum repos and a handful of fixes aside). If you're on a team that shares a dev database — or you've ever pulled a branch and watched `wheels migrate latest` quietly do nothing — this one is for you.

## Migrations when your team shares a dev database

The `wheels_migrator_versions` tracking table records which migrations have run. On a shared dev database it can drift out of sync with the migration files in your checkout: a teammate applies a migration, the tracking table records its version, but the file that produced it isn't on your branch yet. We call that an **orphan version** — a tracked version with no matching local file.

Before 4.0.2, an orphan at the top of the table sent `wheels migrate latest` down a misleading path: it saw a tracked version "ahead" of your latest local file, assumed you were rolling *back*, and silently no-op'd. You'd run the command, see nothing happen, and have no idea why ([#2798](https://github.com/wheels-dev/wheels/pull/2798)).

4.0.2 detects orphans explicitly and does the sensible thing instead — it warns you, names the orphan versions, and then applies your pending local migrations rather than no-op'ing:

```bash
wheels migrate latest
# [warning] These tracked versions have no migration file on this branch:
#   20260522101500  (applied by a peer?)
# Applying 1 pending local migration...
```

`wheels migrate info` now renders orphan rows with a `[?]` marker so a drifted table is obvious at a glance, Rails-style:

```
[x] 20260520090000  create_users
[?] 20260522101500  ********** NO FILE **********
[ ] 20260526140000  add_index_to_orders   (pending)
```

### A health report, and two reconciliation commands

Three new `wheels migrate` subcommands give you a way to *act* on drift — the Flyway `validate` / `repair` analogues for Wheels ([#2799](https://github.com/wheels-dev/wheels/pull/2799)):

```bash
wheels migrate doctor                    # health report: orphans + pending + applied count. Pure read; never mutates.
wheels migrate forget <version> --yes    # drop a stale tracking row WITHOUT running down()
wheels migrate pretend <version> --yes   # mark a version applied WITHOUT running up()
```

- **`doctor`** is a single-command, read-only health check. It lists orphan versions, pending local migrations, and the applied count — and prints in yellow when the migrator is unhealthy so a "succeeded but needs attention" result doesn't read as all-clear.
- **`forget`** removes a single row from `wheels_migrator_versions` without running `down()` — for when an orphan's table changes don't actually exist in your database and you just need the bookkeeping cleaned up. It refuses if a matching local file exists (use `migrate down` for that) or if the version isn't in the table.
- **`pretend`** inserts a tracking row without running `up()` — for when the schema change is already present (a peer applied it) and you only need to record that fact. It refuses if the version is already applied or if no local file matches.

Both `forget` and `pretend` are **dry-run by default** — without `--yes` they print exactly what they would do and exit without touching the table.

### The tracking table knows more now

`wheels_migrator_versions` gained two columns — `name` and `applied_at` ([#2800](https://github.com/wheels-dev/wheels/pull/2800)). They're additive and nullable, added automatically on the first migrator call after you upgrade, so existing rows keep working and simply display version-only. New migrations record their name and the time they ran, which is what lets `migrate info` show you *what* an orphan was and *when* a peer applied it — not just a bare version number.

The full walkthrough — what an orphan is, the three resolution paths, and the recommendation to avoid sharing a dev database in the first place — is in the new [Shared Development Databases](https://guides.wheels.dev/v4-0-0/basics/shared-development-databases/) guide under Basics.

## Two migrator correctness fixes worth calling out

**Model writes inside a migration no longer silently roll back on MSSQL** ([#2810](https://github.com/wheels-dev/wheels/pull/2810)). If your `up()` or `down()` called `model("Tag").create(...)` (or `update()` / `deleteAll()`), the row could vanish. The migrator wraps every `up()`/`down()` in its own outer transaction, and Model's default `transaction="commit"` opened a *nested* transaction on top — and nested-transaction semantics differ per JDBC driver. On MSSQL most acutely, the inner commit didn't release the row and the outer commit dropped it. The migrator now signals "I own the outer transaction" via a request-scoped flag, and Model skips the nested transaction when it sees it. Engine-agnostic, and the flag is cleared on both the success and error paths so it can't leak past the migration.

**No more spurious commit after a rollback** ([#2813](https://github.com/wheels-dev/wheels/pull/2813)). `migrateIndividual()` issued a `transaction action="commit"` unconditionally after its try/catch — including on the error path, where the catch had already rolled back. On Lucee that second action is a silent no-op, but on Adobe CF 2023/2025 the driver can throw "transaction not active" and *mask the real migration failure*, making the underlying problem much harder to diagnose. The commit is now skipped when the rollback fired.

## Consistent migrator helpers: `columnNames` everywhere

In 4.0.1 most `TableDefinition` column helpers already accepted `columnNames` / `columnName`, but `t.references()` insisted on `referenceNames` and `t.primaryKey()` insisted on `name` — the last two outliers. Both humans and AI agents kept reaching for the consistent form and hitting "argument required" errors. 4.0.2 closes the gap ([#2802](https://github.com/wheels-dev/wheels/pull/2802), [#2812](https://github.com/wheels-dev/wheels/pull/2812)), with a broader `Migration.cfc` command-consistency sweep alongside ([#2804](https://github.com/wheels-dev/wheels/pull/2804)):

```cfm
// 4.0.2 — matches every other column helper
t.references(columnNames="user");
t.primaryKey(columnNames="userId", autoIncrement=true);

// still works — the legacy forms aren't going away
t.references(referenceNames="user");
t.primaryKey(name="userId", autoIncrement=true);
```

`t.references()` also respects `useUnderscoreReferenceColumns` — when set, it produces `<name>_id` / `<name>_type` columns matching Wheels' `belongsTo` defaults. (The framework default is `false`; `wheels new` scaffolds new apps with it `true`.)

## `wheels upgrade check` learns to advise

The upgrade scanner only knew how to report *breaking* changes. 4.0.2 adds an **advisory tier** — opt-in recommendations that surface in a separate cyan "Recommended Improvements" section and never affect your exit code ([#2805](https://github.com/wheels-dev/wheels/pull/2805)). Advisory checks run on point-release upgrades too, not just major-version jumps.

The first concrete advisories pair with the helper work above ([#2807](https://github.com/wheels-dev/wheels/pull/2807)): if your migrations use `t.references(` the scanner suggests opting into `useUnderscoreReferenceColumns` to match `belongsTo` naming — and it's careful to note that *already-applied* migrations are unaffected, so you're not alarmed about your existing schema. It also warns about the mixed-convention trap of flipping that flag mid-project. The advisory is suppressed when the flag is already set (new apps ship with it on), and — like every check in the scanner now — it strips CFML comments before pattern-matching so a commented-out `// t.references(...)` doesn't trip a false positive. The pre-check that reads your settings was also widened to scan all of `config/`, not just one file ([#2809](https://github.com/wheels-dev/wheels/pull/2809)).

## Native apt and yum repositories

This is the second headline, and it's the one that touches every Linux user. **`apt.wheels.dev` and `yum.wheels.dev` are live, GPG-signed, and serving real package repositories** ([#2814](https://github.com/wheels-dev/wheels/pull/2814)). Installing and upgrading Wheels on Linux is now a normal package-manager operation — no GitHub-release download step, no manual `dpkg -i ./file.deb`:

```bash
# Debian / Ubuntu
curl -fsSL https://apt.wheels.dev/wheels.gpg \
  | sudo tee /usr/share/keyrings/wheels.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/wheels.gpg] https://apt.wheels.dev stable main" \
  | sudo tee /etc/apt/sources.list.d/wheels.list
sudo apt update && sudo apt install wheels

# Fedora / RHEL / Rocky
sudo dnf config-manager --add-repo https://yum.wheels.dev/wheels.repo
sudo dnf install wheels
```

Upgrades collapse to `sudo apt upgrade wheels` / `sudo dnf upgrade wheels` — one command, no version pinning. The repositories are signed with a dedicated `Wheels Distribution <hello@wheels.dev>` GPG key (fingerprint `6872 16C9 32B4 9F03 94E0 9AED 5D89 AF8F 9C9B 8CFB`), and both the apt `InRelease` index and the yum `repomd.xml.asc` verify against the published key. Under the hood they're served from Cloudflare R2 rather than Pages — Pages caps files at 25 MiB and the `.deb`/`.rpm` are ~80 MB — but the URL experience is identical to what was promised.

While we were in the Linux packaging code, 4.0.2 also fixes the regression where the `.deb`/`.rpm` double-nested the framework one directory too deep, crashing every fresh `wheels new` install on Ubuntu/Fedora with `could not find component or class with name [wheels.Injector]` ([#2776](https://github.com/wheels-dev/wheels/pull/2776)). The Linux packages now stage the framework at the same depth the Homebrew formula does.

## Compatibility matrix restored: BoxLang and Adobe CF 2023/2025

4.0.2 also greens the compatibility matrix for two engines that had been red since 4.0.0 ([#2817](https://github.com/wheels-dev/wheels/pull/2817)). **BoxLang** had been reporting 17 fail / 72 error on every database — traced to a single line in `Global.cfc`'s pseudo-constructor (`local.varKey = ""`), which BoxLang materializes as `variables.local` and which then shadows the function-local `local` scope of every mixed-in `$`-helper, so `local.appKey = $appKey()` resolved against `{varKey}` and threw `KeyNotFoundException`. Lucee and Adobe both keep `local` reserved to the function scope, so neither saw it; the loop now lives in a real function. **Adobe CF 2023/2025** had been crashing the entire suite (HTTP 404 with a ~1 MB HTML prefix corrupting the result JSON) ever since 4.0.1's `cfheader` fix uncovered a deeper response-already-committed cascade — `InvokeMethodSpec` was invoking `Public.index()` and flushing the congratulations welcome page into the test-runner response buffer, which Adobe then commits mid-run. The render is now captured with `cfsavecontent`, and five further Adobe-specific traps were fixed alongside (`request`-scope parameter shadowing in middleware, empty-body `cfhttp` POSTs in `TestClient`, array-by-value mutation in `ParallelRunner.$collectFailures`, double-`include` in `$reincludeGlobals`, a `fileWrite`/`fileRead` newline roundtrip on Adobe 2025, and `cf_sql_integer` overflow on CockroachDB's `unique_rowid()` PKs). Both engines now report zero failures across the full matrix CI — if you were holding off on 4.0 because your target engine was red, this is the release that closes that gap.

## Smaller fixes

- **Reserved-word column names work in `SELECT`** ([#2787](https://github.com/wheels-dev/wheels/pull/2787)). The `WHERE` and `ORDER BY` builders already quoted identifiers, but the `SELECT`/`GROUP BY` builder appended them raw — so a model backed by a table with a `key`, `order`, or `group` column blew up on `findAll`/`findOne` with a cryptic SQL syntax error the moment the select list mentioned it. Identifiers are now quoted there too.
- **`wheels packages install` aliases `add` on the paths LuCLI doesn't intercept** ([#2786](https://github.com/wheels-dev/wheels/pull/2786)). For MCP and programmatic callers, `install` now does exactly what `add` does instead of printing a warning and returning nothing. (At the shell, `wheels packages install` is still swallowed by LuCLI's built-in extension installer upstream of module dispatch, so shell users keep using `wheels packages add` — that's documented in the command's own `--help`.)
- **Clearer routing errors for redundant namespace prefixes** ([#2794](https://github.com/wheels-dev/wheels/pull/2794)). The mapper now rejects a redundant namespace prefix in `to=` / `controller=` instead of silently producing a route that points nowhere.
- **`?reload=true` re-includes changed `app/global/*.cfm` files** ([#2795](https://github.com/wheels-dev/wheels/pull/2795)), so edits to your global helpers take effect on a bare reload without a full server restart.
- **A friendlier fresh-install failure** ([#2774](https://github.com/wheels-dev/wheels/pull/2774)). When the Injector fails to construct during application start (a stale `/wheels` mapping under Lucee Express, say), the generated app's `onError` now guards `application.wo` and preserves the *original* error behind a minimal HTML fallback — instead of cascading into the opaque `The key [WO] does not exist` exception that tripped up "Your First 15 Minutes" tutorial readers.
- A cluster of test-harness fixes: `BrowserTest` resolves its base URL through a layered lookup at instance time ([#2783](https://github.com/wheels-dev/wheels/pull/2783)) and gives a clearer hint when `this.browser` is unwired ([#2782](https://github.com/wheels-dev/wheels/pull/2782)); `WheelsTest` auto-binds include-injected globals into the spec scope ([#2793](https://github.com/wheels-dev/wheels/pull/2793)); and `test-local.sh` no longer dies silently when `~/.lucli/express` is missing ([#2796](https://github.com/wheels-dev/wheels/pull/2796)).

## Upgrading

If you're on 4.0.0 or 4.0.1, upgrading is a one-liner and requires no code changes:

```bash
brew upgrade wheels          # macOS
scoop update wheels          # Windows
sudo apt upgrade wheels      # Debian / Ubuntu  (or add the repo above first)
sudo dnf upgrade wheels      # Fedora / RHEL / Rocky
```

The migrator's new tracking-table columns are added automatically the first time you run any `wheels migrate` command after upgrading — there's nothing to run by hand.

The [4.0.2 release notes](https://github.com/wheels-dev/wheels/releases/tag/v4.0.2) on GitHub have the full PR list, and the [CHANGELOG](https://github.com/wheels-dev/wheels/blob/develop/CHANGELOG.md) carries the longer-form rationale for each entry.

Thank you to everyone running a shared dev database who filed an issue describing exactly how `migrate latest` confused them — the reconciliation tooling in this release exists because you told us what the silent no-op felt like from the other side. As always, the bleeding-edge channel (`brew install wheels-dev/wheels/wheels-be`, the Scoop `wheels-be` manifest, or the `bleeding-edge` suite on apt/yum) tracks `develop` if you want to ride ahead of the next patch.

Onward to 4.0.3.

