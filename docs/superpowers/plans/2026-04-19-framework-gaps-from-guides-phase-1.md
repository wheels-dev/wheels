# Framework + CLI Gaps Surfaced During Guides Phase 1

**Source:** probing conducted while writing the v4 guides' "Build a Blog" tutorial in April 2026. See [Phase 1 report](./2026-04-18-guides-rewrite-phase-1-report.md) for the work that surfaced these.

**Format:** each item is a self-contained work card. Pick one, fix it, tick the box. No need to re-read the Phase 1 session context.

**Priority key:** P0 = blocks tutorial for real users · P1 = polishes the happy path · P2 = nice-to-have

---

## Shipped (2026-04-20 batch)

First batch of fixes landed on branches `claude/framework-gaps-batch-1` in both wheels and LuCLI repos.

| # | Item | Commit | Repo |
|---|------|--------|------|
| 3 | `wheels cfml` exit code | `dc3e20d` | LuCLI |
| 12 | `JAVA_HOME` preflight detection | `0d5b0ca` | LuCLI |
| 9 | Stale `wheels server start` in CLI output | `2827c61f2` | wheels |
| 8 | READMEs in empty scaffold directories | `584f04d48` | wheels |
| 1 | Snippet templates bundled into `wheels new` | `b9b165731` | wheels |
| 5 | Route model binding dev-mode warning | `875639f59` | wheels |
| 13 | `data-auto-id` dual emission on form helpers | `7fc905a79` | wheels |

Remaining items below stay open for future batches.

---

## P0 — Blocks the tutorial for real users

### [x] 1. `wheels generate` fails on fresh apps — snippet templates not bundled — **shipped in `b9b165731`**

**Problem.** On a fresh `wheels new <app>`, `wheels generate model|controller|scaffold|migration` errors with `Template not found: ModelContent.txt` (or equivalent for other commands). The generators look in `app/snippets/*.txt` but the scaffolder creates an empty `app/snippets/` directory.

**Repro.**
```bash
wheels new g-probe --no-open-browser
cd g-probe
wheels generate model Post title:string body:text
# → Template not found: ModelContent.txt
```

**Evidence.** Templates exist at:
- `app/snippets/*.txt` (framework source)
- `cli/src/templates/*.txt`
- `cli/lucli/templates/snippets/*.txt` (some of them)

Copying `app/snippets/*.txt` from the framework source into the fresh app makes `wheels generate model` work (verified).

**Impact.** Every `wheels generate *` command in the tutorial breaks for first-time users. Forced the guides-Phase-1 tutorial to teach by hand-writing files instead of generators.

**Proposed fix.** Options in rough ascending order of effort:
- **Option A:** `wheels new` copies `app/snippets/*.txt` templates into the new app at scaffold time. Simplest; directly mirrors what a user has to do manually today.
- **Option B:** `wheels generate` falls back to framework-source templates when the app's local `app/snippets/` is missing a required file. More forgiving but assumes the framework source is reachable.
- **Option C:** move template lookup entirely into the CLI (not the app); `app/snippets/` becomes user override territory only.

**Acceptance criteria.**
- `wheels new foo && cd foo && wheels generate model Post title:string body:text` succeeds and creates `app/models/Post.cfc` + `app/migrator/migrations/<timestamp>_create_posts_table.cfc`
- Same for `wheels generate controller`, `wheels generate scaffold`, `wheels generate migration`
- `wheels new` now either copies the snippets (Option A) or the generator works without them (Option B/C)

**Files likely involved.**
- `cli/src/templates/` (CLI scaffold templates)
- `cli/lucli/templates/snippets/` (LuCLI generator templates)
- `app/snippets/` (what ends up in user apps)
- The `wheels new` command implementation in LuCLI

---

### [ ] 2. Hotwire / Basecoat / Sentry packages not installable in fresh apps

**Problem.** The first-party packages (`hotwire`, `basecoat`, `sentry`, `legacyadapter`) live at `packages/<name>/` in the framework source. Fresh `wheels new` apps don't include a `packages/` directory. CLAUDE.md documents the activation model as `cp -r packages/<name> vendor/<name>`, but a user has nothing to copy from.

No `wheels package install <name>` / `wheels package list` / `wheels package activate` command exists.

