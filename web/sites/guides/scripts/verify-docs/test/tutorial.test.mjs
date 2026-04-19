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

import { partitionAndOrder } from '../lib/orchestrator.mjs';

test('partitionAndOrder sorts cumulative examples by (sidebarOrder, step, line)', () => {
  const examples = [
    { file: 'a.mdx', line: 10, kind: 'tutorial', attrs: { step: '2', file: 'x.cfc' }, sidebarOrder: 2 },
    { file: 'b.mdx', line: 5, kind: 'tutorial', attrs: { step: '1', file: 'y.cfc' }, sidebarOrder: 1 },
    { file: 'a.mdx', line: 30, kind: 'cli', attrs: { cmd: 'wheels --version', step: '3' }, sidebarOrder: 2 },
    { file: 'c.mdx', line: 5, kind: 'cli', attrs: { cmd: 'wheels info' }, sidebarOrder: 3 },
    { file: 'a.mdx', line: 20, kind: 'compile', attrs: {}, sidebarOrder: 2 },
  ];
  const { perBlock, cumulative } = partitionAndOrder(examples);
  assert.deepEqual(
    cumulative.map((e) => [e.file, e.line]),
    [
      ['b.mdx', 5],
      ['a.mdx', 10],
      ['a.mdx', 30],
    ],
  );
  assert.equal(perBlock.length, 2);
  assert.equal(perBlock[0].kind, 'compile');
  assert.equal(perBlock[1].kind, 'cli');
  assert.equal(perBlock[1].attrs.cmd, 'wheels info');
});

test('readSidebarOrder reads frontmatter sidebar.order', async () => {
  const { readSidebarOrder } = await import('../lib/orchestrator.mjs');
  const tmp = join(here, 'fixtures', 'tmp-frontmatter.mdx');
  await mkdir(dirname(tmp), { recursive: true });
  await writeFile(tmp, '---\ntitle: X\nsidebar:\n  order: 5\n---\nbody', 'utf8');
  const order = await readSidebarOrder(tmp);
  assert.equal(order, 5);
  await rm(tmp);
});

test('readSidebarOrder returns 999 when frontmatter missing order', async () => {
  const { readSidebarOrder } = await import('../lib/orchestrator.mjs');
  const tmp = join(here, 'fixtures', 'tmp-no-order.mdx');
  await mkdir(dirname(tmp), { recursive: true });
  await writeFile(tmp, '---\ntitle: X\n---\nbody', 'utf8');
  const order = await readSidebarOrder(tmp);
  assert.equal(order, 999);
  await rm(tmp);
});
