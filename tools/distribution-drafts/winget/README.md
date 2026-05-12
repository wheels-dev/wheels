# WinGet manifest drafts — `microsoft/winget-pkgs`

Two package identifiers, one per channel:

| Identifier | Channel | Source |
|---|---|---|
| `Wheels.Wheels` | stable | `wheels-dev/wheels` GA tags |
| `Wheels.WheelsBE` | bleeding-edge | `wheels-dev/wheels-snapshots` pre-releases |

WinGet manifests are 3-file YAML triplets per version, submitted as PRs to
[microsoft/winget-pkgs](https://github.com/microsoft/winget-pkgs) under
`manifests/w/Wheels/Wheels/<version>/` (and a parallel `WheelsBE/`).

## Why these are *drafts*, not ready-to-ship

WinGet's installer types (`exe`, `msi`, `msix`, `inno`, `nullsoft`, `wix`,
`portable`, `zip`) all assume one of:

1. A signed installer that drops files in a deterministic location and
   adds itself to PATH (msi/msix/wix/inno/nullsoft).
2. A portable binary that goes onto PATH as-is (portable).
3. A zip whose contents look like one of the above.

Wheels doesn't fit cleanly into any of them out of the box — our
`wheels.cmd` wrapper needs to sync `share/module/` and
`share/framework/wheels/` into `~/.wheels/` on first run, the same way the
brew formula's wrapper does. None of the portable or zip types run setup
scripts on the user's machine the way `pre_install` / `post_install` do
in Scoop.

There are two paths forward:

1. **Build a real WiX MSI.** Largest cost, best UX, supports proper
   uninstall via Add/Remove Programs. Need a build pipeline that bundles
   the wrapper, the LuCLI `.bat`, the SQLite JDBC, and runs the SRC→DST
   sync as a custom action. Probably a week of WiX work.

2. **Wrap a portable install in a self-extracting EXE.** Smaller cost.
   Pack `wheels-module`, `wheels-core`, `lucli-0.3.7.bat`, and
   `sqlite-jdbc-*.jar` into a single signed `.exe` (e.g., via 7-Zip SFX
   or NSIS). Manifest type = `nullsoft` or `inno`. On install it
   extracts to `%ProgramFiles%\Wheels\` and registers the wrapper on
   PATH. First-run sync still needs to happen in the wrapper itself.

Until we pick a path and ship the installer artifact, these manifests
are scaffolding — they document the metadata + identifier conventions
so the day-one PR to `microsoft/winget-pkgs` is mechanical.

## Submission flow (once an installer is built)

```bash
# Fork microsoft/winget-pkgs
gh repo fork microsoft/winget-pkgs
git clone git@github.com:<you>/winget-pkgs
cd winget-pkgs

# Copy our drafts in
mkdir -p manifests/w/Wheels/Wheels/4.0.0
cp ../wheels-dev/wheels/tools/distribution-drafts/winget/Wheels.Wheels/4.0.0/*.yaml manifests/w/Wheels/Wheels/4.0.0/

# Update InstallerUrl + InstallerSha256 with the real GA artifact + hash
$EDITOR manifests/w/Wheels/Wheels/4.0.0/Wheels.Wheels.installer.yaml

# Validate (Microsoft ship a CLI tool):
winget validate --manifest manifests/w/Wheels/Wheels/4.0.0/

# Open PR
git checkout -b add-wheels-stable
git add manifests/w/Wheels/Wheels/4.0.0/
git commit -m "New version: Wheels.Wheels version 4.0.0"
git push -u origin add-wheels-stable
gh pr create --repo microsoft/winget-pkgs ...
```

WinGet's PR review is fairly automated — a bot validates the manifest
schema, runs `winget install` in a sandbox, and merges if green. Manual
review only when the bot's heuristics catch something.

## How autoupdate works for WinGet

Unlike Scoop's per-bucket Excavator bot, WinGet has **no autoupdate** —
every new version is a new PR to `microsoft/winget-pkgs`. We can
automate the PR creation from our own release workflow using
[`vedantmgoyal2009/winget-releaser`](https://github.com/vedantmgoyal2009/winget-releaser)
or similar, but the upstream merge cadence is on the WinGet team's
schedule.

This is the main argument for prioritizing Scoop over WinGet for
bleeding-edge — daily WinGet PRs for snapshot bumps are noise. Scoop's
hourly autoupdate fits the BE cadence; WinGet fits the stable cadence
where new versions are infrequent (GA tags).

Plan: ship `Wheels.Wheels` (stable) on WinGet, leave `Wheels.WheelsBE`
on Scoop only. The BE manifest in this directory is kept for symmetry +
documentation, not for active submission.

## Identifier rationale

`Wheels.Wheels` follows WinGet's convention of
`<Publisher>.<PackageName>`. `Wheels` is short, descriptive, and not
yet claimed in the registry (verified 2026-05).

We deliberately don't use `WheelsDev.Wheels` — the publisher name
should be the brand users recognize, not the org slug.
