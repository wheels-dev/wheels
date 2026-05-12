import { readFile, writeFile, readdir, stat } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { join, resolve } from 'node:path';

const REPO_ROOT = resolve(new URL('../../..', import.meta.url).pathname);
const VENDOR = `${REPO_ROOT}/vendor/wheels`;
const CACHE = resolve(new URL('./', import.meta.url).pathname, '../source-map.cache.json');

const SCAN_DIRS = ['model', 'controller', 'mapper', 'migrator', 'view', 'global'];
const FN_RE = /^\s*(public|private|package|remote)?\s*(?:[A-Za-z][\w.]*\s+)?function\s+([A-Za-z_$][\w$]*)\s*\(/gm;

async function walk(dir) {
  const out = [];
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) out.push(...(await walk(full)));
    else if (entry.isFile() && (full.endsWith('.cfc') || full.endsWith('.cfm'))) out.push(full);
  }
  return out;
}

async function buildIndex() {
  const index = Object.create(null);
  for (const sub of SCAN_DIRS) {
    const root = join(VENDOR, sub);
    if (!existsSync(root)) continue;
    const files = await walk(root);
    for (const file of files) {
      const text = await readFile(file, 'utf8');
      let match;
      const re = new RegExp(FN_RE);
      while ((match = re.exec(text)) !== null) {
        const fnName = match[2];
        if (fnName.startsWith('$')) continue;
        const access = (match[1] || 'public').toLowerCase();
        const lineNumber = text.slice(0, match.index).split('\n').length;
        (index[fnName] ||= []).push({
          file: file.slice(REPO_ROOT.length + 1),
          line: lineNumber,
          access,
        });
      }
    }
  }
  return index;
}

let cached;
export async function getIndex({ refresh = false } = {}) {
  if (cached && !refresh) return cached;
  if (!refresh && existsSync(CACHE)) {
    try {
      cached = JSON.parse(await readFile(CACHE, 'utf8'));
      return cached;
    } catch {}
  }
  cached = await buildIndex();
  await writeFile(CACHE, JSON.stringify(cached, null, 2));
  return cached;
}

export async function locateFunction(name) {
  const idx = await getIndex();
  return idx[name] || [];
}
