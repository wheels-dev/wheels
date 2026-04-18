# Web Cohesion — Visual Polish + Starlight Phase 2 (PR 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the warm/friendly brand polish across landing + blog content, and wire guides + api into the shared design system so all four sites share an identical top chrome.

**Architecture:** Reuses everything shipped in PR 1 ([spec](../specs/2026-04-17-wheels-dev-cohesion-design.md), [PR 1 plan](2026-04-17-web-cohesion-foundation.md)). One new shared component (`RssPill.astro`) in `@wheels-dev/ui`. Landing and blog get per-site content restyling. Guides + api get three new Starlight override components (`starlight/Header.astro`, `starlight/Footer.astro`, `starlight/SocialIcons.astro`) plus `customCss` + `components` wiring.

**Tech Stack:** Astro 5, Starlight, pnpm workspaces, CSS custom properties.

**Reference:**
- Spec: [`docs/superpowers/specs/2026-04-17-wheels-dev-cohesion-design.md`](../specs/2026-04-17-wheels-dev-cohesion-design.md)
- Prior PR: [wheels#2152](https://github.com/wheels-dev/wheels/pull/2152) (merged)

**Branch:** `peter/web-cohesion-polish` off `origin/develop`.

---

## File Structure

**New files:**
- `web/packages/ui/src/components/RssPill.astro` — small pill-shaped "RSS" button, used by blog

**Modified files (UI package):**
- `web/packages/ui/package.json` — add RssPill export
- `web/packages/ui/src/components/starlight/Header.astro` — NEW (under new subfolder)
- `web/packages/ui/src/components/starlight/Footer.astro` — NEW
- `web/packages/ui/src/components/starlight/SocialIcons.astro` — NEW

**Modified files (landing):**
- `web/sites/landing/src/pages/index.astro` — hero eyebrow + pill CTAs + gradient bg + engine caption + features icons/shadows + resources warm bg + subdomain tags

**Modified files (blog):**
- `web/sites/blog/src/components/PostCard.astro` — card shadows, hover lift, tag pills, title size
- `web/sites/blog/src/components/NewsletterSignup.astro` — warm surface, pill input/button, "Prefer RSS?" line
- `web/sites/blog/src/pages/index.astro` — RSS pill in listing header
- `web/sites/blog/src/layouts/PostLayout.astro` — category eyebrow, tag pills at bottom, RSS pill, cover image styling

**Modified files (Starlight):**
- `web/sites/guides/astro.config.mjs` — add `customCss` + `components`
- `web/sites/api/astro.config.mjs` — add `customCss` + `components`

**Not touched:**
- RSS feed generation (`rss.xml.js`) — no change
- Content schema / existing posts
- Guides / api content
- Giscus, Buttondown integration logic

---

## Task 1: Add RssPill shared component

**Files:**
- Create: `web/packages/ui/src/components/RssPill.astro`
- Modify: `web/packages/ui/package.json`

- [ ] **Step 1: Create `web/packages/ui/src/components/RssPill.astro`**

```astro
---
interface Props {
	href?: string;
	label?: string;
	class?: string;
}

const {
	href = '/rss.xml',
	label = 'RSS',
	class: className = '',
} = Astro.props;
---

<a href={href} class:list={['wd-rss-pill', className]} aria-label={`${label} feed`}>
	<svg
		class="wd-rss-pill__icon"
		width="14"
		height="14"
		viewBox="0 0 24 24"
		fill="none"
		stroke="currentColor"
		stroke-width="2"
		stroke-linecap="round"
		stroke-linejoin="round"
		aria-hidden="true"
	>
		<path d="M4 11a9 9 0 0 1 9 9" />
		<path d="M4 4a16 16 0 0 1 16 16" />
		<circle cx="5" cy="19" r="1" />
	</svg>
	<span>{label}</span>
</a>

<style>
	.wd-rss-pill {
		display: inline-flex;
		align-items: center;
		gap: var(--space-2);
		padding: var(--space-2) var(--space-4);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-pill);
		background: transparent;
		color: var(--color-fg-muted);
		font-family: var(--font-sans);
		font-size: var(--text-xs);
		font-weight: 600;
		text-decoration: none;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		transition:
			border-color 0.15s,
			color 0.15s,
			background 0.15s;
	}

	.wd-rss-pill:hover {
		border-color: var(--color-brand);
		color: var(--color-brand);
		background: var(--color-brand-soft);
		text-decoration: none;
	}

	.wd-rss-pill__icon {
		color: var(--color-brand);
		flex-shrink: 0;
	}
</style>
```

- [ ] **Step 2: Add RssPill to package exports in `web/packages/ui/package.json`**

Add to the `exports` object:
```json
"./components/RssPill.astro": "./src/components/RssPill.astro",
```

The final `exports` object should be (order doesn't matter but grouping helps):
```json
"exports": {
  "./components/Header.astro": "./src/components/Header.astro",
  "./components/Footer.astro": "./src/components/Footer.astro",
  "./components/Logo.astro": "./src/components/Logo.astro",
  "./components/RssPill.astro": "./src/components/RssPill.astro",
  "./styles/tokens.css": "./src/styles/tokens.css",
  "./styles/base.css": "./src/styles/base.css",
  "./styles/starlight-theme.css": "./src/styles/starlight-theme.css",
  "./assets/*": "./src/assets/*"
},
```

- [ ] **Step 3: Re-link workspace**

Run from worktree root: `pnpm install`
Expected: "Done in Nms" — workspace symlinks regenerated so sites pick up the new export.

- [ ] **Step 4: Commit**

```bash
git add web/packages/ui/src/components/RssPill.astro web/packages/ui/package.json
git commit -m "feat(web/ui): add RssPill component with icon + pill styling"
```

---

## Task 2: Landing hero polish

**Files:**
- Modify: `web/sites/landing/src/pages/index.astro`

The current hero works structurally but is missing: eyebrow label, gradient background, engine compatibility caption, and the CTAs aren't using the shared `.btn--primary` / `.btn--secondary` classes (they use local styles).

- [ ] **Step 1: Replace the hero `<section>` (inside the `<BaseLayout>`) with this content**

Find the existing `<section class="hero">...</section>` block (lines ~9-25) and replace with:

```astro
	<section class="hero">
		<div class="hero__inner">
			<p class="hero__eyebrow">A Rails-inspired framework for CFML</p>
			<h1 class="hero__title">Build CFML applications, <span>fast</span>.</h1>
			<p class="hero__subtitle">
				Wheels is an open-source MVC framework for CFML. Rails-inspired conventions, a powerful ORM,
				database migrations, and a modern CLI — so you spend less time wiring things up and more
				time shipping.
			</p>
			<div class="hero__cta">
				<a class="btn btn--primary" href="https://guides.wheels.dev/v3-0-0/">Get started</a>
				<a class="btn btn--secondary" href="https://github.com/wheels-dev/wheels">View on GitHub</a>
			</div>
			<pre
				class="hero__install"><code>box install wheels-cli
box wheels generate app MyApp</code></pre>
			<p class="hero__engines">
				Runs on Lucee 7, Adobe ColdFusion 2023/2025, and BoxLang.
			</p>
		</div>
	</section>
```

**Key changes:** new `.hero__eyebrow` above title; CTAs now use `.btn .btn--primary` / `.btn .btn--secondary` (from `base.css`); new `.hero__engines` line below the install snippet.

- [ ] **Step 2: Replace the `.hero` styles in the bottom `<style>` block**

Find the existing `.hero`, `.hero__inner`, `.hero__title`, `.hero__title span`, `.hero__subtitle`, `.hero__cta`, `.btn` (local), `.btn:hover`, `.btn--primary`, `.btn--secondary`, `.hero__install` rules and **replace all of them** with:

```css
	.hero {
		padding: 4rem 1.5rem 3rem;
		text-align: center;
		background: linear-gradient(180deg, var(--color-bg) 0%, var(--color-brand-soft) 100%);
	}
	.hero__inner {
		max-width: 900px;
		margin: 0 auto;
	}
	.hero__eyebrow {
		font-size: var(--text-xs);
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.12em;
		color: var(--color-brand);
		margin: 0 0 var(--space-4);
	}
	.hero__title {
		font-size: var(--text-5xl);
		line-height: var(--leading-tight);
		letter-spacing: var(--tracking-tight);
		margin: 0 0 var(--space-4);
	}
	.hero__title span {
		color: var(--color-brand);
	}
	.hero__subtitle {
		font-size: var(--text-lg);
		line-height: var(--leading-relaxed);
		color: var(--color-fg-muted);
		max-width: 640px;
		margin: 0 auto var(--space-6);
	}
	.hero__cta {
		display: flex;
		gap: var(--space-3);
		justify-content: center;
		flex-wrap: wrap;
		margin-bottom: var(--space-6);
	}
	.hero__install {
		display: inline-block;
		text-align: left;
		background: var(--color-fg);
		color: var(--color-bg);
		padding: var(--space-4) var(--space-5);
		border-radius: var(--radius-lg);
		font-family: var(--font-mono);
		font-size: var(--text-sm);
		line-height: var(--leading-relaxed);
		margin: 0 0 var(--space-4);
		box-shadow: var(--shadow);
	}
	.hero__engines {
		font-size: var(--text-sm);
		color: var(--color-fg-subtle);
		margin: 0;
	}
```

**Note:** The local `.btn`, `.btn--primary`, `.btn--secondary` rules are DELETED — they now come from `base.css`.

- [ ] **Step 3: Type check**

Run: `pnpm --filter @wheels-dev/site-landing exec astro check 2>&1 | tail -5`
Expected: 0 errors.

- [ ] **Step 4: Commit**

```bash
git add web/sites/landing/src/pages/index.astro
git commit -m "feat(web/landing): hero polish — eyebrow, pill CTAs, gradient bg, engine caption"
```

---

## Task 3: Landing features grid — icons + shadows

**Files:**
- Modify: `web/sites/landing/src/pages/index.astro`

- [ ] **Step 1: Replace the features `<section>` in the template**

Find the existing `<section class="features">...</section>` block and replace with:

```astro
	<section class="features">
		<h2 class="features__heading">What you get out of the box</h2>
		<ul class="features__grid">
			<li>
				<svg class="feature-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6A2.25 2.25 0 0 1 6 3.75h2.25A2.25 2.25 0 0 1 10.5 6v2.25a2.25 2.25 0 0 1-2.25 2.25H6a2.25 2.25 0 0 1-2.25-2.25V6ZM3.75 15.75A2.25 2.25 0 0 1 6 13.5h2.25a2.25 2.25 0 0 1 2.25 2.25V18a2.25 2.25 0 0 1-2.25 2.25H6A2.25 2.25 0 0 1 3.75 18v-2.25ZM13.5 6a2.25 2.25 0 0 1 2.25-2.25H18A2.25 2.25 0 0 1 20.25 6v2.25A2.25 2.25 0 0 1 18 10.5h-2.25a2.25 2.25 0 0 1-2.25-2.25V6ZM13.5 15.75a2.25 2.25 0 0 1 2.25-2.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25 2.25 0 0 1 18 20.25h-2.25A2.25 2.25 0 0 1 13.5 18v-2.25Z" /></svg>
				<h3>MVC, done right</h3>
				<p>
					Clear separation between routes, controllers, models, and views. Convention over
					configuration so you write less boilerplate.
				</p>
			</li>
			<li>
				<svg class="feature-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M20.25 6.375c0 2.278-3.694 4.125-8.25 4.125S3.75 8.653 3.75 6.375m16.5 0c0-2.278-3.694-4.125-8.25-4.125S3.75 4.097 3.75 6.375m16.5 0v11.25c0 2.278-3.694 4.125-8.25 4.125s-8.25-1.847-8.25-4.125V6.375m16.5 0v3.75m-16.5-3.75v3.75m16.5 0v3.75C20.25 16.153 16.556 18 12 18s-8.25-1.847-8.25-4.125v-3.75m16.5 0c0 2.278-3.694 4.125-8.25 4.125s-8.25-1.847-8.25-4.125" /></svg>
				<h3>Expressive ORM</h3>
				<p>
					Model classes map directly to database tables. Associations, validations, callbacks, and
					scopes read like plain English.
				</p>
			</li>
			<li>
				<svg class="feature-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182m0-4.991v4.99" /></svg>
				<h3>Database migrations</h3>
				<p>
					Version your schema. <code>wheels dbmigrate latest</code> on one side and
					<code>wheels dbmigrate down</code> on the other — always reversible.
				</p>
			</li>
			<li>
				<svg class="feature-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="m6.75 7.5 3 2.25-3 2.25m4.5 0h3m-9 8.25h13.5A2.25 2.25 0 0 0 21 18V6a2.25 2.25 0 0 0-2.25-2.25H5.25A2.25 2.25 0 0 0 3 6v12a2.25 2.25 0 0 0 2.25 2.25Z" /></svg>
				<h3>Modern CLI</h3>
				<p>
					<code>wheels generate</code>, <code>wheels test</code>, <code>wheels server</code> — a first-class
					command-line workflow for every step of development.
				</p>
			</li>
			<li>
				<svg class="feature-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M8.25 3v1.5M4.5 8.25H3m18 0h-1.5M4.5 12H3m18 0h-1.5m-15 3.75H3m18 0h-1.5M8.25 19.5V21M12 3v1.5m0 15V21m3.75-18v1.5m0 15V21m-9-1.5h10.5a2.25 2.25 0 0 0 2.25-2.25V6.75a2.25 2.25 0 0 0-2.25-2.25H6.75A2.25 2.25 0 0 0 4.5 6.75v10.5a2.25 2.25 0 0 0 2.25 2.25Zm.75-12h9v9h-9v-9Z" /></svg>
				<h3>Multi-engine support</h3>
				<p>
					Runs on Lucee 5/6/7, Adobe ColdFusion 2023/2025, and BoxLang. Primary development target
					is Lucee 7.
				</p>
			</li>
			<li>
				<svg class="feature-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M9.813 15.904 9 18.75l-.813-2.846a4.5 4.5 0 0 0-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 0 0 3.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 0 0 3.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 0 0-3.09 3.09ZM18.259 8.715 18 9.75l-.259-1.035a3.375 3.375 0 0 0-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 0 0 2.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 0 0 2.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 0 0-2.456 2.456Z" /></svg>
				<h3>20 years strong</h3>
				<p>
					Started in 2006. Production-ready since 1.0 in 2009. Still actively developed, now as
					Wheels 4.x with modern tooling.
				</p>
			</li>
		</ul>
	</section>
```

**Icons are Heroicons outline v2 (MIT licensed), inlined as SVG with `currentColor` so they respect dark mode.**

- [ ] **Step 2: Update the `.features*` styles in the `<style>` block**

Find the `.features`, `.features__heading`, `.features__grid`, `.features__grid li`, `.features__grid h3`, `.features__grid p`, `.features__grid code` rules and replace with:

```css
	.features {
		max-width: var(--max-width);
		margin: 5rem auto 4rem;
		padding: 0 1.5rem;
	}
	.features__heading {
		font-size: var(--text-3xl);
		text-align: center;
		margin: 0 0 var(--space-6);
		letter-spacing: var(--tracking-tight);
	}
	.features__grid {
		list-style: none;
		padding: 0;
		margin: 0;
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
		gap: var(--space-5);
	}
	.features__grid li {
		padding: var(--space-5);
		background: var(--color-bg);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-lg);
		box-shadow: var(--shadow-sm);
		transition:
			box-shadow 0.15s,
			transform 0.1s;
	}
	.features__grid li:hover {
		box-shadow: var(--shadow);
		transform: translateY(-2px);
	}
	.feature-icon {
		width: 24px;
		height: 24px;
		color: var(--color-brand);
		margin-bottom: var(--space-3);
	}
	.features__grid h3 {
		font-size: var(--text-lg);
		margin: 0 0 var(--space-2);
		font-weight: 600;
	}
	.features__grid p {
		color: var(--color-fg-muted);
		line-height: var(--leading-relaxed);
		margin: 0;
	}
	.features__grid code {
		font-family: var(--font-mono);
		font-size: 0.875em;
		padding: 0.1rem 0.35rem;
		background: var(--color-surface-2);
		border-radius: var(--radius-sm);
	}
```

- [ ] **Step 3: Type check**

Run: `pnpm --filter @wheels-dev/site-landing exec astro check 2>&1 | tail -5`
Expected: 0 errors.

- [ ] **Step 4: Commit**

```bash
git add web/sites/landing/src/pages/index.astro
git commit -m "feat(web/landing): features grid with icons, shadows, hover lift"
```

---

## Task 4: Landing resources block restyle

**Files:**
- Modify: `web/sites/landing/src/pages/index.astro`

- [ ] **Step 1: Replace the resources `<section>` in the template**

Find `<section class="resources">...</section>` and replace with:

```astro
	<section class="resources">
		<div class="resources__inner">
			<h2 class="resources__heading">Where to go next</h2>
			<p class="resources__lede">
				The docs are split across subdomains. Pick where you need to land.
			</p>
			<div class="resources__grid">
				<a class="resource" href="https://guides.wheels.dev/v3-0-0/">
					<span class="resource__domain">guides.wheels.dev</span>
					<h3>Guides</h3>
					<p>
						Step-by-step guides from installation through deployment. v4.0-SNAPSHOT, v3.0, and
						v2.5 all available.
					</p>
					<span class="resource__link">Open →</span>
				</a>
				<a class="resource" href="https://api.wheels.dev/v3-0-0/">
					<span class="resource__domain">api.wheels.dev</span>
					<h3>API reference</h3>
					<p>
						Every function, parameter, and return type. Searchable across 8 framework versions.
					</p>
					<span class="resource__link">Open →</span>
				</a>
				<a class="resource" href="https://blog.wheels.dev/">
					<span class="resource__domain">blog.wheels.dev</span>
					<h3>Blog</h3>
					<p>Release notes, tutorials, and community news from the Wheels core team.</p>
					<span class="resource__link">Open →</span>
				</a>
				<a class="resource" href="https://github.com/wheels-dev/wheels">
					<span class="resource__domain">github.com/wheels-dev</span>
					<h3>Source on GitHub</h3>
					<p>Code, issues, discussions, and contribution guidelines. MIT licensed.</p>
					<span class="resource__link">Open →</span>
				</a>
			</div>
		</div>
	</section>
```

- [ ] **Step 2: Update `.resources*` and `.resource*` styles**

Replace the existing `.resources`, `.resources__heading`, `.resources__grid`, `.resource`, `.resource:hover`, `.resource h3`, `.resource p`, `.resource__link` rules with:

```css
	.resources {
		background: var(--color-surface);
		padding: 4rem 1.5rem;
		margin-top: 4rem;
	}
	.resources__inner {
		max-width: var(--max-width);
		margin: 0 auto;
	}
	.resources__heading {
		font-size: var(--text-3xl);
		text-align: center;
		margin: 0 0 var(--space-3);
		letter-spacing: var(--tracking-tight);
	}
	.resources__lede {
		text-align: center;
		color: var(--color-fg-muted);
		margin: 0 0 var(--space-6);
	}
	.resources__grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
		gap: var(--space-4);
	}
	.resource {
		display: block;
		padding: var(--space-5);
		background: var(--color-bg);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-lg);
		text-decoration: none;
		color: inherit;
		box-shadow: var(--shadow-sm);
		transition:
			box-shadow 0.15s,
			border-color 0.15s,
			transform 0.1s;
	}
	.resource:hover {
		box-shadow: var(--shadow);
		border-color: var(--color-brand);
		transform: translateY(-2px);
		text-decoration: none;
	}
	.resource__domain {
		display: block;
		font-family: var(--font-mono);
		font-size: var(--text-xs);
		color: var(--color-fg-subtle);
		margin-bottom: var(--space-2);
	}
	.resource h3 {
		font-size: var(--text-lg);
		margin: 0 0 var(--space-2);
		font-weight: 600;
	}
	.resource p {
		color: var(--color-fg-muted);
		margin: 0 0 var(--space-3);
		line-height: var(--leading-relaxed);
	}
	.resource__link {
		color: var(--color-brand);
		font-size: var(--text-sm);
		font-weight: 600;
	}
```

- [ ] **Step 3: Type check**

Run: `pnpm --filter @wheels-dev/site-landing exec astro check 2>&1 | tail -5`
Expected: 0 errors.

- [ ] **Step 4: Commit**

```bash
git add web/sites/landing/src/pages/index.astro
git commit -m "feat(web/landing): resources block with warm bg + subdomain tags + card shadows"
```

---

## Task 5: Blog PostCard restyle

**Files:**
- Modify: `web/sites/blog/src/components/PostCard.astro`

- [ ] **Step 1: Replace the entire contents of `web/sites/blog/src/components/PostCard.astro`**

```astro
---
import { formatDate } from '../utils/posts.ts';
import type { Post } from '../utils/posts.ts';

interface Props {
	post: Post;
}
const { post } = Astro.props;
const { data } = post;
---

<article class="card">
	<h2 class="card__title">
		<a href={`/posts/${data.slug}/`}>{data.title}</a>
	</h2>
	<p class="card__meta">
		<span>{data.author}</span>
		<span aria-hidden="true"> · </span>
		<time datetime={data.publishedAt.toISOString()}>
			{formatDate(data.publishedAt)}
		</time>
	</p>
	{data.excerpt && <p class="card__excerpt">{data.excerpt}</p>}
	{
		data.tags.length > 0 && (
			<ul class="card__tags">
				{data.tags.slice(0, 4).map((t) => (
					<li>
						<a href={`/tags/${t}/`}>#{t}</a>
					</li>
				))}
			</ul>
		)
	}
</article>

<style>
	.card {
		padding: var(--space-5);
		background: var(--color-bg);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-lg);
		box-shadow: var(--shadow-sm);
		transition:
			box-shadow 0.15s,
			border-color 0.15s,
			transform 0.1s;
	}
	.card + .card {
		margin-top: var(--space-4);
	}
	.card:hover {
		box-shadow: var(--shadow);
		border-color: var(--color-border-strong);
		transform: translateY(-2px);
	}
	.card__title {
		font-size: var(--text-2xl);
		line-height: var(--leading-tight);
		letter-spacing: var(--tracking-tight);
		margin: 0 0 var(--space-2);
	}
	.card__title a {
		color: var(--color-fg);
		text-decoration: none;
	}
	.card__title a:hover {
		color: var(--color-brand);
	}
	.card__meta {
		color: var(--color-fg-muted);
		font-size: var(--text-sm);
		margin: 0 0 var(--space-3);
	}
	.card__excerpt {
		margin: 0 0 var(--space-3);
		color: var(--color-fg);
		line-height: var(--leading-relaxed);
	}
	.card__tags {
		list-style: none;
		padding: 0;
		margin: 0;
		display: flex;
		gap: var(--space-2);
		flex-wrap: wrap;
	}
	.card__tags a {
		display: inline-block;
		padding: 0.15rem 0.6rem;
		background: var(--color-brand-soft);
		color: var(--color-brand-ink);
		border-radius: var(--radius-pill);
		font-size: var(--text-xs);
		text-decoration: none;
		font-weight: 500;
	}
	.card__tags a:hover {
		background: var(--color-brand);
		color: #fff;
	}
</style>
```

- [ ] **Step 2: Type check**

Run: `pnpm --filter @wheels-dev/site-blog exec astro check 2>&1 | tail -5`
Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add web/sites/blog/src/components/PostCard.astro
git commit -m "feat(web/blog): PostCard with shadows, hover lift, tag pills"
```

---

## Task 6: Blog index page — RSS pill

**Files:**
- Modify: `web/sites/blog/src/pages/index.astro`

- [ ] **Step 1: Replace the entire contents of `web/sites/blog/src/pages/index.astro`**

```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
import PostCard from '../components/PostCard.astro';
import RssPill from '@wheels-dev/ui/components/RssPill.astro';
import { getAllPosts } from '../utils/posts.ts';

const posts = await getAllPosts();
const pageSize = 10;
const pagePosts = posts.slice(0, pageSize);
const totalPages = Math.ceil(posts.length / pageSize);
---

<BaseLayout
	title="Wheels Blog"
	description="News, tutorials, and release announcements for Wheels."
>
	<header class="blog-header">
		<div>
			<h1>Wheels Blog</h1>
			<p class="lede">
				News, tutorials, and release announcements for the Wheels CFML MVC framework.
			</p>
		</div>
		<RssPill href="/rss.xml" label="RSS" />
	</header>

	{pagePosts.map((post) => <PostCard post={post} />)}

	{
		totalPages > 1 && (
			<nav class="pager" aria-label="Pagination">
				<a href="/page/2/">Older posts →</a>
			</nav>
		)
	}

	<style>
		.blog-header {
			display: flex;
			justify-content: space-between;
			align-items: flex-start;
			gap: var(--space-4);
			flex-wrap: wrap;
			margin-bottom: var(--space-6);
		}
		.blog-header h1 {
			margin: 0 0 var(--space-2);
			letter-spacing: var(--tracking-tight);
		}
		.lede {
			color: var(--color-fg-muted);
			margin: 0;
		}
		.pager {
			margin-top: var(--space-6);
			display: flex;
			justify-content: space-between;
		}
		.pager a {
			color: var(--color-brand);
			text-decoration: none;
			font-weight: 600;
		}
	</style>
</BaseLayout>
```

**Key changes:**
- New `<header class="blog-header">` wrapping the title + RSS pill with flex layout.
- Uses `RssPill` from `@wheels-dev/ui`.

- [ ] **Step 2: Type check**

Run: `pnpm --filter @wheels-dev/site-blog exec astro check 2>&1 | tail -5`
Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add web/sites/blog/src/pages/index.astro
git commit -m "feat(web/blog): blog index RSS pill + header polish"
```

---

## Task 7: Blog PostLayout restyle

**Files:**
- Modify: `web/sites/blog/src/layouts/PostLayout.astro`

- [ ] **Step 1: Replace the entire contents of `web/sites/blog/src/layouts/PostLayout.astro`**

```astro
---
import BaseLayout from './BaseLayout.astro';
import { formatDate } from '../utils/posts.ts';
import type { Post } from '../utils/posts.ts';
import Giscus from '../components/Giscus.astro';
import RssPill from '@wheels-dev/ui/components/RssPill.astro';

interface Props {
	post: Post;
}
const { post } = Astro.props;
const { data } = post;
const eyebrow = data.categories && data.categories.length > 0 ? data.categories[0] : null;
---

<BaseLayout title={`${data.title} | Wheels Blog`} description={data.excerpt}>
	<article class="post">
		<header class="post__header">
			<div class="post__eyebrow-row">
				{eyebrow && <span class="post__eyebrow">{eyebrow}</span>}
				<RssPill href="/rss.xml" label="RSS" class="post__rss" />
			</div>
			<h1 class="post__title">{data.title}</h1>
			<p class="post__meta">
				<span>{data.author}</span>
				<span aria-hidden="true"> · </span>
				<time datetime={data.publishedAt.toISOString()}>
					{formatDate(data.publishedAt)}
				</time>
			</p>
		</header>

		{data.coverImage && <img class="post__cover" src={data.coverImage} alt="" />}

		<div class="post__body prose">
			<slot />
		</div>

		{
			data.tags.length > 0 && (
				<ul class="post__tags">
					{data.tags.map((t) => (
						<li>
							<a href={`/tags/${t}/`}>#{t}</a>
						</li>
					))}
				</ul>
			)
		}
	</article>

	<Giscus />

	<style>
		.post {
			max-width: var(--max-width-prose);
			margin: 0 auto;
		}
		.post__header {
			margin-bottom: var(--space-6);
		}
		.post__eyebrow-row {
			display: flex;
			justify-content: space-between;
			align-items: center;
			gap: var(--space-3);
			margin-bottom: var(--space-3);
			flex-wrap: wrap;
		}
		.post__eyebrow {
			font-size: var(--text-xs);
			font-weight: 700;
			text-transform: uppercase;
			letter-spacing: 0.08em;
			color: var(--color-brand);
		}
		.post__title {
			font-size: var(--text-4xl);
			line-height: var(--leading-tight);
			letter-spacing: var(--tracking-tight);
			margin: 0 0 var(--space-3);
		}
		.post__meta {
			color: var(--color-fg-muted);
			font-size: var(--text-sm);
			margin: 0;
		}
		.post__cover {
			width: 100%;
			border-radius: var(--radius-lg);
			margin-bottom: var(--space-6);
			box-shadow: var(--shadow-sm);
		}
		.post__body {
			margin-bottom: var(--space-7);
		}
		.post__tags {
			list-style: none;
			padding: var(--space-5) 0 0;
			margin: 0;
			border-top: 1px solid var(--color-border);
			display: flex;
			gap: var(--space-2);
			flex-wrap: wrap;
		}
		.post__tags a {
			display: inline-block;
			padding: 0.15rem 0.6rem;
			background: var(--color-brand-soft);
			color: var(--color-brand-ink);
			border-radius: var(--radius-pill);
			font-size: var(--text-xs);
			text-decoration: none;
			font-weight: 500;
		}
		.post__tags a:hover {
			background: var(--color-brand);
			color: #fff;
		}
	</style>
</BaseLayout>
```

**Key changes:**
- `.post` uses `--max-width-prose` (68ch) for reading measure.
- New `.post__eyebrow-row` showing the first category as a red uppercase label + RSS pill on the right.
- Cover image moved above body with shadow.
- `.post__body` now gets `.prose` class from `base.css` for consistent long-form styling; inline `pre`/`h2`/`img` overrides dropped.
- Tags moved to bottom of post above the fold-break, styled as pills.

- [ ] **Step 2: Type check**

Run: `pnpm --filter @wheels-dev/site-blog exec astro check 2>&1 | tail -5`
Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add web/sites/blog/src/layouts/PostLayout.astro
git commit -m "feat(web/blog): PostLayout with prose width, eyebrow, RSS pill, tag pills"
```

---

## Task 8: NewsletterSignup restyle

**Files:**
- Modify: `web/sites/blog/src/components/NewsletterSignup.astro`

- [ ] **Step 1: Replace the entire contents of `web/sites/blog/src/components/NewsletterSignup.astro`**

```astro
---
const username = 'wheelsdev';
const action = `https://buttondown.com/api/emails/embed-subscribe/${username}`;
---

<section class="newsletter" aria-label="Newsletter signup">
	<h2>Newsletter</h2>
	<p class="newsletter__lede">Release notes and new posts, once a month. No spam.</p>
	<form
		action={action}
		method="post"
		target="popupwindow"
		onsubmit={`window.open('https://buttondown.com/${username}', 'popupwindow')`}
		class="newsletter__form"
	>
		<label class="sr-only" for="bd-email">Email</label>
		<input type="email" id="bd-email" name="email" placeholder="you@example.com" required />
		<button type="submit" class="btn btn--primary">Subscribe</button>
	</form>
	<p class="newsletter__rss">
		Prefer RSS? <a href="/rss.xml">Subscribe to the feed →</a>
	</p>
</section>

<style>
	.newsletter {
		max-width: 720px;
		margin: var(--space-7) auto;
		padding: var(--space-6);
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-lg);
	}
	.newsletter h2 {
		font-size: var(--text-xl);
		margin: 0 0 var(--space-2);
	}
	.newsletter__lede {
		color: var(--color-fg-muted);
		margin: 0 0 var(--space-4);
	}
	.newsletter__form {
		display: flex;
		gap: var(--space-2);
		flex-wrap: wrap;
	}
	.newsletter__form input {
		flex: 1 1 240px;
		padding: var(--space-3) var(--space-4);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-pill);
		font: inherit;
		background: var(--color-bg);
		color: var(--color-fg);
	}
	.newsletter__form input:focus {
		outline: none;
		border-color: var(--color-brand);
		box-shadow: 0 0 0 3px var(--color-brand-soft);
	}
	.newsletter__rss {
		margin: var(--space-4) 0 0;
		font-size: var(--text-sm);
		color: var(--color-fg-muted);
	}
	.newsletter__rss a {
		color: var(--color-brand);
		font-weight: 600;
	}
	.sr-only {
		position: absolute;
		width: 1px;
		height: 1px;
		padding: 0;
		margin: -1px;
		overflow: hidden;
		clip: rect(0, 0, 0, 0);
		white-space: nowrap;
		border: 0;
	}
