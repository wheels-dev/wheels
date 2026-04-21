import { spawn, spawnSync } from 'node:child_process';
import { statSync, accessSync, constants } from 'node:fs';

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

const RESOLVED_WHEELS = resolveWheels();

if (process.env.VERIFY_DOCS_DEBUG) {
  console.error('[exec.mjs] RESOLVED_WHEELS =', RESOLVED_WHEELS);
  console.error('[exec.mjs] process.pid =', process.pid);
  console.error('[exec.mjs] process.env.LUCLI_HOME =', process.env.LUCLI_HOME);
}

/**
 * Launches `program` with the given argv array. Never invokes a shell.
 * Returns `{ code, stdout, stderr }`. `code` is the process exit code, or -1
 * on spawn error (stderr will contain the Node error message in that case).
 *
 * Why no shell: the harness runs command strings pulled from MDX metadata.
 * Using `sh -c` would be a shell-injection surface. All callers must
 * pre-tokenize into program + args.
 */
export function runExec(program, args = [], opts = {}) {
  const { cwd, env, timeout } = opts;
  const spawnOpts = {
    stdio: ['ignore', 'pipe', 'pipe'],
    shell: false,
  };
  if (cwd !== undefined) spawnOpts.cwd = cwd;
  if (env !== undefined) spawnOpts.env = env;
  if (timeout !== undefined) spawnOpts.timeout = timeout;

  // Substitute the absolute `wheels` path resolved at module load.
  // Workers inherit default env from the parent; the resolved path
  // sidesteps any PATH lookup fragility inside test-runner workers.
  const resolvedProgram = program === 'wheels' ? RESOLVED_WHEELS : program;

  if (process.env.VERIFY_DOCS_DEBUG && resolvedProgram.startsWith('/')) {
    try {
      const s = statSync(resolvedProgram);
      accessSync(resolvedProgram, constants.X_OK);
      console.error(`[exec.mjs] spawn pre-check: ${resolvedProgram} isFile=${s.isFile()} isSymlink=${s.isSymbolicLink()} mode=${s.mode.toString(8)} executable=yes pid=${process.pid}`);
    } catch (e) {
      console.error(`[exec.mjs] spawn pre-check FAILED: ${resolvedProgram} err=${e.code} msg=${e.message} pid=${process.pid}`);
    }
  }

  return new Promise((resolve) => {
    const proc = spawn(resolvedProgram, args, spawnOpts);
    let stdout = '';
    let stderr = '';
    proc.stdout.on('data', (d) => (stdout += d.toString()));
    proc.stderr.on('data', (d) => (stderr += d.toString()));
    proc.on('error', (err) => resolve({ code: -1, stdout, stderr: stderr + err.message }));
    proc.on('close', (code) => resolve({ code, stdout, stderr }));
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
