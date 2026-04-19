import { spawn } from 'node:child_process';

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
  // Whitelist the spawn options we actually need. Anything else (especially
  // `shell`) is dropped — we must never let a caller re-enable shell execution.
  const { cwd, env, timeout } = opts;
  const spawnOpts = {
    stdio: ['ignore', 'pipe', 'pipe'],
    shell: false,
  };
  if (cwd !== undefined) spawnOpts.cwd = cwd;
  if (env !== undefined) spawnOpts.env = env;
  if (timeout !== undefined) spawnOpts.timeout = timeout;

  return new Promise((resolve) => {
    const proc = spawn(program, args, spawnOpts);
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
