# Fresh-VM Onboarding Findings — 2026-04-29

**Source:** end-to-end fresh-VM run of the public Getting Started tutorial (`https://guides.wheels.dev/v4-0-0-snapshot/start-here/...`) by a first-time-user persona on 2026-04-29. Full journal and report attached to the originating session; quoted error output below is verbatim from that run.

**Format:** triage roadmap modeled on [Framework + CLI Gaps Surfaced During Guides Phase 1](./2026-04-19-framework-gaps-from-guides-phase-1.md). Each item is a self-contained work card. Pick one, fix it, tick the box.

**Priority key:** P0 = blocks tutorial for real users · P1 = polishes the happy path · P2 = nice-to-have

**Cross-reference key:** several findings here are downstream of (or duplicates of) open entries in the April 19 doc. Where that's the case it's called out inline. The fresh-VM run independently confirms those entries are still biting users.

---

## Shipped

### Batch A — Doc-only sweep (2026-04-29)

Per [batch A plan](./2026-04-29-fresh-vm-batch-a-doc-sweep.md).

| # | Item | Commit | Repo |
|---|------|--------|------|
| 5 | Chapter 1 file tree — **verified accurate**, no edit needed | (verification only) | wheels |
| 6 | Cold reload defined inline in chapter 6 | `6a9a6d848` | wheels |
| 1 (doc) | Install page version-surface callout | `96ee165e6` | wheels |

**New sub-finding surfaced during batch A reconnaissance:** `wheels new` creates `tests/specs/{controllers,functional,models}/` directories but does **not** copy the `.gitkeep` files from `cli/lucli/templates/app/tests/specs/*/.gitkeep`. Empty directories won't survive a git commit. Shipped in batch B.

### Batch D — Auth + DI blocker (2026-04-29)

Per [batch D plan](./2026-04-29-fresh-vm-batch-d-di-singleton.md).

| # | Item | Commit (squash) | Repo |
|---|------|--------|------|
| 9 | `asSingleton()` survives framework Bindings | `cbd18c56b` | wheels |
| 9 (error msg) | Diagnostic error when no strategies registered | `cbd18c56b` | wheels |
| 9 (regression) | InjectorLifecycleSpec + iteration-order smoke | `cbd18c56b` | wheels |

### Batch B — CLI output polish (2026-04-29)

Per [batch B plan](./2026-04-29-fresh-vm-batch-b-cli-polish.md).

