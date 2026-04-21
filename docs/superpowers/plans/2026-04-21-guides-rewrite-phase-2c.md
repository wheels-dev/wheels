# Wheels 4.0 Guides — Phase 2c Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the four sections that PR #2169 claimed but didn't deliver: Deployment & Operations, Contributing & Project, Upgrading, Glossary. Plus sidebar wiring and the `.ai/` audit. Closes the gap flagged in the post-merge correction on that PR's description.

**Architecture:** Per-page subagent authoring against authoritative sources. Each page cites source (Module.cfc line numbers, middleware CFC paths, upstream docs) so drift is caught at review. Where v4 has no framework-provided surface (notably `wheels docker` / `wheels deploy` — neither exists in v4), pages teach the underlying mechanics directly (Dockerfiles, systemd units, nginx config) rather than inventing commands.

**Tech Stack:** Astro 5 + Starlight 0.34 + MDX. `wheels` CLI v0.3.5-SNAPSHOT+ (framework v4.0.0). Verify-docs harness with `{test:compile}` and `{test:cli}`.

**Base:** New branch `peter/guides-rewrite-phase-2c` off `develop` after cc2050c39. Merges to `develop` in a single PR at end of phase.

**Review model (unchanged from prior phases):**
- Content pages — subagent-driven; harness + build as verification gate
- Integration tasks (sidebar, `.ai/` audit, landing pages) — inline
- End-of-phase final review — single `pr-review-toolkit:code-reviewer` subagent across the Phase 2c diff

---

## Prologue — scope decisions for this phase

