import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://api.wheels.dev',
  integrations: [
    starlight({
      title: 'Wheels API Reference',
      description: 'Function reference for the Wheels CFML MVC framework.',
      social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/wheels-dev/wheels' }],
      sidebar: [
        { label: 'Overview', link: '/' },
        {
          label: 'v3.0.0 (current)',
          autogenerate: { directory: 'v3.0.0' },
          collapsed: false,
        },
      ],
    }),
  ],
});
