# Issue #1946: Update Chocolatey package to use LuCLI instead of CommandBox

## Verdict
CLOSE — resolved by merged PR `wheels-dev/chocolatey-wheels#2` (commit `98f4782`, merged 2026-04-11). Auto-update pipeline (`auto-update.yml`) has since shipped LuCLI 0.3.3 → 0.3.7 and module `4.0.0-SNAPSHOT+1488` → `+1523` through PRs #4, #5, #6, #7 (all merged). Small cleanup items remain (listed below) but the core swap is done.

## Summary
The Chocolatey package has already been rewritten to drop CommandBox and install LuCLI + the Wheels module zip directly. The issue tracker just hasn't been closed, and a stale superseded PR (chocolatey-wheels#1) is still open.

## Root cause
Original CommandBox-based Chocolatey package required a 142-line `tools/wheels.cmd` batch wrapper to convert `--flag=value` → CommandBox arg style. PR #2 replaced the whole design — not with `lucli modules install wheels` (the approach proposed in the issue and in stale PR #1) but with a **bundled download** approach:

- `wheels.nuspec` (chocolatey-wheels master): `id=wheels`, `version=2.0.0`, dependency `openjdk >=21.0.0` only (no `commandbox`, no `lucli`).
- `tools/chocolateyinstall.ps1`: downloads `lucli-<ver>.bat` from `cybersonic/LuCLI` releases AND `wheels-module-<ver>.zip` from `wheels-dev/wheels` releases, extracts into `tools/module/`, writes `.module-version` marker.
- `tools/wheels.cmd`: 21-line wrapper that copies `tools/module/` → `%USERPROFILE%\.wheels\modules\wheels` on version change, then passes through to `lucli.bat`.
- `.github/workflows/auto-update.yml`: watches both upstream repos for new releases and opens PRs that bump `$lucliVersion` / `$moduleVersion` in `chocolateyinstall.ps1`.

This bypasses the #1947 blocker (no `lucli modules install wheels` needed) and the "`lucli` must be on Chocolatey" blocker (`lucli.bat` is downloaded directly). Issue #1946 was written before PR #2 landed; the auto-analysis comments on the issue describe the abandoned plan, not what shipped.

Evidence:
- `~/GitHub/wheels-dev/chocolatey-wheels/wheels.nuspec:4-5,33-35` — version 2.0.0, openjdk-only dep.
- `~/GitHub/wheels-dev/chocolatey-wheels/tools/chocolateyinstall.ps1:5-6,9-10,13-14` — pins LuCLI + module versions, downloads both.
- `~/GitHub/wheels-dev/chocolatey-wheels/tools/wheels.cmd:21` — passthrough to `lucli.bat`.
- `~/GitHub/wheels-dev/chocolatey-wheels/.github/workflows/auto-update.yml` — auto-update workflow present.
- `gh pr list --repo wheels-dev/chocolatey-wheels --state all`: PRs #2–#7 merged; #1 orphaned OPEN.

Outstanding loose ends:
1. Issue #1946 still OPEN (should close, link PR #2).
2. Stale PR chocolatey-wheels#1 (`peter/lucli-wrapper-swap`) still OPEN, `CONFLICTING`, superseded by PR #2.
3. Local worktree `~/GitHub/wheels-dev/chocolatey-wheels` is on `peter/rewrite-package-lucli` with an unstaged one-line edit to `tools/wheels.cmd` adding `set "LUCLI_HOME=%USERPROFILE%\.wheels"` — not committed, not pushed. Intent: isolate the Wheels module install from a user's other LuCLI modules (see `MODULE_DST` in `wheels.cmd` already writes under `.wheels/modules/wheels`, so the launcher must read from there). Without this fix, `wheels` running through the Chocolatey install will resolve modules from `~/.lucli/modules/` — different location than where the wrapper copies the bundled module to — and fail to find `wheels`.

## Files to change
Chocolatey package (`wheels-dev/chocolatey-wheels` repo) — **not** in this monorepo:

1. `tools/wheels.cmd` (last line): add `LUCLI_HOME` export before invoking `lucli.bat`:
   ```
   endlocal & set "LUCLI_HOME=%USERPROFILE%\.wheels" & "%~dp0lucli.bat" %*
   ```
   (This change is already staged in the local worktree on branch `peter/rewrite-package-lucli`, uncommitted.)

GitHub housekeeping (no code):

2. Close issue `wheels-dev/wheels#1946` with reference to `wheels-dev/chocolatey-wheels#2`.
3. Close stale PR `wheels-dev/chocolatey-wheels#1` (`peter/lucli-wrapper-swap`) with comment pointing at PR #2. Delete the branch.

Optional verification-only (no change needed, confirm only):

4. `~/GitHub/wheels-dev/chocolatey-wheels/tools/chocolateyuninstall.ps1` — confirm it cleans up `%USERPROFILE%\.wheels\modules\wheels` and `tools/module/`. Not read yet; verify exists and works.

## Implementation steps
1. From `~/GitHub/wheels-dev/chocolatey-wheels` on a fresh branch off `master` (do NOT reuse the stale `peter/rewrite-package-lucli` — master already contains the rewrite; we only need the `LUCLI_HOME` fix):
   ```
   git checkout master && git pull
   git checkout -b peter/wheels-cmd-lucli-home
   ```
   Apply the one-line edit to `tools/wheels.cmd` (add `set "LUCLI_HOME=%USERPROFILE%\.wheels" &` before the `lucli.bat` invocation on the final line).

