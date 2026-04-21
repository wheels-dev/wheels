# Wheels 4.0 Guides — Phase 2b-Testing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the Testing section's 9 detail pages — the hands-on how-tos that readers land on from Phase 2a's Testing Overview (Task 21). Covers model, controller, view/form, integration, functional, browser, fixtures, running locally, and CI integration.

**Architecture:** Same rhythm as Phase 2a Basics and Phase 2b-Advanced — each page authored directly in Starlight-native MDX, `{test:compile}` for CFML fragments, subagent-driven content writing with harness-passing as the review gate. Each page's `.ai/` source gets deleted in the same commit. Every spec example and test helper method is cross-checked against `vendor/wheels/WheelsTest.cfc` and `vendor/wheels/wheelstest/` before the page lands.

**Tech Stack:** Astro 5 + Starlight 0.34 + MDX. Node 22+ ESM harness. `wheels` CLI v0.3.5-SNAPSHOT+ (framework v4.0.0). WheelsTest BDD runner + Playwright-Java for browser testing (`BrowserTest`, `BrowserClient`, `BrowserLauncher`). Existing verify-docs harness with three drivers (cli, compile, tutorial) carrying forward.

**Base:** Branch `claude/lucid-thompson-b8c121` at Phase 2b-Advanced head `045b0d231`. All commits land on this same branch; one final merge to develop happens at end of Phase 2c.

**Review model (unchanged from prior phases):**
- Content pages — subagent-driven; harness + build as verification gate
- Integration tasks (sidebar + testing index update, `.ai/` audit) — inline
- End-of-phase final review — single `pr-review-toolkit:code-reviewer` subagent across the Phase 2b-Testing diff

**Prologue — policy decisions carried from prior phases:**

1. **`service("...")` short form is canonical** (settled Phase 2b-Advanced Task 1). Test examples that touch the DI container use the short form.
2. **`.ai/` folder consolidates into user docs**, same per-page deletion pattern. Phase 2c's final audit handles stragglers.
3. **Compile driver is in fallback mode** — bracket-balance validation only until LuCLI #56 merges. Content must still compile; harness only catches typos.
4. **Known framework gap: bcrypt.** Any test example that touches password hashing references salted SHA-256 per the tutorial pattern, with a cross-link to the gap.
5. **Cross-engine gotchas.** `vendor/wheels/wheelstest/BrowserTest.cfc` includes Lucee-only code via `createDynamicProxy` (per CLAUDE.md). Specs that exercise dialogs / file uploads should skip gracefully on non-Lucee engines. Document this in the Browser Tests page.

---

## File Structure

### New files — Testing section (9 pages)

All under `web/sites/guides/src/content/docs/v4-0-0-snapshot/testing/`:

| Path | Responsibility |
|------|----------------|
| `model-tests.mdx` | Testing validations, callbacks, custom methods, associations, scopes |
| `controller-tests.mdx` | Testing actions, filters, response assertions, param mocking, auth |
| `view-and-form-tests.mdx` | Testing view rendering, form helpers, `data-auto-id` selectors |
| `integration-tests.mdx` | Multi-model/cross-controller workflows in-process |
| `functional-tests.mdx` | End-to-end request-response without a browser |
| `browser-tests.mdx` | Playwright-driven UI tests — DSL, fixtures, lifecycle |
| `fixtures-and-test-data.mdx` | `tests/populate.cfm`, test-only models, factory patterns |
| `running-tests-locally.mdx` | `wheels test run`, filtering, Docker cross-engine matrix |
| `ci-integration.mdx` | GitHub Actions templates, JSON output, soft-fail databases |

### Modified files

| Path | Change |
|------|--------|
| `web/sites/guides/src/content/docs/v4-0-0-snapshot/testing/index.mdx` | Update the "Where to go next" CardGrid to point at all 9 new pages |
| `web/sites/guides/src/sidebars/v4-0-0-snapshot.json` | Add 9 new entries to the Testing section (currently has only `Overview`) |

### Deleted files — `.ai/` consolidation

| Deleted as part of | What gets removed |
|---------------------|-------------------|
| Task 1 (Model Tests) | `.ai/wheels/models/testing.md` |
| Task 2 (Controller Tests) | `.ai/wheels/controllers/testing.md` |
| Task 3 (View & Form Tests) | `.ai/wheels/views/testing.md` |
| Task 4-5 (Integration / Functional) | (no direct `.ai/` source) |
| Task 6 (Browser Tests) | `.ai/wheels/testing/browser-testing.md`, `.ai/wheels/testing/browser-automation-patterns.md` |
| Task 7-9 (Fixtures / Running / CI) | `.ai/wheels/testing/unit-testing.md` (split across these or delete as overlap — handle at task time) |

**`.ai/wheels/testing/` + testing.md files under models/controllers/views — all should be clear by end of phase.**

---

## Phase Layout

| Task | Page / Action | `.ai/` delete | Review mode |
|------|---------------|---------------|-------------|
| 1. Model Tests | Content | models/testing | Subagent + harness |
| 2. Controller Tests | Content | controllers/testing | Subagent + harness |
| 3. View & Form Tests | Content | views/testing | Subagent + harness |
| 4. Integration Tests | Content | (none) | Subagent + harness |
| 5. Functional Tests | Content | (none) | Subagent + harness |
| 6. Browser Tests | Content | testing/browser-testing, testing/browser-automation-patterns | Subagent + harness |
| 7. Fixtures & Test Data | Content | (possibly testing/unit-testing split) | Subagent + harness |
| 8. Running Tests Locally | Content | (possibly testing/unit-testing split) | Subagent + harness |
| 9. CI Integration | Content | (none) | Subagent + harness |
| 10. Testing index update + sidebar audit | Integration | (none) | Inline |
| 11. `.ai/testing/` straggler audit | Cleanup | any remaining | Inline |
| 12. Full harness + build + Phase 2b-Testing report | Integration | — | Inline |
| 13. Final code review | Review | — | Subagent |

13 tasks. Expected wall time: 2-3 sessions at Phase 2b-Advanced cadence.

---

## Shared conventions (carrying forward from Phase 2b-Advanced)

