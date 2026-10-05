import { spawn, spawnSync } from 'node:child_process';

/**
 * Resolve `wheels` to an absolute path at module load time. Node 22's
 * test-runner workers don't inherit PATH the same way bash does, so
 * `spawn('wheels')` can return ENOENT inside a worker even when bash
 * can resolve the binary. Looking up the absolute path in the main
 * module scope (before workers fork) sidesteps the lookup entirely.
 *
 * We do NOT pass explicit `env` to spawn — that breaks shebang-script
 * exec on Linuxbrew in a way whose root cause we haven't pinned down.
 * Default env inheritance works correctly for the spawned process.
 */
function resolveWheels() {
  if (process.env.WHEELS_BIN) return process.env.WHEELS_BIN;
  const r = spawnSync('/usr/bin/env', ['command', '-v', 'wheels'], { encoding: 'utf8' });
  if (r.status === 0 && r.stdout) {
    const first = r.stdout.split('\n')[0].trim();
    if (first) return first;
  }
  for (const prefix of ['/opt/homebrew/bin', '/usr/local/bin', '/home/linuxbrew/.linuxbrew/bin']) {
    const candidate = `${prefix}/wheels`;
    const test = spawnSync('/bin/sh', ['-c', `test -x "${candidate}"`]);
    if (test.status === 0) return candidate;
  }
  return 'wheels';
}

/**
 * Exported for the one spawn site that cannot go through runExec(): the
 * long-running tutorial dev server (drivers/tutorial.mjs ensureServer()),
 * which needs the raw child handle. It must spawn this same resolved
 * binary, or the attestation line would name one binary while tutorial
 * asserts-http blocks are served by whatever `wheels` is on PATH.
 */
export const RESOLVED_WHEELS = resolveWheels();

/**
 * One-line attestation of WHICH `wheels` binary this run exercises:
 * the resolved path, how it was resolved, its `--version` output, and
 * the MODE — whose CLI code the binary actually dispatches to (#3042).
 *
 * Mode comes from WHEELS_ATTEST_MODE. The CI docs-verify workflow sets
 * it after overlaying the checkout's cli/lucli module onto the installed
 * CLI's module dir, so a green CI run attests to the branch's CLI module
 * (on the released LuCLI runtime). Without the env var the line says
 * "as-installed": whatever module the resolved binary shipped with —
 * locally that's the released brew CLI, and a green run only attests
 * to that release, not your checkout.
 */
export async function wheelsBinaryAttestation() {
  const source = process.env.WHEELS_BIN ? 'WHEELS_BIN' : 'PATH discovery';
  const mode = process.env.WHEELS_ATTEST_MODE || 'as-installed (no module overlay declared)';
  const r = await runExec('wheels', ['--version']);
  const firstLine = `${r.stdout}\n${r.stderr}`
    .split('\n')
    .map((line) => line.trim())
    .find((line) => line !== '');
  const version =
    r.code === 0 && firstLine
      ? firstLine
      : `--version failed (exit ${r.code}${firstLine ? `: ${firstLine}` : ''})`;
  return `wheels binary: ${RESOLVED_WHEELS} (via ${source}) — ${version} — mode: ${mode}`;
}

/**
 * How long a single command may run before runExec() gives up on it: WHEELS_EXEC_TIMEOUT_MS when it
 * is a positive number, else 240 s. Below the harness tests' own 300 s limit, so a stuck command fails
 * with its name instead of as an anonymous test timeout.
 */
export function defaultExecTimeout(env = process.env) {
  const ms = Number(env.WHEELS_EXEC_TIMEOUT_MS);
  return Number.isFinite(ms) && ms > 0 ? ms : 240_000;
}

// After the command exits, how long to keep reading output a leftover process may still be writing.
const EXIT_GRACE_MS = 2_000;

// Commands still running. Each leads its own process group, so a Ctrl-C at the terminal no longer
// reaches it; when the harness exits (normally, or via the signal handlers in isolated-home.mjs),
// stop whatever is left rather than leave it running.
const running = new Set();
process.on('exit', () => {
  for (const proc of running) killGroup(proc, 'SIGKILL');
});

