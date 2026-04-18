# Starlight Phase 3 — C-Depth Custom Layout Design

**Date:** 2026-04-18
**Status:** Draft, pending user review — no implementation yet
**Scope:** `web/sites/guides` and `web/sites/api` — the two Starlight-powered sites
**Depends on:** [PR #2153](https://github.com/wheels-dev/wheels/pull/2153) (Phase 2 shipped)
**Supersedes:** §8 of [`2026-04-17-wheels-dev-cohesion-design.md`](2026-04-17-wheels-dev-cohesion-design.md)

---

## Why a new spec

The original cohesion spec's §8 proposed six Starlight overrides as one bundle: `PageFrame`, `Sidebar`, `PageTitle`, `TableOfContents`, `VersionSwitcher`, `EditLink`. Investigating against Starlight 0.34.8 surfaced information that reshapes the proposal:

1. **EditLink is not useful for our setup.** Both Starlight sites serve *generated* content — api pages are emitted by `web/scripts/generate-api-docs.mjs` from `docs/api/v*.json`, and guides pages come from the `wheels.dev` sibling repo's GitBook source via `web/scripts/generate-guides.mjs`. A GitHub edit link on a generated file lands a user on a file whose edits will be overwritten on the next regen. Ship-ready only if we re-point edit links at the *source* (JSON/GitBook), which is out of scope for a CSS/component pass.
2. **VersionSwitcher is a net-new UI component with real routing logic.** It needs dropdown state management, slug-equivalence detection across versions, and a fallback routing decision when the slug doesn't exist in the target version. That's a judgment call best made with user input — especially around UX details (dropdown vs popover, keyboard behavior, mobile treatment).
3. **PageFrame override is disproportionately risky.** Starlight's `PageFrame` is the outer scaffold; overriding it means we own the skip-link + sidebar-placement + main-content plumbing that Starlight normally handles. Starlight 0.34.8 refactored its layout architecture significantly; pinning to a specific version is required to avoid breakage on upgrade.
4. **Cosmetic parity is already largely achieved** via the Phase 2 `starlight-theme.css` token bridge. The visible remaining gaps are more about component-specific polish than full-layout reconstruction.

This spec re-scopes Phase 3 into three value-ordered slices, defers the truly risky pieces, and calls out decisions needed from the user.

## Decisions (summary)

| Original §8 component | New plan |
|-----------------------|----------|
| `EditLink` | **Drop.** Edit-on-github for generated content has no clean target. Revisit only if we invest in re-pointing at source files. |
| `VersionSwitcher` | **Keep, but brainstorm first.** Needs UX decisions and slug-equivalence rules. |
| `Sidebar` | **Keep — highest visible impact.** Smallest-risk component override; tune section headings, active state, nested indent treatment. |
| `PageTitle` | **Keep — moderate impact.** Adds category eyebrow + tighter typography. |
| `TableOfContents` | **Keep — small but nice.** Sticky right-rail with branded active indicator. |
| `PageFrame` | **Defer.** Keep Starlight's default outer scaffold; override individual slot components instead. |

## Slice plan

Ship as three PRs, each independently mergeable and reviewable:

### Slice 1: Sidebar + PageTitle + TableOfContents (visual polish)

Three focused component overrides. No new UI, no client-side logic, no Starlight internals touched beyond the documented `components: {...}` slots. Mostly CSS work.

**Files to add:**
- `web/packages/ui/src/components/starlight/Sidebar.astro`
- `web/packages/ui/src/components/starlight/PageTitle.astro`
- `web/packages/ui/src/components/starlight/TableOfContents.astro`

**Design targets:**
- **Sidebar:** section headings in `--text-xs` uppercase `--color-fg-subtle`; leaf links `--color-fg-muted` resting, `--color-brand` + `--color-brand-soft` bg when active, indent-only nesting (no vertical guide lines). Reuse Starlight's `SidebarSublist.astro` internals; only override the outer `Sidebar.astro`.
- **PageTitle:** category eyebrow read from `Astro.locals.starlightRoute.entry.data.category || head of path segments`; H1 `--text-4xl` tracking-tight; breadcrumb line in `--color-fg-subtle`.
- **TableOfContents:** sticky right rail; `--text-xs` headings; active item bold + `--color-brand` with 2px `--color-brand` left border; preserve Starlight's smooth-scroll + mobile-TOC behavior by deferring to `TableOfContentsList` for the inner list.

**Starlight config additions (both guides and api):**
```js
components: {
  // existing Phase 2 overrides:
  Header: '@wheels-dev/ui/components/starlight/Header.astro',
  Footer: '@wheels-dev/ui/components/starlight/Footer.astro',
  SocialIcons: '@wheels-dev/ui/components/starlight/SocialIcons.astro',
  // NEW:
  Sidebar: '@wheels-dev/ui/components/starlight/Sidebar.astro',
  PageTitle: '@wheels-dev/ui/components/starlight/PageTitle.astro',
  TableOfContents: '@wheels-dev/ui/components/starlight/TableOfContents.astro',
},
```

**Risks:**
- Sidebar override must handle "Overview" injection (we already use this pattern in guides's `normalizeItem` helper for linked groups) and autogenerated sections (api uses `autogenerate: { directory: v.slug }`). Read both configs to confirm the override handles both data shapes.
- Starlight 0.34.8 data shape: `Astro.locals.starlightRoute.entry` and `Astro.locals.starlightRoute.sidebar` are the expected sources. Verify at implementation time.

**Acceptance:**
- All 4 sites still build cleanly (`pnpm build`)
- Pagefind search still returns results on guides + api
- Visual diff of one docs page per site vs. the pre-slice baseline shows the intended changes, no regressions

### Slice 2: VersionSwitcher (header dropdown)

Net-new UI. Lives in the header, so it reuses the shared Header component and imports the switcher as a sibling to the nav.

**Open UX questions for user review (answer before implementation):**

1. **Dropdown anchor:** to the right of the site title (before the nav links), or pinned as a separate badge next to it? Current Starlight sidebar version list is already present — do we remove it from the sidebar when we add the header switcher, or keep both as complementary discovery paths?
2. **Slug equivalence:** when a user on `guides.wheels.dev/v3-0-0/models/validations/` clicks "v4.0.0-SNAPSHOT", we navigate to `v4-0-0-snapshot/models/validations/` if it exists. If that slug doesn't exist in the target version, what's the fallback? Options:
   - Navigate to target version's root
   - Surface a notice: "That page isn't in v4.0.0-SNAPSHOT — here's the overview"
   - Try a fuzzy match (substring on final path segment) before root
3. **Current-version indicator:** badge-style (`current release`, `snapshot`, `archived`) or sub-label under the version number?
4. **Keyboard / a11y:** is a native `<select>` acceptable (maximal accessibility, minimal styling control), or do we build a custom listbox with the standard ARIA pattern (more styling, more JS)?
5. **Mobile:** fold into the existing hamburger drawer, or stay as an inline dropdown?

**Implementation sketch (placeholder until UX decisions land):**
- Collect version slugs from per-site config (reuse the `versions` arrays in each `astro.config.mjs`).
- Compute "equivalent page" map at build time via an Astro virtual module so client JS only needs the map + current slug.
- Render a `<details>`/`<summary>` pair as progressive-enhancement base (works without JS), upgrade with a custom listbox behavior when JS is available.

**Deferred until brainstormed.**

### Slice 3: `starlightRoute` API verification + regression test

Add a simple visual-regression screenshot test that runs on PRs touching `web/**`. Rationale: the Phase 2 + Phase 3 overrides all depend on Starlight internal data shapes (`Astro.locals.starlightRoute.*`). A one-docs-page-per-site screenshot check catches regressions before they reach production.

**Scope:**
- Add `web/scripts/visual-regression.mjs` that starts each dev server, navigates to a canary page, and compares a screenshot against a stored baseline
- CI step in `.github/workflows/web-deploy.yml` that runs it on every PR touching `web/**`
- One baseline image per site in `web/tests/visual-baselines/`

Independent of Slices 1 and 2; can be shipped any time.

## What we are intentionally NOT doing in Phase 3

- **EditLink override.** Would need to re-point edit links at source (JSON for api, GitBook markdown for guides in the sibling repo). Interesting future work; not cohesion work.
- **PageFrame override.** Starlight's default scaffold works; overriding it gains little and costs real upgrade risk.
- **Content-page layout changes** (e.g., two-column on api function pages). Separate project; pursue only if the api reference needs dedicated treatment.
- **Search UI override.** Pagefind's default is themed adequately via Phase 2's `starlight-theme.css`. If we want a branded search UI, spec it separately.

## Open questions for user

1. Do you want EditLink back if we re-point at source files (api JSON + wheels.dev GitBook)? Scope implication: separate, larger project.
2. VersionSwitcher UX questions in Slice 2 above — five decisions to make before implementation.
3. Are you OK keeping `PageFrame` as Starlight default indefinitely, or should we revisit if specific pain points emerge?
4. Is the proposed three-slice order (polish → switcher → regression test) the right priority, or does something else jump the queue (e.g., switcher first because users ask for it)?

## References

- Original cohesion spec: [`2026-04-17-wheels-dev-cohesion-design.md`](2026-04-17-wheels-dev-cohesion-design.md)
- Phase 1 plan: [`2026-04-17-web-cohesion-foundation.md`](../plans/2026-04-17-web-cohesion-foundation.md)
- Phase 2 plan: [`2026-04-17-web-cohesion-visual-polish.md`](../plans/2026-04-17-web-cohesion-visual-polish.md)
- Starlight 0.34.8 source: `node_modules/.pnpm/@astrojs+starlight@0.34.8_.../components/`