**Repro.**
```bash
wheels new pkg-probe --no-open-browser
cd pkg-probe
ls packages/ 2>&1       # doesn't exist
ls vendor/              # wheels/ only
```

**Impact.** The guides tutorial (Parts 3–5) centers on Turbo Drive / Frames / Streams. Without a way to install the `hotwire` package, Part 4 falls back to loading Turbo from a CDN via `<script>` tag. Part 3's "activate Hotwire and Basecoat" story is entirely theoretical. Basecoat-styled scaffolds don't exist for real users.

**Proposed fix.**
- **Option A (minimum viable):** `wheels new` bundles the four first-party packages into `packages/` in the new app. Users activate with `cp -r packages/hotwire vendor/hotwire`. No new commands needed.
- **Option B (better UX):** Add CLI subcommands:
  - `wheels package list` — show available vs activated
  - `wheels package install <name>` — copies from the framework's source tree (or downloads) into `packages/<name>` in the app
  - `wheels package activate <name>` — copies from `packages/<name>` to `vendor/<name>` and reloads
  - `wheels package deactivate <name>` — removes `vendor/<name>`
- **Option C (furthest):** a package registry concept (like `npm`) with versioning. Probably overkill for 4.0.

**Acceptance criteria.**
- A fresh app can activate Hotwire in ≤2 commands
- Documentation for package activation matches actual user experience
- Guides Phase 2 can stop using CDN-loaded Turbo

**Files likely involved.**
- `cli/lucli/` command definitions
- `vendor/wheels/PackageLoader.cfc` (the auto-discovery logic)
- The `wheels new` scaffolder

---

### [x] 3. `wheels cfml` exits 0 when CFML execution fails — **shipped in LuCLI `dc3e20d`**

**Status.** Patch ready. See [docs/superpowers/artifacts/lucli-pr-1/](../artifacts/lucli-pr-1/).

**Problem.** `lucli cfml '<expr>'` catches execution errors, logs them, and falls through to `return result` with `result == null`. picocli maps null Object-returns to exit 0.

**Impact.** Every caller checking exit codes silently accepts failure: shell pipelines, CI, pre-commit hooks, the guides doctest harness. Guides Phase 1's compile driver runs in a bracket-balance fallback mode because of this.

**Fix.** One line in `src/main/java/org/lucee/lucli/cli/commands/CfmlCommand.java`:

```diff
         catch (Exception e) {
             System.err.println("Error in cfml command: " + e.getMessage());
             LuCLI.debugStack(e);
+            return 1;
         }
```

**Acceptance criteria.**
- `wheels cfml 'throw(message="boom")'` exits 1
- `wheels cfml '1 + 2'` still exits 0
- Guides harness's compile driver's `detectMode()` flips from `fallback` to `native` automatically on next run

**Files.** `src/main/java/org/lucee/lucli/cli/commands/CfmlCommand.java` in the LuCLI repo (~/GitHub/bpamiri/LuCLI).

---

## P1 — Polishes the happy path

### [ ] 4. No bcrypt in bundled Lucee

**Problem.** `hashBCrypt()`, `bcryptHash()` don't exist. `hash(pw, "BCRYPT")` throws `bcrypt MessageDigest not available`. Every auth tutorial on the internet assumes bcrypt.

**Repro.**
```bash
wheels cfml 'writeOutput(hash("pw" & "salt", "BCRYPT"))'
# → Error: bcrypt MessageDigest not available
```

**Impact.** Guides Part 6 (authentication) ships salted SHA-256 with a caution aside. Not production-grade. Readers who want to ship a real app have to research and assemble their own hashing layer.

**Proposed fix.** Options in order of reach:
- **Option A:** bundle a bcrypt `MessageDigest` provider (e.g. jBCrypt) with the bundled Lucee so `hash(pw, "BCRYPT")` works. Minimal API change; transparent to users.
- **Option B:** ship a `wheels.security` namespace with helpers:
  ```cfm
  wheels.security.hashPassword(password)  // returns struct {hash, salt}
  wheels.security.verifyPassword(password, hash, salt)  // returns boolean
  ```
  Documented as "the right way"; guides and examples reference it.
