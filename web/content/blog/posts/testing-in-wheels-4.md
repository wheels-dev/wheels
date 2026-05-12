---
title: Testing in Wheels 4.0
slug: testing-in-wheels-4
publishedAt: '2026-05-08T14:00:00.000Z'
updatedAt: '2026-05-07T02:00:09.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - testing
  - playwright
  - bdd
categories: []
excerpt: >-
  Wheels 4.0 completes the test pyramid: BDD unit tests, a fluent HTTP
  TestClient for integration, and Playwright-powered browser automation for
  end-to-end — all running in parallel. The category that was most
  embarrassing in 3.0 is the most complete in 4.0.
coverImage: null
---

If you have been writing integration tests for a Wheels app with `curl` and bash, or verifying critical paths by clicking through the browser yourself, Wheels 4.0 is the release where that stops.

The framework ships with three testing layers, all first-class, all in the core distribution: BDD unit tests, an HTTP TestClient for integration, and a Playwright-driven browser DSL for end-to-end. They run in parallel on multi-core runners. They share one base class, one test runner, and one reporter. Across roughly 15 weeks and 260+ merged PRs, testing is the category that moved furthest — and the one that, honestly, most needed it.

## The test pyramid, finally complete

Unit tests have always been table stakes. Every framework ships with them. Wheels 3.0 had RocketUnit, and later added a BDD layer, and that was fine for testing model validations and controller helpers in isolation.

The gaps were integration and end-to-end. If you wanted to assert that `GET /users` returned a 200 and contained "John", you wrote a shell script. If you wanted to confirm that logging in, creating a record, and seeing it in the list actually worked as a user would experience it, you either did not test it or you wired in Selenium from scratch.

In 4.0 both of those are first-class. Not through a plugin, not through a third-party bridge — in the core distribution, extending the same base class, discoverable by the same runner, reported through the same JSON format. The pyramid is complete, and every layer runs fast enough that you will actually use it.

## Unit tests: WheelsTest BDD

