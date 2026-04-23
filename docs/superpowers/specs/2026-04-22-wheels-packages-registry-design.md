# Wheels Packages Registry — Design

**Date:** 2026-04-22
**Status:** Approved strawman — ready for implementation plan
**Relates to:** v4.1 Theme A (packages system production-readiness), audit items P2–P10
**Parent review:** `2026-04-22-v4-ga-architectural-review.md`

---

## Purpose

Wheels 4.0 shipped the in-app `packages/` → `vendor/` activation model. What's missing is a distribution layer: how do third-party package authors publish, how do users discover, and how do we protect consumers from supply-chain attacks?

This spec replaces ForgeBox as the distribution channel with a git-based, curated registry owned by the `wheels-dev` organization.

## Threat model

Three attacks the design must address:

**Attack A — Force-push / tag-rewrite**
Author publishes v1.0.0 with clean bits, later force-pushes the tag to malicious bits. Any user who installs v1.0.0 *after* the rewrite gets malware.

**Attack B — Malicious version bump**
Author publishes v1.0.1 with malicious code. Users running `wheels packages update` auto-pull malware. No cryptographic defense — only human review + restricted auto-update can mitigate.

**Attack C — Upstream URL instability**
GitHub's `/archive/refs/tags/<tag>.tar.gz` URLs regenerate on demand and have historically drifted byte-for-byte. Causes false-positive hash mismatches on clean packages.

