import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://packages.wheels.dev',
  integrations: [sitemap()],
});
