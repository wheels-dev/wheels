# Web Cohesion — Brand Foundation (PR 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the brand foundation in `web/packages/ui` — expanded design tokens, a shared Logo component, rebuilt Header and Footer, a base stylesheet, and a Starlight theme bridge file — so subsequent PRs can roll the brand through every site.

**Architecture:** Everything brand-related lives in `@wheels-dev/ui`. Sites consume it by import. This PR updates the package and wires the new `base.css` into landing + blog layouts so they visually pick up the refreshed chrome. Guides and api are not touched. New files are created alongside existing ones; the package's `exports` map is expanded.

**Tech Stack:** Astro 5, pnpm workspaces, CSS custom properties (no preprocessor), plain `.astro` components.

**Reference spec:** [`docs/superpowers/specs/2026-04-17-wheels-dev-cohesion-design.md`](../specs/2026-04-17-wheels-dev-cohesion-design.md)

**Branch:** `claude/keen-torvalds-4e016b` (current worktree) — landing branch for the PR against `develop`.

---

## File Structure

**New files:**
- `web/packages/ui/src/assets/wheels-logo-mark.png` — raster logo mark (copied from `wheels-dev/wheels.dev`)
- `web/packages/ui/src/assets/wheels-logo.png` — full lockup raster
- `web/packages/ui/src/assets/wheels-logo-white.png` — lockup for dark backgrounds
- `web/packages/ui/src/components/Logo.astro` — mark + lockup component
- `web/packages/ui/src/styles/base.css` — element resets, button styles, `.prose`
- `web/packages/ui/src/styles/starlight-theme.css` — token bridge (scaffold only; not imported in PR 1)

**Modified files:**
- `web/packages/ui/src/styles/tokens.css` — expanded token set
- `web/packages/ui/src/components/Header.astro` — rebuilt with Logo + sticky + mobile drawer
- `web/packages/ui/src/components/Footer.astro` — rebuilt with 3-column + bottom bar
- `web/packages/ui/package.json` — expand `exports` map
- `web/sites/landing/src/layouts/BaseLayout.astro` — import `base.css`
- `web/sites/blog/src/layouts/BaseLayout.astro` — import `base.css`

**Not touched in this PR:**
- `web/sites/guides/*`
- `web/sites/api/*`
- Any content, RSS, or site-specific component

---

## Task 1: Expand the `@wheels-dev/ui` package exports

**Files:**
- Modify: `web/packages/ui/package.json`

Before adding new files, make them reachable from sites via the package's `exports` map.

- [ ] **Step 1: Replace the `exports` block in `web/packages/ui/package.json`**

Current contents (lines 6-10):
```json
"exports": {
  "./components/Header.astro": "./src/components/Header.astro",
  "./components/Footer.astro": "./src/components/Footer.astro",
  "./styles/tokens.css": "./src/styles/tokens.css"
},
```

Replace with:
```json
"exports": {
  "./components/Header.astro": "./src/components/Header.astro",
  "./components/Footer.astro": "./src/components/Footer.astro",
  "./components/Logo.astro": "./src/components/Logo.astro",
  "./styles/tokens.css": "./src/styles/tokens.css",
  "./styles/base.css": "./src/styles/base.css",
  "./styles/starlight-theme.css": "./src/styles/starlight-theme.css",
  "./assets/*": "./src/assets/*"
},
```

- [ ] **Step 2: Verify JSON is valid**

Run: `cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b/web && node -e "JSON.parse(require('fs').readFileSync('packages/ui/package.json','utf8'))"`
Expected: no output (no exception thrown).

