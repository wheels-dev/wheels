# Browser Testing PR 4: CI Workflow + Reference Docs — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make browser tests actually run in CI (pr.yml + snapshot.yml), finalize all reference documentation, and add user-facing docs for native CFML browser testing.

**Architecture:** Add Playwright JAR download + Chromium install steps to the existing fast-test job in both CI workflows. Cache ~370MB of artifacts keyed on browser-manifest.json hash. Update browser-testing.md and CLAUDE.md to reflect all PRs 1-3 as shipped. Create user-facing docs distinguishing native CFML browser testing from the existing Node.js Playwright approach.

**Tech Stack:** GitHub Actions (actions/cache@v4), shell (jq, sha256sum, curl), Playwright Java CLI, Markdown

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `.github/workflows/pr.yml` | Add cache + install steps, env var |
| Modify | `.github/workflows/snapshot.yml` | Same changes as pr.yml |
| Modify | `.ai/wheels/testing/browser-testing.md` | Promote from draft to final — status, DSL, gotchas, roadmap |
| Modify | `CLAUDE.md` | Remove "Deferred to PR 4", update intro text, add gotchas |
| Create | `docs/src/working-with-wheels/browser-testing.md` | User-facing guide for native CFML browser testing |
| Create | `docs/src/command-line-tools/commands/browser/browser-install.md` | CLI reference for `wheels browser:install` |
| Create | `docs/src/command-line-tools/commands/browser/browser-test.md` | CLI reference for `wheels browser:test` |
| Modify | `docs/src/SUMMARY.md` | Add entries for browser testing page + CLI commands |
| Modify | `docs/src/working-with-wheels/end-to-end-testing.md` | Add cross-reference to native CFML browser testing |

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

### Task 5: Create user-facing browser testing guide

**Files:**
- Create: `docs/src/working-with-wheels/browser-testing.md`

- [ ] **Step 1: Create the guide**

Create `docs/src/working-with-wheels/browser-testing.md` with this content:

````markdown
---
description: Write browser tests in CFML using the native Playwright integration...
---

# Browser Testing

Wheels includes native browser testing powered by Playwright Java. Write test specs in CFML that drive a real Chromium browser — no Node.js or TypeScript required.

{% hint style="info" %}
This guide covers the **native CFML browser testing** built into the Wheels framework. For the Node.js/TypeScript Playwright approach, see [End-to-End Testing](end-to-end-testing.md).
{% endhint %}

## Overview

Browser tests extend `wheels.wheelstest.BrowserTest` and use a fluent DSL through `this.browser`. Each `it` block gets a fresh browser context (isolated cookies, storage, sessions).

```cfm
component extends="wheels.wheelstest.BrowserTest" {
    function run() {
        browserDescribe("User login", () => {
            it("shows the dashboard after login", () => {
                if (this.browserTestSkipped) return;
                this.browser
                    .visit("/login")
                    .fill("##email", "alice@example.com")
                    .fill("##password", "secret")
                    .click("button[type=submit]")
                    .assertUrlContains("/dashboard")
                    .assertSee("Welcome");
            });
        });
    }
}
```

## Installation

Install Playwright JARs and Chromium (~370 MB total, one-time download):

```bash
wheels browser:install
```

This downloads 7 JARs from Maven Central and the Chromium browser binary. Re-running is a no-op once everything is installed.

## Writing Tests

### Test File Location

Place browser test specs in `tests/specs/browser/` (or any subdirectory under `tests/specs/`):

```
tests/
  specs/
    browser/
      LoginSpec.cfc
      CheckoutSpec.cfc
```

### Test Structure

Every browser test CFC extends `wheels.wheelstest.BrowserTest` and uses `browserDescribe()` instead of plain `describe()`:

```cfm
component extends="wheels.wheelstest.BrowserTest" {

    this.browserEngine = "chromium";   // only chromium supported currently

    function run() {
        browserDescribe("Feature name", () => {
            it("does something", () => {
                if (this.browserTestSkipped) return;
                this.browser
                    .visit("/page")
                    .assertSee("Expected text");
            });
        });
    }
}
```