All testing pages use `type: howto`, open with "You'll learn," close with "Related guides" CardGrid, use `{test:compile}` for CFML blocks (bracket-balanced, `##` escape for literal `#`), keep headings at `###` max, second-person voice, no marketing copy.

Sidebar sort order 1-9 within Testing section, matching the task number.

Commit message pattern:
```
docs(docs): testing/<page> — <imperative phrase>
```

### Verification template (every page)

```bash
export JAVA_HOME=/opt/homebrew/Cellar/openjdk@21/21.0.8/libexec/openjdk.jdk/Contents/Home
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/lucid-thompson-b8c121/web/sites/guides
pnpm verify:docs src/content/docs/v4-0-0-snapshot/testing/<page>.mdx
pnpm build 2>&1 | tail -5
```

### Cross-page consistency rules

- **WheelsTest BDD class** is extended via `component extends="wheels.WheelsTest"` on every model/controller/view/integration/functional spec
- **BrowserTest class** is extended via `component extends="wheels.wheelstest.BrowserTest"` on browser specs
- **Test file locations** per spec:
  - `tests/specs/models/` — model specs
  - `tests/specs/controllers/` — controller specs
  - `tests/specs/view/` — view + form specs (verify path vs `views/`)
  - `tests/specs/functional/` — integration + functional specs
  - `tests/specs/browser/` — browser specs
- **BDD matchers** — verify against `WheelsTest.cfc` before using:
  - `expect(value).toBe(other)` — strict equality
  - `expect(value).toEqual(other)` — structural equality
  - `expect(boolean).toBeTrue()` / `.toBeFalse()`
  - `expect(value).toBeTruthy()` / `.toBeFalsy()`
  - `expect(value).toBeDefined()` / `.toBeUndefined()`
  - `expect(string).toInclude(substring)` / `.toContain()`
  - `expect(array_or_string).toHaveLength(n)`
  - `expect(value).toBeArray()` / `.toBeStruct()` / `.toBeQuery()`
  
  If a matcher isn't in WheelsTest, document only what is. Phase 2a Task 21 already covers the high-level set; detail pages should confirm their usage.

---

## Task 1: Model Tests

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/testing/model-tests.mdx`

**Type:** `howto`. **Sidebar order:** 2 within Testing (Overview is 1).

**`.ai/` to delete:** `.ai/wheels/models/testing.md`

**Reference material:**
1. `.ai/wheels/models/testing.md`
2. `vendor/wheels/WheelsTest.cfc` — the BDD base. Enumerate the assertion API.
3. Phase 1 Tutorial Part 7 — the `PostSpec` example
4. Phase 2a `basics/models-and-the-orm.mdx`, `basics/validation-and-errors.mdx`, `basics/associations.mdx`, `basics/query-builder-and-scopes.mdx`
5. Tests that ship in the framework itself — `vendor/wheels/tests/specs/model/` for canonical patterns
6. `web/sites/guides/STYLE.md`

**Frontmatter:**

```yaml
---
title: Model Tests
description: Testing validations, callbacks, custom methods, associations, and scopes — the BDD patterns for the model layer.
type: howto
sidebar:
  order: 2
---
```

**Required sections:**

1. Opening + "You'll learn" (BDD shape, testing validations, testing callbacks, testing associations, testing scopes, common pitfalls).
2. Prereq aside — "You should already know how to define a model. See [Models and the ORM](/v4-0-0-snapshot/basics/models-and-the-orm/)."
3. **Minimal spec shape** — `{test:compile}` block:
   ```cfm
   component extends="wheels.WheelsTest" {
       function run() {
           describe("Post", () => {
               it("requires a title", () => {
                   var post = model("Post").new(body="some body");
                   expect(post.valid()).toBeFalse();
                   expect(post.errorsOn("title")).toBeArray();
               });
           });
       }
   }
   ```
   File lives at `tests/specs/models/PostSpec.cfc`.
4. **Testing validations** — `{test:compile}` blocks for presence, length, format, uniqueness. Assert on `errorsOn(property)` returning non-empty array; `valid()` returning false; `hasErrors()` true.
5. **Testing callbacks** — `{test:compile}` block. Verify a `beforeSave` callback mutates fields:
   ```cfm
   it("generates slug on save", () => {
       var post = model("Post").create(title="Hello World", body="...");
       expect(post.slug).toBe("hello-world");
   });
   ```
6. **Testing custom methods** — `{test:compile}` block. Any `public` function on the model is testable:
   ```cfm
   it("displayTitle truncates to 60 chars", () => {
       var post = model("Post").new(title=RepeatString("x", 100));
       expect(post.displayTitle()).toHaveLength(60);
       expect(post.displayTitle()).toInclude("...");
   });
   ```
7. **Testing associations** — `{test:compile}` block. Exercise `hasMany` / `belongsTo` behavior:
   ```cfm
   it("deletes comments when post is deleted", () => {
       var post = model("Post").create(title="T", body="B");
       post.createComment(author="A", body="C");
       expect(post.commentCount()).toBe(1);
       post.delete();
       expect(model("Comment").count(where="postId=#post.id#")).toBe(0);
   });
   ```
8. **Testing scopes** — `{test:compile}` block. Named scopes, dynamic scopes, enum-generated scopes all testable:
   ```cfm
   it("published scope filters out drafts", () => {
       model("Post").create(title="Live", body="B", status="published");
       model("Post").create(title="Wip", body="B", status="draft");
       expect(model("Post").published().count()).toBe(1);
       expect(model("Post").draft().count()).toBe(1);
   });
   ```
9. **Test isolation** — short paragraph. Every spec runs inside a transaction that rolls back by default (verify against `WheelsTest.cfc`). If transaction-rollback isn't the default, document the DROP+CREATE pattern via `tests/populate.cfm`. Cross-link to Fixtures (Task 7).
10. **Common pitfalls** — bulleted list:
    - Mixed positional and named args (CLAUDE.md anti-pattern #1)
    - Asserting on `findAll()` as if it's an array — it's a query (use `<cfloop query=>`, `.recordCount`)
    - Forgetting to reload the model after a `beforeSave` in a different test run
11. **Related guides** CardGrid: Models and the ORM, Validation and Errors, Associations, Fixtures & Test Data (Task 7).

**Constraints:**
- 5-7 `{test:compile}` blocks
- Length: ~250-350 lines
- **Verify every matcher against `vendor/wheels/WheelsTest.cfc` before using.**

**Workflow:**
1. Read references + enumerate WheelsTest matchers
2. Write the page
3. Verify (harness + build)
4. Delete `.ai/`: `git rm .ai/wheels/models/testing.md`
5. Sidebar entry at order 2
6. Commit: `docs(docs): testing/model-tests — add BDD patterns for model layer + drop .ai models/testing`

---

## Task 2: Controller Tests

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/testing/controller-tests.mdx`

