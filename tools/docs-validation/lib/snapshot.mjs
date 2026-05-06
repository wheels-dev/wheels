import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const REPO_ROOT = resolve(new URL('../../..', import.meta.url).pathname);
const DEFAULT_SNAPSHOT = `${REPO_ROOT}/docs/api/v4.0.0.json`;

export async function loadSnapshot(path = DEFAULT_SNAPSHOT) {
  const raw = await readFile(path, 'utf8');
  const snap = JSON.parse(raw);
  if (!Array.isArray(snap.functions) || !Array.isArray(snap.sections)) {
    throw new Error(`snapshot at ${path} is missing functions[] or sections[]`);
  }
  return snap;
}

export function listSections(snap) {
  return snap.sections.map((s) => s.name);
}

export function functionsInSection(snap, sectionName) {
  return snap.functions.filter((f) => f.tags?.section === sectionName);
}

export function findFunction(snap, name) {
  const matches = snap.functions.filter((f) => f.name === name);
  if (matches.length === 0) return null;
  if (matches.length === 1) return matches[0];
  return matches;
}