**Key points:**
- `browserDescribe()` creates a fresh browser context per `it` block
- Always check `this.browserTestSkipped` at the start of each test — this allows specs to skip gracefully when Playwright isn't installed
- `this.browser` is the DSL entry point — all methods are chainable

### Navigation

```cfm
this.browser
    .visit("/login")                    // relative to app base URL
    .visitUrl("https://example.com")    // absolute URL
    .visitRoute("user", {key: 42})      // Wheels named route
    .back()
    .forward()
    .refresh();
```

### Interacting with Elements

```cfm
this.browser
    .click("##submit-btn")              // CSS selector (## = literal #)
    .press("Sign in")                   // click by visible text
    .fill("##email", "alice@example.com")
    .type("##search", "wheels")         // char-by-char typing
    .clear("##email")
    .select("##country", "US")
    .check("##terms")
    .uncheck("##newsletter");
```

### Assertions

```cfm
// Text and visibility
this.browser
    .assertSee("Welcome")              // page contains text
    .assertDontSee("Error")
    .assertSeeIn("h1", "Dashboard")    // scoped to selector
    .assertVisible("##main-nav")
    .assertMissing("##error-banner");

// URL and title
this.browser
    .assertUrlIs("/dashboard")
    .assertUrlContains("/dash")
    .assertTitleContains("Dashboard")
    .assertRouteIs("dashboard");

// Forms
this.browser
    .assertInputValue("##email", "alice@example.com")
    .assertChecked("##terms")
    .assertHasClass("##alert", "success");
```

### Waiting

```cfm
this.browser
    .waitFor("##lazy-element")          // default 30s timeout
    .waitFor("##element", 5)            // 5 second timeout
    .waitForText("Loading complete")
    .waitForUrl("**/dashboard", 5);     // glob pattern
```

### Scoping

```cfm
this.browser.within("form##login", (scoped) => {
    scoped.fill("##email", "alice@example.com")
          .fill("##password", "secret")
          .click("button[type=submit]");
});
```

### Authentication

```cfm
// Quick login via fixture route (no form interaction needed)
this.browser.loginAs("admin");
this.browser.logout();
```

Uses fixture routes mounted automatically at `/_browser/login-as` and `/_browser/logout` in test mode.

### Dialogs (Lucee Only)

```cfm
// Must be called BEFORE the triggering action
this.browser.acceptDialog();
this.browser.acceptDialog("prompt answer");
this.browser.dismissDialog();
var msg = this.browser.dialogMessage();
```

Dialog handling uses Lucee's `createDynamicProxy` and is not available on other CFML engines.

### Viewport

```cfm
this.browser
    .resize(1024, 768)
    .resizeToMobile()       // 375 x 667
    .resizeToTablet()       // 768 x 1024
    .resizeToDesktop();     // 1440 x 900
```

Or set a default viewport for the entire spec:

```cfm
this.browserViewport = "mobile";
// or: this.browserViewport = {width: 1024, height: 768};
```

### Screenshots

```cfm
this.browser.screenshot("/tmp/page.png");
this.browser.screenshot(path="/tmp/full.png", fullPage=true);
```

Failed tests automatically capture a screenshot and HTML dump to `tests/_output/browser/`.

## Running Tests

```bash
# Run all tests (browser specs included when Playwright is installed)
wheels test run

# Run browser specs only
wheels browser:test

# JSON output for CI
wheels browser:test --format=json

# Verbose output (show full spec names + failure details)
wheels browser:test --verbose
```

## CFML Gotchas

- **`##` for CSS ID selectors** — CFML treats `#` as an expression delimiter. Use `##email` to produce `#email` at runtime.
- **`client` is a reserved scope** — Don't use `var client = ...` inside closures on Lucee. Use `var c = ...` instead.
- **Data URLs for simple tests** — `data:text/html,<h1>Hello</h1>` works for most DSL methods without a running server. But cookies and form redirects need a real HTTP origin.

