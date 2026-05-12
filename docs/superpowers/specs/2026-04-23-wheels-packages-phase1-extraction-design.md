# Wheels Packages Registry — Phase 1 Extraction & Bootstrap

**Date:** 2026-04-23
**Status:** Draft — awaiting user approval
**Relates to:** [#2243](https://github.com/wheels-dev/wheels/issues/2243) (Phase 1 specifically), [#2244](https://github.com/wheels-dev/wheels/issues/2244) (guides, sequenced after this), [#2249](https://github.com/wheels-dev/wheels/issues/2249) (sequenced after #2244)
**Parent spec:** `2026-04-22-wheels-packages-registry-design.md` (on branch `claude/infallible-davinci-58997d`, not yet on `develop`)
**Audit:** `2026-04-22-v4-ga-architectural-review.md` P4

---

## Purpose

The parent registry spec assumes every first-party package lives in a standalone author-owned repo with SemVer tags. Today's reality differs:

- Four "first-party packages" (`sentry`, `hotwire`, `basecoat`, `legacyadapter`) are inline in this monorepo's `packages/` directory with no external repo.
- Two existing external repos (`wheels-seo-suite`, `wheels-i18n`) are Wheels 3.x plugins, not 4.0 packages — they have `box.json`, no `package.json`, no `wheelsVersion`, no `tests/`. They'd fail the registry's `validate.yml`.

Result: Phase 1 as written can't seed anything. This spec resolves that.

## Scope

This phase delivers the registry bootstrap (#2243 Phase 1) plus the repo extractions required to make seeding actually work.

**In scope:**

1. Extract four monorepo packages to standalone `wheels-dev/` repos with preserved git history.
2. Tag each extracted repo at `v1.0.0`; cut GH Releases.
3. Create `wheels-dev/wheels-packages` registry repo with: schema, CI validation workflow, tarball-mirror workflow scaffold, seed manifests for the four extracted packages, CONTRIBUTING, README.
4. Remove `packages/` directory from the monorepo (D1-c: 4.0 is pre-release, impact minimal).
5. Remove `packages/` per-package test job from `.github/workflows/compat-matrix.yml`; each extracted repo tests itself.
6. Update in-repo docs that reference `packages/...` to point at either `vendor/...` (activated state) or the extracted repos' GitHub URLs.
7. Open follow-up issues for `wheels-seo-suite` and `wheels-i18n` 3.x → 4.0 package conversion.

**Out of scope (deferred to later phases of #2243):**

- `mirror-tarball.yml` implementation (structure scaffolded, logic deferred to Phase 2).
- `wheels packages list|install|update|remove` CLI commands (Phase 3).
- Web UI at `wheels.dev/packages` and `/wheels/packages` (Phase 4).
- 3.x → 4.0 conversion of seo-suite and i18n.
- P9 checksum-code removal from `PackageLoader.cfc` (separate audit item).

## Decisions

| # | Decision | Choice | Rationale |
|---|---|---|---|
| D1 | `packages/` in monorepo after extraction | **Delete** | 4.0 is pre-release; `packages/` introduced in 4.0 itself — no long-lived users to break. |
| D2 | Starting version on extracted repos | **`v1.0.0` across all four** | Registry publication is the real "1.0" milestone. Pre-registry in-monorepo versions (0.1.0 / 1.0.0 mix) are meaningless externally. |
| D3 | Git history preservation | **`git subtree split`** | Shallow history (5–8 commits per package); trivial to preserve author/date metadata. |
| D4 | `wheels-seo-suite` / `wheels-i18n` handling | **Drop from Phase 1 seed; follow-up issues** | Both are 3.x plugins requiring real conversion work (author `package.json`, port `index.cfm` lifecycle, add tests). That work doesn't belong in a bootstrap phase. |
| D5 | Authorization | **Granted** | User explicitly confirmed `gh repo create` + push + tag + release across five new repos. |

## Architecture

### Repos after this phase

```
wheels-dev/
├── wheels                          ← monorepo (packages/ removed)
├── wheels-packages                 ← NEW registry
├── wheels-sentry                   ← NEW, extracted from packages/sentry
├── wheels-hotwire                  ← NEW, extracted from packages/hotwire
├── wheels-basecoat                 ← NEW, extracted from packages/basecoat
├── wheels-legacy-adapter           ← NEW, extracted from packages/legacyadapter
├── wheels-seo-suite                ← unchanged (follow-up conversion)
└── wheels-i18n                     ← unchanged (follow-up conversion)
```

### Per extracted repo, the delivered state

```
wheels-<name>/
├── LICENSE                 (Apache 2.0, matching wheels parent)
├── README.md               (existing package README)
├── CLAUDE.md               (existing, if present)
├── package.json            (existing manifest; version bumped to 1.0.0, wheelsVersion → ">=4.0")
├── box.json                (existing — kept for legacy CommandBox users)
├── <Name>.cfc              (main entry)
├── index.cfm               (existing bootstrap)
└── tests/                  (existing suite)
```

Tag `v1.0.0` on `main` at extraction commit, then GH Release cut with a stock "Initial release from Wheels monorepo extraction" body.

### `wheels-packages` registry layout

```
wheels-packages/
├── LICENSE                                 Apache 2.0
├── README.md                               registry purpose, install pattern, link to CONTRIBUTING
├── CONTRIBUTING.md                         submission workflow, review criteria
├── schema/
│   └── manifest.schema.json                JSONSchema — enforced by validate.yml
├── packages/
│   ├── wheels-sentry/
│   │   ├── manifest.json                   seed entry with v1.0.0
│   │   └── README.md                       listing blurb (one paragraph)
│   ├── wheels-hotwire/
│   ├── wheels-basecoat/
│   └── wheels-legacy-adapter/
└── .github/
    └── workflows/
        ├── validate.yml                    schema + name uniqueness + tag resolvability + file-type allowlist + size cap
        └── mirror-tarball.yml              SCAFFOLD (runs no-op for now, logic in Phase 2)
```

### Seed manifest shape

```json
{
  "name": "wheels-sentry",
  "description": "Sentry error tracking for Wheels with framework-aware context enrichment",
  "homepage": "https://github.com/wheels-dev/wheels-sentry",
  "documentation": "https://wheels.dev/packages/wheels-sentry",
  "license": "Apache-2.0",
  "maintainers": ["@bpamiri"],
  "tags": ["monitoring", "errors", "observability"],
  "source": {
    "type": "github",
    "repo": "wheels-dev/wheels-sentry"
  },
  "versions": [
    {
      "version": "1.0.0",
      "publishedAt": "2026-04-23T00:00:00Z",
      "wheelsVersion": ">=4.0",
      "sourceTag": "v1.0.0",
      "tarball": null,
      "sha256": null
    }
  ]
}
```

`tarball` and `sha256` remain `null` in Phase 1. Phase 2's `mirror-tarball.yml` will fill them on merge. The JSONSchema accepts null for both at Phase 1; Phase 2 tightens it to require both once the mirror workflow ships.

### `validate.yml` responsibilities (Phase 1)

- JSON schema check against `schema/manifest.schema.json`.
- Manifest `name` matches parent directory name under `packages/`.
- `name` globally unique across the registry.
- `source.repo` resolves via GitHub API.
- `versions[*].sourceTag` resolves on `source.repo`.
- Clone author repo at tag → validate `package.json` present, `name`/`version` match manifest, `wheelsVersion` present.
- File-type allowlist: `.cfc .cfm .cfml .md .json .js .mjs .ts .css .scss .html .txt .sql .yml .yaml .gitkeep`. Anything else → PR comment flagging it for reviewer justification.
- Size cap: 10 MB uncompressed.
- Basic smell checks: no shell-out or process-invocation tags in shipped code without a reviewer annotation.

`mirror-tarball.yml` is stubbed (a workflow file with a single `echo "Phase 2 — not yet implemented"` step) so the referenced workflow file exists and the registry README can point at it.

### Monorepo cleanup (`wheels` repo PR)

Single PR on `develop`:

- Delete `packages/`.
- Remove the "Run per-package tests" step from `.github/workflows/compat-matrix.yml` (lines ~429–500).
- Update docs that reference `packages/<name>`:
  - `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/packages.mdx` — rewrite activation examples to install from `wheels-packages` registry; keep the manifest-schema and lifecycle sections.
  - `CLAUDE.md` — Package System section: drop `packages/` staging concept; redirect to registry URL; keep `vendor/` activation model.
  - Tutorial and upgrade docs that mention `cp -r packages/...` — replace with the future `wheels packages install` idiom marked "coming in 4.1."
  - `cli/lucli/templates/app/app/plugins/README.md` — remove `cp -r packages/hotwire ...` reference.
- `CHANGELOG` / release notes entry.

### Follow-up issues opened at end of phase

- `wheels-seo-suite: convert to 4.0 package format (package.json, lifecycle, tests)`
- `wheels-i18n: convert to 4.0 package format (package.json, lifecycle, tests)`
- `wheels-packages Phase 2 — tarball mirror CI` (child of #2243)
- `wheels-packages Phase 3 — CLI commands` (child of #2243)
- `wheels-packages Phase 4 — web UI` (child of #2243)

## Execution sequence

1. **Stage locally (no public actions).** Under `/tmp/wheels-packages-staging/` create five git repos (four extractions via `git subtree split` + registry). Populate all files. Print a tree-view summary.
2. **User review gate.** Present local state to user. On approval only, continue.
3. **Push pass A — extractions.** For each of four repos: `gh repo create wheels-dev/<name> --public --source=. --push`. Then `git tag v1.0.0 && git push --tags`. Then `gh release create v1.0.0`.
4. **Push pass B — registry.** `gh repo create wheels-dev/wheels-packages --public --source=. --push`. Confirm `validate.yml` runs green on the four seed manifests.
5. **Monorepo PR.** Branch `peter/2243-phase1-remove-packages-dir` off `develop`. Delete `packages/`, rewrite `compat-matrix.yml`, update docs. Open PR with link to this spec.
6. **Spec + follow-up issues.** Commit this spec and the parent design spec (if not already merged) to `develop`. Open the five follow-up issues listed above.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Extracted repo missing a file (e.g., LICENSE not previously per-package) | Pre-push staging review; add LICENSE explicitly. |
| `git subtree split` preserves too little (author attribution only, no cross-package commits) | Acceptable; alternative (`git filter-repo`) adds tooling dep without material benefit at this history depth. |
| `validate.yml` fails on seed manifests because `source.tag` not yet pushed | Sequence enforces: extraction push + tag happens *before* registry push. |
| Monorepo PR breaks CI by removing the per-package test step while some dev branches still assume `packages/` exists | Announce in #it_builds; merge window after hours. All active branches already build clean without the packages step (it's a `continue`-on-missing-tests loop). |
| `packages/` removal confuses 4.0-snapshot users who downloaded the nightly | Upgrade-guide note; dev-only tarballs. 4.0 hasn't shipped as a release — all known users are internal. |
| Extracted repos diverge from monorepo versions (future bug fixes) | Out of scope for Phase 1. Owner-of-record for each extracted repo is documented in its README. |

## Acceptance criteria

- Five new repos live, public, buildable:
  - `wheels-dev/wheels-sentry`, `wheels-hotwire`, `wheels-basecoat`, `wheels-legacy-adapter` each at `v1.0.0` with a GH Release.
  - `wheels-dev/wheels-packages` with passing `validate.yml` on all four seed manifests.
- Monorepo PR merged on `develop`:
  - `packages/` gone.
  - `compat-matrix.yml` per-package step removed.
  - Docs updated; no remaining broken links to `packages/<name>`.
- Five follow-up issues filed and cross-linked.
- This spec plus the parent `2026-04-22-wheels-packages-registry-design.md` both present on `develop`.

## Unresolved questions

- Maintainer handle in seed manifests: `@bpamiri` or `@wheels-dev` team handle? (Defaulting to `@bpamiri` unless told otherwise.)
- `documentation` URL field for manifests — `wheels.dev/packages/<name>` does not yet render (blocked on Phase 4). Leave populated anyway so links activate automatically when Phase 4 ships?
- Should the extracted repos carry CHANGELOG.md? (Lightweight; easy to add. Default: yes, minimal entry.)
