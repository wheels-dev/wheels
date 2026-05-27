# Release Playbook

Operational runbook for cutting Wheels releases. The high-level architecture
and rationale lives in [docs/contributing/release-process.md](../docs/contributing/release-process.md);
this file is the step-by-step "what do I run, in what order" reference for a
maintainer cutting a release at 3am.

## Daily flow (no maintainer action)

```
PR → develop  →  snapshot.yml fires (existing workflow)
                   ↓ calls release.yml via workflow_call
                   ↓ release.yml detects develop branch context
                   ↓ publishes snapshot release to wheels-dev/wheels-snapshots
                                              →  homebrew-wheels tap's bleeding-edge-update.yml auto-PRs the wheels-be bump
                                              →  scoop bucket auto-PRs the wheels-be bump
```

The publish target (wheels-dev/wheels-snapshots vs wheels-dev/wheels) is
selected inside `release.yml` based on `github.ref`. Snapshots and stable
releases share build logic; only the upload destination differs.

Maintainer's only job: rubberstamp the auto-bump PRs in the tap repos when CI
on them is green. ~5 minutes/day max.

## Cutting a GA release

### Pre-flight (anytime up to release day)

1. **Cherry-pick or merge stabilization commits to `release/X.Y.Z`** if using a
   release-branch workflow. Skip this if cutting directly from develop.
