# Browser Testing

Shipped in v4.0 across PRs #2113, #2115, #2116. Specs extend `wheels.wheelstest.BrowserTest` and drive a real Chromium through `this.browser` — a fluent DSL wrapping Playwright Java.

## Example

```cfm
// vendor/wheels/tests/specs/browser/LoginBrowserSpec.cfc
component extends="wheels.wheelstest.BrowserTest" {

    this.browserEngine = "chromium";   // chromium only in PR 1

    function run() {
        // browserDescribe() wraps describe() with beforeEach/afterEach that
        // create a fresh Page per `it`. WheelsTest's BDD lifecycle only treats
        // beforeAll/afterAll as class-level, so we register per-it hooks
        // from inside the suite body via this helper.
        browserDescribe("Login flow", () => {
            it("can load a page and read its title", () => {
                if (this.browserTestSkipped) return;
                this.browser.visitUrl("data:text/html,<title>Hi</title><h1>x</h1>")
                            .assertTitleContains("Hi");
            });
        });
    }
}
```

## Installation

Install Playwright locally before first run (~370MB download: JARs + Chromium):

```bash
wheels browser setup              # downloads JARs + Chromium
```

Then run browser specs via the normal test suite:

```bash
bash tools/test-local.sh                    # skips browser specs if JARs missing
```

## Implemented DSL methods

- **Navigation:** visit, visitUrl, back, forward, refresh, visitRoute
- **Interaction:** click, press, fill, type, clear, select, check, uncheck, attach, dragAndDrop
- **Keyboard:** keys, pressEnter, pressTab, pressEscape
- **Waiting:** waitFor, waitForText, waitForUrl
- **Scoping:** within(selector, callback)
- **Cookies:** setCookie, deleteCookie, cookie, clearCookies
- **Auth:** loginAs, logout
- **Dialogs:** acceptDialog, dismissDialog, dialogMessage (Lucee-only via createDynamicProxy)
- **Viewport:** resize, resizeToMobile, resizeToTablet, resizeToDesktop
- **Script:** script (returns `page.evaluate` result), pause
- **Assertions (text/vis/presence):** assertSee, assertDontSee, assertSeeIn, assertVisible, assertMissing, assertPresent, assertNotPresent
- **Assertions (URL/title/query):** assertUrlIs, assertUrlContains, assertTitleContains, assertQueryStringHas, assertQueryStringMissing, assertRouteIs
- **Assertions (form):** assertInputValue, assertChecked, assertHasClass
- **Terminals:** currentUrl, title, pageSource, text, value, screenshot

## Key gotchas

- **`this.browser` is not wired in plain `describe()` blocks.** Calling any DSL method on `this.browser` outside a `browserDescribe()` block throws `Wheels.BrowserTest.NotWired` (message names `browserDescribe()` as the fix; `detail` names the method that was called). The sentinel `UnwiredBrowserGuard` is installed at construction and after each `$endBrowserContext()` teardown.
- **`##` in selectors** — CFML requires `##` to emit literal `#`. `"##email"` → `"#email"` at runtime.
- **`client` is a Lucee reserved scope.** `var client = ...` in a closure throws "client scope is not enabled". Use `var c = ...` or `var bc = ...`. (Generalized rule: see CLAUDE.md anti-pattern #11.)
- **Data URLs work for most tests** — no server needed for ~95% of DSL coverage. Full HTTP integration (cookies, form submits, redirects) needs a running fixture app; that wiring is the same as Wheels Web app bootstrap (separate server + baseUrl).
- **`this.browserTestSkipped`** — when Playwright JARs aren't installed (fresh CI, clean machine), `beforeAll` sets this flag and `browserDescribe`'s hooks short-circuit. All `it`s should check `if (this.browserTestSkipped) return;` to stay green on CI.
- **CI runs browser tests** — `pr.yml` and `snapshot.yml` install Playwright JARs + Chromium (cached via `browser-manifest.json` hash). Browser specs run as part of the normal test suite. `WHEELS_BROWSER_TEST_BASE_URL=http://localhost:60007` is set automatically.
- **Fixture routes** — `/_browser/login-as` and `/_browser/logout` are mounted automatically in test mode. They must come before `.wildcard()` in routes.cfm. In the Routes UI (`/wheels/routes`) all `/_browser/*` routes appear under the **Internal** tab, not Application.
- **Dialogs are Lucee-only** — `acceptDialog`, `dismissDialog`, `dialogMessage` use `createDynamicProxy` which is Lucee-specific. Specs skip gracefully on other engines.
