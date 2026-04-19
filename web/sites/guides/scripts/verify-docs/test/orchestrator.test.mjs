import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

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