- [ ] **Step 3: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b
git add web/packages/ui/package.json
git commit -m "feat(web/ui): expand package exports for logo, base, starlight-theme"
```

---

## Task 2: Expand design tokens

**Files:**
- Modify: `web/packages/ui/src/styles/tokens.css`

- [ ] **Step 1: Replace the entire contents of `web/packages/ui/src/styles/tokens.css`**

```css
:root {
	/* ── Brand ─────────────────────────────────────────────── */
	--color-brand: #e63946;
	--color-brand-hover: #d12d3a;
	--color-brand-soft: #fef2f2;
	--color-brand-ink: #7a1820;

	/* ── Surface (light) ──────────────────────────────────── */
	--color-bg: #ffffff;
	--color-surface: #fafaf7;
	--color-surface-2: #f3f1ec;
	--color-border: #e8e5df;
	--color-border-strong: #d4d0c6;

	/* ── Text (light) ─────────────────────────────────────── */
	--color-fg: #1a1a1a;
	--color-fg-muted: #6b6b68;
	--color-fg-subtle: #9a9893;

	/* ── Feedback ─────────────────────────────────────────── */
	--color-success: #2f855a;
	--color-warning: #b45309;
	--color-danger: var(--color-brand);

	/* ── Legacy alias (do not remove until all sites migrated) ── */
	--color-accent: var(--color-brand);
	--color-muted: var(--color-fg-muted);

	/* ── Type ─────────────────────────────────────────────── */
	--font-sans: 'Inter', system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
	--font-mono: 'JetBrains Mono', ui-monospace, 'SF Mono', Menlo, monospace;
	--font-display: var(--font-sans);

	--text-xs: 0.75rem;
	--text-sm: 0.875rem;
	--text-base: 1rem;
	--text-lg: 1.125rem;
	--text-xl: 1.25rem;
	--text-2xl: 1.5rem;
	--text-3xl: 1.875rem;
	--text-4xl: 2.25rem;
	--text-5xl: clamp(2.5rem, 5vw, 3.75rem);

	--leading-tight: 1.15;
	--leading-normal: 1.55;
	--leading-relaxed: 1.7;
	--tracking-tight: -0.02em;
	--tracking-normal: 0;

	/* ── Space (4px base) ─────────────────────────────────── */
	--space-1: 0.25rem;
	--space-2: 0.5rem;
	--space-3: 0.75rem;
	--space-4: 1rem;
	--space-5: 1.5rem;
	--space-6: 2rem;
	--space-7: 3rem;
	--space-8: 4rem;
	--space-9: 6rem;

	/* ── Radius ───────────────────────────────────────────── */
	--radius-sm: 0.25rem;
	--radius: 0.5rem;
	--radius-lg: 0.75rem;
	--radius-xl: 1rem;
	--radius-pill: 999px;

	/* ── Shadow ───────────────────────────────────────────── */
	--shadow-sm: 0 1px 2px rgb(0 0 0 / 0.04);
	--shadow: 0 4px 12px rgb(0 0 0 / 0.06);
	--shadow-lg: 0 12px 32px rgb(0 0 0 / 0.08);

	/* ── Layout ───────────────────────────────────────────── */
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
		--shadow-sm: 0 1px 2px rgb(0 0 0 / 0.3);
		--shadow: 0 4px 12px rgb(0 0 0 / 0.4);
		--shadow-lg: 0 12px 32px rgb(0 0 0 / 0.5);
	}
}
```

**Note:** `--color-accent` and `--color-muted` are preserved as aliases so existing code that references them (e.g., `landing/src/pages/index.astro`) keeps working.

- [ ] **Step 2: Verify tokens parse by running format check**

Run: `cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b/web && pnpm format:check --loglevel=silent packages/ui/src/styles/tokens.css 2>&1 || pnpm exec prettier --write packages/ui/src/styles/tokens.css`

Expected: either passes the check, or prettier rewrites formatting cleanly. If it rewrites, that's fine — the token *values* are what matter.

- [ ] **Step 3: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b
git add web/packages/ui/src/styles/tokens.css
git commit -m "feat(web/ui): expand design tokens with warm palette, type scale, shadows"
```

---

## Task 3: Create `base.css` with element resets and `.prose`

**Files:**
- Create: `web/packages/ui/src/styles/base.css`

- [ ] **Step 1: Create `web/packages/ui/src/styles/base.css` with the following contents**

```css
/*
 * Wheels base stylesheet — element resets, buttons, and prose.
 * Depends on tokens.css; import both in site layouts.
 */

*,
*::before,
*::after {
	box-sizing: border-box;
}

html,
body {
	margin: 0;
	padding: 0;
	background: var(--color-bg);
	color: var(--color-fg);
	font-family: var(--font-sans);
	font-size: var(--text-base);
	line-height: var(--leading-normal);
	-webkit-font-smoothing: antialiased;
	-moz-osx-font-smoothing: grayscale;
}

a {
	color: var(--color-brand);
	text-decoration: none;
}

a:hover {
	text-decoration: underline;
}

img,
svg,
video {
	max-width: 100%;
	display: block;
}

/* ── Buttons ──────────────────────────────────────────────── */

.btn {
	display: inline-flex;
	align-items: center;
	gap: var(--space-2);
	padding: var(--space-3) var(--space-5);
	border-radius: var(--radius-pill);
	font-family: var(--font-sans);
	font-weight: 600;
	font-size: var(--text-sm);
	line-height: 1;
	text-decoration: none;
	border: 1px solid transparent;
	cursor: pointer;
	transition:
		transform 0.1s,
		box-shadow 0.1s,
		background 0.15s;
}

.btn:hover {
	text-decoration: none;
	transform: translateY(-1px);
}

.btn--primary {
	background: var(--color-brand);
	color: #fff;
	box-shadow: var(--shadow-sm);
}

.btn--primary:hover {
	background: var(--color-brand-hover);
	box-shadow: var(--shadow);
}

.btn--secondary {
	background: transparent;
	color: var(--color-brand);
	border-color: var(--color-brand);
}

.btn--secondary:hover {
	background: var(--color-brand-soft);
}

.btn--ghost {
	background: transparent;
	color: var(--color-fg);
	border-color: var(--color-border);
}

.btn--ghost:hover {
	background: var(--color-surface);
}

/* ── Prose (long-form reading) ───────────────────────────── */

.prose {
	max-width: var(--max-width-prose);
	font-size: var(--text-base);
	line-height: var(--leading-relaxed);
	color: var(--color-fg);
}

.prose > * + * {
	margin-top: var(--space-4);
}

.prose h1,
.prose h2,
.prose h3,
.prose h4 {
	font-family: var(--font-display);
	letter-spacing: var(--tracking-tight);
	line-height: var(--leading-tight);
	margin-top: var(--space-7);
	margin-bottom: var(--space-3);
}

.prose h1 {
	font-size: var(--text-4xl);
	font-weight: 700;
}

.prose h2 {
	font-size: var(--text-3xl);
	font-weight: 700;
}

.prose h3 {
	font-size: var(--text-xl);
	font-weight: 600;
}

.prose h4 {
	font-size: var(--text-lg);
	font-weight: 600;
}

.prose a {
	color: var(--color-brand);
	text-decoration: underline;
	text-underline-offset: 0.2em;
}

.prose blockquote {
	margin: var(--space-5) 0;
	padding: var(--space-4) var(--space-5);
	border-left: 3px solid var(--color-brand);
	background: var(--color-surface-2);
	border-radius: 0 var(--radius) var(--radius) 0;
	color: var(--color-fg-muted);
}

.prose code {
	font-family: var(--font-mono);
	font-size: 0.875em;
	padding: 0.1em 0.35em;
	background: var(--color-surface-2);
	border-radius: var(--radius-sm);
}

.prose pre {
	background: #111;
	color: #e5e5e5;
	padding: var(--space-4) var(--space-5);
	border-radius: var(--radius-lg);
	overflow-x: auto;
	font-family: var(--font-mono);
	font-size: var(--text-sm);
	line-height: var(--leading-normal);
}

.prose pre code {
	background: transparent;
	color: inherit;
	padding: 0;
	font-size: inherit;
}

.prose ul,
.prose ol {
	padding-left: var(--space-5);
}

.prose li + li {
	margin-top: var(--space-2);
}

.prose img {
	border-radius: var(--radius-lg);
	box-shadow: var(--shadow-sm);
}

.prose hr {
	border: none;
	border-top: 1px solid var(--color-border);
	margin: var(--space-7) 0;
}
```