</style>
```

**Key changes:**
- Background now `--color-surface` (warm off-white).
- Input is pill-shaped with focus ring.
- Button reuses `.btn .btn--primary` from `base.css` (removing local button styles).
- New `.newsletter__rss` secondary line with "Prefer RSS?" link.

- [ ] **Step 2: Type check**

Run: `pnpm --filter @wheels-dev/site-blog exec astro check 2>&1 | tail -5`
Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add web/sites/blog/src/components/NewsletterSignup.astro
git commit -m "feat(web/blog): NewsletterSignup with warm surface, pill input, RSS secondary"
```

---

## Task 9: Starlight Header override

**Files:**
- Create: `web/packages/ui/src/components/starlight/Header.astro`
- Modify: `web/packages/ui/package.json`

- [ ] **Step 1: Create the directory and file**

```bash
mkdir -p web/packages/ui/src/components/starlight
```

- [ ] **Step 2: Create `web/packages/ui/src/components/starlight/Header.astro`**

```astro
---
import Header from '../Header.astro';

// Starlight passes route data via Astro.locals.starlightRoute.
// We infer which Wheels site we're on from the `site` URL, falling back to the
// directory name so this override works both on guides.wheels.dev and
// api.wheels.dev without per-site customization.
const site = Astro.site?.hostname ?? '';
let current: 'landing' | 'guides' | 'api' | 'blog' = 'landing';
if (site.startsWith('guides')) current = 'guides';
else if (site.startsWith('api')) current = 'api';
else if (site.startsWith('blog')) current = 'blog';
---

<Header current={current} />
```

