import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { GUIDES_VERSIONS } from '@wheels-dev/ui/data/versions';

const __dirname = dirname(fileURLToPath(import.meta.url));

function loadSidebar(version) {
	const path = resolve(__dirname, 'src/sidebars', `${version}.json`);
	const groups = JSON.parse(readFileSync(path, 'utf8'));
	return groups;
}

const versions = GUIDES_VERSIONS.map((v) => ({
	slug: v.slug,
	label: v.sidebarLabel ?? v.label,
	collapsed: v.collapsed,
}));

// Starlight doesn't support a "linked group" (item with both link + items).
// Flatten: if a group was also a link in the source, prepend an "Overview"
// child that carries the link.
function normalizeItem(item) {
	if (item.items && Array.isArray(item.items) && item.items.length > 0) {
		const children = item.items.map(normalizeItem);
		if (item.link) {
			children.unshift({ label: 'Overview', link: item.link });
		}
		return {
			label: item.label,
			items: children,
			collapsed: true,
		};
	}
	if (item.link) {
		return { label: item.label, link: item.link };
	}
	// Unlinked leaf — skip
	return null;
}

function buildSidebarForVersion(version) {
	const groups = loadSidebar(version.slug);
	return {
		label: version.label,
		collapsed: version.collapsed,
		items: groups.map((g) => {
			// Top-level entry with a link and no children → render as a leaf link,
			// not a collapsible group. Without this, Starlight would wrap it as an
			// empty group and drop the link entirely (Glossary hit this bug).
			if (g.link && (!g.items || g.items.length === 0)) {
				return { label: g.label, link: g.link };
			}
			return {
				label: g.label,
				collapsed: version.collapsed,
				items: (g.items || []).map(normalizeItem).filter(Boolean),
			};
		}),
	};
}

export default defineConfig({
	site: 'https://guides.wheels.dev',
	redirects: {
		// v4.0.0 GA (2026-05-12) renamed the URL slug `v4-0-0-snapshot` to `v4-0-0`.
		// Astro's static `redirects` map doesn't support [...spread] sources
		// without a backing page that can supply getStaticPaths, so a full
		// catch-all for `/v4-0-0-snapshot/*` → `/v4-0-0/*` isn't possible at this
		// layer. The high-traffic landing pages get explicit redirects here; deep
		// links fall through to the site's 404 page. (Cloudflare-side rewrite
		// rules could provide a full wildcard if SEO equity from deep-link
		// backlinks turns out to matter — out of scope for the GA-day rename.)
		'/v4-0-0-snapshot': '/v4-0-0/',
		'/v4-0-0-snapshot/': '/v4-0-0/',
		'/v4-0-0-snapshot/start-here/installing': '/v4-0-0/start-here/installing/',
		'/v4-0-0-snapshot/start-here/tutorial': '/v4-0-0/start-here/tutorial/',
		'/v4-0-0-snapshot/start-here/first-15-minutes': '/v4-0-0/start-here/first-15-minutes/',
		'/v4-0-0-snapshot/start-here/release-channels': '/v4-0-0/start-here/release-channels/',
		'/v4-0-0-snapshot/start-here/cfml-engines': '/v4-0-0/start-here/cfml-engines/',
		'/v4-0-0-snapshot/command-line-tools/installation': '/v4-0-0/command-line-tools/installation/',
		// Phase 0 preview at /v4-0-0-snapshot/cli-reference/ was retired in
		// PR #2169 and replaced by the 103-page tree at /command-line-tools/.
		// Preserve any external bookmarks or backlinks from the preview window.
		// See issue #2179.
		'/v4-0-0-snapshot/cli-reference': '/v4-0-0/command-line-tools/',
		'/v4-0-0-snapshot/cli-reference/info': '/v4-0-0/command-line-tools/',
		'/v4-0-0/cli-reference': '/v4-0-0/command-line-tools/',
		'/v4-0-0/cli-reference/info': '/v4-0-0/command-line-tools/',
		// The pre-GA `v4-0-1-snapshot` dev channel was retired when the 4.0 docs
		// consolidated onto a single `v4-0-0` line (4.0.x is documented as one
		// version — see web/packages/ui/src/data/versions.ts). Same Astro
		// static-redirect limitation as the GA rename above: high-traffic landings
		// get explicit redirects, deep links fall through. The dev channel carried
		// little backlink equity.
		'/v4-0-1-snapshot': '/v4-0-0/',
		'/v4-0-1-snapshot/': '/v4-0-0/',
		'/v4-0-1-snapshot/start-here/installing': '/v4-0-0/start-here/installing/',
		'/v4-0-1-snapshot/start-here/tutorial': '/v4-0-0/start-here/tutorial/',
		'/v4-0-1-snapshot/command-line-tools': '/v4-0-0/command-line-tools/',
		// Astro/Starlight slugs the dotted filename `3.0.0-config-migration.md`
		// down to `300-config-migration` (github-slugger strips dots). The file
		// was renamed to `3-0-0-config-migration.md` so the URL matches every
		// other doc in the tree; this redirect preserves the original ugly slug
		// for any external bookmarks accumulated while it was live.
		'/v3-0-0/upgrading/300-config-migration': '/v3-0-0/upgrading/3-0-0-config-migration/',
	},
	integrations: [
		starlight({
			title: 'Wheels Guides',
			description: 'Official guides for the Wheels CFML MVC framework.',
			expressiveCode: {
				// High-contrast theme pair — github-dark-high-contrast (dark) and
				// github-light (light) both produce WCAG-AA contrast ratios between
				// every token color and the theme's own background. Starlight picks
				// the first for `data-theme="dark"` and the second for light mode.
				themes: ['github-dark-high-contrast', 'github-light'],
			},
			customCss: [
				'@wheels-dev/ui/styles/tokens.css',
				'@wheels-dev/ui/styles/base.css',
				'@wheels-dev/ui/styles/starlight-theme.css',
			],
			components: {
				Header: '@wheels-dev/ui/components/starlight/Header.astro',
				Footer: '@wheels-dev/ui/components/starlight/Footer.astro',
				SocialIcons: '@wheels-dev/ui/components/starlight/SocialIcons.astro',
				PageTitle: '@wheels-dev/ui/components/starlight/PageTitle.astro',
				EditLink: '@wheels-dev/ui/components/starlight/EditLink.astro',
			},
			editLink: {
				// Our EditLink override computes its own target and points at
				// the Starlight-native MDX at
				// web/sites/guides/src/content/docs/<version>/*.mdx, so the value
				// here is mostly vestigial — but Starlight only renders EditLink
				// when editLink is configured, so we still need this.
				baseUrl: 'https://github.com/wheels-dev/wheels/edit/develop/web/sites/guides/src/content/docs/',
			},
			social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/wheels-dev/wheels' }],
			sidebar: [{ label: 'Overview', link: '/' }, ...versions.map(buildSidebarForVersion)],
		}),
	],
});
