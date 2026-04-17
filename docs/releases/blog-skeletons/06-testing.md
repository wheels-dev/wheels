---
status: skeleton
slot: post 6 (week 2–3; pairs with LuCLI post)
target_length: 1400–1700 words
---

# Testing in Wheels 4.0

**Subhead / dek:** *HTTP integration tests, parallel runners, and full-browser Playwright — the category that was most embarrassing in 3.0 is the most complete in 4.0.*

**Target audience:**
- QA engineers evaluating CFML frameworks
- Developers who've been writing integration tests with curl + bash
- Teams considering Cypress/Playwright but wanting a unified CFML testing story
- Existing Wheels teams wondering whether BDD-only is worth the migration

**Lead paragraph intent:**
- In 3.0, Wheels testing was RocketUnit specs and custom harnesses.
- In 4.0, Wheels testing is a full pyramid: unit (WheelsTest BDD) + integration (HTTP TestClient) + end-to-end (Playwright-backed BrowserTest) — run in parallel.
- This post walks each layer with a concrete example, then discusses the BDD-only stance.

## Sections

### 1. "The test pyramid, finally complete"
- Unit tests exist in every framework; that's table stakes.
- Integration and E2E were the gaps. Both land in 4.0 — natively, not via third-party bridges.
- Running them fast: parallel by default.

