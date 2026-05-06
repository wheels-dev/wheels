import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

const STATE_FILE = resolve(new URL('../', import.meta.url).pathname, 'state.json');

const STATUSES = ['pending', 'in_progress', 'done', 'failed', 'needs_human'];

export async function loadState(path = STATE_FILE) {
  if (!existsSync(path)) return { version: 1, items: {}, runs: [] };
  return JSON.parse(await readFile(path, 'utf8'));
}

export async function saveState(state, path = STATE_FILE) {
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, JSON.stringify(state, null, 2) + '\n');
}

export function itemKey(kind, id) {
  return `${kind}:${id}`;
}

export function getItem(state, kind, id) {
  return state.items[itemKey(kind, id)];
}

export function setItem(state, kind, id, patch) {
  const key = itemKey(kind, id);
  if (patch.status && !STATUSES.includes(patch.status)) {
    throw new Error(`invalid status: ${patch.status}`);
  }
  const prev = state.items[key] ?? { kind, id, status: 'pending', attempts: 0 };
  state.items[key] = {
    ...prev,
    ...patch,
    updatedAt: new Date().toISOString(),
  };
  return state.items[key];
}

export function shouldAttempt(state, kind, id) {
  const item = getItem(state, kind, id);
  if (!item) return true;
  return item.status === 'pending' || item.status === 'failed';
}

export function summary(state) {
  const counts = { pending: 0, in_progress: 0, done: 0, failed: 0, needs_human: 0 };
  for (const item of Object.values(state.items)) counts[item.status]++;
  return counts;
}