This component replaces Starlight's default top bar. Starlight discovers it via `components: { Header: '@wheels-dev/ui/components/starlight/Header.astro' }` in each site's `astro.config.mjs`.

- [ ] **Step 3: Add to package exports in `web/packages/ui/package.json`**

Add to the `exports` object:
```json
"./components/starlight/Header.astro": "./src/components/starlight/Header.astro",
```

- [ ] **Step 4: Commit**

```bash
git add web/packages/ui/src/components/starlight/Header.astro web/packages/ui/package.json
git commit -m "feat(web/starlight): Header override that wraps shared Header with per-site current"
```

---

## Task 10: Starlight Footer override

**Files:**
- Create: `web/packages/ui/src/components/starlight/Footer.astro`
- Modify: `web/packages/ui/package.json`

- [ ] **Step 1: Create `web/packages/ui/src/components/starlight/Footer.astro`**

```astro
---
import Footer from '../Footer.astro';
---

<Footer />
```

Starlight's default Footer slot gets replaced with our shared Footer.

- [ ] **Step 2: Add to `exports` in `web/packages/ui/package.json`**

Add:
```json
"./components/starlight/Footer.astro": "./src/components/starlight/Footer.astro",
```

- [ ] **Step 3: Commit**

```bash
git add web/packages/ui/src/components/starlight/Footer.astro web/packages/ui/package.json
git commit -m "feat(web/starlight): Footer override that wraps shared Footer"
```

