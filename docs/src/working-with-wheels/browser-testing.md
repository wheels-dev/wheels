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
| Test runner | WheelsTest (runs in Wheels) | Playwright Test (runs in Node.js) |
| Best for | Framework tests, CFML-centric teams | Frontend-heavy apps, JS-centric teams |
| Browser support | Chromium only | Chromium, Firefox, WebKit |

Both approaches are valid. Use native CFML if you want tests alongside your models and controllers in the same language. Use Node.js Playwright if you need multi-browser support or prefer TypeScript tooling.

## See Also

- [Testing Your Application](testing-your-application.md) — Unit and integration testing with WheelsTest
- [End-to-End Testing](end-to-end-testing.md) — Node.js/TypeScript Playwright approach
- [`wheels browser:install`](../command-line-tools/commands/browser/browser-install.md) — CLI command reference
- [`wheels browser:test`](../command-line-tools/commands/browser/browser-test.md) — CLI command reference