**Type:** `howto`. **Sidebar order:** 3.

**`.ai/` to delete:** `.ai/wheels/controllers/testing.md`

**Reference material:**
1. `.ai/wheels/controllers/testing.md`
2. **`vendor/wheels/wheelstest/TestClient.cfc`** — the HTTP-free request simulator. Enumerate its API (`get`, `post`, `put`, `delete`, assertion helpers).
3. `vendor/wheels/tests/specs/controller/` — framework's own controller specs
4. Phase 2a `basics/controllers-and-actions.mdx`
5. Phase 1 Tutorial Part 7 — `PostsControllerSpec`

**Frontmatter:**

```yaml
---
title: Controller Tests
description: Testing controller actions — response status, redirects, flash, filters, and params — without a running HTTP server.
type: howto
sidebar:
  order: 3
---
```

**Required sections:**

1. Opening + "You'll learn" (TestClient API, asserting responses, testing filters, mocking params, authenticating).
2. Prereq aside.
3. **The TestClient** — short prose + `{test:compile}` block showing setup:
   ```cfm
   component extends="wheels.WheelsTest" {
       function run() {
           describe("Posts", () => {
               var client = new wheels.wheelstest.TestClient();
               beforeEach(() => { client.reset(); });
               
               it("shows the index page", () => {
                   var res = client.get("/posts");
                   expect(res.status).toBe(200);
                   expect(res.body).toInclude("Posts");
               });
           });
       }
   }
   ```
   Note: **verify `TestClient` constructor + HTTP-method signatures against source before documenting.** Typical shape: `client.get(path)`, `client.post(path, params={})`, response has `status`, `body`, `redirectedTo`, `flashMessages` or similar.
4. **Assertion surface** — bulleted list of response fields available after a request: status, body, content type, redirect target, flash messages. Cross-check against TestClient implementation.
5. **Testing redirects** — `{test:compile}` block:
   ```cfm
   it("redirects after successful create", () => {
       var res = client.post("/posts", {post: {title: "New", body: "B"}});
       expect(res.status).toBe(302);
       expect(res.redirectedTo).toInclude("/posts/");
   });
   ```
6. **Testing flash messages** — `{test:compile}` block. After a redirect, the next request sees the flash.
7. **Testing filters indirectly** — `{test:compile}` block. Can't call private filter methods directly; assert their effect through the response (redirect to login, flash message, 403).
8. **Authenticating in tests** — `{test:compile}` block. Pre-populate session state:
   ```cfm
   it("allows logged-in users to edit their own posts", () => {
       client.session.userId = alice.id;
       var res = client.get("/posts/#alicePost.id#/edit");
       expect(res.status).toBe(200);
   });
   ```
   **Verify `client.session.*` API against source.** If it's `client.setSession(...)` or similar, use the real form.
9. **Mocking params** — short paragraph. Pass a struct as the second argument to `post()`/`put()`. TestClient builds the params struct the controller sees.
10. **Related guides** CardGrid: Controllers and Actions, Authorization & Filters, Tutorial Part 7, Fixtures & Test Data.

**Constraints:**
- 5-7 `{test:compile}` blocks
- Length: ~250-350 lines
- **Verify every TestClient method against `vendor/wheels/wheelstest/TestClient.cfc`.** This is the most drift-prone file; treat it like Phase 2b-Advanced treated the middleware classes.

**Workflow:** standard.

---

## Task 3: View & Form Tests

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/testing/view-and-form-tests.mdx`

**Type:** `howto`. **Sidebar order:** 4.

**`.ai/` to delete:** `.ai/wheels/views/testing.md`

**Reference material:**
1. `.ai/wheels/views/testing.md`
2. Phase 2a `basics/views-layouts-partials.mdx`, `basics/forms-and-form-helpers.mdx`
3. Framework gap #13's `data-auto-id` attribute (shipped via PR #2168) — test selectors pattern
4. `vendor/wheels/tests/specs/view/` for framework-level view tests

**Frontmatter:**

```yaml
---
title: View & Form Tests
description: Testing rendered view output, form helpers, and the data-auto-id attribute for stable selectors.
type: howto
sidebar:
  order: 4
---
```

**Required sections:**

1. Opening + "You'll learn" (rendering a view in a test, asserting on output, form-helper testing, `data-auto-id` usage in selectors).
2. Prereq aside.
3. **Rendering a view inside a spec** — short prose. Two approaches:
   - Via TestClient (full stack): `client.get("/posts")` returns rendered HTML in `res.body`
   - Via the `renderView()` helper directly (isolated): `var output = renderView(controller="posts", action="index", ...)` — verify this helper exists and documents its surface; if not, document the TestClient path only
4. **Asserting on rendered output** — `{test:compile}` block:
   ```cfm
   it("renders the post title as an h1", () => {
       var res = client.get("/posts/#post.id#");
       expect(res.body).toInclude("<h1>My Title</h1>");
   });
   ```
5. **Testing form helpers via output** — `{test:compile}` block. The form helpers emit both `id="post-title"` (dash) AND `data-auto-id="post_title"` (underscore). Tests can target either:
   ```cfm
   it("emits the expected form field ids", () => {
       var res = client.get("/posts/new");
       expect(res.body).toInclude("id=""post-title""");
       expect(res.body).toInclude("data-auto-id=""post_title""");
   });
   ```
6. **The `data-auto-id` convention** — short paragraph. Tests written against the underscore form (`data-auto-id`) are more portable; they survive template rename drift where dash-ids might collide. Cross-link to Forms and Form Helpers.
7. **Snapshot-style output matching** — short paragraph. Use inline `.toInclude` / `.toContain` rather than full snapshot comparison. Full snapshots turn into "update snapshot" noise; targeted substrings pin the real assertion.
8. **Testing form submission round-trips** — `{test:compile}` block combining GET form + POST submit + assert redirect:
   ```cfm
   it("round-trips through new → create → show", () => {
       var showForm = client.get("/posts/new");
       expect(showForm.status).toBe(200);
       var submit = client.post("/posts", {post: {title: "T", body: "B"}});
       expect(submit.status).toBe(302);
   });
   ```
9. **Related guides** CardGrid: Views/Layouts/Partials, Forms and Form Helpers, Controller Tests, Browser Tests.

**Constraints:**
- 4-6 `{test:compile}` blocks
- Length: ~200-300 lines
- **Verify `renderView()` direct-call API exists.** If not, document only TestClient path.

**Workflow:** standard.

---

## Task 4: Integration Tests

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/testing/integration-tests.mdx`

