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

const RESOLVED_WHEELS = resolveWheels();

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
  // sidesteps PATH lookup fragility inside test-runner workers. On
  // Linuxbrew + node --test workers, spawn ALSO ENOENTs on absolute
  // paths including /bin/bash (Node 22 test-runner posix_spawn quirk
  // we couldn't pin down). The main verify-docs run works — only the
  // harness unit tests hit this; those are soft-failed in CI.
  const resolvedProgram = program === 'wheels' ? RESOLVED_WHEELS : program;

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
