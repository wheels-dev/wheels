import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
import { rehypeTableScroll } from '@wheels-dev/ui/markdown/rehype-table-scroll.mjs';

export default defineConfig({
  // Astro 7 changed the compressHTML default to 'jsx', which drops the space
  // between text and an element on the next line ("Install with<code>").
  // true keeps Astro 6's HTML-aware compression.
  compressHTML: true,
  site: 'https://blog.wheels.dev',
  // Wrap every markdown table in the shared accessible scroll container so
  // `.prose table` can go back to native table display (#4575).
  markdown: {
    rehypePlugins: [rehypeTableScroll],
  },
  integrations: [sitemap()],
});