---

## Task 11: Starlight SocialIcons override

**Files:**
- Create: `web/packages/ui/src/components/starlight/SocialIcons.astro`
- Modify: `web/packages/ui/package.json`

Starlight renders its own `SocialIcons` inside its default Header. Because we've replaced the Header with our own, the SocialIcons component wouldn't appear — but Starlight still expects it at `components.SocialIcons`, and some Starlight internals query it. We provide a minimal override that renders nothing (our shared Header already carries a GitHub link).

- [ ] **Step 1: Create `web/packages/ui/src/components/starlight/SocialIcons.astro`**

```astro
---
// Intentionally empty. The shared Header component already renders a GitHub link;
// Starlight's default SocialIcons would be a duplicate.
---
```

- [ ] **Step 2: Add to `exports` in `web/packages/ui/package.json`**

Add:
```json
"./components/starlight/SocialIcons.astro": "./src/components/starlight/SocialIcons.astro",
```

The final `exports` block (after Tasks 1, 9, 10, 11) should be:
```json
"exports": {
  "./components/Header.astro": "./src/components/Header.astro",
  "./components/Footer.astro": "./src/components/Footer.astro",
  "./components/Logo.astro": "./src/components/Logo.astro",
  "./components/RssPill.astro": "./src/components/RssPill.astro",
  "./components/starlight/Header.astro": "./src/components/starlight/Header.astro",
  "./components/starlight/Footer.astro": "./src/components/starlight/Footer.astro",
  "./components/starlight/SocialIcons.astro": "./src/components/starlight/SocialIcons.astro",
  "./styles/tokens.css": "./src/styles/tokens.css",
  "./styles/base.css": "./src/styles/base.css",
  "./styles/starlight-theme.css": "./src/styles/starlight-theme.css",
  "./assets/*": "./src/assets/*"
},
```

