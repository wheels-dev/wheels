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
        { label: 'Coming soon', link: '/' },
      ],
    }),
  ],
});