**Type:** `howto`. **Sidebar order:** 5.

**`.ai/` to delete:** none directly; check `.ai/wheels/testing/unit-testing.md` for integration/functional content that belongs here.

**Reference material:**
1. `.ai/wheels/testing/unit-testing.md` (may contain integration content)
2. `vendor/wheels/tests/specs/functional/` — framework's own integration specs often live here
3. Tasks 1-2 just landed

**Frontmatter:**

```yaml
---
title: Integration Tests
description: Cross-model, cross-controller workflows — the in-process tests that exercise real persistence and real routing.
type: howto
sidebar:
  order: 5
---
```

**Required sections:**

1. Opening + "You'll learn" (what integration tests are, when to reach for them vs unit or browser tests, multi-model workflows, transactions in tests).
2. **Integration vs other test types** — table:
   | Level | What it exercises | Speed |
   |-------|-------------------|-------|
   | Model test | One model in isolation | Fast (no HTTP) |
   | Controller test | One action + its dependencies | Fast (TestClient, no browser) |
   | Integration test | Multiple controllers or a multi-step workflow | Medium (TestClient, multiple requests) |
   | Functional test | Full request lifecycle end-to-end | Medium-Slow |
   | Browser test | UI-driven, real browser | Slowest |
3. **A multi-step workflow spec** — `{test:compile}` block. Signup → login → create post → comment:
   ```cfm
   it("supports the signup-to-comment flow", () => {
       // signup
       client.post("/users", {user: {email: "a@a.com", password: "x"}});
       // login
       client.post("/login", {session: {email: "a@a.com", password: "x"}});
       // create post
       var postRes = client.post("/posts", {post: {title: "T", body: "B"}});
       expect(postRes.status).toBe(302);
       // comment
       var commentRes = client.post("/posts/1/comments", {comment: {author: "A", body: "C"}});
       expect(commentRes.status).toBe(302);
   });
   ```
4. **Transactions in integration tests** — short paragraph. Each integration test often wraps in a `transaction { ... }` that rolls back at the end; this keeps tests fast and reset-free. Verify how `WheelsTest` handles this by default.
5. **Asserting on DB state** — `{test:compile}` block. After the workflow, verify the persistence side:
   ```cfm
   expect(model("Post").count()).toBe(1);
   expect(model("Comment").count(where="postId=1")).toBe(1);
   ```
6. **Related guides** CardGrid: Controller Tests (Task 2), Functional Tests (Task 5), Fixtures & Test Data (Task 7), Models and the ORM.

**Constraints:**
- 3-5 `{test:compile}` blocks
- Length: ~180-260 lines

**Workflow:** standard.

---

## Task 5: Functional Tests

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/testing/functional-tests.mdx`

**Type:** `howto`. **Sidebar order:** 6.

**`.ai/` to delete:** none.

**Reference material:**
1. `.ai/wheels/testing/unit-testing.md` (any functional-specific content)
2. `vendor/wheels/wheelstest/TestClient.cfc` — often the same driver as controller tests, at a different granularity

**Frontmatter:**

```yaml
---
title: Functional Tests
description: End-to-end request-response tests without a real browser — route matching, middleware, full action execution.
type: howto
sidebar:
  order: 6
---
```

**Required sections:**

1. Opening + "You'll learn" (what functional tests verify, the TestClient, how functional differs from integration, when to use each).
2. **Functional vs integration** — short paragraph. Integration tests multiple actors (multiple controllers or models). Functional tests a single feature end-to-end (GET → route match → middleware → filter → action → view render → response). Both use the TestClient; the scope differs.
3. **A functional spec** — `{test:compile}` block. Full request lifecycle:
   ```cfm
   it("matches a public GET /posts/:key and renders the show view", () => {
       var post = model("Post").create(title="T", body="B", status="published");
       var res = client.get("/posts/#post.id#");
       expect(res.status).toBe(200);
       expect(res.headers["Content-Type"]).toInclude("text/html");
       expect(res.body).toInclude("<h1>T</h1>");
   });
   ```
4. **Testing middleware effects** — `{test:compile}` block. Rate limiter, Cors, SecurityHeaders middleware all show up in the response headers:
   ```cfm
   it("applies security headers to every response", () => {
       var res = client.get("/posts");
       expect(res.headers["X-Frame-Options"]).toBe("SAMEORIGIN");
       expect(res.headers["X-Content-Type-Options"]).toBe("nosniff");
   });
   ```
5. **Testing HTTP method dispatch** — `{test:compile}` block. Route model binding, redirects for non-member actions, 404 for missing records.
6. **Testing error paths** — short paragraph + `{test:compile}` block. Unauthorized access → 302 to login. Missing record → 404 via RecordNotFound. Validation error → 422 with partial rendered.
7. **When to choose functional over integration** — short paragraph:
   - Functional: "does this one feature work end-to-end?" Single HTTP request.
   - Integration: "does this multi-step user journey work?" Multiple HTTP requests.
8. **Related guides** CardGrid: Integration Tests (Task 4), Controller Tests (Task 2), Browser Tests (Task 6), Middleware Pipeline.

**Constraints:**
- 3-5 `{test:compile}` blocks
- Length: ~180-260 lines

**Workflow:** standard.

---

## Task 6: Browser Tests

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/testing/browser-tests.mdx`

