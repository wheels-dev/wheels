import { spawn, spawnSync } from 'node:child_process';

/**
 * Resolve `wheels` to an absolute path at module load time. Node 22's
 * test-runner workers don't always propagate PATH the same way bash does,
 * so `spawn('wheels')` can ENOENT inside a worker even when bash can find
 * the binary. Resolving once at module load (main process) and passing
 * the absolute path sidesteps the lookup entirely.
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
  // Whitelist the spawn options we actually need. Anything else (especially
  // `shell`) is dropped — we must never let a caller re-enable shell execution.
  const { cwd, env, timeout } = opts;
  const spawnOpts = {
    stdio: ['ignore', 'pipe', 'pipe'],
    shell: false,
    // Pass env explicitly and augment PATH with common brew locations.
    // Node 22's test-runner workers inherit process.env but their spawn()
    // lookup doesn't always pick up homebrew dirs — explicit env with the
    // paths spliced in makes the binary resolvable.
    env: env ?? {
      ...process.env,
      PATH: [
        process.env.PATH,
        '/opt/homebrew/bin',
        '/usr/local/bin',
        '/home/linuxbrew/.linuxbrew/bin',
      ].filter(Boolean).join(':'),
    },
  };
  if (cwd !== undefined) spawnOpts.cwd = cwd;
  if (timeout !== undefined) spawnOpts.timeout = timeout;

  // Substitute absolute path for `wheels` to avoid PATH-lookup issues in
  // Node test-runner workers.
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
