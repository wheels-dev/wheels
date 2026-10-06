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

test('a leftover from a command that exited is stopped when the harness exits', { timeout: 30_000 }, async () => {
  // A "harness" process runs a command that exits while its grandchild (think: a `wheels start` server)
  // keeps running, then exits itself. The grandchild must not outlive it: the isolated home it runs in
  // is deleted on exit, and a detached group no longer gets the terminal's Ctrl-C.
  const lib = new URL('../lib/exec.mjs', import.meta.url).href;
  const harness = [
    `const { runExec } = await import(${JSON.stringify(lib)});`,
    `const r = await runExec(process.execPath, ['-e', ${JSON.stringify(parentScript({ exit: true }))}]);`,
    "console.log(r.stdout.trim().split('\\n')[0]);",
    'process.exit(0);',
  ].join('\n');
  const { spawn } = await import('node:child_process');
  const proc = spawn(NODE, ['--input-type=module', '-e', harness], { stdio: ['ignore', 'pipe', 'inherit'] });
  let out = '';
  proc.stdout.on('data', (d) => (out += d));
  await new Promise((resolve) => proc.once('exit', resolve));
  const grandchild = Number(out.trim());
  try {
    assert.ok(grandchild > 0, `no grandchild pid: ${out}`);
    assert.ok(await waitDead(grandchild, 5000), `leftover ${grandchild} outlived the harness`);
  } finally {
    if (grandchild) try { process.kill(grandchild, 'SIGKILL'); } catch {}
  }
});

test('wheels starts are staggered, so JVMs never start at the same moment', { timeout: 60_000 }, async () => {
  // Simultaneous `wheels` JVM starts in one CLI home race in Lucee's OSGi bundle cache (#4450).
  // A fake `wheels` prints when it started; three called at once must start at least the gap apart.
  const { mkdtempSync, writeFileSync, chmodSync, rmSync } = await import('node:fs');
  const { tmpdir } = await import('node:os');
  const { join } = await import('node:path');
  const { spawn } = await import('node:child_process');
  const dir = mkdtempSync(join(tmpdir(), 'vd-gate-'));
  try {
    const fake = join(dir, 'wheels');
    writeFileSync(fake, `#!${process.execPath}\nconsole.log(Date.now()); setTimeout(() => {}, 300);\n`);
    chmodSync(fake, 0o755);
    const lib = new URL('../lib/exec.mjs', import.meta.url).href;
    const harness = [
      `const { runExec } = await import(${JSON.stringify(lib)});`,
      "const rs = await Promise.all([1, 2, 3].map(() => runExec('wheels', ['x'])));",
      "console.log(JSON.stringify(rs.map((r) => Number(r.stdout.trim()))));",
    ].join('\n');
    const env = { ...process.env, WHEELS_BIN: fake, WHEELS_START_GAP_MS: '1000' };
    const proc = spawn(NODE, ['--input-type=module', '-e', harness], { env, stdio: ['ignore', 'pipe', 'inherit'] });
    let out = '';
    proc.stdout.on('data', (d) => (out += d));
    await new Promise((resolve) => proc.once('exit', resolve));
    const starts = JSON.parse(out.trim().split('\n').pop()).sort((a, b) => a - b);
    assert.equal(starts.length, 3);
    for (let i = 1; i < starts.length; i++) {
      // The fake records its start after its own Node boot, which varies; leave room for that.
      assert.ok(starts[i] - starts[i - 1] >= 600, `starts ${starts[i - 1]} and ${starts[i]} are under the gap apart`);
    }
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('the start gap comes from WHEELS_START_GAP_MS', async () => {
  const { startGap } = await import('../lib/exec.mjs');
  assert.equal(startGap({ WHEELS_START_GAP_MS: '250' }), 250);
  assert.equal(startGap({ WHEELS_START_GAP_MS: '0' }), 0);
  assert.equal(startGap({}), 1000);
  assert.equal(startGap({ WHEELS_START_GAP_MS: 'nope' }), 1000);
});
