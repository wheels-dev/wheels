# Guides Rewrite — Phase 2a Completion Report

**Date:** 2026-04-20
**Branch:** `claude/lucid-thompson-b8c121` (draft PR [#2169](https://github.com/wheels-dev/wheels/pull/2169))
**Spec:** [../specs/2026-04-18-guides-rewrite-v4-design.md](../specs/2026-04-18-guides-rewrite-v4-design.md)
**Plan:** [./2026-04-20-guides-rewrite-phase-2a.md](./2026-04-20-guides-rewrite-phase-2a.md)
**Prior phase:** [Phase 1 report](./2026-04-18-guides-rewrite-phase-1-report.md)

## Shipped

**23 commits** on top of Phase 1 head `bba06cda5` — 20 content pages + 3 integration/cleanup commits:

| SHA | What |
|-----|------|
| `df1876aa0` | core-concepts/request-lifecycle — rewrite from phase 0 stub |
| `f2cefa003` | fix(web): code-block contrast — high-contrast theme + drop bg override |
| `6616db75e` | core-concepts/mvc-in-wheels + drop .ai mvc-architecture |
| `9ab24bafe` | core-concepts/conventions-over-configuration |
| `3a93e7a9f` | core-concepts/orm-philosophy + drop .ai orm subtree + rails-comparison |
| `0e27a9cda` | core-concepts/dependency-injection + drop .ai dependency-injection |
| `234b00924` | core-concepts/middleware-pipeline + drop .ai middleware |
| `e71f7db51` | core-concepts/how-routing-works + drop .ai routing |
| `396ab07ec` | core-concepts/environments-and-configuration + drop .ai configuration stragglers |
| `d7a79d9ee` | basics/routing + drop .ai configuration/routing |
| `e6fe32bee` | basics/controllers-and-actions + drop .ai controllers subtree |
| `a5c75c452` | basics/views-layouts-partials + drop .ai views stragglers |
| `a1f834719` | basics/forms-and-form-helpers + drop .ai views forms/helpers |
| `ef60e9054` | basics/validation-and-errors + drop .ai database/validations |
| `a938ccaa8` | basics/models-and-the-orm + drop .ai models stragglers |
| `75096e1ae` | basics/associations + drop .ai models/associations + database/associations |
| `e3ec979d8` | basics/migrations + drop .ai database/migrations |
| `183c5807e` | basics/seeding + drop .ai database/seeding |
| `db8c44cba` | basics/query-builder-and-scopes + drop .ai 4 model files |
| `d0f135a56` | basics/database-and-multiple-datasources + drop .ai database/queries |
| `dc13fab88` | tutorial — cross-link Parts 2-6 into Phase 2a reference pages |
| `a0eaac13e` | testing/index — landing page for Phase 2a testing section |
| `9cb36f064` | task 22 .ai/ audit — delete 3 redundant files + reconcile CLAUDE.md |

### Deliverables checklist

**Core Concepts — 8 pages (concept type):**
- [x] The Request Lifecycle
- [x] MVC in Wheels
- [x] Conventions over Configuration
- [x] ORM Philosophy
- [x] The Dependency Injection Container
- [x] Middleware Pipeline
- [x] How Routing Works
- [x] Environments and Configuration

**The Basics — 11 pages (howto type):**
- [x] Routing
- [x] Controllers and Actions
- [x] Views, Layouts, Partials
- [x] Forms and Form Helpers
- [x] Validation and Error Display
- [x] Models and the ORM
- [x] Associations
- [x] Migrations
- [x] Seeding
- [x] Query Builder and Scopes
- [x] Database and Multiple Datasources

**Testing — 1 landing page:**
- [x] Testing (overview)

**Integration:**
- [x] Tutorial Parts 2-6 cross-linked into Phase 2a pages
- [x] Sidebar populated for Core Concepts (8 entries) and The Basics (11 entries)
- [x] Code-block contrast fix (github-dark-high-contrast + github-light theme pair)
- [x] `.ai/` stragglers audit — 3 clearly-redundant files deleted; 36 Phase 2b/2c targets kept
- [x] CLAUDE.md reconciliations landed — `wheels seed`, `wheels start`, `timestamps()` three columns

## Verification

- **`pnpm verify:docs`** — 142 tagged blocks across 44 files. **142 passed, 0 failed.** Runtime ~1 min.
- **`pnpm test:docs-harness`** — 29/29 unit tests pass. Runtime ~30s.
- **`pnpm build`** — 290 pages build clean, no broken-link errors.
- **Compile driver mode:** still `fallback` (LuCLI PR [cybersonic/LuCLI#56](https://github.com/cybersonic/LuCLI/pull/56) not yet merged). Once it merges, every `{test:compile}` block — there are 90+ of them now across tutorial + Phase 2a basics — auto-upgrades to real parse checking with zero harness code changes.

## What changed from the plan

**Seven deviations, all forced by framework reality (drift caught during execution):**

### 1. Path convention: `config/environments/<env>.cfm` → `config/<env>/settings.cfm`
Task 8 verified against scaffold source and framework boot order. Plan had the Rails-style path; Wheels uses `config/production/settings.cfm` etc. Fixed in the Environments page and in Tutorial Part 6 (commit `dc13fab88`).

### 2. `LUCLI_ENV` doesn't exist
Task 8 confirmed only `WHEELS_ENV` is referenced in framework code. Documented `WHEELS_ENV` only.

### 3. `renderJSON` doesn't exist — use `renderWith(data=...)`
Task 10 found the real content-negotiation API. Rails naming didn't transfer.

### 4. View-side is `includePartial`, controller-side is `renderPartial`
Task 11 corrected plan's reversed terminology.

### 5. No `this.layout = "admin"` — use `usesLayout(template="admin")` in `config()`
Task 11 corrected phantom API.

### 6. Form helper gaps caught across multiple tasks
- `dateTimeField` doesn't exist — only `dateField` and `dateTimeSelect` (select-group)
- `label()` / `labelTag()` don't exist as standalone — `label=` is an argument on each helper
- `contentTag` doesn't exist as a public helper

### 7. Model/association API drifts
- **Counter caches don't exist in Wheels.** Plan invented them from Rails.
- `dependent=` accepts `delete`, `deleteAll`, `remove`, `removeAll`, `false` — NOT `destroy`, `deny`, `nullify`.
- Many-to-many uses `shortcut="roles"`, NOT `through="bookings"`.
- `$query()` doesn't exist — raw SQL path is native CFML `queryExecute()` with explicit datasource.
- Read-replica feature: NOT shipped. Manual two-datasource pattern documented honestly.

### 8. Column builder args: `columnNames` (plural) + `allowNull`
Task 16: verified against `TableDefinition.cfc`. Plan used Rails-style `columnName` + `null`.

### 9. `t.timestamps()` creates three columns, not two
Adds `createdAt`, `updatedAt`, AND `deletedAt` (soft-delete marker). CLAUDE.md anti-pattern #7 updated.

### 10. Bonus correction: enum list-form stores STRING, not integer
Task 18: `enum(property="status", values="draft,published,archived")` stores the literal name. Only struct-form (`values={low: 0, medium: 1, high: 2}`) maps to integers.

## Known gaps / Phase 2b follow-ups

The subagents flagged real API drifts worth filing separately:

1. **Cors default is `""` not `"*"`** — Task 6 flagged the `.ai/` middleware doc had the default wrong (framework default is fail-closed). User doc is correct.
2. **SecurityHeaders ships more headers than old `.ai/` docs claimed** — `contentSecurityPolicy`, `strictTransportSecurity`, `permissionsPolicy` exist. Documented in the concept page.
3. **`addForeignKey()` lacks `onDelete`/`onUpdate` options** — only on `t.references()`. A real framework gap; filing as a Phase 2c Wheels improvement candidate.
4. **`tutorial Part 7` may still reference `config/environments/production.cfm`** (Task 20 only fixed Part 6 explicitly). Worth a grep pass in Phase 2b or 2c opening.
5. **Tutorial uses `application.wo.service(...)` in 6b but concept page shows `service(...)`** — both work (the `wo` prefix is the explicit long form). No fix needed for Phase 2a, but Phase 2b Digging Deeper Auth page should resolve which is canonical.
6. **36 `.ai/wheels/` files remain** — every one is a Phase 2b or 2c target. The file-by-file deletion pattern established in Phase 2a continues through those phases.

## Architectural notes worth preserving

### The consolidation pressure caught real bugs

Across 20 subagent dispatches, the content-writer subagents flagged **30+ distinct API drifts** between my plan, the old `.ai/` docs, and framework source. Each drift became a correction in the user doc and — where relevant — a CLAUDE.md update.

The pattern was consistent: subagent reads `.ai/` + reads `vendor/wheels/`, discovers the two disagree, documents the verified reality in the user doc, flags the mismatch in its report. Over 20 pages, this caught counter-caches (nonexistent), read replicas (nonexistent), `renderJSON` (nonexistent), `$query` (nonexistent), plus naming drifts for `dependent=`, `through=`, column builders, environment paths, and form helpers.

The `.ai/` folder wasn't just redundant — it was actively wrong in places. Consolidation with a "verify against source" loop is a one-time correction opportunity that merging-without-verifying would have silently propagated.

### Why concept pages all came in short

Every Core Concepts page landed 50-80 lines despite the plan suggesting 90-140. The subagents consistently invoked STYLE.md's "short sentences, no filler, no marketing copy" rule to resist padding. The result is pages that read tight and honest rather than bloated. This is correct; the plan's length ranges were guidance, not floors.

### Why the Basics how-to pages all passed the harness

11 how-to pages with 90+ `{test:compile}` blocks landed with 100% pass rate on first try. The compile driver's bracket-balance fallback is weak — catches typos only — but discipline in the subagents' block construction made the fallback sufficient. Once LuCLI PR #56 merges and the driver upgrades to real `wheels cfml` parse checking, these blocks get real validation for free. That's the point of the two-mode design.

### The code-block contrast fix was a hidden foundation cost

Task 1's observed "blue text hard to see" interrupt led to commit `f2cefa003` — a 17-line change to `@wheels-dev/ui/styles/starlight-theme.css` and `astro.config.mjs`. The root cause was `background: #111` forced on all `<pre>` in both light and dark mode, combined with no expressive-code theme configuration. Fix: set `expressiveCode.themes: ['github-dark-high-contrast', 'github-light']` and remove the background override. Affects guides, api, and landing sites (all consume the shared UI package).

## Open decisions for Phase 2b

1. **Package installation.** Tutorial Part 4 falls back to loading Turbo from a CDN because there's no `wheels package install hotwire` command. Framework gap #2 in the tracker. Blocks clean Phase 2b Digging Deeper Packages page.

2. **bcrypt availability.** Tutorial Part 6 ships salted SHA-256 with a caution aside because no bcrypt helper exists. Framework gap #4. Phase 2b Auth pages should either ship bcrypt or document SHA-256 as the official guidance.

3. **MCP documentation placement.** `.ai/wheels/mcp/{overview,setup,tool-reference}.md` remain. MCP is a CLI-Reference-style concern or a dedicated Phase 2c page. Decide early.

4. **`agent-context/` folder.** Phase 2a kept `.ai/wheels/cross-engine-compatibility.md`, `snippets/`, `patterns/` intact — all agent-operational content that doesn't have a user-doc home. Phase 2c's final audit decides: absorb into CLAUDE.md, create a dedicated `agent-context/` folder, or keep `.ai/` as the agent-facing namespace.

5. **Tutorial Part 7's stale `config/environments/production.cfm` reference** (if any still exists). A grep pass at Phase 2b start, or fold into Phase 2c polish.

## Next moves

Phase 2b: Advanced + Reference. Scope per Phase 1 plan: Digging Deeper (~14 pages), CLI Reference (~110 pages migrated + enhanced). Writing a Phase 2b plan doc is the natural start.

Before Phase 2b starts:
- **Rebuild + reinstall wheels CLI** to pick up merged [wheels#2168](https://github.com/wheels-dev/wheels/pull/2168) (framework gaps batch 1) — snippet templates, route binding warning, form-helper `data-auto-id`, etc.
- **Chase [LuCLI #56](https://github.com/cybersonic/LuCLI/pull/56)** — once merged, harness compile driver upgrades from fallback to native mode automatically.
- **File Wheels framework issues** for the three remaining-gap follow-ups worth turning into tracked work (addForeignKey cascades, package install command, bcrypt helper).
