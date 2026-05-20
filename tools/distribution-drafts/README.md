# Distribution Drafts

Reference templates for Wheels distribution artifacts that live in **other
repos**. They are checked in here only so they can be reviewed alongside the
matching CI workflow changes (`publish-snapshot.yml`, etc.) in this repo.

When merged, the contents of this directory should be copied into:

| File | Destination repo | Path in destination |
|------|-----------------|---------------------|
| `homebrew/wheels-be.rb` | `wheels-dev/homebrew-wheels` | `Formula/wheels-be.rb` (new file) |
| `homebrew/bleeding-edge-update.yml` | `wheels-dev/homebrew-wheels` | `.github/workflows/bleeding-edge-update.yml` (new file) |
| `homebrew/auto-update-channel-patch.md` | (informational) | applied as a small patch to the existing `auto-update.yml` |
| `winget/manifests/*.yaml` | `microsoft/winget-pkgs` (PR) | `manifests/w/WheelsFramework/Wheels/<version>/` |
| `snapshots-repo/README.md` | `wheels-dev/wheels-snapshots` (✅ pushed) | `README.md` |
| `snapshots-repo/cleanup-old-snapshots.yml` | `wheels-dev/wheels-snapshots` (✅ pushed) | `.github/workflows/cleanup-old-snapshots.yml` |
| `linux-packages/*` | reference + Phase 2 plan for `apt.wheels.dev` / `yum.wheels.dev` | (CF Pages) |

## Scoop bucket is authoritative, not drafted here

The Scoop manifests previously drafted in `scoop/` were removed (wheels#2765).
The live `wheels-dev/scoop-wheels` bucket has its own self-hosted autoupdate
workflow and is the unambiguous source of truth — keeping a drafted copy here
just produced silent drift (the in-repo drafts grew out of sync with the
bucket's inline-JDK rework and no one noticed for two releases). Edit the
bucket repo directly; this repo no longer mirrors it.
