#!/usr/bin/env node
/**
 * Guides generator.
 *
 * Reads a GitBook-style docs directory (with README.md, SUMMARY.md, and
 * .gitbook/assets/) and emits Starlight-compatible content at
 * web/sites/guides/src/content/docs/<versionSlug>/, plus a sidebar.json
 * manifest that astro.config.mjs imports for that version.
 *
 * Also copies .gitbook/assets/ images into web/sites/guides/public/assets/
 * and rewrites references in the markdown to point there.
 *
 * Usage:
 *   node web/scripts/generate-guides.mjs <source-dir> <version-slug> <label>
 *
 * Example:
 *   node web/scripts/generate-guides.mjs docs/src v3-1-0 "v3.1.0 (latest)"
 */
import {
  readFileSync,
  writeFileSync,
  mkdirSync,
  rmSync,
  existsSync,
  readdirSync,
  copyFileSync,
  statSync,
} from 'node:fs';
import { resolve, join, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../..');

const [, , srcArg, versionSlug, labelArg] = process.argv;
if (!srcArg || !versionSlug) {
  console.error('Usage: node generate-guides.mjs <source-dir> <version-slug> [label]');
  console.error('Example: node generate-guides.mjs docs/src v3-1-0 "v3.1.0 (latest)"');
  process.exit(1);
}

const srcDir = resolve(srcArg);
const label = labelArg || versionSlug;

if (!existsSync(join(srcDir, 'SUMMARY.md'))) {
  console.error(`Missing SUMMARY.md in ${srcDir}`);
  process.exit(1);
}

const outDir = join(REPO_ROOT, 'web/sites/guides/src/content/docs', versionSlug);
const sidebarPath = join(REPO_ROOT, 'web/sites/guides/src/sidebars', `${versionSlug}.json`);
const assetsOutDir = join(REPO_ROOT, 'web/sites/guides/public/assets');

if (existsSync(outDir)) {
  rmSync(outDir, { recursive: true });
}
mkdirSync(outDir, { recursive: true });
mkdirSync(dirname(sidebarPath), { recursive: true });
mkdirSync(assetsOutDir, { recursive: true });

// --- Copy assets ---
const assetsSrc = join(srcDir, '.gitbook/assets');
if (existsSync(assetsSrc)) {
  for (const file of readdirSync(assetsSrc)) {
    const src = join(assetsSrc, file);
    if (statSync(src).isFile()) {
      copyFileSync(src, join(assetsOutDir, file));
    }
  }
}

// --- Parse SUMMARY.md ---
// Format:
//   ## SECTION HEADING
//   * [Title](path/to/page.md)
//     * [Nested](path/to/nested.md)
//     * Plain Text Label   (no link — grouping only)
//
// Returns a Starlight sidebar config tree.
function parseSummary(summaryText) {
  const lines = summaryText.split('\n');
  const groups = []; // [{label, items[]}]
  let currentGroup = null;

  // parentAtDepth[d] = the item added at depth d. New items at depth d+1
  // nest under parentAtDepth[d].items.
  let parentAtDepth = [];

  for (const rawLine of lines) {
    if (!rawLine.trim()) continue;
    const sectionMatch = rawLine.match(/^##+\s+(.+)$/);
    if (sectionMatch) {
      currentGroup = { label: sectionMatch[1].trim(), items: [] };
      groups.push(currentGroup);
      // Treat the section itself as the parent at depth -1.
      parentAtDepth = [currentGroup];
      continue;
    }
    if (!currentGroup) continue;

    const itemMatch = rawLine.match(/^(\s*)\*\s+(.+)$/);
    if (!itemMatch) continue;

    const indent = itemMatch[1].replace(/\t/g, '  ').length;
    const depth = Math.floor(indent / 2);
    const text = itemMatch[2].trim();

    // Parse [Title](link) or bare text
    const linkMatch = text.match(/^\[([^\]]+)\]\(([^)]+)\)$/);
    let item;
    if (linkMatch) {
      const [, title, link] = linkMatch;
      const cleanLink = link.replace(/\.md$/, '').replace(/\/README$/, '/');
      const slugPath = cleanLink === 'README' ? '' : cleanLink;
      item = {
        label: title,
        link: `/${versionSlug}/${slugPath}/`.replace(/\/+/g, '/'),
      };
    } else {
      item = { label: text };
    }

    // Find the parent: the item at depth - 1 (or the section group if depth 0).
    const parent = depth === 0 ? currentGroup : parentAtDepth[depth - 1];
    if (!parent) {
      currentGroup.items.push(item);
    } else {
      if (!parent.items) parent.items = [];
      parent.items.push(item);
    }
    parentAtDepth[depth] = item;
    // Truncate deeper levels — they belong to the previous parent subtree
    parentAtDepth.length = depth + 1;
  }

  return groups;
}

const summary = readFileSync(join(srcDir, 'SUMMARY.md'), 'utf8');
const sidebarGroups = parseSummary(summary);
writeFileSync(sidebarPath, JSON.stringify(sidebarGroups, null, 2));