**Type:** `howto`. **Sidebar order:** 7.

**`.ai/` to delete:** `.ai/wheels/testing/browser-testing.md`, `.ai/wheels/testing/browser-automation-patterns.md`

**Reference material:**
1. Both `.ai/` files
2. **`vendor/wheels/wheelstest/BrowserTest.cfc`** — the base class
3. **`vendor/wheels/wheelstest/BrowserClient.cfc`** — the fluent DSL; enumerate every public method
4. **`vendor/wheels/wheelstest/BrowserLauncher.cfc`** — Playwright-Java launcher
5. **`vendor/wheels/wheelstest/DialogConsumer.cfc`** — Lucee-only dialog handling (cross-engine caveat)
6. `CLAUDE.md` Browser Testing Quick Reference section (the full DSL method list)
7. Phase 1 Tutorial Part 7 — `SignupFlowSpec` browser test example

**Frontmatter:**

```yaml
---
title: Browser Tests
description: Playwright-driven UI tests — installation, the fluent DSL, fixture helpers, cross-engine caveats.
type: howto
sidebar:
  order: 7
---
```

**Required sections:**

1. Opening + "You'll learn" (Playwright setup, BrowserTest base class, the DSL, login fixtures, known limits).
2. Prereq aside — "You should already know what WheelsTest BDD looks like. See [Model Tests](/v4-0-0-snapshot/testing/model-tests/) for the basics."
3. **Install Playwright** — `{test:cli}` smoke + prose:
   ```bash {test:cli cmd="wheels --version" asserts-stdout="Wheels"}
   wheels --version
   ```
   In prose: `wheels browser:install` downloads Playwright JARs + Chromium (~370MB). One-time setup.
4. **A minimal browser spec** — `{test:compile}` block:
   ```cfm
   component extends="wheels.wheelstest.BrowserTest" {
       this.browserEngine = "chromium";
       function run() {
           browserDescribe("Login flow", () => {
               it("loads the home page", () => {
                   if (this.browserTestSkipped) return;
                   this.browser.visitUrl("http://localhost:8080/")
                               .assertTitleContains("My App");
               });
           });
       }
   }
   ```
   **Critical:** `if (this.browserTestSkipped) return;` at the top of every `it` block. When Playwright JARs aren't installed (CI, fresh machine), the `beforeAll` sets this flag and specs should exit gracefully.
5. **The fluent DSL — full method list** — bulleted list, grouped. Cross-check every method against `BrowserClient.cfc`:
   - **Navigation:** `visit`, `visitUrl`, `visitRoute`, `back`, `forward`, `refresh`
   - **Interaction:** `click`, `press`, `fill`, `type`, `clear`, `select`, `check`, `uncheck`, `attach`, `dragAndDrop`
   - **Keyboard:** `keys`, `pressEnter`, `pressTab`, `pressEscape`
   - **Waiting:** `waitFor`, `waitForText`, `waitForUrl`
   - **Scoping:** `within(selector, callback)`
   - **Cookies:** `setCookie`, `deleteCookie`, `cookie`, `clearCookies`
   - **Auth:** `loginAs`, `logout`
   - **Dialogs (Lucee only):** `acceptDialog`, `dismissDialog`, `dialogMessage`
   - **Viewport:** `resize`, `resizeToMobile`, `resizeToTablet`, `resizeToDesktop`
   - **Script:** `script`, `pause`
   - **Terminals:** `currentUrl`, `title`, `pageSource`, `text`, `value`, `screenshot`
6. **Assertions** — subsection. Cross-check against `BrowserClient.cfc`:
   - Text/vis/presence: `assertSee`, `assertDontSee`, `assertSeeIn`, `assertVisible`, `assertMissing`, `assertPresent`, `assertNotPresent`
   - URL/title/query: `assertUrlIs`, `assertUrlContains`, `assertTitleContains`, `assertQueryStringHas`, `assertQueryStringMissing`, `assertRouteIs`
   - Form: `assertInputValue`, `assertChecked`, `assertHasClass`
7. **Auth fixtures (`loginAs`)** — short prose + `{test:compile}` block. Bypasses the login form by pre-setting session state via the `/_browser/login-as` fixture route (mounted automatically in test mode):
   ```cfm
   this.browser.loginAs(user={id: 1, email: "alice@example.com"}).visitRoute("posts");
   ```
8. **Using `data-auto-id` selectors** — short paragraph. Selectors can target the dash form (`#post-title`) or the underscore form (`[data-auto-id="post_title"]`). Prefer `data-auto-id` for portability. Cross-link to Forms and Form Helpers.
9. **Dialogs on Lucee** — short paragraph + caveat. `acceptDialog`, `dismissDialog`, `dialogMessage` use `createDynamicProxy` — Lucee-only. Adobe / BoxLang specs skip gracefully via engine detection. Cross-link to `CLAUDE.md` cross-engine notes.
10. **CI-ready specs** — short paragraph. The test suite installs Playwright JARs + Chromium (cached via `browser-manifest.json` hash). Browser specs run as part of the normal suite. `WHEELS_BROWSER_TEST_BASE_URL=http://localhost:60007` is set automatically.
11. **Common patterns** — bulleted list. Screenshot-on-fail, trace recording, per-spec engine selection, stable selectors.
12. **Related guides** CardGrid: View & Form Tests (Task 3), Forms and Form Helpers, Running Tests Locally (Task 8), CI Integration (Task 9).

**Constraints:**
- 5-7 `{test:compile}` blocks + 1 `{test:cli}` smoke
- Length: ~320-420 lines (this is the broadest testing page)
- **Verify every DSL method and assertion name against `vendor/wheels/wheelstest/BrowserClient.cfc`.** Skip anything that doesn't ship.

**Workflow:** standard.

---