`wheels.WheelsTest` is the canonical base class for new tests (#1889). RocketUnit — the older `wheels.Test` base with `test_` prefixed methods and `assert()` calls — is retained for backward compatibility and deprecated for new work (#1925). Every legacy spec continues to run; nobody has to migrate.

The BDD syntax reads top-to-bottom the way a specification does:

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

Specs live under `tests/specs/` — organized into `tests/specs/models/`, `tests/specs/controllers/`, and `tests/specs/functional/` (#1872). The folder layout is convention, not configuration — the runner discovers everything recursively.

We consolidated on BDD-only for new tests deliberately. Dual-stack testing confused contributors. A PR would land with one spec in RocketUnit style and another in BDD style, and the reviewer would have to hold two mental models at once. `describe("User.valid()", () => { it("requires email", ...) })` signals intent unambiguously — the describe block names the unit under test, the `it` names the behavior, the matcher names the expectation. There is exactly one idiomatic way to write a new spec.

## Integration: HTTP TestClient

`TestClient` is a fluent HTTP client for hitting your own app from inside a test (#2099). It speaks the same routes, cookies, and sessions that real requests do, but without the ceremony of spinning up a server and curling against it.

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

The assertion surface covers what you actually want to assert on an HTTP response: status codes (`assertOk`, `assertStatus`, `assertRedirect`), body content (`assertSee`, `assertDontSee`), JSON responses with dot-notation path access (`assertJson`, `assertJsonPath`), headers, and cookies. Cookies are tracked across requests on the same client instance, which means session-based flows — log in on one request, act as the logged-in user on the next — work without extra wiring.

This is the middle layer that was missing in 3.0. You no longer need to stand up a fixture server just to assert that a route returns the right JSON shape.

## End-to-end: BrowserTest with Playwright Java

End-to-end is the layer that turns a "does it work?" question into an actual answer. `wheels.wheelstest.BrowserTest` is the base class; `this.browser` is a fluent DSL wrapping Playwright Java, which drives a real Chromium over the DevTools protocol.

```cfm
// End-to-end — BrowserTest
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

One-time install, about 370MB for JARs plus Chromium:

```bash
wheels browser setup
```

The DSL lands with roughly 60 methods across the shape you want for realistic specs: navigation (`visit`, `visitRoute`, `back`, `refresh`), interaction (`click`, `fill`, `type`, `select`, `check`, `attach`, `dragAndDrop`), keyboard (`press`, `pressEnter`, `pressTab`), waiting (`waitFor`, `waitForText`, `waitForUrl`), scoping (`within(selector, callback)`), cookies, authentication helpers (`loginAs`, `logout`), dialog handling, viewport resize for mobile/tablet/desktop shapes, screenshots, and a text-and-visibility-and-URL-and-form assertion set that covers the common ground. The shape shipped across #2113, #2115, #2116, #2121, and #2122.

CI runs browser specs in both `pr.yml` and `snapshot.yml`. Playwright JARs and Chromium are cached keyed on the hash of `browser-manifest.json`, so the download cost lands once per manifest change rather than once per run. The environment variable `WHEELS_BROWSER_TEST_BASE_URL=http://localhost:60007` is set automatically.

Chromium is the only engine at 4.0 launch. Firefox and WebKit are on the roadmap — the DSL is already shaped to accept them; the work is in the installer and the cross-engine behavior smoothing, not the test code you write.

## Parallel: ParallelRunner

Slow test suites are test suites you do not run. The `ParallelRunner` (#2100) discovers test bundles, partitions them round-robin across N workers, fires parallel HTTP requests through `cfthread`, and aggregates the JSON results at the end. On a multi-core CI runner, suite time drops proportionally.

This matters especially for the browser layer, where each spec carries the cost of a real page load. What used to be a coffee-break suite becomes something you run while you are still looking at the screen.

## A critical path, end-to-end

The shape that justifies the whole effort looks like this:

1. Log in as an admin.
2. Navigate to the new-user form.
3. Fill in name and email.
4. Submit.
5. Assert the URL redirected to the index.
6. Assert the new user shows up in the list.
7. Optionally: click delete, confirm the dialog, assert the user is gone.

That is the end-to-end spec shown above. Write it once in about 15 minutes, get regression coverage for the lifetime of that flow. It catches the class of bug where individual units all pass but the wiring between them is broken — a route that is not mounted, a form that submits to the wrong action, a redirect that targets a URL that no longer exists.

## Hard-won gotchas

These are the ones that bit us during the port, in the order you will likely hit them.

- **`##` in selectors.** CFML requires `##` to emit a literal `#`. In browser selectors, `"##email"` is what you write to target `#email`. Every CSS ID selector in a spec needs this. Miss it and you will see `Invalid Syntax Closing [#] not found` at compile time, which crashes the entire suite, not just the file.
- **`client` is a Lucee reserved scope.** Writing `var client = ...` inside a closure throws `"client scope is not enabled"`. Use `var c = ...` or `var bc = ...` instead. `session` and `application` have the same trap; use `sess` and `app`.
- **`this.browserTestSkipped`** — when Playwright JARs are not installed (fresh clone, clean CI image), the `beforeAll` hook sets this flag and the `browserDescribe` helper short-circuits every nested `it`. All browser specs should open with `if (this.browserTestSkipped) return;` so a machine without JARs stays green instead of red.
- **Data URLs cover about 95% of browser DSL coverage.** Most specs do not need a running fixture server — `this.browser.visitUrl("data:text/html,<title>Hi</title><h1>x</h1>")` is enough to exercise navigation, interaction, waiting, and assertions. Spin up the full fixture app only when you actually need cookies, form submissions, or redirects hitting real routes.
- **Dialogs are Lucee-only.** `acceptDialog`, `dismissDialog`, and `dialogMessage` use `createDynamicProxy`, which is a Lucee feature. Specs that depend on them should skip gracefully on other engines.
- **Fixture routes.** `/_browser/login-as` and `/_browser/logout` are mounted automatically in test mode. They have to come before `.wildcard()` in `routes.cfm` or they will never match.

The full reference is at [`.ai/wheels/testing/browser-testing.md`](https://github.com/wheels-dev/wheels/blob/develop/.ai/wheels/testing/browser-testing.md).

## Test data and fixtures

`tests/populate.cfm` remains the DROP + CREATE + seed harness — it runs once at the start of a test run, resets the schema, and seeds whatever the suite depends on. Test-only models live in `tests/_assets/models/` and use `table()` to map against test tables so they do not collide with real application models.

For local development, the canonical stack is LuCLI with SQLite — `bash tools/test-local.sh` handles everything from database creation through cleanup, no Docker required. CI runs the full matrix across Lucee 5/6/7, Adobe CF 2018/2021/2023/2025, and BoxLang, against MySQL, PostgreSQL, SQL Server, H2, SQLite, and CockroachDB. The LuCLI inner loop is fast enough to use between every edit; the full matrix is what runs pre-merge.

## Where to go next

- [Testing guide](https://guides.wheels.dev/v4-0-0-snapshot/testing/) — the user-facing walkthrough for WheelsTest, TestClient, and the spec layout.
- [Browser testing deep reference](https://github.com/wheels-dev/wheels/blob/develop/.ai/wheels/testing/browser-testing.md) — the full DSL surface, every gotcha we hit during the port, and the classloader/Playwright internals.
- [Running tests locally](https://guides.wheels.dev/v4-0-0-snapshot/testing/running-tests-locally/) — LuCLI and Docker paths.

If you have been treating testing as the part of the Wheels workflow you do not really do, 4.0 is the release where that calculus changes. First green unit spec in under five minutes. First green browser test in under 30. Feedback welcome on everything that is not yet obvious — contributors this cycle include @bpamiri, @zainforbjs, @chapmandu, @mlibbe, @MukundaKatta, and Dependabot, and the feedback loop that shaped the testing surface is exactly the one we want to keep open for 4.0.x.

