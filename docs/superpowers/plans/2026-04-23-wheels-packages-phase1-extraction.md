# Wheels Packages Phase 1 — Extraction & Registry Bootstrap

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract four monorepo packages (sentry, hotwire, basecoat, legacy-adapter) into standalone `wheels-dev/*` repos with preserved git history, bootstrap a new `wheels-dev/wheels-packages` registry seeded with those four, and remove `packages/` from the monorepo.

**Architecture:** Use `git subtree split` to produce history-preserving branches per package, create new standalone repos, tag `v1.0.0`, cut GH Releases. Registry is a plain git repo with JSONSchema-enforced manifests + a `validate.yml` GH Actions workflow. Monorepo cleanup lands as a single PR against `develop`.

**Tech Stack:** bash, `git`, `gh` CLI, GitHub Actions, JSONSchema (via `ajv-cli`), Apache 2.0 license.

**Spec:** [`docs/superpowers/specs/2026-04-23-wheels-packages-phase1-extraction-design.md`](../specs/2026-04-23-wheels-packages-phase1-extraction-design.md)

**Refs:** [#2243](https://github.com/wheels-dev/wheels/issues/2243) (Phase 1)

---

## Prerequisites

- `gh auth status` shows logged in to `bpamiri` account with write access to `wheels-dev/` org
- Working directory: `/Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/fervent-jepsen-e89804`
- Clean working tree (spec already committed at `2c7887ba9`)
- Staging area: `/tmp/wheels-packages-staging/` (will be created in Task 1)
- All implementation work happens on branch `claude/fervent-jepsen-e89804` (current branch)

## File Structure

### New files (staging — `/tmp/wheels-packages-staging/`)

```
/tmp/wheels-packages-staging/
├── wheels-sentry/              git repo (history-preserved from monorepo)
├── wheels-hotwire/             git repo (history-preserved from monorepo)
├── wheels-basecoat/            git repo (history-preserved from monorepo)
├── wheels-legacy-adapter/      git repo (history-preserved from monorepo)
└── wheels-packages/            git repo (new registry)
    ├── LICENSE
    ├── README.md
    ├── CONTRIBUTING.md
    ├── schema/manifest.schema.json
    ├── packages/wheels-sentry/manifest.json
    ├── packages/wheels-sentry/README.md
    ├── packages/wheels-hotwire/manifest.json
    ├── packages/wheels-hotwire/README.md
    ├── packages/wheels-basecoat/manifest.json
    ├── packages/wheels-basecoat/README.md
    ├── packages/wheels-legacy-adapter/manifest.json
    ├── packages/wheels-legacy-adapter/README.md
    └── .github/workflows/validate.yml
    └── .github/workflows/mirror-tarball.yml   (stub)
```

### Modified files (monorepo)

- Delete: `packages/` (entire directory)
- Modify: `.github/workflows/compat-matrix.yml` (remove "Run per-package tests" step, lines ~429–500)
- Modify: `CLAUDE.md` (Package System section)
- Modify: `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/packages.mdx`
- Modify: `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/03-crud-scaffold.mdx`
- Modify: `web/sites/guides/src/content/docs/v4-0-0-snapshot/upgrading/3x-to-4x.mdx`
- Modify: `web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/observability-and-logging.mdx`
- Modify: `cli/lucli/templates/app/app/plugins/README.md`

### Testing approach

This work is infrastructure, not application code — there's no unit test to write. Verification is:

- **Per extracted repo:** `git log --oneline` shows preserved history; `cat package.json` shows version `1.0.0`, `wheelsVersion` `>=4.0`; `ls` shows expected files; test suite runs via the Wheels rig after activation.
- **Registry:** `ajv validate` runs against all four seed manifests locally before push; GH Actions `validate.yml` runs green on first push.
- **Monorepo PR:** `.github/workflows/compat-matrix.yml` passes; documentation renders (astro build); no dead links to `packages/` paths.

---

## Task 1: Create local staging workspace & extract first package (sentry)

**Files:**
- Create: `/tmp/wheels-packages-staging/` (directory)
- Create: `/tmp/wheels-packages-staging/wheels-sentry/` (git repo via subtree split)

- [ ] **Step 1: Create staging directory**

```bash
rm -rf /tmp/wheels-packages-staging
mkdir -p /tmp/wheels-packages-staging
```

Expected: directory created, empty.

- [ ] **Step 2: Produce a history-preserving branch for packages/sentry from the monorepo**

From the wheels monorepo working directory (`/Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/fervent-jepsen-e89804`):

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/fervent-jepsen-e89804
git subtree split --prefix=packages/sentry -b split/wheels-sentry
```

Expected: outputs a commit SHA (the tip of the history-preserved branch). The working tree is unchanged.

- [ ] **Step 3: Clone that branch into the staging dir as a standalone repo**

```bash
git clone -b split/wheels-sentry . /tmp/wheels-packages-staging/wheels-sentry
cd /tmp/wheels-packages-staging/wheels-sentry
git remote remove origin
git log --oneline | head -10
```

Expected: `wheels-sentry/` directory is a git repo with history from `packages/sentry/` only (no monorepo parent commits). 5 commits.

- [ ] **Step 4: Delete the temporary split branch from the monorepo**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/fervent-jepsen-e89804
git branch -D split/wheels-sentry
```

Expected: branch deleted, no trace in the monorepo.

- [ ] **Step 5: Verify extracted repo contents**

```bash
cd /tmp/wheels-packages-staging/wheels-sentry
ls
```

Expected output includes: `Sentry.cfc`, `SentryClient.cfc`, `README.md`, `CLAUDE.md`, `box.json`, `index.cfm`, `package.json`, `tests/`.

- [ ] **Step 6: Commit progress note (no code change yet — extraction only)**

No commit in this task — the extracted repo content is exactly what was in the monorepo. Normalization happens in Task 3.

---

## Task 2: Extract remaining three packages

**Files:**
- Create: `/tmp/wheels-packages-staging/wheels-hotwire/`
- Create: `/tmp/wheels-packages-staging/wheels-basecoat/`
- Create: `/tmp/wheels-packages-staging/wheels-legacy-adapter/`

- [ ] **Step 1: Extract hotwire**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/fervent-jepsen-e89804
git subtree split --prefix=packages/hotwire -b split/wheels-hotwire
git clone -b split/wheels-hotwire . /tmp/wheels-packages-staging/wheels-hotwire
cd /tmp/wheels-packages-staging/wheels-hotwire && git remote remove origin
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/fervent-jepsen-e89804
git branch -D split/wheels-hotwire
```

Expected: `/tmp/wheels-packages-staging/wheels-hotwire` git repo with 8 commits preserved.

- [ ] **Step 2: Extract basecoat**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/fervent-jepsen-e89804
git subtree split --prefix=packages/basecoat -b split/wheels-basecoat
git clone -b split/wheels-basecoat . /tmp/wheels-packages-staging/wheels-basecoat
cd /tmp/wheels-packages-staging/wheels-basecoat && git remote remove origin
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/fervent-jepsen-e89804
git branch -D split/wheels-basecoat
```

Expected: 8 commits.

- [ ] **Step 3: Extract legacy-adapter (note dir rename from `legacyadapter` → `wheels-legacy-adapter`)**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/fervent-jepsen-e89804
git subtree split --prefix=packages/legacyadapter -b split/wheels-legacy-adapter
git clone -b split/wheels-legacy-adapter . /tmp/wheels-packages-staging/wheels-legacy-adapter
cd /tmp/wheels-packages-staging/wheels-legacy-adapter && git remote remove origin
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/fervent-jepsen-e89804
git branch -D split/wheels-legacy-adapter
```

Expected: 6 commits.

- [ ] **Step 4: Verify all four extractions**

```bash
for d in sentry hotwire basecoat legacy-adapter; do
    echo "=== wheels-$d ==="
    cd /tmp/wheels-packages-staging/wheels-$d
    git log --oneline | wc -l
    ls package.json README.md 2>&1
done
```

Expected: each repo prints commit count (5/8/8/6), shows `package.json` and `README.md` present.

---

## Task 3: Normalize extracted repos (version bump, LICENSE, wheelsVersion, CHANGELOG)

Each extracted repo needs: version `1.0.0`, `wheelsVersion` `>=4.0`, Apache 2.0 `LICENSE`, minimal `CHANGELOG.md`. The homepage/author fields in `box.json` also need updating (sentry currently says `paiindustries/sentry-for-wheels`).

**Files per extracted repo:**
- Create: `LICENSE`
- Create: `CHANGELOG.md`
- Modify: `package.json` (version, wheelsVersion)
- Modify: `box.json` (homepage, author, version)

- [ ] **Step 1: Copy LICENSE from wheels monorepo into each extracted repo**

```bash
for d in sentry hotwire basecoat legacy-adapter; do
    cp /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/fervent-jepsen-e89804/LICENSE \
       /tmp/wheels-packages-staging/wheels-$d/LICENSE
done
```

Expected: each repo has an identical Apache 2.0 LICENSE file.

- [ ] **Step 2: Write package.json normalizer script**

Create `/tmp/wheels-packages-staging/normalize.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

for d in sentry hotwire basecoat legacy-adapter; do
    repo_dir="/tmp/wheels-packages-staging/wheels-$d"
    pkg_json="$repo_dir/package.json"

    # Bump version to 1.0.0 and wheelsVersion to >=4.0
    python3 -c "
import json
with open('$pkg_json') as f:
    pkg = json.load(f)
pkg['version'] = '1.0.0'
pkg['wheelsVersion'] = '>=4.0'
with open('$pkg_json', 'w') as f:
    json.dump(pkg, f, indent=4)
    f.write('\n')
"
    echo "Normalized $pkg_json"
done
```

Make executable and run:

```bash
chmod +x /tmp/wheels-packages-staging/normalize.sh
/tmp/wheels-packages-staging/normalize.sh
```

Expected: each `package.json` has `"version": "1.0.0"` and `"wheelsVersion": ">=4.0"`.

- [ ] **Step 3: Verify normalization**

```bash
for d in sentry hotwire basecoat legacy-adapter; do
    echo "=== wheels-$d/package.json ==="
    grep -E '"version"|"wheelsVersion"' /tmp/wheels-packages-staging/wheels-$d/package.json
done
```

Expected: all four show `"version": "1.0.0"` and `"wheelsVersion": ">=4.0"`.

- [ ] **Step 4: Update box.json homepage/version for sentry (points at old paiindustries URL)**

```bash
python3 -c "
import json
path = '/tmp/wheels-packages-staging/wheels-sentry/box.json'
with open(path) as f: b = json.load(f)
b['homepage'] = 'https://github.com/wheels-dev/wheels-sentry'
b['version'] = '1.0.0'
with open(path, 'w') as f: json.dump(b, f, indent=4); f.write('\n')
"
grep -E '"homepage"|"version"' /tmp/wheels-packages-staging/wheels-sentry/box.json
```

Expected: homepage points at `wheels-dev/wheels-sentry`, version `1.0.0`.

- [ ] **Step 5: Bump box.json version on other three**

```bash
for d in hotwire basecoat legacy-adapter; do
    python3 -c "
import json
path = '/tmp/wheels-packages-staging/wheels-$d/box.json'
with open(path) as f: b = json.load(f)
b['version'] = '1.0.0'
with open(path, 'w') as f: json.dump(b, f, indent=4); f.write('\n')
"
done
```

Expected: each box.json shows `"version": "1.0.0"`.

- [ ] **Step 6: Write minimal CHANGELOG.md per repo**

```bash
for d in sentry hotwire basecoat legacy-adapter; do
    cat > /tmp/wheels-packages-staging/wheels-$d/CHANGELOG.md <<EOF
# Changelog

All notable changes to this package will be documented in this file.

## [1.0.0] — 2026-04-23

### Added
- Initial standalone release, extracted from the Wheels monorepo at \`packages/$d\`.
- Git history preserved from the monorepo's package directory.
- Published to the \`wheels-dev/wheels-packages\` registry for installation via \`wheels packages install\` (coming in Wheels 4.1).
EOF
done
```

Expected: each repo has a `CHANGELOG.md` with a 1.0.0 entry.

- [ ] **Step 7: Commit normalization in each extracted repo**

```bash
for d in sentry hotwire basecoat legacy-adapter; do
    cd /tmp/wheels-packages-staging/wheels-$d
    git add LICENSE CHANGELOG.md package.json box.json
    git -c user.email="noreply@anthropic.com" -c user.name="Peter Amiri" \
        commit -m "chore: prepare for standalone release as wheels-$d v1.0.0

- Bump version to 1.0.0
- Set wheelsVersion >=4.0 (registry era begins at Wheels 4.1)
- Add Apache 2.0 LICENSE (previously inherited from monorepo)
- Add CHANGELOG with extraction note
- Update box.json homepage to wheels-dev org (sentry only)

Extracted from wheels-dev/wheels via git subtree split.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
done
```

Expected: each repo has one new commit on top of the preserved history.

---

## Task 4: Stage wheels-packages registry repo locally

**Files:**
- Create: `/tmp/wheels-packages-staging/wheels-packages/` (git repo)
- Create: `LICENSE`, `README.md`, `CONTRIBUTING.md`
- Create: `schema/manifest.schema.json`
- Create: `packages/wheels-{sentry,hotwire,basecoat,legacy-adapter}/manifest.json`
- Create: `packages/wheels-{sentry,hotwire,basecoat,legacy-adapter}/README.md`
- Create: `.github/workflows/validate.yml`
- Create: `.github/workflows/mirror-tarball.yml` (stub)

- [ ] **Step 1: Initialize repo**

```bash
mkdir -p /tmp/wheels-packages-staging/wheels-packages
cd /tmp/wheels-packages-staging/wheels-packages
git init -b main
```

Expected: empty repo on branch `main`.

- [ ] **Step 2: Write LICENSE**

```bash
cp /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/fervent-jepsen-e89804/LICENSE \
   /tmp/wheels-packages-staging/wheels-packages/LICENSE
```

Expected: Apache 2.0 LICENSE.

- [ ] **Step 3: Write README.md**

Create `/tmp/wheels-packages-staging/wheels-packages/README.md`:

```markdown
# Wheels Packages

The official registry for [Wheels](https://wheels.dev) packages. This repo holds package manifests and hosts their distribution tarballs as GitHub Release assets.

## What lives here

```
packages/
  wheels-sentry/
    manifest.json     ← authoritative metadata, version history
    README.md         ← listing blurb, shown on wheels.dev/packages
  wheels-hotwire/
  wheels-basecoat/
  wheels-legacy-adapter/
schema/
  manifest.schema.json  ← JSONSchema, CI-enforced
.github/workflows/
  validate.yml          ← runs on every PR
  mirror-tarball.yml    ← packages + uploads release asset on merge (Phase 2)
```

## How users install packages

Once the CLI ships in Wheels 4.1:

```bash
wheels packages list
wheels packages install wheels-sentry
wheels packages install wheels-sentry@1.0.0
wheels packages update wheels-sentry
```

The CLI reads manifests from this repo, downloads the tarball listed in the manifest (hosted as a GH Release asset on this repo), verifies the sha256, and activates the package into `vendor/` in the consumer's Wheels app.

## How authors submit packages

See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## License

Registry tooling and manifests: Apache 2.0. Each listed package carries its own license, declared in its manifest.
```

Expected: README.md written.

- [ ] **Step 4: Write CONTRIBUTING.md**

Create `/tmp/wheels-packages-staging/wheels-packages/CONTRIBUTING.md`:

```markdown
# Contributing to Wheels Packages

This registry is the official distribution channel for Wheels packages. This document explains how to submit a new package, publish a new version of an existing one, and what the review process looks like.

## Before you submit

Your package must:

1. **Live in its own public git repo** on GitHub. Monorepos and subpath-based submissions are not accepted in Phase 1.
2. **Have a `package.json` manifest** at the repo root with `name`, `version`, `wheelsVersion`, and either `provides.mixins` or at least one of `provides.services` / `provides.middleware`.
3. **Declare `wheelsVersion` as a SemVer range** (e.g., `">=4.0"`). Packages that don't declare this will be rejected.
4. **Be tagged at the version you're submitting.** The tag name must match `v<version>` — e.g., manifest version `1.2.0` → tag `v1.2.0`.
5. **Ship only allowlisted file types:** `.cfc`, `.cfm`, `.cfml`, `.md`, `.json`, `.js`, `.mjs`, `.ts`, `.css`, `.scss`, `.html`, `.txt`, `.sql`, `.yml`, `.yaml`, `.gitkeep`. Anything else will block CI until a maintainer reviews and approves.
6. **Stay under 10 MB uncompressed.** Packages larger than this need explicit maintainer approval.
7. **Declare a license** in the manifest's `license` field (SPDX identifier).

## Submitting a new package

1. **Fork this repo.**
2. **Create a new directory** under `packages/` named exactly after your package — e.g., `packages/wheels-foo/`.
3. **Add `manifest.json`** following the schema at `schema/manifest.schema.json`. Leave `versions[].tarball` and `versions[].sha256` as `null` — CI fills these on merge.
4. **Add `README.md`** — a one-paragraph listing blurb. Shown on `wheels.dev/packages/<name>`.
5. **Open a PR** with title `Add wheels-foo v1.0.0`.
6. **CI runs** — validates schema, name uniqueness, source-repo resolvability, tag existence, file-type allowlist, size cap.
7. **Maintainer reviews** — confirms author, glances at the author's repo, merges if everything looks good.
8. **Mirror workflow fires on merge** (Phase 2) — packages the tagged source into a deterministic tarball, uploads to this repo's Releases, computes sha256, commits both back into your manifest.
9. **Users can now install** via `wheels packages install wheels-foo`.

## Publishing a new version

1. **Tag the new version in your own repo** (`v1.1.0` etc.).
2. **Open a PR here** that appends to `packages/wheels-foo/manifest.json`'s `versions[]` array. Do not modify previous entries.
3. **CI and review** same as above.
4. **Users run `wheels packages update wheels-foo`** — opt-in only; no auto-pull.

## Review criteria

Maintainers look at:

- Does the author repo look real (commits, README, tests)?
- Does the manifest match the schema?
- Does the tag at `source.repo` resolve?
- Does the package fit the ecosystem (Wheels app augmentation, not e.g. a general-purpose CFML library masquerading as a package)?

## What we don't do

- **We don't host source code.** Your repo stays authoritative.
- **We don't auto-update.** Version bumps require an explicit PR.
- **We don't accept author-hosted tarball URLs** (Attack A defense — see the registry design spec).
- **We don't support private packages yet.** Post-4.1.

## Getting help

Open an issue on this repo or ping `#wheels-packages` on Discord.
```

Expected: CONTRIBUTING.md written.

- [ ] **Step 5: Write JSONSchema**

Create `/tmp/wheels-packages-staging/wheels-packages/schema/manifest.schema.json`:

```json
{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://github.com/wheels-dev/wheels-packages/schema/manifest.schema.json",
    "title": "Wheels Package Manifest",
    "description": "Metadata entry for a package listed in the Wheels packages registry",
    "type": "object",
    "required": ["name", "description", "license", "source", "versions"],
    "additionalProperties": false,
    "properties": {
        "name": {
            "type": "string",
            "pattern": "^wheels-[a-z0-9][a-z0-9-]*$",
            "description": "Package identifier, lowercase, prefixed with 'wheels-'"
        },
        "description": {
            "type": "string",
            "minLength": 10,
            "maxLength": 300
        },
        "homepage": { "type": "string", "format": "uri" },
        "documentation": { "type": "string", "format": "uri" },
        "license": {
            "type": "string",
            "description": "SPDX identifier (e.g., 'Apache-2.0', 'MIT')"
        },
        "maintainers": {
            "type": "array",
            "items": { "type": "string", "pattern": "^@[a-zA-Z0-9-]+$" },
            "minItems": 1
        },
        "tags": {
            "type": "array",
            "items": { "type": "string" }
        },
        "source": {
            "type": "object",
            "required": ["type", "repo"],
            "additionalProperties": false,
            "properties": {
                "type": { "enum": ["github"] },
                "repo": {
                    "type": "string",
                    "pattern": "^[a-zA-Z0-9-]+/[a-zA-Z0-9._-]+$"
                }
            }
        },
        "versions": {
            "type": "array",
            "minItems": 1,
            "items": {
                "type": "object",
                "required": ["version", "publishedAt", "wheelsVersion", "sourceTag"],
                "additionalProperties": false,
                "properties": {
                    "version": {
                        "type": "string",
                        "pattern": "^[0-9]+\\.[0-9]+\\.[0-9]+(-[a-zA-Z0-9.-]+)?$"
                    },
                    "publishedAt": { "type": "string", "format": "date-time" },
                    "wheelsVersion": { "type": "string" },
                    "sourceTag": { "type": "string", "minLength": 1 },
                    "tarball": {
                        "type": ["string", "null"],
                        "description": "GH Release asset URL, null until Phase 2 mirror runs"
                    },
                    "sha256": {
                        "type": ["string", "null"],
                        "pattern": "^([a-f0-9]{64})?$"
                    }
                }
            }
        }
    }
}
```

Expected: schema written with `null` permitted on `tarball` and `sha256` (Phase 1 allowance).

- [ ] **Step 6: Write seed manifests (four packages)**

Use this template, substituting per-package fields. Write one file per package.

`packages/wheels-sentry/manifest.json`:

```json
{
    "name": "wheels-sentry",
    "description": "Sentry error tracking for Wheels with framework-aware context enrichment.",
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

`packages/wheels-hotwire/manifest.json`:

```json
{
    "name": "wheels-hotwire",
    "description": "Hotwire infrastructure for Wheels: Turbo Drive, Turbo Frames, Turbo Streams, Stimulus helpers, and Hotwire Native mobile support.",
    "homepage": "https://github.com/wheels-dev/wheels-hotwire",
    "documentation": "https://wheels.dev/packages/wheels-hotwire",
    "license": "Apache-2.0",
    "maintainers": ["@bpamiri"],
    "tags": ["hotwire", "turbo", "stimulus", "spa"],
    "source": {
        "type": "github",
        "repo": "wheels-dev/wheels-hotwire"
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

`packages/wheels-basecoat/manifest.json`:

```json
{
    "name": "wheels-basecoat",
    "description": "Basecoat UI component helpers for Wheels. shadcn/ui-quality design using plain HTML + Tailwind CSS. No React required.",
    "homepage": "https://github.com/wheels-dev/wheels-basecoat",
    "documentation": "https://wheels.dev/packages/wheels-basecoat",
    "license": "Apache-2.0",
    "maintainers": ["@bpamiri"],
    "tags": ["ui", "components", "tailwind", "forms"],
    "source": {
        "type": "github",
        "repo": "wheels-dev/wheels-basecoat"
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

`packages/wheels-legacy-adapter/manifest.json`:

```json
{
    "name": "wheels-legacy-adapter",
    "description": "Backward compatibility adapter for migrating Wheels 3.x applications to 4.0. Provides deprecation logging, API shims, and a migration scanner.",
    "homepage": "https://github.com/wheels-dev/wheels-legacy-adapter",
    "documentation": "https://wheels.dev/packages/wheels-legacy-adapter",
    "license": "Apache-2.0",
    "maintainers": ["@bpamiri"],
    "tags": ["migration", "upgrade", "compatibility", "3x"],
    "source": {
        "type": "github",
        "repo": "wheels-dev/wheels-legacy-adapter"
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

Bash for creating directories:

```bash
cd /tmp/wheels-packages-staging/wheels-packages
mkdir -p packages/wheels-sentry packages/wheels-hotwire packages/wheels-basecoat packages/wheels-legacy-adapter schema .github/workflows
```

Then write each manifest file using the content above.

Expected: four manifest files under `packages/<name>/manifest.json`.

- [ ] **Step 7: Write per-package README listing blurbs**

`packages/wheels-sentry/README.md`:

```markdown
# wheels-sentry

Sentry error tracking for Wheels apps with framework-aware context enrichment. Captures exceptions with request, user, and route context. Mixes into controllers.

- **Source:** https://github.com/wheels-dev/wheels-sentry
- **License:** Apache-2.0
- **Wheels:** >= 4.0
```

`packages/wheels-hotwire/README.md`:

```markdown
# wheels-hotwire

Hotwire integration for Wheels: Turbo Drive for full-page SPA feel, Turbo Frames for scoped updates, Turbo Streams for real-time DOM updates, and Stimulus helpers for JavaScript sprinkles. Also supports Hotwire Native for mobile. Mixes into controllers and views.

- **Source:** https://github.com/wheels-dev/wheels-hotwire
- **License:** Apache-2.0
- **Wheels:** >= 4.0
```

`packages/wheels-basecoat/README.md`:

```markdown
# wheels-basecoat

shadcn/ui-quality UI components rendered as plain HTML with Tailwind CSS — no React required. Drop-in form controls, buttons, cards, alerts, and more. Mixes into controllers and views.

- **Source:** https://github.com/wheels-dev/wheels-basecoat
- **License:** Apache-2.0
- **Wheels:** >= 4.0
```

`packages/wheels-legacy-adapter/README.md`:

```markdown
# wheels-legacy-adapter

Backward compatibility shim for migrating Wheels 3.x applications to 4.0. Deprecation logging surfaces every 3.x idiom touched at runtime; API shims keep older code paths alive during migration; the migration scanner flags 3.x patterns in your codebase. Mixes into controllers.

- **Source:** https://github.com/wheels-dev/wheels-legacy-adapter
- **License:** Apache-2.0
- **Wheels:** >= 4.0
```

Expected: four README files under `packages/<name>/README.md`.

- [ ] **Step 8: Write `validate.yml` workflow**

Create `/tmp/wheels-packages-staging/wheels-packages/.github/workflows/validate.yml`:

```yaml
name: validate

on:
  pull_request:
    paths:
      - "packages/**"
      - "schema/**"
  push:
    branches: [main]
    paths:
      - "packages/**"
      - "schema/**"

jobs:
  schema:
    name: JSONSchema validation
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: "20"

      - name: Install ajv-cli
        run: npm install -g ajv-cli ajv-formats

      - name: Validate every manifest against schema
        run: |
          set -euo pipefail
          FAIL=0
          for manifest in packages/*/manifest.json; do
              echo "Validating $manifest"
              ajv validate -c ajv-formats -s schema/manifest.schema.json -d "$manifest" --strict=false || FAIL=1
          done
          exit $FAIL

  structure:
    name: Directory + name consistency
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check name matches directory
        run: |
          set -euo pipefail
          FAIL=0
          for manifest in packages/*/manifest.json; do
              dir=$(basename "$(dirname "$manifest")")
              name=$(jq -r .name "$manifest")
              if [ "$dir" != "$name" ]; then
                  echo "MISMATCH: directory '$dir' but manifest.name '$name'"
                  FAIL=1
              fi
          done
          exit $FAIL

      - name: Check name uniqueness
        run: |
          set -euo pipefail
          duplicates=$(jq -r .name packages/*/manifest.json | sort | uniq -d)
          if [ -n "$duplicates" ]; then
              echo "Duplicate names: $duplicates"
              exit 1
          fi

  source-resolvable:
    name: source.repo + sourceTag resolve on GitHub
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Verify each source.repo and its tags exist
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          set -euo pipefail
          FAIL=0
          for manifest in packages/*/manifest.json; do
              repo=$(jq -r .source.repo "$manifest")
              echo "Checking $repo ..."
              if ! gh repo view "$repo" >/dev/null 2>&1; then
                  echo "MISSING REPO: $repo"
                  FAIL=1
                  continue
              fi
              jq -r '.versions[].sourceTag' "$manifest" | while read -r tag; do
                  if ! gh api "repos/$repo/git/refs/tags/$tag" >/dev/null 2>&1; then
                      echo "MISSING TAG: $repo#$tag"
                      exit 1
                  fi
              done || FAIL=1
          done
          exit $FAIL

  content-safety:
    name: File-type allowlist + size cap
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Clone each source tag & scan
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          set -euo pipefail
          ALLOWED='\.cfc$|\.cfm$|\.cfml$|\.md$|\.json$|\.js$|\.mjs$|\.ts$|\.css$|\.scss$|\.html$|\.txt$|\.sql$|\.yml$|\.yaml$|\.gitkeep$|LICENSE$|CHANGELOG$'
          MAX_BYTES=$((10 * 1024 * 1024))
          FAIL=0
          for manifest in packages/*/manifest.json; do
              repo=$(jq -r .source.repo "$manifest")
              latest_tag=$(jq -r '.versions[-1].sourceTag' "$manifest")
              echo "Scanning $repo@$latest_tag"
              tmp=$(mktemp -d)
              gh repo clone "$repo" "$tmp/src" -- --depth=1 --branch="$latest_tag"
              # Size cap
              size=$(du -sb "$tmp/src" --exclude=.git | awk '{print $1}')
              if [ "$size" -gt "$MAX_BYTES" ]; then
                  echo "OVER CAP: $repo = $size bytes"
                  FAIL=1
              fi
              # File-type allowlist
              disallowed=$(find "$tmp/src" -type f -not -path "*/.git/*" | grep -vE "$ALLOWED" || true)
              if [ -n "$disallowed" ]; then
                  echo "DISALLOWED FILE TYPES in $repo:"
                  echo "$disallowed"
                  FAIL=1
              fi
              rm -rf "$tmp"
          done
          exit $FAIL
```

Expected: workflow file written.

- [ ] **Step 9: Write stub `mirror-tarball.yml`**

Create `/tmp/wheels-packages-staging/wheels-packages/.github/workflows/mirror-tarball.yml`:

```yaml
name: mirror-tarball

# Phase 2 workflow — not yet implemented. Scaffolded so validate.yml can
# reference the file path and the registry README can point at it.
# When implemented, this will run on PR merge:
#   - clone source.repo at sourceTag
#   - produce deterministic tarball (tar --sort=name --mtime=@0)
#   - upload as GH Release asset on wheels-packages
#   - compute sha256
#   - commit tarball URL + sha256 back into the manifest

on:
  workflow_dispatch:

jobs:
  noop:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Phase 2 — not yet implemented. See the registry design spec."
```

Expected: stub file written.

- [ ] **Step 10: Validate manifests locally with ajv-cli before proceeding**

```bash
cd /tmp/wheels-packages-staging/wheels-packages
npm install --no-save ajv-cli ajv-formats
for manifest in packages/*/manifest.json; do
    echo "=== $manifest ==="
    npx ajv validate -c ajv-formats -s schema/manifest.schema.json -d "$manifest" --strict=false
done
```

Expected: each manifest prints "valid".

- [ ] **Step 11: Commit registry repo initial state**

```bash
cd /tmp/wheels-packages-staging/wheels-packages
rm -rf node_modules package-lock.json  # ajv install artifacts
git add .
git -c user.email="noreply@anthropic.com" -c user.name="Peter Amiri" \
    commit -m "feat: bootstrap wheels-packages registry with four seed manifests

Seeds:
- wheels-sentry v1.0.0
- wheels-hotwire v1.0.0
- wheels-basecoat v1.0.0
- wheels-legacy-adapter v1.0.0

Ships:
- schema/manifest.schema.json (JSONSchema, CI-enforced)
- .github/workflows/validate.yml (schema + name uniqueness + source resolvability + file-type allowlist + size cap)
- .github/workflows/mirror-tarball.yml (Phase 2 stub)
- CONTRIBUTING.md + README.md
- Apache 2.0 LICENSE

All four seed packages are extracted from the wheels monorepo's
packages/ directory via git subtree split into wheels-dev/wheels-<name>
standalone repos, each tagged v1.0.0.

Ref: wheels-dev/wheels#2243 Phase 1

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

Expected: one commit in the new registry repo with all the bootstrap contents.

---

## Task 5: User review gate

**This task is not automatable. The implementation agent must pause and hand control to the user.**

- [ ] **Step 1: Print local staging tree for review**

```bash
echo "=== Staging summary ==="
for r in wheels-sentry wheels-hotwire wheels-basecoat wheels-legacy-adapter wheels-packages; do
    echo ""
    echo "--- $r ---"
    cd /tmp/wheels-packages-staging/$r
    git log --oneline | head -5
    echo "Files:"
    git ls-files | head -20
done
```

- [ ] **Step 2: Display to user and await approval**

Post to the user: "Local staging complete. Five repos staged under `/tmp/wheels-packages-staging/`. Review the tree output and the contents of any file you'd like. Approve (yes/no) before I push to GitHub."

Do not proceed to Task 6 until explicit user approval is received.

---

## Task 6: Push four extraction repos + tag + release

For each of the four extracted repos: create GH repo, push, tag v1.0.0, cut release.

**Files:**
- Creates GitHub repos: `wheels-dev/wheels-sentry`, `wheels-dev/wheels-hotwire`, `wheels-dev/wheels-basecoat`, `wheels-dev/wheels-legacy-adapter`

- [ ] **Step 1: Create + push `wheels-sentry`**

```bash
cd /tmp/wheels-packages-staging/wheels-sentry
gh repo create wheels-dev/wheels-sentry \
    --public \
    --description "Sentry error tracking for Wheels with framework-aware context enrichment" \
    --homepage "https://wheels.dev/packages/wheels-sentry" \
    --source=. \
    --push
```

Expected: repo created, commits pushed to `main`.

- [ ] **Step 2: Tag v1.0.0 and push the tag**

```bash
cd /tmp/wheels-packages-staging/wheels-sentry
git tag -a v1.0.0 -m "v1.0.0 — initial standalone release from wheels monorepo extraction"
git push origin v1.0.0
```

Expected: tag visible in `gh release list`.

- [ ] **Step 3: Cut GH Release**

```bash
cd /tmp/wheels-packages-staging/wheels-sentry
gh release create v1.0.0 \
    --title "wheels-sentry v1.0.0" \
    --notes "Initial standalone release, extracted from the [Wheels monorepo](https://github.com/wheels-dev/wheels) at \`packages/sentry\` with preserved git history.

Published to the [wheels-dev/wheels-packages](https://github.com/wheels-dev/wheels-packages) registry for installation via \`wheels packages install wheels-sentry\` (coming in Wheels 4.1).

See [CHANGELOG.md](CHANGELOG.md) for details."
```

Expected: GH Release at `wheels-dev/wheels-sentry/releases/tag/v1.0.0`.

- [ ] **Step 4: Repeat for `wheels-hotwire`**

Same three commands, substituting `sentry` → `hotwire`, with description "Hotwire infrastructure for Wheels: Turbo Drive, Turbo Frames, Turbo Streams, Stimulus helpers, and Hotwire Native mobile support".

- [ ] **Step 5: Repeat for `wheels-basecoat`**

Substitute description "Basecoat UI component helpers for Wheels. shadcn/ui-quality design using plain HTML + Tailwind CSS. No React required."

- [ ] **Step 6: Repeat for `wheels-legacy-adapter`**

Substitute description "Backward compatibility adapter for migrating Wheels 3.x applications to 4.0. Provides deprecation logging, API shims, and a migration scanner."

- [ ] **Step 7: Verify all four repos + releases**

```bash
for r in wheels-sentry wheels-hotwire wheels-basecoat wheels-legacy-adapter; do
    echo "=== $r ==="
    gh release view v1.0.0 --repo wheels-dev/$r --json name,tagName,isPrerelease
done
```

Expected: four releases each at `v1.0.0`, non-prerelease.

---

## Task 7: Push wheels-packages registry + validate CI runs green

**Files:**
- Creates GitHub repo: `wheels-dev/wheels-packages`

- [ ] **Step 1: Create + push registry repo**

```bash
cd /tmp/wheels-packages-staging/wheels-packages
gh repo create wheels-dev/wheels-packages \
    --public \
    --description "Official registry for Wheels packages. Manifests and distribution tarballs for the Wheels ecosystem." \
    --homepage "https://wheels.dev/packages" \
    --source=. \
    --push
```

Expected: repo created, one commit on main.

- [ ] **Step 2: Wait for validate.yml to complete on first push**

```bash
sleep 15
gh run list --repo wheels-dev/wheels-packages --limit 5
```

Expected: `validate` workflow in progress or completed.

- [ ] **Step 3: Check run status**

```bash
gh run watch --repo wheels-dev/wheels-packages $(gh run list --repo wheels-dev/wheels-packages --workflow validate.yml --limit 1 --json databaseId --jq '.[0].databaseId')
```

Expected: all four jobs (`schema`, `structure`, `source-resolvable`, `content-safety`) pass.

- [ ] **Step 4: If any job fails, diagnose and fix**

If CI fails, read the logs:

```bash
gh run view --log --repo wheels-dev/wheels-packages $(gh run list --repo wheels-dev/wheels-packages --workflow validate.yml --limit 1 --json databaseId --jq '.[0].databaseId')
```

Likely failure modes:
- `source-resolvable` fails: one of the extracted repos didn't push cleanly → re-run Task 6 for the missing one.
- `content-safety` fails: an extracted repo has files outside the allowlist (likely `.gitattributes`, `.editorconfig`, etc.). Either extend the allowlist in `validate.yml` or remove the files from the extracted repo + retag.
- `schema` fails: a manifest has a subtle schema violation. Fix and push.

Commit any fix to `main` on `wheels-packages`.

- [ ] **Step 5: Confirm CI green**

```bash
gh run list --repo wheels-dev/wheels-packages --workflow validate.yml --limit 1
```

Expected: most recent run shows `completed success`.

---

## Task 8: Monorepo PR — delete packages/, rewrite CI, update docs

**Files:**
- Delete: `packages/` (everything under it)
- Modify: `.github/workflows/compat-matrix.yml` (remove the "Run per-package tests" step)
- Modify: `CLAUDE.md`
- Modify: `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/packages.mdx`
- Modify: `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/03-crud-scaffold.mdx`
- Modify: `web/sites/guides/src/content/docs/v4-0-0-snapshot/upgrading/3x-to-4x.mdx`
- Modify: `web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/observability-and-logging.mdx`
- Modify: `cli/lucli/templates/app/app/plugins/README.md`

- [ ] **Step 1: Verify branch + clean tree**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/fervent-jepsen-e89804
git status
git branch --show-current
```

Expected: branch `claude/fervent-jepsen-e89804`, clean tree (spec commit already present).

- [ ] **Step 2: Delete packages/ directory**

```bash
git rm -rf packages
```

Expected: `git status` shows all files under `packages/` staged as deleted.

- [ ] **Step 3: Remove per-package test step from compat-matrix.yml**

Open `.github/workflows/compat-matrix.yml`. Locate the `- name: Run per-package tests` step (search for that string). Delete the entire step (from `- name: Run per-package tests` through the end of that step's `run:` block — in practice, lines ~429 through ~500 or wherever the step ends and the next `- name:` begins).

Exact boundaries: find the line starting with `      - name: Run per-package tests` and find the next `      - name:` that follows; delete everything in between (inclusive of the first line, exclusive of the second).

If there is no next `- name:` (i.e., it's the last step in the job), delete everything from that line to the end of the `steps:` list.

Verify with:

```bash
grep -n "per-package tests" .github/workflows/compat-matrix.yml
```

Expected: no matches.

- [ ] **Step 4: Update CLAUDE.md Package System section**

Open `CLAUDE.md`. Find the `## Package System` section. Replace it with:

```markdown
## Package System

Optional modules are distributed via the [`wheels-dev/wheels-packages`](https://github.com/wheels-dev/wheels-packages) registry. Users install them via `wheels packages install <name>` (coming in Wheels 4.1); packages land under `vendor/` and are auto-discovered on startup by `PackageLoader.cfc` with per-package error isolation.

```
vendor/
  wheels/              #   Framework core (excluded from package discovery)
  wheels-sentry/       #   Installed package (extracted to standalone repo)
  ...
plugins/               # DEPRECATED: legacy plugins still work with warning
```

### package.json Manifest

(Schema reference unchanged — keep this block.)

### Distribution

Each package is a public git repo under `wheels-dev/` (e.g., `wheels-dev/wheels-sentry`). The `wheels-packages` registry holds manifests pointing at those source repos + distribution tarballs as GH Release assets. Installation flow (once CLI ships in Wheels 4.1):

```bash
wheels packages list
wheels packages install wheels-sentry
wheels packages update wheels-sentry
```

Until the CLI ships, manual install:

```bash
gh repo clone wheels-dev/wheels-sentry vendor/wheels-sentry
# or: download the GH Release tarball and extract into vendor/
```

Restart or reload the app after install.
```

Keep the existing "Error Isolation" and "Testing Packages" subsections unchanged — they still apply.

Delete any paragraph that mentions `packages/` as a staging area.

- [ ] **Step 5: Update `packages.mdx` guide**

In `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/packages.mdx`:

- Replace the "activation model" section: drop the "packages/ is a staging area" framing. Replace with: "Packages are installed into `vendor/<name>/` via the `wheels packages` CLI (coming in Wheels 4.1) or by cloning the package's repo directly."
- Replace the `cp -r packages/hotwire vendor/hotwire` examples with `gh repo clone wheels-dev/wheels-hotwire vendor/wheels-hotwire` (interim workflow until CLI ships).
- Update the "First-party packages" list — each entry now links to `https://github.com/wheels-dev/wheels-<name>`.
- Delete the `packages/` symlink example; symlinks now point at a cloned-elsewhere dir if authors want live development.

Use Edit tool with exact old_string / new_string pairs since the file is 253 lines.

- [ ] **Step 6: Update tutorial `03-crud-scaffold.mdx`**

In `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/03-crud-scaffold.mdx`:

Find any `packages/` reference. Most likely a "copy basecoat from packages/" step. Replace with instructions to install via `gh repo clone wheels-dev/wheels-basecoat vendor/wheels-basecoat`.

- [ ] **Step 7: Update `3x-to-4x.mdx` upgrade guide**

In `web/sites/guides/src/content/docs/v4-0-0-snapshot/upgrading/3x-to-4x.mdx`:

Replace `packages/legacyadapter` → `wheels-dev/wheels-legacy-adapter` external repo. Update activation instructions to reflect registry install pattern.

- [ ] **Step 8: Update `observability-and-logging.mdx`**

In `web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/observability-and-logging.mdx`:

Replace any `packages/sentry` references with `wheels-dev/wheels-sentry` + registry install instructions.

- [ ] **Step 9: Update `cli/lucli/templates/app/app/plugins/README.md`**

Replace the `cp -r packages/hotwire vendor/hotwire` line with `gh repo clone wheels-dev/wheels-hotwire vendor/wheels-hotwire` (or the `wheels packages install` line with a note that it's 4.1+).

- [ ] **Step 10: Grep for any remaining `packages/<name>` references**

```bash
grep -rn "packages/sentry\|packages/hotwire\|packages/basecoat\|packages/legacyadapter" \
    --include="*.md" --include="*.mdx" --include="*.cfm" --include="*.cfc" \
    . 2>/dev/null | grep -v "^\./docs/superpowers/"
```

Expected: zero matches (excluding historical plan/spec docs under `docs/superpowers/` which we intentionally preserve as history).

If any matches appear, edit each to use the new pattern.

- [ ] **Step 11: Run local doc build to confirm no broken links**

```bash
cd web/sites/guides
npm install
npm run build 2>&1 | tail -30
```

Expected: build succeeds. Any "broken link" warnings must be addressed before commit.

- [ ] **Step 12: Commit monorepo changes**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/fervent-jepsen-e89804
git add -A
git commit -m "$(cat <<'EOF'
feat(plugin): remove packages/ directory, redirect to wheels-packages registry

The four inline first-party packages (sentry, hotwire, basecoat, legacyadapter)
have been extracted to standalone wheels-dev/ repos and registered in the new
wheels-dev/wheels-packages registry. This commit removes the monorepo staging
copies and redirects all docs to the new installation path.

Changes:
- Delete packages/ (sentry, hotwire, basecoat, legacyadapter subdirs)
- Remove "Run per-package tests" step from compat-matrix.yml — extracted
  repos now test themselves in their own CI
- CLAUDE.md: rewrite Package System section to reflect registry-based
  distribution; drop packages/ staging concept
- digging-deeper/packages.mdx: replace activation examples with registry
  install pattern; update first-party package list to external-repo links
- Tutorial, upgrade guide, and observability guide: redirect all packages/
  references to external repos
- CLI template README: redirect packages/hotwire reference

The new external repos:
- https://github.com/wheels-dev/wheels-sentry (v1.0.0)
- https://github.com/wheels-dev/wheels-hotwire (v1.0.0)
- https://github.com/wheels-dev/wheels-basecoat (v1.0.0)
- https://github.com/wheels-dev/wheels-legacy-adapter (v1.0.0)

All four registered in wheels-dev/wheels-packages under packages/<name>/manifest.json.

Closes #2243 Phase 1.

Refs design spec: docs/superpowers/specs/2026-04-23-wheels-packages-phase1-extraction-design.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

Expected: single commit on the current branch.

- [ ] **Step 13: Push and open PR**

```bash
git push -u origin claude/fervent-jepsen-e89804
gh pr create \
    --base develop \
    --title "feat(plugin): remove packages/ directory, redirect to wheels-packages registry (#2243 Phase 1)" \
    --body "$(cat <<'EOF'
## Summary

Phase 1 of [#2243](https://github.com/wheels-dev/wheels/issues/2243) — extracts the four inline first-party packages into standalone `wheels-dev/*` repos and bootstraps the new `wheels-dev/wheels-packages` registry. This PR removes the monorepo staging copies and redirects all docs to the new registry-based install path.

**Design spec:** `docs/superpowers/specs/2026-04-23-wheels-packages-phase1-extraction-design.md`

### What landed outside this repo

- [wheels-dev/wheels-sentry v1.0.0](https://github.com/wheels-dev/wheels-sentry/releases/tag/v1.0.0)
- [wheels-dev/wheels-hotwire v1.0.0](https://github.com/wheels-dev/wheels-hotwire/releases/tag/v1.0.0)
- [wheels-dev/wheels-basecoat v1.0.0](https://github.com/wheels-dev/wheels-basecoat/releases/tag/v1.0.0)
- [wheels-dev/wheels-legacy-adapter v1.0.0](https://github.com/wheels-dev/wheels-legacy-adapter/releases/tag/v1.0.0)
- [wheels-dev/wheels-packages](https://github.com/wheels-dev/wheels-packages) (registry with the four seeds, passing validate.yml)

### Follow-ups (filed as separate issues)

- `wheels-seo-suite` → convert to 4.0 package format
- `wheels-i18n` → convert to 4.0 package format
- `#2243` Phase 2 — tarball mirror CI
- `#2243` Phase 3 — CLI commands
- `#2243` Phase 4 — web UI

## Test plan

- [ ] compat-matrix.yml is green after removing the per-package-test step
- [ ] `npm run build` in `web/sites/guides/` succeeds with no broken-link warnings
- [ ] `grep -rn "packages/(sentry|hotwire|basecoat|legacyadapter)"` returns zero code/doc matches (excluding `docs/superpowers/` history)
- [ ] CLAUDE.md Package System section reads correctly

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Expected: PR opened against `develop`.

- [ ] **Step 14: Wait for CI**

```bash
gh pr checks --watch
```

Expected: compat-matrix + other required checks green. If any fail, diagnose and push fix commits to the same branch.

---

## Task 9: File follow-up issues

- [ ] **Step 1: File `wheels-seo-suite` conversion issue**

```bash
gh issue create --repo wheels-dev/wheels --title "packages: convert wheels-seo-suite to 4.0 package format" --body "$(cat <<'EOF'
Follow-up from [#2243](https://github.com/wheels-dev/wheels/issues/2243) Phase 1.

`wheels-dev/wheels-seo-suite` is currently a Wheels 3.x plugin (has `box.json` with `type: "cfwheels-plugins"`, classic `index.cfm` bootstrap, no `package.json`, no `tests/`).

To be registerable in the `wheels-packages` registry, it needs 4.0 conversion:

### Scope
- [ ] Author `package.json` (name, version, wheelsVersion, provides.mixins)
- [ ] Port `index.cfm` lifecycle to the package CFC init() hook
- [ ] Add `tests/` suite (use WheelsTest BDD)
- [ ] Update README to reflect 4.0 installation via `wheels packages install wheels-seo-suite`
- [ ] Tag `v2.0.0` (major bump — 4.0 is breaking vs 3.x plugin format) and cut GH release
- [ ] Open PR on `wheels-dev/wheels-packages` adding `packages/wheels-seo-suite/manifest.json`

### Acceptance
- Registry's `validate.yml` passes on the new manifest
- `wheels packages install wheels-seo-suite` works (once Phase 3 CLI ships)
EOF
)"
```

- [ ] **Step 2: File `wheels-i18n` conversion issue**

Same template as Step 1, substituting `wheels-seo-suite` → `wheels-i18n` and the feature-list (add i18n-specific scope bullets if appropriate).

- [ ] **Step 3: File `#2243` Phase 2 child issue (tarball mirror CI)**

```bash
gh issue create --repo wheels-dev/wheels --title "wheels-packages Phase 2 — tarball mirror CI" --body "$(cat <<'EOF'
Phase 2 of [#2243](https://github.com/wheels-dev/wheels/issues/2243).

Implement the mirror-tarball.yml workflow on `wheels-dev/wheels-packages`. Currently a stub.

### Scope
- [ ] On PR merge: clone `source.repo` at `sourceTag` → deterministic tar (sort + mtime=0) → upload as GH Release asset on wheels-packages → compute sha256 → bot-commit tarball URL + sha256 back into manifest
- [ ] Release tag convention: `<name>-<version>`
- [ ] Tighten schema: `tarball` and `sha256` required post-Phase-2

### Acceptance
- Opening a PR on wheels-packages that appends a new version triggers the mirror automatically on merge; the manifest entry is populated with tarball + sha256 without manual edit.
EOF
)"
```

- [ ] **Step 4: File `#2243` Phase 3 child issue (CLI)**

Template similar to Step 3, scoped to CLI commands (`wheels packages list|search|show|install|update|remove|registry refresh|registry info`).

- [ ] **Step 5: File `#2243` Phase 4 child issue (web UI)**

Template similar to Step 3, scoped to `wheels.dev/packages` + `/wheels/packages` in-app.

- [ ] **Step 6: Link follow-up issues in #2243**

```bash
gh issue comment 2243 --repo wheels-dev/wheels --body "Phase 1 complete. Follow-up issues filed:
- Phase 2 — tarball mirror CI: #<NEW_ISSUE_NUMBER>
- Phase 3 — CLI: #<NEW_ISSUE_NUMBER>
- Phase 4 — web UI: #<NEW_ISSUE_NUMBER>
- External conversions: #<SEO_ISSUE>, #<I18N_ISSUE>

See design spec: [\`2026-04-23-wheels-packages-phase1-extraction-design.md\`](link)"
```

Expected: issue #2243 has a summary comment linking all children.

---

## Final verification

- [ ] **Registry CI green:** `gh run list --repo wheels-dev/wheels-packages --workflow validate.yml --limit 1` → most recent = `success`
- [ ] **All four external repos have v1.0.0 release:** `for r in sentry hotwire basecoat legacy-adapter; do gh release view v1.0.0 --repo wheels-dev/wheels-$r --json name; done`
- [ ] **Monorepo PR merged** to `develop` (code-tier merge per CLAUDE.local.md: full test suite green, no auto-merge)
- [ ] **Five follow-up issues filed** and linked in #2243
- [ ] **Spec + plan both committed** on `develop`

## Unresolved from spec — decisions at execution time

- **Maintainer handle:** plan assumes `@bpamiri`. Change in manifests if user wants `@wheels-dev`.
- **`documentation` URL:** plan leaves `wheels.dev/packages/<name>` populated even though it 404s until Phase 4 ships. Acceptable per spec; noted.
- **CHANGELOG in extracted repos:** plan includes them (Step 3.6). Minimal content; easy to maintain.
