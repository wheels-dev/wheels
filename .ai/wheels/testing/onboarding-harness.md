# Local Onboarding Harness

`tools/test-onboarding.sh` is a local fresh-install simulator. It exercises
the same `wheels new → wheels start → wheels migrate latest → wheels seed`
path that a brand-new user follows, in an isolated `LUCLI_HOME` so it
doesn't touch the developer's daily wheels install.

The harness is not a unit test runner. It exists to **validate cliff fixes
locally before asking for a fresh-VM tutorial run**. A fresh VM costs ~30
minutes round-trip; the harness costs ~90 seconds.

## When to reach for it

- Editing CLI / framework / template code that affects `wheels new`,
  `wheels start`, `wheels migrate latest`, or `wheels seed`.
- Working on a finding from a fresh-VM tutorial-onboarding journal — the
  harness output mirrors that journal format so signatures map directly.
- Diagnosing dotted-path resolution issues, Lucee bundle problems, or
  config emission bugs that only surface in install contexts that copy
  the module rather than symlinking it (i.e., Homebrew bottle, Chocolatey
  package, real fresh VMs).
- Validating that a doc fix matches the actual behaviour the user sees.

The harness is NOT the right tool for:

- Running framework unit tests — use `bash tools/test-local.sh`.
- Running CLI module unit tests — use `bash tools/test-cli-local.sh`.
- Cross-engine compatibility checks — use the Docker matrix
  (`docker compose up`).
- Browser automation tests — use `wheels browser test` or the Playwright
  spec runner.

## How it works

The harness creates a temporary `LUCLI_HOME` at `$TMPDIR/.lucli` (the literal
`.lucli` suffix matters because LuCLI's `getComponentPath()` hardcodes that
directory name when deciding whether to load `Module.cfc` by absolute file
path). It then mounts the worktree's `cli/lucli/` into
`$LUCLI_HOME/modules/wheels` (default: symlink, `MODE=copy` for closer
brew-install simulation), sets `WHEELS_FRAMEWORK_PATH` to the worktree's
`vendor/wheels`, and symlinks the user's existing Lucee Express install
under `$LUCLI_HOME/express` so the 74MB download is skipped.

