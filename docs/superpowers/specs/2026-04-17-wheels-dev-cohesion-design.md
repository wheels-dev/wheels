# wheels.dev Multi-Site Cohesion — Design Spec

**Date:** 2026-04-17
**Status:** Draft, pending user review
**Scope:** `web/` — the four Astro sites (landing, blog, guides, api) and the shared `@wheels-dev/ui` package.
**Goal:** make `wheels.dev`, `blog.wheels.dev`, `guides.wheels.dev`, and `api.wheels.dev` feel like one property, not four separate sites.

---

## 1. Decisions

| Decision | Choice | Notes |
|----------|--------|-------|
| Visual personality | **Warm / friendly** (Rails / Laravel feel) | Rounded, generous color, pill CTAs, warm off-white surfaces. |
| Unification scope | **Full brand system** (Phase B → C) | Shared shell on every site + real design tokens + Starlight custom layout. |
| Header lockup | **Identical wordmark across all sites** | Only the active nav link indicates which section you're in. |
| Logo | **Existing marks from `wheels.dev` repo** | `wheels-logo-mark.png` (322×322), `wheels-logo.png` (lockup). Convert mark to SVG for crispness. |
| Starlight depth | **C — full custom layout** | Overrides PageFrame, Sidebar, PageTitle, TOC, Header, Footer. Build a dedicated version switcher. |
| Sequencing | **Parallel foundation** | Build `packages/ui` once, then roll through all sites together. |

## 2. Architecture

Brand lives in `web/packages/ui`. Sites consume it. Nothing brand-related is duplicated per-site.

```
web/packages/ui/
├── package.json
└── src/
    ├── assets/
    │   ├── wheels-logo-mark.svg         # NEW — SVG'd from PNG mark, respects currentColor
    │   ├── wheels-logo-mark.png         # raster fallback for OG images / email
    │   ├── wheels-logo.png              # full lockup, raster only
    │   └── favicon.svg                  # existing
    ├── components/
    │   ├── Logo.astro                   # NEW — mark-only and lockup variants
    │   ├── Header.astro                 # REBUILT — logo + nav, sticky, mobile drawer
    │   ├── Footer.astro                 # REBUILT — 3-column + bottom bar
    │   └── starlight/                   # NEW — Starlight overrides (Phase 2+3)
    │       ├── Header.astro             # Phase 2 — wraps shared Header
    │       ├── Footer.astro             # Phase 2 — wraps shared Footer
    │       ├── SocialIcons.astro        # Phase 2 — themed social links
    │       ├── PageFrame.astro          # Phase 3 — outer scaffold
    │       ├── Sidebar.astro            # Phase 3 — sidebar with warm styling
    │       ├── PageTitle.astro          # Phase 3 — consistent page header
    │       ├── TableOfContents.astro    # Phase 3 — themed right rail
    │       ├── VersionSwitcher.astro    # Phase 3 — dropdown in header
    │       └── EditLink.astro           # Phase 3 — GitHub edit link
    └── styles/
        ├── tokens.css                   # EXPANDED — full token set (see §3)
        ├── base.css                     # NEW — element resets, .prose, buttons
        └── starlight-theme.css          # NEW — maps --sl-color-* → our tokens
```

**Consumption from sites:**
- Landing, blog (plain Astro): import Header, Footer, tokens.css, base.css in their `BaseLayout.astro`.
- Guides, api (Starlight): import `tokens.css` + `starlight-theme.css` via `starlight({ customCss: [...] })`; wire the `components: {...}` override to the `starlight/` components.

## 3. Design tokens

All tokens defined in `web/packages/ui/src/styles/tokens.css`. Dark mode via `@media (prefers-color-scheme: dark)`.

