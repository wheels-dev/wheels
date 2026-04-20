# Guides Rewrite — Phase 1 Completion Report

**Date:** 2026-04-19
**Branch:** `claude/lucid-thompson-b8c121`
**Spec:** [../specs/2026-04-18-guides-rewrite-v4-design.md](../specs/2026-04-18-guides-rewrite-v4-design.md)
**Plan:** [./2026-04-18-guides-rewrite-phase-1.md](./2026-04-18-guides-rewrite-phase-1.md)
**Phase 0 report:** [./2026-04-18-guides-rewrite-phase-0-report.md](./2026-04-18-guides-rewrite-phase-0-report.md)

## Shipped

16 commits on top of Phase 0 head `ee2ad45bd`:

| SHA | What |
|-----|------|
| `a4d95f6a0` | `chore(docs): tutorial-fixture lib for persistent blog-tutorial app` |
| `5abce1df8` | `chore(docs): orchestrator partitions per-block vs cumulative examples` |
| `935f9f9f0` | `feat(docs): tutorial driver for cumulative blog-tutorial fixture` |
| `4ed05113c` | `refactor(docs): address tutorial driver code review` |
| `c8485d59c` | `feat(docs): compile driver (wheels cfml exit-code based)` |
| `5814c3b33` | `fix(docs): extract indented fences inside starlight steps components` |
| `513856adb` | `refactor(docs): cache detectMode promise for concurrent callers` |
| `68a90b997` | `docs(docs): start here pages — welcome, why wheels, installing, first 15 min` |
| `2cc31ebe0` | `docs(docs): tutorial index + part 1 rewrite for wheels 4.0 reality` |
| `f0a2bd89b` | `docs(docs): tutorial part 2 — first model` |
| `a7554ce5d` | `docs(docs): tutorial part 3 — crud scaffold + package activation` |
| `2c2a1bd9f` | `docs(docs): fix stale part 4 link in part 3 next-up pointer` |
| `a5ee815a7` | `docs(docs): tutorial part 4 — validations + turbo frames` |
| `7500b2a72` | `docs(docs): tutorial part 5 — comments + turbo streams` |
| `711f72644` | `docs(docs): tutorial part 6 — authentication (hand-rolled + built-in)` |
| `12028b55d` | `docs(docs): tutorial part 7 — testing, deploying, what's next` |

## Deliverables checklist

- [x] **Task 1** — Tutorial driver + `TutorialSession` class + fixture lib + orchestrator (code). Subagent ceremony: implementer → spec review → code review. Round 2 review fixes landed in `4ed05113c`.
- [x] **Task 2** — Compile driver (native + fallback modes) + re-tag existing Phase 0 sample pages. Subagent ceremony as above. Plus an unscheduled-but-required fix to `lib/extract.mjs` to match indented fences inside `<Steps>` components. Minor nit (cache `detectMode` promise instead of value) fixed inline.
- [x] **Task 3** — Welcome to Wheels (orientation concept page).
- [x] **Task 4** — Why Wheels? (Rails / Laravel / Django comparison with when-not-to).
- [x] **Task 5** — Installing Wheels (macOS / Windows / Linux tabs, one harness-checked `wheels --version`).
- [x] **Task 6** — Your First 15 Minutes (skim-level zero-to-running-page).
- [x] **Task 7** — Tutorial index + Part 1 rewrite (Main controller, not Home; note Hotwire/Basecoat activate in Part 3; dropped false "Turbo Drive active from page 1" aside).
- [x] **Task 8** — Tutorial Part 2: first model (Post + migration + seeds + controller + views + routes).
- [x] **Task 9** — Tutorial Part 3: CRUD scaffold (7-action controller + `_form.cfm` + 4 views + full `resources("posts")` + package-activation explainer).
- [x] **Task 10** — Tutorial Part 4: validations + Turbo Frames (validations, CDN Turbo, frame-wrapped form, partial-render on invalid).
- [x] **Task 11** — Tutorial Part 5: comments + Turbo Streams (Comment model + hasMany/belongsTo, nested routes via callback syntax, stream append on create).
- [x] **Task 12** — Tutorial Part 6: authentication (6a hand-rolled with SHA-256 + salt, 6b with `wheels.auth.SessionStrategy`).
- [x] **Task 13** — Tutorial Part 7: testing + deploying (model spec, controller spec, one browser spec, Kamal-first deployment overview, CardGrid to next sections).
- [x] **Task 14** — Full harness run + build + report (this file).
- [ ] **Task 15** — Final code review across Phase 1 diff. Remaining.

## Verification

