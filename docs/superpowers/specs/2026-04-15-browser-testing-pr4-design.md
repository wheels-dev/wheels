# Browser Testing PR 4: CI Workflow + Reference Docs

## Context

PRs 1-3 (#2113, #2115, #2116) shipped the full browser testing stack:
- BrowserLauncher/BrowserClient/BrowserTest CFCs
- ~60 DSL methods (nav, interaction, keyboard, waiting, scoping, cookies, auth, dialogs, viewport, routes)
- CLI commands (wheels browser:install, wheels browser:test)
- Fixture route mounting under /_browser/
- 3045+ tests pass, 0 fail

Browser specs skip gracefully when Playwright JARs are missing (`browserTestSkipped` flag). PR 4 makes them actually run in CI by installing JARs + Chromium, and promotes the reference docs to final state.

## Decisions

- **Same job vs separate job:** Browser steps go into the existing `fast-test` job in both `pr.yml` and `snapshot.yml`. No separate job — avoids duplicating JDK/LuCLI/SQLite/Lucee setup.
- **Caching strategy:** Single `actions/cache@v4` entry keyed on `browser-manifest.json` hash. JARs and Chromium version are always coupled through the manifest, so they invalidate together.
- **Full matrix (tests.yml):** Not changed. Docker-based engines don't have JDK 21 readily available, and dialog tests are Lucee-only. Future work.

## 1. CI Workflow Changes

### Target files
- `.github/workflows/pr.yml` — fast-test job
- `.github/workflows/snapshot.yml` — fast-test job

### New steps (inserted between "Create test databases" and "Download SQLite JDBC driver")

#### Step: Cache Playwright
```yaml
- name: Cache Playwright
  id: playwright-cache
  uses: actions/cache@v4
  with:
    path: |
      ~/.wheels/browser/lib
      ~/.cache/ms-playwright
    key: playwright-${{ hashFiles('vendor/wheels/browser-manifest.json') }}
    restore-keys: |
      playwright-
```

#### Step: Install Playwright
```yaml
- name: Install Playwright
  if: steps.playwright-cache.outputs.cache-hit != 'true'
  run: |
    mkdir -p ~/.wheels/browser/lib
    
    # Download JARs from manifest
    for row in $(jq -c '.classpath[]' vendor/wheels/browser-manifest.json); do
      URL=$(echo "$row" | jq -r '.url')
      FILE=$(echo "$row" | jq -r '.filename')
      SHA=$(echo "$row" | jq -r '.sha256')
      
      echo "Downloading ${FILE}..."
      curl -sL "$URL" -o ~/.wheels/browser/lib/"$FILE"
      
      ACTUAL=$(sha256sum ~/.wheels/browser/lib/"$FILE" | cut -d' ' -f1)
      if [ "$ACTUAL" != "$SHA" ]; then
        echo "::error::SHA-256 mismatch for ${FILE}: expected ${SHA}, got ${ACTUAL}"
        exit 1
      fi
    done
    
    # Build classpath
    CP=$(ls ~/.wheels/browser/lib/*.jar | tr '\n' ':')
    
    # Install Chromium binary
    java -cp "$CP" com.microsoft.playwright.CLI install --with-deps chromium
```

`install --with-deps` installs both the browser binary AND system dependencies (libglib, libnss, etc.) that Chromium needs on Ubuntu. This replaces the need for a separate `npx playwright install-deps` step.

Note: `jq` and `sha256sum` are pre-installed on GitHub Actions `ubuntu-latest` runners.

#### Step: Set browser env var
Add `WHEELS_BROWSER_TEST_BASE_URL` to the job-level `env` block:
```yaml
env:
  WHEELS_CI: "true"
  WHEELS_BROWSER_TEST_BASE_URL: "http://localhost:60007"
```

No changes to `run-tests.sh` needed — the browser specs are already part of the normal test suite and pick up this env var from BrowserTest.cfc.

### Cache sizing
- JARs: ~200MB (driver-bundle is 191MB)
- Chromium: ~170MB under `~/.cache/ms-playwright/`
- Total: ~370MB (GitHub allows 10GB per repo)
- First run: ~2-3 min for downloads
- Cached runs: ~10s (cache restore only)

### Failure modes
- **Cache miss + Maven Central down:** JAR download fails → step fails → job fails. Acceptable — transient infra issue.
- **SHA mismatch:** Download corruption → step fails explicitly with error message.
- **Chromium install fails:** `playwright CLI install` returns non-zero → step fails. System deps may be missing on non-Ubuntu runners.
- **Browser specs fail:** Same as any other test failure — reported in test results, job fails.

## 2. Reference Docs Updates

### browser-testing.md
- Remove "Status (v4.0 PR 1 of 4 — foundation)" section → replace with "Status: Complete (v4.0)"
- Update "Deferred functionality" table → all items shipped, remove or mark as delivered
- Update "PR roadmap" → mark all 4 PRs complete with PR numbers
- Add to "Implemented DSL methods":
  - Auth: `loginAs(identifier)`, `logout()`
  - Dialogs: `acceptDialog(text?)`, `dismissDialog()`, `dialogMessage()`
  - Routes: `visitRoute(name, params)`, `assertRouteIs(name, params)`
- Add to "Gotchas":
  - Fat arrow syntax in TestBox suites (closure semantics differ from function expressions in some CFML edge cases)
  - `createDynamicProxy` pattern for Lucee-only dialog handling
  - `cfexecute` overload ambiguity with Playwright setters
  - Fixture routes must be mounted before `.wildcard()` in routes.cfm
- Update "CI / skip logic" section to reflect that CI now installs Playwright

### CLAUDE.md browser testing section
- Remove "Deferred to PR 4" bullet under "Key gotchas"
- Ensure "Implemented DSL methods" list includes all PR 3 additions
- Update the "Deferred to follow-up PRs" text → remove entirely or replace with note that browser testing is complete

## 3. Scope exclusions

- `tests.yml` (Docker matrix) — no browser support added
- No new CFC files — all runtime code shipped in PRs 1-3
- No changes to BrowserTest.cfc, BrowserClient.cfc, BrowserLauncher.cfc
- No changes to `run-tests.sh` — browser specs are already discovered by the test runner
- `tools/install-playwright.sh` — already deprecated in PR 2, no changes
