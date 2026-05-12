# Wheels 4.0 Guides — Phase 2a Implementation Plan (Foundations)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the Core Concepts section (8 pages), The Basics section (11 pages), and the Testing Overview landing page — the foundation layer that every other Phase 2 section will cross-link into. Consolidate each section's `.ai/` equivalent into user docs as it lands.

**Architecture:** Each page is authored directly in Starlight-native MDX at `web/sites/guides/src/content/docs/v4-0-0-snapshot/`. Concept pages use prose + diagrams (no code harness blocks); how-to pages use `{test:compile}` on CFML snippets and `{test:cli}` for CLI commands. Sidebar updated incrementally per page. For each section that lands, the corresponding `.ai/wheels/<subdir>/` is audited and deleted — user docs become the single source of truth.

**Tech Stack:** Astro 5 + Starlight 0.34 + MDX. Node 22+ ESM harness. `wheels` CLI v0.3.5-SNAPSHOT+ (framework v4.0.0). Existing Phase 1 verify-docs harness with three drivers (cli, compile, tutorial).

**Base:** Branch `claude/lucid-thompson-b8c121` at Phase 1 head `bba06cda5`. Phase 2a commits land here. The branch stays open through Phase 2b and 2c; the single final merge to develop happens at the end of Phase 2c (per the original spec).

**Review model (pragmatic split established in Phase 1):**
- Concept + how-to content pages — inline execution with self-review against STYLE.md + harness-passing as the review gate
- Any harness changes needed mid-phase — full subagent ceremony (implementer → spec review → code review)
- Section-boundary integration (sidebar, build check, `.ai/` deletion) — inline
- End-of-phase final review — single pr-review-toolkit:code-reviewer subagent across the full Phase 2a diff

**Prologue — policy decisions in force for Phase 2:**

1. **Kamal is the committed deploy path.** No "TBD" / "being evaluated" language anywhere. Phase 2c's Deployment section writes the full Kamal walkthrough; Phase 2a's pages don't touch deployment but should name Kamal if they need to reference deploy (e.g., How Routing Works → "in production the router delegates to the Kamal-managed Lucee container…").

2. **`.ai/` folder consolidates into user docs.** Every Phase 2 section has a corresponding `.ai/wheels/<subdir>/`. As each user page or subsection lands, its `.ai/` equivalent is DELETED in the same commit — no drift window. Content that is genuinely agent-specific (operational runbooks for Claude, Lucee/Adobe cross-engine gotchas that only agents care about) gets promoted into CLAUDE.md or a narrowly-scoped `agent-context/` directory at the repo root. User-facing content becomes the new single source of truth.

---

## File Structure

### New files — Core Concepts

All under `web/sites/guides/src/content/docs/v4-0-0-snapshot/core-concepts/`:

| Path | Responsibility |
|------|----------------|
| `request-lifecycle.mdx` | Page (rewrite existing stub) — how a request flows through middleware → router → controller → view |
| `mvc-in-wheels.mdx` | Page — Wheels' flavor of MVC, what lives where, why |
| `conventions-over-configuration.mdx` | Page — the conventions Wheels enforces, what they buy you, when to override |
| `orm-philosophy.mdx` | Page — ActiveRecord-style ORM mental model, fat-models-thin-controllers, validation-in-model |
| `dependency-injection.mdx` | Page — the DI container, service scopes, injection patterns |
| `middleware-pipeline.mdx` | Page — how middleware composes, request/response flow, built-in middleware |
| `how-routing-works.mdx` | Page — route matching, resource routes, route model binding, named routes |
| `environments-and-configuration.mdx` | Page — development/test/production, `config/*.cfm`, the `set()` function, env-specific overrides |

### New files — The Basics

All under `web/sites/guides/src/content/docs/v4-0-0-snapshot/basics/`:

| Path | Responsibility |
|------|----------------|
| `routing.mdx` | Page — how to define routes (resources, get/post, nested, namespaced), the route helpers |
| `controllers-and-actions.mdx` | Page — writing a controller, the 7 REST actions, custom actions, params, filters |
| `views-layouts-partials.mdx` | Page — rendering, layouts, partials, `includePartial`, view helpers overview |
| `forms-and-form-helpers.mdx` | Page — every form helper (textField, select, etc.), object-bound vs tag-style, the `data-auto-id` attribute |
| `validation-and-errors.mdx` | Page — model validations, error rendering, `errorMessagesFor`, custom validations |
| `models-and-the-orm.mdx` | Page — defining a model, finders, persistence, primary keys, `findAll`/`findByKey`/`findOne` |
| `associations.mdx` | Page — hasMany/belongsTo/hasOne, through, polymorphic, eager loading with `include=` |
| `migrations.mdx` | Page — writing migrations, column types, indexes, rollback, running them |
| `seeding.mdx` | Page — `app/db/seeds.cfm`, `seedOnce()`, environment-specific seeds |
| `query-builder-and-scopes.mdx` | Page — chainable `where`, scopes, enum scopes, batch processing |
| `database-and-multiple-datasources.mdx` | Page — configuring datasources, multiple DBs, readReplicas, transactions |

### New files — Testing (landing only for Phase 2a; rest to 2b)

| Path | Responsibility |
|------|----------------|
| `testing/index.mdx` | Landing page — what kinds of tests Wheels ships, WheelsTest vs legacy RocketUnit, running tests, where to go next |

### Modified files

| Path | Change |
|------|--------|
| `web/sites/guides/src/sidebars/v4-0-0-snapshot.json` | Add all 20+ new page entries under Core Concepts, The Basics, Testing |
| `web/sites/guides/src/content/docs/v4-0-0-snapshot/core-concepts/request-lifecycle.mdx` | Rewrite (currently a Phase 0 stub) |

### Deleted files — `.ai/` consolidation