- `pnpm verify:docs` — **46 tagged blocks passed, 0 failed** across 26 MDX files.
- `pnpm test:docs-harness` — **29 specs passed, 0 failed** (tutorial + orchestrator + extract + compile + cli + fixture). Duration ~25s with `JAVA_HOME` set.
- `pnpm --filter @wheels-dev/site-guides build` — **272 pages built** in ~4.7s. 266 was the Phase 0 baseline; +6 = 4 Start Here pages + tutorial index + 6 new tutorial parts minus adjustments.
- All harness blocks validated against the real `wheels` CLI v0.3.5-SNAPSHOT. Compile driver runs in **fallback mode** (LuCLI PR #1 not yet merged); fallback catches bracket balance only. `wheels --version` smoke test per-page confirms CLI presence.

## Deviations from the plan

The Phase 1 plan was written against an aspirational view of the Wheels 4.0 CLI and package surface. Sandbox probing against the actual installed `wheels` v0.3.5-SNAPSHOT revealed a number of spec-vs-reality gaps. Rather than documenting features that don't work yet, the tutorial adapts to what ships today and notes the gaps explicitly. The decisions below are documented here so Peter can audit and roll them forward if he prefers.

### 1. Default controller is `Main`, not `Home`

Phase 0 Part 1 and the Phase 1 plan assumed the scaffolded app had a `Home` controller. `wheels new <app>` actually scaffolds `Main.cfc` with a single `index` action at `app/views/main/index.cfm`. Part 1 was rewritten to add a `hello` action to the existing `Main` controller rather than invent a `Home`.

### 2. Hotwire and Basecoat are NOT activated by default

Phase 0 Part 1's FileTree showed `vendor/hotwire/` and `vendor/basecoat/`; its closing aside claimed "click between pages — Turbo Drive handling transitions." Neither is true. A fresh `wheels new` app has only `vendor/wheels/`. The packages exist at `packages/hotwire/` and `packages/basecoat/` in the framework source tree, but the scaffold does not copy them into new apps, and a fresh user has no `packages/` directory at all to copy from.

**Adaptation:** Part 1 drops the "Turbo Drive active from page 1" claim. Part 3 introduces the package-activation model conceptually (`cp -r packages/X vendor/X`) and notes that fresh apps don't ship with the packages/ dir yet. Part 4 adds Turbo via a CDN `<script>` tag in `layout.cfm` — an honest workaround that teaches readers how Turbo integrates, pending a `wheels package install hotwire` command in a future CLI release.

### 3. `wheels generate model|controller|scaffold` is broken on v0.3.5-SNAPSHOT

A fresh `wheels new` app creates an empty `app/snippets/` directory. The generators look for templates there (e.g. `ModelContent.txt`) and error with "Template not found: ModelContent.txt" if they're missing. Copying the framework's own `app/snippets/*.txt` into the app makes the generator work, but that's not a discoverable path for a new user.

**Adaptation:** Parts 2-7 teach via hand-written files. Each part shows the full contents of each new CFC or CFM. An illustrative `wheels generate model Post ...` command appears in Part 2 with a "you may see `Template not found` on your CLI — hand-write the following if so" note. This is educational (readers see what a scaffold produces) and works today.

### 4. Password hashing: no bcrypt on bundled Lucee

Phase 1 Task 12 (Part 6) assumed `hashBCrypt()` / `bcryptHash()` existed. They don't. Lucee's bundled Java stack reports "bcrypt MessageDigest not available" when attempting `hash(pw, "BCRYPT")`.

**Adaptation:** Part 6 teaches salted SHA-256 (`Hash(pw & salt, "SHA-256")` with `generateSecretKey("AES")` for the salt). An `<Aside type="caution">` explains SHA-256 is educational-only and points at bcrypt via CFX / Java libs / future `wheels-security` package for production. The mental model (salt + hash + compare) stays identical.

### 5. CLI command names

- `wheels dbmigrate` → actual is `wheels migrate`
- `wheels db:seed` → actual is `wheels seed`
- `wheels server start/stop` → actual is `wheels start` / `wheels stop`

All tutorial pages use the actual command names. Task 1's `tutorial-fixture.mjs` was already fixed to use `wheels start` during Task 1 implementation (noted in the Task 1 implementer report).

### 6. `wheels migrate` requires a running dev server

Unlike most frameworks where migrations run against a DB connection, `wheels migrate latest` calls into the running app via HTTP. Without `wheels start` first, it errors with "No running Wheels server detected." This is noted in Part 2's migration step.

### 7. `{test:tutorial}` cumulative state not used in tutorial parts

The plan prescribed using `{test:tutorial step=N file="..."}` blocks so the harness would build up the blog app end-to-end. With the CLI's generator gaps and the package system's bootstrap issue, the cumulative shared-fixture path is too fragile for Phase 1. Tutorial parts instead use:

- `{test:compile}` for every CFC / `config/routes.cfm` block — catches bracket errors in fallback mode, will become full parse checks once LuCLI PR #1 merges
- `{test:cli cmd="wheels --version" asserts-stdout="Wheels"}` as a per-page smoke test
- `title="app/views/..."` (illustrative) for HTML views — views aren't reliably parseable via `wheels cfml`

The reader's hands-on walkthrough is the end-to-end validation loop. The harness validates that the CFML code parses and that the `wheels` CLI is reachable.

### 8. Unscheduled scope expansion: `extract.mjs` indented fences

Task 2's re-tag work revealed that `FENCE_RE` in `lib/extract.mjs` required fences at column 0. MDX inside `<Steps>` components indents fences 3 spaces (list-item content). The existing regex silently skipped indented fences — 2 of `01-hello-wheels.mdx`'s re-tagged blocks never reached the harness, and every tutorial part using `<Steps>` would have had the same problem.

Fix: extend `FENCE_RE` to capture leading whitespace and require the same indent on the closing fence (via backreference `\1`). Add a `stripIndent` helper to remove the indent from body content. Ships with 3 new extract tests; Phase 0's 5 tests remain green unchanged.

## Architectural additions

Task 1 shipped three new modules in `web/sites/guides/scripts/verify-docs/`:

- **`drivers/tutorial.mjs`** (~190 lines) — `TutorialSession` class managing a persistent blog-tutorial fixture + server lifecycle. HTTP assertion parser (`parseHttpAssert`), DB row assertion via `wheels cfml` one-liner, safe spawn via existing `runExec`. The full tutorial driver is implemented but not used by Phase 1 content per Deviation #7; it stays ready for Phase 2 end-to-end assertions.
- **`lib/tutorial-fixture.mjs`** — persistent fixture lifecycle (`resetFixture` / `writeFixtureFile` / `appendFixtureFile` / `readFixtureFile` / `runInFixture`). Path-traversal guards reject `../` and absolute paths.
- **`lib/orchestrator.mjs`** — partitions examples into cumulative (tutorial + step-numbered cli) vs per-block (everything else). Orders cumulative examples by `(sidebarOrder, step, line)`.

Task 2 shipped:
- **`drivers/compile.mjs`** — `detectMode()` probes `wheels cfml 'throw()'` once per process; falls back to bracket-balance check when LuCLI PR #1 hasn't merged. Promise-cache avoids concurrent double-probe under `Promise.all`.
- **`lib/cli-assert.mjs`** — shared `assertCliResult(result, attrs)` between `cli.mjs` and the tutorial driver's cli path.

VALIDATION.md documents all three drivers (cli, compile, tutorial) with stable semantics.

## Known gaps / Phase 2 follow-ups

### Ready-to-file LuCLI issues

1. **LuCLI PR #1** (already drafted; see `docs/superpowers/artifacts/lucli-pr-1/`) — `wheels cfml` exits 0 on CFML errors. Once merged, the compile driver auto-promotes from fallback to native mode with no code changes.
2. **LuCLI `parse` proposal** (drafted as issue markdown; see `docs/superpowers/artifacts/lucli-pr-2/`) — dedicated `lucli parse <file-or-expr> [--json]` for side-effect-free parse checks. Would give the doctest harness proper structured diagnostics.
3. **`wheels generate` on fresh apps** — snippets aren't bundled by the CLI into new scaffolds. Fix should either (a) have `wheels new` copy snippets from the framework source, or (b) have `wheels generate` find them in the framework source when missing from the app. This is blocking for anyone actually running the tutorial commands today.
4. **`wheels package install <name>`** — no current mechanism to install Hotwire/Basecoat/etc. on a fresh app. Today requires manually copying from framework source, which most users don't have.
5. **Parallel `wheels new` flakiness** — the harness's cli driver creates fresh fixtures in parallel. Occasionally (intermittent, one in ~20 runs) LuCLI engine init races produce "Can't cast String [] to a value of type [Struct]" / "Cannot invoke ScriptEngine.put because engine is null". Rerunning passes. Worth investigating via LuCLI logs. Workaround in Task 14: just rerun when it flakes.
6. **No bcrypt on bundled Lucee.** Part 6 uses salted SHA-256. Either bundle a bcrypt-capable MessageDigest provider, or ship a `wheels-security` package with a proper hash helper.

### Documentation follow-ups

7. **`.ai/` decision** (deferred from Phase 0) — still unreached. Revisit at end of Phase 2.
8. **Part 2's migration filename timestamps** are hand-chosen to be stable across the tutorial. In a real user's run, timestamps differ by the second they ran the generator. Once `wheels generate migration` works cleanly, we can replace hand-written timestamps with illustrative ones and show the actual generated filename format.
9. **CI workflow `JAVA_HOME`** — `.github/workflows/docs-verify.yml` (Phase 0) doesn't export `JAVA_HOME`. Locally the `wheels start` in the tutorial driver test fails silently without it. Likely needs `env: JAVA_HOME: ...` in the workflow. Flagged in Task 1's report; haven't landed a fix yet.
10. **Kamal walkthrough** — Part 7 mentions Kamal as the primary deploy path. Phase 2's Deployment section needs to write the actual walkthrough.

### Harness follow-ups

11. **`asserts-db-rows` untested in practice.** No tutorial page uses it; first real use may reveal needed fixes in the `wheels cfml` invocation. Documented as such in VALIDATION.md.
12. **Fixture flakiness under high parallelism.** `cli` driver creates a fresh fixture per block; 4+ blocks in parallel occasionally races on LuCLI engine init. Mitigations to consider: fixture pool + reuse, retry-with-backoff on `createFixture`, or serial-fallback when >N blocks per run.
13. **Tutorial driver not exercised by tutorial content.** The `TutorialSession` class + `{test:tutorial}` block syntax are fully implemented and unit-tested via the mini-tutorial fixture. No real tutorial page uses them yet, per Deviation #7. Phase 2 may revisit this when the CLI gaps close.

## What to review before Phase 2 starts

1. **Tone and voice of the 4 Start Here pages** — are Welcome, Why Wheels?, Installing, and First 15 Minutes the right front door? Specific feedback welcomed on Why Wheels? comparisons.
2. **Tutorial Part 1 rewrite** — the old Phase 0 version was wrong about the default controller and package activation. The new version is honest about the CLI's current state. Does the "Hotwire/Basecoat arrive later" framing land?
3. **Parts 2–7 accuracy** — these were probed against the installed `wheels` CLI but depend on APIs and conventions I read from the framework source, not end-to-end executed against a running app. A hands-on run-through by a real user (or Peter) is the best way to catch gaps.
4. **Part 6 auth flow** — SHA-256 + salt instead of bcrypt is a compromise. Happy to rewrite Part 6 once a bcrypt path ships (package, CFX, or Java lib doc).
5. **`{test:compile}` fallback mode's blind spots** — it catches bracket mismatches, nothing else. Mixed-arg-style errors pass, wrong function names pass, anything semantic passes. Once LuCLI PR #1 merges, native mode catches all of these with no code changes. Worth reviewing any CFML block for correctness — I've tried hard to match patterns from `vendor/wheels/auth/`, `vendor/wheels/migrator/`, the framework's own examples, and CLAUDE.md's anti-pattern guide.
6. **The extract.mjs indent fix** — regex backreference plus `stripIndent`. Edge cases: tabs vs spaces (handled), mixed indent (rejected, correct), blockquote-inside-fence (not handled; not a realistic case).

## Open decisions before Phase 2 starts

1. **LuCLI PR filing.** Do you want to file the PR (ready-to-apply diff at `docs/superpowers/artifacts/lucli-pr-1/`) and the companion issue (`docs/superpowers/artifacts/lucli-pr-2/`) from this session, or save for a later session?
2. **Tutorial rework after CLI fixes.** Once `wheels generate` works on fresh apps and Hotwire/Basecoat are installable, the tutorial should replace hand-written files with generator commands. Plan: audit and rewrite as a dedicated task in Phase 2, or wait for Wheels 4.1?
3. **`{test:tutorial}` cumulative state.** The driver is built. Should Phase 2 retry wiring it up once the CLI's generator gaps close? Or is per-block testing enough for ongoing maintenance?
4. **Kamal vs. other deploy paths.** Part 7 names Kamal as primary. Phase 2's Deployment section needs to either commit to Kamal or present multiple options.
5. **Sidebar polish.** Start Here's `items` list now has 5 top-level entries plus the 7-part tutorial nested under "Tutorial: Build a Blog." Consider whether the nested tutorial items should collapse by default or stay expanded.

## Summary

Phase 1 ships two new harness drivers (tutorial + compile), both well-tested; four orientation pages (Welcome, Why Wheels?, Installing, First 15 Minutes); a rewritten Part 1; and the seven-part Build a Blog tutorial — 2,000+ lines of MDX narrative, 46 harness-validated code blocks, 29 unit tests, 272 pages building clean. Where the installed `wheels` CLI doesn't match the Phase 1 plan's aspirations, the tutorial adapts to current reality and explicitly notes the gaps. The scaffolding is in place to upgrade blocks to richer testing once LuCLI PR #1 lands and the CLI's generator/package gaps close.