- [ ] **Step 2: Verify the file formats cleanly**

Run: `cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b/web && pnpm exec prettier --check packages/ui/src/styles/base.css`
Expected: either "All matched files use Prettier code style!" or re-run with `--write`.

- [ ] **Step 3: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b
git add web/packages/ui/src/styles/base.css
git commit -m "feat(web/ui): add base stylesheet with buttons and prose"
```

---

## Task 4: Copy logo assets into the UI package

**Files:**
- Create: `web/packages/ui/src/assets/wheels-logo-mark.png`
- Create: `web/packages/ui/src/assets/wheels-logo.png`
- Create: `web/packages/ui/src/assets/wheels-logo-white.png`

The logo files live in the sibling repo `wheels-dev/wheels.dev`. They are already approved brand assets — we copy them, not re-create.

- [ ] **Step 1: Create the assets directory and copy the files**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b
mkdir -p web/packages/ui/src/assets
cp ~/GitHub/wheels-dev/wheels.dev/public/images/wheels-logo-mark.png web/packages/ui/src/assets/
cp ~/GitHub/wheels-dev/wheels.dev/public/images/wheels-logo.png web/packages/ui/src/assets/
cp ~/GitHub/wheels-dev/wheels.dev/public/images/wheels-logo-white.png web/packages/ui/src/assets/
```

- [ ] **Step 2: Verify the files were copied and have expected sizes**

Run: `ls -la web/packages/ui/src/assets/`

Expected: three PNG files, `wheels-logo-mark.png` approximately 9K (322×322), `wheels-logo.png` approximately 20K (518×64), `wheels-logo-white.png` approximately 8K (714×84).

- [ ] **Step 3: Commit**

```bash
git add web/packages/ui/src/assets/
git commit -m "feat(web/ui): add wheels logo assets (mark, lockup, white)"
```

**Note:** SVG conversion of the mark is deferred to a follow-up issue — see `docs/superpowers/specs/2026-04-17-wheels-dev-cohesion-design.md` §12.

---

## Task 5: Create `Logo.astro` component

**Files:**
- Create: `web/packages/ui/src/components/Logo.astro`

- [ ] **Step 1: Create `web/packages/ui/src/components/Logo.astro`**

```astro
---
import markPng from '../assets/wheels-logo-mark.png';
import lockupPng from '../assets/wheels-logo.png';
import lockupWhitePng from '../assets/wheels-logo-white.png';

interface Props {
	variant?: 'mark' | 'lockup' | 'lockup-on-dark';
	size?: 'sm' | 'md' | 'lg';
	class?: string;
}

const { variant = 'mark', size = 'md', class: className = '' } = Astro.props;

const markSizes = {
	sm: { w: 20, h: 20 },
	md: { w: 28, h: 28 },
	lg: { w: 40, h: 40 },
};

const lockupHeights = {
	sm: 20,
	md: 28,
	lg: 40,
};

const isLockup = variant === 'lockup' || variant === 'lockup-on-dark';
const src = variant === 'mark' ? markPng : variant === 'lockup-on-dark' ? lockupWhitePng : lockupPng;
---

{
	variant === 'mark' && (
		<img
			src={src.src}
			width={markSizes[size].w}
			height={markSizes[size].h}
			alt="Wheels"
			class:list={['wd-logo', 'wd-logo--mark', className]}
			loading="eager"
			decoding="async"
		/>
	)
}

{
	isLockup && (
		<img
			src={src.src}
			height={lockupHeights[size]}
			alt="wheels.dev"
			class:list={['wd-logo', 'wd-logo--lockup', className]}
			loading="eager"
			decoding="async"
		/>
	)
}

<style>
	.wd-logo {
		display: inline-block;
		flex-shrink: 0;
	}
	.wd-logo--lockup {
		width: auto;
	}
</style>
```

