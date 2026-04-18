import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));

function loadSidebar(version) {
  const path = resolve(__dirname, 'src/sidebars', `${version}.json`);
  const groups = JSON.parse(readFileSync(path, 'utf8'));
  return groups;
}

const versions = [
  { slug: 'v4-0-0-snapshot', label: 'v4.0.0-SNAPSHOT (dev)', collapsed: false },
  { slug: 'v3-0-0', label: 'v3.0.0 (current)', collapsed: true },
  { slug: 'v2-5-0', label: 'v2.5.0', collapsed: true },
];

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
    items: groups.map((g) => ({
      label: g.label,
      collapsed: version.collapsed,
      items: (g.items || []).map(normalizeItem).filter(Boolean),
    })),
  };
}

export default defineConfig({
  site: 'https://guides.wheels.dev',
  integrations: [
    starlight({
      title: 'Wheels Guides',
      description: 'Official guides for the Wheels CFML MVC framework.',
      social: [
        { icon: 'github', label: 'GitHub', href: 'https://github.com/wheels-dev/wheels' },
      ],
      sidebar: [
        { label: 'Overview', link: '/' },
        ...versions.map(buildSidebarForVersion),
      ],
    }),
  ],
});