- **Option C:** new first-party package `wheels-security` containing both the bundled bcrypt bits and the helpers. Package-system-native.

Recommend A+B together. C is overkill.

**Acceptance criteria.**
- Guides Part 6 can swap SHA-256 for bcrypt in a 1-line change
- Tutorial's caution aside becomes a brief "use `wheels.security.hashPassword`" line

**Files likely involved.** Lucee distribution (bundling), or `vendor/wheels/security/*.cfc` (if helper path).

---

### [x] 5. Route model binding requires explicit `binding=true` but failure is silent — **shipped in `875639f59`** (dev warning; default stays false)

**Problem.** `.resources(name="posts")` does NOT enable route model binding by default. Readers who write `post = params.post;` in show/edit/update/delete get `params.post is undefined`. The framework doesn't warn or error — it just silently passes a missing variable.

**Evidence.** Final Phase 1 code review caught this after all 7 tutorial parts were written. Would've broken the tutorial for every reader.

**Impact.** The "convenience" of route model binding is undercut by the requirement to remember a flag. Tutorials elsewhere (Rails) default-enable this behavior.

**Proposed fix.** Options:
- **Option A:** default `binding=true` when the resource name singularizes to an existing model class. Matches Rails' convention. Users opt out with `binding=false` if they don't want the lookup.
- **Option B:** runtime warning when `params.<singular>` is referenced in an action on a bound-capable route and binding is off. "Did you mean to set `binding=true` on `resources('posts')`?"
- **Option C:** rename the flag to something self-documenting: `autoLoadModel=true`, or split into `loadBy=key` for explicit control.

**Acceptance criteria.**
- Tutorial readers who copy the Part 2 hand-written controller into a Part 3 scaffold pattern don't silently break
- Existing 4.0 apps that relied on `binding` being off opt-out explicitly if A is chosen

**Files likely involved.** `vendor/wheels/mapper/resources.cfc`, route model binding dispatcher in `vendor/wheels/controller/`.

---

### [ ] 6. Wheels Auth requires 3-step manual wiring; no convenience helper

**Problem.** Using `wheels.auth.SessionStrategy` in an app requires:
1. Create `Authenticator` and register it as a service
2. Create `SessionStrategy` and register it as a service
3. Call `registerStrategy()` on the Authenticator at init

Plus the controller code to call `service("authenticator").authenticate(request)`.

**Impact.** Guides Part 6b takes ~50 lines just to wire auth up before any logic runs. A one-line enable would dramatically simplify the tutorial and real-world adoption.

**Proposed fix.** A convenience helper:
```cfm
// config/app.cfm
wheels.auth.enableSession();       // session auth with defaults
wheels.auth.enableSession(sessionKey="myapp.session");  // customized
```

Or a module-level pattern:
```cfm
// config/services.cfm
wheels.auth.configure({
    strategies: ["session"],
    defaultStrategy: "session"
});
```

**Acceptance criteria.**
- Guides Part 6b shrinks from ~50 lines of wiring to ~3
- Advanced users can still go manual (current path stays working)

**Files likely involved.** `vendor/wheels/auth/` — add a facade/bootstrap module.

---

### [ ] 7. `config/services.cfm` load behavior is unclear

**Problem.** The DI container is documented assuming `config/services.cfm` is auto-loaded at app init. Fresh `wheels new` apps don't create this file, and there's no comment anywhere indicating it's expected.

**Impact.** Guides Part 6b hand-waves the loading step. Readers who follow the tutorial may create `config/services.cfm` and have it silently not load, or may have it load and not know when.

**Proposed fix.** Options:
- **Option A:** `wheels new` creates `config/services.cfm` with a template comment explaining the DI container:
  ```cfm
  // This file is auto-loaded at app init and every reload.
  // Register services for dependency injection. Example:
  //   injector().map("emailService").to("app.lib.EmailService").asSingleton();
  ```
- **Option B:** Document the auto-discovery rule prominently in the DI guide (Core Concepts section).

Recommend both.

**Acceptance criteria.**
- A fresh app has a discoverable stub for services.cfm
- Load ordering (is it before or after `config/settings.cfm`? before or after package load?) is documented

**Files likely involved.** `cli/lucli/` scaffolder, `vendor/wheels/` DI bootstrap, Core Concepts docs.