- [ ] **Step 3: Re-link**

Run from worktree root: `pnpm install`
Expected: Done in Nms.

- [ ] **Step 4: Commit**

```bash
git add web/packages/ui/src/components/starlight/SocialIcons.astro web/packages/ui/package.json
git commit -m "feat(web/starlight): empty SocialIcons override (shared Header has GitHub link)"
```

---

## Task 12: Wire guides Starlight config

**Files:**
- Modify: `web/sites/guides/astro.config.mjs`

- [ ] **Step 1: Edit `web/sites/guides/astro.config.mjs`**

Find the `starlight({...})` call. Currently it has `title`, `description`, `social`, and `sidebar`. Add `customCss` and `components` keys so the final call looks like this:

```js
starlight({
  title: 'Wheels Guides',
  description: 'Official guides for the Wheels CFML MVC framework.',
  customCss: [
    '@wheels-dev/ui/styles/tokens.css',
    '@wheels-dev/ui/styles/base.css',
    '@wheels-dev/ui/styles/starlight-theme.css',
  ],
  components: {
    Header: '@wheels-dev/ui/components/starlight/Header.astro',
    Footer: '@wheels-dev/ui/components/starlight/Footer.astro',
    SocialIcons: '@wheels-dev/ui/components/starlight/SocialIcons.astro',
  },
  social: [
    { icon: 'github', label: 'GitHub', href: 'https://github.com/wheels-dev/wheels' },
  ],
  sidebar: [
    { label: 'Overview', link: '/' },
    ...versions.map(buildSidebarForVersion),
  ],
}),
```