## Task 7: Fixtures & Test Data

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/testing/fixtures-and-test-data.mdx`

**Type:** `howto`. **Sidebar order:** 8.

**`.ai/` to delete:** (partial `.ai/wheels/testing/unit-testing.md` if its content splits across this + Task 8)

**Reference material:**
1. `.ai/wheels/testing/unit-testing.md`
2. `vendor/wheels/tests/populate.cfm` — the framework's own `populate.cfm`
3. `tests/populate.cfm` pattern from a fresh app
4. `tests/_assets/` test-only models pattern

**Frontmatter:**

```yaml
---
title: Fixtures & Test Data
description: Seeding test databases — tests/populate.cfm, test-only models, and factory patterns.
type: howto
sidebar:
  order: 8
---
```

**Required sections:**

1. Opening + "You'll learn" (populate.cfm, idempotent setup, test-only models, factory patterns).
2. **`tests/populate.cfm` — the canonical setup** — short prose + `{test:compile}` block:
   ```cfm
   // tests/populate.cfm
   // Runs before each spec. Drop + create tables, seed known data.
   $dbinfo(action="tableinfo", table="posts", result="local.info");
   if (local.info.recordCount > 0) {
       execute("DROP TABLE posts");
   }
   execute("CREATE TABLE posts (id integer primary key, title varchar(120), body text, status varchar(20))");
   execute("INSERT INTO posts (id, title, body, status) VALUES (1, 'Seed 1', 'Body', 'published')");
   ```
   **Verify the scope gotcha from CLAUDE.md:** "Wheels internal functions (`$dbinfo`, `model()`, etc.) aren't available as bare calls in `.cfm` files included from plain CFCs. Use `application.wo.model()` or native CFML tags (`cfdbinfo`)."
3. **Test-only models** — short prose + `{test:compile}` block. `tests/_assets/models/` for models that only exist in the test suite:
   ```cfm
   component extends="Model" {
       function config() {
           tableName("test_posts");
           setPrimaryKey("id");
       }
   }
   ```
4. **Factory patterns** — short paragraph + `{test:compile}` block. When `populate.cfm` is too heavy for a specific spec, factory-style builders keep tests readable:
   ```cfm
   private function buildPost(struct overrides={}) {
       var defaults = {title: "Default Title", body: "Default Body", status: "published"};
       StructAppend(defaults, arguments.overrides, true);
       return model("Post").new(argumentCollection=defaults);
   }
   ```
5. **Idempotent setup** — short paragraph. `populate.cfm` typically DROPs + CREATEs + seeds. This is cheap on SQLite (the reference platform) but expensive on production DB engines. For cross-engine CI, consider transaction-rollback isolation over DROP/CREATE.
6. **Per-test vs per-suite scope** — short paragraph. `beforeEach` runs `populate.cfm`. `beforeAll` runs once per spec file. The framework default is per-suite-file; wire per-test if specs need full isolation.
7. **Testing associations with fixtures** — short prose + `{test:compile}` block. Pre-create parent records in `populate.cfm`, then in specs just build children:
   ```cfm
   // populate.cfm creates posts with id 1-3
   // spec:
   var comment = model("Comment").create(postId=1, author="A", body="C");
   expect(comment.valid()).toBeTrue();
   ```
8. **Related guides** CardGrid: Model Tests, Running Tests Locally (Task 8), Seeding (basics — different concern), Models and the ORM.

**Constraints:**
- 4-6 `{test:compile}` blocks
- Length: ~220-300 lines
- **Respect the CLAUDE.md scope gotcha for `.cfm` files.**

**Workflow:** standard.

---

## Task 8: Running Tests Locally

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/testing/running-tests-locally.mdx`

**Type:** `howto`. **Sidebar order:** 9.

**`.ai/` to delete:** possibly `.ai/wheels/testing/unit-testing.md` (audit content at task time — overlapping with Task 7 and Task 9; delete if no unique content remains).

**Reference material:**
1. `.ai/wheels/testing/unit-testing.md` (audit)
2. `cli/lucli/Module.cfc` — `wheels test` subcommand
3. `tools/test-local.sh` — the one-shot LuCLI test script (mentioned in CLAUDE.md)
4. Docker `compose.yml` in `rig/` — the cross-engine test setup
5. `CLAUDE.md` — sections on local testing (LuCLI + Docker)

**Frontmatter:**

```yaml
---
title: Running Tests Locally
description: Running the test suite — wheels test run, tools/test-local.sh, filtering, and Docker cross-engine matrix.
type: howto
sidebar:
  order: 9
---
```

**Required sections:**

1. Opening + "You'll learn" (the `wheels test` CLI, the local shell script, filtering tests, running cross-engine via Docker).
2. **Fastest path: `wheels test run`** — short prose + `{test:cli}` smoke:
   ```bash {test:cli cmd="wheels --version" asserts-stdout="Wheels"}
   wheels --version
   ```
   In prose:
   - `wheels test run` — full suite
   - `wheels test run --filter=models` — directory filter
   - `wheels test run --format=json` — CI-parseable output
   - `wheels test run --reporter=tap` — tap-formatted for editor integrations
3. **LuCLI one-shot: `tools/test-local.sh`** — short prose + illustrative bash block:
   ```bash title="your shell"
   bash tools/test-local.sh              # run all core tests
   bash tools/test-local.sh model        # run model tests only
   bash tools/test-local.sh browser      # run browser tests only
   ```
4. **The test runner HTTP URL** — short prose. Direct-hit URL pattern:
   ```
   http://localhost:60007/wheels/core/tests?db=sqlite&format=json
   http://localhost:60007/wheels/core/tests?db=sqlite&format=json&directory=tests.specs.model
   ```
   Useful when iterating on a specific spec file during development.
5. **Prerequisites** — short bulleted list: Java 21, LuCLI (brew install / choco install / install script), SQLite.
6. **Docker cross-engine** — short prose + illustrative bash block. `rig/compose.yml` defines services per engine + database:
   ```bash title="your shell — in wheels repo rig/"
   docker compose up -d lucee7 adobe2025
   curl -s "http://localhost:60007/wheels/core/tests?db=sqlite&format=json" > /tmp/lucee7.json
   curl -s "http://localhost:62025/wheels/core/tests?db=sqlite&format=json" > /tmp/adobe2025.json
   ```
   Engine ports: lucee5=60005, lucee6=60006, lucee7=60007, adobe2018=62018, adobe2021=62021, adobe2023=62023, adobe2025=62025, boxlang=60001.