// Kill the child's whole process group (it leads one: spawned detached), so a JVM or anything else it
// started goes too; fall back to the child alone where groups aren't available.
function killGroup(proc, signal) {
  try {
    if (process.platform !== 'win32') {
      process.kill(-proc.pid, signal);
      return;
    }
  } catch {
    // no group (already gone, or not a group leader): try the child itself
  }
  try { proc.kill(signal); } catch {}
}

/**
 * Launches `program` with the given argv array. Never invokes a shell.
 * Returns `{ code, stdout, stderr }`, plus `timedOut: true` when the command was stopped for running
 * too long. `code` is the process exit code, or -1 on spawn error or timeout (stderr then carries the
 * reason).
 *
 * Why no shell: the harness runs command strings pulled from MDX metadata.
 * Using `sh -c` would be a shell-injection surface. All callers must
 * pre-tokenize into program + args.
 *
 * Bounded, so one stuck `wheels` can't stall the run (a hung `wheels` call used to wait out a test's
 * 300 s limit and then hang the job):
 * - `opts.timeout` (default defaultExecTimeout()) stops the command and the whole process group it
 *   leads, and reports "timed out after Ns running <program> <args>".
 * - It returns when the command exits, after a short grace for the last output, even if a leftover
 *   process still holds its output pipes. That leftover is not killed: a block may legitimately leave
 *   a server running (`wheels start`).
 */
export function runExec(program, args = [], opts = {}) {
  const { cwd, env } = opts;
  const timeout = opts.timeout ?? defaultExecTimeout();
  const spawnOpts = {
    stdio: ['ignore', 'pipe', 'pipe'],
    shell: false,
    // Its own process group, so a timeout can kill everything the command started.
    detached: process.platform !== 'win32',
  };
  if (cwd !== undefined) spawnOpts.cwd = cwd;
  if (env !== undefined) spawnOpts.env = env;

  // Substitute the absolute `wheels` path resolved at module load.
  // Belt-and-braces: also protects against shells where PATH doesn't
  // include the homebrew bin dir (e.g., a test runner spawned from a
  // stripped env). The separate "spawn PROGRAM ENOENT" failures we
  // used to see under node --test were not a Node bug — they came
  // from spawning with a cwd that no longer existed because
  // `wheels new` exited 0 despite a framework-not-found error. See
  // fixtures.mjs `createFixture` for the guard.
  const resolvedProgram = program === 'wheels' ? RESOLVED_WHEELS : program;
  const label = [program, ...args].join(' ');

  return new Promise((resolve) => {
    const proc = spawn(resolvedProgram, args, spawnOpts);
    running.add(proc);
    let stdout = '';
    let stderr = '';
    let settled = false;
    let graceTimer;
    const finish = (result) => {
      if (settled) return;
      settled = true;
      running.delete(proc);
      clearTimeout(timeoutTimer);
      clearTimeout(graceTimer);
      proc.stdout.destroy();
      proc.stderr.destroy();
      resolve(result);
    };
    const timeoutTimer = setTimeout(() => {
      killGroup(proc, 'SIGKILL');
      const reason = `timed out after ${timeout / 1000}s running ${label}`;
      finish({ code: -1, stdout, stderr: stderr ? `${stderr}\n${reason}` : reason, timedOut: true });
    }, timeout);
    proc.stdout.on('data', (d) => (stdout += d.toString()));
    proc.stderr.on('data', (d) => (stderr += d.toString()));
    proc.on('error', (err) => finish({ code: -1, stdout, stderr: stderr + err.message }));
    proc.on('exit', (code, signal) => {
      const exitCode = code ?? (signal ? -1 : 0);
      graceTimer = setTimeout(() => finish({ code: exitCode, stdout, stderr }), EXIT_GRACE_MS);
    });
    proc.on('close', (code, signal) => finish({ code: code ?? (signal ? -1 : 0), stdout, stderr }));
  });
}

/**
 * Whitespace-tokenizes a command string into [program, ...args].
 * Phase 0 does not support quoted arguments or shell features. Authors
 * who need those must restructure the command or mark it illustrative.
 */
export function tokenize(command) {
  const trimmed = command.trim();
  if (trimmed === '') {
    throw new Error('empty command');
  }
  return trimmed.split(/\s+/);
}