| Deleted as part of | What gets removed |
|---------------------|-------------------|
| Task 2 (MVC in Wheels) | `.ai/wheels/core-concepts/mvc-architecture/` (all files) |
| Task 4 (ORM Philosophy) | `.ai/wheels/core-concepts/orm/` (all files), `.ai/wheels/core-concepts/rails-comparison.md` (merge into Why Wheels? if gap found; otherwise delete) |
| Task 7 (How Routing Works) | `.ai/wheels/core-concepts/routing/` |
| Task 8 (Environments and Configuration) | `.ai/wheels/configuration/{application,environments,framework-settings,overview,best-practices,troubleshooting}.md` |
| Task 9 (Routing — Basics) | `.ai/wheels/configuration/routing.md` |
| Task 10 (Controllers and Actions) | `.ai/wheels/controllers/{architecture,filters,model-interactions,rendering,params,http-detection,security}.md` + subdirs (except api.md which defers to Phase 2b) |
| Task 11 (Views, Layouts, Partials) | `.ai/wheels/views/{architecture,layouts,partials,data-handling,best-practices,advanced-patterns}.md` + subdirs (except helpers.md which belongs with the forms page) |
| Task 12 (Forms and Form Helpers) | `.ai/wheels/views/forms.md`, `.ai/wheels/views/helpers.md`, `.ai/wheels/views/helpers/` |
| Task 13 (Validation and Error Display) | `.ai/wheels/database/validations/` |
| Task 14 (Models and the ORM) | `.ai/wheels/models/{architecture,methods-reference,callbacks,performance,best-practices,advanced-features,advanced-patterns}.md` |
| Task 15 (Associations) | `.ai/wheels/models/associations.md`, `.ai/wheels/database/associations/` |
| Task 16 (Migrations) | `.ai/wheels/database/migrations/` |
| Task 17 (Seeding) | `.ai/wheels/database/seeding.md` |
| Task 18 (Query Builder and Scopes) | `.ai/wheels/models/{query-builder,scopes,enums,batch-processing}.md` |
| Task 19 (Database and Multiple Datasources) | `.ai/wheels/database/queries/` |
| Task 21 (Testing Overview) | `.ai/wheels/testing/README.md` (if applicable; don't touch subdirs — rest to 2b) |

`.ai/wheels/core-concepts/README.md`, `.ai/wheels/models/testing.md`, `.ai/wheels/models/user-authentication.md`, `.ai/wheels/models/shared-models.md` — evaluate in Task 22 (`.ai/` audit); may relocate, may delete.

Note: the `.ai/wheels/core-concepts/` directory also contains supporting files (`mvc-architecture/`, `orm/`, etc. have subdirectories). Each task's deletion is "the whole subtree unless there's a specific exception." Do not carry forward content that has been captured in the user docs; do not delete content that hasn't. When in doubt, read the `.ai/` file and compare against the user doc — the user doc must cover everything user-facing before the delete happens.

---

## Phase Layout

| Task | Page / Action | Review mode |
|------|---------------|-------------|
| 1. Request Lifecycle | Concept content | Inline + build check |
| 2. MVC in Wheels (+ `.ai/` delete) | Concept content | Inline + build check |
| 3. Conventions over Configuration | Concept content | Inline + build check |
| 4. ORM Philosophy (+ `.ai/` delete) | Concept content | Inline + build check |
| 5. The Dependency Injection Container | Concept content | Inline + build check |
| 6. Middleware Pipeline | Concept content | Inline + build check |
| 7. How Routing Works (+ `.ai/` delete) | Concept content | Inline + build check |
| 8. Environments and Configuration (+ `.ai/` delete) | Concept content | Inline + build check |
| 9. Routing (Basics) (+ `.ai/` delete) | How-to + compile blocks | Inline + harness + build |
| 10. Controllers and Actions (+ `.ai/` delete) | How-to + compile blocks | Inline + harness + build |
| 11. Views, Layouts, Partials (+ `.ai/` delete) | How-to + compile blocks | Inline + harness + build |
| 12. Forms and Form Helpers (+ `.ai/` delete) | How-to + compile blocks | Inline + harness + build |
| 13. Validation and Error Display (+ `.ai/` delete) | How-to + compile blocks | Inline + harness + build |
| 14. Models and the ORM (+ `.ai/` delete) | How-to + compile blocks | Inline + harness + build |
| 15. Associations (+ `.ai/` delete) | How-to + compile blocks | Inline + harness + build |
| 16. Migrations (+ `.ai/` delete) | How-to + compile blocks | Inline + harness + build |
| 17. Seeding (+ `.ai/` delete) | How-to + compile blocks | Inline + harness + build |
| 18. Query Builder and Scopes (+ `.ai/` delete) | How-to + compile blocks | Inline + harness + build |
| 19. Database and Multiple Datasources (+ `.ai/` delete) | How-to + compile blocks | Inline + harness + build |
| 20. Sidebar + tutorial cross-link pass | Integration | Inline + build |
| 21. Testing Overview (+ `.ai/` delete) | Landing page | Inline + build |
| 22. `.ai/` final audit for Phase 2a | Cleanup | Inline |
| 23. Full harness + build + Phase 2a completion report | Integration | Inline |
| 24. Final code review across Phase 2a diff | Review | Subagent |

24 tasks. Expected wall time: 4-6 sessions assuming ~4-5 pages per session at content-writer subagent pace.

---

## Shared conventions for every content task

To avoid repetition across 20 nearly-identical tasks, here are the conventions every task inherits. Each task brief below points at this section.

### Frontmatter template

Every page has frontmatter of this shape:

```yaml
---
title: <Human Title>
description: <one-sentence description, 80-140 chars, no trailing period>
type: concept | howto | reference
sidebar:
  order: N
---
```

`type` matches Diátaxis — concept pages explain, how-to pages perform a task, reference pages are dry tables/lists.

### Opening section (every page)

- Starlight component imports line (at minimum: `Aside`, plus whatever else the page uses):
  ```mdx
  import { Aside, Steps, CardGrid, LinkCard, FileTree, Tabs, TabItem } from '@astrojs/starlight/components';
  ```
  Only import what the page actually uses.

- One-sentence summary paragraph.

- **"You'll learn"** bullet block (3-5 items), formatted:
  ```mdx
  **You'll learn:**

  - First thing
  - Second thing
  - Third thing
  ```

- Optional `<Aside type="note">` declaring audience assumptions when relevant (per STYLE.md).

### Closing section (concept pages)

Concept pages end with a **"See also"** block — plain bulleted list, not a CardGrid:

```mdx
## See also

- [Related Concept](/v4-0-0-snapshot/core-concepts/related/) — one-line hook
- [Related How-to](/v4-0-0-snapshot/basics/related/) — one-line hook
```

### Closing section (how-to pages)

How-to pages end with a **"Related guides"** CardGrid:

```mdx
## Related guides

<CardGrid>
  <LinkCard title="X" href="/v4-0-0-snapshot/..." description="Y" />
  <LinkCard title="X" href="/v4-0-0-snapshot/..." description="Y" />
</CardGrid>
```

### Code block tagging rules (from STYLE.md)

- **Illustrative** (can't or shouldn't compile): `title="path/to/file.cfm"` or `title="illustrative — do not type"`. No `{test:*}` tag.
- **CFML that should parse**: `{test:compile}`. Verify bracket balance — fallback mode checks this.
- **CLI commands that should run**: `{test:cli cmd="wheels --version" asserts-stdout="Wheels"}`. Only use `wheels --version` as the test target unless you've personally verified another command works reliably in isolation against the installed CLI.
- **HTML fragments**: `title="path/to/view.cfm"` (illustrative, not compile-tagged).
- **Output blocks** (showing what a command prints): `title="expected output"` or just no meta.

### Voice + prose rules

- Second person ("you"), active voice
- No marketing copy ("powerful", "robust", "effortless")
- No headings deeper than `###`
- Short sentences
- Function names in code voice (`findAll()`), concepts in prose voice ("finders")
- Real names (`Post`, `user.email`), not `foo`/`bar`

### Verification template (every page)

After writing a page, these three steps always run:

```bash
export JAVA_HOME=/opt/homebrew/Cellar/openjdk@21/21.0.8/libexec/openjdk.jdk/Contents/Home
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/lucid-thompson-b8c121/web/sites/guides
pnpm verify:docs src/content/docs/v4-0-0-snapshot/<section>/<page>.mdx
pnpm build 2>&1 | tail -5
```

Expected: verify:docs all-pass; build page count increases by 1 over the previous state.

### Sidebar update pattern

Each new page gets added to `web/sites/guides/src/sidebars/v4-0-0-snapshot.json` inside the section's `items` array. Order is specified per-page in the task brief.

### `.ai/` deletion pattern

For each task that owns a `.ai/` deletion per the File Structure table:

1. **Before writing the user doc**: read the corresponding `.ai/` files to understand their content. Capture anything genuinely user-useful into the user doc outline.
2. **Before committing the user doc**: verify the user doc covers the user-facing material from `.ai/`. Anything that's agent-operational (cross-engine gotchas, runbooks, Claude-implementation-specific context) gets moved to CLAUDE.md or flagged for Task 22 to place in `agent-context/`.
3. **In the same commit**: `git rm -r .ai/wheels/<subdir>/` (or the specific files). The user doc and the `.ai/` deletion ship together.

### Commit messages

`docs(docs): <section>/<page> — <imperative phrase>`

Examples:
- `docs(docs): core-concepts/request-lifecycle — rewrite from phase 0 stub`
- `docs(docs): basics/associations — add full associations how-to + drop .ai/database/associations`
- `docs(docs): testing/index — landing page for testing section`

Scope is `docs`. Subject starts lowercase. Footer references the issue/plan if useful.

---

## Task 1: Request Lifecycle (Core Concept)

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/core-concepts/request-lifecycle.mdx` (rewrite existing Phase 0 stub).

**Type:** `concept`. **Sidebar order:** 1 within Core Concepts.

**`.ai/` to delete:** None this task.

**Page specification:**

Frontmatter:
```yaml
---
title: The Request Lifecycle
description: How an HTTP request flows through a Wheels app — from the JVM socket to the rendered response.
type: concept
sidebar:
  order: 1
---
```

Required sections:

1. **Opening** — one-sentence summary. "You'll learn" block: the four request phases, what each phase can do, where your code hooks in. `<Aside type="note">` noting this is conceptual — the [Controllers and Actions](/v4-0-0-snapshot/basics/controllers-and-actions/) page has the hands-on version.

2. **The four phases** — a section per phase:
    - **Phase 1: The JVM receives the request.** Lucee's servlet container accepts the TCP connection, parses the HTTP request into a `request` struct. The `onRequestStart()` event fires.
    - **Phase 2: The middleware pipeline.** Each registered middleware inspects/mutates the request struct and can short-circuit the response. Order matters. Wheels' built-in middleware (CSRF, security headers, rate limiter) runs first unless re-ordered.
    - **Phase 3: Routing and dispatch.** The router matches the URL against `config/routes.cfm`. A match selects a controller + action + route params. Route model binding (when enabled) loads `params.<singular>` from the DB. Filters fire: `before` filters (including `authenticate`), then the action, then `after` filters.
    - **Phase 4: View rendering and response.** The action sets instance variables, Wheels looks up the matching view under `app/views/<controller>/<action>.cfm`, renders it through the layout, serializes to HTTP, and writes to the socket.

3. **Visual diagram** — ASCII or Mermaid. Keep it simple:
    ```
    HTTP request
        ↓
    Middleware → [CSRF] → [Headers] → [Rate limit] → [Custom] 
        ↓
    Router → match route → set params
        ↓
    beforeAction filters → authenticate → ownership checks
        ↓
    Controller action
        ↓
    afterAction filters
        ↓
    View render (action view → layout)
        ↓
    HTTP response
    ```

4. **Where your code hooks in** — short prose listing the hook points:
    - `config/app.cfm` — once per process init
    - `config/routes.cfm` — route definitions, ran at init + reload
    - `config/settings.cfm` — the `set(...)` calls for middleware + defaults
    - `config/services.cfm` — DI container registration
    - `app/events/onRequestStart.cfm`, `onRequestEnd.cfm` — per-request hooks
    - `config/environment.cfm` — environment-specific overrides
    - Controller `config()` — filter declarations
    - Private filter methods — per-request logic before actions

5. **When something breaks** — three common symptoms and where in the pipeline they originate:
    - 500 with "route not found" → router, Phase 3
    - 422 with inline validation errors → Phase 4, view rendered the partial instead of redirecting
    - Blank page → Phase 4, view file missing or named wrong

6. **See also** block:
    - How Routing Works
    - Middleware Pipeline
    - Controllers and Actions
    - The Dependency Injection Container

Constraints:
- No CFML code blocks on this page. It's pure explanation.
- Diagram must be accurate — trace it against the real dispatch code in `vendor/wheels/Dispatch.cfc` before writing.
- Length: ~200-300 lines of MDX.

- [ ] **Step 1: Read the existing stub and the real dispatch code**

```bash
cat web/sites/guides/src/content/docs/v4-0-0-snapshot/core-concepts/request-lifecycle.mdx
head -100 vendor/wheels/Dispatch.cfc
```

- [ ] **Step 2: Rewrite the page per the specification above**

Write the full MDX content.

- [ ] **Step 3: Verify**

```bash
export JAVA_HOME=/opt/homebrew/Cellar/openjdk@21/21.0.8/libexec/openjdk.jdk/Contents/Home
cd web/sites/guides
pnpm verify:docs src/content/docs/v4-0-0-snapshot/core-concepts/request-lifecycle.mdx
pnpm build 2>&1 | tail -5
```

Expected: verify:docs reports "0 passed, 0 failed" (no harness blocks on a pure concept page); build produces 272+ pages.

- [ ] **Step 4: Self-review against STYLE.md**

Particular focus: no marketing copy, diagram is accurate, every "See also" link resolves to an existing or Phase 2a-scoped page.

- [ ] **Step 5: Commit**

```bash
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/core-concepts/request-lifecycle.mdx
git commit -m "docs(docs): core-concepts/request-lifecycle — rewrite from phase 0 stub"
```

---

## Task 2: MVC in Wheels (Core Concept)

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/core-concepts/mvc-in-wheels.mdx`.

**Type:** `concept`. **Sidebar order:** 2 within Core Concepts.

**`.ai/` to delete:** `.ai/wheels/core-concepts/mvc-architecture/` (entire subdir).

**Page specification:**

Frontmatter (title "MVC in Wheels", description "How Wheels interprets Model-View-Controller — where behavior lives, what controllers should never do, and why Wheels models are fat on purpose.", sidebar.order 2).

Required sections:
1. Opening + "You'll learn" (the MVC boundary lines, what each layer owns, common violations).
2. **The three layers** — one subsection per layer:
   - **Model** — domain logic, validations, callbacks, database access, business rules. ActiveRecord-style: the model knows how to load, save, and validate itself. Fat-model-thin-controller is the Wheels default, deliberately.
   - **View** — presentation only. `.cfm` templates with inline `#expr#` interpolation + helper calls. No DB access. No business logic. If a view needs computed data, the controller computes it.
   - **Controller** — request handling. Parses params, loads models, orchestrates, picks a view. Minimal logic — ideally just redirect-or-render decisions. Controllers are thin.
3. **What Wheels conventions enforce** — the naming that glues the layers together:
   - Plural controllers: `Posts.cfc` for posts
   - Singular models: `Post.cfc`
   - Snake-case-ish table: `posts`
   - View path: `app/views/posts/<action>.cfm`
   - When you follow the conventions, the framework wires everything by default. When you break them (different table, custom view path), you explicitly override.
4. **Common violations** — short, prose-only list:
   - DB calls in a view → move to the controller action, pass down as a variable
   - Validation logic in a controller → lift into the model's `validatesPresenceOf` or a custom validation
   - Business calculations in a controller with 5 `findAll` calls → extract a service object into `app/lib/`
   - Rendering decisions (`if (params.json) { ... }`) everywhere → use respond_to / format detection and partials
5. **Why fat models** — 2-paragraph explanation. Models are shared across controllers, background jobs, seeds, tests. A validation on the model means every caller enforces it. A validation in a controller means every other caller reimplements it (or doesn't).
6. See also block.

Constraints: no code blocks. Pure explanation.

**Deletion scope for Task 2:** read `.ai/wheels/core-concepts/mvc-architecture/` to ensure no user-facing gap, then `git rm -r .ai/wheels/core-concepts/mvc-architecture/` in the same commit as the user page.

- [ ] **Step 1: Read source material**

```bash
ls .ai/wheels/core-concepts/mvc-architecture/
cat .ai/wheels/core-concepts/mvc-architecture/*.md | head -200
```

Capture anything user-facing. Agent-specific content gets moved to CLAUDE.md (flag for Task 22 if non-trivial).

- [ ] **Step 2: Write the user doc per specification**

- [ ] **Step 3: Verify**

```bash
cd web/sites/guides
pnpm verify:docs src/content/docs/v4-0-0-snapshot/core-concepts/mvc-in-wheels.mdx
pnpm build 2>&1 | tail -5
```

- [ ] **Step 4: Delete the `.ai/` subdir**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/lucid-thompson-b8c121
git rm -r .ai/wheels/core-concepts/mvc-architecture/
```

- [ ] **Step 5: Commit both together**

```bash
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/core-concepts/mvc-in-wheels.mdx
git commit -m "docs(docs): core-concepts/mvc-in-wheels — add user doc + drop .ai mvc-architecture"
```

---

## Task 3: Conventions over Configuration (Core Concept)

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/core-concepts/conventions-over-configuration.mdx`.

**Type:** `concept`. **Sidebar order:** 3.

**`.ai/` to delete:** None (this is a philosophy page with no direct `.ai/` equivalent).

**Page specification:**

Required sections:
1. Opening + "You'll learn" (what "convention over configuration" means concretely, which conventions Wheels enforces, when and how to override).
2. **What the convention buys you** — a table of what happens automatically when you name things the Wheels way:

| You create | Wheels infers |
|------------|---------------|
| `app/models/Post.cfc` | Model class `Post`, table `posts`, primary key `id`, datasource = app default |
| `app/controllers/Posts.cfc` | Controller `Posts`, view dir `app/views/posts/`, routes via `.resources("posts")` |
| Action `index` on `Posts` | View path `app/views/posts/index.cfm`, renders through `app/views/layout.cfm` |
| `config/routes.cfm` with `.resources("posts")` | Seven routes (`posts`/`newPost`/`post`/`editPost` named), CRUD mapping |
| `hasMany(name="comments")` on `Post` | Foreign key `postId` on `comments`, methods `post.comments()` and `post.createComment()` |

3. **How to override when you need to** — short list of the common overrides:
   - Custom table: `tableName("old_blog_entries")` in model `config()`
   - Custom primary key: `setPrimaryKey("entryId")`
   - Custom view: `renderView(action="summary")`
   - Custom route mapping: `.get(pattern="/old/:key", to="posts##show")`
4. **When conventions fight you** — 2 paragraphs. Legacy databases, multi-tenancy, pluralization edge cases (`person`/`people`, `datum`/`data`). Name it, address it, move on.
5. **Why this philosophy** — 2 paragraphs. Conventions reduce the decision surface. New developers onboarding to a Wheels app know where things live. Tooling (generators, scaffolds, the CLI) can assume the conventions hold. You pay an override cost when you break convention, not a discoverability cost for every file.
6. See also block.

Constraints: prose-only, no code blocks except the small inline examples in section 3.

- [ ] **Step 1: Write per specification**
- [ ] **Step 2: Verify + build**
- [ ] **Step 3: Commit**

```bash
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/core-concepts/conventions-over-configuration.mdx
git commit -m "docs(docs): core-concepts/conventions-over-configuration — add philosophy page"
```

---

## Task 4: ORM Philosophy (Core Concept)

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/core-concepts/orm-philosophy.mdx`.

**Type:** `concept`. **Sidebar order:** 4.

**`.ai/` to delete:** `.ai/wheels/core-concepts/orm/` (subtree). Also audit `.ai/wheels/core-concepts/rails-comparison.md` — if there's useful Rails-specific content, either merge into Why Wheels? (via a separate commit to that existing page) or delete.

**Page specification:**

Required sections:
1. Opening + "You'll learn" (what ActiveRecord vs DataMapper is, Wheels' position, what that means for you).
2. **ActiveRecord vs DataMapper** — 2 paragraphs contrasting the patterns. ActiveRecord: the model IS a row. Load a User, call `user.save()`, the row updates. DataMapper: models are dumb data, repositories handle persistence. Wheels is ActiveRecord, like Rails and Laravel Eloquent. Django ORM sits closer to DataMapper.
3. **What this means for your code** — short list:
   - Models carry behavior. A `User` has `authenticate()`, not an `AuthService.authenticate(user)`.
   - Validations live on the model. `user.valid()` and `user.errors()` return state.
   - Lifecycle callbacks (`beforeSave`, `afterCreate`) are methods on the model.
   - Persistence is per-instance. `user.save()`, `user.delete()`, `user.update(...)`.
4. **What this DOESN'T mean** — common confusions:
   - Models don't have to do everything. Complex workflows live in `app/lib/` service objects.
   - Models don't have to hit the database every time. Use finders with caching, scopes, `include=` for eager loading.
   - Models aren't the only domain objects. Plain CFCs in `app/lib/` are fine for value objects, calculators, etc.
5. **The "fat model" mental pitfall** — 1 paragraph. When a model accrues 2000 lines, the temptation is "rewrite as DataMapper." The reality: you need a service object. Keep the model; extract the service.
6. See also (Models and the ORM, Associations, Validation and Errors).

Constraints: prose + one tiny illustrative model snippet showing behavior on the class. No compile blocks.

- [ ] **Step 1: Read source material**

```bash
ls .ai/wheels/core-concepts/orm/
cat .ai/wheels/core-concepts/orm/*.md | head -300
cat .ai/wheels/core-concepts/rails-comparison.md | head -100
```

- [ ] **Step 2: Write the user doc**
- [ ] **Step 3: Verify + build**
- [ ] **Step 4: Delete `.ai/`**

```bash
git rm -r .ai/wheels/core-concepts/orm/
# Audit rails-comparison.md — if useful, defer to a small commit that merges into why-wheels.mdx; otherwise delete
cat .ai/wheels/core-concepts/rails-comparison.md
# If merge: edit web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/why-wheels.mdx and commit separately
# If delete:
git rm .ai/wheels/core-concepts/rails-comparison.md
```

- [ ] **Step 5: Commit**

```bash
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/core-concepts/orm-philosophy.mdx
git commit -m "docs(docs): core-concepts/orm-philosophy — add ORM mental model + drop .ai orm subtree"
```

---

## Task 5: The Dependency Injection Container (Core Concept)

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/core-concepts/dependency-injection.mdx`.

**Type:** `concept`. **Sidebar order:** 5.

**`.ai/` to delete:** `.ai/wheels/configuration/dependency-injection.md` (single file).

**Page specification:**

Required sections:
1. Opening + "You'll learn" (what the container is, when to use it, the three scopes, how injection works).
2. **What the container does** — 2 paragraphs. The container holds named references to components. Code asks for a name, gets an instance. Enables swapping implementations (test doubles, strategy patterns, environment-specific configs) without rewriting consumers.
3. **Registration** — where it happens (`config/services.cfm`), the shape:
   ```cfm title="illustrative — config/services.cfm"
   var di = injector();
   di.map("emailService").to("app.lib.EmailService").asSingleton();
   di.map("currentUser").to("app.lib.CurrentUserResolver").asRequestScoped();
   di.bind("INotifier").to("app.lib.SlackNotifier").asSingleton();
   ```
4. **The three scopes** — table:
   | Scope | Lifetime | Use when |
   |-------|----------|----------|
   | `transient` (default) | New instance each resolve | Components with no shared state |
   | `.asSingleton()` | One per application | Stateless services, expensive-to-construct objects |
   | `.asRequestScoped()` | One per HTTP request | Per-request state (current user, request-tenant) |
5. **Resolving** — two patterns:
   - Lazy: `service("emailService")` anywhere in your code
   - Declarative injection in controllers: `inject("emailService")` in `config()`, use as `this.emailService` in actions
6. **Auto-wiring** — short paragraph. `init()` params matching registered names are auto-resolved when no `initArguments` is passed. Constructor injection for the common case.
7. **When NOT to use the container** — 1 paragraph. Don't inject everything. Plain `new app.lib.Foo()` is fine for stateless things you never swap. The container earns its keep when you WILL swap or WHEN test doubles matter.
8. See also (Middleware Pipeline, Controllers and Actions, Authentication Patterns).

Constraints: 1-2 illustrative code snippets (marked with title, not compile). No harness blocks on a concept page.

- [ ] **Step 1: Read .ai source**
- [ ] **Step 2: Write**
- [ ] **Step 3: Verify + build**
- [ ] **Step 4: Delete `.ai/wheels/configuration/dependency-injection.md`**
- [ ] **Step 5: Commit**

```bash
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/core-concepts/dependency-injection.mdx .ai/wheels/configuration/dependency-injection.md
git commit -m "docs(docs): core-concepts/dependency-injection — add DI concept + drop .ai dependency-injection"
```

---

## Task 6: Middleware Pipeline (Core Concept)

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/core-concepts/middleware-pipeline.mdx`.

**Type:** `concept`. **Sidebar order:** 6.

**`.ai/` to delete:** Review `.ai/wheels/middleware/` (likely subdir). Delete whatever's user-facing; promote agent-specific pieces if any.

**Page specification:**

Required sections:
1. Opening + "You'll learn" (what middleware is, where it runs, how ordering works, the built-ins).
2. **The pipeline model** — 2 paragraphs. Middleware is a chain of `(request, next)` functions. Each one inspects the request, optionally calls `next(request)` to continue, optionally mutates the response on the way back. Order = chain order.
3. **Where middleware registers** — `config/settings.cfm`:
   ```cfm title="illustrative — config/settings.cfm"
   set(middleware = [
       new wheels.middleware.RequestId(),
       new wheels.middleware.SecurityHeaders(),
       new wheels.middleware.Cors(allowOrigins="https://myapp.com"),
       new wheels.middleware.RateLimiter(maxRequests=100, windowSeconds=60)
   ]);
   ```
4. **Built-in middleware** — short prose list:
   - `RequestId` — adds a unique ID to each request; threaded into logs
   - `SecurityHeaders` — sets CSP, HSTS, X-Frame-Options
   - `Cors` — handles OPTIONS preflight + sets CORS headers
   - `RateLimiter` — multi-strategy (fixed/sliding/token-bucket)
5. **Route-scoped middleware** — short example of `.scope(path="/api", middleware=[...])`. Middleware can apply globally or to a route subtree.
6. **Writing your own** — 1 paragraph. Implement `wheels.middleware.MiddlewareInterface`, place in `app/middleware/`. See [Rate Limiting](/v4-0-0-snapshot/digging-deeper/) and [CORS](/v4-0-0-snapshot/digging-deeper/) in Digging Deeper for the how-to.
7. See also (Request Lifecycle, How Routing Works, CORS, Rate Limiting).

Constraints: illustrative snippets only; no harness blocks.

Steps follow the same pattern: read .ai, write, verify, delete .ai, commit.

```bash
# After writing user doc and verifying:
git rm -r .ai/wheels/middleware/  # adjust based on what's actually there
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/core-concepts/middleware-pipeline.mdx
git commit -m "docs(docs): core-concepts/middleware-pipeline — add concept + drop .ai middleware"
```

---

## Task 7: How Routing Works (Core Concept)

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/core-concepts/how-routing-works.mdx`.

**Type:** `concept`. **Sidebar order:** 7.

**`.ai/` to delete:** `.ai/wheels/core-concepts/routing/`.

**Page specification:**

Required sections:
1. Opening + "You'll learn" (how URL → action mapping happens, what resources generate, route model binding mechanics, the order rules).
2. **The match algorithm** — 2 paragraphs. The router walks `config/routes.cfm` top-to-bottom. First match wins. Resource routes expand to 7 routes at definition time. The wildcard route catches anything that falls through, mapping `/controller/action` conventionally.
3. **What `.resources("posts")` expands to** — concrete table showing 7 generated routes:

| HTTP method | Path | Controller#action | Named route |
|-------------|------|-------------------|-------------|
| GET | `/posts` | `posts##index` | `posts` |
| GET | `/posts/new` | `posts##new` | `newPost` |
| POST | `/posts` | `posts##create` | n/a (same path as index) |
| GET | `/posts/:key` | `posts##show` | `post` |
| GET | `/posts/:key/edit` | `posts##edit` | `editPost` |
| PATCH / PUT | `/posts/:key` | `posts##update` | n/a |
| DELETE | `/posts/:key` | `posts##delete` | n/a |

4. **Order rules** — short list:
   - Specific routes before generic
   - `.resources(...)` before `.wildcard()` before `.root(...)`
   - Named routes can be ordered however is clearest — name, not position, is the lookup key
5. **Route model binding** — 2 paragraphs. When `.resources(name="posts", binding=true)` is set, any action receiving a `:key` has `params.<singular>` pre-populated with the matching record. A 404 is raised before the action runs if the record doesn't exist. Without `binding=true`, `params.post` is undefined — the dev-mode warning (shipped in the gap-fix batch) flags this at dispatch time when the action is a binding-eligible one.
6. **Named routes everywhere** — short paragraph. `linkTo(route="post", key=post.id)`, `redirectTo(route="posts")`, `urlFor(route="newPost")` all use the same names.
7. See also (Routing how-to, Controllers and Actions, Middleware Pipeline).

Constraints: prose + the one table + 2-3 illustrative snippets.

Steps same as Task 6.

---

## Task 8: Environments and Configuration (Core Concept)

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/core-concepts/environments-and-configuration.mdx`.

**Type:** `concept`. **Sidebar order:** 8.

**`.ai/` to delete:** `.ai/wheels/configuration/{application,environments,framework-settings,overview,best-practices,troubleshooting}.md` (six files).

**Page specification:**

Required sections:
1. Opening + "You'll learn" (the 3 standard environments, where settings live, how environment-specific overrides work, the `set()` pattern).
2. **The three environments** — quick table:

| Environment | When it's used | Typical settings |
|-------------|----------------|------------------|
| `development` | Local dev server | Verbose errors, hot reload, debug helpers visible |
| `testing` | Test suite runs | Same DB reset before each spec, faster timeouts |
| `production` | Real users | Errors hidden, caches warmed, log rotation, HTTPS enforced |

3. **Where settings live** — one sentence per file:
   - `config/settings.cfm` — shared defaults, middleware list
   - `config/environment.cfm` — the active environment name, usually read from `LUCLI_ENV` or similar
   - `config/environments/development.cfm`, `testing.cfm`, `production.cfm` — per-env overrides
   - `config/app.cfm` — init-time hooks
4. **The `set()` pattern** — 2 paragraphs. `set(key=value)` writes into the Wheels settings struct. Settings cascade: default → settings.cfm → environments/<env>.cfm. Later writes win.
5. **Environment detection** — 1 paragraph. The active environment is set by `config/environment.cfm` (file), optionally overridden by `LUCLI_ENV` / `WHEELS_ENV` env var. The CLI respects this.
6. **Secrets handling** — short paragraph. Use environment variables or a secrets manager (1Password Connect, AWS Secrets Manager, etc.); reference via `application.wo.env("VAR_NAME")` in CFML. Don't commit `.env` or equivalent — the scaffold ships a `.gitignore` that excludes them.
7. See also (The Dependency Injection Container, Deployment Overview, Installing Wheels).

Constraints: prose + the table + inline set() examples.

Steps same as Task 6 but with 6 files to delete.

---

## Task 9: Routing (The Basics — How-to)

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/basics/routing.mdx`.

**Type:** `howto`. **Sidebar order:** 1 within The Basics.

**`.ai/` to delete:** `.ai/wheels/configuration/routing.md`.

**Page specification (abbreviated — detailed task briefs start here):**

Required sections:
1. Opening + "You'll learn" (defining routes, resources, nested resources, namespaced, custom constraints, named routes).
2. Prerequisites aside — "You should already know what a route is from [How Routing Works](/v4-0-0-snapshot/core-concepts/how-routing-works/)."
3. **Define a simple route** — `{test:compile}` block showing `mapper().get(name="hello", pattern="/hello", to="main##hello").end();` — with the full `<cfscript>` wrapper.
4. **Resources** — `{test:compile}` block with `resources("posts", binding=true)`.
5. **Nested resources** — callback syntax per Phase 1 tutorial pattern.
6. **Namespaced routes** — `scope(path="/admin")` example.
7. **Custom constraints** — regex patterns on the pattern.
8. **Route helpers** — `linkTo`, `urlFor`, `redirectTo`, `buttonTo` — short prose reference.
9. **Listing all routes** — `wheels routes` command, shown with `{test:cli cmd="wheels --version" asserts-stdout="Wheels"}` smoke test only (not the routes command itself since it depends on a running app).
10. Related guides CardGrid (Controllers and Actions, How Routing Works, Middleware Pipeline).

Constraints: every routes.cfm block wrapped in `<cfscript>`. Bracket balance matters for fallback compile mode.

Steps:
- [ ] Read `.ai/wheels/configuration/routing.md` for source material
- [ ] Write per specification
- [ ] Verify: `pnpm verify:docs src/content/docs/v4-0-0-snapshot/basics/routing.mdx`
- [ ] Build
- [ ] `git rm .ai/wheels/configuration/routing.md`
- [ ] Commit

---

## Task 10: Controllers and Actions (The Basics — How-to)

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/basics/controllers-and-actions.mdx`. Order 2.

**`.ai/` to delete:** `.ai/wheels/controllers/{architecture,filters,filters/*,model-interactions,rendering,rendering/*,params,params/*,http-detection,security}.md` + subdirs. Exceptions: `.ai/wheels/controllers/api.md` defers to Phase 2b's Digging Deeper → API Controllers page.

**Page specification:** writing a controller + 7 REST actions, filters (config() declaration, `filters(through=..., except=...)`, private filter methods), `params` struct, rendering (`renderView`, `renderPartial`, `renderText`, `renderJSON`), redirect (`redirectTo`), flash messages, strong params patterns.

Same task structure as Task 9: read .ai, write, verify, build, delete, commit.

---

## Task 11: Views, Layouts, Partials (The Basics — How-to)

**Page:** `basics/views-layouts-partials.mdx`. Order 3.

**`.ai/` to delete:** `.ai/wheels/views/{architecture,layouts,layouts/*,partials,data-handling,best-practices,advanced-patterns}.md`.

**Page specification:** view file structure, layout.cfm, content blocks (`contentFor`, `yieldContent`), partials (`includePartial`, `renderPartial`), passing data to partials, the `_form.cfm` convention, escaping (the `h()` helper, auto-escaping in 4.0).

Same task structure.

---

## Task 12: Forms and Form Helpers (The Basics — How-to)

**Page:** `basics/forms-and-form-helpers.mdx`. Order 4.

**`.ai/` to delete:** `.ai/wheels/views/forms.md`, `.ai/wheels/views/helpers.md`, `.ai/wheels/views/helpers/`.

**Page specification:** `startFormTag` / `endFormTag`, object-bound helpers (textField / textArea / select / checkBox / radioButton / dateField / timeField / fileField), tag-style helpers, the `data-auto-id` attribute (new in 4.0, shipped in gap-batch #7), HTML5 input types, errorMessagesFor, label helpers, form submission with Turbo Frames (pointer back to tutorial Part 4).

The `data-auto-id` section references the feature shipped in `7fc905a79` — explain the dual emission (`id="post-title"` + `data-auto-id="post_title"`).

Same task structure.

---

## Task 13: Validation and Error Display (The Basics — How-to)

**Page:** `basics/validation-and-errors.mdx`. Order 5.

**`.ai/` to delete:** `.ai/wheels/database/validations/`.

**Page specification:** built-in validations (`validatesPresenceOf`, `validatesLengthOf`, `validatesFormatOf`, `validatesUniquenessOf`, `validatesInclusionOf`, `validatesNumericalityOf`), when validations fire (`save`, `update`), the errors API (`errors()`, `errorsOn()`, `hasErrors()`), inline rendering (`errorMessagesFor`), custom validations (`validate="myCustomMethod"`), conditional validations (`if="..."`).

Same task structure.

---

## Task 14: Models and the ORM (The Basics — How-to)

**Page:** `basics/models-and-the-orm.mdx`. Order 6.

**`.ai/` to delete:** `.ai/wheels/models/{architecture,methods-reference,callbacks,performance,best-practices,advanced-features,advanced-patterns}.md`. Leave `associations.md`, `query-builder.md`, `scopes.md`, `enums.md`, `batch-processing.md`, `testing.md`, `user-authentication.md`, `shared-models.md` for their respective pages.

**Page specification:** defining a model (`extends="Model"`, `config()`), finders (`findAll`, `findOne`, `findByKey`, `exists`), persistence (`new`, `create`, `save`, `update`, `delete`), callbacks (`beforeSave`, `afterCreate`, `beforeValidation`, list of all lifecycle hooks with a table), custom methods on the model, model reloading after save.

Same task structure.

---

## Task 15: Associations (The Basics — How-to)

**Page:** `basics/associations.mdx`. Order 7.

**`.ai/` to delete:** `.ai/wheels/models/associations.md`, `.ai/wheels/database/associations/` (subtree).

**Page specification:** `hasMany`, `belongsTo`, `hasOne`, the `through:` option for many-through-many, `dependent="delete"`, eager loading with `include=`, polymorphic, counter caches, the generated association methods (`post.createComment(...)`, `post.comments()`), N+1 query avoidance.

Same task structure.

---

## Task 16: Migrations (The Basics — How-to)

**Page:** `basics/migrations.mdx`. Order 8.

**`.ai/` to delete:** `.ai/wheels/database/migrations/` (subtree).

**Page specification:** running (`wheels migrate latest`, `up`, `down`, `info`), writing (extend `wheels.migrator.Migration`, `up()` and `down()`, the transaction+try/catch pattern), column types table (string, text, integer, float, decimal, boolean, datetime, date, time, binary), `t.timestamps()`, indexes, foreign keys, adding/removing/renaming columns, the generated migration filename format.

Same task structure.

---

## Task 17: Seeding (The Basics — How-to)

**Page:** `basics/seeding.mdx`. Order 9.

**`.ai/` to delete:** `.ai/wheels/database/seeding.md`.

**Page specification:** `app/db/seeds.cfm` convention, `seedOnce(modelName, uniqueProperties, properties)` shape, environment-specific seeds (`app/db/seeds/development.cfm`, `production.cfm`), running (`wheels seed`), when seeds are idempotent (always — `seedOnce` checks `uniqueProperties` first), test data via generator (`wheels seed --generate`), when to prefer factories instead.

Same task structure.

---

## Task 18: Query Builder and Scopes (The Basics — How-to)

**Page:** `basics/query-builder-and-scopes.mdx`. Order 10.

**`.ai/` to delete:** `.ai/wheels/models/{query-builder,scopes,enums,batch-processing}.md` (four files).

**Page specification:** the chainable query builder (`where`, `orWhere`, `whereNull`, `whereBetween`, `whereIn`, `orderBy`, `limit`, `offset`, `get`), SQL injection safety of the builder, scopes (`scope(name="published", where="...")`), dynamic scopes (`scope(name="byRole", handler="scopeByRole")` + handler function), enum scopes (auto-generated per enum value), composing scopes, batch processing (`findEach`, `findInBatches`).

Same task structure.

---

## Task 19: Database and Multiple Datasources (The Basics — How-to)

**Page:** `basics/database-and-multiple-datasources.mdx`. Order 11.

**`.ai/` to delete:** `.ai/wheels/database/queries/` (subtree).

**Page specification:** configuring the default datasource in `config/settings.cfm`, adding additional datasources in `config/app.cfm` (or the DataSource registry), per-model datasource (`dataSource("legacy_db")` in config()), read replicas, transactions (`transaction{}` block), raw queries via `$query()` (with escaping warnings), connection pooling briefly.

Same task structure.

---

## Task 20: Sidebar + tutorial cross-link pass

**Files to modify:**
- `web/sites/guides/src/sidebars/v4-0-0-snapshot.json`
- `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/*.mdx` (all 8 files — add back-references to newly-available Core Concepts and Basics pages in their "See also" / "Related guides" sections)

**Purpose:** The tutorial parts wrote "See also" / "Related guides" links pointing at pages that didn't exist yet (Phase 1 known gap). Now they exist. Audit each tutorial part for stale links or missing cross-references to Phase 2a pages.

**Sidebar changes:** every new page from Tasks 1-19 gets an entry. Final sidebar has full Core Concepts and The Basics sections populated.

Steps:
- [ ] Walk each tutorial part, identify any `/v4-0-0-snapshot/core-concepts/` or `/v4-0-0-snapshot/basics/` link that now resolves to a new page
- [ ] Add 1-2 "Related guides" links on Part 7 pointing at the new Basics pages (query builder, forms, associations) readers might want next
- [ ] Run `pnpm build` — confirm no broken internal links (Starlight surfaces them)
- [ ] Commit

```bash
git add web/sites/guides/src/sidebars/v4-0-0-snapshot.json web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/
git commit -m "docs(docs): cross-link tutorial parts to phase 2a concept and basics pages"
```

---

## Task 21: Testing Overview (Landing)

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/testing/index.mdx`.

**Type:** `concept` (it's an overview/landing, not a how-to). **Sidebar order:** 1 within Testing.

**`.ai/` to delete:** `.ai/wheels/testing/README.md` if applicable. Don't touch subdirs — the detailed testing pages land in Phase 2b.

**Page specification:**

Required sections:
1. Opening + "You'll learn" (what test categories Wheels ships, the BDD runner, the reference platform, where to go for each category).
2. **Categories** — table:

| Category | Runner | File location | Typical scope |
|----------|--------|---------------|---------------|
| Model tests | WheelsTest | `tests/specs/models/` | One model, validations, callbacks, custom methods |
| Controller tests | WheelsTest | `tests/specs/controllers/` | Action dispatch, `processRequest`, response assertions |
| Functional tests | WheelsTest | `tests/specs/functional/` | Cross-controller workflows |
| Browser tests | Playwright via BrowserTest | `tests/specs/browser/` | Full UI flows, click-through |

3. **WheelsTest BDD shape** — 1 paragraph + small illustrative snippet showing `describe`/`it`/`expect`.
4. **The reference platform** — Lucee 7 + SQLite, matching the CI setup. Cross-engine nuances (Adobe, other databases) surface as asides in the detailed pages.
5. **Running tests** — `wheels test run`, `wheels test run --filter=browser`, the test runner URL pattern.
6. **CI integration** — pointer to the existing `.github/workflows/` setup; Phase 2b's "CI Integration" page has the details.
7. **Where to go next** — CardGrid with 4 cards: Model Tests (Phase 2b), Controller Tests (2b), Browser Tests (2b), Running Tests Locally (2b) — cards will be slightly ahead of the pages they link to; that's fine (tutorial Part 7 already links forward, too).

Constraints: one illustrative snippet, no harness blocks.

Steps same pattern.

---

## Task 22: `.ai/` final audit for Phase 2a

**Files to audit and potentially relocate:**
- `.ai/wheels/core-concepts/README.md` — if it's a TOC, delete. If it has substance, merge into Core Concepts landing (need to check if Core Concepts has a landing — probably a Starlight-generated section index).
- `.ai/wheels/models/testing.md` — belongs with testing, defer to Phase 2b's model-tests page.
- `.ai/wheels/models/user-authentication.md` — belongs with Authentication, defer to Phase 2b's Digging Deeper → Auth.
- `.ai/wheels/models/shared-models.md` — evaluate; likely either Phase 2b (Multi-tenancy in Digging Deeper) or delete.
- Any stragglers from Tasks 1-21 that weren't cleanly deleted.

**Output:**
- List in plan what was relocated, what was deleted, what defers to Phase 2b.
- Commit the results.

Steps:
- [ ] List all remaining `.ai/wheels/` files
- [ ] Classify each as: keep for later phase / relocate to CLAUDE.md or agent-context/ / delete
- [ ] Execute the deletions and relocations
- [ ] Commit

```bash
git add .ai CLAUDE.md agent-context/
git commit -m "docs(docs): phase 2a .ai/ audit — consolidate stragglers into user docs or agent-context"
```

---

## Task 23: Full harness run + build + Phase 2a completion report

**Files:**
- Create: `docs/superpowers/plans/2026-04-20-guides-rewrite-phase-2a-report.md`

Steps:
- [ ] **Full harness run:**
  ```bash
  export JAVA_HOME=/opt/homebrew/Cellar/openjdk@21/21.0.8/libexec/openjdk.jdk/Contents/Home
  cd web/sites/guides
  pnpm verify:docs 2>&1 | tee /tmp/phase2a-harness.log
  ```
  Expected: all tagged blocks pass. Page count goes from Phase 1's 272 to ~292 (20 new pages).

- [ ] **Full unit test suite:**
  ```bash
  pnpm test:docs-harness
  ```

- [ ] **Full astro build:**
  ```bash
  pnpm build 2>&1 | tee /tmp/phase2a-build.log
  ```

- [ ] **Push branch:**
  ```bash
  git push
  ```

- [ ] **Write completion report following Phase 1 report template**, including:
  - Table of Phase 2a commits
  - Deliverables checklist
  - Verification section (harness pass count, test pass count, build page count)
  - What changed from the plan (deviations)
  - Known gaps / Phase 2b follow-ups
  - Open decisions before Phase 2b starts

- [ ] **Commit report**

---

## Task 24: Final code review across Phase 2a diff

Dispatch a pr-review-toolkit:code-reviewer subagent with:

- Full diff: `git diff <phase1-head>..HEAD` where `<phase1-head>` is `bba06cda5`
- Review focus: voice consistency across 20 pages, Diátaxis purity (every concept page is explanation, every how-to is task-oriented), internal link accuracy, `.ai/` deletions were complete (no orphan references), no marketing language, bracket-balanced code snippets, sidebar matches file tree.
- Known items to skip flagging: CFML tag-comment fallback gap, any item already in the P1 gap tracker.

Steps:
- [ ] Compute diff range
- [ ] Dispatch subagent with task-specific brief
- [ ] Address blocking issues inline
- [ ] File Phase 2b follow-ups for non-blockers

---

## Self-review

**Spec coverage check:**

| Spec requirement | Task(s) |
|------------------|---------|
| Core Concepts: Request Lifecycle | 1 |
| Core Concepts: MVC in Wheels | 2 |
| Core Concepts: Conventions over Configuration | 3 |
| Core Concepts: ORM Philosophy | 4 |
| Core Concepts: Dependency Injection | 5 |
| Core Concepts: Middleware Pipeline | 6 |
| Core Concepts: How Routing Works | 7 |
| Core Concepts: Environments and Configuration | 8 |
| Basics: Routing | 9 |
| Basics: Controllers & Actions | 10 |
| Basics: Views, Layouts, Partials | 11 |
| Basics: Forms & Form Helpers | 12 |
| Basics: Validation & Error Display | 13 |
| Basics: Models & ORM | 14 |
| Basics: Associations | 15 |
| Basics: Migrations | 16 |
| Basics: Seeding | 17 |
| Basics: Query Builder & Scopes | 18 |
| Basics: Database & Multiple Datasources | 19 |
| Testing Overview | 21 |
| `.ai/` consolidation (policy decision) | 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22 |
| Kamal commitment (policy decision — doesn't affect 2a directly; enforced in 2c) | — |
| Tutorial cross-link pass | 20 |

All Phase 2a spec requirements mapped. Kamal is for 2c. Testing detail pages (9 out of 10) deferred to 2b.

**Placeholder scan:**
- No "TBD" in the plan body.
- Content task briefs use structural outlines (required sections + required components) rather than verbatim prose. Same pragmatic pattern established in Phase 1 Tasks 3-13. Writing agent composes prose at execution time with STYLE.md + this outline + `.ai/` source material in hand.
- Commands in verification steps are exact.

**Type / method consistency:**
- `inject()` / `service()` / `injector().map(...).to(...).asSingleton()` referenced consistently across Tasks 5, 10, 14.
- Form helper naming (`textField`, `startFormTag`, `errorMessagesFor`) consistent across Tasks 12, 13.
- Finder naming (`findAll`, `findOne`, `findByKey`) consistent across Tasks 14, 15, 18.
- Route helpers (`linkTo`, `redirectTo`, `urlFor`, `buttonTo`) consistent across Tasks 9, 10, 11.
- `.resources(name="...", binding=true)` consistent with Phase 1 gap-fix #5.

**Known friction point (same as Phase 1):** content task briefs don't inline full prose. The implementing agent composes during execution against `.ai/` source + STYLE.md + existing page examples. This is deliberate — writing 20 full page drafts verbatim in the plan would 5x its length. If an executing agent needs more scaffolding before writing a given page, they should read the relevant `.ai/` files first (every task has a "read source material" step).

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-20-guides-rewrite-phase-2a.md`.

**Per Phase 1's proven pragmatic split:**
- **Content tasks (1-19, 21)** — inline execution. Compose each page against STYLE.md + `.ai/` source. Harness + build is the review gate.
- **Integration tasks (20, 22, 23)** — inline.
- **Final review (24)** — pr-review-toolkit:code-reviewer subagent across the full Phase 2a diff.

Two execution options per the writing-plans skill:

1. **Subagent-Driven (recommended for the bulk)** — dispatch one content-writer subagent per page, I review the result + harness output, commit. Roughly 20 dispatch cycles for the content pages. Preserves my context for coordination.

2. **Inline Execution** — I write each page myself in this session. Shorter latency per page, higher context consumption.

Given Phase 1 worked well with subagent dispatch for content tasks (Parts 2-7), option 1 is the natural fit. **Proceed with subagent-driven execution?**
