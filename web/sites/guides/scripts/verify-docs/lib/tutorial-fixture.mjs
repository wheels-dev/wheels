import { readFile, writeFile, appendFile, mkdir, rm, stat } from 'node:fs/promises';
import { join, dirname, resolve, relative, isAbsolute } from 'node:path';
import { fileURLToPath } from 'node:url';
import { runExec } from './exec.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(join(here, '..', 'fixtures', 'blog-tutorial'));
const PARENT = dirname(ROOT);
const APP_NAME = 'blog-tutorial';

export function fixturePath() {
  return ROOT;
}

function resolveInside(relPath) {
  if (isAbsolute(relPath)) {
    throw new Error(`path must be relative: ${relPath}`);
  }
  const full = resolve(ROOT, relPath);
  const rel = relative(ROOT, full);
  if (rel.startsWith('..')) {
    throw new Error(`path escapes fixture root: ${relPath}`);
  }
  return full;
}

export async function resetFixture() {
  await rm(ROOT, { recursive: true, force: true });
  await mkdir(PARENT, { recursive: true });
  const result = await runExec(
    'wheels',
    ['new', APP_NAME, '--no-open-browser'],
    { cwd: PARENT },
  );
  if (result.code !== 0) {
    throw new Error(
      `wheels new failed (exit ${result.code}):\n${result.stderr || result.stdout}`,
    );
  }
}

export async function writeFixtureFile(relPath, body) {
  const full = resolveInside(relPath);
  await mkdir(dirname(full), { recursive: true });
  await writeFile(full, body, 'utf8');
}

export async function appendFixtureFile(relPath, body) {
  const full = resolveInside(relPath);
  await mkdir(dirname(full), { recursive: true });
  await appendFile(full, body, 'utf8');
}

export async function readFixtureFile(relPath) {
  const full = resolveInside(relPath);
  return await readFile(full, 'utf8');
}

export async function runInFixture(args, opts = {}) {
  return await runExec('wheels', args, { cwd: ROOT, ...opts });
}