## Comparison with Node.js Playwright

| | Native CFML | Node.js Playwright |
|---|---|---|
| Language | CFML (`.cfc` files) | TypeScript/JavaScript (`.spec.ts`) |
| Setup | `wheels browser:install` | `npm install && npx playwright install` |
| Test runner | TestBox (runs in Wheels) | Playwright Test (runs in Node.js) |
| Best for | Framework tests, CFML-centric teams | Frontend-heavy apps, JS-centric teams |
| Browser support | Chromium only | Chromium, Firefox, WebKit |

Both approaches are valid. Use native CFML if you want tests alongside your models and controllers in the same language. Use Node.js Playwright if you need multi-browser support or prefer TypeScript tooling.

## See Also

- [Testing Your Application](testing-your-application.md) — Unit and integration testing with TestBox
- [End-to-End Testing](end-to-end-testing.md) — Node.js/TypeScript Playwright approach
- [`wheels browser:install`](../command-line-tools/commands/browser/browser-install.md) — CLI command reference
- [`wheels browser:test`](../command-line-tools/commands/browser/browser-test.md) — CLI command reference
````

- [ ] **Step 2: Commit**

```bash
git add docs/src/working-with-wheels/browser-testing.md
git commit -m "docs(test): add user-facing browser testing guide"
```

---

### Task 6: Create CLI command reference pages

**Files:**
- Create: `docs/src/command-line-tools/commands/browser/browser-install.md`
- Create: `docs/src/command-line-tools/commands/browser/browser-test.md`

- [ ] **Step 1: Create browser-install.md**

Create `docs/src/command-line-tools/commands/browser/browser-install.md`:

````markdown
---
description: Install Playwright JARs and browser binaries for native CFML browser testing.
---

# wheels browser:install

Install Playwright Java JARs and browser binaries for native CFML browser testing. Downloads 7 JARs from Maven Central (~200 MB), verifies SHA-256 hashes, then installs the Chromium browser binary (~170 MB).

## Usage

```bash
wheels browser:install [options]
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--force` | boolean | `false` | Re-download JARs even if SHA-256 hashes match |
| `--browser` | string | `chromium` | Which browser to install (`chromium`, `firefox`, `webkit`) |

## Examples

### Standard installation

```bash
wheels browser:install
```

### Force re-download

```bash
wheels browser:install --force
```

### Install Firefox instead

```bash
wheels browser:install --browser=firefox
```

## What Gets Installed

**JARs** (~200 MB) are downloaded to `~/.wheels/browser/lib/`:
- `playwright-1.52.0.jar` — Playwright client API
- `driver-1.52.0.jar` — Driver class
- `driver-bundle-1.52.0.jar` — Bundled Node runtime (~191 MB)
- `gson-2.12.1.jar` — JSON library
- `Java-WebSocket-1.6.0.jar` — WebSocket transport
- `slf4j-api-2.0.17.jar` — Logging API
- `slf4j-simple-2.0.17.jar` — Logging implementation

**Browser binary** (~170 MB) is installed to the Playwright cache:
- macOS: `~/Library/Caches/ms-playwright/`
- Linux: `~/.cache/ms-playwright/`

## Idempotent

Re-running is a no-op when all JARs pass SHA-256 verification and the browser is already installed. Use `--force` to re-download regardless.

## Environment Variables

| Variable | Description |
|----------|-------------|
| `WHEELS_BROWSER_HOME` | Override install directory (default: `~/.wheels/browser`) |

## Manifest

JAR URLs and SHA-256 hashes are defined in `vendor/wheels/browser-manifest.json`. This file is version-controlled and determines which Playwright version is used.

## See Also

- [`wheels browser:test`](browser-test.md) — Run browser tests
- [Browser Testing Guide](../../working-with-wheels/browser-testing.md) — Full browser testing guide
````

- [ ] **Step 2: Create browser-test.md**

Create `docs/src/command-line-tools/commands/browser/browser-test.md`:

````markdown
---
description: Run native CFML browser tests using Playwright.
---