7. **Testing against specific databases** — short paragraph:
   ```bash title="your shell"
   docker compose up -d lucee7 mysql
   curl -sf "http://localhost:60007/wheels/core/tests?db=mysql&format=json"
   ```
   Supported: `h2` (default), `sqlite`, `mysql`, `postgresql`, `mssql`, `cockroachdb`.
8. **Known cross-engine gotchas** — short bulleted list from CLAUDE.md:
   - Lucee/Adobe struct member function differences (`struct.map()` resolution)
   - Adobe CF doesn't support function members on the `application` scope
   - Closure `this` capture differences
   - Bracket-notation function call in Adobe 2021/2023 parser
   - `private` mixin functions not integrated (use `public` with `$` prefix)
9. **Cleanup** — short paragraph. `docker compose down` stops containers. SQLite DB files in `rig/` can be deleted between runs.
10. **Related guides** CardGrid: CI Integration (Task 9), Browser Tests (Task 6), Fixtures & Test Data (Task 7).

**Constraints:**
- 1 `{test:cli}` smoke + several illustrative bash blocks (not harness-tested — they need running servers)
- Length: ~250-350 lines
- **Verify every `wheels test` flag against `cli/lucli/Module.cfc`.**

**Workflow:** standard.

---

## Task 9: CI Integration

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/testing/ci-integration.mdx`

**Type:** `howto`. **Sidebar order:** 10.

**`.ai/` to delete:** none direct.

**Reference material:**
1. `.github/workflows/tests.yml` (or similar) — the framework's own test CI
2. Phase 0 `.github/workflows/docs-verify.yml` — reference for Actions patterns
3. `cli/lucli/Module.cfc` — `wheels test run --format=json` output shape
4. `CLAUDE.md` — CI soft-fail databases section

**Frontmatter:**

```yaml
---
title: CI Integration
description: Running Wheels tests in GitHub Actions, GitLab CI, CircleCI — cross-engine matrix, JSON output, soft-fail databases.
type: howto
sidebar:
  order: 10
