# Wheels 4.0.2 — social copy (draft for review)

Admin import mapping (`POST localhost:8585/api/posts`):

| This section | Admin field |
|---|---|
| X / Twitter | `xCopy` |
| LinkedIn | `linkedinCopy` |
| Slack / Discord | `slackCopy` |
| Reddit / GitHub Discussions (long-form) | `discussionsCopy` |

Not tracked by the admin (no column): **Bluesky, Mastodon, Hacker News** — post manually or add a migration if you want them tracked.

Replace `RELEASE_URL` with the published blog-post URL once it's live. All copy assumes the v4.0.2 release is actually cut.

---

## X / Twitter — `xCopy`

Wheels 4.0.2 is out. Migration reconciliation for teams sharing a dev database — `wheels migrate doctor` / `forget` / `pretend` to fix a drifted tracking table. Plus native apt + yum repos and consistent columnNames migrator helpers. No breaking changes. RELEASE_URL

<!-- Optional thread continuation (post as replies if you want a thread):

2/ The problem it solves: on a shared dev DB, a teammate's migration gets recorded in wheels_migrator_versions but the file isn't on your branch yet. Before 4.0.2, `wheels migrate latest` saw that "orphan" version and silently no-op'd. Now it warns and applies your pending migrations.

3/ `wheels migrate doctor` is a read-only health report (orphans + pending + applied count). `forget` drops a stale tracking row without running down(); `pretend` records a version as applied without running up(). Both are dry-run unless you pass --yes.

4/ Linux installs are now a one-liner: add the signed apt.wheels.dev / yum.wheels.dev repo and `apt install wheels` / `dnf install wheels`. Upgrades are `apt upgrade wheels`. No more downloading a .deb from GitHub Releases.
-->

---

## LinkedIn — `linkedinCopy`

Wheels 4.0.2 is out — the second patch on the 4.0 line, with no breaking changes and a clear focus: making database migrations behave when more than one developer shares a development database.

If your team has ever pulled a branch and watched `wheels migrate latest` quietly do nothing, you've hit an "orphan version" — a migration recorded in the tracking table whose file isn't on your branch yet, because a teammate applied it first. 4.0.2 detects that situation explicitly instead of silently no-op'ing, and adds three reconciliation commands modeled on Flyway's validate/repair workflow:

• `wheels migrate doctor` — a read-only health report listing orphans, pending migrations, and applied count
• `wheels migrate forget` — drop a stale tracking row without running down()
• `wheels migrate pretend` — record a version as applied without running up()

(Both forget and pretend are dry-run by default — they show you what they'd do until you pass --yes.)

The release also fixes a class of silent migration rollbacks on SQL Server, makes the migrator's column-name helpers consistent (`t.references(columnNames=...)` and `t.primaryKey(columnNames=...)` now match every other helper), and — the part every Linux user will feel — ships native signed package repositories at apt.wheels.dev and yum.wheels.dev. Installing and upgrading Wheels on Debian, Ubuntu, Fedora, RHEL, or Rocky is now a normal one-line package-manager operation.

Upgrade with `brew upgrade wheels`, `scoop update wheels`, `apt upgrade wheels`, or `dnf upgrade wheels`. Full notes: RELEASE_URL

#CFML #ColdFusion #Lucee #BoxLang #WebDevelopment #OpenSource

---

## Slack / Discord — `slackCopy`

*Wheels 4.0.2 is out* :tada:  (second patch on the 4.0 line — no breaking changes)

The theme this time is *migrations on a shared dev database*. If a teammate's migration ever got recorded in your tracking table without the file being on your branch — an _orphan version_ — `wheels migrate latest` used to silently do nothing. Now it warns you and applies your pending migrations instead.

Three new reconciliation commands:
• `wheels migrate doctor` — read-only health report (orphans + pending + applied count)
• `wheels migrate forget <version> --yes` — drop a stale tracking row, no `down()`
• `wheels migrate pretend <version> --yes` — mark a version applied, no `up()`

Also in 4.0.2:
• Fixed silent migration rollbacks on SQL Server when `up()`/`down()` write via the model
• `t.references()` and `t.primaryKey()` now accept `columnNames` like every other helper
• *Native apt/yum repos* — `apt install wheels` / `dnf install wheels` and `apt upgrade wheels` now Just Work

Upgrade: `brew upgrade wheels` / `scoop update wheels` / `apt upgrade wheels` / `dnf upgrade wheels`
Full write-up: RELEASE_URL

<!-- Note: Slack uses mrkdwn (*single* asterisks for bold, <url|label> for links). The :tada: emoji is optional — drop it if you'd rather keep emoji out. Discord renders **double-asterisk** bold, so if you post the same copy to Discord, switch *bold* -> **bold**. -->

---

## Reddit / GitHub Discussions — `discussionsCopy`

**Title:** Wheels 4.0.2 released — migration reconciliation for shared dev databases, native apt/yum repos

Wheels 4.0.2 is out, six days after 4.0.1. It's a patch release (no breaking changes), and unlike the broad 4.0.1 shakeout it has a clear center of gravity: the database migrator.

**Migrations on a shared dev database.** The `wheels_migrator_versions` tracking table records which migrations have run. When a team shares one development database, that table can drift from the files in your checkout — a teammate applies a migration, the version gets recorded, but the file isn't on your branch yet. We call that an *orphan version*. Before 4.0.2, an orphan at the top of the table fooled `wheels migrate latest` into thinking you were rolling back, so it silently did nothing. Now the migrator detects orphans, warns you (naming the versions), and applies your pending local migrations instead.

There are also three new reconciliation subcommands, modeled on Flyway's validate/repair:

- `wheels migrate doctor` — a read-only health report: orphan versions, pending migrations, applied count. Prints yellow when something needs attention.
- `wheels migrate forget <version> --yes` — removes a stale tracking row without running `down()` (refuses if a matching file exists).
- `wheels migrate pretend <version> --yes` — records a version as applied without running `up()` (refuses if already applied or no file matches).

Both `forget` and `pretend` are dry-run unless you pass `--yes`. The tracking table also gained `name` and `applied_at` columns (added automatically on upgrade) so `migrate info` can show you what an orphan was and when a peer applied it.

**Other highlights:**

- Fixed a class of *silent* migration rollbacks on SQL Server: model writes inside `up()`/`down()` could vanish because Model opened a nested transaction on top of the migrator's outer one. The migrator now signals ownership and Model skips the nested transaction.
- `t.references()` and `t.primaryKey()` now accept `columnNames` like every other column helper (the legacy `referenceNames` / `name` forms still work).
- `wheels upgrade check` gained an advisory tier — opt-in recommendations separate from breaking-change warnings.
- Reserved-word column names (`key`, `order`, `group`) now work in `SELECT`/`GROUP BY`, not just `WHERE`/`ORDER BY`.
- **Native signed apt.wheels.dev / yum.wheels.dev repositories.** Linux install and upgrade is now a one-liner — `apt install wheels` / `dnf install wheels`, `apt upgrade wheels` / `dnf upgrade wheels` — no GitHub-release download step.

Upgrade with `brew upgrade wheels`, `scoop update wheels`, `apt upgrade wheels`, or `dnf upgrade wheels`. No code changes required.

Full release notes: RELEASE_URL
