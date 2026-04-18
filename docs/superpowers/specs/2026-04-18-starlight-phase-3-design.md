# Starlight Phase 3 — C-Depth Custom Layout Design

**Date:** 2026-04-18
**Status:** Approved — decisions locked after interview 2026-04-18. Ready for implementation.
**Scope:** `web/sites/guides` and `web/sites/api` — the two Starlight-powered sites
**Depends on:** [PR #2153](https://github.com/wheels-dev/wheels/pull/2153) (Phase 2 shipped)
**Supersedes:** §8 of [`2026-04-17-wheels-dev-cohesion-design.md`](2026-04-17-wheels-dev-cohesion-design.md)

---

## Why a new spec

The original cohesion spec's §8 proposed six Starlight overrides as one bundle: `PageFrame`, `Sidebar`, `PageTitle`, `TableOfContents`, `VersionSwitcher`, `EditLink`. Investigating against Starlight 0.34.8 and walking the decision tree with the user surfaced information that reshapes the proposal:

1. **EditLink is worth investing in**, contrary to the original assumption that our generated content made it useless. Guides are *generated* — but the source is markdown files at `docs/src/**/*.md` *in this repo*, not in a sibling repo. API pages are extracted from CFC function annotations into `docs/api/v*.json`; the json is the build artifact, but the source CFC files (`vendor/wheels/<scope>/*.cfc`) are grep-findable and we can link directly to them.
2. **PageFrame override is disproportionately risky.** Starlight 0.34.8's layout architecture is churny; overriding the outer scaffold means owning skip-link plumbing + mobile-drawer + sidebar persistence ourselves. Deferring.
3. **Cosmetic parity is already largely achieved** via the Phase 2 `starlight-theme.css` token bridge. The remaining gaps are component-specific polish and the VersionSwitcher UI.
4. **VersionSwitcher UX is now specified.** The user and I walked the eight open questions through a structured interview; every decision below is locked.

## Decisions (summary)

| Component | Decision |
|-----------|----------|
| `EditLink` | **Keep.** Guides link at `https://github.com/wheels-dev/wheels/edit/develop/docs/src/{path}.md`. API links at the source CFC for that function. Exact mechanism for the api mapping decided during Slice 1 implementation. |
| `VersionSwitcher` | **Keep — UX locked.** See Slice 2. |
| `Sidebar` | **Keep** — highest visible impact. Section headings in `--text-xs` uppercase `--color-fg-subtle`; leaf links `--color-fg-muted` resting, `--color-brand` + `--color-brand-soft` bg when active, indent-only nesting (no vertical guide lines). |
| `PageTitle` | **Keep** — category eyebrow from frontmatter or first path segment; H1 `--text-4xl` tracking-tight; breadcrumb line in `--color-fg-subtle`. |
| `TableOfContents` | **Keep** — sticky right rail; `--text-xs` headings; active item bold + `--color-brand` with 2px `--color-brand` left border. |
| `PageFrame` | **Defer.** Keep Starlight's default outer scaffold. |

## Slice plan

Three PRs, each independently mergeable and reviewable. Priority: polish (lowest risk) → VersionSwitcher (moderate) → regression safety net.

### Slice 1 — Sidebar + PageTitle + TableOfContents + EditLink

Four focused component overrides. No new UI, no client-side logic, no Starlight internals touched beyond the documented `components: {...}` slots.

**Files to add:**
- `web/packages/ui/src/components/starlight/Sidebar.astro`
- `web/packages/ui/src/components/starlight/PageTitle.astro`
- `web/packages/ui/src/components/starlight/TableOfContents.astro`
- `web/packages/ui/src/components/starlight/EditLink.astro`

**Design targets:**
- **Sidebar:** see decision table. Reuse Starlight's `SidebarSublist.astro` internals; only override the outer `Sidebar.astro`. Must handle both data shapes — manual sidebar with `normalizeItem` (guides) and `autogenerate: { directory: ... }` (api).
- **PageTitle:** category eyebrow read from `Astro.locals.starlightRoute.entry.data.category` if present, else the first non-version path segment (e.g., `/v3-0-0/models/validations/` → "Models"). H1 `--text-4xl` tracking-tight. Breadcrumb crumbs on a thin line in `--color-fg-subtle`.
- **TableOfContents:** sticky below header; `--text-xs` headings, `--color-fg-muted`; active item `--color-brand` bold with 2px `--color-brand` left border. Preserve Starlight's smooth-scroll + mobile-TOC drawer by rendering `TableOfContentsList` inside our shell.
- **EditLink:**
  - **Guides:** construct URL as `https://github.com/wheels-dev/wheels/edit/develop/docs/src/{entry.id}.md` (verify `entry.id` aligns with source path during implementation; generator may prepend the version slug — strip it if so).
  - **API:** three candidate mechanisms for mapping `function name + availableIn scope` → CFC file path. Decide during implementation:
    - (a) **GitHub search link** — cheapest. `https://github.com/wheels-dev/wheels/search?q=repo%3Awheels-dev%2Fwheels+function+{name}&type=code`. Zero generator change.
    - (b) **Build-time grep** — at generate-api-docs time, walk `vendor/wheels/<availableIn[0]>/*.cfc` and record the file path per function into the generated frontmatter. Best direct-link UX, modest generator change.
    - (c) **Enhance the upstream JSON extractor** — ask the tool that builds `docs/api/v*.json` to record source path. Cleanest long-term but depends on upstream.
  - **Recommend starting with (b)** and falling back to (a) if ambiguity (multiple matches).

**Starlight config additions (both guides and api):**
```js
components: {
  // existing Phase 2:
  Header: '@wheels-dev/ui/components/starlight/Header.astro',
  Footer: '@wheels-dev/ui/components/starlight/Footer.astro',
  SocialIcons: '@wheels-dev/ui/components/starlight/SocialIcons.astro',
  // Slice 1:
  Sidebar: '@wheels-dev/ui/components/starlight/Sidebar.astro',
  PageTitle: '@wheels-dev/ui/components/starlight/PageTitle.astro',
  TableOfContents: '@wheels-dev/ui/components/starlight/TableOfContents.astro',
  EditLink: '@wheels-dev/ui/components/starlight/EditLink.astro',
},
```

Also wire `editLink: { baseUrl: 'https://github.com/wheels-dev/wheels/edit/develop/' }` in the Starlight config so `Astro.locals.starlightRoute.editUrl` is populated for our override to pick up.

**Acceptance:**
- All 4 sites still build cleanly (`pnpm build`)
- Pagefind search still returns results on guides + api
- Visual diff of one docs page per site vs. the pre-slice baseline shows the intended changes, no regressions
- EditLink on a guides page lands on the correct `docs/src/*.md` file in GitHub's edit view
- EditLink on an api page lands somewhere useful (target depends on which api mechanism ships first)

### Slice 2 — VersionSwitcher (header dropdown)

Net-new UI. Lives in the header, to the right of the wordmark lockup. Replaces the per-version grouping in the sidebar — sidebar becomes scoped to the currently selected version only.

**UX decisions (locked):**

| Question | Answer |
|----------|--------|
| Dropdown anchor | Inline pill next to the wordmark. Sidebar drops per-version grouping; shows only the currently selected version's TOC. |
| Slug-equivalence fallback | **Hybrid:** exact slug match first → fuzzy match on final 1-2 path segments → fall back to target version root. Computed at build time as a static map. |
| Indicator style | Colored badge: `v3.0.0 [CURRENT]` (green), `v4.0.0-SNAPSHOT [SNAPSHOT]` (amber), `v2.5.0 [ARCHIVED]` (grey). Badge shows ambient status without requiring dropdown interaction. |
| a11y / keyboard | `<details>`/`<summary>` progressive-enhancement base (works without JS as native disclosure). With JS, upgrade to an ARIA listbox pattern — `role="listbox"`, arrow-key navigation, enter-to-commit, escape-to-close, focus trap while open. |
| Mobile | Fold into the hamburger drawer. Drawer shows nav + a "Switch version" section listing all versions with their badges. Inline pill in the header hides at `<720px`. |

**Files to add:**
- `web/packages/ui/src/components/starlight/VersionSwitcher.astro`
- Some form of build-time slug-equivalence map. Options:
  - Astro virtual module exposing `{ version, slugMap }` to client JS (recommended)
  - Static JSON written to `web/packages/ui/src/generated/version-slugs.json` at build time via a `scripts/build-version-slugs.mjs` script
  - Pre-computed inside each site's `astro.config.mjs` and passed as a prop

**Per-site config:**
- Each `astro.config.mjs` continues to own its `versions` array. The switcher reads it via Starlight route data or a site-provided integration.
- Add `editLink.baseUrl` (already done in Slice 1).

**Where to dock the switcher:** not inside Starlight's default `Header` (that's already overridden to render our shared `Header.astro`). Instead:
- Extend the shared `Header.astro` with an optional `<slot name="after-brand">` placement
- Populate that slot from the Starlight Header wrapper (`@wheels-dev/ui/components/starlight/Header.astro`) so landing + blog don't render the switcher (no versions there)

