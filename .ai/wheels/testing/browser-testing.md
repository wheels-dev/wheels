# Browser Testing (`wheels.wheelstest.BrowserTest`)

Native browser testing added in Wheels v4.0 via Playwright Java. Specs extend `wheels.wheelstest.BrowserTest` and drive a real Chromium browser through a fluent DSL that mirrors the shape of `wheels.wheelstest.TestClient` (HTTP integration testing): chainable actions return `this`, terminals return values.

## Status: Complete (v4.0)

Shipped across four PRs (#2113, #2115, #2116, and the CI/docs PR). Full DSL, CLI commands, CI integration, and fixture route support.

## Installation

```bash
wheels browser:install              # recommended (LuCLI or CommandBox)
bash tools/install-playwright.sh    # legacy fallback (deprecated)
```

Idempotent. Downloads seven JARs totalling ~192 MB (client + driver + driver-bundle + gson + Java-WebSocket + slf4j-api + slf4j-simple) from Maven Central, SHA-verifies each, then runs `playwright install chromium` which drops ~170 MB of Chromium under `~/Library/Caches/ms-playwright/` (macOS) or `~/.cache/ms-playwright/` (Linux). Re-running is a no-op once the SHAs match.

## CLI Commands

```bash
wheels browser:install              # download JARs + browser binaries
wheels browser:install --force      # re-download even if SHAs match
wheels browser:install --browser=firefox

wheels browser:test                 # run browser test suite
wheels browser:test --verbose       # show full spec names
wheels browser:test --format=json   # JSON output for CI
```

## Architecture

Three CFCs under `vendor/wheels/wheelstest/`:

1. **`BrowserLauncher.cfc`** — process-level owner of the Playwright instance. Reads `vendor/wheels/browser-manifest.json`, walks the `classpath[]` array to compute JAR paths, loads them into a `URLClassLoader` with `PlatformClassLoader` as parent (critical — see Gotchas below), acquires one `Browser` per engine, caches it. State machine: `uninitialized → ready → shut-down`.
2. **`BrowserClient.cfc`** — the DSL. Takes a `Page`, a `BrowserContext`, and a base URL; wraps Playwright's locator/page APIs with the ~40 chainable methods enumerated below.
3. **`BrowserTest.cfc`** — TestBox BDD base class. `beforeAll` lazy-initializes an application-scoped launcher so all spec CFCs in a test run share one Chromium startup (~1.7 s). Provides `browserDescribe(title, body)` which wraps `describe()` with per-`it` beforeEach/afterEach that create a fresh `BrowserContext` and inject it as `this.browser`.

## Spec structure

```cfm
component extends="wheels.wheelstest.BrowserTest" {

    this.browserEngine = "chromium";   // chromium is the only engine in PR 1

    function run() {
        // browserDescribe === describe + per-it browser lifecycle.
        // Mix with plain describe() blocks for non-browser tests.
        browserDescribe("My feature", () => {

            it("renders the welcome page", () => {
                if (this.browserTestSkipped) return;  // see "CI / skip logic"
                this.browser
                    .visitUrl("data:text/html,<h1>Hello</h1>")
                    .assertSee("Hello");
            });
        });
    }
}
```

### Why `browserDescribe` instead of `beforeEach` on the class

TestBox BDD treats `beforeAll`/`afterAll` as class-level lifecycle hooks but `beforeEach`/`afterEach` as *registration* functions that must be called from inside a `describe` body. So the natural "add a method named `beforeEach` to the parent class and let inheritance do its thing" pattern doesn't work. `browserDescribe` sidesteps this by calling `describe(...)` internally and registering the hooks from within the suite body.

## CI / skip logic

`beforeAll` calls `$ensureLauncher()`, which throws `Wheels.BrowserNotInstalled` when any classpath JAR is missing. `BrowserTest` catches that and sets `this.browserTestSkipped = true`; `browserDescribe`'s hooks then short-circuit. Every `it` should start with:

```cfm
if (this.browserTestSkipped) return;
```

**CI behavior:** The `pr.yml` and `snapshot.yml` workflows install Playwright JARs + Chromium via a cached step (keyed on `browser-manifest.json` hash). When the cache is warm, restore takes ~10s. When cold, downloads ~370MB of JARs + Chromium (~2-3 min). The `WHEELS_BROWSER_TEST_BASE_URL` env var is set to `http://localhost:60007` so browser specs can make HTTP requests to the running Lucee server.

**Local behavior:** If you haven't run `wheels browser:install`, browser specs skip silently. Run `wheels browser:install` once to enable them locally.

## Implemented DSL methods

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

### Interaction

```cfm
this.browser
    .click("##signin-button")            // CSS selector
    .press("Sign in")                    // visible text (getByText().first())
    .fill("##email", "alice@example.com")
    .type("##search", "wheels")          // char-by-char (triggers autocomplete handlers)
    .clear("##email")
    .select("##country", "US")
    .check("##terms")
    .uncheck("##newsletter")
    .attach("##upload", "/path/to/file.txt")
    .dragAndDrop("##source", "##target");
```

`press()` matches by visible text (Playwright `getByText(...).first()`). If you need role-specific matching (e.g., button-only, ignoring same-text headings), use `click("button:has-text('Save')")` instead.

### Keyboard

```cfm
this.browser
    .keys("##email", "Control+A")       // any key combination
    .pressEnter("##password")            // shorthand; selector optional
    .pressTab()                          // no selector → sends to focused element
    .pressEscape();
```

### Waiting

```cfm
this.browser
    .waitFor("##late-loaded-element")   // waits up to Playwright's default (30s)
    .waitFor("##late-element", 5)       // custom timeout in seconds
    .waitForText("Loading complete")
    .waitForUrl("**/dashboard", 5);     // glob pattern + timeout
```

### Scoping

```cfm
// Same `#email` selector in two different forms — within() disambiguates.
this.browser.within("form##signin", (scoped) => {
    scoped.fill("##email", "alice@example.com")
          .fill("##password", "secret")
          .click("button[type=submit]");
});
```

Inside the callback, `scoped` is a BrowserClient whose selectors resolve relative to the `form#signin` subtree.

### Viewport

```cfm
this.browser
    .resize(1024, 768)
    .resizeToMobile()      // 375 x 667
    .resizeToTablet()      // 768 x 1024
    .resizeToDesktop();    // 1440 x 900
```

### Script + Pause

```cfm
var title = this.browser.script("() => document.title");
var count = this.browser.script("() => document.querySelectorAll('li').length");
this.browser.pause(500);  // prints a warning; use waitFor instead for sync
```

### Assertions

All throw `Wheels.BrowserAssertionFailed` on mismatch and return `this` on success.

**Text / visibility / presence:**
- `assertSee(text)` / `assertDontSee(text)` — page-wide substring (case-insensitive)
- `assertSeeIn(selector, text)` — scoped substring
- `assertVisible(selector)` — rendered + not `display:none`
- `assertMissing(selector)` / `assertPresent(selector)` / `assertNotPresent(selector)` — DOM count checks

**URL / title / query:**
- `assertUrlIs(expected)` — path-only compare when arg starts with `/`, otherwise full URL
- `assertUrlContains(substring)` — substring check (more forgiving for dynamic URLs)
- `assertTitleContains(text)` — case-insensitive
- `assertQueryStringHas(key [, value])` / `assertQueryStringMissing(key)`
- `assertRouteIs(name [, params])` — matches current URL against Wheels `urlFor()` output

**Form:**
- `assertInputValue(selector, value)`
- `assertChecked(selector)`
- `assertHasClass(selector, class)` — space-separated list match

### Terminals

```cfm
this.browser.currentUrl();           // string
this.browser.title();                // <title> content
this.browser.pageSource();           // full HTML
this.browser.text("h1");             // textContent of first match
this.browser.value("##email");       // input/textarea/select value
this.browser.screenshot("/tmp/x.png"); // writes PNG; returns this for chaining
```

### Cookies

```cfm
this.browser
    .setCookie(name="session", value="abc123", url="http://localhost:8080")
    .deleteCookie("session");

var c = this.browser.cookie("session");  // returns struct {name, value, domain, ...}
```

Cookies require a real HTTP origin — `data:` URLs are opaque origins.

### Auth

```cfm
// loginAs sends POST to /_browser/login-as with the given identifier
this.browser.loginAs("admin");        // sets session via fixture route
this.browser.logout();                // sends POST to /_browser/logout
```

Requires fixture routes mounted in `config/routes.cfm` (added automatically by the framework in test mode). The `/_browser/login-as` route accepts a `POST` with `identifier` param and sets `session.currentUser`. The `/_browser/logout` route clears the session.

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

### Configurable Timeouts

```cfm
this.browser
    .waitFor("##late-element", 5)      // 5-second timeout (default: 30)
    .waitForText("Loaded", 10)
    .waitForUrl("**/dashboard", 5);
```

### Screenshot Options

```cfm
this.browser.screenshot("/tmp/page.png");                           // basic
this.browser.screenshot(path="/tmp/full.png", fullPage=true);       // full page
this.browser.screenshot(path="/tmp/q.png", quality=80);             // JPEG quality
```

### Viewport Config (BrowserTest Level)

```cfm
component extends="wheels.wheelstest.BrowserTest" {
    this.browserViewport = "mobile";           // preset: mobile/tablet/desktop
    // or: this.browserViewport = {width: 1024, height: 768};
}
```

Presets: `"mobile"` (375x667), `"tablet"` (768x1024), `"desktop"` (1440x900).

### Auto-Screenshot on Failure

When a browser test fails, a screenshot and HTML dump are automatically saved to `tests/_output/browser/`. Disable per-spec:

```cfm
this.browserScreenshotOnFailure = false;
```

Configure artifact directory:
```cfm
this.browserArtifactPath = expandPath("/custom/path");
```

## Gotchas (keep these in working memory when writing browser specs)

### `##` in CFML strings

CFML treats `#` as an expression delimiter inside double-quoted strings. To emit a literal `#` (for CSS ID selectors), escape as `##`. So `"##email"` compiles to the runtime string `"#email"`.

### `client` is a reserved Lucee scope

Declaring `var client = ...` inside a closure throws "client scope is not enabled". Use `var c`, `var bc`, or `variables.bc` instead. Same goes for `session`, `application`, `request`, `form`, `url`, `arguments`, `local`, `variables`, `this` — avoid as local variable names.

### Data URLs for most tests

Many DSL methods can be tested against inline `data:text/html,...` URLs without any server running. This is the pattern used throughout `BrowserIntegrationSpec.cfc`. Data URLs can carry query strings (`data:text/html,<h1/>?foo=bar`) and fragments, but **cannot set HTTP cookies or localStorage** — Chromium treats them as opaque origins. For anything involving cookies or server-driven redirects, you need a real fixture server running at `baseUrl`.

### URLClassLoader + Playwright's inner-class options

`createObject("java", "com.microsoft.playwright.Locator$WaitForOptions")` fails under Lucee when the class lives inside a URLClassLoader — Lucee's class-resolver tries to treat the loader as an OSGi bundle and can't. Workaround (not yet implemented as a DSL helper; apply by hand if you need a specific option):

```cfm
var cl = variables.$browser.getClass().getClassLoader();
var klass = cl.loadClass("com.microsoft.playwright.Locator$WaitForOptions");
var opts = klass.getDeclaredConstructor().newInstance();
opts.setTimeout(javaCast("double", 5000));
```

A `$buildOption(className, ...)` helper on `BrowserLauncher` is planned — when it lands, configurable-timeout `waitFor`, `waitForUrl`, full screenshot options, and cookie manipulation all unblock.

### `PlatformClassLoader` as parent

If you're building another URLClassLoader-backed Java library on top of the manifest install, parent it to `ClassLoader.getPlatformClassLoader()` rather than `getSystemClassLoader()` / TCCL. AppClassLoader-as-parent causes cross-JAR superclass resolution to fail at `defineClass` time with `NoClassDefFoundError` — even when the superclass IS on the URLClassLoader's own URLs. This was the most painful trap in the Task 4 implementation.

### Thread context classloader during Playwright calls

Playwright's `DriverJar.getDriverResourceURI()` uses `Thread.currentThread().getContextClassLoader()` to locate the bundled Node runtime inside `driver-bundle.jar`. Default TCCL is the AppClassLoader, which doesn't see our JARs — so the lookup returns null and `Playwright.create()` fails with an NPE that Lucee swallows silently (looks like a hang — it's not). `BrowserLauncher.acquireBrowser()` swaps TCCL to our URLClassLoader for the duration of the Playwright call chain. If you call Playwright methods outside the DSL (directly via `this.browser.getPage()`), you may need `$pushTCCL()` / `$popTCCL()` manually.

### `createDynamicProxy` for Java interface implementation (Lucee-only)

Dialog handling requires implementing Playwright's `Consumer<Dialog>` Java interface. Lucee's `createDynamicProxy` creates a Java proxy from a CFML struct of handler functions. This is Lucee-specific — Adobe CF and BoxLang don't support it. Browser specs that test dialogs should check `server.lucee` or wrap in try/catch with engine-aware skip logic.

### Fixture routes must mount before `.wildcard()`

The `/_browser/*` fixture routes (login-as, logout, login form, protected page) are mounted by the framework in test mode. They must come before `.wildcard()` in `config/routes.cfm` or the wildcard catches them first. The framework handles this automatically, but custom route files that override the default order should be aware.

### Fat arrow closures in TestBox suites

CFML fat arrow syntax (`() => { ... }`) works in most contexts, but closure semantics can differ from `function() { ... }` in edge cases related to `this` binding and component scope. In browser test specs, fat arrows work well for `describe`/`it` callbacks because `this` refers to the spec CFC instance. If you encounter scope issues, switch to explicit `function()` syntax.

## Delivered functionality (PRs 1-4)

All originally deferred features have been shipped:

| Category | Delivered | PR |
|---|---|---|
| Auth | `loginAs(identifier)`, `logout()` | #2116 |
| Dialogs | `acceptDialog`, `dismissDialog`, `dialogMessage` (Lucee-only) | #2116 |
| Routes | `visitRoute(name, params)`, `assertRouteIs(name, params)` | #2116 |
| Fixture routes | `/_browser/login-as`, `/_browser/logout`, login form, protected dashboard | #2116 |
| CI integration | Playwright cache + install in pr.yml and snapshot.yml | PR 4 |

## PR history

- **PR 1 (#2113):** Foundation — BrowserLauncher, BrowserClient, BrowserTest, core DSL (~40 methods).
- **PR 2 (#2115):** CLI commands (`wheels browser:install`, `wheels browser:test`), $buildOption helper, configurable timeouts, screenshot options, viewport config.
- **PR 3 (#2116):** loginAs/logout, dialog handling (createDynamicProxy), visitRoute/assertRouteIs, fixture routes under `/_browser/`.
- **PR 4:** CI workflow integration (Playwright cache + install in GitHub Actions) + reference docs finalization.
