import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { spawn } from 'node:child_process';
import { writeFile, mkdir, rm, mkdtemp } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { partitionAndOrder, readSidebarOrder } from '../lib/orchestrator.mjs';
import { bodyHash } from '../lib/allowlist.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const entry = join(here, '..', 'verify-docs.mjs');
const fixture = join(here, 'fixtures/sample.mdx');

function runEntry(args, env = {}) {
  return new Promise((resolve) => {
    const proc = spawn('node', [entry, ...args], {
      stdio: ['ignore', 'pipe', 'pipe'],
      shell: false,
      env: { ...process.env, ...env },
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
  // Phase 1 drivers: cli + tutorial + compile. Fixture has compile + cli +
  // tutorial; all three pass (compile falls back to bracket-check when
  // LuCLI PR #1 isn't installed, which still accepts the balanced sample).
  assert.equal(code, 0);
  assert.match(stdout, /passed/);
});

test('verify-docs exits 2 when no files match', async () => {
  const { code } = await runEntry(['/nonexistent/path/does/not/exist.mdx']);
  assert.equal(code, 2);
});

test('verify-docs allowlist masks expected failures', { timeout: 300_000 }, async () => {
  const dir = await mkdtemp(join(tmpdir(), 'vd-e2e-'));
  try {
    // unbalanced brackets: fails in both native and fallback compile modes
    const body = 'component {\n  function broken( {\n}';
    const page = join(dir, 'broken.mdx');
    await writeFile(page, `---\ntitle: Broken\n---\n\n\`\`\`cfm {test:compile}\n${body}\n\`\`\`\n`, 'utf8');

    const without = await runEntry([page]);
    assert.equal(without.code, 1, `expected failure without allowlist:\n${without.stdout}`);
    assert.match(without.stdout, /body-sha256/);

    const allowlist = join(dir, 'expected-failures.json');
    await writeFile(
      allowlist,
      JSON.stringify({
        entries: [
          { file: 'broken.mdx', bodySha256: bodyHash(body), reason: 'deliberately broken e2e fixture', issue: '#3041' },
        ],
      }),
      'utf8',
    );
    const withList = await runEntry([page], { VERIFY_DOCS_ALLOWLIST: allowlist });
    assert.equal(withList.code, 0, `allowlisted run should exit 0:\n${withList.stdout}`);
    assert.match(withList.stdout, /expected failure/i);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});

test('verify-docs exits 2 on an invalid allowlist', { timeout: 300_000 }, async () => {
  const dir = await mkdtemp(join(tmpdir(), 'vd-e2e-bad-allowlist-'));
  try {
    const allowlist = join(dir, 'expected-failures.json');
    await writeFile(
      allowlist,
      JSON.stringify({ entries: [{ file: 'a.mdx', bodySha256: 'abcdef012345', reason: '', issue: '#1' }] }),
      'utf8',
    );
    const { code, stderr } = await runEntry([fixture], { VERIFY_DOCS_ALLOWLIST: allowlist });
    assert.equal(code, 2);
    assert.match(stderr, /reason/);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
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
