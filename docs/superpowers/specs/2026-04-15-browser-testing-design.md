# Browser Testing — Design

**Status:** Approved
**Date:** 2026-04-15
**Target release:** Wheels v4.0
**Closes:** Item 4 in `docs/wheels-vs-frameworks.md` "Where Wheels Trails"

## 1. Problem

Wheels has first-class HTTP integration testing via `TestClient.cfc`
(`visit/get/post/assertOk/assertSee/assertJson`), but no native browser
automation. Rails ships System Tests (Capybara + Selenium), Laravel ships
Dusk, Spring ships Selenium/Playwright integration. A Wheels app that
wants to test a login form end-to-end, a Hotwire Turbo Frame update, or
any JS-driven flow has to assemble external tooling from scratch.

This design adds native browser testing to Wheels, modeled on Laravel
Dusk's ergonomics but built on Playwright Java for better cross-browser
coverage and JVM-native integration.

## 2. Goals

1. **Fluent DSL** (`BrowserClient.cfc`) that mirrors `TestClient.cfc`'s
   shape — same naming conventions (`visit`, `assertSee`, `assertDontSee`),
   same chainable pattern, same terminal accessors.
2. **TestBox integration** via a `BrowserTest.cfc` base class that manages
   Playwright lifecycle invisibly — spec writers never see
   `Playwright.create()` or `browser.newContext()`.
3. **`loginAs` ergonomics** via a test-only route + `storageState` hook,
   so specs don't spend 5-10 lines logging in before every test.
4. **Multi-browser support** (Chromium default, Firefox/WebKit opt-in via
   `wheels browser:install --browsers=...`) with one engine per spec CFC.
5. **CLI integration** — `wheels browser:install` for one-time setup,
   `wheels browser:test` for running specs, with optional `--managed`
   flag to auto-spawn LuCLI.
6. **MCP integration** — new `wheels_browser_install`,
   `wheels_browser_test`, `wheels_browser_status` tools.
7. **Dogfooding** — `packages/hotwire/` gets browser specs that exercise
   Turbo Frame, Turbo Stream, and Stimulus flows using the new DSL.

## 3. Non-goals (v4.0)

- **Adobe CF and BoxLang support.** Classloader risk deferred to a future
  sprint. v4.0 targets Lucee 7 only.
- **MySQL / PostgreSQL / SQL Server as browser-test DB.** SQLite only for
  v4.0 to keep CI and inner-loop fast.
- **Parallel browser test execution.** `ParallelRunner.cfc` works for HTTP
  tests; browser adds port-collision complexity. v4.1.
- **Multi-engine per spec CFC** (same `it` block running against Chromium,
  Firefox, and WebKit in one go). v4.1.
- **`wheels-plugin-auth` default `$signInAsForBrowserTest` implementation.**
  The auth plugin doesn't exist as a package yet. Apps implement the hook
  themselves in v4.0.
- **`@testid` selector shortcut.** Wait for a convention to emerge.
- **Touch / mobile tap methods.** v4.1+ if mobile testing grows.
- **`wheels generate browser-test` scaffold generator.** Nice-to-have; v4.1.

## 4. Architecture

Three new components, each with one responsibility. Boundaries are
deliberate — `BrowserClient` knows nothing about TestBox,
`BrowserTest` knows nothing about Playwright internals, CLI knows
nothing about either.

```
┌─────────────────────────────────────────────────────────────┐
│  tests/specs/browser/LoginBrowserSpec.cfc                   │
│  (user-written — extends wheels.BrowserTest)                │
└──────────────────┬──────────────────────────────────────────┘
                   │ this.browser (fluent DSL)
                   ▼
┌─────────────────────────────────────────────────────────────┐
│  vendor/wheels/wheelstest/BrowserClient.cfc                 │
│  Fluent DSL: visit/click/fill/assertSee/assertUrlIs/...     │
│  Wraps one Playwright BrowserContext + Page pair.           │
└──────────────────┬──────────────────────────────────────────┘
                   │ CreateObject("java", "com.microsoft.playwright.*")
                   ▼
┌─────────────────────────────────────────────────────────────┐
│  vendor/wheels/wheelstest/BrowserLauncher.cfc               │
│  Process singleton. Holds one Playwright + one Browser per  │
│  test run. Loads JAR via this.javaSettings dynamically.     │
└──────────────────┬──────────────────────────────────────────┘
                   │ JAR classpath
                   ▼
┌─────────────────────────────────────────────────────────────┐
│  ~/.wheels/browser/lib/playwright-java-1.45.0.jar (~50MB)   │
│  Includes bundled Node.js driver (invisible to user)        │
└──────────────────┬──────────────────────────────────────────┘
                   │ IPC to bundled Node driver
                   ▼
┌─────────────────────────────────────────────────────────────┐
│  Chromium / Firefox / WebKit browser binaries               │
│  Installed to ~/.wheels/browser/browsers/ by                │
│  `wheels browser:install`                                   │
└─────────────────────────────────────────────────────────────┘
```

