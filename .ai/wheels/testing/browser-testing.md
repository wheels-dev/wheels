# Browser Testing (`wheels.wheelstest.BrowserTest`)

Native browser testing added in Wheels v4.0 via Playwright Java. Specs extend `wheels.wheelstest.BrowserTest` and drive a real Chromium browser through a fluent DSL that mirrors the shape of `wheels.wheelstest.TestClient` (HTTP integration testing): chainable actions return `this`, terminals return values.

## Status (v4.0 PR 1 of 4 — foundation)

This PR lands the plumbing. CLI, dogfood specs, and CI matrix integration come in PRs 2-4.

**What works:** navigation, interaction, keyboard, waiting (default timeout), scoping, viewport, script evaluation, most assertions, most terminals, lifecycle via `browserDescribe`.

**What's deferred:** `loginAs`/`logout` (needs test-only route + fixture server), dialogs (needs `createDynamicProxy`), `visitRoute`/`assertRouteIs` (needs `urlFor` outside controller), fixture app integration.

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

so CI (which doesn't run `install-playwright.sh`) stays green. Counts the skipped tests as passing, which is consistent with TestBox's "return early = pass" semantics.

## Implemented DSL methods

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

## Deferred functionality

Tracked as follow-ups:

| Category | What's missing | Unblocked by |
|---|---|---|
| Auth | `loginAs(identifier)`, `logout()`, `keepSignedInAs` | Test-only route (`POST /_browser/login-as`) + running fixture server |
| Dialogs | `acceptDialog`, `dismissDialog`, `typeInDialog` | `createDynamicProxy` → `Consumer<Dialog>` via URLClassLoader |
| Routes | `visitRoute`, `assertRouteIs` | Wheels `urlFor()` outside controller context |
| Fixture app integration | End-to-end flow through Wheels HTTP pipeline | Dedicated fixture-server bootstrap |

## PR roadmap

- **PR 1 (this PR):** Foundation — launcher, client, base class, install bootstrap, core DSL.
- **PR 2:** `wheels browser:install` + `wheels browser:test` CLI + MCP tools.
- **PR 3:** `packages/hotwire/` dogfood browser specs against a real app.
- **PR 4:** CI workflow integration + reference docs promotion from draft.
