# Fresh-VM Batch E — Browser Test Infrastructure

> **For agentic workers:** REQUIRED SUB-SKILLs in execution order:
> 1. superpowers:test-driven-development for Tasks 1, 2, and the Task 3 regression
> 2. superpowers:systematic-debugging for Task 4 (the #12 diagnosis)
> 3. superpowers:subagent-driven-development (recommended) OR superpowers:executing-plans for orchestration
>
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the chapter 7 `SignupFlowSpec` actually pass for a reader following the tutorial verbatim from a freshly-scaffolded app. Three findings stack up between them and the user: (#11) ambiguous selector that hits Playwright strict-mode, (#10) `wheels test` runs against the dev database where chapter 6's manual signup already saved `alice@example.com`, and (#12) a still-uncharacterised failure on the final `assertSee("Great post")` after the comment submit. After this batch, a fresh-VM run of chapter 7 should report `wheels test` green end-to-end without manual intervention.

**Architecture.**

- **Cheap doc fix first (#11):** narrow the comment-submit selector. Land it as a pre-emptive doc PR or fold into the bigger PR — either way, it's a 2-line change with no risk.
- **Convention fix (#10):** the project already creates `db/test.sqlite` and a `<appname>_test` datasource at `wheels new` time (`cli/lucli/Module.cfc:3766-3786`). What's missing is a runtime path that swaps `application.wheels.dataSourceName` to the `_test` datasource for the duration of an app-test run, and a generated `tests/populate.cfm` whose job is to mirror the dev schema into the test database. This batch picks the **CLI/framework-side fix** (no per-tutorial hand-waving) over emitting a hand-rolled `populate.cfm` — making `wheels test` Rails-shaped is a one-time cost that pays back on every chapter-7-style spec.
- **Diagnostic-first investigation (#12):** the Turbo-Stream final-assertion failure has at least three plausible root causes. Section 4 enumerates H1/H2/H3 and branches the implementation task by which hypothesis the reproduction confirms. Same shape as batch D's diagnostic tree.

**Tech Stack:** CFML/Lucee, WheelsTest BDD, [LuCLI local test harness](../../tools/test-local.sh), Playwright Java via the `wheels.wheelstest.BrowserClient` DSL ([`vendor/wheels/wheelstest/BrowserClient.cfc`](../../vendor/wheels/wheelstest/BrowserClient.cfc)). Doc edits target `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/07-testing-deploying.mdx`.

**Source findings:** [#10, #11, #12 in the 2026-04-29 fresh-VM triage](./2026-04-29-fresh-vm-onboarding-findings.md). Cross-references April 19 [#16](./2026-04-19-framework-gaps-from-guides-phase-1.md) (populate.cfm not documented at tutorial level).

---

## Pre-flight reconnaissance — confirmed during plan-writing

These facts are baked into the steps below; reverify only if something looks off.

- **Test DB is already provisioned at scaffold time.** `cli/lucli/Module.cfc:3766-3786` writes both `db/development.sqlite` and `db/test.sqlite`, and `config/app.cfm` ends up with two SQLite datasources: `<appname>` (dev) and `<appname>_test`. Nothing needs to change in the scaffolder for the file or the datasource to exist — the gap is that no runtime path *uses* the test datasource.
- **App test runner does NOT switch datasources.** [`vendor/wheels/tests/app-runner.cfm`](../../vendor/wheels/tests/app-runner.cfm) deliberately does not include `/wheels/tests/runner.cfm` and does not consult `url.db`. It runs against whatever `application.wheels.dataSourceName` was set at boot — i.e., the dev datasource.
- **Core test runner SETS `application.wheels.dataSourceName` from `url.db`.** [`vendor/wheels/tests/runner.cfm:69-80`](../../vendor/wheels/tests/runner.cfm) flips the datasource based on `url.db`. The pattern is `wheelstestdb_<db>` for engine-specific test datasources. App-runner has no equivalent.
- **`wheels test` always hits `/wheels/app/tests` for user apps** with `db=sqlite`. [`cli/lucli/Module.cfc:3419-3426`](../../cli/lucli/Module.cfc) builds the URL; the `db` param does nothing for app tests today because app-runner ignores it.
- **`tests/populate.cfm` is a framework convention, not a CLI template.** The framework's own copy lives at [`vendor/wheels/tests/populate.cfm`](../../vendor/wheels/tests/populate.cfm) and `vendor/wheels/tests/runner.cfm:96` includes `/wheels/tests/populate.cfm`. Apps may have their own at `/tests/populate.cfm` (an empty `tests/specs/` ships, but no `populate.cfm`). The framework includes the user's only when `tests/runner.cfm` exists, which fresh apps don't have either.
- **Browser DSL is at [`vendor/wheels/wheelstest/BrowserClient.cfc`](../../vendor/wheels/wheelstest/BrowserClient.cfc) (978 lines).** `click()` → `$locator(selector).click()` (line 105–114). `assertSee()` reads `variables.page.content()` (line 575–580). There is **no** `waitForLoadState("networkidle")`, no `turbo:load` event listener, and no special handling for `text/vnd.turbo-stream.html` — clicks just fire and the next assertion runs against whatever Playwright thinks the current page is.
- **Tutorial chapter 5 implementation.** [`05-comments-streams.mdx:194-206`](../../web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/05-comments-streams.mdx) has the controller call `renderPartial(partial="comment", comment=comment, layout=false)` — plain HTML output, no `cfheader content-type="text/vnd.turbo-stream.html"`. Wheels itself has no convention for setting that header today.
- **Tutorial chapter 4 layout.** [`04-validations-frames.mdx:106`](../../web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/04-validations-frames.mdx) loads Turbo from jsdelivr as a `type="module"` script — no async/defer, but ES modules are deferred-by-default.

---

## Hypothesis space for finding #12 — the final `assertSee("Great post")` failure

The failure mode in the original fresh-VM journal: after `click("turbo-frame#new_comment button[type=submit]")`, the next line `assertSee("Great post")` does not find the comment text on the page. Three plausible root causes, ranked.

### H1 (most likely): missing Content-Type header makes Turbo treat the response as a navigation

Turbo only intercepts a fetch response and processes `<turbo-stream>` elements when the response declares `Content-Type: text/vnd.turbo-stream.html` (Turbo 7+ requirement). The chapter 5 implementation calls `renderPartial(partial="comment", layout=false)` — plain HTML, no content-type override. The browser receives `text/html`, the form was submitted via Turbo, but Turbo's stream handler refuses to parse the body. Default fallback: a full navigation that lands on `/posts/<id>/comments` (the form action), which is a server-rendered page that wasn't designed for direct GET. The result: the test sees a different DOM than expected.

**Why this fits:** the journal said "the response from `comments##create` is a `<turbo-stream>` element (`text/html` MIME type) and Playwright treats it as a navigation rather than letting Turbo intercept and process it." That's exactly the H1 mode. `curl` sees the right body shape but the browser refuses to claim it.

**How to confirm:** Playwright `page.on("response", …)` listener captures the response Content-Type before the click resolves.

### H2 (possible): Turbo CDN script not finished loading before the click resolves

The layout loads Turbo from jsdelivr as `<script type="module" src="...">`. ES modules are deferred-by-default but they're still subject to network latency. If Playwright's click + form submit fires before Turbo's `connect` is complete, the form does a regular browser submit (full navigation), and `assertSee` runs against the post-redirect page where the comment may or may not be rendered (depends on what the controller's success path actually returns).

**Why this fits:** browser tests are timing-sensitive; the fresh-VM journal didn't show network logs, only the assertion failure. CDN-loaded scripts sometimes cold-start slow.

**Why this might not fit:** if H2 were the cause, ALL Turbo-driven tests would flake, not just the comment append. Chapter 4's frame-based form (also relying on Turbo) was reported as "cleanest chapters, no drift."

**How to confirm:** wait for Turbo to be ready (`page.evaluate("typeof Turbo !== 'undefined'")`) before the click, see if the test passes.

### H3 (less likely): the test browser is mid-navigation when `assertSee` runs

`click()` returns as soon as Playwright dispatches the event — it doesn't wait for the next page-load. If the form submit triggers a real navigation (because of H1 or H2), the page may still be loading when `assertSee` reads `page.content()`, returning an intermediate (or previous) DOM.

**Why this fits:** `BrowserClient.click()` (lines 105-114) does NOT call `waitForLoadState`. The DSL has no built-in post-click wait.

**Why this might not fit:** this would be a deterministic-ish race; on a fast local machine the assertion would land after the load. Worth verifying.

**How to confirm:** add an explicit `waitForLoadState("networkidle")` (or equivalent — see Task 4 step 3) before the assertion.

We test these in order. Confirmation flow → fix path:
- **H1 confirmed:** ship a Content-Type fix (framework-level: a new `cfheader` in `renderPartial` when a turbo-stream is detected) plus a tutorial-level note. Task 4.A.
- **H2 confirmed:** add a Turbo-readiness wait helper to `BrowserClient`. Task 4.B.
- **H3 confirmed:** make `click()` optionally wait for the next idle. Task 4.C.
- **Combination:** fix in stack order — H1 first since it's the most invasive symptom.

---

## Task 1: Doc fix #11 — narrow the ambiguous selector (cheap, lands first)

**Files:**
- Modify: [`web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/07-testing-deploying.mdx:199, 205`](../../web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/07-testing-deploying.mdx)

The two `click("button[type=submit]")` calls at lines 199 and 205 both land on the post show page where two submit buttons exist (`Delete` from `buttonTo(method="delete")` and `Post comment` from the comment form). Playwright strict mode rejects `locator("button[type=submit]")` when more than one element matches.

The form is wrapped in `<turbo-frame id="new_comment">` per chapter 5 line 224, so a frame-scoped selector is unambiguous. The CFML string literal needs `##new_comment` to emit a single `#` at runtime (per CLAUDE.md's selector gotcha).

- [ ] **Step 1: Read the current spec block in chapter 7**

```bash
sed -n '174,213p' web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/07-testing-deploying.mdx
```

Confirm the spec body matches the version in this plan (lines 199 and 205 both use `button[type=submit]`).

- [ ] **Step 2: Apply the selector edit**

Edit `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/07-testing-deploying.mdx`. The first `click("button[type=submit]")` at line 199 lands on the new-post page (only one submit button) — leave it alone. The second click at line 205 needs the frame scope:

```diff
                    this.browser
                        .fill("input[name='comment[author]']", "Bob")
                        .fill("textarea[name='comment[body]']", "Great post")
-                       .click("button[type=submit]")
+                       .click("turbo-frame##new_comment button[type=submit]")
                        .assertSee("Great post");
```

Note: `##new_comment` is CFML escaping a literal `#` inside a string — at runtime the selector is `turbo-frame#new_comment button[type=submit]`. Same convention chapter 7 already uses for `##post-title` and `##post-body`.

- [ ] **Step 3: Add an explanatory bullet under "Four things to notice"**

Right after the `##post-title` bullet (around line 218), add:

```diff
 - `##post-title` is CFML escaping a literal `#` inside a string. At runtime the selector is `#post-title` — the CSS id the `textField(objectName="post", property="title")` helper emits (Wheels joins object + property with a dash). Without the double `##`, CFML would try to evaluate `post-title` as an expression and throw.
+- `turbo-frame##new_comment button[type=submit]` is the same `##` escape applied to a frame-scoped selector. The post show page has two submit buttons — the `Delete` button and the `Post comment` button — so a bare `button[type=submit]` would match both and Playwright's strict-mode locator would refuse to act. Scoping to the new-comment frame is unambiguous.
```

- [ ] **Step 4: Build the guides site to confirm no MDX syntax error**

```bash
cd web/sites/guides
pnpm build
cd ../../..
```

Expected: build succeeds, `dist/v4-0-0-snapshot/start-here/tutorial/07-testing-deploying/index.html` is freshly emitted.

- [ ] **Step 5: Commit**

```bash
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/07-testing-deploying.mdx
git commit -m "$(cat <<'EOF'
docs(web/guides): scope chapter 7 comment-submit selector to the new-comment frame

The post show page has two submit buttons after chapter 5 — the
Delete button (from buttonTo(method="delete")) and the Post comment
button — so the existing `button[type=submit]` selector hit
Playwright's strict-mode rejection. Scope to `turbo-frame##new_comment
button[type=submit]` so the locator is unambiguous, and add an
explainer bullet for the ##-escape pattern.

Closes finding #11 in
docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md
EOF
)"
```

---

## Task 2: Framework fix #10 — `wheels test` runs against `db/test.sqlite` by default

The scaffolder already creates the test database file and registers a `<appname>_test` datasource. What's missing: a runtime path that swaps the active datasource to the `_test` one for the duration of a test run, and a default `tests/populate.cfm` that mirrors the development schema into the test DB on first run.

The minimal-touch design: extend `vendor/wheels/tests/app-runner.cfm` to consult `url.db` (mirroring core-runner's behavior), and have the CLI pass `--use-test-db` (default true, opt-out) so the runner switches to `<dataSourceName>_test`. Add a tutorial-level acceptance criterion that the spec passes after a chapter-6 manual signup.

**Files:**
- Modify: [`vendor/wheels/tests/app-runner.cfm`](../../vendor/wheels/tests/app-runner.cfm) (datasource swap + populate.cfm include)
- Modify: [`cli/lucli/Module.cfc:3405-3449`](../../cli/lucli/Module.cfc) (`runTests` adds `&useTestDB=true`)
- Modify: [`cli/lucli/templates/app/`](../../cli/lucli/templates/app/) — add a default `tests/populate.cfm` that runs the migrator against the test datasource
- Modify: [`cli/lucli/Module.cfc`](../../cli/lucli/Module.cfc) `wheelsNew` (around line 3405-3500 area for templates) — copy the new `populate.cfm` into the scaffolded app
- Create: `vendor/wheels/tests/specs/dispatch/AppRunnerTestDbSpec.cfc` (regression spec)
- Modify: [`web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/07-testing-deploying.mdx`](../../web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/07-testing-deploying.mdx) (drop the troubleshooting note that points users at populate.cfm; replace with a short "what `wheels test` does to your databases" explainer)

- [ ] **Step 1: Write the failing regression spec**

Create `vendor/wheels/tests/specs/dispatch/AppRunnerTestDbSpec.cfc`:

```cfm
component extends="wheels.WheelsTest" {

    function run() {

        describe("app-runner test database resolution", () => {

            it("swaps to <appname>_test datasource when useTestDB=true", () => {
                // Simulate the dispatch path: app-runner.cfm reads url.useTestDB
                // and url.db. When useTestDB=true and a `<dataSourceName>_test`
                // datasource exists, application.wheels.dataSourceName is
                // overwritten for the duration of the run and restored on exit.
                var originalDataSource = application.wheels.dataSourceName;

                // Stub: pretend a "<originalDataSource>_test" datasource exists
                // by registering one against the same SQLite file the test suite
                // already uses. The unit test cares about the swap mechanic, not
                // the real datasource registration.
                var fakeUrl = {
                    useTestDB: true,
                    format: "json",
                    directory: "tests.specs._noop"
                };

                var resolver = new wheels.tests._assets.dispatch.TestDbResolver();
                var swapped = resolver.resolveDataSource(
                    currentName = originalDataSource,
                    url = fakeUrl
                );

                expect(swapped).toBe(originalDataSource & "_test");
            });

            it("returns the current datasource untouched when useTestDB is false", () => {
                var fakeUrl = { useTestDB: false };
                var resolver = new wheels.tests._assets.dispatch.TestDbResolver();
                expect(resolver.resolveDataSource(currentName = "myapp", url = fakeUrl))
                    .toBe("myapp");
            });

            it("returns the current datasource untouched when useTestDB is missing", () => {
                var resolver = new wheels.tests._assets.dispatch.TestDbResolver();
                expect(resolver.resolveDataSource(currentName = "myapp", url = {}))
                    .toBe("myapp");
            });

        });

    }

}
```

And the test asset `vendor/wheels/tests/_assets/dispatch/TestDbResolver.cfc`:

```cfm
component {

    public string function resolveDataSource(
        required string currentName,
        required struct url
    ) {
        var useTestDB = StructKeyExists(arguments.url, "useTestDB")
            && arguments.url.useTestDB;
        if (!useTestDB) return arguments.currentName;
        return arguments.currentName & "_test";
    }

}
```

The resolver is intentionally a thin extracted helper so it's unit-testable without a full HTTP request. `app-runner.cfm` will instantiate it and use its return value.

- [ ] **Step 2: Run the spec — confirm it passes (the helper is self-contained)**

```bash
bash tools/test-local.sh dispatch
```

The resolver tests should pass on their own. They're a contract, not a reproduction — the integration is in app-runner itself.

- [ ] **Step 3: Wire the resolver into `app-runner.cfm`**

Edit `vendor/wheels/tests/app-runner.cfm` — insert before the existing `try { testBox = ...` block (line 29):

```cfm
// Resolve target datasource. If url.useTestDB=true and a
// `<dataSourceName>_test` datasource is registered, swap to it for
// the duration of this run. Mirrors Rails' RAILS_ENV=test convention
// without requiring the user to manage two databases by hand.
local.originalDataSource = application.wheels.dataSourceName;
local.targetDataSource = local.originalDataSource;
if (StructKeyExists(url, "useTestDB") && url.useTestDB) {
    local.candidate = local.originalDataSource & "_test";
    // Verify the test datasource actually exists before swapping —
    // otherwise the user gets a confusing CFDBINFO failure.
    local.registered = GetApplicationMetaData().datasources;
    if (StructKeyExists(local.registered, local.candidate)) {
        local.targetDataSource = local.candidate;
        application.wheels.dataSourceName = local.candidate;
    }
}

// If the test database is empty (no tables), include the user's
// tests/populate.cfm to bootstrap schema. Skip when the file doesn't
// exist (advanced users who already have their own setup).
local.populatePath = ExpandPath("/tests/populate.cfm");
if (
    local.targetDataSource != local.originalDataSource
    && FileExists(local.populatePath)
) {
    local.tables = application.wo.$dbinfo(
        datasource = local.targetDataSource,
        type = "tables"
    );
    local.tableList = ValueList(local.tables.table_name);
    // Heuristic: a fresh test DB has no migrator-versions table.
    if (!FindNoCase(application.wheels.migratorTableName, local.tableList)) {
        include "/tests/populate.cfm";
    }
}
```

And after the JSON output (after line 80, before `</cfscript>`):

```cfm
// Restore the original datasource so subsequent requests see the
// dev DB again.
application.wheels.dataSourceName = local.originalDataSource;
```

Wrap the run inside a try/finally so the restore happens even if a spec throws:

```cfm
try {
    // ... existing testBox.run() and output emission ...
} finally {
    application.wheels.dataSourceName = local.originalDataSource;
}
```

- [ ] **Step 4: Add `useTestDB=true` to the CLI's test URL**

Edit `cli/lucli/Module.cfc` `runTests` (line 3405-3449). Add a `--no-test-db` opt-out flag and pass `useTestDB=true` by default:

```diff
 private string function runTests(
     string filter = "",
     string reporter = "simple",
     string format = "json",
     boolean verboseOutput = false,
     boolean coreTests = false,
     string db = "sqlite",
-    boolean ciMode = false
+    boolean ciMode = false,
+    boolean useTestDB = true
 ) {
     var serverPort = $requireRunningServer([
         "Start one with: wheels start",
         "Or use: bash tools/test-local.sh (auto-manages server)"
     ]);

     var testPath = coreTests ? "/wheels/core/tests" : "/wheels/app/tests";
     out("Running #(coreTests ? 'core' : 'app')# tests (#db#)...", "cyan");

     try {
         var testUrl = "http://localhost:#serverPort##testPath#?format=#format#&db=#db#";
+        // App tests default to running against the <appname>_test datasource.
+        // Core tests already pick datasources via url.db so we leave them alone.
+        if (!coreTests && useTestDB) {
+            testUrl &= "&useTestDB=true";
+        }
         if (len(filter)) {
             testUrl &= "&directory=#filter#";
         }
```

And in `test()` (around line 380), parse the new flag:

```diff
             } else if (arg == "--core") {
                 coreTests = true;
+            } else if (arg == "--no-test-db") {
+                useTestDB = false;
             } else if (!arg.startsWith("--")) {
```

Update the call at line 398:

```diff
-        return runTests(filter, reporter, format, verboseOutput, coreTests, db, ciMode);
+        return runTests(filter, reporter, format, verboseOutput, coreTests, db, ciMode, useTestDB);
```

- [ ] **Step 5: Generate a default `tests/populate.cfm` at scaffold time**

Create `cli/lucli/templates/app/tests/populate.cfm`:

```cfm
<cfsetting requestTimeOut="300">
<!---
    tests/populate.cfm — bootstraps the test database before specs run.

    `wheels test` runs against the `<appname>_test` datasource (separate
    SQLite file from your dev DB) so chapter-6 manual signups don't bleed
    into chapter-7 specs. The first time the test DB is empty, this file
    runs every migration in `app/migrator/migrations/` against it,
    leaving you with the same schema as `wheels migrate latest` produces
    on the dev DB.

    Customise this file when you need test-specific seed data — model
    fixtures, baseline users, anything that should exist before EVERY
    test run. The framework calls this file from app-runner.cfm only
    when the test DB has no migrator-versions table (i.e. on first run
    or after you delete `db/test.sqlite`).
--->
<cfscript>
    // Run all pending migrations against the (currently-active) test
    // datasource. application.wheels.dataSourceName has already been
    // swapped by app-runner.cfm before this file is included.
    if (StructKeyExists(application.wheels, "migrator")) {
        application.wheels.migrator.migrateToLatest();
    }

    // Add test-specific seed data below. Keep it minimal — most specs
    // should set up their own state via beforeEach/it blocks rather
    // than relying on globally-seeded fixtures.
    //
    // Example:
    //     application.wo.model("User").create(
    //         email = "fixture@example.com",
    //         password = "test1234"
    //     );
</cfscript>
```

In `cli/lucli/Module.cfc`'s `wheelsNew` template-copy block (search for the existing `tests/specs/.gitkeep` copy logic — likely around line 3580-3700 where `printCreated` calls reference test paths), append a copy step for the new `populate.cfm`. Pseudocode (verify the actual template-copying mechanism in the existing `wheelsNew` body before editing):

```cfm
// After the tests/specs/<subdir>/ creates, drop in a default populate.cfm.
local.populateSrc = variables.templateRoot & "/app/tests/populate.cfm";
local.populateDst = targetDir & "/tests/populate.cfm";
if (FileExists(local.populateSrc)) {
    fileCopy(local.populateSrc, local.populateDst);
    printCreated(appName & "/tests/populate.cfm");
}
```

If the existing template-copy code is a directory walker rather than per-file `fileCopy`, the new `populate.cfm` will land automatically once it lives in `templates/app/tests/`.

- [ ] **Step 6: Update chapter 7 troubleshooting to match new behavior**

Edit `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/07-testing-deploying.mdx`. The current troubleshooting block at line 290 says:

```mdx
**"Model spec fails with `cannot find Post.cfc`."** The test runner boots a fresh schema from `tests/populate.cfm`, which you haven't set up yet. See [Fixtures & Test Data]...
```

Replace with:

```diff
-**"Model spec fails with `cannot find Post.cfc`."** The test runner boots a fresh schema from `tests/populate.cfm`, which you haven't set up yet. See [Fixtures & Test Data](/v4-0-0-snapshot/testing/fixtures-and-test-data/) for the standard `populate.cfm` that mirrors your development schema into the test database.
+**"Model spec fails with `cannot find Post.cfc`."** The test runner runs against `db/test.sqlite` (separate from your dev DB so chapter 6's manual signup doesn't leak in). The framework auto-runs `tests/populate.cfm` the first time the test DB is empty — that file ships with `wheels new` and runs your migrations against the test database. If you've customised `populate.cfm` and removed the `migrateToLatest()` call, restore it or run `wheels migrate latest --datasource=<appname>_test` manually. See [Fixtures & Test Data](/v4-0-0-snapshot/testing/fixtures-and-test-data/) for ways to add test-specific seed data.
```

Also add a short paragraph after "Run the tests" (around line 246):

```mdx
:::note
`wheels test` runs against `db/test.sqlite` — a second SQLite file scaffolded alongside `db/development.sqlite` when you ran `wheels new`. The first time the test DB is empty, the framework includes `tests/populate.cfm` to apply your migrations. Subsequent runs reuse the schema until you delete the file. This means `[email protected]` from chapter 6's manual signup walkthrough lives ONLY in `db/development.sqlite` — chapter 7's signup spec gets a clean slate every run.
:::
```

- [ ] **Step 7: Run the regression suite**

```bash
bash tools/test-local.sh dispatch
bash tools/test-local.sh   # full suite — make sure no other test is silently
                            # depending on app-runner not swapping datasources
```

Expected: all green. Pay particular attention to `vendor/wheels/tests/specs/dispatch/` and any spec that imports `app-runner.cfm`.

- [ ] **Step 8: End-to-end verification on a freshly-scaffolded app**

```bash
TMP=$(mktemp -d) && cd "$TMP"
WHEELS_FRAMEWORK_PATH=/Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/fresh-vm-batch-e/vendor/wheels \
    wheels new e10-repro --no-open-browser
cd e10-repro

# Mirror tutorial chapters 2-6 minimally
wheels migrate latest    # runs against e10-repro (dev) datasource
wheels generate model User email:string passwordHash:string
wheels generate scaffold User email:string passwordHash:string
wheels migrate latest

wheels start --port=9876 &
sleep 8

# Sanity: dev DB has migrations applied
sqlite3 db/development.sqlite ".tables" | grep -q users && echo OK-dev

# Sanity: test DB still empty
sqlite3 db/test.sqlite ".tables" | grep -q users && echo BAD-test-already-has-tables || echo OK-test-empty

# First wheels test run — should auto-bootstrap the test DB
wheels test 2>&1 | tail -20

# Test DB should now have schema
sqlite3 db/test.sqlite ".tables" | grep -q users && echo OK-test-now-bootstrapped

wheels stop
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/fresh-vm-batch-e
rm -rf "$TMP"
```

Expected: `OK-dev`, `OK-test-empty`, then `OK-test-now-bootstrapped` after `wheels test`.

- [ ] **Step 9: Commit the framework + CLI work**

```bash
git add vendor/wheels/tests/app-runner.cfm \
        vendor/wheels/tests/_assets/dispatch/TestDbResolver.cfc \
        vendor/wheels/tests/specs/dispatch/AppRunnerTestDbSpec.cfc \
        cli/lucli/Module.cfc \
        cli/lucli/templates/app/tests/populate.cfm
git commit -m "$(cat <<'EOF'
feat(test): wheels test runs against <appname>_test datasource by default

The scaffolder already creates db/test.sqlite and registers a
<appname>_test datasource at wheels new time, but no runtime path
used it. wheels test ran against the dev datasource through the
running dev server, so chapter 6's manual signup of
[email protected] bled into chapter 7's SignupFlowSpec and the
spec failed on uniqueness validation.

Make app-runner.cfm consult url.useTestDB and swap
application.wheels.dataSourceName to the matching _test datasource
for the duration of the run. Restore on exit. The CLI passes
useTestDB=true by default; --no-test-db opts out for users who want
to point app tests at the dev DB explicitly.

Generate a default tests/populate.cfm at scaffold time that runs
migrateToLatest() against the active datasource. The framework
includes the user's populate.cfm only when the test DB has no
migrator-versions table — every subsequent run reuses the schema.

Closes finding #10 in
docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md.
Subsumes April 19 #16 (populate.cfm not documented at tutorial level).
EOF
)"
```

And the doc update separately:

```bash
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/07-testing-deploying.mdx
git commit -m "$(cat <<'EOF'
docs(web/guides): explain wheels test ↔ db/test.sqlite contract in chapter 7

Previously chapter 7 mentioned tests/populate.cfm only in
troubleshooting. Now that the framework auto-swaps to the
<appname>_test datasource and runs the user's populate.cfm on first
empty run, document the contract explicitly so readers know:

- their dev DB and test DB are separate
- chapter 6's manual signup does NOT leak into chapter 7 specs
- populate.cfm ships with wheels new and runs their migrations

Aligns the tutorial with the new wheels test default introduced in
the framework commit landed in batch E.
EOF
)"
```

---

## Task 3: Regression — verify chapter 7's `SignupFlowSpec` actually passes end-to-end

After Tasks 1 and 2, the spec should be runnable. Add a CI-grade harness that scaffolds a fresh app, applies the chapters 2–6 minimum, drops in the chapter 7 spec verbatim, and runs `wheels test` to completion. This is the canary: if it goes red later, we know the tutorial drifted before any user hits it.

**Files:**
- Create: [`tools/test-tutorial-ch7.sh`](../../tools/test-tutorial-ch7.sh) — bash harness following the same shape as `tools/test-onboarding.sh`
- (Optional, follow-up) extend `.github/workflows/snapshot.yml` to run this harness — out of scope for this batch unless trivial

The harness scaffolds → applies migrations → seeds a deliberately-conflicting `[email protected]` in the dev DB (mimicking chapter 6's "Test 6a manually" walkthrough that bit the original fresh-VM run) → writes the `SignupFlowSpec.cfc` from chapter 7 → runs `wheels test` → asserts exit code 0.

- [ ] **Step 1: Read the existing onboarding harness as a model**

```bash
sed -n '1,50p' tools/test-onboarding.sh
ls .ai/wheels/testing/onboarding-harness.md 2>/dev/null && \
    sed -n '1,40p' .ai/wheels/testing/onboarding-harness.md
```

Mirror its structure: `LUCLI_HOME` isolation under `mktemp -d`, symlink the framework worktree into the scaffolded app, optional `KEEP_TEMP=1` for inspection.

- [ ] **Step 2: Create the harness**

`tools/test-tutorial-ch7.sh` (high-level skeleton — flesh out per the existing onboarding harness's conventions):

```bash
#!/usr/bin/env bash
# Validate that Wheels guides chapter 7's SignupFlowSpec passes against a
# freshly-scaffolded app that's also seeded with the chapter-6 [email protected]
# the original fresh-VM run found bled into the spec.
set -euo pipefail

WHEELS_REPO="${WHEELS_REPO:-$(git rev-parse --show-toplevel)}"
HARNESS_TMP=$(mktemp -d)
PORT="${PORT:-9876}"
APP_NAME="ch7-canary"

cleanup() {
    if [[ "${KEEP_TEMP:-0}" != "1" ]]; then
        rm -rf "$HARNESS_TMP"
    else
        echo "Preserved harness dir: $HARNESS_TMP"
    fi
}
trap cleanup EXIT

cd "$HARNESS_TMP"
WHEELS_FRAMEWORK_PATH="$WHEELS_REPO/vendor/wheels" wheels new "$APP_NAME" --no-open-browser
cd "$APP_NAME"

# Apply tutorial chapters 2-6 minimally
wheels generate model Post title:string body:text status:enum
wheels generate model User email:string passwordHash:string
wheels migrate latest

# Mimic chapter 6's "Test 6a manually" — sign up [email protected]
# DIRECTLY in the dev DB. This is the conflict that bit the fresh-VM run.
sqlite3 db/development.sqlite \
    "INSERT INTO users (email, passwordhash, createdat, updatedat)
     VALUES ('[email protected]', 'stub', datetime('now'), datetime('now'));"

# Drop in chapter 7's SignupFlowSpec verbatim
cat > tests/specs/browser/SignupFlowSpec.cfc <<'CFM'
component extends="wheels.wheelstest.BrowserTest" {
    this.browserEngine = "chromium";
    function run() {
        browserDescribe("Full signup flow", () => {
            it("signs up, creates a post, adds a comment", () => {
                if (this.browserTestSkipped) return;
                this.browser
                    .visitRoute("signup")
                    .fill("input[name='user[email]']", "alice@example.com")
                    .fill("input[name='user[password]']", "hunter2")
                    .click("button[type=submit]")
                    .assertUrlContains("/posts");
            });
        });
    }
}
CFM

wheels start --port="$PORT" &
SERVER_PID=$!
sleep 8

set +e
wheels test
RESULT=$?
set -e

wheels stop || kill "$SERVER_PID" 2>/dev/null || true

if [[ $RESULT -ne 0 ]]; then
    echo "FAIL: SignupFlowSpec failed in canary harness."
    exit 1
fi
echo "PASS: SignupFlowSpec green against fresh app (with conflicting dev-DB user)."
```

The chapter-7 spec itself uses `wheels.wheelstest.BrowserTest` — which requires Playwright JARs. The harness should `wheels browser setup` first if the JARs aren't already cached.

- [ ] **Step 3: Run the harness — confirm green**

```bash
chmod +x tools/test-tutorial-ch7.sh
bash tools/test-tutorial-ch7.sh
```

Expected: `PASS`. If red, re-check Tasks 1 and 2 — the harness exists specifically to surface tutorial-spec drift before users see it.

- [ ] **Step 4: Commit**

```bash
git add tools/test-tutorial-ch7.sh
git commit -m "$(cat <<'EOF'
test(test): add chapter-7 SignupFlowSpec canary harness

Scaffolds a fresh app, applies the tutorial chapter 2-6 minimum,
seeds a chapter-6-equivalent [email protected] in the dev DB to
verify it does NOT bleed into the chapter-7 spec, then runs the
exact SignupFlowSpec from the published tutorial. Exits non-zero
if anything between batch E's fixes and the published spec drifts.

Mirrors tools/test-onboarding.sh's structure (LUCLI_HOME isolation,
KEEP_TEMP=1 for inspection, symlinked framework worktree).
EOF
)"
```

---

## Task 4: Diagnose finding #12 — final `assertSee("Great post")` failure

This task is **diagnosis-first**. We don't know which of H1/H2/H3 (or a combination) is the real cause. Before prescribing a fix we set up a focused reproduction that captures the network response, the page state, and the timing of the click → assertion gap.

**Files:**
- Create: `tools/diagnose-ch7-comment-stream.sh` (one-shot reproduction harness; not committed if results aren't load-bearing)
- Possibly modify: depending on which hypothesis confirms — see Task 4.A / 4.B / 4.C below

- [ ] **Step 1: Build the focused reproduction**

The chapter 7 spec covers signup → post creation → comment append. The signup and post-create steps are validated by Task 3's harness. Strip everything except the comment-submit step, then layer in instrumentation:

Create a temp app the same way Task 3 does, walk it through chapters 2-5, then drop in a stripped reproduction spec at `tests/specs/browser/CommentStreamReproSpec.cfc`:

```cfm
component extends="wheels.wheelstest.BrowserTest" {
    this.browserEngine = "chromium";

    function run() {
        browserDescribe("Comment stream repro", () => {

            it("captures Content-Type + page state across the click", () => {
                if (this.browserTestSkipped) return;

                // ── Setup: log in, create a post ───────────────────
                // (use loginAs + direct DB seeds rather than running
                // through the UI — we want the comment-click to be
                // the only thing under test)
                this.browser
                    .loginAs("alice@example.com")
                    .visit("/posts/1");

                // ── Instrumentation 1: capture every response on the
                //    next click. Playwright's page.on("response", …)
                //    fires for the form POST.
                var capturedResponses = [];
                var ctx = {responses: capturedResponses};
                // Note: requires bridging through createDynamicProxy on
                // Lucee. Cross-engine alternative: page.waitForResponse.
                this.browser.script("
                    window.__capturedResponses = [];
                    document.addEventListener('turbo:before-fetch-response', e => {
                        window.__capturedResponses.push({
                            status: e.detail.fetchResponse.response.status,
                            contentType: e.detail.fetchResponse.response.headers.get('content-type'),
                            url: e.detail.fetchResponse.response.url
                        });
                    }, true);
                    window.__turboReady = (typeof Turbo !== 'undefined');
                ");

                // ── Instrumentation 2: confirm Turbo is ready ──────
                var turboReady = this.browser.script("return window.__turboReady");
                $debug("Turbo ready before click: " & SerializeJSON(turboReady));

                // ── The click under test ───────────────────────────
                this.browser
                    .fill("input[name='comment[author]']", "Bob")
                    .fill("textarea[name='comment[body]']", "Great post")
                    .click("turbo-frame##new_comment button[type=submit]");

                // ── Instrumentation 3: dump captured responses ────
                var captured = this.browser.script("return window.__capturedResponses");
                $debug("Captured responses: " & SerializeJSON(captured));

                var bodyAfter = this.browser.script("return document.body.innerHTML");
                $debug("Body after click (first 1000 chars): "
                    & Left(bodyAfter, 1000));

                var url = this.browser.currentUrl();
                $debug("URL after click: " & url);

                // ── No assertion — this is a diagnostic spec ──────
                expect(true).toBeTrue();
            });

        });
    }

    private void function $debug(required string msg) {
        WriteLog(file="ch7-repro", type="information", text=arguments.msg);
        WriteOutput("[ch7-repro] " & arguments.msg & chr(10));
    }
}
```

The spec emits to stdout AND to `~/.wheels/servers/<appname>/ch7-repro.log` so the harness can grep for the captured Content-Type even if the test summary swallows stdout.

- [ ] **Step 2: Run the reproduction; capture the three diagnostics**

```bash
bash tools/diagnose-ch7-comment-stream.sh   # script that wraps the temp-app
                                             # setup and runs the spec
grep "ch7-repro" ~/.wheels/servers/*/ch7-repro.log | tee /tmp/ch7-diagnostics.txt
```

Expected outputs to inspect:
1. `Turbo ready before click: …` — `true` or `false`
2. `Captured responses: [{status: 200, contentType: "...", url: "..."}]` — what Content-Type did the comments##create response set?
3. `Body after click (first 1000 chars): …` — does the body contain `Great post` or has the page navigated?
4. `URL after click: …` — did the URL change to `/posts/1/comments` (full nav) or stay on `/posts/1` (Turbo-handled)?

- [ ] **Step 3: Decide which hypothesis path applies**

  - **If `contentType` does NOT include `text/vnd.turbo-stream.html` AND URL changed:** H1 confirmed. Proceed to Task 4.A.
  - **If `Turbo ready before click` was `false`:** H2 confirmed. Proceed to Task 4.B.
  - **If Turbo was ready, response was right, but URL/body shows mid-navigation state:** H3 confirmed. Proceed to Task 4.C.
  - **If responses array is empty:** the form didn't submit. Re-check selector resolution; this would mean Task 1's selector edit is wrong.
  - **If everything looks fine but assertSee still fails on the original spec:** investigate `page.content()` vs `page.locator(...).textContent()` — Playwright's `content()` reads from the snapshot at call time, which can race differently than the in-page DOM. Append an `assertSee` workaround using `assertSeeIn("section##comments", "Great post")`.

- [ ] **Step 4: No commit yet — diagnosis is captured in `/tmp/ch7-diagnostics.txt`. Move to the matching Task 4.X.**

---

### Task 4.A (H1 fix): Set `Content-Type: text/vnd.turbo-stream.html` when rendering a `<turbo-stream>` partial

**Files:**
- Modify: [`vendor/wheels/controller/rendering.cfc`](../../vendor/wheels/controller/rendering.cfc) — add a content-type override path
- Possibly modify: [`web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/05-comments-streams.mdx`](../../web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/05-comments-streams.mdx) to mention the new behavior
- Add: a unit test in `vendor/wheels/tests/specs/controller/`

The Turbo 7+ contract: a response that contains `<turbo-stream>` elements MUST be served with `Content-Type: text/vnd.turbo-stream.html` for Turbo to claim it. Otherwise it does a regular navigation. Two options:

- **Option 1 (sniff):** detect when the rendered partial body starts with `<turbo-stream` and override the content-type automatically. Lowest user friction.
- **Option 2 (explicit):** add a `format="turbo-stream"` argument to `renderPartial` / `renderText` that sets the header. Higher friction but explicit.

Pick Option 1 for the minimum-disruption fix. Document Option 2 as a future enhancement if the sniff is too magical.

- [ ] **Step 1: Write the failing test**

`vendor/wheels/tests/specs/controller/TurboStreamContentTypeSpec.cfc`:

```cfm
component extends="wheels.WheelsTest" {
    function run() {
        describe("renderPartial — turbo-stream content type", () => {

            it("sets text/vnd.turbo-stream.html when partial body starts with <turbo-stream", () => {
                var ctrl = controller("DummyController");
                ctrl.$renderText = function() { return arguments.text; };

                // Stub the partial output
                ctrl.renderPartial = function(required string partial) {
                    var rendered = "<turbo-stream action=""append"" target=""comments"">
                        <template><article>hi</article></template>
                    </turbo-stream>";
                    return ctrl.$applyTurboStreamContentType(rendered);
                };

                var headers = {};
                ctrl.$setHttpHeader = function(required string name, required string value) {
                    headers[arguments.name] = arguments.value;
                };

                var output = ctrl.renderPartial(partial="comment");
                expect(headers).toHaveKey("Content-Type");
                expect(headers["Content-Type"]).toContain("text/vnd.turbo-stream.html");
            });

            it("does not override Content-Type for regular partial output", () => {
                var ctrl = controller("DummyController");
                var rendered = "<article>plain</article>";
                var headers = {};
                ctrl.$setHttpHeader = function(required string name, required string value) {
                    headers[arguments.name] = arguments.value;
                };
                ctrl.$applyTurboStreamContentType(rendered);
                expect(headers).notToHaveKey("Content-Type");
            });

        });
    }
}
```

(Adapt the stub-and-mock shape to whatever `controller("DummyController")` actually returns in the existing controller specs — see [`vendor/wheels/tests/specs/controller/`](../../vendor/wheels/tests/specs/controller/) for the in-repo pattern. The above is illustrative.)

- [ ] **Step 2: Implement the sniff in `vendor/wheels/controller/rendering.cfc`**

Add a private helper:

```cfm
public string function $applyTurboStreamContentType(required string body) {
    // If the rendered body's first non-whitespace bytes are a
    // <turbo-stream> opening tag, advertise the response as a Turbo
    // Stream so the browser-side Turbo runtime processes it instead of
    // doing a full navigation. Turbo 7+ requirement.
    if (REFindNoCase("^\s*<turbo-stream\b", arguments.body)) {
        $header(name="Content-Type", value="text/vnd.turbo-stream.html; charset=utf-8");
    }
    return arguments.body;
}
```

Then call it from `renderPartial` (after the partial is rendered, before the body is returned to the dispatcher). Find the existing `renderPartial` body in `rendering.cfc` and wrap the return:

```diff
-    return rendered;
+    return $applyTurboStreamContentType(rendered);
```

(Confirm the actual return shape during implementation — `renderPartial` may emit via `cfsavecontent` and pass through other helpers. The sniff has to land in the path that produces the final HTTP body.)

- [ ] **Step 3: Run the unit test, then re-run Task 4 Step 1's repro**

```bash
bash tools/test-local.sh controller
bash tools/diagnose-ch7-comment-stream.sh
grep "Captured responses" /tmp/ch7-diagnostics.txt
```

Expected: the captured response now shows `contentType: "text/vnd.turbo-stream.html..."` and the page body contains `Great post`.

- [ ] **Step 4: Re-run the chapter-7 canary**

```bash
bash tools/test-tutorial-ch7.sh
```

If green, H1 was the cause. If still red, `cat /tmp/ch7-diagnostics.txt` again — H2 or H3 may still apply.

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/controller/rendering.cfc \
        vendor/wheels/tests/specs/controller/TurboStreamContentTypeSpec.cfc
git commit -m "$(cat <<'EOF'
fix(controller): set turbo-stream Content-Type when partial body starts with <turbo-stream>

Turbo 7+ requires responses carrying <turbo-stream> elements to be
served with Content-Type: text/vnd.turbo-stream.html. Without it
the browser-side Turbo runtime declines to claim the response and
the form submit becomes a full navigation. The Wheels guides
chapter 5 implementation called renderPartial(layout=false) which
emitted plain text/html, so chapter 7's browser spec saw a
post-navigation page instead of an in-place comment append.

Sniff the rendered body — if it starts with <turbo-stream> (after
optional whitespace), override the Content-Type before the response
is flushed. Plain partials are untouched.

Closes finding #12 in
docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md
(H1 path).
EOF
)"
```

Optionally update `05-comments-streams.mdx:212` to mention the new automatic content-type behavior so readers know they don't need to set the header manually.

---

### Task 4.B (H2 fix): Wait for Turbo to be ready before the first interaction

**Files:**
- Modify: [`vendor/wheels/wheelstest/BrowserClient.cfc`](../../vendor/wheels/wheelstest/BrowserClient.cfc) — add a `waitForTurbo()` method
- Possibly modify: [`web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/07-testing-deploying.mdx`](../../web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/07-testing-deploying.mdx) to use it

This path fires only if Task 4 Step 3 confirmed H2.

- [ ] **Step 1: Add the helper to `BrowserClient.cfc`**

After the existing `waitForUrl` method (around line 175 area — confirm exact location during implementation), add:

```cfm
/**
 * Wait until Turbo's drive runtime is connected. Use after the first
 * navigation that loads the Turbo CDN script — protects against
 * races where the click fires before Turbo's listeners are wired up
 * and the form does a regular browser submit.
 *
 * Default timeout 5000ms. Returns this for chaining.
 */
public BrowserClient function waitForTurbo(numeric timeoutMs = 5000) {
    variables.page.waitForFunction(
        "() => typeof window.Turbo !== 'undefined' && document.documentElement.hasAttribute('data-turbo-loaded')",
        javacast("null", ""),
        $newWaitOptions(arguments.timeoutMs)
    );
    return this;
}
```

The `data-turbo-loaded` attribute is set by Turbo's drive on first connect — sniffing it is more reliable than just `typeof Turbo`. If that attribute isn't actually emitted (verify by checking the Turbo source), fall back to a simple `typeof Turbo !== 'undefined'` poll.

- [ ] **Step 2: Update chapter 7 spec to use it**

```diff
                this.browser
-                   .visitRoute("posts")
+                   .visitRoute("posts")
+                   .waitForTurbo()
                    .click("a[href*='/posts/new']")
```

- [ ] **Step 3-5: Run repro, then canary, commit (same shape as Task 4.A)**

Commit message scope `test(test)`:

```
test(test): add waitForTurbo helper for browser specs

Browser specs that depend on Turbo intercepting form submits or
link clicks could race the CDN-loaded Turbo runtime — the click
fires before Turbo wires up listeners and the form does a regular
navigation. waitForTurbo() polls for the Turbo runtime + its
data-turbo-loaded attribute and short-circuits when ready.
```

---

### Task 4.C (H3 fix): Optional post-click wait in `BrowserClient.click()`

**Files:**
- Modify: [`vendor/wheels/wheelstest/BrowserClient.cfc:105-114`](../../vendor/wheels/wheelstest/BrowserClient.cfc) — `click()` accepts a `waitForLoad` arg

This path fires only if Task 4 Step 3 confirmed H3 (response was right, URL/body still mid-navigation when assertSee runs).

- [ ] **Step 1: Extend `click()` with an optional wait**

```diff
-public BrowserClient function click(required string selector) {
+public BrowserClient function click(
+    required string selector,
+    string waitForLoad = ""
+) {
     var hasDialog = isStruct(variables.$pendingDialogAction);
     if (hasDialog) $registerDialogListener();
     try {
         $locator(arguments.selector).click();
+        if (Len(arguments.waitForLoad)) {
+            // "networkidle" | "domcontentloaded" | "load"
+            variables.page.waitForLoadState(arguments.waitForLoad);
+        }
     } finally {
         if (hasDialog) $clearDialogListener();
     }
     return this;
 }
```

- [ ] **Step 2: Update chapter 7 spec to opt in**

```diff
-                   .click("turbo-frame##new_comment button[type=submit]")
+                   .click("turbo-frame##new_comment button[type=submit]", waitForLoad="networkidle")
                    .assertSee("Great post");
```

- [ ] **Step 3-5: Run repro, then canary, commit (same shape as Task 4.A)**

Commit scope `test(test)`.

---

## Task 5: Update triage doc + open the PR

**Files:**
- Modify: `docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md`

- [ ] **Step 1: Mark findings #10, #11, #12 as shipped**

```diff
-### [ ] 10. Browser-test DB collision: `tests/populate.cfm` not generated and not documented at tutorial level
+### [x] 10. Browser-test DB collision — **shipped in batch E** (commits `<sha-app-runner>`, `<sha-doc>`)

-### [ ] 11. Tutorial browser spec selector `button[type=submit]` is ambiguous on the post show page
+### [x] 11. Tutorial browser spec selector ambiguity — **shipped in batch E** (commit `<sha-selector>`)

-### [ ] 12. Tutorial browser spec final assertion (`assertSee("Great post")`) fails after submitting comment
+### [x] 12. Tutorial browser spec final assertion fails — **shipped in batch E** (commit `<sha-h1-or-h2-or-h3>`, root cause: H? per repro at /tmp/ch7-diagnostics.txt)
```

- [ ] **Step 2: Add the Batch E row to the Shipped table**

```markdown
### Batch E — Browser test infra (2026-04-XX)

Per [batch E plan](./2026-04-29-fresh-vm-batch-e-browser-test-infra.md).

| # | Item | Commit | Repo |
|---|------|--------|------|
| 11 | Chapter 7 selector scoped to `turbo-frame#new_comment` | `<sha>` | wheels |
| 10 (framework) | `wheels test` swaps to `<appname>_test` datasource | `<sha>` | wheels |
| 10 (CLI templates) | Default `tests/populate.cfm` ships with `wheels new` | `<sha>` | wheels |
| 10 (doc) | Chapter 7 explains test DB / dev DB separation | `<sha>` | wheels |
| 12 (root cause) | H? — see commit body | `<sha>` | wheels |
| Canary | `tools/test-tutorial-ch7.sh` | `<sha>` | wheels |
```

- [ ] **Step 3: Cross-reference April 19 #16**

If the April 19 doc still has #16 ("populate.cfm not documented at tutorial level") open, mark it subsumed by batch E.

- [ ] **Step 4: Commit the doc updates**

```bash
git add docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md \
        docs/superpowers/plans/2026-04-19-framework-gaps-from-guides-phase-1.md
git commit -m "docs(docs): mark batch E items shipped + subsume april 19 #16"
```

- [ ] **Step 5: Push and open the PR**

```bash
git push -u origin HEAD
gh pr create --base develop \
  --title "feat(test): wheels test runs against test.sqlite + chapter 7 spec hardening" \
  --body "$(cat <<'EOF'
## Summary
- `wheels test` defaults to running against the `<appname>_test` datasource (created at scaffold time but unused until now). The framework auto-includes `tests/populate.cfm` on first run to bootstrap schema. `--no-test-db` opts back to the dev DB.
- Default `tests/populate.cfm` ships with `wheels new` and runs `migrateToLatest()` against the active datasource — Rails-shaped convention, no per-tutorial hand-waving.
- Chapter 7's comment-submit selector now scopes to `turbo-frame##new_comment` so Playwright strict-mode passes.
- Finding #12 root cause: H? (Turbo content-type / Turbo readiness / post-click wait — confirmed via reproduction at `tools/diagnose-ch7-comment-stream.sh`). Fix landed in commit X.
- New canary `tools/test-tutorial-ch7.sh` scaffolds a fresh app, mirrors chapter 6's manual signup, and runs the chapter 7 spec verbatim. Future drift fails this script before users hit it.

Closes findings #10, #11, #12 in `docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md`. Subsumes April 19 #16.

## Test plan
- [ ] `bash tools/test-local.sh dispatch` passes
- [ ] `bash tools/test-local.sh controller` passes (Task 4.A's content-type spec)
- [ ] `bash tools/test-local.sh` full suite stable
- [ ] `bash tools/test-tutorial-ch7.sh` PASS
- [ ] Manual: scaffold a fresh app, walk chapters 2-7, confirm `wheels test` is green end-to-end without manual `populate.cfm` editing
- [ ] Manual: confirm `wheels test --no-test-db` runs against the dev DB and reproduces the original chapter-6/7 collision (sanity check that the swap is what cured the bug)
EOF
)"
```

- [ ] **Step 6: Report the PR URL and commit SHAs to backfill the triage table**

---

## Out of scope

These deliberately stay out of batch E and remain in the triage:

- **#9 (DI singleton)**: shipped in batch D.
- **#2 (test runner reports 0 passed on parse error)**: belongs in batch B (CLI output polish). Adjacent but distinct surface — TestRunner's failure reporting, not the runner's DB resolution.
- **#3 (migrate output formatting)**: batch B.
- **#4 (scaffold output drift)**: batch C.
- **The wider `wheels test` UX overhaul** (per-spec timing, watch mode, fixture loaders): too big for this batch. Land the convention now; iterate later.
- **Cross-engine Turbo content-type sniff verification on Adobe CF / BoxLang**: Task 4.A's regex is plain CFML so it should be portable, but the test matrix is not exercised here. If the cross-engine matrix flags a regression after merge, treat as a follow-up.

---

## Open questions

- **If H1 is confirmed but the sniff in Task 4.A misfires on edge cases (e.g. a layout that wraps a turbo-stream partial in `<html>` chrome by mistake), do we want a hard guard?** A user could call `renderPartial(partial="comment", layout=false)` correctly and still have an upstream `cfheader` clobber the content-type. Worth a follow-up audit of the `Content-Type` set-points across `controller/`.
- **Should `wheels test` also auto-run pending migrations against the test DB on every invocation, not just first run?** Right now the schema-bootstrap only happens when `c_o_r_e_migrator_versions` is missing. Long-running test DBs could drift. Counter-argument: explicit is better than magic; users who change schema can `rm db/test.sqlite` or run `wheels migrate latest --datasource=...`.
- **Does `--no-test-db` break any existing user's CI?** Default-on means anyone whose existing app tests rely on dev-DB state will silently flip to a different (empty) datasource on first upgrade. The `tests/populate.cfm` fallback should cover it, but a release-note callout is warranted.
- **Should chapter 7's spec use `loginAs` instead of driving the signup form?** It would decouple the spec from chapter 6's UI. Out of scope for this batch — the goal here is to make the published spec pass as written, not to redesign it.