| # | Item | Commit | Repo |
|---|------|--------|------|
| sub | `.gitkeep` files copied so empty test dirs survive git | `3d72fa272` | wheels |
| 3 | `wheels migrate` emits CRLF | `f9bf3e239` | wheels |
| 2 | `wheels test` surfaces silent compile errors | `aa557a229` | wheels |
| 8 | `wheels reload` notes that `onApplicationStart` does not re-fire | `b59793ca4` | wheels |
| 7 | `wheels destroy` accepts `<type> <name>` order | `c39f5e5f4` | wheels (shipped via PR #2360, separate workstream) |

### Batch E — Browser test infrastructure (2026-04-29)

Per [batch E plan](./2026-04-29-fresh-vm-batch-e-browser-test-infra.md).

| # | Item | Commit | Repo |
|---|------|--------|------|
| 11 | Chapter 7 selector scoped to new-comment frame | `f274677de` | wheels |
| 10 | `wheels test` runs against `<appname>_test` datasource by default | `80be9f8cc` | wheels |
| 10 (doc) | Chapter 7 explains test-DB isolation | `80b8c61b1` | wheels |
| 10 (canary) | `tools/test-tutorial-ch7.sh` regression harness | `375673f03` | wheels |
| 12 | `Content-Type: text/vnd.turbo-stream.html` for stream responses | `21df38ac1` | wheels |

Subsumes April 19 #16 (`tests/populate.cfm` not documented at tutorial level).

---

## Suggested PR-sized batches

These are scoping suggestions only — re-batch as needed when picking work.

| Batch | Items | Repo(s) | Risk | Why grouped |
|-------|-------|---------|------|-------------|
| **A — Doc-only sweep** | #1 (text portion), #5, #6, #7, #8 | wheels (web/sites/guides) | low | All edits to `web/sites/guides/src/content/docs/.../start-here/`. Single PR, straightforward review, immediately improves next fresh-VM run. |
| **B — CLI output polish** | #2 (test runner parse-error surfacing), #3 (migrate output newlines) | wheels (cli/lucli/), possibly LuCLI | low | Both touch `cli/lucli/services/` output formatting. Independent of framework. Subsumes April 19 #15. |
| **C — Scaffold templates align with tutorial** | #4 (scaffold output drift), the enum→select sub-finding | wheels (vendor/wheels/snippets/, cli/lucli/templates/snippets/) | medium | Template overhaul. Needs cross-engine verification. Touches existing scaffold tests. |
| **D — Auth + DI blocker** | #9 (DI singleton bug), the silent-no-strategies failure mode | wheels (vendor/wheels/lib/Injector.cfc, vendor/wheels/auth/) | high | Real framework bug. Investigate before guessing at fix. Subsumes/unblocks April 19 #6 and #7. |
| **E — Browser test infra** | #10 (test DB seed gap), #11 (selector ambiguity in tutorial spec), #12 (turbo-stream final assertion) | wheels (cli/lucli/, vendor/wheels/wheelstest/, web/sites/guides) | medium | Test runner DB convention + tutorial spec hardening + a real diagnosis task. Subsumes April 19 #16. |
| **F — Version surface unification** | #1 (framework portion) | wheels (build pipeline, Homebrew formula) | medium | Three surfaces report three different versions. Touches release engineering. Defer until A–C land if scoping pressure. |

---

## P0 — Blocks the tutorial for real users

### [x] 9. `wheels.auth.SessionStrategy` cannot be wired up — **shipped in batch D** (squash commit `cbd18c56b`)

**Tutorial location.** [Part 6b — The Built-in Way](https://guides.wheels.dev/v4-0-0-snapshot/start-here/tutorial/06-authentication/), sections "Register the authenticator" through end of chapter.

**Problem.** Following the tutorial verbatim — `config/services.cfm` registering `Authenticator` and `SessionStrategy` as singletons, `onApplicationStart` calling `auth.registerStrategy(name="session", strategy=sessionStrategy)`, controller filter calling `application.wo.service("authenticator").authenticate(request)` — produces a silent failure on every protected request: every request returns `{success: false, error: "No authentication strategy supports this request", strategy: "", statusCode: 401}` and redirects to `/login`. Login itself succeeds (`session.wheels.auth = {ID, EMAIL}` is set), but the next request never finds a registered strategy.

**Diagnosis from the fresh-VM run.**
- Same `application.wo.service("authenticator")` call returns *one* authenticator in `onApplicationStart` (with `getStrategyNames()` → `["session"]`) and a *different* authenticator inside the request handler (with `getStrategyNames()` → `[]`).
- Even moving registration into `onRequestStart` and reading the names back inside the controller filter in the same request returns `[]`.
- This means `injector().map(...).asSingleton()` is **not** caching the resolved instance for `wheels.auth.Authenticator`. Every `service("authenticator")` resolves a fresh component.

**Impact.** Chapter 6b is unfollowable. The tutorial's "Compare" table at the end of chapter 6 advertises 6b as a small line-count win over 6a; in reality 6b is *zero working lines*. New users who pick the "modern" path end up debugging a framework bug they have no way to diagnose.

**Repro.**
```cfm
// config/services.cfm
var di = injector();
di.map("authenticator").to("wheels.auth.Authenticator").asSingleton();
di.map("sessionStrategy").to("wheels.auth.SessionStrategy").asSingleton();

// app/events/onapplicationstart.cfm
var auth = application.wo.service("authenticator");
auth.registerStrategy(name="session", strategy=application.wo.service("sessionStrategy"));
WriteLog(text="onApplicationStart strategies: #SerializeJSON(auth.getStrategyNames())#");

// app/controllers/Posts.cfc — private filter
var auth = application.wo.service("authenticator");
WriteLog(text="filter strategies: #SerializeJSON(auth.getStrategyNames())#");
// First log line:  ["session"]
// Second log line: []
```

**Proposed fix.**

Two parts — both framework:

1. **`asSingleton()` must actually cache.** Read `vendor/wheels/lib/Injector.cfc` (or wherever the DI container's binding-resolution path lives). The `asSingleton()` scope is supposed to memoize the instance after first resolution. Verify whether the cache is keyed correctly, whether it survives across requests, and whether component-loaded-by-name vs `CreateObject` is bypassing the cache. Likely root causes to rule out:
   - The cache lookup is keyed on instance identity instead of binding name.
   - The cache is stored on a per-request scope (`request.$wheelsDICache`) instead of `application` for `asSingleton()`. (CLAUDE.md documents `.asRequestScoped()` uses `request.$wheelsDICache` — `.asSingleton()` should not.)
   - The container itself is being re-created on every `service()` call (e.g. `application.wheelsdi` is rebuilt instead of cached).

2. **Improve the failure mode when no strategies are registered.** `Authenticator.authenticate()` currently returns `"No authentication strategy supports this request"` when zero strategies exist — indistinguishable from "your strategy didn't claim this request." Change the zero-strategies path to return a distinct, diagnostic error: `"No authentication strategies registered. Did onApplicationStart run? Check that registerStrategy() is being called on the same Authenticator instance returned by service('authenticator')."`

**Acceptance criteria.**
- New test: `assert application.wo.service("authenticator") is application.wo.service("authenticator")` for an `asSingleton()` binding (currently fails).
- New test: `Authenticator.authenticate()` with zero strategies returns an error string containing the words "registered" and "registerStrategy".
- Following [Part 6b](https://guides.wheels.dev/v4-0-0-snapshot/start-here/tutorial/06-authentication/) verbatim from a fresh `wheels new` ends with a working session login (no controller-side workaround needed).

**Files likely involved.**
- `vendor/wheels/lib/Injector.cfc`
- `vendor/wheels/auth/Authenticator.cfc`
- `vendor/wheels/wheelstest/system/specs/lib/InjectorSpec.cfc` (or equivalent — verify scope behavior under test)

**Cross-reference.** Subsumes/unblocks April 19 [#6](./2026-04-19-framework-gaps-from-guides-phase-1.md) ("auth convenience helper") and [#7](./2026-04-19-framework-gaps-from-guides-phase-1.md) ("services.cfm load behavior"). The convenience helper from #6 cannot be built until the singleton bug here is fixed.

**Doc hedge until fixed.** Until the DI bug is resolved, the chapter 6 "Compare" section should recommend 6a as the only working path for 4.0-SNAPSHOT, with a note that 6b is "in progress."

---

## P1 — Polishes the happy path

### [ ] 4. `wheels generate scaffold` output disagrees with chapter 3 of the tutorial

**Tutorial location.** [Part 3 — CRUD scaffold](https://guides.wheels.dev/v4-0-0-snapshot/start-here/tutorial/03-crud-scaffold/), sections "The controller", "The form partial", "The four views".

**Problem.** The tutorial introduces chapter 3 with: *"`wheels generate scaffold` creates the controller, the seven CRUD views, and (if it didn't already exist) the model and migration in one shot."* Then a `<Steps>` block instructs the reader to "Create `app/controllers/Posts.cfc`" with a specific code body. The body shown in the guide does **not** match what the scaffold actually emits.

**Repro.**
```bash
wheels new blog
cd blog
wheels generate model Post title:string body:text status:enum
wheels migrate latest
wheels generate scaffold Post title:string body:text status:enum
```

**Drift between scaffold output and tutorial body:**

| Surface | Tutorial shows | Scaffold actually emits |
|---|---|---|
| `Posts.cfc` `show/edit/update/delete` | route-model-binding (`post = params.post`) | `findByKey(params.key)` |
| `Posts.cfc` redirects | `redirectTo(route="post", key=post.id)` | `redirectTo(action="index", success="...")` |
| `Posts.cfc` create flow | `model("Post").new(params.post)` + `.save()` | `model("post").create(params.post)` + `hasErrors()` |
| `Posts.cfc` not-found handling | implicit (binding throws 404) | explicit `objectNotFound` handler + `verifies(...handler="objectNotFound")` |
| `_form.cfm` | `startFormTag` + `errorMessagesFor` + submit `<button>` + `select` for `status` | three lines: `textField`, `textArea`, `textField` (for `status`) — no form wrapper, no error display, no submit |
| `index.cfm` | clean `<article>` markup | Bootstrap-styled `<table class="table">` |
| `show.cfm` | `<h1>#post.title#</h1>` | "View Post" header + Bootstrap buttons |
| Test files | not mentioned | also generates `tests/specs/models/PostSpec.cfc` + `tests/specs/controllers/PostsControllerSpec.cfc` |
| `config/routes.cfm` | not modified by scaffold | injects `.resources("posts")` even though chapter 2 already added `.resources(name="posts", only="index,show")` — leaves a duplicate |

**Impact.** A reader following the tutorial verbatim either hand-overwrites every scaffolded file (what I did) or stops here. **This is the chapter most likely to make a user give up.**

**Proposed fix.** Two routes — pick one or do both:

- **Doc fix (faster):** re-frame chapter 3 as *"Generate the scaffold, then replace these files with the cleaner versions below."* Add a "What the scaffold actually emits" callout. Document the route duplication and how to clean it up. Mention the generated specs explicitly.
- **CLI/template fix (better long-term, batch C):** update the scaffold templates so they emit what the tutorial shows. Specifically:
  - Use route-model-binding by default in `Posts.cfc`.
  - Drop Bootstrap classes from `index.cfm` and `show.cfm`.
  - Make `_form.cfm` self-contained: `startFormTag/endFormTag`, `errorMessagesFor`, submit button.
  - Detect enum-typed properties on the model and emit `select(options=...)` populated from the declared values (sub-finding: `status:enum` currently produces `textField`, ignoring the model's `enum(...)` declaration).
  - Don't double-add a `.resources` line if one already exists for the same resource. Detect the existing line and skip or merge instead.
  - Document (or hide) the auto-generated specs so chapter 7 isn't surprising.

**Acceptance criteria.**
- After `wheels new blog && cd blog && wheels generate model Post title:string body:text status:enum && wheels migrate latest && wheels generate scaffold Post title:string body:text status:enum`, the generated files match (or are documented to differ from) the bodies shown in chapter 3.
- `config/routes.cfm` does not contain a duplicate `.resources("posts")` line.
- The form helper for `status:enum` renders a `<select>` with the enum values, not a free-text input.

**Files likely involved.**
- `vendor/wheels/snippets/*.txt` (framework template source)
- `cli/lucli/templates/snippets/*.txt` (LuCLI generator templates)
- `cli/lucli/services/generators/` (scaffold orchestration, route injection)
- `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/03-crud-scaffold.mdx`

---

### [x] 10. Browser-test DB collision — **shipped in batch E** (commit `80be9f8cc` framework + `80b8c61b1` doc + `375673f03` canary)

**Tutorial location.** [Part 7 — Testing & Deploying](https://guides.wheels.dev/v4-0-0-snapshot/start-here/tutorial/07-testing-deploying/), section "Browser spec — full signup to post to comment".

**Problem.** `wheels test` runs against `db/test.sqlite`, which `wheels migrate` does not migrate by default — only `db/development.sqlite` is migrated. The tutorial's `SignupFlowSpec.cfc` therefore runs against the dev DB through the running dev server. The dev DB already contains `[email protected]` (from chapter 6's "Test 6a manually" walkthrough). When the browser test signs up `[email protected]` again, uniqueness validation fires, the form re-renders `/signup`, and the test fails:

```
Expected URL to contain '/posts', got '/signup'
```

The tutorial mentions `tests/populate.cfm` only in troubleshooting and never instructs creating it.

**Impact.** The tutorial closes by saying "Click through the running app one more time" implying `wheels test` passes. It does not. The reader is left holding a broken test on the last page.

**Proposed fix.** Choose one (or both):

- **Framework/CLI fix (preferred, batch E):** `wheels test` should default to using `db/test.sqlite` with migrations applied automatically — Rails convention. The reader doesn't manage two databases by hand. *Or* `wheels new` should generate `tests/populate.cfm` with a comment explaining what it's for.
- **Doc fix (immediate, batch A):** the tutorial's browser spec should:
  - Use a unique email per run via `getTickCount()` or a `beforeEach` that wipes the user.
  - Or include a `tests/populate.cfm` snippet that resets the relevant tables.
  - Either way, demonstrate the convention rather than relying on a clean DB.

**Acceptance criteria.**
- A reader following chapter 7 from a clean checkout — having previously completed chapter 6's manual signup of `[email protected]` — can run `wheels test` and have the browser spec pass.

**Files likely involved.**
- `cli/lucli/services/test/` (test runner — DB resolution)
- `vendor/wheels/wheelstest/` (test bootstrap — populate hook)
- `cli/lucli/templates/scaffold/tests/populate.cfm` (new file? or existing template needs surfacing)
- `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/07-testing-deploying.mdx`

**Cross-reference.** Same surface as April 19 [#16](./2026-04-19-framework-gaps-from-guides-phase-1.md) ("populate.cfm not documented at tutorial level"). The fresh-VM run confirms it's still biting.

---

### [x] 11. Tutorial browser spec selector `button[type=submit]` is ambiguous on the post show page — **shipped in batch E** (commit `f274677de`)

**Tutorial location.** Same chapter 7 section as #10.

**Problem.** The post show page (after chapter 5's comments work) has both a `Delete` button (from `buttonTo(method="delete")`) **and** a `Post comment` button. The tutorial spec uses the bare selector `button[type=submit]` to target "Post comment." Playwright strict mode rejects this:

```
strict mode violation: locator("button[type=submit]") resolved to 2 elements:
  1) <button type="submit">Delete</button>
  2) <button type="submit">Post comment</button>
```

The test fails before exercising the comment form.

**Impact.** Even after working around #10, the tutorial spec fails on the next assertion. Blocker for completing chapter 7.

**Proposed fix.** Doc fix — narrow the selector. The new-comment form is wrapped in `<turbo-frame id="new_comment">`, so `turbo-frame##new_comment button[type=submit]` is unambiguous. (Reminder for tutorial readers: CFML `##` escapes a literal `#` inside CSS selectors in CFML strings.)

**Acceptance criteria.** Tutorial spec runs to completion without strict-mode violations.

**Files likely involved.**
- `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/07-testing-deploying.mdx`

**Process suggestion.** The doc-site verify-docs harness clearly does not exercise this spec. Consider adding a CI step that runs the chapter 7 browser spec end-to-end against a freshly-scaffolded app before publishing tutorial changes — the same drift would be caught automatically.

---

### [x] 12. Tutorial browser spec final assertion fails after submitting comment — **shipped in batch E** (commit `21df38ac1`, H1 fix: Content-Type for stream responses; end-to-end browser-spec verification deferred to canary harness once Playwright JARs ship in CI)

**Tutorial location.** Same chapter 7 section as #10/#11.

**Problem.** Even after fixing #10 (unique email) and #11 (narrowed comment selector), the final `assertSee("Great post")` after submitting the comment fails. Suspected cause from the fresh-VM run: the response from the `comments##create` endpoint is a `<turbo-stream>` element (`text/html` MIME type), and Playwright treats it as a navigation rather than letting Turbo intercept and process it. Could also be a Turbo CDN script load timing issue — the test browser may not finish loading the Turbo runtime before the click. Not fully diagnosed.

**Impact.** The tutorial's headline browser test does not pass as written.

**Proposed fix.** Investigation task. Options include:
- Verify the Turbo CDN script is loaded and ready before the click — add `assertVisible("turbo-frame##new_comment form")` or wait for Turbo's `turbo:load` event.
- Check whether the `comments##create` response sets the correct `Content-Type` header (`text/vnd.turbo-stream.html`) so Turbo claims it instead of the browser performing a full navigation.
- Confirm the chapter 5 implementation actually emits the `<turbo-stream>` shape the test expects. The fresh-VM run confirmed it does for `curl`, but a real browser test exercises the JS side.

**Acceptance criteria.** Chapter 7 browser spec completes with all assertions passing.

**Files likely involved.**
- `app/controllers/Comments.cfc` (response shape and `Content-Type`)
- `app/views/layout.cfm` (Turbo CDN script tag — load ordering)
- `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/07-testing-deploying.mdx`
- `vendor/wheels/wheelstest/browser/` (DSL — does it set the right Accept headers / waits?)

---

### [x] 2. `wheels test` reports "0 passed" when a spec fails to compile — **shipped in batch B** (commit `aa557a229`)

**Tutorial location.** Chapter 7 (also a general framework concern).

**Problem.** Introduced a CFML parse error in a spec file (unescaped `#` inside a CSS selector string: `"turbo-frame#new_comment button[type=submit]"`). Lucee fails to compile with `Invalid Syntax Closing [#] not found at SignupFlowSpec.cfc:27`. **`wheels test` from the CLI reports `0 passed` with no warning, no error count, no path of the broken spec.** The user has to navigate to `/wheels/app/tests` in a browser to see the actual error.

**Impact.** Extremely confusing failure mode. New users will introduce parse errors (it's CFML; the `#` rules are non-obvious) and have no idea why their test count is zero. Several minutes of "did I delete my tests?" before discovering the runner's silence.

**Proposed fix.** CLI fix in `cli/lucli/services/test/`. When the runner can't compile a spec, surface that distinctly from "no specs passed":

```
Running app tests (sqlite)...
⚠ Could not compile tests/specs/browser/SignupFlowSpec.cfc:
    Invalid Syntax: Closing [#] not found at line 27
Continuing with the rest of the suite...
5 passed, 0 failed, 1 spec failed to load
```

Anything that distinguishes "all clear" from "your spec is broken and we silently skipped it."

**Acceptance criteria.**
- New CLI spec: introduce a deliberately broken `tests/specs/foo.cfc`, run `wheels test`, assert exit code is non-zero and stdout contains the broken file's path and the parse error.
- Total counts at the end of a run report "X failed to compile" separately from "X failed."

**Files likely involved.**
- `cli/lucli/services/test/TestRunnerCli.cfc` (or equivalent — verify path)
- `cli/lucli/tests/specs/services/test/`

**Cross-reference.** Subsumes April 19 [#15](./2026-04-19-framework-gaps-from-guides-phase-1.md) ("test runner output format needs verification") — fresh-VM run gives a concrete, fixable case.

---

### [x] 3. `wheels migrate` output mis-formatted — **shipped in batch B** (commit `f9bf3e239`)

**Tutorial location.** [Part 2 — First model](https://guides.wheels.dev/v4-0-0-snapshot/start-here/tutorial/02-first-model/), section "Run the migration."

**Problem.** Output of `wheels migrate latest` collapses section header, divider, and per-table result onto a single line:

```
Migrating from 0 up to 20260428225339.-------- 20260428225339_create_posts_table -----------------Created table posts
```

Multi-migration runs (chapter 6) are even worse — both migrations on one line. Tutorial says expected output is `Migrating up <timestamp>_create_posts_table.cfc` followed by `Migration complete.` Neither line is in the actual output.

**Impact.** Cosmetic but loud — first thing a reader sees from `wheels migrate` is mangled. "Did the migration even run?" The reader has to inspect the DB to confirm.

**Proposed fix.** Two parts:
- **CLI fix:** add newlines between the `Migrating from` header, the `--------` divider, and each per-migration result line. Verify in `cli/lucli/services/migrate/` (or wherever `wheels migrate` aggregates output from the migrator).
- **Doc fix:** update [chapter 2's](https://guides.wheels.dev/v4-0-0-snapshot/start-here/tutorial/02-first-model/) expected-output text to match what the (fixed) CLI emits. Same edit needed in chapter 5 and chapter 6 where multi-migration runs are shown.

**Acceptance criteria.**
- `wheels migrate latest` emits output where each migration takes 3+ visible lines (header, divider, per-table summary).
- Tutorial chapters 2/5/6 expected-output blocks match the CLI's actual output verbatim.

**Files likely involved.**
- `cli/lucli/services/migrate/MigrateCli.cfc` or equivalent
- `vendor/wheels/migrator/` (if formatting comes from the migrator's own output)
- Tutorial chapters 2, 5, 6

---

### [~] 5. Tutorial chapter 1 file tree disagrees with reality — **verified accurate** during batch A (Task 0); was a stale-cache false positive in the original fresh-VM report

**Tutorial location.** [Part 1 — Hello, Wheels](https://guides.wheels.dev/v4-0-0-snapshot/start-here/tutorial/01-hello-wheels/), section "What got created."

**Problem.** Two specific drift points in the file tree:

1. The tree lists `app/controllers/events`, `app/controllers/global`, `app/controllers/jobs`, etc. as children of `app/controllers/`. Those directories are *siblings* of `app/controllers/`, not children. The indentation is misleading.
2. The tree shows `tests/specs/{controllers, functional, models}` as scaffolded subfolders. Only `tests/specs/` exists in fresh apps. Subfolders appear later when `wheels generate scaffold` runs (per finding #4).

**Impact.** Confusing for ~30 seconds; doesn't block. But it does make a reader wonder "is my install correct?" on the first scaffold inspection.

**Proposed fix.** Doc fix — re-render the directory tree with correct nesting. Either remove the `tests/specs/*` subfolders or have `wheels new` create them as empty placeholders with a `.gitkeep`.

**Acceptance criteria.** A reader running `wheels new blog && tree blog -L 3` sees a directory tree that matches the tutorial's "What got created" section exactly.

**Files likely involved.**
- `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/01-hello-wheels.mdx`
- (Optionally) `cli/lucli/templates/scaffold/tests/specs/{controllers,functional,models}/.gitkeep`

---

### [x] 6. "Cold reload" terminology used without definition — **shipped in `6a9a6d848`** (batch A)

**Tutorial location.** [Part 6b](https://guides.wheels.dev/v4-0-0-snapshot/start-here/tutorial/06-authentication/) — "On a cold reload this registers the strategy exactly once" (and similar phrasing).

**Problem.** A new user reasonably assumes "cold reload" means `wheels reload`. It doesn't — `wheels reload` does not re-fire `onApplicationStart`. To re-execute init code you need `wheels stop && wheels start`. This is implicit knowledge the tutorial doesn't surface.

**Impact.** Once finding #9 (DI singleton) is fixed, this becomes the next thing that bites — readers edit their init code, run `wheels reload`, see no change, and wonder why.

**Proposed fix.** Two routes:
- **Doc fix (immediate):** spell out "cold reload = `wheels stop && wheels start`" the first time the term appears in the auth chapter. Add a short explainer in the framework's reload-lifecycle reference.
- **CLI fix (longer):** add a `wheels reload --cold` (or `wheels restart`) command that does the stop-and-start, so the doc instruction is `wheels restart` and there's no friction.

**Acceptance criteria.**
- Tutorial readers can find a one-line definition of "cold reload" the first time it's used.
- (Optional) `wheels restart` exists as a single command.

**Files likely involved.**
- `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/06-authentication.mdx`
- `web/sites/guides/src/content/docs/v4-0-0-snapshot/working-with-wheels/cli/` (reload-lifecycle reference)
- `cli/lucli/services/server/` (optional `wheels restart`)

---

### [x] 7. `wheels destroy` accepts `<type> <name>` order — **shipped via PR #2360** (commit `c39f5e5f4`, separate workstream from #2313 F16)

**Tutorial location.** [Part 3](https://guides.wheels.dev/v4-0-0-snapshot/start-here/tutorial/03-crud-scaffold/), section "Delete Part 2's handiwork."

**Problem.** Wheels uses `<name> [type]` (`Posts controller`) where Rails users expect `<type> <name>` (`controller Posts`). The tutorial does call this out, so this is purely an enhancement.

**Impact.** Rails users will naturally type the wrong order at least once when they're not following the tutorial.

**Proposed fix.** CLI fix — accept both orders, or detect `wheels destroy controller Posts` and suggest the correct form:

```
$ wheels destroy controller Posts
ⓘ Did you mean: wheels destroy Posts controller ?
   (Wheels uses <name> [type], not <type> <name>.)
```

**Acceptance criteria.** `wheels destroy <known-type> <name>` is detected and produces a friendly correction suggestion instead of an opaque error.

**Files likely involved.**
- `cli/lucli/services/destroy/` (or wherever destroy is implemented)

---

### [x] 8. `wheels reload` doesn't re-fire `onApplicationStart` — **shipped in batch B** (commit `b59793ca4`)

Captured separately from #6 because #6 is the doc fix and this is the framework consideration.

**Problem.** Currently `wheels reload` re-loads the framework code but does not re-fire `onApplicationStart`. This is the standard ColdBox/CFML reload semantics, but it surprises users coming from Rails/Django where init runs on every restart.

**Impact.** Tied to #6 above; once a user knows the rule, they cope. The friction is for first-time users.

**Proposed fix.** Don't change reload semantics — that would break existing apps. Instead, make the contract more discoverable:
- `wheels reload` output should mention "(Note: `onApplicationStart` is not re-run; use `wheels stop && wheels start` for cold init.)"
- Optionally, a `--cold` flag on `wheels reload` or a `wheels restart` alias that does the cold path.

**Acceptance criteria.** A user running `wheels reload` after editing `onapplicationstart.cfm` sees a hint that init code didn't re-run.

**Files likely involved.**
- `cli/lucli/services/server/` (reload command)

---

## P2 — Nice-to-have polish

### [~] 1. Three different version strings reported across surfaces — **doc note shipped in `96ee165e6`** (batch A); framework fix still open (batch F)

**Where.** Anywhere a Wheels version is shown.

**Problem.** Three surfaces, three different answers — observed during the same fresh-VM session:

| Surface | Reported |
|---|---|
| `brew info wheels` (formula) | `4.0.0-SNAPSHOT+1632` |
| `wheels --version` (CLI runtime) | `4.0.0-SNAPSHOT+1630` (one moment), `4.0.0-SNAPSHOT+1632` (later) |
| In-page debug bar (rendered HTML) | `Wheels 0.0.0-dev` |

**Diagnosis.**
- The brew formula and CLI runtime drift apart when the formula bundles a different framework SHA than the CLI was built against.
- The `0.0.0-dev` in the debug bar comes from `vendor/wheels/`'s own version metadata. The Homebrew formula is not stamping a release version into the framework source it vendors, so the framework reports its in-tree dev version instead of the released number.

**Impact.** "Is my install correct?" becomes hard to answer. Bug reports include a version that's not the version that's actually running.

**Proposed fix.**
- **Build/release fix:** the Homebrew formula's `install` step should stamp the release version into `vendor/wheels/` (e.g. write `vendor/wheels/version.cfc` with the resolved version) at install time, the same way it stamps the CLI version. The `0.0.0-dev` placeholder in the source tree is fine for development; the released artifact should always carry a real version.
- **CLI fix:** investigate why `wheels --version` flickered between `+1630` and `+1632` mid-session — likely a stale cache or a subprocess reading from a different binary. Make the version-detection path deterministic.
- **Doc fix:** make sure the install page's verification step (`wheels --version`) explicitly mentions what to expect and where to look if the answer disagrees with the brew formula version.

**Acceptance criteria.**
- After `brew install wheels`, all three surfaces report the same version string.
- `wheels --version` returns the same value across consecutive invocations in the same session.

**Files likely involved.**
- `https://github.com/wheels-dev/homebrew-wheels` formula
- `cli/lucli/` version-detection path
- `vendor/wheels/` version metadata source (likely `vendor/wheels/version.cfc` or `BuildInfo.cfc`)
- Web debug-bar template

---

## What worked (don't regress)

Captured here so that whoever picks up the next batch knows what *not* to break:

- `wheels new` and `wheels start` from a non-project directory (auto-walks up to find the project).
- `wheels reload` after every code change — fast and quiet.
- Generators for `model`, `migration`, and the migration round-trip on SQLite/arm64.
- Chapter 4 (validations + Turbo Frame) and chapter 5 (comments + Turbo Streams) — cleanest chapters, no drift.
- Chapter 6a (hand-rolled session auth) — works end-to-end.
- `wheels browser setup` — single command, stays out of the way.
- The dev-mode debug bar (matched route, controller/action, params, environment, timing) — high signal, zero setup.

---

## Open questions

- **Is the DI singleton bug (#9) reproducible without auth?** Worth a focused unit test that ignores `Authenticator` entirely — register an arbitrary `MyService` as `asSingleton()`, resolve it twice, assert identity. Confirms the bug is in the container, not in `Authenticator`.
- **Should `wheels test` migrate `db/test.sqlite` automatically (Rails-style), or just document the convention?** Rails-style is friendlier but has a config-discoverability cost. Pick before starting batch E.
- **Is the chapter 7 browser-test final assertion (#12) a Turbo wiring bug, a tutorial timing bug, or a framework wheelstest DSL bug?** Diagnosis required before fix. Likely a combination.