---

### [x] 8. Empty `app/snippets/` and `app/plugins/` directories in fresh apps — **shipped in `584f04d48`** (also covers `mailers/`, `lib/`, `jobs/`)

**Problem.** Fresh `wheels new` creates these directories with no README, no example, no indication of purpose. Users see empty folders and wonder if they should delete them.

Note: `app/snippets/` is actively used by generators (see item #1). The fact that it's empty in fresh apps is both a UX bug and the root cause of #1.

**Proposed fix.** Each directory gets a `README.md` stub:
- `app/snippets/README.md` — "Template overrides for `wheels generate`. Copy a template from the framework source here to customize."
- `app/plugins/README.md` — "Legacy plugin drop-in directory (deprecated; see `vendor/` for packages)."

Or, per #1, `app/snippets/` gets populated with default templates at `wheels new` time and the README explains how to override them.

**Acceptance criteria.** A first-time user can open the scaffolded directory tree and understand each top-level directory's purpose from its contents.

**Files.** `cli/lucli/` scaffolder or a `app/*/README.md` seed set.

---

### [x] 9. `wheels migrate` error message uses old command name — **shipped in `2827c61f2`**

**Problem.** Running `wheels migrate latest` without a running server prints:
```
No running Wheels server detected.
Migrations require a running server. Start with: wheels server start
```

But the current CLI command is `wheels start`, not `wheels server start`. Stale string from an earlier CLI version.

**Impact.** Reader copies the suggested command, gets "command not found," has to look up the right one.

**Fix.** Replace `wheels server start` with `wheels start` in the error message. Then sweep the rest of the codebase for other stale references.

**Grep suggestion.**
```bash
grep -rn "wheels server start\|wheels server stop" cli/ vendor/wheels/ --include="*.cfc"
```

**Files likely involved.** `cli/lucli/` or `vendor/wheels/migrator/` — wherever the migrate command emits this message.

---

### [ ] 10. `wheels migrate` requires a running HTTP server

**Problem.** Unlike most frameworks, `wheels migrate latest` talks to the app via HTTP instead of directly to the database. Creates a chicken-and-egg for:
- CI pipelines (need to boot a server just to apply schema)
- Scripted provisioning
- One-shot migration runners
- Docker builds

**Impact.** Deployment sections of the guides become more complex. Kamal's `kamal deploy` can't trivially run migrations as a separate step without an extra boot-then-migrate-then-teardown dance.

**Proposed fix.** Add an offline migration path:
- `wheels migrate latest --offline` — opens a direct DB connection using the same datasource configuration, runs migrations, exits
- Keep the current HTTP-backed path as the default for dev (because it auto-reloads the running app)

**Acceptance criteria.** CI workflow can run `wheels migrate latest --offline` between clone and test-suite-run without booting a dev server.

**Files.** `vendor/wheels/migrator/` — add a standalone-mode execution path; `cli/lucli/` — add the `--offline` flag.

---

### [ ] 11. Intermittent race when spawning `wheels new` in parallel

**Problem.** When the guides doctest harness runs multiple `wheels new` invocations in parallel (via `Promise.all`), ~1 in 20 runs fails with:
```
Can't cast String [] to a value of type [Struct]
```
or
```
Cannot invoke "javax.script.ScriptEngine.put(String, Object)" because "engine" is null
```

Rerunning passes. Appears to be a LuCLI engine init race when multiple JVM instances spin up at once.

**Impact.** CI flakes. The guides harness has to either retry-with-backoff or serialize.

**Fix.** Lives in LuCLI — likely a locking or single-init issue in the ScriptEngine bootstrap path.

**Acceptance criteria.** 100 parallel `wheels new`s pass without flakes.

**Files.** `src/main/java/org/lucee/lucli/LuceeScriptEngine.java` (or wherever the engine is initialized) in ~/GitHub/bpamiri/LuCLI.

---

### [x] 12. `wheels start` silently fails when `JAVA_HOME` is unset — **shipped in LuCLI `0d5b0ca`**

**Problem.** Without `JAVA_HOME` exported, `wheels start` spawns a child that exits before binding. The main process stderr shows a misleading error:
```
❌ Command failed: Cannot start server - port conflicts detected:
```
The real error (Java not found) only appears in `~/.wheels/servers/<name>/server.err`, which the user has to know to look at.

**Impact.** Hours of debugging the wrong thing. Especially painful in CI, where JAVA_HOME setup is the kind of thing workflow authors forget.

**Fix.** Detect a missing/invalid `JAVA_HOME` up front and exit with an actionable error:
```
Error: JAVA_HOME is not set (or does not point at a JDK).
Wheels needs Java 21 or newer.
Install: https://adoptium.net/
Then: export JAVA_HOME=/path/to/jdk-21
```

**Acceptance criteria.** Running `unset JAVA_HOME && wheels start` prints the actionable error instead of the port-conflict red herring.

**Files.** LuCLI entry point (probably `src/main/java/org/lucee/lucli/LuCLI.java`) in ~/GitHub/bpamiri/LuCLI.

---

### [x] 13. Form-helper id convention (`post-title` with dash) is non-obvious — **shipped in `7fc905a79`** (Option C: dual `data-auto-id` emission; default on)

**Problem.** `textField(objectName="post", property="title")` emits `id="post-title"` (joined with a dash). Conventions in Rails (`post_title`), Laravel, Django, and HTML-form tutorials elsewhere uniformly use underscore. Browser specs written against `#post_title` silently fail.

**Evidence.** Guides Part 7 browser spec was originally written against `#post_title` and `#user_email`; final code review caught it.

**Impact.** Every browser/E2E test written by a newcomer fails on first run. Debugging is tedious because the form renders correctly — the selector just doesn't match.

**Proposed fix.** Options:
- **Option A:** document the dash convention with a loud callout in the form-helper reference and browser-testing guide. Non-breaking; expectations set.
- **Option B:** change the default to underscore; add a config flag to keep dash for backward compat. Breaking change.
- **Option C:** emit both as `id="post-title" data-auto-id="post_title"` (or equivalent). Tests can target either. Non-breaking.

Recommend A at minimum. C is a nice enhancement.

**Files likely involved.** `vendor/wheels/view/miscellaneous.cfc` (specifically `$tagId`); form helper docs.

---

## P2 — Nice-to-have polish

### [ ] 14. No `wheels generate <thing> --dry-run`

**Problem.** To preview what a scaffold would produce without touching files, you have no option. Rails ships `rails g ... --pretend`.

**Fix.** Add `--dry-run` (or `--pretend`) flag to every `wheels generate *` subcommand. Print the file paths and bodies, don't write to disk.

**Acceptance criteria.** `wheels generate scaffold Post title:string --dry-run` prints what would be created; repo is untouched.

---

### [ ] 15. `wheels test run` output format needs verification

**Problem.** Guides Part 7 describes the expected output of `wheels test run` without ever executing the command end-to-end in the probe environment. The tutorial's "Expected output (illustrative)" placeholder is a hand-wave.

**Fix.** After items #1–#2 land, validate the full test-running flow end-to-end and update the tutorial with real output.

**Files likely involved.** `cli/lucli/` test-runner command, guides Part 7.

---

### [ ] 16. BDD test fixture setup (`tests/populate.cfm`) not documented at tutorial level

**Problem.** CLAUDE.md documents the fixture-setup pattern, but that's contributor-facing. Guides Part 7 mentions it only in troubleshooting.

**Fix.** Phase 2's Testing section should walk through `tests/populate.cfm`, how test isolation works, and when to use it. Captured here for scoping.

**Files.** Guides Phase 2 Testing section (future work).

---

## What's explicitly not on this list

Items surfaced during Phase 1 that are working-as-intended or out-of-scope:

- The CFML tag-comment (`<!--- --->`) gap in the compile driver's fallback mode. Theoretical; no current content hits it.
- Occasional flakiness of parallel `wheels verify:docs` runs with multiple cli blocks — same root as #11.
- The `.ai/` reference docs decision (deferred to end of Phase 2).

---

## How to use this doc

Pick any `[ ]` item, open a fresh session (or worktree), and fix it. Each card has the context needed — problem, repro, impact, proposed fix, acceptance criteria. No need to re-read the Phase 1 report unless you want background.

When fixed: tick the box, add the PR/commit link inline, and optionally move to a `## Shipped` section.