`JAVA_HOME` is auto-resolved (via `/usr/libexec/java_home -v 21` first, then
falling back to `brew --prefix openjdk@21` for keg-only installs). The
`wheels` wrapper resolves Java internally, but `lucli server run` (which the
harness uses to avoid the wrapper's 30-second startup timeout) does not, so
`JAVA_HOME` must be exported explicitly.

The temp directory is wiped on exit. Use `KEEP_TEMP=1` to preserve it for
inspection (logs, generated app, server stdout) — paths are printed at the
end of the run.

## Phases

```
Phase 1: Setup isolated LUCLI_HOME
Phase 2: wheels new (file tree, no bundleName, no duplicates)
Phase 3: server boot via `lucli server run` + sqlite-jdbc shim
Phase 4: migration cliff (assert real schema, not just exit 0)
Phase 5: seed (cfscript wrapper + seedOnce idempotency)
Phase 6: CRUD walkthrough (chapters 2-3 happy path)
Phase 7: wheels packages list (currently SKIP pending follow-up)
```

Each phase emits `✓` (pass), `✗` (fail), or `-` (skip) lines. The summary
counts add up across all phases. A failure in Phase 1-3 aborts subsequent
phases (no point running migrations against a server that didn't start).

## Modes

| Mode | Invocation | Use case |
|---|---|---|
| symlink (default) | `bash tools/test-onboarding.sh` | Fast iteration on worktree changes |
| copy | `MODE=copy bash tools/test-onboarding.sh` | Closer simulation of fresh brew install (forces `Lucee` to walk the actual directory hierarchy rather than the symlink target) |
| baseline | `BASELINE=1 bash tools/test-onboarding.sh` | Run against the user's brew-installed `wheels` rather than the worktree (sanity check for what a real user sees today) |
| keep | `KEEP_TEMP=1 bash tools/test-onboarding.sh` | Preserve the temp dirs (LUCLI_HOME, app dir, server log) so you can inspect state |
| skip | `FROM_PHASE=4 bash tools/test-onboarding.sh` | Skip earlier phases when you only care about Phase N+ |
| port | `PORT=9787 bash tools/test-onboarding.sh` | Override server port (default 9988) |

Modes compose: `MODE=copy KEEP_TEMP=1 PORT=9787 bash tools/test-onboarding.sh`.

## Reading the output

The harness mirrors the fresh-VM onboarding journal format used by the
manual VM-test runs. Each phase prints a header (`━━━ Phase N: title ━━━`)
followed by per-check lines.

A green run produces something like:

```
━━━ Phase 4: Migration cliff — wheels migrate latest (covers F2/F5) ━━━
  ✓ ch02 migration written
  ✓ wheels migrate latest exited 0
  ✓ F5: db/development.sqlite is non-empty (24576 bytes)
  ✓ F5: posts table exists in development.sqlite
      |       CREATE TABLE IF NOT EXISTS "posts" (
```

A failure looks like:

```
━━━ Phase 4: Migration cliff — wheels migrate latest (covers F2/F5) ━━━
  ✓ ch02 migration written
  ✓ wheels migrate latest exited 0
  ✗ F5: db/development.sqlite is 0 bytes — migration silently no-op'd
      migrate-output:
      | Running migration: latest...
      | Migration latest completed.
```

The "F5" prefix references the finding ID from the second fresh-VM
onboarding journal. Lookup table:

| ID | Finding | Status as of merge of #2304/2306/2307/2308/2309 |
|---|---|---|
| F1 | bundleName forces broken OSGi resolution | fixed (bundleName stripped from template) |
| F2/F5 | `wheels migrate latest` silently no-ops | fixed (correct command name) |
| F3 | duplicate `create blog/Application.cfc` lines | open ([#2311](https://github.com/wheels-dev/wheels/issues/2311), didn't reproduce locally) |
| F3-orig | seedOnce non-idempotent | likely downstream of F1 (column case-folding); covered by Phase 5 |
| F4 | tutorial file tree out of date | fixed (regenerated from real `wheels new`) |
| F7 | `cli.lucli.X` doesn't resolve in copy installs | fixed (rewrote to `modules.wheels.X`) |
| F7 follow-up | `wheels.SemVer` not loaded in CLI context | open ([#2310](https://github.com/wheels-dev/wheels/issues/2310)) |

## Required state

The harness needs:

- A worktree-style checkout of `wheels-dev/wheels` (not just the brew-installed bottle)
- `wheels` (i.e. lucli) on `PATH`
- Java 21 (`brew install openjdk@21` on macOS)
- An existing Lucee Express install under `~/.wheels/express/` or `~/.lucli/express/` (created by any prior `wheels start` — the symlink reuses it). If neither exists, the harness will trigger one during Phase 3 (slower first run).
- `sqlite3` on PATH (used to verify schema)

If `sqlite3` is missing, the schema verification check skips with a warning;
the rest of the harness runs. Other missing dependencies abort with a
specific error.

## Adding new phases

Each phase is gated by the `phase` helper (`if phase N "title"; then ...`),
which respects `FROM_PHASE`. New phases should:

- Mirror the journal format — emit `pass` / `fail` / `skip` calls per check
- Reference fresh-VM finding IDs (F-numbers) in the section title and
  per-check labels so signatures stay greppable
- Expose log files via `$TMPDIR/wheels-<phase>.log` for inspection in
  `KEEP_TEMP=1` mode

The harness is intentionally one bash file. A multi-phase walkthrough is
easier to audit and modify in one place than spread across modules.

## Related documentation

- `tools/test-onboarding.sh` — the script itself, with extensive header
  comments documenting every mode and phase
- [PR #2308](https://github.com/wheels-dev/wheels/pull/2308) — the
  introduction PR with full design context
- The original fresh-VM tutorial-onboarding journals (April 2026) that
  motivated the harness

## Why a separate harness vs extending `tools/test-local.sh`

`tools/test-local.sh` runs the framework's own unit-test suite (3328+ specs)
inside a running Wheels server. It assumes the framework is correctly
loaded — which is the very assumption a brand-new user can't make. The
onboarding harness exists below that assumption: it boots from
`wheels new` and proves the cliff is closed at every step the user
actually walks through. Folding it into `tools/test-local.sh` would mix
two different test layers; keeping them separate keeps each one fast and
clearly scoped.
