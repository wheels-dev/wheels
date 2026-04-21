# Guides Rewrite — Phase 0 Completion Report

**Date:** 2026-04-18
**Branch:** `claude/youthful-montalcini-6ea95c` (worktree at `.claude/worktrees/youthful-montalcini-6ea95c`)
**Spec:** [../specs/2026-04-18-guides-rewrite-v4-design.md](../specs/2026-04-18-guides-rewrite-v4-design.md)
**Plan:** [./2026-04-18-guides-rewrite-phase-0.md](./2026-04-18-guides-rewrite-phase-0.md)

## Shipped

Ten commits on the branch, base `1b4c70b66` → head `e87e7488a`:

| SHA | What |
|-----|------|
| `2497da3e3` | Cleared auto-generated v4 content from prior `generate-guides.mjs` run |
| `2c141b2ba` | Scaffolded new v4 directory + 17 placeholder MDX + hand-authored sidebar |
| `446c89a31` | Writing style guide at [web/sites/guides/STYLE.md](../../../web/sites/guides/STYLE.md) |
| `8140603f7` | verify-docs harness skeleton + VALIDATION.md + safe `runExec` wrapper |
| `560e81016` | Hardened the exec wrapper per code review (whitelist opts, force `shell: false`) |
| `68508c6e2` | `extract.mjs` MDX walker + 5 passing unit tests |
| `385491a8e` | `cli.mjs` driver + fixture management + 4 passing tests (real `wheels new`) |
| `169c2f14e` | Orchestrator + report + 2 end-to-end tests |
| `f64ebded2` | Four Diátaxis sample pages + `asserts-stderr` / `asserts-output` on the cli driver |
| `e87e7488a` | CI workflow at `.github/workflows/docs-verify.yml` |

### Deliverables checklist

- [x] New IA scaffold at `web/sites/guides/src/content/docs/v4-0-0-snapshot/` with placeholders per top-level section.
- [x] Hand-authored sidebar `web/sites/guides/src/sidebars/v4-0-0-snapshot.json`.
- [x] Writing style guide.
- [x] verify-docs harness:
  - `extract.mjs` — MDX walker (regex-based)
  - `exec.mjs` — safe spawn wrapper (no shell)
  - `cli.mjs` driver — `{test:cli}` with stdout/stderr/output asserts
  - Orchestrator + report + dispatcher
  - 11 passing `node:test` specs under `scripts/verify-docs/test/`
- [x] Four sample pages, one per Diátaxis type:
  - Tutorial — [Part 1: Hello, Wheels](../../../web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/01-hello-wheels.mdx)
  - How-to — [Sending Email](../../../web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/sending-email.mdx)
  - Concept — [The Request Lifecycle](../../../web/sites/guides/src/content/docs/v4-0-0-snapshot/core-concepts/request-lifecycle.mdx)
  - Reference — [`wheels info`](../../../web/sites/guides/src/content/docs/v4-0-0-snapshot/cli-reference/info.mdx)
- [x] CI workflow at `.github/workflows/docs-verify.yml`.

### Verification

- `pnpm verify:docs` → **2 passed, 0 failed**. The two `{test:cli}` blocks (`wheels --version` on the tutorial, `wheels info` on the reference) both execute cleanly against a real fresh fixture app.
- `pnpm test:docs-harness` → **11 passed, 0 failed** across extract, cli, and orchestrator suites.
- `pnpm --filter @wheels-dev/site-guides build` → **266 pages built** without errors or broken links. All four sample pages resolve from the sidebar.

## What changed from the plan

Three deviations, all intentional and discussed during execution:

### 1. Compile driver deferred (plan Task 6 → skipped)

The plan assumed `wheels check <file>` exists as a standalone CFML syntax-check subcommand. It doesn't — `wheels` 4.0 ships `validate`, `analyze`, `doctor`, `console`, and `migrate`, but nothing that compiles an isolated file without an app context.

**Decision (with Peter):** drop `{test:compile}` from Phase 0 entirely. Sample pages that would have used it (Tutorial Part 1, Sending Email) now mark their CFC fragments as illustrative (`title="app/controllers/Home.cfc"`) rather than `{test:compile}`. The harness's extract step still parses `{test:compile}` tags; the orchestrator reports "no driver for kind 'compile'" if it encounters one.

**Follow-up:** file an issue against the Wheels CLI proposing `wheels check <file>` as a parse-only subcommand. Once shipped, implement the compile driver (~30 lines) and re-tag illustrative blocks. This is purely additive — nothing to unwind.

### 2. Reference page changed from `wheels dbmigrate latest` to `wheels info`

The plan used `wheels dbmigrate latest` as the Phase 0 reference sample. Two problems:
- The 4.0 CLI renamed it to `wheels migrate latest`.
- Any `wheels migrate` subcommand requires a running server, which the harness's isolated fixture doesn't have.