```css
:root {
  /* Brand */
  --color-brand: #e63946;
  --color-brand-hover: #d12d3a;
  --color-brand-soft: #fef2f2;
  --color-brand-ink: #7a1820;

  /* Surface (light) */
  --color-bg: #ffffff;
  --color-surface: #fafaf7;
  --color-surface-2: #f3f1ec;
  --color-border: #e8e5df;
  --color-border-strong: #d4d0c6;

  /* Text (light) */
  --color-fg: #1a1a1a;
  --color-fg-muted: #6b6b68;
  --color-fg-subtle: #9a9893;

  /* Feedback */
  --color-success: #2f855a;
  --color-warning: #b45309;
  --color-danger: var(--color-brand);

  /* Type */
  --font-sans: 'Inter', system-ui, -apple-system, sans-serif;
  --font-mono: 'JetBrains Mono', ui-monospace, Menlo, monospace;
  --font-display: var(--font-sans);

  --text-xs: 0.75rem;    --text-sm: 0.875rem;    --text-base: 1rem;
  --text-lg: 1.125rem;   --text-xl: 1.25rem;     --text-2xl: 1.5rem;
  --text-3xl: 1.875rem;  --text-4xl: 2.25rem;
  --text-5xl: clamp(2.5rem, 5vw, 3.75rem);       /* hero */

  --leading-tight: 1.15;
  --leading-normal: 1.55;
  --leading-relaxed: 1.7;
  --tracking-tight: -0.02em;

  /* Space (4px base) */
  --space-1: 0.25rem; --space-2: 0.5rem;  --space-3: 0.75rem;
  --space-4: 1rem;    --space-5: 1.5rem;  --space-6: 2rem;
  --space-7: 3rem;    --space-8: 4rem;    --space-9: 6rem;

  /* Radius */
  --radius-sm: 0.25rem;
  --radius: 0.5rem;
  --radius-lg: 0.75rem;
  --radius-xl: 1rem;
  --radius-pill: 999px;

  /* Shadow */
  --shadow-sm: 0 1px 2px rgb(0 0 0 / 0.04);
  --shadow: 0 4px 12px rgb(0 0 0 / 0.06);
  --shadow-lg: 0 12px 32px rgb(0 0 0 / 0.08);

  /* Layout */
  --max-width: 1200px;
  --max-width-prose: 68ch;
  --header-height: 64px;
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-bg: #0f0f0e;
    --color-surface: #181816;
    --color-surface-2: #222220;
    --color-border: #2a2a27;
    --color-border-strong: #3a3a35;
    --color-fg: #f5f5f3;
    --color-fg-muted: #a8a6a1;
    --color-fg-subtle: #6a6864;
    --color-brand-soft: #2a1416;
    --color-brand-ink: #ffb5bc;
  }
}
```

**Notable shifts from current:**
- Cool greys → warm greys (tinted toward red/brown, not blue).
- Brand-soft + brand-ink enable warm-tinted surfaces without using body bg as the only "color" move.
- Full type scale so all heading and body sizes are defined once, not redeclared per component.
- Shadow tokens (currently none). Cards stop looking flat.
- `--radius-pill` for warm CTAs.
- `--max-width-prose` for blog posts and guide pages (68ch reading measure).

## 4. Shared components

### `Logo.astro`
```astro
---
interface Props {
  variant?: 'mark' | 'lockup';   // default 'mark'
  size?: 'sm' | 'md' | 'lg';     // 20 / 28 / 40 px for mark
  class?: string;
}
---
```
Inline SVG (currentColor) for the mark so it scales and theming works. Lockup = mark + "wheels.dev" wordmark, with the `.` in `--color-brand`. Raster PNG fallback available for OG/email.

### `Header.astro` (rebuilt)
- Sticky, 64px tall.
- Left: `<Logo variant="lockup">`.
- Right: links — Home · Guides · API · Blog · GitHub (last item has ↗).
- Active link: bold + `--color-brand`.
- Scroll state: adds `--shadow-sm` once scrolled past the top.
- Mobile: <720px → hamburger. Drawer slides in from right.

```astro
interface Props {
  current?: 'landing' | 'guides' | 'api' | 'blog';
}
```