**Key:** the `customCss` array order matters — tokens must come before base and theme.

- [ ] **Step 2: Type check + build guides**

Run:
```bash
pnpm --filter @wheels-dev/site-guides exec astro check 2>&1 | tail -5
pnpm --filter @wheels-dev/site-guides build 2>&1 | tail -10
```

Expected: 0 errors on check; build succeeds.

- [ ] **Step 3: Commit**

```bash
git add web/sites/guides/astro.config.mjs
git commit -m "feat(web/guides): wire Starlight header/footer/socials + theme customCss"
```

---

## Task 13: Wire api Starlight config

**Files:**
- Modify: `web/sites/api/astro.config.mjs`

- [ ] **Step 1: Edit `web/sites/api/astro.config.mjs`**

Add `customCss` and `components` keys to the `starlight({...})` call. Final shape:

```js
starlight({
  title: 'Wheels API Reference',
  description: 'Function reference for the Wheels CFML MVC framework.',
  customCss: [
    '@wheels-dev/ui/styles/tokens.css',
    '@wheels-dev/ui/styles/base.css',
    '@wheels-dev/ui/styles/starlight-theme.css',
  ],
  components: {
    Header: '@wheels-dev/ui/components/starlight/Header.astro',
    Footer: '@wheels-dev/ui/components/starlight/Footer.astro',
    SocialIcons: '@wheels-dev/ui/components/starlight/SocialIcons.astro',
  },
  social: [
    { icon: 'github', label: 'GitHub', href: 'https://github.com/wheels-dev/wheels' },
  ],
  sidebar: [
    { label: 'Overview', link: '/' },
    ...versions.map((v) => ({
      label: v.label,
      autogenerate: { directory: v.slug },
      collapsed: v.collapsed,
    })),
  ],
}),
```

