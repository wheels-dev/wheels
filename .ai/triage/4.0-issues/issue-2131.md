# Issue #2131: GA tag plan for Wheels 4.0.0

## Verdict
FIX NOW (execute last — this is the terminal release task; all phase:1-stabilize work must land first)

## Summary
Release-orchestration issue: cut a clean, unsuffixed `v4.0.0` annotated tag (avoiding the `v3.0.0+N`-only mess that bit the 3.0 cycle), publish packages to ForgeBox, push a GitHub Release, and fan out to Homebrew/Chocolatey/docs/announcements. Source (`box.json`) already shows `4.0.0` — the workflow injects `+<run_number>` on main push and `-SNAPSHOT+<run>` on develop.

## Root cause
Not a bug. A planning/checklist issue. Gaps to close before a GA cut is safe:

1. **Stabilization**: open `phase:1-stabilize` issues (#2011, #2106, #2110, #2135, #2136, #2138) describe failing tests, misplaced routes/controllers, CockroachDB flakes. A GA that green-lights on partial CI is the same foot-gun the 3.0 cycle hit.
2. **Snapshot-tag backflow**: `snapshot.yml` fires on every develop push and delegates to `release.yml`, which cuts `v{ver}-SNAPSHOT+N` tags. Once `v4.0.0` exists, any further develop push in the 4.0.x timeline would still cut `v4.0.0-SNAPSHOT+N` — tags that sort *before* `v4.0.0` and confuse ForgeBox/downstream resolvers. Guard needed (skip when `box.json.version` matches an existing annotated release tag, or require bumping develop to `4.1.0` before re-snapshotting).
3. **Distribution fan-out**: homebrew-wheels + chocolatey-wheels live as sibling repos under `~/GitHub/wheels-dev/`. Both have auto-update workflows (per MEMORY `reference_distribution_repos.md`) but need trigger verification against a real GA tag, not a snapshot.
4. **LuCLI DX issues** (#1942, #1944, #1945, #1946): per MEMORY `project_lucli_1_0_cfcamp.md`, LuCLI plans a 1.0.0 tag + Lucee-org move timed with wheels 4.0. Decide whether LuCLI 1.0.0 blocks, or whether 4.0 GA ships against the pinned `LUCLI_VERSION: "0.3.3"` currently in `snapshot.yml`.

## Files to change

### In wheels repo
- `box.json` — already at `4.0.0`; no change for GA cut. After tagging, bump to `4.1.0` (the release workflow appends `-SNAPSHOT+N` on develop automatically — do **not** commit a literal `4.1.0-SNAPSHOT`; the `release.yml` validation at line 79 rejects that).
- `examples/starter-app/box.json` — bump in lockstep (same rule: clean version, no `-SNAPSHOT`).
- `CHANGELOG.md` — rename `## [Unreleased]` to `## [4.0.0] - YYYY-MM-DD`. Keep the narrative preamble ("Wheels 4.0 — the release that started as 3.1…") under the new header. Confirm the closing `---` separator is present so `release.yml`'s `awk '/^# \[...\]/,/^---$/'` extractor at line 285 works (note: the extractor uses `# \[` single-hash; CHANGELOG entries currently use `## [`. Verify one pass on a recent tag — if extraction is empty, the GitHub Release body will be blank. Fix by adjusting the awk pattern to `## \[` or re-leveling the header.)
- `.github/workflows/snapshot.yml` — add a guard step before `build:` that fails/skips if `git tag --points-at HEAD` includes a non-SNAPSHOT `v*` tag, or if `box.json.version` already has an annotated release tag upstream. Simpler: gate on `box.json.version == "4.0.0"` → exit cleanly (expected state immediately post-GA, before the 4.1 bump merges).
- `docs/wheels-vs-frameworks.md` — update "Recently Closed Gaps — April 2026" header to "Wheels 4.0 (YYYY-MM-DD)".
- `docs/releases/wheels-4.0-audit.md` — if any "TBD" / placeholder dates remain, replace with GA date.

### In sibling repos (coordinated bumps)
- `homebrew-wheels/` — auto-update workflow consumes GitHub Release assets (sha512 files from `release.yml` lines 205, 302-316). Verify the workflow trigger pattern matches `v4.0.0` (not `v*-SNAPSHOT*`). Per MEMORY: auto-update exists; just needs the new release to land.
- `chocolatey-wheels/` — same drill; `publish-chocolatey.yml` exists in this repo too (line 1 of `.github/workflows/publish-chocolatey.yml`). Inspect its trigger before cutting the tag.

## Implementation steps

### Phase A — Pre-flight (do not tag yet)
1. Close or explicitly defer the six `phase:1-stabilize` issues (#2011, #2106, #2110, #2135, #2136, #2138). Any marked "defer to 4.0.1" must be tagged `milestone: 4.0.1` so they don't block.
2. Decide LuCLI fate: pin to `0.3.3` for GA (current CI state) OR wait for LuCLI 1.0.0 + Lucee-org repo move (#1942, #1945, #1946). Document the decision in the issue.
3. Run the full matrix on the chosen develop HEAD: all engines (lucee5/6/7, adobe2018/2021/2023/2025, boxlang) × all DBs (sqlite, mysql, postgres, sqlserver, h2, cockroach). `compat-matrix.yml` is the canonical gate. CockroachDB is currently soft-fail per `tests.yml` — either fix (#2106) or accept and note in release notes.
4. Verify CHANGELOG extraction: run `awk '/^## \[Unreleased\]/,/^---$/' CHANGELOG.md | sed '1d;$d'` and confirm non-empty output. If `release.yml` line 285 uses `# \[` (single hash) but the file uses `## [`, that's a latent bug — fix the awk pattern to `## \[` in `release.yml` **before** cutting GA, or the Release body will be empty.
5. Dry-run `generate-changelog.sh` against the `v3.0.0+33` baseline (proxy for "3.0 final") to confirm the changelog section is complete.

### Phase B — Prep commits on develop (still no tag)
6. Commit: `chore(config): rename changelog unreleased section to 4.0.0`
   - Edits: `CHANGELOG.md` (rename header + date), `docs/wheels-vs-frameworks.md` (date header).
7. Merge develop → main via the normal promote PR. Lock CI green on the merge commit.

### Phase C — Cut GA
8. On main, at the locked-green commit:
   ```bash
   git checkout main && git pull
   git tag -a v4.0.0 -m "Wheels 4.0.0"
   git push origin v4.0.0
   ```
   Note: `release.yml` currently fires on `push: branches: main` and appends `+<run_number>` → that will produce a separate `v4.0.0+<run>` tag *in addition to* the manual `v4.0.0`. Two options:
   - **(preferred)** Add a short-circuit in `release.yml` when `git describe --exact-match` returns a clean `v*` tag: publish assets under `v4.0.0`, skip the `+N` tag creation.
   - **(simpler)** Let main push produce `v4.0.0+1`, then tag `v4.0.0` manually pointing to the same commit and upload artifacts to the manual Release via `gh release upload`. Ugly but works.
   Resolve this before tagging; a tag with `+N` suffix is exactly the 3.0.0 failure mode this issue exists to avoid.
9. `gh release create v4.0.0 --title "Wheels 4.0.0" --notes-file release-notes.md` (build body from the `[4.0.0]` CHANGELOG section + link to `docs/src/introduction/upgrading-to-4.0.md`). Attach the artifact set from step 8.
10. Verify ForgeBox publication: `box search wheels` should return 4.0.0 as stable. Manually bless via `publish-to-forgebox.sh` if workflow inject missed.

### Phase D — Post-GA
11. PR on develop: `chore(config): bump version to 4.1.0`
    - Edits `box.json` + `examples/starter-app/box.json` to `4.1.0` (no SNAPSHOT suffix; workflow appends). Add a fresh `## [Unreleased]` section at top of CHANGELOG.
12. Add the snapshot-workflow guard (new step in `snapshot.yml`): fail fast if `v$(jq -r .version box.json)` already exists as an annotated tag on origin. Prevents a stale develop push from clobbering.
13. Trigger homebrew-wheels auto-update (should fire on release webhook; manually dispatch if not). Install test: `brew tap wheels-dev/wheels && brew install wheels && wheels --version` should print `4.0.0`.
14. Trigger chocolatey-wheels auto-update. Install test on Windows runner or local VM: `choco install wheels` then `wheels --version`.
15. Deploy docs: `web-deploy.yml` should auto-fire; confirm wheels.dev shows 4.0.0 as current. `api.wheels.dev` snapshot → release URL (`v4.0.0-snapshot` → `v4.0.0`).
16. Announcements:
    - Blog post at wheels.dev (draft skeletons in `docs/releases/blog-skeletons/`).
    - Social: coordinate with the `social announcements 4.0` branch (per MEMORY).
    - `#announcements` in Slack/Discord/ForgeBox forum.

## Testing

- **CI green**: `gh run list --workflow=compat-matrix.yml --branch=main --limit=1` → success across all cells (except documented soft-fail DBs).
- **Release artifacts present**: `gh release view v4.0.0` lists 6 sets of files (base, core, cli, starter-app, module tar/zip) with `.md5` and `.sha512`.
- **ForgeBox resolvable**: `box install wheels@4.0.0` into a scratch dir, start server, hit `/`. Repeat for `wheels-core@4.0.0` and `wheels-cli@4.0.0`.
- **Homebrew**: `brew tap wheels-dev/wheels && brew install wheels && wheels --version` on a clean mac.
- **Chocolatey**: `choco install wheels --version 4.0.0 -y && wheels --version` on Win runner.
- **Docs deploy**: browse wheels.dev homepage, upgrade guide (`/guides/upgrading-to-4.0`), API reference (`api.wheels.dev/v4-0-0`).
- **No stale snapshot tags**: `git tag -l 'v4.0.0-SNAPSHOT*'` should return nothing after the guard lands. Any pre-existing ones can stay (historical) but no new ones should appear.
- **CHANGELOG extraction**: the GitHub Release body must be non-empty and match the `[4.0.0]` section.

## Risk & dependencies

- **Blockers (phase:1-stabilize)**: #2011 (core tests inside app tests), #2106 (CockroachDB), #2110 (tests failing across DBs), #2135 (internal routes leak into app), #2136 (DB incompatibility in suite), #2138 (controllers/views inside /app). These are correctness issues; shipping GA with any of them open invites a quick 4.0.1.
- **LuCLI coupling (#1942, #1944, #1945, #1946)**: decision needed. `snapshot.yml` pins `LUCLI_VERSION: "0.3.3"`. If LuCLI 1.0.0 is the intended pair (per MEMORY `project_lucli_1_0_cfcamp.md`), need to bump the pin, re-run CI, and update the `wheels browser:install` / `wheels mcp setup` docs that name a version.
- **Workflow double-tagging**: `release.yml` on main push appends `+<run_number>` unconditionally. Must be fixed or bypassed before tagging — otherwise the clean `v4.0.0` tag exists alongside `v4.0.0+<run>`, defeating the whole point of this issue.
- **CHANGELOG extractor regex**: `release.yml:285` uses `# \[` not `## \[`. Needs verification; if broken, Release body will be empty. Cheap to fix pre-GA; expensive if discovered post-GA when docs/announcements already link to an empty release.
- **Distribution repos**: `homebrew-wheels`, `chocolatey-wheels` coordinated updates. Auto-update workflows should fire on release, but manually verify. LuCLI has its own homebrew/chocolatey repos (per MEMORY `reference_distribution_repos.md`) — don't confuse with wheels distribution.
- **Comms**: blog post + social + ForgeBox. Not a code risk, but missing them wastes the GA moment.

## Effort estimate
**L** — release orchestration. Core steps (tag, push, release) are minutes; prep (stabilize issues, workflow guard, extractor fix) is days; post-release fan-out + comms is another day. Realistic calendar time from "decide to ship" to "comms done" is 1-2 weeks assuming `phase:1-stabilize` is already clear.
