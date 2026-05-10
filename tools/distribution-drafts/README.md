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
| `scoop/wheels.json` | `wheels-dev/scoop-wheels` (new repo) | `bucket/wheels.json` |
| `scoop/wheels-be.json` | `wheels-dev/scoop-wheels` | `bucket/wheels-be.json` |
| `winget/manifests/*.yaml` | `microsoft/winget-pkgs` (PR) | `manifests/w/WheelsFramework/Wheels/<version>/` |
| `snapshots-repo/README.md` | `wheels-dev/wheels-snapshots` (✅ pushed) | `README.md` |
| `snapshots-repo/cleanup-old-snapshots.yml` | `wheels-dev/wheels-snapshots` (✅ pushed) | `.github/workflows/cleanup-old-snapshots.yml` |
| `linux-packages/*` | reference + Phase 2 plan for `apt.wheels.dev` / `yum.wheels.dev` | (CF Pages) |

After Tuesday's GA, this directory can either stay (as canonical source-of-truth
for what each tap looks like) or be removed (the taps become authoritative).
Leaning toward keeping it — drift between the in-repo template and the actual
tap is a useful diff signal during release reviews.