**Design responses:**
- Attack A: registry hosts its own tarballs (not author's).
- Attack B: human review on every version-bump PR; CLI does *not* auto-update by default.
- Attack C: never link to source-archive URLs in manifests.

## Architecture

### Registry repo: `wheels-dev/wheels-packages`

```
packages/
  wheels-sentry/
    manifest.json          ← authoritative metadata
    README.md              ← listing blurb, shown on wheels.dev/packages
  wheels-hotwire/
  wheels-seo-suite/
  wheels-basecoat/
  ...
schema/
  manifest.schema.json     ← JSONSchema, CI-enforced
.github/workflows/
  validate.yml             ← runs on every PR
  mirror-tarball.yml       ← packages + uploads release asset on merge
  auto-label.yml
CONTRIBUTING.md            ← how to submit + review guidelines
README.md                  ← registry purpose + install instructions
```

Authority model: the `manifest.json` in the registry repo is **the** source of truth. Author's own repo is the development home; the registry controls what users install.

### manifest.json schema

```json
{
  "name": "wheels-sentry",
  "description": "Sentry error tracking for Wheels apps",
  "homepage": "https://github.com/wheels-dev/wheels-sentry",
  "documentation": "https://wheels.dev/packages/wheels-sentry",
  "license": "MIT",
  "maintainers": ["@bpamiri"],
  "tags": ["monitoring", "errors", "observability"],
  "source": {
    "type": "github",
    "repo": "wheels-dev/wheels-sentry"
  },
  "versions": [
    {
      "version": "1.0.0",
      "publishedAt": "2026-04-22T10:30:00Z",
      "wheelsVersion": ">=4.0",
      "tarball": "https://github.com/wheels-dev/wheels-packages/releases/download/wheels-sentry-1.0.0/wheels-sentry-1.0.0.tar.gz",
      "sha256": "abc123…",
      "sourceTag": "v1.0.0"
    },
    { "version": "1.1.0", "…": "…" }
  ]
}
```

**Required fields:** `name`, `description`, `license`, `source`, `versions[]`.
**Constraint:** `tarball` URL MUST point at a `wheels-dev/wheels-packages` release asset. The registry rejects author-hosted URLs.

### Publishing workflow

1. **Author PR**
   Opens PR adding or updating `packages/<name>/manifest.json` with an entry in `versions[]`: name, version, source.tag, and optionally wheelsVersion. Leaves `tarball` and `sha256` empty — CI fills them.

2. **CI validation (`validate.yml`)**
   - JSON schema check
   - `name` matches directory
   - `name` globally unique across registry
   - Author repo + tag resolvable
   - Clones author repo at that tag into a temp dir
   - Validates: `package.json` present, `name`/`version` match manifest, `wheelsVersion` declared
   - File-type allowlist: `.cfc`, `.cfm`, `.cfml`, `.md`, `.json`, `.js`, `.mjs`, `.ts`, `.css`, `.scss`, `.html`, `.txt`, `.sql`, `.yml`, `.yaml`, `.gitkeep`. Anything else → PR comment asking for justification.
   - Size cap: 10 MB uncompressed per package.
   - Basic smell checks: no dangerous execution primitives in shipped code (shell-out helpers, native-process spawners, or CFML process-invocation tags without an explicit reviewer-approved annotation).

3. **CI packaging (`mirror-tarball.yml`, runs on merge or PR approval)**
   - Re-clones author repo at `source.tag` (clean slate)
   - Produces deterministic tarball: `tar --sort=name --mtime=@0 -czf <name>-<version>.tar.gz <source>/`
   - Creates GH Release on `wheels-dev/wheels-packages` with tag `<name>-<version>`
   - Uploads tarball as release asset
   - Computes sha256
   - Bot commits `tarball` URL + `sha256` back into the manifest

4. **Human review**
   Maintainer glances at diff, confirms author is known or PR is substantive, merges.

5. **Distribution URL (stable forever):**
   `https://github.com/wheels-dev/wheels-packages/releases/download/<name>-<version>/<name>-<version>.tar.gz`

### Install mechanics

1. CLI fetches `https://raw.githubusercontent.com/wheels-dev/wheels-packages/main/packages/<name>/manifest.json`
2. Parses `versions[]`, filters by `wheelsVersion` compatibility (SemVer matcher shared with PackageLoader — implemented in issue #2231)
3. Picks highest matching version (or user-pinned version)
4. Downloads tarball
5. Computes sha256, compares to manifest — on mismatch: **refuse, do not install**
6. Extracts to `vendor/<name>/`
7. Next `wheels reload` picks up the new package via PackageLoader

No git clone. No ssh key. No CommandBox. Pure HTTPS + JSON.

### CLI surface

```
wheels packages list                        # all packages in registry
wheels packages search <query>              # name/description/tag match
wheels packages show <name>                 # details, versions, homepage
wheels packages install <name>              # latest compat version
wheels packages install <name>@<version>    # pin
wheels packages update <name>               # bump to latest compat — requires confirmation
wheels packages update --all                # bump all — requires --yes
wheels packages remove <name>               # rm -rf vendor/<name>
wheels packages registry refresh            # bust 24h manifest cache
wheels packages registry info               # show registry URL, last refresh, cache location
```

**Auto-update policy:** `update` is explicit. No background pulls. No implicit upgrades on `wheels reload`. This is Attack B defense.

### Web UI

`wheels.dev/packages` (on the marketing / docs site) and `/wheels/packages` (in-app, dev/testing only, gated per #2233):

- Reads the same `manifest.json` files the CLI reads
- Lists, searches, shows detail pages
- In-app: "activated" vs "available", with install button (dev only)
- Marketing site: static rebuild on registry merges (GH Action)

One source of truth for CLI + web.

## Versioning policy

Track all versions in `versions[]` (not latest-only). Benefits:

- Offline determinism — any user with a registry clone can resolve any version
- Stable pinning — `wheels packages install foo@1.2.3` always works even if author deletes their repo
- Auditable — registry git history shows every version bump and its reviewer

Cost: manifest grows over time. Target ~50 versions before needing pagination — irrelevant for realistic package lifecycles.

## Implementation phases

| Phase | Scope | Issue |
|---|---|---|
| 1 | Create `wheels-dev/wheels-packages` repo, seed with first-party manifests (sentry/hotwire/basecoat/legacyadapter/wheels-seo-suite), add schema + CI validation | P4.a |
| 2 | Build tarball-mirror CI (clone → package → release asset → sha256 → manifest commit) | P4.b |
| 3 | CLI commands (`wheels packages ...`) | P4.c |
| 4 | Web UI on wheels.dev + `/wheels/packages` in-app | P4.d |
| 5 | Developer guide (CONTRIBUTING + packaging how-to) | P3 |

## Decisions confirmed

| # | Decision | Choice |
|---|---|---|
| 1 | Authority model | Registry manifest authoritative, registry-hosted tarballs |
| 2 | Version history | Full `versions[]` array |
| 3 | Registry name | `wheels-packages` |
| 4 | Auto-update | Explicit only (Attack B defense) |
| 5 | File-type allowlist | Strict; process-invocation tags require review |
| 6 | Size cap | 10 MB uncompressed per package |

## Out of scope for v4.1

- PGP signing of manifests by authors (post-v4.1)
- Dependency resolution between packages (if needed, add in v5.0)
- Private registries for enterprise use (post-v4.1)
- Mirror CDN beyond GH Releases (not needed at current scale)

## Implications for existing audit items

- **P4 (distribution story)**: this spec is the resolution.
- **P1 (`wheelsVersion` validation)**: already shipped as #2231; CLI install reuses the same SemVer matcher.
- **P9 (checksum feature in PackageLoader)**: the per-file `checksums` field in `package.json` is now redundant — sha256 at the distribution layer is stronger and simpler. **Remove the field + code path** in `PackageLoader.cfc:315-342`.
- **P3 (package-creation guide)**: becomes the `CONTRIBUTING.md` on `wheels-packages` + a user-facing page on wheels.dev.