### `Footer.astro` (rebuilt)
Three-column layout + bottom bar:
- Col 1: logo + one-line description.
- Col 2 "Docs": Guides, API reference, Blog, CLI, RSS feed.
- Col 3 "Community": GitHub, Discussions, Matrix chat, Security policy.
- Bottom: © year + "MIT licensed" + framework version.

Background: `--color-surface`.

## 5. Landing page (`sites/landing/src/pages/index.astro`)

Structure unchanged (hero / features / resources). Polish only.

**Hero:**
- Background: subtle gradient from `--color-bg` to `--color-brand-soft`.
- Eyebrow label above title: small uppercase red text.
- Title: `--text-5xl`, `--tracking-tight`. "fast" in `--color-brand` as today.
- CTAs: pill-shaped (`--radius-pill`). Primary = red filled "Get started". Secondary = red outlined "View on GitHub".
- Install snippet: dark bg, `--shadow`, `--radius-lg`.
- Below snippet: small caption "Runs on Lucee 7, Adobe 2023/2025, BoxLang."

**Features grid:**
- Cards: `--shadow-sm`, hover lifts to `--shadow`.
- Each card: 20px `--color-brand` line icon + h3 + body. Use Heroicons outline or similar (decision deferred to implementation).
- Grid unchanged: `repeat(auto-fit, minmax(280px, 1fr))`.

**Resources block:**
- Background: `--color-surface` (currently `--color-border`, which is harsh).
- Cards stay on `--color-bg` white for contrast.
- Add short intro line above grid: "Everything is split across subdomains — here's where to go next."
- Each resource card gets a subdomain tag (e.g., `guides.wheels.dev`) in `--color-fg-subtle`.

**Removed:** no "Built with Wheels" showcase section — the site is Astro, not Wheels, and showing "built with" logos would misrepresent.

## 6. Blog (`sites/blog/`)

Minimal visual changes. RSS promoted to a first-class affordance.

**`BaseLayout.astro`:** swaps to new shared Header + Footer automatically (nothing site-specific to change). Body uses `--color-bg`; `<main>` caps at `--max-width-prose` (68ch) — flag for user review since some migrated posts may assume wider layout.

**Post list (`index.astro`):**
- Paginated cards: `--shadow-sm`, hover → `--shadow`.
- Cover image (when present) fills card top with rounded-top corners.
- Meta row: author + date in `--color-fg-muted`.
- Tag pills: `--color-brand-soft` bg / `--color-brand-ink` text.
- Top-right of listing area: outline pill button "RSS" linking to `/rss.xml`.

**Individual post (`PostLayout.astro`):**
- Category eyebrow → title (`--text-4xl`) → author/date → cover image → prose body.
- Same RSS pill in post header area.
- Tag pills at bottom.
- Existing Giscus + NewsletterSignup preserved.

**Prose styling (new `.prose` class in `packages/ui/src/styles/base.css`):**
- Reused by guides + api content in Phase 3.
- Headings: `--tracking-tight`, `--font-display`.
- Body: `--leading-relaxed`, `--color-fg`.
- Links: `--color-brand`, underline on hover.
- Blockquotes: left border `--color-brand`, `--color-surface-2` background.
- Inline code: `--color-surface-2` bg, `--radius-sm`.
- Code blocks: dark bg (matches hero install block).

**NewsletterSignup:**
- Restyled: `--color-surface` bg, pill input + pill button.
- Secondary line below form: "Prefer RSS? Subscribe to the feed →"

**RSS visibility summary:**
- Listing page: RSS pill top-right.
- Post page: RSS pill in header.
- NewsletterSignup: secondary "Prefer RSS?" line.
- Footer: RSS entry in Community column.
- `<head>`: `<link rel="alternate" type="application/rss+xml">` preserved.

**Unchanged:** tag pages, RSS feed generation, content schema, Buttondown integration, Giscus config.

## 7. Starlight integration — Phase 2 (B-depth)