`wheels info` is a better reference target: it works without a running server, produces real output, and has sensible options + exit codes to document. Page renamed and sidebar updated.

### 3. cli driver gained `asserts-stderr` and `asserts-output` attrs

Discovered during Task 12 that `wheels info` writes its report to stderr (while `wheels --version` writes to stdout). Added two attrs so authors aren't coupled to the stream distinction:

- `asserts-stderr="..."` — substring must appear in stderr
- `asserts-output="..."` — substring must appear in stdout OR stderr (the forgiving default)

All three assertions run together if specified. Documented in `VALIDATION.md`.

## Known gaps / follow-ups for Phase 1

- **Compile driver.** Needs `wheels check <file>` or equivalent. Sample pages using illustrative CFC blocks should be re-tagged once that driver lands.
- **Tutorial driver.** Not implemented; `{test:tutorial}` tags report "no driver for kind" at run time. Plan target: Phase 1 Task 1.
- **CI install path for `wheels`.** The workflow uses `brew install wheels` on `macos-latest`; tap name `wheels-dev/wheels` is a placeholder pending confirmation. Linux-runner support is a meaningful Phase 2 follow-up — macOS runners are 10× more expensive on GitHub, and there's no reason the CLI can't target Linux.
- **Test runner script.** `test:docs-harness` uses `scripts/verify-docs/test/*.test.mjs` explicit glob because Node 24 stopped accepting bare directory targets for `node --test`. Works, but if we pick up nested test dirs later, widen to `**/*.test.mjs`.
- **pnpm workspace scripts directory.** `web/sites/guides/scripts/` didn't exist before Phase 0; it does now. Nothing else should live in it besides the verify-docs harness — if visual-regression tests ever move from `web/scripts/` to a per-site layout, rename conventions need thinking.

## Architectural notes worth preserving

### Why authoring in Starlight-native MDX

Original plan called for GitBook-flavored markdown, translated by `generate-guides.mjs` into Starlight content. For v4 we skip the translator entirely — MDX is the source, Starlight reads it directly. Pipeline is simpler, edit links point at the real source, Starlight components (`<Aside>`, `<Steps>`, `<FileTree>`, etc.) are available. v2.5 and v3.0 keep using `generate-guides.mjs` since their source stays frozen in GitBook format.

### Why regex MDX parsing

A real MDX parser (`@mdx-js/mdx`) would be more robust, but Phase 0 Meta strings are simple: `{test:kind attr="value" attr2="value2"}`. The regex handles every tagged block the samples generated. If Phase 1 or Phase 2 hits an edge case (multi-line meta, nested braces), upgrade then — the extract module is 40 lines.

### Why fixture-per-example

Every `{test:cli}` block creates a fresh fixture app via `wheels new`. It's ~1.5s per fixture, but it guarantees isolation: one example's migrations, generated files, or state can't contaminate another's. Parallel execution in the orchestrator cuts total wall-time.

## What to review

1. **Tone & structure** — read the four sample pages in order (tutorial → how-to → concept → reference). Does the voice feel right? Is tutorial hand-holding vs. reference dryness crisp enough?
2. **[STYLE.md](../../../web/sites/guides/STYLE.md)** — 73 lines, every rule enforceable. Anything missing or wrong?
3. **IA** — the sidebar JSON declares the full v4 information architecture. 11 top-level groups. Anything to rename/regroup before Phase 1 starts populating?
4. **Harness code** — `web/sites/guides/scripts/verify-docs/`. Short enough to read end-to-end. Key files: `lib/exec.mjs` (safe spawn), `lib/extract.mjs` (MDX walker), `drivers/cli.mjs` (driver with output asserts).
5. **Preview** — boot the site locally: `pnpm --filter @wheels-dev/site-guides dev`, then hit `http://localhost:4323/v4-0-0-snapshot/`. Navigate via the sidebar.

## Open decisions before Phase 1

These deferred from the spec and/or surfaced during Phase 0:

1. **Compile driver path.** File the `wheels check` CLI issue, or invent an alternative (e.g. temp-app + `wheels validate`)?
2. **CI install mechanism.** Confirm the brew tap name in `.github/workflows/docs-verify.yml`.
3. **Kamal deployment adoption.** Still pending — decision is Phase 1's deployment section.
4. **`.ai/` reference docs.** Leave alone, merge into guides, or keep parallel? No action needed yet; flagging for the end-of-Phase-2 decision.
5. **Tutorial domain check-in.** Still a blog? If Peter wants a different app for the tutorial (task list, polls, etc.), say so before Phase 1 Part 2.

Once approved: Phase 1 begins — the full 7-part tutorial (Parts 2–7) plus the supporting Start Here pages (Welcome, Why Wheels?, Installing, First 15 Minutes).