- [ ] **Step 2: Type check + build api**

Run:
```bash
pnpm --filter @wheels-dev/site-api exec astro check 2>&1 | tail -5
pnpm --filter @wheels-dev/site-api build 2>&1 | tail -10
```

Expected: 0 errors; build succeeds.

- [ ] **Step 3: Commit**

```bash
git add web/sites/api/astro.config.mjs
git commit -m "feat(web/api): wire Starlight header/footer/socials + theme customCss"
```

---

## Task 14: Full build + format

**Files:** (none modified in tasks; this is a verification + format gate)

- [ ] **Step 1: Run prettier format across the tree**

Run from the `web/` directory: `pnpm format`

If any files are reformatted, inspect the diff before committing. Prettier may touch line breaks in the files you edited; these are safe to accept.

- [ ] **Step 2: Full build of all 4 sites**

Run: `pnpm build`

Expected: all four sites report `[build] Complete!` and no Rollup/vite errors.

- [ ] **Step 3: Full astro check of all 4 sites in sequence**

```bash
pnpm --filter @wheels-dev/site-landing exec astro check
pnpm --filter @wheels-dev/site-blog exec astro check
pnpm --filter @wheels-dev/site-guides exec astro check
pnpm --filter @wheels-dev/site-api exec astro check
```

Expected: each reports `0 errors`.

- [ ] **Step 4: Format check**

Run: `pnpm format:check`
Expected: "All matched files use Prettier code style!"

- [ ] **Step 5: Commit if any format changes landed**

```bash
git status
# if there are changes, add them all and commit:
git add -u
git commit -m "style(web): prettier format pass"
```

---

## Task 15: Visual parity verification

**Files:** (none modified)

This task confirms all four sites share an identical top chrome.

- [ ] **Step 1: Start each dev server in turn and screenshot the top 200px**

Use the Claude Preview MCP tool (or equivalent browser automation):

For each of `web-landing` (port 4321), `web-blog` (port 4322), `web-guides` (port 4323), `web-api` (port 4324):
1. Start the server via `preview_start` (launch.json entries may need to be added for guides and api — follow the same pattern as `web-landing` in `.claude/launch.json`).
2. Resize viewport to 1280x800, color scheme = light.
3. Screenshot.
4. Stop server.

- [ ] **Step 2: Compare headers**

Open all four screenshots side by side. The `wheels.dev` logo + wordmark on the left and the nav links on the right must match pixel-for-pixel. The only difference should be which nav link is bold + red (Home / Guides / API / Blog).

- [ ] **Step 3: Quick UX spot-checks**

On each Starlight site (guides, api):
- Scroll past the top — our Header's sticky-shadow transition should fire.
- Click the logo — should navigate to `https://wheels.dev/`.
- Open the mobile width (<720px) — hamburger drawer should open.
- Open a deep docs page (e.g., `/v3-0-0/something/`) — sidebar + content still render (Starlight internals intact).

On blog:
- Confirm RSS pill is visible in the listing header area.
- Click a post; confirm RSS pill appears in the post header and NewsletterSignup shows "Prefer RSS?" secondary line at the bottom.

