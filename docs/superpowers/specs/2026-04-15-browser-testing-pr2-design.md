# Browser Testing PR 2 — CLI + Deferred DSL Methods

**Date:** 2026-04-15
**Status:** Approved
**Prereq:** PR 1 merged as #2113 (foundation — BrowserLauncher, BrowserClient, BrowserTest, install script, 62 specs)

## Scope

PR 2 delivers three themes:
1. `$buildOption` reflection helper + all DSL methods it unblocks
2. CLI commands (`wheels browser:install`, `wheels browser:test`)
3. Auto-screenshot/HTML dump on test failure

Deferred to PR 3: loginAs/logout, fixture-server bootstrap, dialogs (`createDynamicProxy`), visitRoute/assertRouteIs.

## 1. `$buildOption` Reflection Helper

### Location

`BrowserLauncher.cfc` — new public method.

### Signature

```cfm
public any function $buildOption(required string className, struct setterMap = {})
```

### Behavior

1. Load class via `variables.$classLoader.loadClass(className)`
2. Call `getDeclaredConstructor().newInstance()` (all Playwright option classes have zero-arg constructors)
3. Iterate `setterMap`: for each key (setter name) + value, find the setter method on the class, auto-cast the value to match the setter's parameter type, invoke it
4. Return the constructed option object

### Type Casting

Auto-detect from setter's `getParameterTypes()[1]`:
- `java.lang.Double` / `double` → `javaCast("double", value)`
- `java.lang.Boolean` / `boolean` → `javaCast("boolean", value)`
- `java.lang.Integer` / `int` → `javaCast("int", value)`
- `java.lang.String` → `javaCast("string", value)`
- Anything else (including Java objects from nested `$buildOption` calls) → pass through untouched

### TCCL

Not needed. `loadClass()` + `newInstance()` + setter calls don't trigger Playwright's driver resource lookup. TCCL is only required for `Playwright.create()` and `BrowserType.launch()`.

### Error Handling

Wraps reflection failures in `Wheels.BrowserOptionError` with class name + setter name for debuggability.

### Tests

- Unit tests using a known JDK class to verify reflection mechanics
- Integration tests building real Playwright option objects (guarded by JAR-present skip logic)

## 2. Deferred DSL Methods

Each method lives in `BrowserClient.cfc`. A `variables.$launcher` field is added, set during `init()` (BrowserTest already has the launcher in scope when creating the client).

### 2.1 Cookies

```cfm
setCookie(name, value, url)  → BrowserClient (chainable)
deleteCookie(name)           → BrowserClient (chainable)
cookie(name)                 → struct {name, value, domain, path, ...}
```

- `setCookie`: builds `com.microsoft.playwright.options.Cookie` via `$buildOption`, calls `context.addCookies(List.of(cookie))`
- `deleteCookie`: builds `BrowserContext$ClearCookiesOptions` with name filter (available since Playwright 1.43), calls `context.clearCookies(options)`
- `cookie`: calls `context.cookies()`, iterates returned `List<Cookie>` to find by name, returns struct with cookie properties. Throws `Wheels.BrowserAssertionFailed` if not found.

Cookies require a real HTTP origin (not `data:` URLs). Tests for these methods need either the fixture server (PR 3) or a minimal inline HTTP server. If too complex, tests can use `visitUrl("about:blank")` + JavaScript `document.cookie` as a workaround for basic coverage, with full HTTP-based tests deferred to PR 3.

### 2.2 Configurable Timeouts

Update existing `waitFor(selector, seconds)` and `waitForText(text, seconds)`:
- When `seconds != 30` (non-default): build `Locator$WaitForOptions` via `$buildOption({setTimeout: seconds * 1000})`, call `waitFor(options)`
- When `seconds == 30`: use zero-arg overload (fast path, no reflection)

### 2.3 waitForUrl

```cfm
waitForUrl(url, seconds=30)  → BrowserClient (chainable)
```

Builds `Page$WaitForURLOptions` with timeout via `$buildOption`. Calls `page.waitForURL(url, options)`. Supports exact URL strings and glob patterns (Playwright native).

### 2.4 Screenshot Options

Update existing `screenshot(path)`:

```cfm
screenshot(path, fullPage=false, quality=0)
```

When non-default options are passed, builds `Page$ScreenshotOptions` via `$buildOption`. Zero-arg fast path preserved when only `path` is given with defaults.

### 2.5 Viewport Config at BrowserTest Level

New property on spec CFCs:

```cfm
this.browserViewport = "mobile";          // preset
this.browserViewport = {width: 1024, height: 768};  // custom
```

`BrowserTest.$startBrowserContext()` reads `this.browserViewport`. If set:
1. Build `ViewportSize` via `$buildOption` with width/height
2. Build `Browser$NewContextOptions` via `$buildOption` with `{setViewportSize: viewportObj}`
3. Pass options to `browser.newContext(options)` instead of zero-arg overload

Presets: `"mobile"` (375x667), `"tablet"` (768x1024), `"desktop"` (1440x900).

### 2.6 Not in PR 2

| Feature | Reason | Target |
|---------|--------|--------|
| Dialogs (acceptDialog, dismissDialog, typeInDialog) | Needs `createDynamicProxy` for `Consumer<Dialog>` | PR 3 |
| loginAs / logout | Needs fixture server + test-only routes | PR 3 |
| visitRoute / assertRouteIs | Needs `urlFor` outside controller context | PR 3 |

