# Monorepo Reorganization Proposal

## Problem Statement

Cloning the Wheels repository does not produce a runnable application. The monorepo splits the framework across multiple subdirectories (`core/src/wheels/`, `templates/base/src/`, `cli/src/`) that are only assembled into a working app during the CI/CD build process or via Docker Compose volume mounts. This breaks the historical expectation that cloning the repo gives you a working Wheels application.

## Current Structure

```
wheels/
├── cli/                    # CLI source (published as wheels-cli)
│   └── src/
├── core/                   # Framework runtime (published as wheels-core)
│   └── src/wheels/
├── templates/
│   └── base/               # App scaffold (published as wheels-base-template)
│       └── src/
│           ├── app/
│           ├── config/
│           ├── public/     # Contains Application.cfc, index.cfm
│           ├── vendor/     # Empty (.keep only)
│           ├── tests/
│           └── box.json
├── examples/
│   └── starter-app/        # Published as wheels-starter-app
├── tests/                  # Framework test suite
├── tools/
│   ├── build/scripts/      # Build & publish scripts
│   └── docker/             # Docker test environments
├── docs/                   # MkDocs documentation
├── design_docs/
├── compose.yml
└── server.json             # Nearly empty
```

### How it currently works

**Docker (testing):** compose.yml assembles a runnable app through volume mounts:
```yaml
volumes:
  - ./templates/base/src:/wheels-test-suite
  - ./core/src/wheels:/wheels-test-suite/vendor/wheels
  - ./tests:/wheels-test-suite/tests
```

**CI/CD (release):** Build scripts copy files from multiple source directories into four separate build artifacts:
1. `wheels-base-template` — from `templates/base/src/`
2. `wheels-core` — from `core/src/wheels/`
3. `wheels-cli` — from `cli/src/`
4. `wheels-starter-app` — from `examples/starter-app/`

**End user (production):** Installs via `box install wheels-cli` → `wheels new myapp` which downloads the base template and installs wheels-core into `vendor/wheels/`.

### The gap

After `git clone`, a developer must either:
- Use Docker Compose (which assembles the app via volume mounts)
- Manually understand the structure and mentally map across 3+ directories
- Run a build script to produce artifacts

There is no way to simply `box server start` from the repo root and have a working application.

---

## Four Options Analyzed

### Option A: Promote app structure to root ("Flatten")

Move `templates/base/src/` content to the repo root and `core/src/wheels/` into `vendor/wheels/`:

```
wheels/
├── app/                    ← was templates/base/src/app/
│   ├── controllers/
│   ├── models/
│   ├── views/
│   └── ...
├── config/                 ← was templates/base/src/config/
│   ├── app.cfm
│   ├── routes.cfm
│   ├── settings.cfm
│   └── ...
├── public/                 ← was templates/base/src/public/
│   ├── Application.cfc
│   └── index.cfm
├── vendor/
│   └── wheels/             ← was core/src/wheels/
├── db/                     ← was templates/base/src/db/
├── plugins/                ← was templates/base/src/plugins/
├── tests/                  ← merged: framework tests + app tests
├── box.json                ← app-level manifest
├── server.json             ← CommandBox server config
├── .env
│
│  ── Development infrastructure (not part of the app) ──
│
├── cli/                    # CLI source (unchanged)
│   └── src/
├── docs/                   # Documentation (unchanged)
├── tools/
│   ├── build/              # Build scripts (paths updated)
│   └── docker/             # Docker configs (simplified)
├── examples/
│   └── starter-app/
├── design_docs/
├── .github/
├── .ai/
└── compose.yml
```

**What changes:**
- `templates/base/src/*` → moves to repo root
- `core/src/wheels/*` → moves to `vendor/wheels/`
- `templates/base/` directory is removed (build scripts extract from root instead)
- `core/` directory is removed (build scripts extract from `vendor/wheels/` instead)
- `compose.yml` simplified — no more cross-directory volume mounts
- All build scripts updated to reference new paths
- CI/CD workflows updated accordingly
- `tests/` may need restructuring to merge framework tests with app-level tests
- `.gitignore` updated

