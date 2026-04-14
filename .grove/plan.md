# W-007: LuCLI Module Distribution Plan

## Decision

**Subdirectory install from the monorepo is not supported by LuCLI.** LuCLI's `ModuleCommand.java` (lines 821-825) validates that `module.json` and `Module.cfc` exist at the **repository root** after cloning. There is no `--subdir` parameter. The Wheels module lives at `cli/lucli/` in the monorepo — not at root.

**Primary distribution path: `wheels-dev/wheels-cli-lucli`** — a dedicated distribution repo auto-synced from the monorepo via GitHub Actions.

### Correct Install Commands

```bash
# Named install (after LuCLI registry PR is merged)
lucli modules install wheels

# Explicit URL install (works immediately once repo exists)
lucli modules install wheels --url https://github.com/wheels-dev/wheels-cli-lucli

# Specific version
lucli modules install wheels --url https://github.com/wheels-dev/wheels-cli-lucli#v3.1.0
```

**The command in issue #1947 is wrong:**
```bash
# WRONG — module.json is not at monorepo root
lucli modules install wheels --url https://github.com/wheels-dev/wheels
```

---

## Phase 1: Create Distribution Repo

**Status:** `wheels-dev/wheels-cli-lucli` does not exist yet (verified via `gh repo view`).

### Steps

1. Create `wheels-dev/wheels-cli-lucli` as a public repo via `gh repo create`
   - Description: "Wheels CLI module for LuCLI — auto-synced from wheels-dev/wheels"
   - No template, empty initial state
   - Public visibility (LuCLI needs unauthenticated clone access)

2. Seed initial content by running the sync logic locally:
   - Copy `cli/lucli/*` → repo root (excluding `PLAN.md`)
   - Copy `cli/src/templates/` → `templates/codegen/`
   - Add a `README.md` explaining this is auto-synced and PRs should go to the monorepo

3. Push initial commit and tag `v3.1.0`

4. Verify install works:
   ```bash
   lucli modules install wheels --url https://github.com/wheels-dev/wheels-cli-lucli
   ```

### Files Created (in distribution repo)
```
wheels-cli-lucli/
  Module.cfc          # from cli/lucli/Module.cfc
  module.json         # from cli/lucli/module.json
  services/           # from cli/lucli/services/
  templates/
    app/              # from cli/lucli/templates/app/
    codegen/          # from cli/src/templates/
  README.md           # new: explains auto-sync, points PRs to monorepo
```

---

## Phase 2: Fix Sync Workflow

**Problem:** `.github/workflows/sync-lucli-module.yml` uses `continue-on-error: true` at the job level. If the PAT expires or the distribution repo is deleted, syncs fail silently with no notification. The distribution repo goes stale indefinitely.

### Changes to `.github/workflows/sync-lucli-module.yml`