### 4.1 Component responsibilities

| Component | Path | Responsibility |
|---|---|---|
| `BrowserClient.cfc` | `vendor/wheels/wheelstest/BrowserClient.cfc` | Fluent DSL for one browser session. Wraps Playwright `BrowserContext` + `Page`. Mirrors `TestClient.cfc`'s shape. No TestBox coupling. |
| `BrowserTest.cfc` | `vendor/wheels/wheelstest/BrowserTest.cfc` | TestBox base class extending `wheels.WheelsTest`. Manages per-`it` context lifecycle via `beforeEach`/`afterEach`. Provides `this.browser`, `this.keepSignedInAs`, `this.browserViewport`, `this.screenshotOnFailure`, `this.traceOnFailure`, `this.browserEngine`. |
| `BrowserLauncher.cfc` | `vendor/wheels/wheelstest/BrowserLauncher.cfc` | Process-level singleton. Holds the one `Playwright` instance and one `Browser` per test run. Discovers JAR path from `WHEELS_BROWSER_HOME` env var, then `~/.wheels/browser/lib/`. Integrates with Lucee's `this.javaSettings`. |
| `wheels browser:install` | `vendor/wheels/cli/commands/browser/install.cfc` | Downloads Playwright Java JAR + runs `playwright install <browsers>`. Writes `~/.wheels/browser/` layout. |
| `wheels browser:test` | `vendor/wheels/cli/commands/browser/test.cfc` | Preflight checks, optional LuCLI spawn via `--managed`, invokes existing test runner against `tests/specs/browser/`. |
| Test-only login route | Registered in `vendor/wheels/routes.cfm` | `POST /_browser/login-as` with `identifier` in request body. Only active when `get("environment") == "testing"`. Delegates to app-defined `$signInAsForBrowserTest(identifier)`. |

### 4.2 Key architectural decisions

- **JAR lives in `~/.wheels/browser/`, not `vendor/`.** Keeps the framework
  repo ~50MB lighter. Same pattern as Playwright's own browser cache.
  `wheels browser:install` is a one-time per-dev-machine step.
- **Classloader loading via `this.javaSettings` in `Application.cfc`.**
  Lucee-specific, fine for v4.0 (Adobe deferred). `BrowserLauncher`
  verifies JAR presence at init and fails loud with a clear error if
  missing.
- **`BrowserLauncher` as process singleton.** `Playwright.create()` is
  ~1-2s; doing it once per test run vs. per spec CFC is the difference
  between tests finishing in 30s and 5min.
- **No coupling between `BrowserClient` and TestBox.** Someone could use
  `BrowserClient` standalone from a controller or job.

## 5. BrowserClient DSL

### 5.1 Usage example

```cfm
// tests/specs/browser/LoginBrowserSpec.cfc
component extends="wheels.BrowserTest" {
    function run() {
        describe("Login flow", () => {
            it("signs in an existing user", () => {
                this.browser
                    .visit("/login")
                    .fill("##email", "alice@example.com")
                    .fill("##password", "secret")
                    .click("button[type=submit]")
                    .assertUrlIs("/dashboard")
                    .assertSee("Welcome, Alice");
            });

            it("rejects bad credentials", () => {
                this.browser
                    .visit("/login")
                    .fill("##email", "alice@example.com")
                    .fill("##password", "wrong")
                    .click("button[type=submit]")
                    .assertUrlIs("/login")
                    .assertSee("Invalid credentials");
            });
        });
    }
}
```

### 5.2 Method catalog (~35 methods)

**Navigation**
- `visit(path)` — navigate to path (relative to baseUrl)
- `visitRoute(name, params={})` — navigate via named route
- `back()` / `forward()` / `refresh()`

**Interaction**
- `click(selector)` — click first matching element; auto-waits for actionable
- `press(buttonText)` — find button by visible text and click
- `fill(selector, value)` — set input value instantly (fast path)
- `type(selector, value)` — simulate keystrokes (for autocomplete / char-count
  validation)
