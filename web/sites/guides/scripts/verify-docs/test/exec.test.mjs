import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { wheelsBinaryAttestation } from '../lib/exec.mjs';

const TIMEOUT = 120_000;

// The attestation line must state which MODE the run exercised (#3042):
// CI sets WHEELS_ATTEST_MODE when it overlays the checkout's cli/lucli
// module onto the installed CLI; without it the line must say the binary
// ran as-installed so a green run is never mistaken for branch coverage.

test('attestation includes mode from WHEELS_ATTEST_MODE', { timeout: TIMEOUT }, async () => {
  const prev = process.env.WHEELS_ATTEST_MODE;
  process.env.WHEELS_ATTEST_MODE = 'checkout cli/lucli module overlay @ deadbeef';
  try {
    const line = await wheelsBinaryAttestation();
    assert.match(line, /mode: checkout cli\/lucli module overlay @ deadbeef/);
  } finally {
    if (prev === undefined) delete process.env.WHEELS_ATTEST_MODE;
    else process.env.WHEELS_ATTEST_MODE = prev;
  }
});

test('attestation defaults to as-installed mode when WHEELS_ATTEST_MODE is unset', { timeout: TIMEOUT }, async () => {
  const prev = process.env.WHEELS_ATTEST_MODE;
  delete process.env.WHEELS_ATTEST_MODE;
  try {
    const line = await wheelsBinaryAttestation();
    assert.match(line, /mode: as-installed/);
    // Still carries the original path + resolution + version segments.
    assert.match(line, /wheels binary: /);
    assert.match(line, /\(via (WHEELS_BIN|PATH discovery)\)/);
  } finally {
    if (prev !== undefined) process.env.WHEELS_ATTEST_MODE = prev;
  }
});

// A `wheels` call that never finishes used to stall the harness until the test's own timeout and then
// hang the job: runExec() had no default timeout and waited for its output pipes to close, which a
// leftover process can hold open forever. These use small `node` programs in place of `wheels`.
const NODE = process.execPath;

// Starts a grandchild that inherits the output pipes and sleeps, prints its pid, then (optionally) exits.
function parentScript({ exit }) {
  return [
    "const { spawn } = require('node:child_process');",
    "const g = spawn(process.execPath, ['-e', 'setInterval(() => {}, 1000)'], { stdio: 'inherit' });",
    "console.log(g.pid);",
    exit ? "setTimeout(() => process.exit(0), 100);" : "setInterval(() => {}, 1000);",
  ].join('\n');
}

function alive(pid) {
  try { process.kill(pid, 0); return true; } catch { return false; }
}

async function waitDead(pid, ms) {
  const deadline = Date.now() + ms;
  while (Date.now() < deadline && alive(pid)) await new Promise((r) => setTimeout(r, 100));
  return !alive(pid);
}

test('a command that never exits fails fast with a timeout that names it', { timeout: 30_000 }, async () => {
  const { runExec } = await import('../lib/exec.mjs');
  const started = Date.now();
  const r = await runExec(NODE, ['-e', 'setInterval(() => {}, 1000)'], { timeout: 800 });
  assert.ok(Date.now() - started < 10_000, 'runExec did not return promptly');
  assert.equal(r.code, -1);
  assert.equal(r.timedOut, true);
  assert.match(r.stderr, /timed out after 0\.8s running /);
  assert.match(r.stderr, /setInterval/);
});

test('returns once the command exits, even when a leftover process holds its output pipes', { timeout: 30_000 }, async () => {
  const { runExec } = await import('../lib/exec.mjs');
  let grandchild;
  try {
    const started = Date.now();
    const r = await runExec(NODE, ['-e', parentScript({ exit: true })]);
    grandchild = Number(r.stdout.trim().split('\n')[0]);
    assert.ok(Date.now() - started < 10_000, 'runExec waited for the leftover process');
    assert.equal(r.code, 0);
  } finally {
    if (grandchild) try { process.kill(grandchild, 'SIGKILL'); } catch {}
  }
});

test('a timeout kills the whole process group, so nothing it started lingers', { timeout: 30_000 }, async () => {
  const { runExec } = await import('../lib/exec.mjs');
  let grandchild;
  try {
    const r = await runExec(NODE, ['-e', parentScript({ exit: false })], { timeout: 1500 });
    grandchild = Number(r.stdout.trim().split('\n')[0]);
    assert.equal(r.timedOut, true);
    assert.ok(grandchild > 0, `no grandchild pid in stdout: ${r.stdout}`);
    assert.ok(await waitDead(grandchild, 5000), `grandchild ${grandchild} survived the timeout`);
  } finally {
    if (grandchild) try { process.kill(grandchild, 'SIGKILL'); } catch {}
  }
});

test('the default timeout comes from WHEELS_EXEC_TIMEOUT_MS', async () => {
  const { defaultExecTimeout } = await import('../lib/exec.mjs');
  assert.equal(defaultExecTimeout({ WHEELS_EXEC_TIMEOUT_MS: '5000' }), 5000);
  assert.equal(defaultExecTimeout({}), 240_000);
  assert.equal(defaultExecTimeout({ WHEELS_EXEC_TIMEOUT_MS: 'nope' }), 240_000);
});