**Acceptance:**
- All four sites still build + style-check clean
- Switcher renders only on guides + api
- Switching from a deep page navigates to the equivalent page in the target version when it exists; otherwise lands at target version root (fuzzy match path covered by tests)
- Keyboard: arrow-up/down moves highlight, enter navigates, escape closes
- Screen reader (VoiceOver / NVDA) announces as a listbox with the current selection
- `<details>`-base still opens and navigates when JS is disabled (progressive enhancement)
- Mobile drawer shows the "Switch version" section

### Slice 3 — Visual-regression screenshot test in CI

Add a minimal screenshot-comparison step that runs on PRs touching `web/**`. Catches Starlight internal-API breakage before it ships (Phase 2 + Slice 1/2 both depend on `Astro.locals.starlightRoute.*` shape, which could shift on a Starlight upgrade).

**Scope:**
- `web/scripts/visual-regression.mjs` — starts each dev server, navigates to one canary page per site, screenshots, compares against a stored baseline (pixel diff via `pixelmatch` or similar).
- Baselines in `web/tests/visual-baselines/` (4 images — one per site).
- CI step in `.github/workflows/web-deploy.yml` that runs it on every PR touching `web/**`. Failure doesn't block merge initially (soft-fail) so contributors can refresh baselines; tighten to hard-fail once stable.
- One documented refresh command: `pnpm --filter @wheels-dev/web run visual:baseline`.

**Independent of Slices 1 and 2.** Can ship at any time.

## What we are intentionally NOT doing in Phase 3

- **PageFrame override.** Starlight default is fine; skip the upgrade risk.
- **Content-page layout changes** (e.g., two-column on api function pages). Separate project.
- **Search UI override.** Pagefind's default is themed adequately via Phase 2's `starlight-theme.css`. If we want a branded search UI, spec it separately.

## References

- Original cohesion spec: [`2026-04-17-wheels-dev-cohesion-design.md`](2026-04-17-wheels-dev-cohesion-design.md)
- Phase 1 plan: [`2026-04-17-web-cohesion-foundation.md`](../plans/2026-04-17-web-cohesion-foundation.md)
- Phase 2 plan: [`2026-04-17-web-cohesion-visual-polish.md`](../plans/2026-04-17-web-cohesion-visual-polish.md)
- Starlight 0.34.8 source: `node_modules/.pnpm/@astrojs+starlight@0.34.8_.../components/`
- Guides markdown source: `docs/src/**/*.md`
- API JSON source: `docs/api/v*.json`; CFC origin under `vendor/wheels/<scope>/*.cfc`
