import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';

const REPO_ROOT = resolve(new URL('../../..', import.meta.url).pathname);
const REF_ROOT = `${REPO_ROOT}/vendor/wheels/public/docs/reference`;

function slugFor(scope, fnName) {
  return join(REF_ROOT, scope.toLowerCase(), `${fnName.toLowerCase()}.txt`);
}

export function referencePath(scope, fnName) {
  return slugFor(scope, fnName);
}

export async function readReference(scope, fnName) {
  const path = slugFor(scope, fnName);
  if (!existsSync(path)) return null;
  return readFile(path, 'utf8');
}

export async function readReferenceAnyScope(fnName, availableIn = []) {
  for (const scope of availableIn) {
    const body = await readReference(scope, fnName);
    if (body !== null) return { scope, body };
  }
  return null;
}

export async function writeReference(scope, fnName, body) {
  const path = slugFor(scope, fnName);
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, body, 'utf8');
  return path;
}