- [ ] **Step 2: Verify the file formats cleanly**

Run: `cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b/web && pnpm exec prettier --check packages/ui/src/components/Logo.astro`
Expected: passes or rewrites cleanly.

- [ ] **Step 3: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b
git add web/packages/ui/src/components/Logo.astro
git commit -m "feat(web/ui): add Logo component with mark and lockup variants"
```

---

## Task 6: Rebuild `Header.astro`

**Files:**
- Modify: `web/packages/ui/src/components/Header.astro`

- [ ] **Step 1: Replace the entire contents of `web/packages/ui/src/components/Header.astro`**

```astro
---
import Logo from './Logo.astro';

interface Props {
	current?: 'landing' | 'guides' | 'api' | 'blog';
}
const { current } = Astro.props;

const links = [
	{ label: 'Home', href: 'https://wheels.dev/', key: 'landing' },
	{ label: 'Guides', href: 'https://guides.wheels.dev/', key: 'guides' },
	{ label: 'API', href: 'https://api.wheels.dev/', key: 'api' },
	{ label: 'Blog', href: 'https://blog.wheels.dev/', key: 'blog' },
];
---

<header class="wd-header" data-current={current ?? 'landing'}>
	<a class="wd-header__brand" href="https://wheels.dev/" aria-label="wheels.dev home">
		<Logo variant="lockup" size="md" />
	</a>

	<button
		class="wd-header__toggle"
		type="button"
		aria-label="Toggle menu"
		aria-expanded="false"
		aria-controls="wd-header-nav"
	>
		<span></span><span></span><span></span>
	</button>

	<nav id="wd-header-nav" class="wd-header__nav" aria-label="Primary">
		{
			links.map((l) => (
				<a
					href={l.href}
					class:list={['wd-header__link', { 'is-current': current === l.key }]}
				>
					{l.label}
				</a>
			))
		}
		<a class="wd-header__link wd-header__link--external" href="https://github.com/wheels-dev/wheels">
			GitHub <span aria-hidden="true">↗</span>
		</a>
	</nav>
</header>

<script>
	const header = document.querySelector('.wd-header');
	const toggle = document.querySelector('.wd-header__toggle');
	const nav = document.getElementById('wd-header-nav');

	if (toggle && nav && header) {
		toggle.addEventListener('click', () => {
			const open = header.classList.toggle('is-open');
			toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
		});
	}

	if (header) {
		const onScroll = () => {
			if (window.scrollY > 8) {
				header.classList.add('is-scrolled');
			} else {
				header.classList.remove('is-scrolled');
			}
		};
		onScroll();
		window.addEventListener('scroll', onScroll, { passive: true });
	}
</script>

<style>
	.wd-header {
		position: sticky;
		top: 0;
		z-index: 50;
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: var(--space-4);
		padding: 0 var(--space-5);
		height: var(--header-height);
		background: var(--color-bg);
		border-bottom: 1px solid transparent;
		font-family: var(--font-sans);
		transition:
			border-color 0.15s,
			box-shadow 0.15s;
	}

	.wd-header.is-scrolled {
		border-bottom-color: var(--color-border);
		box-shadow: var(--shadow-sm);
	}

	.wd-header__brand {
		display: inline-flex;
		align-items: center;
		text-decoration: none;
	}

	.wd-header__nav {
		display: flex;
		align-items: center;
		gap: var(--space-5);
	}

	.wd-header__link {
		color: var(--color-fg-muted);
		text-decoration: none;
		font-size: var(--text-sm);
		font-weight: 500;
	}

	.wd-header__link:hover {
		color: var(--color-fg);
	}

	.wd-header__link.is-current {
		color: var(--color-brand);
		font-weight: 600;
	}

	.wd-header__link--external {
		color: var(--color-fg-muted);
	}

	.wd-header__toggle {
		display: none;
		flex-direction: column;
		justify-content: center;
		gap: 4px;
		width: 40px;
		height: 40px;
		padding: 0 8px;
		background: transparent;
		border: 1px solid var(--color-border);
		border-radius: var(--radius);
		cursor: pointer;
	}

	.wd-header__toggle span {
		display: block;
		height: 2px;
		background: var(--color-fg);
		border-radius: 2px;
	}

	@media (max-width: 720px) {
		.wd-header__toggle {
			display: flex;
		}

		.wd-header__nav {
			position: absolute;
			top: var(--header-height);
			right: 0;
			flex-direction: column;
			align-items: flex-start;
			gap: var(--space-3);
			padding: var(--space-5);
			background: var(--color-bg);
			border-left: 1px solid var(--color-border);
			border-bottom: 1px solid var(--color-border);
			box-shadow: var(--shadow);
			min-width: 220px;
			transform: translateX(100%);
			transition: transform 0.2s ease;
			visibility: hidden;
		}

		.wd-header.is-open .wd-header__nav {
			transform: translateX(0);
			visibility: visible;
		}
	}
