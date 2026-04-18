import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

const versions = [
	{ slug: 'v3-0-0', label: 'v3.0.0 (current)', collapsed: false },
	{ slug: 'v2-5-0', label: 'v2.5.0', collapsed: true },
	{ slug: 'v2-4-0', label: 'v2.4.0', collapsed: true },
	{ slug: 'v2-3-0', label: 'v2.3.0', collapsed: true },
	{ slug: 'v2-2-0', label: 'v2.2.0', collapsed: true },
	{ slug: 'v2-1-0', label: 'v2.1.0', collapsed: true },
	{ slug: 'v2-0-0', label: 'v2.0.0', collapsed: true },
	{ slug: 'v1-4-5', label: 'v1.4.5', collapsed: true },
];

export default defineConfig({
	site: 'https://api.wheels.dev',
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
			},
			social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/wheels-dev/wheels' }],
			sidebar: [
				{ label: 'Overview', link: '/' },
				...versions.map((v) => ({
					label: v.label,
					autogenerate: { directory: v.slug },
					collapsed: v.collapsed,
				})),
			],
		}),
	],
});