Target: guides + api share the same top chrome as landing + blog. Sidebars and content layouts still use Starlight defaults, themed via tokens.

**`astro.config.mjs` additions (both guides and api):**
```js
starlight({
  // ...existing config...
  customCss: [
    '@wheels-dev/ui/styles/tokens.css',
    '@wheels-dev/ui/styles/starlight-theme.css',
  ],
  components: {
    Header: '@wheels-dev/ui/components/starlight/Header.astro',
    SocialIcons: '@wheels-dev/ui/components/starlight/SocialIcons.astro',
    Footer: '@wheels-dev/ui/components/starlight/Footer.astro',
  },
});
```

**`starlight-theme.css`** — token bridge. Maps Starlight's `--sl-color-*` onto our `--color-*`. Covers colors, fonts, radii, shadows, and spacing. Full map in implementation; key entries:
```css
--sl-color-accent: var(--color-brand);
--sl-color-accent-low: var(--color-brand-soft);
--sl-color-accent-high: var(--color-brand-ink);
--sl-color-bg: var(--color-bg);
--sl-color-bg-sidebar: var(--color-surface);
--sl-font: var(--font-sans);
--sl-font-mono: var(--font-mono);
--sl-radius-small: var(--radius-sm);
--sl-radius-medium: var(--radius);
/* + gray-1..7, text, etc. */
```

**`starlight/Header.astro`:** wraps shared `Header` and derives `current` from the site slug (guides vs api) so identical markup renders on all sites. Reads `Astro.locals.starlightRoute` to hide the version switcher on pages where it doesn't apply (Overview page).

**`starlight/Footer.astro`:** same pattern around shared `Footer`.

**`starlight/SocialIcons.astro`:** themed GitHub link matching header treatment.

**Phase 2 validation:** visual diff check — screenshot top 200px of every site, expect pixel-identical headers. If not, fix tokens or `starlight-theme.css` before Phase 3.

**What still looks "Starlight-y" at end of Phase 2:**
- Sidebar tree
- Page title + breadcrumbs area
- TOC
- Pagefind search UI

Intentional — Phase 3 picks those up.

## 8. Starlight customization — Phase 3 (C-depth)

Full custom layout for guides + api. Ship in a separate PR after Phase 2 has soaked.

**Override components in `packages/ui/src/components/starlight/`:**

- **`PageFrame.astro`** — outer scaffold. Uses `--header-height`, wraps main in max-width container, `--color-surface` sidebar.
- **`Sidebar.astro`** — rebuilt look. Section headings `--text-xs` uppercase `--color-fg-subtle`. Leaf links smaller, `--color-brand` active state with `--color-brand-soft` bg. No vertical guide lines.
- **`PageTitle.astro`** — category eyebrow from frontmatter → H1 `--text-4xl` tracking-tight → optional subtitle → breadcrumb line.
- **`TableOfContents.astro`** — sticky right rail, `--text-xs` headings. Active item: bold, `--color-brand`, 2px left-border.
- **`VersionSwitcher.astro` (NEW)** — dropdown docked in header next to site title. Replaces sidebar version list. On click: shows all versions with badges (`current`, `snapshot`, `archived`). Clicking a version navigates to the same slug if it exists in that version, else the version's root. Closes the "dedicated top-bar version dropdown" item on the v4.0 web backlog.
- **`EditLink.astro`** — restyled "Edit this page on GitHub →" at bottom of docs pages. URL built from `Astro.locals.starlightRoute.entry.filePath`.

**Kept from Starlight default:**
- Pagefind search (themed via CSS only, no component override).
- Content + MDX pipeline.
- Prev/next page navigation.
- i18n plumbing (unused today, preserved).