</style>
```

- [ ] **Step 2: Verify prettier is happy**

Run: `cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b/web && pnpm exec prettier --check packages/ui/src/components/Header.astro`
Expected: passes or rewrites cleanly (run with `--write` if needed).

- [ ] **Step 3: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b
git add web/packages/ui/src/components/Header.astro
git commit -m "feat(web/ui): rebuild Header with Logo, sticky scroll, mobile drawer"
```

---

## Task 7: Rebuild `Footer.astro`

**Files:**
- Modify: `web/packages/ui/src/components/Footer.astro`

- [ ] **Step 1: Replace the entire contents of `web/packages/ui/src/components/Footer.astro`**

```astro
---
import Logo from './Logo.astro';

const year = new Date().getFullYear();
---

<footer class="wd-footer">
	<div class="wd-footer__inner">
		<div class="wd-footer__brand">
			<a href="https://wheels.dev/" aria-label="wheels.dev home">
				<Logo variant="lockup" size="md" />
			</a>
			<p class="wd-footer__tagline">
				A Rails-inspired MVC framework for CFML. Conventions, ORM, migrations, CLI.
			</p>
		</div>

		<div class="wd-footer__col">
			<h3 class="wd-footer__heading">Docs</h3>
			<ul>
				<li><a href="https://guides.wheels.dev/">Guides</a></li>
				<li><a href="https://api.wheels.dev/">API reference</a></li>
				<li><a href="https://blog.wheels.dev/">Blog</a></li>
				<li><a href="https://blog.wheels.dev/rss.xml">RSS feed</a></li>
			</ul>
		</div>

		<div class="wd-footer__col">
			<h3 class="wd-footer__heading">Community</h3>
			<ul>
				<li><a href="https://github.com/wheels-dev/wheels">GitHub</a></li>
				<li><a href="https://github.com/wheels-dev/wheels/discussions">Discussions</a></li>
				<li><a href="https://github.com/wheels-dev/wheels/issues">Issues</a></li>
				<li>
					<a href="https://github.com/wheels-dev/wheels/security/policy">Security policy</a>
				</li>
			</ul>
		</div>
	</div>

	<div class="wd-footer__bottom">
		<span>&copy; {year} Wheels contributors</span>
		<span class="wd-footer__sep">·</span>
		<span>MIT licensed</span>
	</div>
</footer>

<style>
	.wd-footer {
		background: var(--color-surface);
		border-top: 1px solid var(--color-border);
		color: var(--color-fg-muted);
		font-family: var(--font-sans);
		font-size: var(--text-sm);
	}

	.wd-footer__inner {
		max-width: var(--max-width);
		margin: 0 auto;
		padding: var(--space-7) var(--space-5) var(--space-5);
		display: grid;
		grid-template-columns: 2fr 1fr 1fr;
		gap: var(--space-6);
	}

	.wd-footer__brand :global(.wd-logo) {
		margin-bottom: var(--space-3);
	}

	.wd-footer__tagline {
		margin: 0;
		max-width: 34ch;
		line-height: var(--leading-normal);
	}

	.wd-footer__heading {
		margin: 0 0 var(--space-3);
		font-size: var(--text-xs);
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		color: var(--color-fg);
	}

	.wd-footer__col ul {
		margin: 0;
		padding: 0;
		list-style: none;
		display: flex;
		flex-direction: column;
		gap: var(--space-2);
	}

	.wd-footer__col a {
		color: var(--color-fg-muted);
		text-decoration: none;
	}

	.wd-footer__col a:hover {
		color: var(--color-brand);
		text-decoration: underline;
	}

	.wd-footer__bottom {
		max-width: var(--max-width);
		margin: 0 auto;
		padding: var(--space-4) var(--space-5);
		border-top: 1px solid var(--color-border);
		color: var(--color-fg-subtle);
		font-size: var(--text-xs);
		display: flex;
		gap: var(--space-3);
		flex-wrap: wrap;
		align-items: center;
	}

	.wd-footer__sep {
		color: var(--color-border-strong);
	}

	@media (max-width: 720px) {
		.wd-footer__inner {
			grid-template-columns: 1fr;
			gap: var(--space-5);
		}
	}
</style>
```

- [ ] **Step 2: Prettier check**

Run: `cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b/web && pnpm exec prettier --check packages/ui/src/components/Footer.astro`
Expected: passes or rewrites cleanly.

