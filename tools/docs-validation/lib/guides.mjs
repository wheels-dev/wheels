import { readFile, readdir, stat } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { join, relative, resolve } from 'node:path';

const REPO_ROOT = resolve(new URL('../../..', import.meta.url).pathname);
const GUIDES_ROOT = `${REPO_ROOT}/web/sites/guides/src/content/docs/v4-0-0-snapshot`;

const MDX_RE = /\.(mdx?|md)$/i;
const FRONTMATTER_RE = /^---\n([\s\S]*?)\n---\n/;
const CODE_BLOCK_RE = /```([a-zA-Z0-9_+-]*)([^\n]*)\n([\s\S]*?)```/g;
const TEST_META_RE = /\{test:([^}]+)\}/;

export function relativeToGuidesRoot(absPath) {
  return relative(GUIDES_ROOT, absPath);
}

export async function listDirectories() {
  const entries = await readdir(GUIDES_ROOT, { withFileTypes: true });
  return entries.filter((e) => e.isDirectory()).map((e) => e.name).sort();
}

export async function listPagesInDirectory(dirName) {
  const dir = join(GUIDES_ROOT, dirName);
  if (!existsSync(dir)) return [];
  const out = [];
  await collectPages(dir, out);
  return out.sort();
}

async function collectPages(dir, out) {
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) await collectPages(full, out);
    else if (entry.isFile() && MDX_RE.test(entry.name)) {
      out.push(relative(GUIDES_ROOT, full));
    }
  }
}

export async function loadGuidePage(relPath) {
  const abs = join(GUIDES_ROOT, relPath);
  if (!existsSync(abs)) throw new Error(`page not found: ${relPath}`);
  const content = await readFile(abs, 'utf8');
  return {
    relPath,
    absPath: abs,
    repoRelPath: relative(REPO_ROOT, abs),
    content,
    frontmatter: parseFrontmatter(content),
    blocks: extractCodeBlocks(content),
  };
}

function parseFrontmatter(content) {
  const m = FRONTMATTER_RE.exec(content);
  if (!m) return null;
  const raw = m[1];
  const out = {};
  for (const line of raw.split('\n')) {
    const km = /^([A-Za-z][\w-]*):\s*(.*)$/.exec(line);
    if (km) out[km[1]] = km[2].trim();
  }
  return out;
}

function extractCodeBlocks(content) {
  const blocks = [];
  let match;
  const re = new RegExp(CODE_BLOCK_RE);
  while ((match = re.exec(content)) !== null) {
    const lang = match[1] || '';
    const meta = (match[2] || '').trim();
    const body = match[3];
    const startLine = content.slice(0, match.index).split('\n').length;
    const testTagMatch = TEST_META_RE.exec(meta);
    blocks.push({
      lang,
      meta,
      body,
      startLine,
      bodyLength: body.length,
      tested: testTagMatch !== null,
      testKind: testTagMatch ? testTagMatch[1].split(/\s/)[0] : null,
      illustrative: /title=/.test(meta) && !testTagMatch,
    });
  }
  return blocks;
}

export function summarizeBlocks(blocks) {
  return {
    total: blocks.length,
    tested: blocks.filter((b) => b.tested).length,
    illustrative: blocks.filter((b) => b.illustrative).length,
    untested: blocks.filter((b) => !b.tested && !b.illustrative).length,
    byKind: blocks.reduce((acc, b) => {
      if (b.testKind) acc[b.testKind] = (acc[b.testKind] || 0) + 1;
      return acc;
    }, {}),
  };
}
