# Browser Testing PR 4: CI Workflow + Reference Docs — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make browser tests actually run in CI (pr.yml + snapshot.yml) and finalize all reference documentation.

**Architecture:** Add Playwright JAR download + Chromium install steps to the existing fast-test job in both CI workflows. Cache ~370MB of artifacts keyed on browser-manifest.json hash. Update browser-testing.md and CLAUDE.md to reflect all PRs 1-3 as shipped.

**Tech Stack:** GitHub Actions (actions/cache@v4), shell (jq, sha256sum, curl), Playwright Java CLI, Markdown

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `.github/workflows/pr.yml` | Add cache + install steps, env var |
| Modify | `.github/workflows/snapshot.yml` | Same changes as pr.yml |
| Modify | `.ai/wheels/testing/browser-testing.md` | Promote from draft to final — status, DSL, gotchas, roadmap |
| Modify | `CLAUDE.md` | Remove "Deferred to PR 4", update intro text, add gotchas |

---

### Task 1: Add Playwright cache + install to pr.yml

**Files:**
- Modify: `.github/workflows/pr.yml:43-68` (fast-test job env block + steps)

- [ ] **Step 1: Add env var to fast-test job**

In `.github/workflows/pr.yml`, add `WHEELS_BROWSER_TEST_BASE_URL` to the job-level `env` block (line 48):

```yaml
    env:
      FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true
      LUCLI_VERSION: "0.3.3"
      WHEELS_CI: "true"
      WHEELS_BROWSER_TEST_BASE_URL: "http://localhost:60007"
```

- [ ] **Step 2: Add cache step**

Insert this step after "Create test databases" (after line 71) and before "Download SQLite JDBC driver":

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

- [ ] **Step 3: Add install step**

