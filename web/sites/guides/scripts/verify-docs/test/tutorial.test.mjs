import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
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

test('parseHttpAssert reads METHOD PATH → STATUS', async () => {
  const { parseHttpAssert } = await import('../drivers/tutorial.mjs');
  assert.deepEqual(
    parseHttpAssert('GET /posts → 200'),
    { method: 'GET', path: '/posts', status: 200, bodyIncludes: null },
  );
  assert.deepEqual(
    parseHttpAssert('POST /posts → 302 "Location: /posts/1"'),
    { method: 'POST', path: '/posts', status: 302, bodyIncludes: 'Location: /posts/1' },
  );
});

test('parseHttpAssert rejects malformed strings', async () => {
  const { parseHttpAssert } = await import('../drivers/tutorial.mjs');
  assert.throws(() => parseHttpAssert('bogus'), /malformed/);
  assert.throws(() => parseHttpAssert('GET /posts 200'), /arrow/);
});

test('tutorial driver walks mini-tutorial end to end', { timeout: 300_000 }, async () => {
  const { TutorialSession } = await import('../drivers/tutorial.mjs');
  const { extractExamples } = await import('../lib/extract.mjs');
  const { partitionAndOrder, enrichWithSidebarOrder } = await import('../lib/orchestrator.mjs');

  const dir = join(here, 'fixtures', 'mini-tutorial');
  const files = [join(dir, 'step-1.mdx'), join(dir, 'step-2.mdx')];
  const examples = await extractExamples(files);
  await enrichWithSidebarOrder(examples);
  const { cumulative } = partitionAndOrder(examples);

  const session = new TutorialSession();
  try {
    for (const ex of cumulative) {
      const result = ex.kind === 'tutorial'
        ? await session.applyTutorialExample(ex)
        : await session.applyCliExample(ex);
      assert.equal(result.ok, true, `example at ${ex.file}:${ex.line} failed: ${result.message ?? ''}`);
    }
  } finally {
    await session.stopServer();
  }
});