On landing:
- Hero has an eyebrow label above title ("A Rails-inspired framework for CFML").
- CTAs are pill-shaped.
- "Runs on Lucee 7, Adobe ColdFusion 2023/2025, and BoxLang." caption is below the install snippet.
- Features grid: every card has a red line icon and lifts on hover.
- Resources block: warm off-white bg; each card has a monospace subdomain label.

No commits — this is verification only. If issues are found, fix the underlying source and re-verify.

---

## Task 16: Push branch and open PR

**Files:** (none modified)

- [ ] **Step 1: Review commit log**

Run: `git log --oneline origin/develop..HEAD`

Expected: approximately 14-16 commits with scopes matching the task breakdown (`feat(web/ui)`, `feat(web/landing)`, `feat(web/blog)`, `feat(web/starlight)`, `feat(web/guides)`, `feat(web/api)`, plus any `style(web)` format pass).

- [ ] **Step 2: Push the branch**

```bash
git push -u origin peter/web-cohesion-polish
```

- [ ] **Step 3: Open the PR against `develop`**

```bash
gh pr create --base develop --title "feat(web): visual polish + starlight phase 2 cohesion" --body "$(cat <<'EOF'
## Summary

PR 2 of 3 rolling out the wheels.dev multi-site cohesion design ([spec](docs/superpowers/specs/2026-04-17-wheels-dev-cohesion-design.md)). Builds on [#2152](https://github.com/wheels-dev/wheels/pull/2152).

Every site now looks like it belongs to the same property. Guides and api share the identical top chrome with landing and blog via Starlight component overrides; each site's content gets the warm-palette visual polish.

### What changed

**`@wheels-dev/ui` additions:**
- \`RssPill.astro\` — small pill-shaped RSS button, used by blog
- \`starlight/Header.astro\` — wraps shared Header, derives \`current\` from site hostname
- \`starlight/Footer.astro\` — wraps shared Footer
- \`starlight/SocialIcons.astro\` — empty override (shared Header carries GitHub link)

**Landing:**
- Hero: eyebrow label, pill-shaped CTAs (now from \`base.css\`), gradient bg, engine-compat caption
- Features grid: red line icons (Heroicons outline), card shadows, hover lift
- Resources: warm off-white section, subdomain tags per card, card shadows, hover border

**Blog:**
- PostCard: card shadows + hover lift + pill tags
- Index page: RSS pill in listing header
- PostLayout: prose-width reading measure, category eyebrow, RSS pill in header, tag pills at bottom
- NewsletterSignup: warm surface, pill input with focus ring, "Prefer RSS?" secondary line

**Guides + api:**
- \`astro.config.mjs\`: add \`customCss\` (tokens + base + starlight-theme) and \`components\` (Header/Footer/SocialIcons overrides)

### Test plan

- [x] \`pnpm build\` — all four sites build cleanly
- [x] \`pnpm format:check\` — passes
- [x] All four sites: \`astro check\` reports 0 errors
- [x] Landing renders with new hero + features icons + resources warm bg
- [x] Blog index has RSS pill in listing area
- [x] Blog post page has category eyebrow + RSS pill + prose-width body + tag pills at bottom
- [x] Guides + api share identical header with landing + blog
- [x] Starlight sidebar + content still render on docs pages (search, version switching, edit-on-github unchanged)
- [ ] Reviewer: spot-check mobile drawer behavior + dark mode

### Follow-ups

- [ ] PR 3: Starlight Phase 3 — custom layout (PageFrame, Sidebar, PageTitle, TOC, VersionSwitcher, EditLink)
- [ ] Button \`:focus-visible\` / \`:active\` states (a11y polish)
- [ ] SVG conversion of the logo mark

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Expected: returns a PR URL.

---

## Self-Review

**Spec coverage check:**

| Spec section | Task(s) |
|---|---|
| §4 RssPill helper | Task 1 |
| §5 Landing hero (eyebrow, gradient, pill CTAs, engine caption) | Task 2 |
| §5 Landing features (icons + shadows) | Task 3 |
| §5 Landing resources (warm bg, intro, subdomain tags) | Task 4 |
| §6 Blog post list shadows + tag pills | Task 5 |
| §6 Blog listing RSS pill | Task 6 |
| §6 Blog PostLayout (eyebrow, tag pills, RSS, prose width) | Task 7 |
| §6 NewsletterSignup (warm bg, pill input, RSS secondary) | Task 8 |
| §7 Starlight Header/Footer/SocialIcons overrides | Tasks 9, 10, 11 |
| §7 Starlight config (customCss + components) | Tasks 12, 13 |
| §9 PR 2 rollout | Tasks 1–16 (this plan) |
| §10 Test matrix | Task 14, 15 |

**Placeholder scan:** no TBD / "implement later" / "similar to Task N". Each code block has the complete content to paste.

**Type consistency:**
- `Header` component's `current` prop accepts `'landing' | 'guides' | 'api' | 'blog'` — Task 9's override derives `current` from `Astro.site.hostname`, matching the existing interface.
- `RssPill` props (`href`, `label`, `class`) are reused in Tasks 6 and 7 with matching names.
- `.btn .btn--primary` / `.btn--secondary` classes used in Tasks 2 and 8 are defined in `base.css` (shipped in PR 1).

**Deferred (called out, not blocking):**
- Post-frontmatter `categories` may not exist on every blog post — Task 7 guards with `data.categories && data.categories.length > 0` before accessing.
- Task 15 requires `web-guides` and `web-api` entries in `.claude/launch.json` — the engineer adds them ad-hoc if the preview tool isn't already configured for those ports.
- Visual regression screenshot automation is deferred to PR 3.

**Risks:**
- If `Astro.site` isn't set on a Starlight site at SSG time, the `current` detection in `starlight/Header.astro` falls back to `'landing'`. This is benign (visible as an unhighlighted nav) but worth knowing. The `site:` key in each Starlight site's `astro.config.mjs` should already be set (it is — guides has `site: 'https://guides.wheels.dev'`, api has `site: 'https://api.wheels.dev'`).
- `customCss` order matters — putting `starlight-theme.css` before `tokens.css` would mean the bridge file references undefined `--color-*` variables. Task 12 and 13 explicitly order them tokens → base → theme.