Insert this step immediately after "Cache Playwright":

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

          # Build classpath and install Chromium + system deps
          CP=$(ls ~/.wheels/browser/lib/*.jar | tr '\n' ':')
          java -cp "$CP" com.microsoft.playwright.CLI install --with-deps chromium
```

- [ ] **Step 4: Validate YAML syntax**

Run:
```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/pr.yml'))" && echo "YAML OK"
```
Expected: `YAML OK`

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/pr.yml
git commit -m "ci(test): add Playwright cache + install to PR fast-test job"
```

---

### Task 2: Add Playwright cache + install to snapshot.yml

**Files:**
- Modify: `.github/workflows/snapshot.yml:18-106` (fast-test job)

- [ ] **Step 1: Add env var to fast-test job**

In `.github/workflows/snapshot.yml`, add `WHEELS_BROWSER_TEST_BASE_URL` to the job-level env block (around line 25):

```yaml
    env:
      WHEELS_CI: "true"
      WHEELS_BROWSER_TEST_BASE_URL: "http://localhost:60007"
```

- [ ] **Step 2: Add cache step**

Insert after "Create test databases" (after line 47) and before "Download SQLite JDBC driver":

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

- [ ] **Step 3: Add install step**

Insert immediately after "Cache Playwright":

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

          # Build classpath and install Chromium + system deps
          CP=$(ls ~/.wheels/browser/lib/*.jar | tr '\n' ':')
          java -cp "$CP" com.microsoft.playwright.CLI install --with-deps chromium
```

- [ ] **Step 4: Validate YAML syntax**

Run:
```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/snapshot.yml'))" && echo "YAML OK"
```
Expected: `YAML OK`

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/snapshot.yml
git commit -m "ci(test): add Playwright cache + install to snapshot fast-test job"
```

---

### Task 3: Update browser-testing.md — status, DSL, and roadmap

**Files:**
- Modify: `.ai/wheels/testing/browser-testing.md`

- [ ] **Step 1: Replace the "Status" section**

Replace lines 5-8 (the old status block):

```
## Status (v4.0 PR 1 of 4 — foundation)

This PR lands the plumbing. CLI, dogfood specs, and CI matrix integration come in PRs 2-4.

**What works:** navigation, interaction, keyboard, waiting (default timeout), scoping, viewport, script evaluation, most assertions, most terminals, lifecycle via `browserDescribe`.

**What's deferred:** `loginAs`/`logout` (needs test-only route + fixture server), dialogs (needs `createDynamicProxy`), `visitRoute`/`assertRouteIs` (needs `urlFor` outside controller), fixture app integration.
```

With:

```
## Status: Complete (v4.0)

Shipped across four PRs (#2113, #2115, #2116, and the CI/docs PR). Full DSL, CLI commands, CI integration, and fixture route support.
```

- [ ] **Step 2: Update the "Navigation" section under "Implemented DSL methods"**

Replace lines 81-97 (Navigation subsection):

```markdown
### Navigation

```cfm
this.browser
    .visit("/login")                  // baseUrl + path; requires leading slash
    .visitUrl("data:text/html,<h1/>") // absolute URL; any scheme
    .back()
    .forward()
    .refresh();

this.browser.currentUrl();  // terminal → string
```

`visitRoute(name, params)` is **deferred** (depends on Wheels `urlFor()` framework context, which isn't available outside a controller).
```

With:

````markdown
### Navigation

```cfm
this.browser
    .visit("/login")                  // baseUrl + path; requires leading slash
    .visitUrl("data:text/html,<h1/>") // absolute URL; any scheme
    .visitRoute("user", {key: 42})    // uses Wheels urlFor() via application.wo
    .back()
    .forward()
    .refresh();

this.browser.currentUrl();  // terminal → string
```
````

- [ ] **Step 3: Add Auth section after Cookies**

Insert after the Cookies section (after line 207, after "Cookies require a real HTTP origin"):

````markdown
### Auth

```cfm
// loginAs sends POST to /_browser/login-as with the given identifier
this.browser.loginAs("admin");        // sets session via fixture route
this.browser.logout();                // sends POST to /_browser/logout
```

Requires fixture routes mounted in `config/routes.cfm` (added automatically by the framework in test mode). The `/_browser/login-as` route accepts a `POST` with `identifier` param and sets `session.currentUser`. The `/_browser/logout` route clears the session.
````

- [ ] **Step 4: Add Dialogs section after Auth**

Insert after the Auth section:

````markdown
### Dialogs (Lucee-only)

```cfm
// Must be called BEFORE the action that triggers the dialog
this.browser.acceptDialog();                  // accept next alert/confirm/prompt
this.browser.acceptDialog("prompt answer");   // accept with text for prompt
this.browser.dismissDialog();                 // dismiss/cancel next dialog

// Read the dialog message (call after dialog was handled)
var msg = this.browser.dialogMessage();       // terminal → string
```

Dialog handling uses `createDynamicProxy` to implement Playwright's `Consumer<Dialog>` Java interface. This is a Lucee-only feature — on other engines, dialog methods throw `Wheels.BrowserDialogNotSupported` and specs should be skipped with an engine check.
````

- [ ] **Step 5: Add Route Assertions to the assertions section**

In the "URL / title / query" assertions block (around line 178), add after `assertQueryStringMissing`:

```
- `assertRouteIs(name [, params])` — matches current URL against Wheels `urlFor()` output
```

- [ ] **Step 6: Replace "Deferred functionality" table**

Replace lines 287-296 (the entire "Deferred functionality" section):

```markdown
## Deferred functionality

Tracked as follow-ups:

| Category | What's missing | Unblocked by |
|---|---|---|
| Auth | `loginAs(identifier)`, `logout()`, `keepSignedInAs` | Test-only route (`POST /_browser/login-as`) + running fixture server |
| Dialogs | `acceptDialog`, `dismissDialog`, `typeInDialog` | `createDynamicProxy` → `Consumer<Dialog>` via URLClassLoader |
| Routes | `visitRoute`, `assertRouteIs` | Wheels `urlFor()` outside controller context |
| Fixture app integration | End-to-end flow through Wheels HTTP pipeline | Dedicated fixture-server bootstrap |
```

With:

```markdown
## Delivered functionality (PRs 1-4)

All originally deferred features have been shipped:

| Category | Delivered | PR |
|---|---|---|
| Auth | `loginAs(identifier)`, `logout()` | #2116 |
| Dialogs | `acceptDialog`, `dismissDialog`, `dialogMessage` (Lucee-only) | #2116 |
| Routes | `visitRoute(name, params)`, `assertRouteIs(name, params)` | #2116 |
| Fixture routes | `/_browser/login-as`, `/_browser/logout`, login form, protected dashboard | #2116 |
| CI integration | Playwright cache + install in pr.yml and snapshot.yml | PR 4 |
```

- [ ] **Step 7: Replace "PR roadmap" section**

Replace lines 298-302 (the PR roadmap):

```markdown
## PR roadmap

- **PR 1 (this PR):** Foundation — launcher, client, base class, install bootstrap, core DSL.
- **PR 2:** `wheels browser:install` + `wheels browser:test` CLI + MCP tools.
- **PR 3:** `packages/hotwire/` dogfood browser specs against a real app.
- **PR 4:** CI workflow integration + reference docs promotion from draft.
```

With:

```markdown
## PR history

- **PR 1 (#2113):** Foundation — BrowserLauncher, BrowserClient, BrowserTest, core DSL (~40 methods).
- **PR 2 (#2115):** CLI commands (`wheels browser:install`, `wheels browser:test`), $buildOption helper, configurable timeouts, screenshot options, viewport config.
- **PR 3 (#2116):** loginAs/logout, dialog handling (createDynamicProxy), visitRoute/assertRouteIs, fixture routes under `/_browser/`.
- **PR 4:** CI workflow integration (Playwright cache + install in GitHub Actions) + reference docs finalization.
```

- [ ] **Step 8: Update "CI / skip logic" section**

Replace lines 71-77 (the CI/skip logic section):

```markdown
## CI / skip logic

`beforeAll` calls `$ensureLauncher()`, which throws `Wheels.BrowserNotInstalled` when any classpath JAR is missing. `BrowserTest` catches that and sets `this.browserTestSkipped = true`; `browserDescribe`'s hooks then short-circuit. Every `it` should start with:

```cfm
if (this.browserTestSkipped) return;
```

so CI (which doesn't run `install-playwright.sh`) stays green. Counts the skipped tests as passing, which is consistent with TestBox's "return early = pass" semantics.
```

With:

````markdown
## CI / skip logic

`beforeAll` calls `$ensureLauncher()`, which throws `Wheels.BrowserNotInstalled` when any classpath JAR is missing. `BrowserTest` catches that and sets `this.browserTestSkipped = true`; `browserDescribe`'s hooks then short-circuit. Every `it` should start with:

```cfm
if (this.browserTestSkipped) return;
```

**CI behavior:** The `pr.yml` and `snapshot.yml` workflows install Playwright JARs + Chromium via a cached step (keyed on `browser-manifest.json` hash). When the cache is warm, restore takes ~10s. When cold, downloads ~370MB of JARs + Chromium (~2-3 min). The `WHEELS_BROWSER_TEST_BASE_URL` env var is set to `http://localhost:60007` so browser specs can make HTTP requests to the running Lucee server.

**Local behavior:** If you haven't run `wheels browser:install`, browser specs skip silently. Run `wheels browser:install` once to enable them locally.
````

- [ ] **Step 9: Add new gotchas**

Append these to the "Gotchas" section (after the "Thread context classloader" gotcha, around line 283):

```markdown
### `createDynamicProxy` for Java interface implementation (Lucee-only)

Dialog handling requires implementing Playwright's `Consumer<Dialog>` Java interface. Lucee's `createDynamicProxy` creates a Java proxy from a CFML struct of handler functions. This is Lucee-specific — Adobe CF and BoxLang don't support it. Browser specs that test dialogs should check `server.lucee` or wrap in try/catch with engine-aware skip logic.

### Fixture routes must mount before `.wildcard()`

The `/_browser/*` fixture routes (login-as, logout, login form, protected page) are mounted by the framework in test mode. They must come before `.wildcard()` in `config/routes.cfm` or the wildcard catches them first. The framework handles this automatically, but custom route files that override the default order should be aware.

### Fat arrow closures in TestBox suites

CFML fat arrow syntax (`() => { ... }`) works in most contexts, but closure semantics can differ from `function() { ... }` in edge cases related to `this` binding and component scope. In browser test specs, fat arrows work well for `describe`/`it` callbacks because `this` refers to the spec CFC instance. If you encounter scope issues, switch to explicit `function()` syntax.
```

- [ ] **Step 10: Commit**

```bash
git add .ai/wheels/testing/browser-testing.md
git commit -m "docs(test): finalize browser-testing.md — all PRs shipped, full DSL reference"
```

---

### Task 4: Update CLAUDE.md — browser testing section

**Files:**
- Modify: `CLAUDE.md:765-831` (Browser Testing Quick Reference)

- [ ] **Step 1: Update intro paragraph**

Replace lines 767 (the intro text):

```
Foundation landed in v4.0 (PR 1 of 4). Specs extend `wheels.wheelstest.BrowserTest` and drive a real Chromium through `this.browser` — a fluent DSL wrapping Playwright Java.
```

With:

```
Shipped in v4.0 across PRs #2113, #2115, #2116. Specs extend `wheels.wheelstest.BrowserTest` and drive a real Chromium through `this.browser` — a fluent DSL wrapping Playwright Java.
```

- [ ] **Step 2: Remove "Deferred to PR 4" section**

Delete lines 819-822 entirely:

```markdown
### Deferred to PR 4

- CI workflow integration (Playwright install + browser specs in GitHub Actions)
- Reference docs promotion from draft `.ai/` to published docs
```

- [ ] **Step 3: Add CI note to the Key gotchas section**

After the `this.browserTestSkipped` gotcha (line 829), add:

```
- **CI runs browser tests** — `pr.yml` and `snapshot.yml` install Playwright JARs + Chromium (cached via `browser-manifest.json` hash). Browser specs run as part of the normal test suite. `WHEELS_BROWSER_TEST_BASE_URL=http://localhost:60007` is set automatically.
```

- [ ] **Step 4: Add fixture route and dialog gotchas**

Append after the new CI gotcha:

```
- **Fixture routes** — `/_browser/login-as` and `/_browser/logout` are mounted automatically in test mode. They must come before `.wildcard()` in routes.cfm.
- **Dialogs are Lucee-only** — `acceptDialog`, `dismissDialog`, `dialogMessage` use `createDynamicProxy` which is Lucee-specific. Specs skip gracefully on other engines.
```

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(test): update CLAUDE.md browser section — mark complete, add CI + fixture gotchas"
```

---

### Task 5: Run local tests to verify nothing broke

**Files:** None modified — verification only.

- [ ] **Step 1: Run the test suite**

```bash
bash tools/test-local.sh
```

Expected: All tests pass (3045+), 0 fail, 0 error. Browser specs will skip if Playwright isn't installed locally — that's fine.

- [ ] **Step 2: Validate both YAML files**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/pr.yml'))" && echo "pr.yml OK"
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/snapshot.yml'))" && echo "snapshot.yml OK"
```

Expected: Both print `OK`.

- [ ] **Step 3: Verify no broken markdown links in CLAUDE.md**

```bash
grep -n 'browser-testing.md' CLAUDE.md
```

Expected: Line ~831 shows `Full reference: .ai/wheels/testing/browser-testing.md.` — path unchanged.

---

### Task 6: Final commit + PR readiness

- [ ] **Step 1: Review all changes**

```bash
git log --oneline claude/awesome-noyce ^develop
git diff develop --stat
```

Expected: 4 commits (pr.yml, snapshot.yml, browser-testing.md, CLAUDE.md) + the spec commit from earlier.

- [ ] **Step 2: Squash-readiness check**

Verify no untracked files were left behind:

```bash
git status
```

Expected: Clean working tree.