2. **Update `CHANGELOG.md`**: rename `# [Unreleased]` to
   `# [X.Y.Z](...) => YYYY-MM-DD` with the real release date (replace any
   `=> TBD`). Then confirm the separator line directly below the renamed
   section is exactly `---` (three dashes), NOT `----`. `release.yml` refuses
   to publish if it sees TBD on the target version, and also fails if a `----`
   separator would make the release-notes awk bleed into the previous version's
   notes (recurring footgun — see #2606, #2768; now guarded in `release.yml`).
3. **Verify `wheels.json` version** matches what you want to release.
   `wheels.json` is the canonical version source since the 4.0 rebrand (the
   workflows read it; `box.json` is legacy and may be absent or empty). After
   the last GA, the `bump-develop-version.yml` workflow set it to next-patch;
   if you're shipping a bigger bump, update it manually.

### Release day

`main` has a **"PRs only" ruleset** — `git push origin main` is rejected with
`GH013`. You also never tag manually: `release.yml` auto-creates the tag via
`softprops/action-gh-release` once the merge lands on main.

```bash
# 1. Open a PR into main from a release branch. (Cutting from develop directly
#    is fine — just branch off develop so the PR has a head ref to merge.)
git checkout develop && git pull
git checkout -b release/X.Y.Z-to-main
git push -u origin release/X.Y.Z-to-main
gh pr create --base main --head release/X.Y.Z-to-main \
  --title "Release X.Y.Z" --body "Cut X.Y.Z. See CHANGELOG."

# 2. Merge with "Create a merge commit" (NOT squash — preserves develop
#    history on main).
gh pr merge --merge --delete-branch
```

The push-to-main from that merge triggers `release.yml`, which builds the
artifacts and calls `softprops/action-gh-release` with `tag_name: vX.Y.Z`,
creating the tag at main HEAD automatically. Do **not** run `git tag` /
`git push --tags` — the legacy `git push origin main --tags` flow is rejected
by the ruleset anyway.

The tag push triggers:
- `release.yml` builds artifacts, publishes to `wheels-dev/wheels/releases`
- `release.yml`'s "Dispatch downstream package managers" step then fires
  three `repository_dispatch` events via `DOWNSTREAM_DISPATCH_TOKEN` (a PAT):
  - `wheels-released` → `wheels-dev/homebrew-wheels` (brew formula bump)
  - `wheels-released` → `wheels-dev/chocolatey-wheels` (choco package bump)
  - `bump-develop` → `wheels-dev/wheels` itself (this repo) — only for
    `CHANNEL=stable` (snapshots and RCs don't bump develop)
- `bump-develop-version.yml` fires on the `bump-develop` dispatch and opens
  a PR against develop bumping `wheels.json` to next-patch. (We use
  `repository_dispatch` rather than `release: published` because the
  release-publish step uses the default `GITHUB_TOKEN`, which by design
  cannot trigger downstream workflows. See [#2609](https://github.com/wheels-dev/wheels/issues/2609).)
- The brew tap's `wheels-bump.yml` (parallel to `wheels-be-bump.yml`) opens a
  PR bumping `Formula/wheels.rb`
- Same for scoop bucket and (eventually) the WinGet manifest PR

Total maintainer turnaround: merge 3 auto-PRs across 3 tap repos. ~10 minutes.

### Post-release verification

```bash
# Within ~5min of the auto-PR being merged:
brew update && brew upgrade wheels
wheels --version    # should report X.Y.Z (stable)

# Smoke test:
mkdir /tmp/release-smoke && cd /tmp/release-smoke
wheels new myapp && cd myapp && wheels start
# Visit http://localhost:8080 — should see the welcome page.
```

If the smoke test fails: roll back (see below) before the formula propagates
widely to other users.

## Rollback

A bad GA can be rolled back by reverting the brew formula to the previous tag.
The GitHub Release stays — yanking it would 404 anyone who scaffolded against
that version's URL. The formula revert is enough to stop *new* installs from
landing on the broken version.

```bash
# In wheels-dev/homebrew-wheels:
git checkout main
git revert <commit-of-bump-PR>
git push
# Within ~5min, brew update && brew upgrade wheels lands users back on the
# previous good version.
```

For severe regressions where users on the broken version need to be alerted:

1. Edit the GitHub Release notes for the bad tag, prepend a `## ⚠ KNOWN ISSUE`
   block with the workaround. Don't delete the release — links to it persist.
2. Open a hotfix branch from the previous good tag, fix, follow the GA flow
   above to ship `X.Y.Z+1`.
3. Once the hotfix is shipped, optionally edit the bad release's notes again
   to point users at the hotfix.

## Cutting a release candidate

```bash
git checkout -b release/X.Y.Z develop
# Stabilize.
git push origin release/X.Y.Z
```

`release-candidate.yml` runs on every push to a `release/*` branch and
publishes RC artifacts to `wheels-dev/wheels-snapshots` (alongside develop
snapshots, but with version `X.Y.Z-rc.N`). Users testing RCs install via:

```bash
brew install wheels-dev/wheels/wheels-be   # same channel — RCs and snapshots coexist
```

Or directly download from the snapshots repo's releases page.

## Coordination with first-party packages

The wheels-* packages (wheels-sentry, wheels-hotwire, etc.) live in their own
repos and ship on their own cadence. They aren't gated by Wheels GA cuts.
However: if a package's `wheelsVersion` constraint excludes the new GA
version, that's a coordination problem. Pre-flight check:

```bash
# In each first-party package repo, verify wheelsVersion in package.json:
for pkg in sentry hotwire basecoat i18n seo-suite legacy-adapter; do
  echo "=== wheels-${pkg} ==="
  curl -sf "https://raw.githubusercontent.com/wheels-dev/wheels-${pkg}/main/package.json" \
    | jq '.wheelsVersion'
done
```

If any pin to `<X.Y.Z`, open issues on those repos to widen the constraint.

## Common failure modes

| Symptom | Cause | Fix |
|---|---|---|
| `release.yml` fails: "CHANGELOG contains TBD" | Forgot to update changelog | Add release date to `# [X.Y.Z]` line, push, re-run workflow |
| `release.yml` fails: "release-notes range … bleeds into a later version section" | Separator below the target version is `----` (4 dashes), not `---` — the awk extraction overruns into the previous version | Change that separator line to exactly `---`, push, re-run |
| `release.yml` fails: "version contains -SNAPSHOT" | `wheels.json` has a `-snapshot` suffix on main | Strip the suffix in `wheels.json`, push (release.yml asserts clean main versions) |
| brew tap PR doesn't open after release | `DOWNSTREAM_DISPATCH_TOKEN` expired or unset | Rotate token in repo secrets; re-run `release.yml` workflow_dispatch |
| develop-bump PR doesn't open after GA | `DOWNSTREAM_DISPATCH_TOKEN` expired/unset, OR the `bump-develop` dispatch step warned and exited 0 | Fire it manually: Actions → "Bump Develop Version" → "Run workflow" → enter the just-released version (e.g. `4.0.0`). The workflow has a `workflow_dispatch` fallback for exactly this case. |
| `brew install wheels` post-release fails | Formula sha256 mismatch | Re-run the tap bump workflow with `workflow_dispatch` to recompute |
| Snapshot publish fails: "tag already exists" | Re-run after partial success | Delete the orphaned tag in `wheels-dev/wheels-snapshots`, re-run |
| Linux package URL 404s when version has `~snapshot.N` | GitHub Releases silently rewrites `~` to `.` in uploaded asset filenames | Use `.` in the URL: `wheels_4.0.0.snapshot.1787_amd64.deb`, NOT `wheels_4.0.0~snapshot.1787_amd64.deb`. The on-disk filename keeps `~` (so `dpkg --compare-versions` orders pre-releases correctly), but the uploaded URL gets mangled. Downstream consumers (apt repo metadata generator, install scripts) must compute the `.`-form. See `tools/distribution-drafts/linux-packages/build-linux-packages.sh`. |

## See also

- [docs/contributing/release-process.md](../docs/contributing/release-process.md) — design rationale (versioning, channel model, why two repos)
- [docs/contributing/wheels-bot.md](../docs/contributing/wheels-bot.md) — Claude-powered bot that triages issues and PRs
- [.github/workflows/release.yml](workflows/release.yml) — GA + snapshot release pipeline (channel-aware: snapshots target wheels-dev/wheels-snapshots, stable targets wheels-dev/wheels)
- [.github/workflows/snapshot.yml](workflows/snapshot.yml) — develop-branch driver (fast-test gate + calls release.yml + deploys API docs to CF Pages)
- [.github/workflows/bump-develop-version.yml](workflows/bump-develop-version.yml) — auto-bumps develop after GA