- `clear(selector)` — clear input value
- `select(selector, value)` — choose option in `<select>`
- `check(selector)` / `uncheck(selector)` — checkbox/radio
- `attach(selector, filePath)` — file upload
- `dragAndDrop(fromSelector, toSelector)` — drag source to target

**Keyboard**
- `keys(selector, ...keys)` — `.keys("##search", "{enter}")`
- `pressEnter()` / `pressTab()` / `pressEscape()` — sugar over `keys`

**Dialogs**
- `acceptDialog()` — accept next native confirm/alert
- `dismissDialog()` — dismiss next native confirm
- `typeInDialog(text)` — respond to native prompt

**Waiting**
- `waitFor(selector, seconds=5)`
- `waitForText(text, seconds=5)`
- `waitForUrl(path, seconds=5)`

**Scoping**
- `within(selector, callback)` — scope subsequent selectors to subtree.
  Callback receives a scoped BrowserClient.

**Viewport**
- `resize(width, height)`
- `resizeToMobile()` — 375×667
- `resizeToTablet()` — 768×1024
- `resizeToDesktop()` — 1440×900

**Auth**
- `loginAs(identifier)` — call test-only route, set session cookie.
  `identifier` is passed through to the app's `$signInAsForBrowserTest`
  hook unchanged (can be a numeric user ID, an email, or any value the
  app's resolver accepts).
- `logout()` — clear session cookies from context

**Debug / escape**
- `script(js)` — run arbitrary JS in page context, return result
- `pause(milliseconds)` — DEBUG ONLY; CI fails if detected unless
  `BROWSER_TEST_PAUSE_WARNING=off`

**Cookies**
- `setCookie(name, value)` / `deleteCookie(name)` / `cookie(name)`

**Assertions**
- `assertSee(text)` / `assertDontSee(text)`
- `assertSeeIn(selector, text)`
- `assertUrlIs(path)` / `assertRouteIs(name, params={})`
- `assertQueryStringHas(key, value="")` / `assertQueryStringMissing(key)`
- `assertTitleContains(text)`
- `assertVisible(selector)` / `assertMissing(selector)` — visible ≠ present
- `assertPresent(selector)` / `assertNotPresent(selector)` — DOM presence
  regardless of display
- `assertInputValue(selector, value)`
- `assertChecked(selector)`
- `assertHasClass(selector, class)`

**Terminals** (for `expect()` drop-out)
- `currentUrl()` / `title()` / `pageSource()` / `text(selector)` /
  `value(selector)` / `screenshot(path)`

### 5.3 Design decisions

- **`fill` vs `type` distinction preserved** (Playwright convention).
  `fill` sets value instantly (95% case), `type` simulates keystrokes
  (autocomplete, char-count validation).
- **`within(selector, callback)` over `scope()/unscope()`.** Lexical
  boundary prevents forgotten-unscope bugs. Callback receives a scoped
  client; chain resumes after.
- **Selectors are raw CSS.** No `@name` shortcut. Tests requiring stable
  selectors use `data-testid="..."` and `[data-testid=foo]`.
- **`assertRouteIs(name, params)` uses `urlFor()` internally.** Tests
  survive URL structure changes.
- **No mouse-positioning methods** (`mouseover`, `clickAtPoint`). Rare;
  `script()` is the fallback.

## 6. BrowserTest base class

### 6.1 Hooks and properties

```cfm
component extends="wheels.WheelsTest" {
    // All optional; sensible defaults
    this.keepSignedInAs = "";          // identifier passed to $signInAsForBrowserTest; non-empty triggers storageState reuse
    this.browserViewport = "desktop";  // "desktop" | "tablet" | "mobile" | struct{w,h}
    this.browserEngine = "chromium";   // "chromium" | "firefox" | "webkit"
    this.screenshotOnFailure = true;   // dump PNG to tests/_artifacts/
    this.traceOnFailure = false;       // dump Playwright trace.zip (slower, richer)
    this.browser = "";                 // populated in beforeEach — the BrowserClient

    function beforeAll() { ... }
    function beforeEach() { ... }
    function afterEach() { ... }
    function afterAll() { ... }
}
```

### 6.2 Lifecycle

| Hook | Action | Cost |
|---|---|---|
| `beforeAll` (once per spec CFC) | `BrowserLauncher.acquireBrowser(engine=this.browserEngine)` — returns process-level singleton. If `this.keepSignedInAs` set, logs that user in via test-only route, captures `storageState` into `variables.$savedState`. | ~1-2s first spec CFC; ~10ms thereafter |
| `beforeEach` (per `it` block) | `context = browser.newContext(storageState=$savedState, viewport=...)`, `page = context.newPage()`, wire both into fresh `BrowserClient`, assign to `this.browser`. | ~15ms |
| `afterEach` (per `it` block) | On failure: dump screenshot to `tests/_artifacts/{run}/{specName}/{itName}.png`, dump HTML source, optionally trace.zip. Close context. | ~20ms |
| `afterAll` (once per spec CFC) | Release browser handle (Playwright itself stays alive for next spec). | ~5ms |

### 6.3 `loginAs` flow

Two complementary patterns; choose per-spec based on need:

**Pattern A — `this.keepSignedInAs` property** (once per spec CFC).
Every `it` in the spec starts as that user. Uses `storageState` replay
for speed.

```cfm
component extends="wheels.BrowserTest" {
    this.keepSignedInAs = 42;  // passed to app's $signInAsForBrowserTest hook

    function run() {
        describe("Admin dashboard", () => {
            it("shows user list", () => {
                this.browser.visit("/admin/users").assertSee("Users");
            });
        });
    }
}
```

**Pattern B — `this.browser.loginAs(userId)` mid-test** (ad-hoc).
Use when different `it` blocks need different users, or the test itself
exercises login.

```cfm
it("admin sees edit buttons, member does not", () => {
    this.browser.loginAs(adminId).visit("/posts/1").assertVisible(".edit");
    this.browser.logout().loginAs(memberId).visit("/posts/1").assertMissing(".edit");
});
```

### 6.4 Test-only login route

Registered in `vendor/wheels/routes.cfm` with an environment guard:

```cfm
// Inside mapper() chain, before .wildcard()
if (get("environment") == "testing") {
    .post(name="wheelsBrowserTestLogin",
          pattern="/_browser/login-as",
          to="wheels.wheelstest.BrowserTestLoginController##loginAs")
}
```

The controller reads `params.identifier` from the POST body and passes
it through to `$signInAsForBrowserTest`. Body transport avoids URL
encoding concerns when the identifier contains special characters
(e.g., `admin@example.com`).

**Safety layers:**

1. Route only registered when `environment == "testing"`. Same guard
   pattern used by the dev toolbar.
2. Startup check in `BrowserLauncher` logs a loud warning if the route
   is detected in production mode (belt-and-suspenders).
3. Controller delegates to app-defined `$signInAsForBrowserTest(userId)`
   — app provides the actual auth logic. If app hasn't defined it,
   route returns 501 Not Implemented with clear error.

**App implementation contract** (docs in
`.ai/wheels/testing/browser-testing.md`):

```cfm
// app/events/onapplicationstart.cfm or a dedicated app/events/browsertest.cfm
function $signInAsForBrowserTest(required any identifier) {
    // App fills in: look up user (by id, email, or custom), set session, etc.
    // arguments.identifier is whatever the test passed to
    // this.browser.loginAs() or this.keepSignedInAs (no coercion).
    session.userId = arguments.identifier;
}
```

## 7. CLI + installation

### 7.1 `wheels browser:install`

One-time per developer machine; idempotent.

```bash
wheels browser:install                              # default: chromium only
wheels browser:install --browsers=chromium,firefox
wheels browser:install --all                        # all three
wheels browser:install --add=webkit                 # add to existing
wheels browser:install --remove=firefox             # reclaim disk
wheels browser:install --force                      # re-download even if present
```

Output:
```
Installing Playwright Java browser automation...

✓ Java 21 detected
✓ Downloading playwright-1.45.0.jar (49.2 MB)
✓ Verified SHA256 (pinned in vendor/wheels/browser-manifest.json)
✓ Installing Chromium 127.0.6533.17 (130 MB, to ~/.wheels/browser/browsers/)
✓ Writing ~/.wheels/browser/version

Installed to ~/.wheels/browser/.

Add this to your app's Application.cfc this.javaSettings.loadPaths:
  getUserHome() & "/.wheels/browser/lib/"

Or set BROWSER_TEST_AUTO_LOAD=true in .env (done automatically for
LuCLI dev servers).
```

### 7.2 Install layout

```
~/.wheels/browser/
├── lib/
│   └── playwright-java-1.45.0.jar          # ~50MB (JAR + bundled Node)
├── browsers/
│   ├── chromium-1124/                      # ~300MB on disk
│   ├── firefox-1440/                       # ~180MB (optional)
│   └── webkit-2033/                        # ~200MB (optional)
├── version                                  # "1.45.0"
├── manifest.json                            # SHA256s, pinned versions
└── install.log
```

### 7.3 Browser sizes (reference)

| Browser | Download | Disk after extract |
|---|---|---|
| Chromium | ~130 MB (macOS), ~170 MB (Linux) | ~300 MB |
| Firefox | ~80 MB | ~180 MB |
| WebKit | ~70 MB | ~200 MB |
| **All three** | **~280 MB** | **~680 MB** |

The Playwright Java JAR itself is ~50MB regardless of which browsers are
installed.

### 7.4 Pinned versions

`vendor/wheels/browser-manifest.json` (checked into repo):

```json
{
    "playwrightJavaVersion": "1.45.0",
    "playwrightJavaJar": {
        "url": "https://repo1.maven.org/maven2/com/microsoft/playwright/playwright/1.45.0/playwright-1.45.0.jar",
        "sha256": "..."
    },
    "browsers": {
        "chromium": "1124",
        "firefox": "1440",
        "webkit": "2033"
    }
}
```

Updating Playwright = bumping the manifest + re-testing. No
"works on my machine" surprises.

### 7.5 `wheels browser:test`

```bash
wheels browser:test                           # assumes server on :8080
wheels browser:test --managed                 # spawns LuCLI on ephemeral port
wheels browser:test --managed --port=8090     # specific port
wheels browser:test --directory=tests/specs/browser/login/
wheels browser:test --spec=LoginBrowserSpec
wheels browser:test --headed                  # visible browser (debug)
wheels browser:test --pause-on-failure        # halt on first fail, browser stays open
```

**Under the hood:**

1. Preflight: `~/.wheels/browser/` populated? Java version ok?
   If not: "run wheels browser:install" and exit non-zero.
2. If `--managed`: start LuCLI server on ephemeral port, set baseUrl.
3. Clean `tests/_artifacts/` of stale runs (respecting `--keep-runs=N`).
4. Invoke existing test runner (same infra as `wheels test run`)
   pointing at `tests/specs/browser/` (or `--directory`).
5. If `--managed`: stop LuCLI server, forward exit code.
6. Print summary + artifact locations for failures.

**Why separate from `wheels test run`:** preconditions matter.
`wheels test run` should stay lightweight. Browser tests have a hard
prerequisite (JAR must be installed). A distinct command enforces that
with a fast, loud failure path.

**No auto-install on first `wheels browser:test`.** A 150MB download
happening "magically" is a bad surprise. Dev runs install consciously
(matches `npm install` behavior).

### 7.6 MCP tools

Three additions to `/wheels/mcp`:

- `wheels_browser_install(browsers="chromium", force=false)` — runs install
- `wheels_browser_test(directory="tests.specs.browser", managed=true, spec="", engine="chromium")` — runs browser specs
- `wheels_browser_status()` — reports install state, pinned version,
  detected Java, cached browser binaries

The MCP `wheels_test()` tool stays as-is (non-browser specs). Browser
tests get their own tool because their semantics differ enough that
collapsing would hide the cost.

### 7.7 `tools/test-local.sh` integration

New `browser` target:

```bash
bash tools/test-local.sh browser    # preflight, then --managed mode
```

Checks `~/.wheels/browser/`, errors with install instructions if
missing (doesn't auto-install — too slow for inner loop).

## 8. Artifacts on failure

### 8.1 Directory structure

```
tests/_artifacts/
└── 2026-04-15-142301/                      # timestamped run dir
    ├── LoginBrowserSpec/
    │   ├── rejects-bad-credentials.png
    │   ├── rejects-bad-credentials.html
    │   └── rejects-bad-credentials.trace.zip   # only if traceOnFailure=true
    ├── CheckoutBrowserSpec/
    │   └── ...
    └── summary.json                        # failures, timings, trace paths
```

Timestamped run dirs so yesterday's failure artifacts aren't lost.
`--keep-runs=5` trims to last N. `.gitignore` gets `tests/_artifacts/`.

### 8.2 Failure output

```
✗ LoginBrowserSpec > rejects bad credentials (1.2s)
  AssertionError: expected to see "Invalid credentials" but page contained "Server error"
  Screenshot: tests/_artifacts/2026-04-15-142301/LoginBrowserSpec/rejects-bad-credentials.png
  Page source: tests/_artifacts/2026-04-15-142301/LoginBrowserSpec/rejects-bad-credentials.html
```

Paths are clickable in modern terminals (iTerm2, VS Code).

## 9. Testing the framework feature itself

Three layers:

| Layer | Location | What it proves |
|---|---|---|
| Unit | `vendor/wheels/tests/specs/wheelstest/BrowserClientSpec.cfc` | Each DSL method calls the correct Playwright Java method with correct args (mocked `Page`). No browser launch. Fast. |
| Integration | `vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc` | Real Chromium launch. Exercises `BrowserLauncher` singleton, `BrowserTest` lifecycle, `loginAs`, storageState replay. Uses fixture app in `vendor/wheels/tests/fixtures/browserapp/`. |
| Dogfood | `packages/hotwire/tests/specs/browser/` | ~8 browser specs for wheels-hotwire: Turbo Frame updates, Turbo Stream broadcasts, Stimulus controllers activating, form submissions without full reload. |

The dogfood layer is where the design justifies itself. If
wheels-hotwire specs are noisy, we iterate on the DSL before v4.0 ships.

## 10. Rollout

### 10.1 PR split

| PR | Scope | Approx LOC |
|---|---|---|
| **1. Foundation** | `BrowserLauncher.cfc`, `BrowserClient.cfc`, `BrowserTest.cfc`, `browser-manifest.json`, unit + integration tests, `BrowserTestLoginController.cfc`, route registration | ~2500 |
| **2. CLI + install** | `wheels browser:install`, `wheels browser:test`, MCP tools, `tools/test-local.sh browser target` | ~800 |
| **3. Hotwire dogfood** | 8 browser specs for `packages/hotwire/`, minor hotwire fixes surfaced by testing | ~500 |
| **4. CI + docs** | GitHub Actions `browser-tests` job (soft-fail initially), `.ai/wheels/testing/browser-testing.md`, CLAUDE.md section, changelog | ~300 |

Each PR independently reviewable and mergeable. If a PR blocks,
subsequent ones can land behind the partial foundation (the DSL works
without CI; docs stand alone).

### 10.2 CI integration

New `browser-tests` job in `.github/workflows/tests.yml`:

- Runs only on Lucee 7 + SQLite for v4.0 (per Section 3 scope).
- Caches `~/.wheels/browser/` by `browser-manifest.json` hash — JAR +
  Chromium download happens once per manifest bump, not per build.
- **Soft-fail for the first 2 weeks after merge**, same pattern
  CockroachDB followed. Promoted to hard-fail only after a green streak
  demonstrates stability.

### 10.3 Multi-engine CI (optional)

Separate `browser-tests-multi-engine` job runs on nightly schedule or
release candidates only. Exercises Firefox + WebKit. Does not block
normal builds.

## 11. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Playwright Java JAR has classloader issues under some Lucee 7 configs | Integration specs run on lucee7 matrix; also verified manually against a real Lucee 7 deployment before PR merge |
| Flaky tests erode trust | Soft-fail in CI initially; promote to hard-fail only after 2-week green streak |
| Test-only `loginAs` route accidentally enabled in production | Environment guard (`get("environment") == "testing"`); startup warning if detected in production mode; controller returns 501 if app hasn't defined `$signInAsForBrowserTest` |
| Install flow confuses first-time users | Dedicated `.ai/wheels/testing/browser-testing.md` doc; error messages that link to it; `wheels browser:status` MCP tool for diagnosis |
| Disk use balloons (all three browsers = ~680MB) | Opt-in via `--browsers=` flag; Chromium-only default; `--remove=firefox` reclaims |
| Users on Java < 21 | Preflight check in `wheels browser:install` fails with clear version requirement |

## 12. Documentation

- `.ai/wheels/testing/browser-testing.md` — reference doc (DSL method
  table, setup walkthrough, failure-artifact guide, `$signInAsForBrowserTest`
  contract, common pitfalls)
- `CLAUDE.md` — new "Browser Testing" section summarizing the runner
  URL, DSL, install steps
- `packages/hotwire/README.md` — example browser spec in the package
  readme
- Changelog entry under v4.0 release notes

## 13. Open questions (minor)

- Do we pin Chromium to a specific version in `browser-manifest.json`,
  or use Playwright's default per JAR version? Leaning pin for
  reproducibility.
- Should `wheels browser:status` be under the MCP `wheels_browser_status`
  tool only, or also a CLI command? Leaning both (trivial cost, useful
  for CI preflight).
- Artifact retention default: `--keep-runs=5` or `--keep-runs=10`?
  Leaning 5 for disk friendliness.
