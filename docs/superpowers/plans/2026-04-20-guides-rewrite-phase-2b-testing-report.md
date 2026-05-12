# Guides Rewrite — Phase 2b-Testing Completion Report

**Date:** 2026-04-20
**Branch:** `claude/lucid-thompson-b8c121` (draft PR [#2169](https://github.com/wheels-dev/wheels/pull/2169))
**Spec:** [../specs/2026-04-18-guides-rewrite-v4-design.md](../specs/2026-04-18-guides-rewrite-v4-design.md)
**Plan:** [./2026-04-20-guides-rewrite-phase-2b-testing.md](./2026-04-20-guides-rewrite-phase-2b-testing.md)
**Prior phase:** [Phase 2b-Advanced report](./2026-04-20-guides-rewrite-phase-2b-digging-deeper-report.md)

## Shipped

**11 commits** on top of Phase 2b-Advanced head `045b0d231` — 9 content pages + 2 integration commits.

| SHA | What |
|-----|------|
| `1b1816b4c` | testing/model-tests — BDD patterns + matcher reality check |
| `3074af9eb` | testing/controller-tests — TestClient (real HTTP client, not simulator) |
| `0609d26b7` | testing/view-and-form-tests — rendered output + `data-auto-id` selectors |
| `139fbebb0` | testing/integration-tests — multi-step workflow patterns |
| `b09aa2a6e` | testing/functional-tests — single-feature end-to-end through full pipeline |
| `d91119dce` | testing/browser-tests — Playwright DSL + fixtures + cross-engine |
| `9f3ee7648` | testing/fixtures-and-test-data — populate.cfm lifecycle reality |
| `bfd94ee90` | testing/running-tests-locally — wheels test CLI + Docker matrix |
| `36dc76fe8` | testing/ci-integration — GitHub Actions + browser gating + soft-fail |
| `b8f943ae9` | testing index rewrite + fix phantom matchers in tutorial Part 7 |
| `b645ab7fa` | task 11 .ai/ testing stragglers — delete unit-testing.md |

### Deliverables checklist (9 pages)

- [x] Model Tests
- [x] Controller Tests
- [x] View & Form Tests
- [x] Integration Tests
- [x] Functional Tests
- [x] Browser Tests
- [x] Fixtures & Test Data
- [x] Running Tests Locally
- [x] CI Integration

### Integration

- [x] Testing section landing (index.mdx) rewritten — all 9 cards + corrected framing
- [x] Sidebar populated with all 10 entries (Overview + 9 detail pages)
- [x] Tutorial Part 7 phantom matchers corrected (`toBeTruthy` → `toBeArray`, `toEqual(200)` → `$testClient().get(...).assertOk()`)
- [x] `.ai/wheels/testing/unit-testing.md` deleted — content covered by new pages
- [x] `.ai/wheels/testing/` directory auto-removed

## Verification

- **`pnpm verify:docs`** — **283/283 tagged blocks pass** across 66 files. (Hit framework gap #11 LuCLI parallel-spawn race on first attempt; succeeded on retry.)
- **`pnpm test:docs-harness`** — 29/29 unit tests pass.
- **`pnpm build`** — **312 pages** build clean, no broken-link errors.
- Compile driver still in fallback mode (LuCLI #56 pending) — significant because:
  - **Phantom-matcher drift pre-Phase-2b was invisible to the harness** (bracket-balance can't detect method names)
  - Task 1 caught it by cross-checking WheelsTest source
  - The Testing Overview AND Tutorial Part 7 were affected — both patched in Task 10

## What changed from the plan

Phase 2b-Testing continued the pattern established in Phase 2a, 2b-Advanced: subagents cross-check plan claims against `vendor/wheels/` source before writing. **Drift rate stayed high** — every substantial page caught 3-8 API corrections.

### Major drifts caught (and corrected in user docs)

**Controller Tests (Task 2) — TestClient is a REAL HTTP client, not an in-process simulator.**
- Uses `cfhttp` with `redirect=false`
- No `client.session.userId = 1` — session state lives in server cookies, persists across calls on same client
- No `reset()` — create new client via `$testClient()`
- Response is raw `cfhttp` result with accessor methods (`statusCode()`, `content()`, `json()`, `headers()`, `response()`)
- Fluent assertion API throws `TestBox.AssertionFailed`: `assertStatus(n)`, `assertOk()`, `assertCreated()`, `assertRedirect(to="")`, `assertSee(text)`, `assertDontSee(text)`, `assertSeeInOrder([...])`, `assertJson(expected={})`, `assertJsonPath(path, value)`, `assertHeader(name, value="")`, `assertCookie(name, value="")`
- `asJson()` sets Content-Type + Accept for JSON
- POST body uses bracket-notation keys: `{"post[title]": "T", "post[body]": "B"}`
- No auto-redirect — extract `headers()["Location"]` to follow
- WheelsTest ships helper shortcuts: `$testClient()` auto-baseUrl from `CGI.SERVER_PORT`; `visit(path)` = `$testClient().get(path)`

**Model Tests (Task 1) — WheelsTest matcher inventory, phantom matchers exposed.**
- Shipped: `toBe` (deep-compares structs/arrays via `isEqual`), `toBeTrue`, `toBeFalse`, `toBeNull`, `toBeInstanceOf`, `toBeArray`, `toBeStruct`, `toBeQuery`, `toBeNumeric`, `toBeString`, `toBeBoolean`, `toBeDate`, `toContain`, `toInclude`, `toBeIn`, `toHaveKey`, `toHaveDeepKey`, `toHaveLength`, `toBeEmpty`, `toMatch`, `toStartWith`, `toEndWith`, `toBeGT`, `toBeGTE`, `toBeLT`, `toBeLTE`, `toBeBetween`, `toBeCloseTo`, `toBeJSON`, `toSatisfy`, `toThrow`, `notToThrow`. Negation via `notTo*` prefix.
- BDD aliases: `feature`, `story`, `given`, `when`, `then`, `scenario`.
- **Phantom (do not ship):** `toEqual`, `toBeTruthy`, `toBeFalsy`. Used by Tutorial Part 7 + old Testing Overview — fixed in Task 10.
- **Test isolation reality:** `transactionMode="none"` by default. `populate.cfm` runs ONCE per test run (when `url.populate` truthy, default `true`, OR core tables missing). Per-spec rollback requires manual `transaction { ... transaction action="rollback"; }`. This is a deliberate departure from Rails/Laravel per-spec rollback.

**Browser Tests (Task 6) — extensive DSL with several spec adjustments.**
- `loginAs(identifier)` — takes single STRING identifier, NOT a user struct (plan was wrong)
- `pause(milliseconds)` — takes REQUIRED numeric sleep, not a no-arg REPL drop-in (plan was wrong; prints warning to stderr)
- `setCookie(name, value, url)` — `url` is REQUIRED
- `aroundEach` auto-captures screenshot + HTML to `tests/_output/browser/` on failure — documented as bonus
- `this.browserScreenshotOnFailure`, `this.browserViewport` class-level settings
- CI gate: `WHEELS_CI` (non-empty, uses `len()` not equality) + `WHEELS_BROWSER_CI_ENABLE` in `true,1,yes`
- `ParallelRunner.cfc` exists (383 lines) but user-facing API isn't firmly pinned — subagent wisely skipped that section

**Running Tests Locally (Task 8) — CLI flags correctly enumerated.**
- `--filter=<dir>`, `--reporter=<name>`, `--db=<sqlite|mysql|postgres|mssql|h2>`, `--verbose`/`-v`, `--ci`, `--core` — real
- **Phantom:** `--format=json` (CLI always requests JSON internally), `--reporter=tap` / `--reporter=junit`. Plan invented both.
- **`compose.yml` is at repo root**, NOT `rig/compose.yml` as plan said
- **`tools/test-local.sh browser`** doesn't have a dedicated alias — falls through as literal directory filter
- Postgres compose in overlay: `docker-compose.db-postgres.yml`

**CI Integration (Task 9) — `--reporter` flag is parsed but not consumed.**
- `--reporter=<name>` is parsed but the value is not currently used by `runTests()`
- CLI always requests `format=json` from the test endpoint and formats a human-readable summary
- `--ci` flag ships but `ciMode` passed to `runTests()` is also currently a no-op on output shaping
- **Phantom:** `--parallel` flag (not shipped — matrix parallelism only)
- Real command is `wheels browser install` (NO colon), not `wheels browser:install`
- Browser CI gate verified at `BrowserTest.cfc:87-97` via `$isCiSkipEnabled()`

### Deletions from `.ai/`

- `.ai/wheels/models/testing.md` (Task 1)
- `.ai/wheels/controllers/testing.md` (Task 2)
- `.ai/wheels/views/testing.md` (Task 3)
- `.ai/wheels/testing/browser-testing.md` (Task 6)
- `.ai/wheels/testing/browser-automation-patterns.md` (Task 6)
- `.ai/wheels/testing/unit-testing.md` (Task 11)

**`.ai/wheels/testing/` directory empty and auto-removed.** 6 testing-related files deleted this phase.

## Phantom matchers in pre-existing docs — corrected

**Tutorial Part 7 (`start-here/tutorial/07-testing-deploying.mdx`):**
- `toBeTruthy()` → `toBeArray()` (3 occurrences)
- `toEqual(200)` → `$testClient().get("/posts").assertOk()` (more accurate — exercises real TestClient)
- Updated matcher vocabulary list

**Testing Overview (`testing/index.mdx`):**
- Complete rewrite — was phantom-matcher-laden and framed populate.cfm wrong
- Now: accurate matcher list, accurate populate lifecycle, TestClient references, all 9 CardGrid links, correct runner URL (`/wheels/core/tests` not `/wheels/app/tests`)

Both landed in commit `b8f943ae9`.

## Known issue from this phase

**Framework gap #11 (LuCLI parallel-spawn race) hitting harness consistently.** The verify-docs harness now scans 66 files with 283 tagged blocks — many `{test:cli}` blocks spawn fresh fixtures in parallel via `Promise.all`. First harness run in this phase hit a `Can't cast String [] to a value of type [Struct]` error parsing `lucee.json` (classic sign of the race — parallel `wheels new` overwriting the file mid-read). Retry succeeded.

Before Phase 2c starts, gap #11 should be prioritized. Options:
- Serialize fixture creation in the harness orchestrator (docs-side workaround)
- Fix the LuCLI race (framework fix — proper)

The failure is transient enough that retry works, but it will cause CI flakes once the harness runs on every PR.

## Next moves

**Phase 2b-CLI** is the natural next sub-phase. Scope per original spec: ~110 pages of CLI Reference. This is a **migration + restructure** of existing GitBook content, not net-new content authoring. Different workflow from the content subagent pattern.

Before Phase 2b-CLI starts:
- **Audit the existing `cli-reference/` v4 content** — check if `generate-guides.mjs` already populated it from GitBook source
- **Reach a decision on migration pattern**: mechanical convert + touch-up, or rewrite per command?
- **Decide `cli-reference/info.mdx`** (Phase 0 sample page — last unverified against source) — likely needs an audit like Sending Email got

Then draft Phase 2b-CLI plan.

Optionally before that:
- **File gap #17-21** as GitHub issues (user-mailer snippet, wheels-i18n package, bindBy, toFactory, i18n primitives)
- **Chase [LuCLI #56](https://github.com/cybersonic/LuCLI/pull/56)** for compile driver native mode
- **File gap #11 fix** (parallel spawn race) — the harness will flake on CI when Phase 2c's CI workflow activates

## Architectural notes

### Drift-catch rate stays high

Pre-existing docs (`.ai/`, CLAUDE.md, Phase 0 samples, Phase 1 tutorial) were drafted before source verification. Every Phase 2 phase has caught roughly as many drifts per page as Phase 1 + 2a. The pattern holds: the only way to trust a doc is to cross-check every claim against `vendor/wheels/` source. Phase 2b-Testing caught phantom matchers, phantom TestClient API, phantom CLI flags, phantom reporters, phantom URL — all landed silently through prior phases because none of them are bracket-balance-catchable.

**Implication for Phase 2b-CLI and Phase 2c:** plan drafts for those phases are SUSPECT. Assume the subagents will catch comparable drift. Budget accordingly — don't scope tightly based on plan assumptions.

### The compile driver's bracket-balance fallback is insufficient for method validation

The harness catches typos and unbalanced delimiters. It does NOT catch:
- Phantom method names (`toEqual`, `toBeTruthy`, `renderNotFound`, `hasService`)
- Phantom parameter names (`columnName` when real is `columnNames`)
- Phantom class paths (`wheels.Mailer` when no such class exists)

Once [LuCLI #56](https://github.com/cybersonic/LuCLI/pull/56) merges, the compile driver flips to `native` mode automatically via `detectMode()` probe. Every `{test:compile}` block in Phase 2a + 2b + 2c will get real parse-checking with zero code changes. This phase's drift catches would have been automatic once native mode is live.

### Phase 0 samples are a completed cleanup

- Tutorial Part 1 — rewritten Phase 1
- Request Lifecycle — rewritten Phase 2a Task 1
- Sending Email — rewritten Phase 2b-Advanced Task 5 (Phase 0 was mostly fabricated API)
- Testing Overview — landed Phase 2a Task 21, phantom matchers patched Phase 2b-Testing Task 10
- **CLI Reference Info — still unverified.** Phase 2b-CLI first order of business.

### 2/3 of Phase 2 complete

Phase 2a shipped 20 pages (Core Concepts + Basics + Testing Overview). Phase 2b-Advanced shipped 14 pages (Digging Deeper). Phase 2b-Testing shipped 9 pages (Testing detail). **Total: 43 content pages, plus 4 planning + report documents, plus framework gap fixes shipped separately.**

Remaining for Phase 2: CLI Reference (~110 pages, Phase 2b-CLI) + Operations and Polish (Kamal deployment + contributing + glossary + `.ai/` final audit + cutover merge, Phase 2c).