**Pros:**
- Clone and run: `git clone → box install → box server start`
- Matches historical Wheels repo layout
- Simplest mental model — root IS the application
- Docker compose becomes trivial (just mount root)
- Contributors immediately see the app structure
- Same structure as what end users get after `wheels new`

**Cons:**
- Root is busier (mixes app files with dev infrastructure)
- Build scripts need path adjustments
- Need clear convention to separate "app files" from "monorepo dev files"
- `vendor/wheels/` is now tracked in git (not installed via dependency)
- Large one-time git history disruption

**Impact on build process:**
- `prepare-core.sh`: copies from `vendor/wheels/` instead of `core/src/wheels/`
- `prepare-base.sh`: copies from root `app/`, `config/`, `public/`, etc.
- `prepare-cli.sh`: unchanged (cli/ stays where it is)
- `prepare-starterApp.sh`: unchanged
- `compose.yml`: simplified — just map `.` as the app root

---

### Option B: Symlinks at root

Keep source in subdirectories but create symlinks at root:

```
wheels/
├── app -> templates/base/src/app
├── config -> templates/base/src/config
├── public -> templates/base/src/public
├── vendor/
│   └── wheels -> ../../core/src/wheels
├── core/                   # Actual source
├── templates/              # Actual source
├── cli/
└── ...
```

**Pros:**
- Minimal file movement
- Source stays organized in logical directories
- Clone and run (on systems that support symlinks)