// --- Walk source directory and copy + rewrite markdown files ---
function walkMd(dir, prefix = '') {
  const out = [];
  for (const entry of readdirSync(dir)) {
    if (entry.startsWith('.') || entry === '_layouts' || entry === 'stylesheets') continue;
    const full = join(dir, entry);
    const rel = prefix ? `${prefix}/${entry}` : entry;
    const st = statSync(full);
    if (st.isDirectory()) {
      out.push(...walkMd(full, rel));
    } else if (entry.toLowerCase().endsWith('.md') && entry.toUpperCase() !== 'SUMMARY.MD') {
      out.push({ full, rel });
    }
  }
  return out;
}

function rewriteContent(content, ownPath) {
  // ownPath is like "introduction/frameworks-and-wheels.md"
  const ownDir = dirname(ownPath);

  // 1) Rewrite .gitbook/assets/foo.png → /assets/foo.png
  //    GitBook wraps URLs with spaces as `(<...>)`. Handle both forms.
  content = content.replace(
    /(!\[[^\]]*\]\(\s*)<(?:\.\.\/)*\.gitbook\/assets\/([^>]+)>\)/g,
    (_, pre, file) => `${pre}/assets/${encodeURI(file)})`
  );
  content = content.replace(
    /(!\[[^\]]*\]\(\s*)(?:\.\.\/)*\.gitbook\/assets\/([^)\s]+)\)/g,
    (_, pre, file) => `${pre}/assets/${file})`
  );
  // HTML <img src="...gitbook/assets/...">
  content = content.replace(
    /<img([^>]*)src=["'](?:\.\.\/)*\.gitbook\/assets\/([^"']+)["']/g,
    (_, attrs, file) => `<img${attrs}src="/assets/${file}"`
  );

  // 2) Rewrite internal `[text](relative/path.md)` links → `/<version>/<resolved>/`
  content = content.replace(
    /(\[[^\]]*\]\()([^):#][^)#]*\.md)(#[^)]*)?\)/g,
    (_, pre, path, anchor = '') => {
      // Resolve relative to ownDir
      let resolved = path.startsWith('/') ? path.slice(1) : join(ownDir, path);
      resolved = resolved.replace(/\\/g, '/');
      // Normalize `foo/../bar` etc.
      const parts = [];
      for (const p of resolved.split('/')) {
        if (p === '..') parts.pop();
        else if (p && p !== '.') parts.push(p);
      }
      resolved = parts.join('/');
      // Drop .md
      resolved = resolved.replace(/\.md$/, '');
      // Drop trailing README
      resolved = resolved.replace(/\/?README$/, '');
      return `${pre}/${versionSlug}/${resolved}${resolved ? '/' : ''}${anchor})`;
    }
  );

  return content;
}

// Starlight requires `title` in frontmatter. The source GitBook files
// typically have `description` but put the title in an H1 heading. Ensure
// every emitted file has a `title` field, extracting from the first H1 if
// missing. Falls back to the filename.
function ensureFrontmatterTitle(content, fallbackTitle) {
  const fmMatch = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  let fm, body;
  if (fmMatch) {
    fm = fmMatch[1];
    body = fmMatch[2];
  } else {
    fm = '';
    body = content;
  }

  if (/^\s*title\s*:/m.test(fm)) {
    // Already has a title
    return content;
  }

  // Extract first H1 from body
  const h1 = body.match(/^#\s+(.+?)\s*$/m);
  const title = h1 ? h1[1].trim() : fallbackTitle;
  // YAML-escape: if title has special chars, quote it.
  const needsQuote = /[":#&*!|>%@`]/.test(title);
  const titleLine = needsQuote
    ? `title: "${title.replace(/"/g, '\\"')}"`
    : `title: ${title}`;

  const newFm = fm ? `${titleLine}\n${fm}` : titleLine;
  return `---\n${newFm}\n---\n${body}`;
}

function humanizeSlug(path) {
  const leaf = path.split('/').pop().replace(/\.md$/, '');
  return leaf
    .replace(/[-_]/g, ' ')
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

const mdFiles = walkMd(srcDir);
let written = 0;
for (const { full, rel } of mdFiles) {
  const raw = readFileSync(full, 'utf8');
  const rewritten = rewriteContent(raw, rel);
  const withTitle = ensureFrontmatterTitle(rewritten, humanizeSlug(rel));

  // README.md at the root becomes index.md for Starlight
  let outRel = rel;
  if (rel === 'README.md') {
    outRel = 'index.md';
  } else if (rel.endsWith('/README.md')) {
    outRel = rel.replace(/\/README\.md$/, '/index.md');
  }

  const outPath = join(outDir, outRel);
  mkdirSync(dirname(outPath), { recursive: true });
  writeFileSync(outPath, withTitle);
  written++;
}

console.error(`Generated ${written} guide pages → ${outDir}`);
console.error(`Sidebar manifest → ${sidebarPath}`);
console.error(`Version label: ${label}`);