- [ ] **Step 3: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b
git add web/packages/ui/src/components/Footer.astro
git commit -m "feat(web/ui): rebuild Footer with 3-column layout + RSS link"
```

---

## Task 8: Create `starlight-theme.css` (scaffold only)

**Files:**
- Create: `web/packages/ui/src/styles/starlight-theme.css`

This file is shipped but **not imported** by any site in PR 1. PR 2 wires it into guides + api.

- [ ] **Step 1: Create `web/packages/ui/src/styles/starlight-theme.css`**

```css
/*
 * Starlight theme bridge for Wheels.
 * Maps Starlight's internal --sl-* tokens onto our --color-* / --font-* tokens.
 * Not imported in PR 1 — consumed by guides + api in PR 2 via `customCss`.
 */

:root {
	/* Accents */
	--sl-color-accent: var(--color-brand);
	--sl-color-accent-low: var(--color-brand-soft);
	--sl-color-accent-high: var(--color-brand-ink);

	/* Text (Starlight uses "white" as strongest text in dark mode naming) */
	--sl-color-white: var(--color-fg);
	--sl-color-gray-1: var(--color-fg-muted);
	--sl-color-gray-2: var(--color-fg-subtle);
	--sl-color-gray-3: var(--color-border-strong);
	--sl-color-gray-4: var(--color-border);
	--sl-color-gray-5: var(--color-surface-2);
	--sl-color-gray-6: var(--color-surface);
	--sl-color-gray-7: var(--color-bg);

	/* Surfaces */
	--sl-color-bg: var(--color-bg);
	--sl-color-bg-nav: var(--color-bg);
	--sl-color-bg-sidebar: var(--color-surface);

	/* Typography */
	--sl-font: var(--font-sans);
	--sl-font-mono: var(--font-mono);
	--sl-text-code: var(--text-sm);

	/* Radii */
	--sl-radius-small: var(--radius-sm);
	--sl-radius-medium: var(--radius);
	--sl-radius-large: var(--radius-lg);

	/* Layout */
	--sl-sidebar-width: 18rem;
	--sl-content-width: 45rem;
}

/* Custom prose-like tweaks to Starlight content area */
:root[data-has-toc] .sl-markdown-content {
	font-size: var(--text-base);
	line-height: var(--leading-relaxed);
}

/* Code block styling — match hero install block on landing */
.sl-markdown-content :not(pre) > code {
	background: var(--color-surface-2);
	border-radius: var(--radius-sm);
	padding: 0.1em 0.35em;
	font-family: var(--font-mono);
	font-size: 0.875em;
}

.sl-markdown-content pre {
	background: #111;
	color: #e5e5e5;
	border-radius: var(--radius-lg);
	box-shadow: var(--shadow-sm);
}
```

- [ ] **Step 2: Prettier check**

Run: `cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b/web && pnpm exec prettier --check packages/ui/src/styles/starlight-theme.css`
Expected: passes or rewrites cleanly.

- [ ] **Step 3: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b
git add web/packages/ui/src/styles/starlight-theme.css
git commit -m "feat(web/ui): add starlight-theme.css token bridge (not yet consumed)"
```

---

## Task 9: Wire `base.css` into landing layout

**Files:**
- Modify: `web/sites/landing/src/layouts/BaseLayout.astro`

- [ ] **Step 1: Update the imports at the top of `web/sites/landing/src/layouts/BaseLayout.astro`**

Find this block (lines 1-4):
```astro
---
import Header from '@wheels-dev/ui/components/Header.astro';
import Footer from '@wheels-dev/ui/components/Footer.astro';
import '@wheels-dev/ui/styles/tokens.css';
```

Replace with:
```astro
---
import Header from '@wheels-dev/ui/components/Header.astro';
import Footer from '@wheels-dev/ui/components/Footer.astro';
import '@wheels-dev/ui/styles/tokens.css';
import '@wheels-dev/ui/styles/base.css';
```

- [ ] **Step 2: Remove the now-redundant inline global styles**

The component has an `is:global` style block that duplicates what `base.css` now handles. Find this block (lines 30-51 approximately):

```astro
		<style is:global>
			* {
				box-sizing: border-box;
			}
			html,
			body {
				margin: 0;
				padding: 0;
				background: var(--color-bg);
				color: var(--color-fg);
				font-family: var(--font-sans);
			}
			main {
				max-width: var(--max-width);
				margin: 0 auto;
				padding: 2rem 1.5rem;
				min-height: 60vh;
			}
			a {
				color: var(--color-accent);
			}
		</style>
```

Replace with a trimmed version that only keeps layout-specific rules not covered by `base.css`:

```astro
		<style is:global>
			main {
				max-width: var(--max-width);
				margin: 0 auto;
				padding: 2rem 1.5rem;
				min-height: 60vh;
			}
		</style>
```

- [ ] **Step 3: Run astro check on landing**

Run: `cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b/web && pnpm --filter @wheels-dev/site-landing exec astro check`

Expected: `0 errors, 0 warnings` (or similar success output).