**Risk & mitigation:**
- *Starlight upgrades may break overrides.* → Pin Starlight version in `package.json` until we understand stability cost. Add visual-regression screenshot test (one docs page per site) on PRs.
- *`starlightRoute` API shape varies between versions.* → Verify against the pinned version in the implementation plan.
- *Pagefind indexing relies on `<ContentPanel>` DOM.* → PageFrame override preserves `<ContentPanel>` placement. Post-Phase-3 smoke test: run a search, confirm results.

**Deferred to Phase 4 (not blocking Phase 3):** switch generated API pages from `.md` to `.mdx` so they can use the existing `FunctionSignature.astro` component.

## 9. Phased rollout

Three PRs, sequenced:

**PR 1 — Brand foundation** (`web/packages/ui`)
- Expand tokens (§3).
- Add `base.css` + `.prose` class.
- Copy logo assets into `packages/ui/src/assets/`; convert mark PNG → SVG.
- Build `Logo.astro`, rebuild `Header.astro`, rebuild `Footer.astro` (backwards-compatible with current `current` prop).
- Add `starlight-theme.css` file — not yet imported by any site.
- Smoke test: `pnpm dev:landing` and `pnpm dev:blog` still load and render the updated header/footer cleanly. Sites pick up the new chrome automatically (same import paths) but no site-level code changes.
- No changes to guides / api in this PR.

**PR 2 — Visual polish + Starlight Phase 2**
- Landing: apply hero/features/resources polish from §5.
- Blog: add RSS pills, restyle post list + post page, restyle NewsletterSignup.
- Guides + api: import `tokens.css` + `starlight-theme.css` via `starlight({ customCss })`; build and wire the three Starlight overrides — `starlight/Header.astro`, `starlight/Footer.astro`, `starlight/SocialIcons.astro`.
- Validation: screenshot top 200px of all four sites; headers must match pixel-level.

**PR 3 — Starlight Phase 3 (C-depth)**
- Build remaining `starlight/` component overrides: `PageFrame`, `Sidebar`, `PageTitle`, `TableOfContents`, `VersionSwitcher`, `EditLink`.
- Wire all overrides into guides + api `astro.config.mjs`.
- Add visual-regression test (one screenshot per site).
- Full smoke test: search, version switching, edit links.

Each PR independently deployable and reviewable. PR 2 is the biggest.

## 10. Testing & verification

- **Local dev:** `pnpm dev:landing|blog|guides|api` to check each site.
- **Astro check:** `pnpm --filter <site> exec astro check` for type errors.
- **Build:** `pnpm build` must pass cleanly.
- **Visual check:** after each PR, open all four sites side-by-side at desktop + mobile widths.
- **Phase 2 acceptance:** identical top chrome across all four sites.
- **Phase 3 acceptance:** search works on guides + api; version switcher switches within same page slug when available; edit links point to the right GitHub file.
- **Dark mode:** spot-check each site in Chrome DevTools "prefers-color-scheme: dark" emulation.
- **Pagefind:** after Phase 3, run search on guides + api and confirm results render.

## 11. Branches, scopes, commits

- Branch: `peter/web-cohesion-foundation`, `peter/web-cohesion-rollout`, `peter/web-cohesion-starlight-custom` (one per PR).
- Commit scope: `web/ui`, `web/landing`, `web/blog`, `web/guides`, `web/api`, `web/starlight` per commitlint config.
- Subjects lowercase.

## 12. Open questions (to resolve during implementation)

- **SVG'd mark:** convert `wheels-logo-mark.png` → `wheels-logo-mark.svg` by hand or via vectorization tool. Needs a clean-up pass.
- **Icon library for feature grid:** Heroicons, Lucide, or custom. Deferred; pick during PR 2.
- **Prose max-width for blog posts (68ch):** confirm with user on spec review — migrated posts may expect wider layout.
- **`starlightRoute` API shape:** verify stability on the Starlight version pinned; adjust `VersionSwitcher` implementation accordingly.
- **Pagefind search styling:** scope of CSS override needed to blend with brand. Phase 3.
- **Apex cutover (`wheels.dev` Swarm retirement):** out of scope for this spec; flagged separately.