**Cons:**
- **Windows support is poor** — Git symlinks require `core.symlinks=true` and elevated permissions on Windows, which is a deal-breaker for many CFML developers
- Confusing for newcomers (symlinks aren't obvious)
- Some CFML engines may not follow symlinks correctly
- Docker may need additional configuration for symlinks
- **Not recommended** due to cross-platform issues

---

### Option C: Setup script / bootstrap

Keep current structure, add a one-time setup script:

```bash
#!/bin/bash
# setup.sh — Assemble runnable app from monorepo components
mkdir -p vendor
ln -sf ../core/src/wheels vendor/wheels  # or cp -r
echo "App assembled. Run: box server start --directory=templates/base/src"
```

Or modify the root `box.json` so `box install` creates the right structure automatically.

**Pros:**
- No structural changes needed
- Build scripts untouched

**Cons:**
- Extra step after clone ("run this script first")
- Still doesn't produce a root-level runnable app
- Users forget to run setup scripts
- Symlink-based version has the same Windows issues as Option B
- Copy-based version means edits in vendor/ don't reflect in core/src/

---

### Option D: Hybrid — promote app to root, keep core as named source directory

```
wheels/
├── app/                    ← from templates/base/src/app/
├── config/                 ← from templates/base/src/config/
├── public/                 ← from templates/base/src/public/
├── vendor/
│   └── wheels/             ← from core/src/wheels/
├── db/
├── plugins/
├── tests/
├── box.json
├── server.json
│
├── _src/                   # Dev-only source directories
│   ├── cli/                # CLI source
│   ├── docs/               # Documentation
│   └── docker/             # Docker environments
├── _build/                 # Build tooling
│   └── scripts/
├── examples/
├── design_docs/
├── .github/
└── compose.yml
```

**Pros:**
- Clone and run
- Underscore-prefixed directories make dev infrastructure visually distinct
- Still separates build/dev tooling from app code

**Cons:**
- Unconventional underscore naming
- CLI source path changes (from `cli/` to `_src/cli/`)
- Essentially the same as Option A with a different folder naming convention
- Adds indirection without much benefit over Option A

---

## Recommendation: Option A (Flatten)

Option A is the strongest choice for these reasons:

1. **It matches what users expect.** Historically and currently, the end result of `wheels new` is exactly this structure. The repo should look like what it produces.

2. **Clone-and-run.** `git clone` → `box server start` works immediately (with an H2 embedded database, no external DB needed).

3. **Docker simplification.** The compose.yml volume mounts go from 3 cross-directory binds to a single root mount.

4. **Build script changes are mechanical.** Every path change is a straightforward find-and-replace in shell scripts.

5. **It's how Docker already assembles the app.** The compose.yml volume mounts already demonstrate the "flattened" layout — we're just making it the default state.

6. **The "dev infrastructure" concern is manageable.** The root directory will have `cli/`, `docs/`, `tools/`, `examples/`, `design_docs/` alongside the app directories. This is the same pattern used by many frameworks (Rails has `railties/` alongside `app/`; Laravel has tooling alongside the framework). A `.gitattributes` `export-ignore` can exclude dev directories from release archives.

### What stays the same
- `cli/` directory (unchanged path and structure)
- `examples/` directory (unchanged)
- `docs/` directory (unchanged)
- `tools/` directory (unchanged, just paths in scripts updated)
- `.github/` workflows (paths updated)
- `design_docs/` (unchanged)
- `.ai/` and `.claude/` (unchanged)

### What moves
| From | To |
|------|-----|
| `templates/base/src/app/` | `app/` |
| `templates/base/src/config/` | `config/` |
| `templates/base/src/public/` | `public/` |
| `templates/base/src/db/` | `db/` |
| `templates/base/src/plugins/` | `plugins/` |
| `templates/base/src/tests/` | `tests/app/` (app-level tests) |
| `templates/base/src/box.json` | `box.json` (becomes root manifest) |
| `templates/base/src/server.json` | `server.json` (becomes root server config) |
| `templates/base/src/.env` | `.env` (already at root) |
| `templates/base/src/AGENTS.md` | stays at root (already exists) |
| `core/src/wheels/` | `vendor/wheels/` |
| `tests/` (framework) | `tests/` (merge with app tests) |

### What gets deleted
| Directory | Reason |
|-----------|--------|
| `templates/base/` | Content promoted to root |
| `core/` | Content moved to `vendor/wheels/` |
| `templates/` | Empty after base/ removal (unless other templates exist) |

### Files that need path updates
1. `tools/build/scripts/prepare-base.sh` — copy from root instead of `templates/base/src/`
2. `tools/build/scripts/prepare-core.sh` — copy from `vendor/wheels/` instead of `core/src/wheels/`
3. `tools/build/scripts/build-base.sh` — same path updates
4. `tools/build/scripts/build-core.sh` — same path updates
5. `compose.yml` — simplify volume mounts
6. `.github/workflows/release.yml` — version source from root `box.json`
7. `.github/workflows/tests.yml` — path updates
8. `.github/workflows/release-candidate.yml` — path updates
9. `.github/workflows/snapshot.yml` — path updates
10. `.gitignore` — add `vendor/` exclusion rules (only track `vendor/wheels/`)
11. `MONOREPO.md` — update all documentation
12. `CLAUDE.md` — update directory references
13. `AGENTS.md` — update directory references

### Test directory strategy

Currently there are two test directories:
- `tests/` (root) — framework test suite (specs that test the core)
- `templates/base/src/tests/` — app-level test scaffolding

After flattening:
```
tests/
├── specs/          ← from current tests/specs/ (framework tests)
├── _assets/        ← from current tests/_assets/
├── models/         ← from templates/base/src/tests/models/
├── controllers/    ← from templates/base/src/tests/controllers/
└── runner.cfm
```

### server.json update

The root `server.json` should be updated to point to `public/` as the web root:
```json
{
    "app": {
        "cfengine": "lucee@5"
    },
    "web": {
        "webroot": "public",
        "rewrites": {
            "enable": true
        }
    }
}
```

---

## Migration Plan

### Phase 1: Move files (single atomic commit)
1. Move `templates/base/src/app/` → `app/`
2. Move `templates/base/src/config/` → `config/`
3. Move `templates/base/src/public/` → `public/`
4. Move `templates/base/src/db/` → `db/`
5. Move `templates/base/src/plugins/` → `plugins/`
6. Move `core/src/wheels/` → `vendor/wheels/`
7. Merge test directories
8. Update root `box.json` and `server.json`
9. Remove empty `templates/base/` and `core/` directories

### Phase 2: Update build tooling
1. Update all `prepare-*.sh` scripts
2. Update all `build-*.sh` scripts
3. Update `publish-to-forgebox.sh` if needed

### Phase 3: Update CI/CD
1. Update `compose.yml`
2. Update all GitHub Actions workflows
3. Update Docker build contexts

### Phase 4: Update documentation
1. Update `MONOREPO.md`
2. Update `CLAUDE.md` and `AGENTS.md`
3. Update `README.md`
4. Update `CONTRIBUTING.md`
5. Update any `.ai/` references

### Phase 5: Validation
1. Verify `box server start` works from repo root
2. Verify Docker compose still works
3. Verify build scripts produce correct artifacts
4. Verify CI test matrix passes
5. Verify ForgeBox publish produces correct packages

---

## Risk Assessment

| Risk | Mitigation |
|------|-----------|
| Git history disruption | Use `git mv` to preserve file history |
| Broken CI | Update all workflow files in same PR |
| Contributors confused | Clear PR description, updated docs |
| Build script breakage | Test scripts locally before merge |
| `vendor/wheels/` tracked in git | Add `.gitattributes` to mark it as framework source, not a dependency |
| Existing forks/PRs broken | Coordinate timing, announce in advance |

## Open Questions — Resolved

Resolved based on cross-framework research (Laravel, Rails, Django, Symfony, Next.js, Nuxt, ColdBox).

### 1. Should `vendor/wheels/` be the actual directory name?

**Decision: Yes — use `vendor/wheels/`.** This matches the convention users see in their apps after `wheels new`. Every major framework keeps runtime dependencies in a vendored location (`vendor/` in PHP, `node_modules/` in JS, `lib/` in Ruby). The fact that the source is first-party is already documented and understood — ColdBox uses a similar pattern with `system/` containing its own source. A `.gitattributes` annotation clarifies the intent.

### 2. Test directory merge strategy

**Decision: Keep framework tests in `tests/` at root; app scaffold tests stay as a minimal placeholder.** This matches the Django/ColdBox/Next.js pattern — a single top-level `tests/` for framework tests. The app scaffold's `tests/` subdirectory (from `templates/base/src/tests/`) contains only a `runner.cfm` placeholder, not real tests, so it merges cleanly. The core framework already has its own internal tests at `vendor/wheels/tests/` (co-located, like Rails/Symfony). Structure after merge:

```
tests/
├── specs/          ← framework functional tests (current tests/specs/)
├── _assets/        ← test fixtures (current tests/_assets/)
├── runner.cfm      ← test runner
├── routes.cfm
└── populate.cfm
```

### 3. Should the starter-app example remain separate?

**Decision: Yes — keep `examples/` at root.** It serves a different purpose (a pre-built demo app) than the base template (an empty scaffold). No major framework merges its example apps with its scaffold. It stays at `examples/starter-app/`.

### 4. Timing

**Decision: Land on the development branch now.** The reorganization is structural, not functional — no framework code changes. It should be validated before 3.0 stable so the stable release ships with the clean structure.

### 5. Ancillary directory organization (new — from research)

**Decision: Keep `cli/`, `docs/`, `tools/`, `examples/`, `design_docs/` flat at root.** Research across 8 major frameworks confirmed that no framework groups dev infrastructure into a single umbrella directory. Flat, descriptive root-level directories are the universal standard. The `_src/` and `_build/` patterns from Option D are unconventional and provide no real benefit over Option A.

---

## Research Summary

Cross-framework analysis of monorepo layouts (Laravel, Rails, Django, Symfony, Next.js, Nuxt, ColdBox, CFWheels current):

- **Test separation**: Django/ColdBox/Next.js use top-level `tests/`; Rails/Symfony co-locate tests per sub-package. Both work — we use the top-level pattern since Wheels is a single-package framework.
- **Ancillary directories**: Every framework puts `docs/`, `tools/`, `scripts/`, `examples/` at root. No framework uses `_dev/`, `internal/`, or other umbrella groupings.
- **ColdBox precedent**: The closest CFML framework uses `system/` (framework core), `test-harness/` (test app), `build/` (scripts), `tests/` (test suite) — all flat at root. Our approach matches this.
- **The `packages/` pattern** (Next.js, Nuxt) is for multi-package monorepos publishing independent npm packages. Not applicable to Wheels' single-core-package model.