1. **Remove `continue-on-error: true`** from the job level
2. **Add Slack notification on failure** using the existing `SLACK_WEBHOOK_URL` org secret (posts to #it_builds)
3. Keep the workflow non-blocking for the main CI pipeline (it's a separate workflow, not part of `tests.yml`)

```yaml
jobs:
  sync:
    runs-on: ubuntu-latest
    # REMOVED: continue-on-error: true
    steps:
      # ... existing steps ...

      - name: Notify on failure
        if: failure()
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
        run: |
          curl -s -X POST "$SLACK_WEBHOOK_URL" \
            -H 'Content-Type: application/json' \
            -d "{\"text\": \":warning: LuCLI module sync failed for wheels@${GITHUB_SHA:0:7}. Check: $GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID\"}"
```

### Files Modified
- `.github/workflows/sync-lucli-module.yml`

---

## Phase 3: LuCLI Registry Entry

**Problem:** `lucli modules install wheels` (no `--url`) fails because the `wheels` module is not in LuCLI's bundled registry (`src/main/resources/repository/local.json`).

### Steps

1. Create a PR to `bpamiri/LuCLI` (local clone at `~/GitHub/bpamiri/LuCLI`)
2. Add entry to `src/main/resources/repository/local.json`:

```json
{
  "name": "wheels",
  "description": "Code generation, migrations, testing, and server management for CFWheels",
  "url": "https://github.com/wheels-dev/wheels-cli-lucli.git"
}
```

3. This enables the named install: `lucli modules install wheels`

### Files Modified (in LuCLI repo)
- `src/main/resources/repository/local.json`

---

## Phase 4: Update PLAN.md — Correct Homebrew Formula

**Problem:** `cli/lucli/PLAN.md` Phase 3A shows the Homebrew formula installing from monorepo archive. This will fail because the archive contains the full monorepo — `module.json` is at `cli/lucli/module.json`, not at root.

### Corrected Formula (for `wheels-dev/homebrew-wheels`)

```ruby
depends_on "lucli"  # was: depends_on "commandbox"

# post_install: install wheels module from distribution repo
system bin/"lucli", "modules", "install", "wheels",
       "--url", "https://github.com/wheels-dev/wheels-cli-lucli"
```

### Changes to `cli/lucli/PLAN.md`
- Phase 3A: Replace monorepo archive URL with distribution repo URL
- Phase 3C: Remove "verify subdirectory install" — explicitly state it's not supported
- Update install command examples throughout

### Files Modified
- `cli/lucli/PLAN.md`

---

## Phase 5: Integration Test

**Purpose:** Verify the full install pipeline: fresh install → template resolution → successful `wheels generate model` in a test project.

### Test Script: `cli/lucli/tests/test-module-install.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

# Test: LuCLI module install and basic generator functionality
#
# Prerequisites:
#   - lucli binary on PATH
#   - git available
#   - Network access to github.com

DIST_REPO="${1:-https://github.com/wheels-dev/wheels-cli-lucli}"
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "=== Phase 1: Install module from distribution repo ==="
lucli modules install wheels --url "$DIST_REPO" --force
lucli modules list | grep -q "wheels" || { echo "FAIL: wheels module not found"; exit 1; }

echo "=== Phase 2: Verify module.json integrity ==="
MODULE_DIR="$HOME/.lucli/modules/wheels"
[ -f "$MODULE_DIR/module.json" ] || { echo "FAIL: module.json missing"; exit 1; }
[ -f "$MODULE_DIR/Module.cfc" ] || { echo "FAIL: Module.cfc missing"; exit 1; }

echo "=== Phase 3: Scaffold a test project ==="
cd "$TMPDIR"
lucli wheels new testapp || { echo "FAIL: wheels new failed"; exit 1; }
cd testapp

echo "=== Phase 4: Generate a model ==="
lucli wheels generate model User firstName lastName email || {
  echo "FAIL: generate model failed"; exit 1;
}
[ -f "app/models/User.cfc" ] || { echo "FAIL: User.cfc not created"; exit 1; }

echo "=== Phase 5: Generate a controller ==="
lucli wheels generate controller Users index show new create edit update delete || {
  echo "FAIL: generate controller failed"; exit 1;
}
[ -f "app/controllers/Users.cfc" ] || { echo "FAIL: Users.cfc not created"; exit 1; }

echo ""
echo "ALL TESTS PASSED"
```

### Files Created
- `cli/lucli/tests/test-module-install.sh`

---

## Phase 6: Update GitHub Issue #1947

Add a comment to issue #1947 correcting the install command:

> The monorepo URL (`wheels-dev/wheels`) won't work because LuCLI requires `module.json` at the repository root. The module lives at `cli/lucli/` in the monorepo.
>
> Correct install command (via distribution repo):
> ```bash
> lucli modules install wheels --url https://github.com/wheels-dev/wheels-cli-lucli
> ```
>
> Once the LuCLI registry PR is merged:
> ```bash
> lucli modules install wheels
> ```

---

## Implementation Order

| # | Task | Depends On | Deliverable |
|---|------|------------|-------------|
| 1 | Create `wheels-dev/wheels-cli-lucli` repo | — | Public GitHub repo with module files |
| 2 | Fix sync workflow (remove silent failures) | — | Updated `.github/workflows/sync-lucli-module.yml` |
| 3 | Update PLAN.md (correct formulas + commands) | — | Updated `cli/lucli/PLAN.md` |
| 4 | Add integration test script | — | `cli/lucli/tests/test-module-install.sh` |
| 5 | Seed distribution repo with initial content | 1 | Initial commit + `v3.1.0` tag |
| 6 | Run integration test | 5 | Verified install pipeline |
| 7 | PR to LuCLI adding registry entry | 1 | PR on `bpamiri/LuCLI` |
| 8 | Comment on issue #1947 | 1 | Corrected install instructions |

---

## Backwards Compatibility

- **CommandBox CLI**: Unaffected. `box install wheels-cli` continues to work. The LuCLI module is additive.
- **Existing users**: No breaking changes. This creates a new install path, doesn't remove the old one.
- **Homebrew formula**: The formula update (Phase 4, in `wheels-dev/homebrew-wheels`) will be a separate PR. Current formula still works with CommandBox.

## Edge Cases

- **PAT expiration**: After Phase 2, the sync workflow will fail loudly (Slack notification) instead of silently.
- **Distribution repo deletion**: Same — sync fails, Slack notification fires.
- **LuCLI not installed**: `lucli modules install` requires LuCLI. Users without it use CommandBox. Both paths documented.
- **Offline/air-gapped**: Module install requires network. No offline fallback planned (consistent with all LuCLI modules).
- **Version drift**: The sync workflow runs on every push to `develop` that touches `cli/lucli/**` or `cli/src/templates/**`. Version is read from `module.json` and auto-tagged. Drift only occurs if the workflow breaks — which Phase 2 now makes visible.

## Unresolved Questions

1. Should the distribution repo's default branch be `main` or `develop`? (LuCLI clones default branch when no `--ref` given)
2. Does the `WHEELS_DEV_PAT` secret already exist at the org level, or does it need to be created for the sync workflow?
3. Should we update the Homebrew formula in this task or defer to a separate PR? (The formula lives in `wheels-dev/homebrew-wheels`, a different repo)
