import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { spawn } from 'node:child_process';
import { writeFile, mkdir, rm } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { partitionAndOrder, readSidebarOrder } from '../lib/orchestrator.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const entry = join(here, '..', 'verify-docs.mjs');
const fixture = join(here, 'fixtures/sample.mdx');

function runEntry(args) {
  return new Promise((resolve) => {
    const proc = spawn('node', [entry, ...args], {
      stdio: ['ignore', 'pipe', 'pipe'],
      shell: false,
    });
    let stdout = '';
    let stderr = '';
    proc.stdout.on('data', (d) => (stdout += d.toString()));
    proc.stderr.on('data', (d) => (stderr += d.toString()));
    proc.on('close', (code) => resolve({ code, stdout, stderr }));
  });
}

test('verify-docs reports pass/fail counts', { timeout: 300_000 }, async () => {
  const { code, stdout } = await runEntry([fixture]);
  // Phase 1 drivers: cli + tutorial. Fixture has compile + cli + tutorial.
  // cli + tutorial pass, compile still reports "no driver" → exit 1.
  assert.equal(code, 1);
  assert.match(stdout, /passed/);
  assert.match(stdout, /failed/);
  assert.match(stdout, /no driver for kind "compile"/);
});

test('verify-docs exits 2 when no files match', async () => {
  const { code } = await runEntry(['/nonexistent/path/does/not/exist.mdx']);
  assert.equal(code, 2);
});

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
  const tmp = join(here, 'fixtures', 'tmp-frontmatter.mdx');
  await mkdir(dirname(tmp), { recursive: true });
  await writeFile(tmp, '---\ntitle: X\nsidebar:\n  order: 5\n---\nbody', 'utf8');
  const order = await readSidebarOrder(tmp);
  assert.equal(order, 5);
  await rm(tmp);
});

test('readSidebarOrder returns 999 when frontmatter missing order', async () => {
  const tmp = join(here, 'fixtures', 'tmp-no-order.mdx');
  await mkdir(dirname(tmp), { recursive: true });
  await writeFile(tmp, '---\ntitle: X\n---\nbody', 'utf8');
  const order = await readSidebarOrder(tmp);
  assert.equal(order, 999);
  await rm(tmp);
});
