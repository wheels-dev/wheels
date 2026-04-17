import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://guides.wheels.dev',
  integrations: [
    starlight({
      title: 'Wheels Guides',
      description: 'Official guides for the Wheels CFML MVC framework.',
      social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/wheels-dev/wheels' }],
      sidebar: [
        { label: 'Coming soon', link: '/' },
      ],
    }),
  ],
});
