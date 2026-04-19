import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { existsSync } from 'node:fs';
import { readFile, writeFile, mkdir, rm } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { resetFixture, writeFixtureFile, readFixtureFile, appendFixtureFile, runInFixture, fixturePath } from '../lib/tutorial-fixture.mjs';

const TIMEOUT = 180_000;
const here = dirname(fileURLToPath(import.meta.url));
const ROOT = join(here, '..', 'fixtures', 'blog-tutorial');

test('resetFixture creates a fresh wheels app at the canonical path', { timeout: TIMEOUT }, async () => {
  await resetFixture();
  assert.equal(fixturePath(), ROOT);
  assert.ok(existsSync(join(ROOT, 'config', 'routes.cfm')), 'routes.cfm should exist');
  assert.ok(existsSync(join(ROOT, 'app')), 'app directory should exist');
});

test('writeFixtureFile overwrites relative paths within the fixture', { timeout: TIMEOUT }, async () => {
  await resetFixture();
  await writeFixtureFile('app/controllers/Probe.cfc', 'component { function ping() {} }');
  const body = await readFixtureFile('app/controllers/Probe.cfc');
  assert.match(body, /function ping/);
});

test('writeFixtureFile rejects paths that escape the fixture root', { timeout: TIMEOUT }, async () => {
  await resetFixture();
  await assert.rejects(
    () => writeFixtureFile('../outside.cfc', 'x'),
    /escapes fixture root/,
  );
  await assert.rejects(
    () => writeFixtureFile('/absolute.cfc', 'x'),
    /must be relative/,
  );
});

test('appendFixtureFile adds to existing file', { timeout: TIMEOUT }, async () => {
  await resetFixture();
  await writeFixtureFile('app/test.txt', 'line1\n');
  await appendFixtureFile('app/test.txt', 'line2\n');
  const body = await readFixtureFile('app/test.txt');
  assert.equal(body, 'line1\nline2\n');
});

test('runInFixture executes wheels command in the fixture cwd', { timeout: TIMEOUT }, async () => {
  await resetFixture();
  const result = await runInFixture(['--version']);
  assert.equal(result.code, 0);
  assert.match(result.stdout, /Wheels/);
});
