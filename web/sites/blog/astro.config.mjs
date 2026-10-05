import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  // Astro 7 changed the compressHTML default to 'jsx', which drops the space
  // between text and an element on the next line ("Install with<code>").
  // true keeps Astro 6's HTML-aware compression.
  compressHTML: true,
  site: 'https://blog.wheels.dev',
  integrations: [sitemap()],
});