- [ ] **Step 4: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b
git add web/sites/landing/src/layouts/BaseLayout.astro
git commit -m "feat(web/landing): import base.css from shared UI package"
```

---

## Task 10: Wire `base.css` into blog layout

**Files:**
- Modify: `web/sites/blog/src/layouts/BaseLayout.astro`

- [ ] **Step 1: Update the imports**

Find the imports block at the top of `web/sites/blog/src/layouts/BaseLayout.astro` (lines 1-6):
```astro
---
import Header from '@wheels-dev/ui/components/Header.astro';
import Footer from '@wheels-dev/ui/components/Footer.astro';
import NewsletterSignup from '../components/NewsletterSignup.astro';
import '@wheels-dev/ui/styles/tokens.css';
```

Replace with:
```astro
---
import Header from '@wheels-dev/ui/components/Header.astro';
import Footer from '@wheels-dev/ui/components/Footer.astro';
import NewsletterSignup from '../components/NewsletterSignup.astro';
import '@wheels-dev/ui/styles/tokens.css';
import '@wheels-dev/ui/styles/base.css';
```

- [ ] **Step 2: Trim the inline global style block the same way as Task 9**

Find the `is:global` block in the layout (near lines 30-51):

```astro
			<style is:global>
				* {
					box-sizing: border-box;
				}
				html,
				body {
					margin: 0;
					padding: 0;
					background: var(--color-bg);
					color: var(--color-fg);
					font-family: var(--font-sans);
				}
				main {
					max-width: var(--max-width);
					margin: 0 auto;
					padding: 2rem 1.5rem;
					min-height: 60vh;
				}
				a {
					color: var(--color-accent);
				}
			</style>
```

Replace with:
```astro
			<style is:global>
				main {
					max-width: var(--max-width);
					margin: 0 auto;
					padding: 2rem 1.5rem;
					min-height: 60vh;
				}
			</style>
```

- [ ] **Step 3: Run astro check on blog**

Run: `cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b/web && pnpm --filter @wheels-dev/site-blog exec astro check`
Expected: `0 errors, 0 warnings`.

- [ ] **Step 4: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b
git add web/sites/blog/src/layouts/BaseLayout.astro
git commit -m "feat(web/blog): import base.css from shared UI package"
```

---

## Task 11: Build + type check all sites

**Files:** (none modified)

Verification gate — no site should break.

- [ ] **Step 1: Run astro check on all four sites in parallel**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b/web
pnpm --filter @wheels-dev/site-landing exec astro check
pnpm --filter @wheels-dev/site-blog exec astro check
pnpm --filter @wheels-dev/site-guides exec astro check
pnpm --filter @wheels-dev/site-api exec astro check
```

Expected: each reports `0 errors`.

- [ ] **Step 2: Full build**

Run: `cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b/web && pnpm build`
Expected: all four sites build successfully. Final lines resemble `✓ built in Ns` per site.

- [ ] **Step 3: Format check**

Run: `cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b/web && pnpm format:check`
Expected: passes. If fails, run `pnpm format` and inspect the diff before continuing.

**Do not commit anything here.** This task exits clean with no changes, or halts with errors to investigate.

---

## Task 12: Visual smoke test — landing page

**Files:** (none modified)

Start the landing dev server and confirm the new header/footer render correctly via the browser preview tool.

- [ ] **Step 1: Start the landing dev server**

Run: `cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b/web && pnpm dev:landing` in background mode.

Expected stdout contains: `Local: http://localhost:4321/`.

- [ ] **Step 2: Open the landing page in the preview tool**

Use `mcp__Claude_Preview__preview_start` (or navigate an existing preview) to `http://localhost:4321/`.

- [ ] **Step 3: Screenshot and verify**

Use `mcp__Claude_Preview__preview_screenshot` to capture the page. Confirm visually:
- Header: wheels.dev lockup on left, nav links on right, "Home" is red/bold (current page).
- Hero, features, resources all render without layout break.
- Footer: three columns (logo+tagline, Docs, Community), bottom bar with copyright.
- Scrolling the page adds a subtle shadow under the sticky header.

- [ ] **Step 4: Check the dev console for errors**

Use `mcp__Claude_Preview__preview_console_logs` — expect no errors. Warnings about missing favicon or third-party services are OK.

- [ ] **Step 5: Stop the landing dev server**

Kill the background process.

**No commit — verification only.** If anything looks wrong, fix the relevant component/stylesheet and rerun.

---

## Task 13: Visual smoke test — blog index

**Files:** (none modified)

- [ ] **Step 1: Start the blog dev server**

Run: `cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b/web && pnpm dev:blog` in background.
Expected: `Local: http://localhost:4322/`.

- [ ] **Step 2: Open in the preview tool**

Navigate to `http://localhost:4322/`.

- [ ] **Step 3: Screenshot and verify**

Use `mcp__Claude_Preview__preview_screenshot`. Confirm:
- Header identical to landing (lockup left, nav right), but "Blog" link is red/bold.
- Paginated post list renders without layout break.
- NewsletterSignup visible between posts and footer.
- Footer identical to landing.

- [ ] **Step 4: Click through to a blog post**