## 3. CLI Commands

### 3.1 `wheels browser:install`

Replaces `tools/install-playwright.sh` with a framework-native command.

**CommandBox:** `cli/src/commands/wheels/browser/install.cfc` extending `../base`
**LuCLI:** `public string function browser()` on `Module.cfc` dispatching `install` subcommand to private `browserInstall(args)`

**Behavior:**
1. Read `vendor/wheels/browser-manifest.json`
2. Resolve install dir (env var `WHEELS_BROWSER_HOME` or `~/.wheels/browser`)
3. For each JAR in `classpath[]`: check if exists + SHA matches → skip; otherwise download via `cfhttp`/`curl`, verify SHA256 via `java.security.MessageDigest`
4. Run `java -cp <jars> com.microsoft.playwright.CLI install <browser>`
5. Print summary

**Flags:**
- `--force` — re-download even if SHAs match
- `--browser=chromium` — which browser (default: chromium)

**`tools/install-playwright.sh`:** Kept as fallback, deprecation notice added pointing to `wheels browser:install`.

### 3.2 `wheels browser:test`

Runs browser test directory with proper setup.

**CommandBox:** `cli/src/commands/wheels/browser/test.cfc`
**LuCLI:** Private `browserTest(args)` dispatched from `browser()`

**Behavior:**
1. Pre-flight: verify Playwright JARs installed. If missing, print helpful message and exit.
2. Hit test runner URL with `directory=wheels.tests.specs.wheelstest` (or user-specified) and `format=json`
3. Parse results, print summary

**Flags:**
- `--filter=<pattern>` — filter spec names
- `--format=json|text` — output format
- `--verbose` — full spec names

### 3.3 Shared Service

JAR download + SHA logic lives in `cli/src/models/BrowserService.cfc` (CommandBox) so both `install` and `test` (pre-flight) reuse it. LuCLI inlines the logic in Module.cfc private methods (no WireBox DI).

## 4. Auto-Screenshot + HTML Dump on Failure

### Mechanism

`browserDescribe()` registers an `aroundEach` hook alongside the existing `beforeEach`/`afterEach`:

```
aroundEach flow:
  1. beforeEach (creates context/page/client) — unchanged
  2. aroundEach:
     try { spec.body(data=arguments.data) }
     catch (any e) { capture screenshot + HTML; rethrow }
  3. afterEach (closes context) — unchanged
```

Rethrow preserves TestBox's normal failure reporting. Capture is additive.

### Artifact Output

- **Directory:** `tests/_output/browser/` (convention, created on first failure)
- **Configurable via:** `this.browserArtifactPath` on the spec CFC
- **Naming:** `<specName>-<timestamp>.png` and `<specName>-<timestamp>.html`
- **Spec name sanitized:** non-alphanumeric → underscore, truncated to 80 chars

### Guards

- Only captures if `this.browser` is populated and page is alive
- Nested try/catch around capture itself — swallows failures silently (don't mask real test failure)
- Checks `browserTestSkipped` flag — no capture when Playwright not installed

### Opt-out

```cfm
this.browserScreenshotOnFailure = false;  // default: true
```

## File Inventory

### New Files

| File | Purpose |
|------|---------|
| `cli/src/commands/wheels/browser/install.cfc` | CommandBox browser:install command |
| `cli/src/commands/wheels/browser/test.cfc` | CommandBox browser:test command |
| `cli/src/models/BrowserService.cfc` | Shared JAR download + SHA verification |

### Modified Files

| File | Changes |
|------|---------|
| `vendor/wheels/wheelstest/BrowserLauncher.cfc` | Add `$buildOption()` |
| `vendor/wheels/wheelstest/BrowserClient.cfc` | Add cookies, waitForUrl, update waitFor/waitForText/screenshot; accept `$launcher` in init |
| `vendor/wheels/wheelstest/BrowserTest.cfc` | Add `aroundEach` failure capture, viewport config, pass launcher to BrowserClient |
| `cli/lucli/Module.cfc` | Add `browser()` public function with install/test dispatch |
| `tools/install-playwright.sh` | Add deprecation notice |
| `vendor/wheels/tests/specs/wheelstest/BrowserLauncherSpec.cfc` | Tests for `$buildOption` |
| `vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc` | Tests for new DSL methods |
| `vendor/wheels/tests/specs/wheelstest/BrowserTestLifecycleSpec.cfc` | Tests for auto-screenshot, viewport config |

### Untouched

| File | Why |
|------|-----|
| `browser-manifest.json` | No version bump needed |
| `vendor/wheels/tests/fixtures/browserapp/` | Expanded in PR 3 (loginAs, fixture server) |

## Unresolved Questions

1. **Cookie tests without fixture server** — can we get meaningful coverage with `about:blank` + `document.cookie`, or should we defer cookie tests to PR 3 when the fixture server lands?
2. **`aroundEach` + TestBox compatibility** — need to verify `aroundEach` works inside a dynamically-registered describe body (same pattern as beforeEach/afterEach in `browserDescribe`). If not, fallback is wrapping in afterEach with a caught-error flag.
3. **`BrowserContext$ClearCookiesOptions`** — need to verify the exact inner-class path in Playwright 1.52. If the API changed, `deleteCookie` may need to clear-all + re-add others.