2. Verify locally on Windows (or document that this is untested on macOS — see Testing):
   ```
   powershell -ExecutionPolicy Bypass -File .\test-wrapper.ps1
   powershell -ExecutionPolicy Bypass -File .\test-local.ps1
   ```

3. Commit with conventional message:
   ```
   fix(cli): set LUCLI_HOME so wrapper finds bundled wheels module

   The install script copies the Wheels module into
   %USERPROFILE%\.wheels\modules\wheels, but lucli.bat defaults to
   ~/.lucli/modules. Export LUCLI_HOME=%USERPROFILE%\.wheels in the
   wrapper so the bundled module resolves correctly.
   ```
   (Note: chocolatey-wheels uses commitlint scopes; `cli` is valid.)

4. Push and open PR against `wheels-dev/chocolatey-wheels:master`. Title: `fix(cli): set LUCLI_HOME in wheels.cmd wrapper`.

5. Close stale PR chocolatey-wheels#1: `gh pr close 1 --repo wheels-dev/chocolatey-wheels --comment "Superseded by #2 (merged 2026-04-11). The final design bundles lucli.bat + the module zip in chocolateyinstall.ps1 rather than invoking 'lucli modules install wheels' — no dependency on LuCLI being on Chocolatey and no dependency on #1947."` and delete branch `peter/lucli-wrapper-swap`.

6. Close issue #1946: `gh issue close 1946 --repo wheels-dev/wheels --comment "Shipped via wheels-dev/chocolatey-wheels#2 (merged 2026-04-11). Auto-update workflow has since delivered LuCLI 0.3.7 + module 4.0.0-SNAPSHOT+1523 through PRs #4–#7. LUCLI_HOME fix tracked separately."`

## Testing
Windows-specific — this package only runs on Windows. The LuCLI + module bundling approach has two failure modes to verify:

1. **Cold install on a clean Windows VM / runner:**
   ```
   choco install wheels --source . -y
   wheels --version
   wheels generate model User name:string email:string
   wheels server start
   ```
   Expected: wrapper copies module to `%USERPROFILE%\.wheels\modules\wheels`, `LUCLI_HOME` points LuCLI at that dir, `wheels` subcommand resolves.

2. **Upgrade path:** install an older version first (e.g., pin LuCLI 0.3.3 / module `+1488` via the `auto-update/lucli-0.3.3-module-4.0.0-SNAPSHOT+1488` branch release), then upgrade with `choco upgrade wheels`. Confirm `.module-version` triggers a re-copy and old module files aren't left behind.

3. **Uninstall:**
   ```
   choco uninstall wheels -y
   ```
   Confirm `%USERPROFILE%\.wheels\modules\wheels` removed (or explicitly preserved with a note).

4. **Auto-update smoke test:** manually dispatch `.github/workflows/auto-update.yml`, confirm it opens a PR when a newer LuCLI/module release exists, and the resulting PR's `.nupkg` installs cleanly.

From macOS there is no direct Windows test path. Two options:
- Push the branch and let the existing CI on chocolatey-wheels run `choco pack` + the test scripts on `windows-latest` (check `.github/workflows/` for existing test workflow first).
- Manual test on a Windows machine or a `windows-latest` GitHub Actions `workflow_dispatch` using the test scripts already in the repo (`test-local.ps1`, `test-wrapper.ps1`).

## Risk & dependencies
- **Related issues:** #1945 (Homebrew equivalent — mirror status once confirmed; likely also done via homebrew-wheels repo), #1947 (module distribution — **obsoleted** by the bundling approach PR #2 chose; may be closeable too), #1942 (4.0 CLI distribution tracking), #1949 (E2E testing).
- **Distribution concerns:**
  - The `.nupkg` must still be pushed to chocolatey.org for public availability — verify the publish workflow (`.github/workflows/` in chocolatey-wheels) actually pushes, not just packs. Monorepo has `publish-chocolatey.yml` but that publishes **LuCLI**, not the Wheels wrapper (working dir `tools/installer/chocolatey` contains a `lucli.nuspec`). The Wheels Chocolatey publish path lives in chocolatey-wheels itself.
  - Module zip (`wheels-module-*.zip`) must always exist at the expected GitHub release URL for the version `chocolateyinstall.ps1` pins. Confirmed present: `Wheels 4.0.0-SNAPSHOT+1537` is current latest pre-release.
- **Windows-specific concerns:**
  - `LUCLI_HOME` env var must be honored by `lucli.bat` — verify against cybersonic/LuCLI launcher source before assuming. If LuCLI reads `LUCLI_HOME` only at startup and not after `setlocal endlocal`, the `endlocal & set ... & ...` chaining needs scrutiny. Alternative: set `LUCLI_HOME` before `endlocal` or use `cmd /c`.
  - `%USERPROFILE%` with spaces (common on Windows) — paths are quoted in current wrapper, preserve.
  - PowerShell execution policy — `test-local.ps1` / `test-wrapper.ps1` use `-ExecutionPolicy Bypass`; production install should still work under default `RemoteSigned` since choco invokes scripts directly.
- **No risk** to the wheels core monorepo — all changes are in the sibling chocolatey-wheels repo and GitHub issue tracker.

## Effort estimate
S — the core work shipped months ago. Remaining scope is one-line fix + two GitHub housekeeping actions. About 30 min plus Windows verification time.
