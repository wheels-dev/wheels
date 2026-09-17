# Distribution Drafts

Reference templates for Wheels distribution artifacts that live in **other
repos**. They are checked in here only so they can be reviewed alongside the
matching CI workflow changes (`publish-snapshot.yml`, etc.) in this repo.

When merged, the contents of this directory should be copied into:

| File | Destination repo | Path in destination |
|------|-----------------|---------------------|
| `winget/manifests/*.yaml` | `microsoft/winget-pkgs` (PR) | `manifests/w/WheelsFramework/Wheels/<version>/` |
| `snapshots-repo/README.md` | `wheels-dev/wheels-snapshots` (✅ pushed) | `README.md` |
| `snapshots-repo/cleanup-old-snapshots.yml` | `wheels-dev/wheels-snapshots` (✅ pushed) | `.github/workflows/cleanup-old-snapshots.yml` |
| `linux-packages/*` | nfpm configs + `build-linux-packages.sh` — used live by `release.yml` to build the `.deb`/`.rpm` | (source repo) |

## Homebrew tap is authoritative, not drafted here

The live tap is `wheels-dev/homebrew-wheels` (`Formula/wheels.rb` stable,
`Formula/wheels-be.rb` bleeding-edge). Its `wheels-be.rb` and
`bleeding-edge-update.yml` were previously mirrored here; both drifted badly
enough that a docs change written against the in-repo copy never reached the
tap at all, and the feature silently did not ship. The drafts were removed for
the same reason as the Scoop and apt/yum ones.

Edit the tap directly. `bleeding-edge-update.yml` recomputes each resource's
`sha256` by anchored regex, so **adding a resource to the formula means adding
the matching compute step, `env:` entry, and rewrite pattern there too** —
otherwise the next auto-bump leaves a stale hash and `brew install` fails its
checksum check.

## Scoop bucket is authoritative, not drafted here

The Scoop manifests previously drafted in `scoop/` were removed (wheels#2765).
The live `wheels-dev/scoop-wheels` bucket has its own self-hosted autoupdate
workflow and is the unambiguous source of truth — keeping a drafted copy here
just produced silent drift (the in-repo drafts grew out of sync with the
bucket's inline-JDK rework and no one noticed for two releases). Edit the
bucket repo directly; this repo no longer mirrors it.

## apt / yum buckets are authoritative, not drafted here

`apt.wheels.dev` and `yum.wheels.dev` are live (served from Cloudflare R2).
The `wheels-dev/apt-wheels` and `wheels-dev/yum-wheels` repos are the source of
truth for their receiver workflow (`wheels-released.yml`), regen/signing
scripts, and landing pages. The `apt-repo/` and `yum-repo/` drafts that used to
live here were removed for the same reason as the Scoop drafts: they drifted
from the deployed workflows and misled reviewers. Edit the bucket repos
directly; this repo no longer mirrors them.
