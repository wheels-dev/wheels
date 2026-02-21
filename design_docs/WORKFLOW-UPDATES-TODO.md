# GitHub Actions Workflow Updates for Flattened Monorepo

The monorepo reorganization (commit `268d575`) moved `templates/base/src/` to the repo root and `core/src/wheels/` to `vendor/wheels/`. Five GitHub Actions workflow files still reference the old paths and need updating.

These could not be pushed in the original session because the GitHub App token lacked `workflows` permission.

## Changes Needed

### 1. `.github/workflows/release.yml` (line 38)

Remove the `cd` and `pwd` lines — `box.json` is now at root:

```diff
      - name: Setup Environment Variables For Build Process
        id: Calculate-Version-And-Branch
        run: |
-          cd ./templates/base/src
-          pwd
           cat box.json
           echo "WHEELS_VERSION=`cat box.json | jq '.version' -r`+${{ github.run_number }}" >> $GITHUB_ENV
```

### 2. `.github/workflows/release-candidate.yml` (line 32)

Same fix — remove `cd` and `pwd`:

```diff
      - name: Setup Environment Variables For Build Process
        id: Calculate-Version-And-Branch
        run: |
-          cd ./templates/base/src
-          pwd
           cat box.json

           # Extract version from box.json (should be something like 3.0.0-rc.1)
           VERSION=$(cat box.json | jq '.version' -r)
```

### 3. `.github/workflows/tests.yml` (lines 140-145)

Oracle JDBC download path — `templates/base/src/` prefix removed:

```diff
      - name: Download jdbc10
        run: |
-          mkdir -p ./templates/base/src/.engine/${{ matrix.cfengine }}/WEB-INF/lib
-
-          wget https://download.oracle.com/otn-pub/otn_software/jdbc/1927/ojdbc10.jar \
-            -O ./templates/base/src/.engine/${{ matrix.cfengine }}/WEB-INF/lib/ojdbc10.jar
-
-          ls -l ./templates/base/src/.engine/${{ matrix.cfengine }}/WEB-INF/lib/
+          mkdir -p ./.engine/${{ matrix.cfengine }}/WEB-INF/lib
+
+          wget https://download.oracle.com/otn-pub/otn_software/jdbc/1927/ojdbc10.jar \
+            -O ./.engine/${{ matrix.cfengine }}/WEB-INF/lib/ojdbc10.jar
+
+          ls -l ./.engine/${{ matrix.cfengine }}/WEB-INF/lib/
```

### 4. `.github/workflows/generate-changelog.yml` (line 90)

Version detection reads from root `box.json`:

```diff
-          VERSION=$(jq -r '.version' templates/base/src/box.json)
+          VERSION=$(jq -r '.version' box.json)
```

### 5. `.github/workflows/version-bump.yml` (lines 52-55, 77, 98)

Three separate changes in this file:

**Line 52-55** — version bump target:
```diff
-          # Update templates/base/src/box.json
+          # Update root box.json
           jq --arg version "$NEW_VERSION" '.version = $version | .dependencies."wheels-core" = ("^" + $version)' \
-            templates/base/src/box.json > templates/base/src/box.json.tmp
-          mv templates/base/src/box.json.tmp templates/base/src/box.json
+            box.json > box.json.tmp
+          mv box.json.tmp box.json
```

**Line 77** — git add:
```diff
-          git add templates/base/src/box.json
+          git add box.json
```

**Line 98** — summary output:
```diff
-          echo "- templates/base/src/box.json" >> $GITHUB_STEP_SUMMARY
+          echo "- box.json" >> $GITHUB_STEP_SUMMARY
```

## Commit Message

```
ci: update GitHub Actions workflow paths for flattened monorepo

Updates version detection and JDBC download paths in all workflows
to match the new flattened directory structure:
- Version read from root box.json instead of templates/base/src/box.json
- Oracle JDBC downloaded to .engine/ instead of templates/base/src/.engine/
- Removed cd into deleted templates/base/src/ directory
```

## Branch

All changes go on: `claude/reorganize-monorepo-structure-qNFcv`