1. **Kamal posture (option a, user-confirmed 2026-04-21).** Deployment section documents Docker packaging + VM deploy + security hardening + observability using framework primitives that exist today. A single sentence in `deployment/index.mdx` notes the `wheels deploy` Kamal port is in progress with a link to the implementation plan at `docs/superpowers/plans/2026-04-20-wheels-deploy-kamal-port.md`. No `kamal-preview.mdx` page.
2. **No CommandBox-era command docs.** The legacy GitBook pages at `docs/src/working-with-wheels/` and the deleted `docs/src/command-line-tools/commands/docker/*` describe a defunct CommandBox module. They may be skimmed for IA hints but are NOT authoritative for v4. Subagents must verify every command against `cli/lucli/Module.cfc` + LuCLI Java sources before documenting it.
3. **User-authored Dockerfiles.** Since `wheels docker build/push/deploy` doesn't exist, `deployment/docker-deployment.mdx` walks the reader through writing a production Dockerfile for a Wheels app. The `tools/docker/lucee7/Dockerfile` in this repo is a cross-engine test rig, NOT a user template — do not copy/paste it; reference it only as an example of Java 21 + Lucee setup. The page ships a minimal reference Dockerfile that subagents author against Lucee 7 + Wheels 4.0 actuals.
4. **Upgrading scope.** Two active upgrade paths (3.x → 4.x, 2.x → 3.x). The 3.x → 4.x page is the critical one: it's the entry point for existing Wheels users landing on v4. The 2.x → 3.x page can cite the v3.0 guides instead of re-documenting everything.
5. **Contributing framing.** "Contributing & Project" section explicitly includes a "Writing docs" page (spec open-question #8, resolved in favor of inclusion). This teaches MDX + `{test:*}` harness + style guide so future contributors can fix/add pages without tribal knowledge.
6. **Glossary is a reference.** Single `glossary.mdx` under `v4-0-0-snapshot/` (already exists as placeholder). Hand-authored from terms already in-use in shipped Phase 2a/2b pages. No auto-linker plumbing in Phase 2c — that's a later polish pass.
7. **`.ai/` audit.** Remaining `.ai/wheels/**` files get checked for supersession by Phase 2c content. Any contributing/upgrading/deployment content in `.ai/` moves to guides or is deleted.

---

## File Structure

### New files — Deployment & Operations (6 pages)

All under `web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/`:

| Path | Responsibility |
|------|----------------|
| `index.mdx` (rewrite) | Landing — deployment models overview, decision matrix (Docker vs VM), note `wheels deploy` Kamal port in progress, CardGrid to sub-pages |
| `production-config.mdx` | Environment vars (`WHEELS_*`), `reloadPassword` rotation, datasource config for prod, route cache, environment.cfm for production |
| `docker-deployment.mdx` | Writing a production Dockerfile (Lucee 7 + Java 21 + Wheels), docker-compose example, multi-stage build, image size tips, health checks |
| `vm-deployment.mdx` | Lucee server install, nginx reverse proxy, systemd unit, zero-downtime with symlink swap, log rotation |
| `security-hardening.mdx` | `SecurityHeaders` middleware config, CSRF enforcement, HTTPS/HSTS, trusted proxies for real IP, secret management (no `.env` in image) |
| `observability-and-logging.mdx` | Structured logging patterns, health-check endpoint, error tracking via `wheels-sentry` package, metrics/APM options (opt-in), request ID middleware |

### New files — Contributing & Project (4 pages)

All under `web/sites/guides/src/content/docs/v4-0-0-snapshot/contributing/`:

| Path | Responsibility |
|------|----------------|
| `index.mdx` (rewrite) | Landing — how the project is run, core team, code of conduct link, ways to contribute (code / docs / packages / issues), CardGrid |
| `pull-requests.mdx` | Fork → branch → test → submit workflow; commit message conventions (commitlint scopes); `peter/*` branch prefix; PR review expectations |
| `coding-standards.mdx` | camelCase naming; CFML component conventions; cross-engine compat rules (summarize `.ai/wheels/cross-engine-compatibility.md`); test-before-push requirement |
| `writing-docs.mdx` | MDX frontmatter schema; `{test:compile}` / `{test:cli}` / `{test:tutorial}` harness blocks; style guide pointer; `pnpm verify:docs` + `pnpm build` workflow; how to add a page to the sidebar |

### New files — Upgrading (3 pages)

All under `web/sites/guides/src/content/docs/v4-0-0-snapshot/upgrading/`:

| Path | Responsibility |
|------|----------------|
| `index.mdx` (rewrite) | Versioning policy (semver), release cadence, upgrade philosophy, CardGrid to per-version pages |
| `3x-to-4x.mdx` | **The big one.** Breaking changes (plugins → packages, DI container changes, middleware pipeline, test framework BDD), deprecations, migration checklist, before/after code samples. Sources: `CHANGELOG.md`, `docs/releases/wheels-3.0-vs-4.0.md`, `docs/releases/wheels-4.0-audit.md` |
| `2x-to-3x.mdx` | Short page. Points readers to v3.0 guides for the 2→3 upgrade proper, then calls out what changed in 4.0 that affects anyone hopping 2→3→4 in one sitting |

### New / rewrite — Glossary (1 page)

| Path | Responsibility |
|------|----------------|
| `glossary.mdx` (rewrite) | Alphabetized terms; definitions link to the authoritative guide page; terms harvested from Phase 2a/2b shipped content |

### Modified files

| Path | Change |
|------|--------|
| `web/sites/guides/src/sidebars/v4-0-0-snapshot.json` | Populate `items: []` for Deployment & Operations (6), Contributing & Project (4), Upgrading (3). Glossary already single-link. |

### Deleted files

TBD during `.ai/` audit (Task 15). Candidates:
- `.ai/wheels/contributing-*` (if any — verify)
- `.ai/wheels/deployment-*` (if any — verify)
- `.ai/wheels/upgrading/*` (if any — verify)

---

## Phase Layout

| Task | Page / Action | Source authority | Review mode |
|------|---------------|------------------|-------------|
| 0 | Create branch, confirm clean base, set up TodoWrite tracking | — | Inline |
| 1 | `deployment/index.mdx` — Landing | Existing placeholder; design spec deployment goals | Subagent + harness |
| 2 | `deployment/production-config.mdx` | `config/environment.cfm`, `config/settings.cfm`, framework env-var handling | Subagent + harness |
| 3 | `deployment/docker-deployment.mdx` | Lucee 7 + Java 21 actuals; `tools/docker/lucee7/Dockerfile` for reference only | Subagent + harness |
| 4 | `deployment/vm-deployment.mdx` | Lucee admin install docs; nginx/systemd standard patterns | Subagent + harness |
| 5 | `deployment/security-hardening.mdx` | `vendor/wheels/middleware/SecurityHeaders.cfc`, `vendor/wheels/middleware/Cors.cfc`, CSRF helpers | Subagent + harness |
| 6 | `deployment/observability-and-logging.mdx` | `vendor/wheels/middleware/RequestId.cfc`, `packages/sentry/` package, Wheels logging conventions | Subagent + harness |
| 7 | `contributing/index.mdx` — Landing | Legacy `contributing-to-wheels.md` (IA only), current core team, CONTRIBUTING.md if present | Subagent + harness |
| 8 | `contributing/pull-requests.mdx` | Legacy `submitting-pull-requests.md` (process), `commitlint.config.js`, CLAUDE.md commit conventions | Subagent + harness |
| 9 | `contributing/coding-standards.mdx` | `.ai/wheels/cross-engine-compatibility.md`, wiki code-style link, test-before-push convention from CLAUDE.md | Subagent + harness |
| 10 | `contributing/writing-docs.mdx` | `web/sites/guides/scripts/verify-docs/`, style guide, sidebar JSON format | Subagent + harness |
| 11 | `upgrading/index.mdx` — Landing | Versioning in `box.json` / framework version constant | Subagent + harness |
| 12 | `upgrading/3x-to-4x.mdx` | `CHANGELOG.md`, `docs/releases/wheels-3.0-vs-4.0.md`, `docs/releases/wheels-4.0-audit.md`, `docs/releases/blog-skeletons/02-upgrading-from-3x.md` | Subagent + harness |
| 13 | `upgrading/2x-to-3x.mdx` | v3.0 guides + 4.0 changelog relevant entries | Subagent + harness |
| 14 | `glossary.mdx` — Rewrite | Harvest terms from Phase 2a/2b shipped pages | Subagent + harness |
| 15 | `.ai/` audit — delete anything superseded by Phase 2c | — | Inline |
| 16 | Sidebar JSON — wire all 13 new pages into three empty groups | — | Inline |
| 17 | Full harness + build + Phase 2c report | — | Inline |
| 18 | Final code review | — | Subagent (pr-review-toolkit:code-reviewer) |

**19 tasks. Expected wall time: 2-3 sessions.** Lighter than 2b-CLI because the page count is smaller and most pages don't need extensive `{test:cli}` coverage (Deployment + Contributing + Upgrading are more narrative than CLI reference).

---

## Shared conventions (carrying forward from Phase 2b)

- **Diátaxis typing:** Deployment pages = `howto`. Contributing pages = `howto`. Upgrading pages = `howto`. Glossary = `reference`. Landing pages = `section`.
- **Second-person voice.** No marketing copy. Headings at `###` max.
- **`{test:compile}`** on every non-trivial code block that's valid CFML/MDX. No `{test:cli}` spam — most Phase 2c pages are narrative, not command reference.
- **Authoritative source cite** at top of each subagent prompt. Drift is prevented by grounding in source, not by review.
- **Commit message pattern:**
  ```
  docs(docs): <section>/<page-slug> — <imperative phrase>
  ```
  Examples:
  - `docs(docs): deployment/docker-deployment — write production Dockerfile reference`
  - `docs(docs): upgrading/3x-to-4x — breaking changes and migration checklist`
- **Sidebar sort order** matches Phase Layout task numbers within each section.

### Verification template (every page)

```bash
export JAVA_HOME=/opt/homebrew/Cellar/openjdk@21/21.0.8/libexec/openjdk.jdk/Contents/Home
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/upbeat-napier-7ccf97/web/sites/guides
pnpm verify:docs src/content/docs/v4-0-0-snapshot/<section>/<page>.mdx
pnpm build 2>&1 | tail -5
```

### Cross-page consistency rules

- **No fabricated commands.** If a command doesn't exist in `cli/lucli/Module.cfc` or LuCLI upstream, don't document it. For Deployment especially: `wheels docker *` and `wheels deploy` do NOT exist in v4 at time of writing.
- **Kamal reference is forward-looking.** `deployment/index.mdx` mentions `wheels deploy` (Kamal port) as in-progress, links to `docs/superpowers/plans/2026-04-20-wheels-deploy-kamal-port.md`. Other deployment pages do NOT assume Kamal.
- **Upgrading citations.** Every breaking change in `3x-to-4x.mdx` cites a CHANGELOG entry or release doc. Don't paraphrase — quote + link.
- **Glossary entries** point to the page where the term is fully defined. If a term is used in Phase 2a/2b pages but never defined, flag it in the Phase 2c report — don't invent the definition.

---

## Task details

### Task 0: Create branch + clean base

- [ ] Branch from `develop` at cc2050c39 (or later if develop has advanced): `git checkout -b peter/guides-rewrite-phase-2c develop`
- [ ] Confirm clean tree, no untracked under `web/sites/guides/src/content/docs/v4-0-0-snapshot/`
- [ ] Spawn TodoWrite with tasks 1–18 for progress tracking

### Tasks 1–14: Per-page subagent authoring

Each page task follows the same shape. Dispatched as a single subagent call (general-purpose or feature-dev:code-architect):

**Subagent prompt template:**
```
You are authoring one page in the Wheels v4 guides rewrite, Phase 2c.

Page: web/sites/guides/src/content/docs/v4-0-0-snapshot/<path>.mdx
Diátaxis type: <howto|reference|section>
Scope: <from table above>
Source authority: <specific file paths + line numbers>

REQUIREMENTS:
- Read the style guide at web/sites/guides/docs/writing-style-guide.md
- Read 2-3 existing Phase 2b pages in the same directory/type to match voice
- Verify every technical claim against source (cite file + line)
- Every non-trivial code block gets a {test:compile} or {test:cli} block
- Close with a "Related" CardGrid to 2-4 sibling pages
- Run pnpm verify:docs on the page and pnpm build; both must pass

NON-REQUIREMENTS (explicit):
- Do NOT invent commands. If wheels docker X doesn't exist in cli/lucli/Module.cfc, don't document it.
- Do NOT copy from legacy docs/src/ without source-verifying — most of it is CommandBox-era.

Commit with: docs(docs): <section>/<slug> — <imperative phrase>
```

Task 0 sets up the worktree + todos. Tasks 1–14 dispatch subagents per page. Each task is marked complete only after the subagent's commits are on branch AND `pnpm verify:docs` + `pnpm build` pass on the page.

### Task 15: `.ai/` audit

- [ ] List all files under `.ai/wheels/` that mention "contributing", "deployment", "upgrading", or "docs workflow"
- [ ] For each: determine if Phase 2c pages supersede it
- [ ] Delete superseded files; update `CLAUDE.md` `.ai/` reference list
- [ ] Commit: `docs(docs): .ai/ audit — delete files superseded by Phase 2c`

### Task 16: Sidebar wiring

- [ ] Edit `web/sites/guides/src/sidebars/v4-0-0-snapshot.json`
- [ ] Deployment & Operations: 6 entries, order matches Tasks 1–6
- [ ] Contributing & Project: 4 entries, order matches Tasks 7–10
- [ ] Upgrading: 3 entries, order matches Tasks 11–13
- [ ] Glossary: already single-link, no change
- [ ] Commit: `docs(docs): sidebar — wire phase 2c pages`
- [ ] Full `pnpm build` — confirm no broken-link warnings, all 13 pages render

### Task 17: Phase 2c report

Mirror prior reports' structure. File: `docs/superpowers/plans/2026-04-21-guides-rewrite-phase-2c-report.md`.

Sections:
- Summary (page count, harness blocks, verification status)
- Drift caught per page (every time source verification surfaced a discrepancy)
- Source-verification wins
- Carryover (anything not shipped, tracked as issue)
- Next (follow-up work)

### Task 18: Final code review

Dispatch `pr-review-toolkit:code-reviewer` across the Phase 2c diff. Resolve high-priority findings before opening PR.

---

## Exit criteria

Phase 2c is done when:

1. 13 new content pages shipped (6 Deployment + 4 Contributing + 3 Upgrading) + glossary rewrite
2. `pnpm verify:docs` passes on the full tree (no regressions in Phase 0–2b, all new blocks pass)
3. `pnpm build` produces 351 rendered pages (338 + 13) with no broken-link warnings
4. Sidebar JSON has no empty `items: []` arrays under v4-0-0-snapshot
5. Phase 2c report committed
6. `.ai/` audit committed
7. Final review resolved
8. PR opened to `develop` with accurate description

---

## Scope decisions (resolved 2026-04-21)

1. **Dockerfile reference pattern → Lucee 7 canonical, others in a sidebar note.** `wheels new` scaffolds Lucee by default, CI's canary matrix leads with Lucee 7, and writing three parallel Dockerfile patterns triples maintenance for no reader benefit. Adobe/BoxLang get a "same pattern applies, swap the base image" callout.
2. **Kamal plan link target → link the plan file now, with a grep-able TODO to swap.** The plan file is the only concrete artifact today. Embed `<!-- TODO(phase-2c): swap Kamal plan link to wheels deploy PR once opened -->` in `deployment/index.mdx` so the next deployment-touching PR catches the swap.
3. **`upgrading/2x-to-3x.mdx` → short pointer page (~1 screen).** v3.0 guides are still frozen and live; duplicating the 2→3 upgrade path here creates two sources of truth that will drift. Real value-add is ~20 lines: "if you're hopping 2→4 in one sitting, do 2→3 per the v3 guides first, then read 3x-to-4x."
4. **Glossary → hand-curated, ~30-50 terms.** Auto-harvest has no reliable "what's a defined term?" rule. Walk Phase 2a/2b pages, pull terms readers will Google or cmd-F (Turbo Frame, DI container, scope, middleware, migrator, package, enum, etc.), one-sentence definitions, link to the page where the concept is fully explained. Automation is a 4.1 polish task.
5. **`.ai/` audit → scoped to Phase 2c topics.** Matches prior phase precedent. Grep `.ai/wheels/**` for "contributing", "deployment", "upgrading", "docs workflow" — delete what's superseded, leave the rest. A full `.ai/` sweep is on the design spec's list for end-of-Phase-2.