---
```

**Required sections:**

1. Opening + "You'll learn" (GitHub Actions template, JSON test output, cross-engine matrix, soft-fail databases, parallel execution).
2. **GitHub Actions — minimum viable** — illustrative YAML block:
   ```yaml title=".github/workflows/tests.yml"
   name: tests
   on: [pull_request, push]
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: actions/setup-java@v4
           with:
             java-version: '21'
             distribution: 'temurin'
         - name: Install wheels CLI
           run: curl -fsSL https://get.wheels.dev/install.sh | sh
         - name: Run tests
           run: wheels test run --format=json > /tmp/results.json
         - name: Parse results
           run: |
             python3 -c "import json; d=json.load(open('/tmp/results.json')); print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail'); exit(1 if d['totalFail'] > 0 else 0)"
   ```
3. **JSON output shape** — short paragraph + example:
   ```json
   {
     "totalPass": 42,
     "totalFail": 0,
     "totalError": 0,
     "bundleStats": [
       {
         "suiteStats": [
           { "specStats": [ { "status": "Passed", "name": "..." } ] }
         ]
       }
     ]
   }
   ```
   Every CI scraper uses `totalPass`, `totalFail`, `totalError`. The nested `bundleStats` / `specStats` surface per-spec detail for richer reporting.
4. **Cross-engine matrix via Docker** — short prose + illustrative YAML:
   ```yaml
   strategy:
     matrix:
       engine: [lucee7, adobe2025, boxlang]
       database: [sqlite, mysql, postgresql]
   ```
   Each matrix cell boots the appropriate Docker services and targets the right port.
5. **Soft-fail databases** — short paragraph. Some DB engines have known failing tests (e.g., CockroachDB in the framework's own CI). Mark them soft-fail via `continue-on-error: true` on the matrix cell. CLAUDE.md lists which DBs are currently soft-fail. Remove a DB from the soft-fail list once its tests are fixed.
6. **Caching dependencies** — short prose + YAML. Java setup-java action already caches; Playwright JARs can be cached via `actions/cache` keyed by `browser-manifest.json` hash.
7. **Test result reporting** — short paragraph. `EnricoMi/publish-unit-test-result-action` ingests JUnit-style XML. If `wheels test run --format=junit` exists, use that. Otherwise, convert JSON → JUnit with a small script.
8. **Parallel execution** — short paragraph. `wheels test run --parallel` (verify this flag ships) or matrix-level parallelism via GitHub Actions. Per-spec isolation via transaction rollback in `populate.cfm`.
9. **Common CI failures** — bulleted list:
   - Playwright not installed (browser tests skip with `browserTestSkipped=true`; see Task 6)
   - `JAVA_HOME` unset (framework gap #12 in the tracker — fixed in LuCLI)
   - Docker not available on runner (use setup-docker or a runner with docker pre-installed)
   - Race between DB startup and first request (add a `wait-for-it.sh` before the test step)
10. **Related guides** CardGrid: Running Tests Locally (Task 8), Browser Tests (Task 6), Deployment (Phase 2c target).

**Constraints:**
- No `{test:*}` blocks (everything is illustrative YAML/bash for external systems)
- Length: ~220-300 lines
- **Verify `--format=json` output shape against `cli/lucli/Module.cfc`.**

**Workflow:** standard.

---

## Task 10: Testing index update + sidebar audit

**Inline task.**

### Testing index update

Current `web/sites/guides/src/content/docs/v4-0-0-snapshot/testing/index.mdx` ends with a 4-LinkCard CardGrid pointing at Model Tests, Controller Tests, Browser Tests, Running Tests Locally. Expand to all 9 Phase 2b-Testing pages in a proper LinkCard grid.

- [ ] Read current testing/index.mdx
- [ ] Replace the "Where to go next" CardGrid with all 9 LinkCards (per the DD index pattern Phase 2b-Advanced Task 16 established)
- [ ] Verify build

### Sidebar audit

The Testing section in `web/sites/guides/src/sidebars/v4-0-0-snapshot.json` currently has:
```json
{
  "label": "Testing",
  "link": "/v4-0-0-snapshot/testing/",
  "items": [
    { "label": "Overview", "link": "/v4-0-0-snapshot/testing/" }
  ]
}
```

- [ ] Confirm all 9 new pages have been added during Tasks 1-9 (each task's commit adds its own entry)
- [ ] Confirm order 1-10 matches sidebar.order frontmatter
- [ ] Build to verify

Commit:
```bash
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/testing/index.mdx web/sites/guides/src/sidebars/v4-0-0-snapshot.json
git commit -m "docs(docs): testing/index — expand landing cardgrid to 9 detail pages"
```

---

## Task 11: `.ai/wheels/testing/` straggler audit

**Inline task.**

After Tasks 1-9, `.ai/wheels/` should have the following testing-related files gone:
- `.ai/wheels/models/testing.md` (Task 1)
- `.ai/wheels/controllers/testing.md` (Task 2)
- `.ai/wheels/views/testing.md` (Task 3)
- `.ai/wheels/testing/browser-testing.md` (Task 6)
- `.ai/wheels/testing/browser-automation-patterns.md` (Task 6)

Potentially remaining:
- `.ai/wheels/testing/unit-testing.md` — audit content at task time. May have been split across Task 7 (Fixtures), Task 8 (Running Tests Locally), Task 9 (CI). If any user-facing content remains uncovered, either fold into the right page or delete.

- [ ] `find .ai/wheels -name "*testing*" -o -path "*testing*"` — inventory stragglers
- [ ] For each, decide: covered (delete), agent-operational (preserve for Phase 2c agent-context decision), Phase 2c target (preserve)
- [ ] Execute deletions + commit:
  ```bash
  git rm <files marked for delete>
  git commit -m "docs(docs): task 11 .ai/ testing stragglers audit — delete N covered files"
  ```

---

## Task 12: Full harness + build + Phase 2b-Testing report

**Files:**
- Create: `docs/superpowers/plans/2026-04-20-guides-rewrite-phase-2b-testing-report.md`

Steps:
- [ ] Full harness: `pnpm verify:docs` — expect 236 + N new blocks (N = sum of tagged blocks from Tasks 1-9, probably 35-55)
- [ ] Unit tests: `pnpm test:docs-harness` — expect 29/29 pass unchanged
- [ ] Build: `pnpm build` — expect ~312 pages (303 + 9)
- [ ] Push branch
- [ ] Write completion report following Phase 2b-Advanced report template:
  - Table of commits
  - Deliverables checklist (9 pages + index + sidebar + audit)
  - Verification section
  - API drift caught
  - `.ai/` files deleted
  - Known gaps for Phase 2b-CLI
- [ ] Commit report:
  ```bash
  git add docs/superpowers/plans/2026-04-20-guides-rewrite-phase-2b-testing-report.md
  git commit -m "docs(docs): phase 2b-testing completion report"
  git push
  ```

---

## Task 13: Final code review across Phase 2b-Testing diff

Dispatch a `pr-review-toolkit:code-reviewer` subagent with:

- Diff range: `045b0d231..HEAD` (Phase 2b-Advanced head → current)
- Review focus: voice consistency across 9 pages, Diátaxis (how-to), internal link accuracy, `.ai/` audit completeness, bracket-balance on compile blocks, sidebar matches file tree, BDD matcher names verified against `WheelsTest.cfc`, DSL method names verified against `BrowserClient.cfc`, `TestClient` API verified
- Known items to skip flagging: compile driver fallback mode, known gaps #17-21, forward links to Phase 2b-CLI / Phase 2c targets

Same template as Phase 2b-Advanced Task 18.

---

## Self-review

**Spec coverage check:**

| Spec § 5 requirement | Task |
|----------------------|------|
| Testing Overview | Phase 2a Task 21 (done) |
| Model Tests | 1 |
| Controller Tests | 2 |
| View & Form Tests | 3 |
| Integration Tests | 4 |
| Functional Tests | 5 |
| Browser Tests (Playwright) | 6 |
| Fixtures & Test Data | 7 |
| Running Tests Locally | 8 |
| CI Integration | 9 |

10/10 — all Testing spec items mapped.

**Placeholder scan:**
- No "TBD" / "implement later" in body
- Some sections flag "verify against source" at task time (`renderView()` direct-call API in Task 3, `TestClient.session.*` in Task 2, `--format=junit` in Task 9, `--parallel` flag in Task 9, transaction-rollback default in Task 1). All explicitly scoped as "verify before writing" — not placeholders in the "fill in details" sense.
- No "similar to Task N" references.

**Type / method consistency:**
- `component extends="wheels.WheelsTest"` consistent across Tasks 1-5, 7, 8 (model/controller/view/integration/functional/fixtures/running)
- `component extends="wheels.wheelstest.BrowserTest"` in Task 6
- `this.browser` DSL object referenced consistently
- `this.browserTestSkipped` guard pattern across all browser examples
- BDD matcher names (`toBe`, `toEqual`, `toBeTrue`, `toBeFalse`, `toBeTruthy`, `toInclude`, `toHaveLength`, `toBeArray`) used consistently across Tasks 1-5
- `TestClient` method names (`get`, `post`, `put`, `delete`, `reset`) consistent across Tasks 2-5

**Known friction carried forward from prior phases:**
- Content tasks use structural outlines + API-verification steps; subagents compose prose during execution
- Length ranges are guidance; STYLE.md anti-padding rule wins

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-20-guides-rewrite-phase-2b-testing.md`.

**Per Phase 2a/2b-Advanced pragmatic split:**
- **Content tasks (1-9)** — subagent-driven. One content-writer subagent per page, 9 dispatches.
- **Integration (10-12)** — inline.
- **Final review (13)** — single `pr-review-toolkit:code-reviewer` subagent.

Two execution options:

1. **Subagent-Driven (recommended)** — 9 content-writer subagents, same rhythm as Phase 2a Basics and Phase 2b-Advanced.
2. **Inline Execution** — I write each page myself.

**Proceed with subagent-driven execution?**
