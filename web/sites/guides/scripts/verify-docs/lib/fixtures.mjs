import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { runExec } from './exec.mjs';

/**
 * Creates a fresh SQLite-backed Wheels app in a tmp directory.
 * Returns the absolute path to the app root.
 *
 * Phase 0: invokes `wheels new <name> --no-open-browser`. SQLite is the
 * default datasource; no other flags required. The app boots to a working
 * state (migrations, controllers, routes) in ~1.5s locally.
 */
export async function createFixture(name = 'fixture') {
  const parent = await mkdtemp(join(tmpdir(), 'wheels-doctest-'));
  const result = await runExec(
    'wheels',
    ['new', name, '--no-open-browser'],
    { cwd: parent },
  );
  if (result.code !== 0) {
    await rm(parent, { recursive: true, force: true });
    throw new Error(
      `wheels new failed (exit ${result.code}):\n${result.stderr || result.stdout}`,
    );
  }
  return join(parent, name);
}

/**
 * Removes the fixture's parent tmp dir (which contains the app).
 */
export async function destroyFixture(fixturePath) {
  const parent = join(fixturePath, '..');
  await rm(parent, { recursive: true, force: true });
}