Use `mcp__Claude_Preview__preview_click` on the first post title. Verify:
- Post renders in prose style.
- Heading hierarchy preserved.
- Links inside post body are red.

- [ ] **Step 5: Check the console for errors**

`mcp__Claude_Preview__preview_console_logs` — expect no errors.

- [ ] **Step 6: Stop the blog dev server**

**No commit — verification only.**

---

## Task 14: Format pass + final verification

**Files:** any auto-formatted files from prior commits.

- [ ] **Step 1: Run format across the whole tree**

Run: `cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b/web && pnpm format`

Expected: prettier rewrites any unformatted files. If there are changes, they should only be whitespace/quote adjustments.

- [ ] **Step 2: Check git status**

Run: `cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b && git status`

Expected: either clean, or only formatting changes to files we've already committed.

- [ ] **Step 3: If formatting changes exist, commit them**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b
git add -u web/
git commit -m "style(web): prettier format pass"
```

Skip this step if `git status` is clean.

- [ ] **Step 4: Full log review**

Run: `git log --oneline origin/develop..HEAD`

Expected: approximately 10 commits with scopes `feat(web/ui)`, `feat(web/landing)`, `feat(web/blog)`, and one `style(web)` if formatting landed.

---

## Task 15: Push branch and open PR

**Files:** (none modified)

- [ ] **Step 1: Push the branch**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/keen-torvalds-4e016b
git push -u origin claude/keen-torvalds-4e016b
```

- [ ] **Step 2: Open the PR against `develop`**

```bash
gh pr create --base develop --title "feat(web): brand foundation — expanded tokens, Logo, new Header & Footer" --body "$(cat <<'EOF'
## Summary

PR 1 of 3 rolling out the wheels.dev multi-site cohesion design ([spec](docs/superpowers/specs/2026-04-17-wheels-dev-cohesion-design.md)).

- Expanded design tokens in \`@wheels-dev/ui\` (warm palette, type scale, shadows, radius-pill)
- New \`base.css\` with element resets, button variants, and \`.prose\` for long-form content
- New \`Logo.astro\` component (mark + lockup variants, sized sm/md/lg)
- Rebuilt \`Header.astro\` (sticky, scroll shadow, mobile drawer, uses Logo)
- Rebuilt \`Footer.astro\` (3-column layout with RSS in Community, bottom copyright bar)
- New \`starlight-theme.css\` token bridge (shipped, not yet consumed)
- Landing + blog layouts wired to import \`base.css\`; redundant inline globals removed

Guides and api are intentionally **not touched** in this PR — they're picked up in PR 2.

## Test plan

- [ ] \`pnpm --filter @wheels-dev/site-landing exec astro check\` passes
- [ ] \`pnpm --filter @wheels-dev/site-blog exec astro check\` passes
- [ ] \`pnpm --filter @wheels-dev/site-guides exec astro check\` passes (unchanged)
- [ ] \`pnpm --filter @wheels-dev/site-api exec astro check\` passes (unchanged)
- [ ] \`pnpm build\` succeeds for all four sites
- [ ] Landing page renders with new header/footer + hero/features/resources intact
- [ ] Blog index renders with new header/footer + post list intact
- [ ] Blog post page renders with prose styling + new chrome
- [ ] Sticky header shadow appears on scroll
- [ ] Mobile drawer opens at <720px
- [ ] RSS link present in footer

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Expected: returns a PR URL; report it back.

---

## Self-Review

**Spec coverage check:**

| Spec section | Plan task |
|---|---|
| §3 Tokens | Task 2 |
| §4 Logo component | Task 5 |
| §4 Header rebuild | Task 6 |
| §4 Footer rebuild | Task 7 |
| §5 base.css / .prose | Task 3 |
| §7 starlight-theme.css scaffold | Task 8 |
| §9 PR 1 scope | Tasks 1–15 (this plan) |
| §9 PR 2, PR 3 scope | Out of scope — separate plans |
| §10 Testing | Tasks 11, 12, 13 |

**Deferred from spec §12 for follow-up issues (not in this plan):**
- SVG conversion of mark
- Icon library selection
- Pagefind search styling
- `starlightRoute` API verification (not needed until PR 2)

**Placeholder scan:** no TBD / TODO / "implement later" / "similar to Task N" / "add appropriate error handling" in any step. Every code block is the full content to paste or the full diff to apply.

**Type consistency:** `Logo.astro` prop names (`variant`, `size`) are reused consistently in Task 6 (`<Logo variant="lockup" size="md" />`) and Task 7. `Header` prop `current` matches across call sites (the `BaseLayout.astro` files already pass `current=...` via their own `Props` interface — unchanged in this PR).

**Risks called out:**
- Task 9 and Task 10 assume the exact line-range of the `is:global` block. If the file has drifted, the engineer should find the block by content (starts with `<style is:global>`, contains `* { box-sizing: border-box; }`) and replace it in-place.
- Task 12 and 13 depend on the Claude Preview MCP tool being available. If unavailable, substitute manual browser testing and note in the PR.