# wheels browser:test

Run browser test specs that extend `wheels.wheelstest.BrowserTest`. Verifies Playwright is installed before hitting the test runner URL.

## Usage

```bash
wheels browser:test [options]
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--format` | string | `text` | Output format: `text` or `json` |
| `--verbose` | boolean | `false` | Show full spec names and failure details |
| `--directory` | string | `wheels.tests.specs.wheelstest` | Test directory (dot-notation) |

## Examples

### Run all browser tests

```bash
wheels browser:test
```

### JSON output for CI

```bash
wheels browser:test --format=json
```

### Verbose output

```bash
wheels browser:test --verbose
```

### Run a specific test directory

```bash
wheels browser:test --directory=tests.specs.browser
```

## Pre-flight Check

Before running tests, this command verifies that all Playwright JARs are installed and SHA-256 hashes match. If anything is missing, it prints instructions to run `wheels browser:install`.

## Requirements

- A running Wheels server (the command auto-detects the host and port from CommandBox)
- Playwright installed via `wheels browser:install`

## See Also

- [`wheels browser:install`](browser-install.md) — Install Playwright
- [Browser Testing Guide](../../working-with-wheels/browser-testing.md) — Full browser testing guide
````

- [ ] **Step 3: Commit**

```bash
git add docs/src/command-line-tools/commands/browser/
git commit -m "docs(cli): add browser:install and browser:test command reference pages"
```

---

### Task 7: Update SUMMARY.md and cross-reference from end-to-end-testing.md

**Files:**
- Modify: `docs/src/SUMMARY.md:57-62` (Testing Commands + Playwright Commands sections)
- Modify: `docs/src/SUMMARY.md:123-124` (Working with Wheels section)
- Modify: `docs/src/working-with-wheels/end-to-end-testing.md:1-7` (add cross-reference)

- [ ] **Step 1: Add Browser Commands section to SUMMARY.md**

In `docs/src/SUMMARY.md`, after the Playwright Commands section (line 62), insert:

```markdown
  * Browser Commands
    * [wheels browser:install](command-line-tools/commands/browser/browser-install.md)
    * [wheels browser:test](command-line-tools/commands/browser/browser-test.md)
```

- [ ] **Step 2: Add Browser Testing page to Working with Wheels section**

In `docs/src/SUMMARY.md`, after the "End-to-End Testing" entry (line 124), insert:

```markdown
* [Browser Testing](working-with-wheels/browser-testing.md)
```

- [ ] **Step 3: Add cross-reference to end-to-end-testing.md**

At the top of `docs/src/working-with-wheels/end-to-end-testing.md`, after the frontmatter and title (after line 7), insert:

```markdown

{% hint style="info" %}
This guide covers the **Node.js/TypeScript Playwright** approach. For native CFML browser testing that runs inside TestBox, see [Browser Testing](browser-testing.md).
{% endhint %}
```

- [ ] **Step 4: Commit**

```bash
git add docs/src/SUMMARY.md docs/src/working-with-wheels/end-to-end-testing.md
git commit -m "docs(test): add browser testing to SUMMARY.md, cross-reference from e2e docs"
```

---

### Task 8: Run local tests to verify nothing broke

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

- [ ] **Step 4: Verify new docs files exist**

```bash
ls docs/src/working-with-wheels/browser-testing.md
ls docs/src/command-line-tools/commands/browser/browser-install.md
ls docs/src/command-line-tools/commands/browser/browser-test.md
```

Expected: All three files exist.

---

### Task 9: Final commit + PR readiness

- [ ] **Step 1: Review all changes**

```bash
git log --oneline claude/awesome-noyce ^develop
git diff develop --stat
```

Expected: 7 commits (pr.yml, snapshot.yml, browser-testing.md, CLAUDE.md, user-facing guide, CLI command pages, SUMMARY.md updates) + the spec/plan commits from earlier.

- [ ] **Step 2: Squash-readiness check**

Verify no untracked files were left behind:

```bash
git status
```

Expected: Clean working tree.