### 2. Unit tests — WheelsTest BDD
- `wheels.WheelsTest` replaces `wheels.Test` as the canonical base class ([#1889](https://github.com/wheels-dev/wheels/pull/1889)).
- `describe()` / `it()` / `expect()` — familiar BDD syntax.
- RocketUnit retained for legacy specs but deprecated for new work ([#1925](https://github.com/wheels-dev/wheels/pull/1925)).
- Tests directory renamed to `tests/specs/functional/` ([#1872](https://github.com/wheels-dev/wheels/pull/1872)).

### 3. Integration — HTTP TestClient
- `TestClient.visit("/users").assertOk().assertSee("John")` — fluent, familiar from Laravel/Rails test clients.
- Assertions: status codes, body content (`assertSee`, `assertDontSee`, `assertSeeInOrder`), JSON responses (`assertJson`, `assertJsonPath` with dot notation), redirects, headers, cookies.
- Cookies tracked across requests → session support.
- PR: [#2099](https://github.com/wheels-dev/wheels/pull/2099).
- Use case: test a full request/response cycle without a browser.

### 4. End-to-end — BrowserTest (Playwright Java)
- Extend `wheels.wheelstest.BrowserTest`; get `this.browser` as a fluent DSL wrapping Playwright Java.
- Install once: `wheels browser:install` — ~370MB (JARs + Chromium).
- ~60 DSL methods: navigation, interaction (`click`, `fill`, `select`, `attach`, `dragAndDrop`), keyboard, waiting (`waitFor`, `waitForText`, `waitForUrl`), scoping (`within`), cookies, auth (`loginAs`, `logout`), dialogs (Lucee-only), viewport (`resize`, `resizeToMobile`), script, screenshots, full assertion suite.
- Shipped across [#2113](https://github.com/wheels-dev/wheels/pull/2113), [#2115](https://github.com/wheels-dev/wheels/pull/2115), [#2116](https://github.com/wheels-dev/wheels/pull/2116), [#2121](https://github.com/wheels-dev/wheels/pull/2121), [#2122](https://github.com/wheels-dev/wheels/pull/2122).
- CI runs browser specs in `pr.yml` and `snapshot.yml` with Playwright JARs + Chromium cached.
- Caveat: dialogs use `createDynamicProxy` which is Lucee-specific; specs skip gracefully on other engines.

### 5. Parallel — ParallelRunner
- PR: [#2100](https://github.com/wheels-dev/wheels/pull/2100).
- Discovers bundles, round-robin partitions them across N workers, fires parallel HTTP requests via `cfthread`, aggregates JSON results.
- Configurable worker count and timeout.
- Cuts suite time on multi-core CI runners.

### 6. "Why BDD-only for new tests?"
- Signals intent clearly: `describe("User.valid()", () => { it("requires email", ...) })` reads top-to-bottom.
- Consolidates on one style — dual-stack testing confused contributors.
- Legacy RocketUnit specs continue to run; nobody has to migrate. New specs should follow the BDD pattern.

### 7. A critical-path test, end-to-end in 50 lines
- Skeleton example: login → create a record → verify it appears in the list → delete it → verify it's gone.
- Show the BrowserTest equivalent using `loginAs()`, `fill()`, `click()`, `assertSee()`.
- 15-minute setup, lifetime of regression coverage. Call out that this replaces manual QA for the 5-10 critical journeys in most apps.

### 8. Hard-won gotchas (short list)
- **`##` in selectors** — CFML requires `##` to emit literal `#`. `"##email"` → `"#email"` at runtime.
- **`client` is a Lucee reserved scope.** Use `var c = ...` or `var bc = ...` instead of `var client`.
- **`this.browserTestSkipped`** — when Playwright JARs aren't installed, `beforeAll` sets this flag; all `it`s should short-circuit to stay green.
- **Data URLs work for most tests** — no fixture server needed for ~95% of DSL coverage.
- Reference: [`.ai/wheels/testing/browser-testing.md`](https://github.com/wheels-dev/wheels/blob/develop/.ai/wheels/testing/browser-testing.md).

### 9. Test data, fixtures, and populate.cfm
- `tests/populate.cfm` remains the DROP + CREATE + seed harness.
- Test models live in `tests/_assets/models/`.
- LuCLI + SQLite for local runs; full matrix DBs for CI.

## Code / config snippets to include (pick 3)

```cfm
// Unit — WheelsTest BDD
component extends="wheels.WheelsTest" {
    function run() {
        describe("User", () => {
            it("validates presence of email", () => {
                var u = model("User").new();
                expect(u.valid()).toBeFalse();
            });
        });
    }
}
```

```cfm
// Integration — HTTP TestClient
component extends="wheels.WheelsTest" {
    function run() {
        describe("GET /users", () => {
            it("lists users", () => {
                TestClient.visit("/users")
                    .assertOk()
                    .assertSee("John")
                    .assertJsonPath("data[0].email", "john@example.com");
            });
        });
    }
}
```

```cfm
// End-to-end — BrowserTest with loginAs + critical-path assertion
component extends="wheels.wheelstest.BrowserTest" {
    this.browserEngine = "chromium";

    function run() {
        browserDescribe("Create a user via the admin UI", () => {
            it("creates and lists a user", () => {
                if (this.browserTestSkipped) return;
                this.browser
                    .loginAs({email: "admin@example.com"})
                    .visit("/admin/users/new")
                    .fill("##name", "Alice")
                    .fill("##email", "alice@example.com")
                    .click("button[type=submit]")
                    .assertUrlContains("/admin/users")
                    .assertSee("Alice");
            });
        });
    }
}
```

## Suggested visuals

- **Test pyramid:** classic triangle — unit (wide base: WheelsTest BDD) / integration (middle: TestClient) / E2E (tip: BrowserTest). Label each layer with the Wheels-specific API.
- **Screenshot:** parallel runner output showing workers claiming bundles, final aggregate summary.
- **Before/after (3.0 vs 4.0):** checklist matrix — unit / integration / E2E / parallel / BDD syntax. 3.0 column mostly empty; 4.0 column mostly checked.

## Outro / CTA

- "You can reach your first green browser test in under half an hour."
- Link to `docs/src/working-with-wheels/testing-your-application.md`.
- Link to `.ai/wheels/testing/browser-testing.md` for the deep reference.
- Note BrowserTest is Chromium-only at 4.0 launch; Firefox/WebKit are roadmap.

## Citations (must link in final post)

- [TestClient PR #2099](https://github.com/wheels-dev/wheels/pull/2099)
- [ParallelRunner PR #2100](https://github.com/wheels-dev/wheels/pull/2100)
- [BrowserTest PRs #2113, #2115, #2116, #2121, #2122](https://github.com/wheels-dev/wheels/pull/2113)
- [WheelsTest namespace #1889](https://github.com/wheels-dev/wheels/pull/1889)
- [RocketUnit deprecation #1925](https://github.com/wheels-dev/wheels/pull/1925)
- `docs/src/working-with-wheels/testing-your-application.md`
- `.ai/wheels/testing/browser-testing.md`
