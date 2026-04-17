#!/usr/bin/env node
/**
 * API docs generator.
 *
 * Reads docs/api/v{version}.json from the repo root and emits one markdown
 * file per function into web/sites/api/src/content/docs/v{version}/{section}/{slug}.md.
 *
 * Usage:  node web/scripts/generate-api-docs.mjs 3.0.0
 */
import { readFileSync, writeFileSync, mkdirSync, rmSync, existsSync } from 'node:fs';
import { resolve, join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../..');

const version = process.argv[2];
if (!version) {
  console.error('Usage: node generate-api-docs.mjs <version>');
  console.error('Example: node generate-api-docs.mjs 3.0.0');
  process.exit(1);
}

const jsonPath = join(REPO_ROOT, 'docs/api', `v${version}.json`);
if (!existsSync(jsonPath)) {
  console.error(`Missing input: ${jsonPath}`);
  process.exit(1);
}

// Astro/Starlight strips dots from URL slugs, so 'v3.0.0' directory would
// resolve to '/v300/' URLs. Use dashes in the directory/URL and keep the
// dotted version in user-facing titles/labels only.
const versionSlug = version.replace(/\./g, '-');
const outRoot = join(REPO_ROOT, 'web/sites/api/src/content/docs', `v${versionSlug}`);

// Clean previous output for this version only (never other versions or unrelated files).
if (existsSync(outRoot)) {
  rmSync(outRoot, { recursive: true });
}
mkdirSync(outRoot, { recursive: true });

const data = JSON.parse(readFileSync(jsonPath, 'utf8'));

// --- helpers ---

function slugify(str) {
  return String(str)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
}

function escapeYaml(str) {
  // For description strings in frontmatter, quote and escape double quotes.
  if (str == null) return '""';
  return `"${String(str).replace(/"/g, '\\"').replace(/\n/g, ' ').trim()}"`;
}

function renderParameters(params) {
  if (!params || params.length === 0) return '';
  const rows = params
    .map((p) => {
      const name = p.name || '';
      const type = p.type || 'any';
      const req = p.required ? 'yes' : 'no';
      const def = p.default === '' || p.default == null ? '—' : `\`${p.default}\``;
      const hint = (p.hint || '').replace(/\|/g, '\\|').replace(/\n/g, ' ').trim();
      return `| \`${name}\` | \`${type}\` | ${req} | ${def} | ${hint} |`;
    })
    .join('\n');
  return [
    '## Parameters',
    '',
    '| Name | Type | Required | Default | Description |',
    '| ---- | ---- | -------- | ------- | ----------- |',
    rows,
    '',
  ].join('\n');
}

function renderExtended(extended) {
  if (!extended || !extended.hasExtended || !extended.docs) return '';
  // extended.docs often contains <pre><code> blocks. Pass through as HTML —
  // Astro/Starlight renders inline HTML inside markdown.
  return ['## Examples', '', extended.docs, ''].join('\n');
}

// --- main ---

const sections = new Map();
for (const fn of data.functions) {
  const section = fn.tags?.section || 'Miscellaneous';
  if (!sections.has(section)) sections.set(section, []);
  sections.get(section).push(fn);
}

let written = 0;

// Version index
const versionIndex = [
  '---',
  `title: Wheels ${version} API Reference`,
  `description: ${escapeYaml(`Function reference for Wheels version ${version}.`)}`,
  '---',
  '',
  `All ${data.functions.length} functions available in Wheels ${version}, grouped by section.`,
  '',
  ...[...sections.entries()].map(
    ([section, fns]) =>
      `- [${section}](/${`v${versionSlug}/${slugify(section)}/`}) — ${fns.length} function${fns.length === 1 ? '' : 's'}`
  ),
  '',
].join('\n');
writeFileSync(join(outRoot, 'index.md'), versionIndex);

for (const [section, fns] of sections) {
  const sectionSlug = slugify(section);
  const sectionDir = join(outRoot, sectionSlug);
  mkdirSync(sectionDir, { recursive: true });

  // Section index
  const sectionIndex = [
    '---',
    `title: ${section}`,
    `description: ${escapeYaml(`${fns.length} ${section} functions in Wheels ${version}.`)}`,
    '---',
    '',
    ...fns
      .sort((a, b) => a.name.localeCompare(b.name))
      .map((fn) => `- [\`${fn.name}()\`](/${`v${versionSlug}/${sectionSlug}/${slugify(fn.name)}/`}) — ${(fn.hint || '').split('\n')[0].slice(0, 120)}`),
    '',
  ].join('\n');
  writeFileSync(join(sectionDir, 'index.md'), sectionIndex);

  for (const fn of fns) {
    const fnSlug = slugify(fn.name);
    const availableIn = Array.isArray(fn.availableIn) ? fn.availableIn : [];
    const returntype = fn.returntype || 'any';
    const category = fn.tags?.category || '';

    const front = [
      '---',
      `title: ${fn.name}()`,
      `description: ${escapeYaml((fn.hint || '').split('\n')[0].slice(0, 160))}`,
      'sidebar:',
      `  label: ${fn.name}()`,
      `  order: 0`,
      '---',
      '',
      '## Signature',
      '',
      `\`${fn.name}()\` — returns \`${returntype}\``,
      '',
      availableIn.length > 0
        ? `**Available in:** ${availableIn.map((x) => `\`${x}\``).join(', ')}`
        : '',
      category ? `**Category:** ${category}` : '',
      '',
      '## Description',
      '',
      fn.hint || '_(no description)_',
      '',
    ].join('\n');

    const body = [front, renderParameters(fn.parameters), renderExtended(fn.extended)].join('\n');

    writeFileSync(join(sectionDir, `${fnSlug}.md`), body);
    written++;
  }
}

console.error(`Generated ${written} function pages across ${sections.size} sections → ${outRoot}`);
