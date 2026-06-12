import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { writeFile, mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { loadAllowlist, applyAllowlist, bodyHash } from '../lib/allowlist.mjs';

async function withAllowlistFile(content, fn) {
  const dir = await mkdtemp(join(tmpdir(), 'vd-allowlist-'));
  const file = join(dir, 'expected-failures.json');
  await writeFile(file, typeof content === 'string' ? content : JSON.stringify(content), 'utf8');
  try {
    return await fn(file);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

test('bodyHash is a deterministic 12-char hex digest', () => {
  const h = bodyHash('component {}');
  assert.match(h, /^[0-9a-f]{12}$/);
  assert.equal(h, bodyHash('component {}'));
  assert.notEqual(h, bodyHash('component { }'));
});

test('loadAllowlist returns entries from a valid file', async () => {
  await withAllowlistFile(
    {
      entries: [
        {
          file: 'src/content/docs/v4-0-0/basics/routing.mdx',
          bodySha256: 'abcdef012345',
          reason: 'tag fragment needs app context',
          issue: '#3041',
        },
      ],
    },
    async (file) => {
      const entries = await loadAllowlist(file);
      assert.equal(entries.length, 1);
      assert.equal(entries[0].issue, '#3041');
    },
  );
});

test('loadAllowlist returns [] when the file does not exist', async () => {
  const entries = await loadAllowlist('/nonexistent/expected-failures.json');
  assert.deepEqual(entries, []);
});

test('loadAllowlist rejects entries missing a reason', async () => {
  await withAllowlistFile(
    { entries: [{ file: 'a.mdx', bodySha256: 'abcdef012345', reason: '', issue: '#3041' }] },
    async (file) => {
      await assert.rejects(() => loadAllowlist(file), /reason/);
    },
  );
});

test('loadAllowlist rejects entries with an invalid issue ref', async () => {
  await withAllowlistFile(
    { entries: [{ file: 'a.mdx', bodySha256: 'abcdef012345', reason: 'why', issue: 'soon' }] },
    async (file) => {
      await assert.rejects(() => loadAllowlist(file), /issue/);
    },
  );
});

test('loadAllowlist rejects malformed shapes', async () => {
  await withAllowlistFile({ entries: 'nope' }, async (file) => {
    await assert.rejects(() => loadAllowlist(file), /entries/);
  });
  await withAllowlistFile('not json at all {', async (file) => {
    await assert.rejects(() => loadAllowlist(file), /JSON/);
  });
});

function result(file, body, ok) {
  return { file, line: 1, kind: 'compile', attrs: {}, body, ok, message: ok ? undefined : 'boom' };
}

test('applyAllowlist marks matching failures as expected', () => {
  const body = 'set(foo=);';
  const results = [result('/repo/web/sites/guides/src/content/docs/v4-0-0/a.mdx', body, false)];
  const entries = [
    { file: 'src/content/docs/v4-0-0/a.mdx', bodySha256: bodyHash(body), reason: 'r', issue: '#3041' },
  ];
  const { warnings } = applyAllowlist(results, entries, { checkOrphans: true });
  assert.equal(results[0].expected, true);
  assert.deepEqual(warnings, []);
});

test('applyAllowlist does not match when the body hash differs', () => {
  const results = [result('/g/src/content/docs/v4-0-0/a.mdx', 'set(foo=);', false)];
  const entries = [
    { file: 'src/content/docs/v4-0-0/a.mdx', bodySha256: 'deadbeef0000', reason: 'r', issue: '#3041' },
  ];
  const { warnings } = applyAllowlist(results, entries, { checkOrphans: false });
  assert.notEqual(results[0].expected, true);
  assert.equal(warnings.length, 0);
});

test('applyAllowlist warns on stale entries that now pass', () => {
  const body = 'x = 1;';
  const results = [result('/g/src/content/docs/v4-0-0/a.mdx', body, true)];
  const entries = [
    { file: 'src/content/docs/v4-0-0/a.mdx', bodySha256: bodyHash(body), reason: 'r', issue: '#3041' },
  ];
  const { warnings } = applyAllowlist(results, entries, { checkOrphans: true });
  assert.equal(results[0].expected, undefined);
  assert.equal(warnings.length, 1);
  assert.match(warnings[0], /passes/);
});

test('applyAllowlist warns on orphan entries only when checkOrphans is set', () => {
  const entries = [
    { file: 'src/content/docs/v4-0-0/gone.mdx', bodySha256: 'abcdef012345', reason: 'r', issue: '#3041' },
  ];
  const { warnings: w1 } = applyAllowlist([], entries, { checkOrphans: true });
  assert.equal(w1.length, 1);
  assert.match(w1[0], /no block/);
  const { warnings: w2 } = applyAllowlist([], entries, { checkOrphans: false });
  assert.equal(w2.length, 0);
});
