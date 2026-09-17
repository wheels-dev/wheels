import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { API_VERSIONS } from '@wheels-dev/ui/data/versions';
import { rehypeBasePrefix } from '@wheels-dev/ui/markdown/rehype-base-prefix.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const contentRoot = resolve(__dirname, 'src/content/docs');


// Snapshot content is generated in CI from the running Wheels server and is
// NOT committed. Filter it out of the sidebar when the directory doesn't
// exist so local `pnpm build` without a prior generate step still succeeds.
const versions = API_VERSIONS.filter(
	(v) => v.status !== 'snapshot' || existsSync(resolve(contentRoot, v.slug))
).map((v) => ({
	slug: v.slug,
	label: v.sidebarLabel ?? v.label,
	collapsed: v.collapsed,
}));

export default defineConfig({
	site: 'https://api.wheels.dev',
	// See the guides config: the local docs bundle is served from /wheels/api/,
	// and Astro's absolute asset URLs need the prefix baked in at build time.
	...(process.env.WHEELS_DOCS_BASE ? { base: process.env.WHEELS_DOCS_BASE } : {}),
	// See the guides config: content links authored as `/v4-0-0/...` are not
	// rewritten by Astro's `base`, so the local bundle prefixes them here.
	markdown: {
		rehypePlugins: [
			[rehypeBasePrefix, { base: process.env.WHEELS_DOCS_BASE || '' }],
		],
	},
	integrations: [
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
				PageTitle: '@wheels-dev/ui/components/starlight/PageTitle.astro',
				EditLink: '@wheels-dev/ui/components/starlight/EditLink.astro',
			},
			editLink: {
				// Vestigial — our EditLink override composes a GitHub code-search
				// URL from the function name in frontmatter. Setting baseUrl so
				// Starlight renders the EditLink component at all.
				baseUrl: 'https://github.com/wheels-dev/wheels/edit/develop/docs/api/',
			},
			social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/wheels-dev/wheels' }],
			sidebar: [
				{ label: 'Overview', link: '/' },
				...versions.map((v) => ({
					label: v.label,
					// Starlight 0.39+ requires autogenerate to be wrapped in items[].
					items: [{ autogenerate: { directory: v.slug } }],
					collapsed: v.collapsed,
				})),
			],
		}),
	],
});
