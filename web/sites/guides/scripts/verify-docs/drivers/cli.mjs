import { runExec, tokenize } from '../lib/exec.mjs';
import { createFixture, destroyFixture } from '../lib/fixtures.mjs';
import { assertCliResult } from '../lib/cli-assert.mjs';

/**
 * Runs a `wheels` command in a fresh fixture app and asserts output + exit.
 *
 * attrs:
 *   cmd              — command string, whitespace-tokenized (required)
 *   asserts-stdout   — substring that must appear in stdout (optional)
 *   asserts-stderr   — substring that must appear in stderr (optional)
 *   asserts-output   — substring that must appear in stdout OR stderr (optional)
 *   asserts-exit     — expected exit code (default 0)
 *
 * Why three output asserts: the `wheels` CLI writes user-facing reports to
 * stderr for some commands (e.g., `wheels info`) and to stdout for others
 * (e.g., `wheels --version`). `asserts-output` is the forgiving default
 * when the author doesn't care which stream the text lands on.
 */
// Transient error patterns from gap #11 — LuCLI concurrency races.
// Shared between createFixture retry and per-block retry.
const TRANSIENT_PATTERNS = [
  /Can't cast String \[\] to a value of type \[Struct\]/,
  /because "engine" is null/,
  /ScriptEngine\.put/,
  /^spawn .* ENOENT$/m,
  /spawn \/home\/linuxbrew.*ENOENT/,
];

function isTransient(result) {
  if (!result || result.code === 0) return false;
  const text = `${result.stderr || ''}${result.stdout || ''}`;
  return TRANSIENT_PATTERNS.some((p) => p.test(text));
}

export async function runCli(example) {
  const cmd = example.attrs.cmd;
  if (!cmd) return { ok: false, message: 'missing required attr: cmd' };

  let tokens;
  try {
    tokens = tokenize(cmd);
  } catch (err) {
    return { ok: false, message: `tokenize failed: ${err.message}` };
  }
  const [program, ...args] = tokens;

  // Retry the whole block on transient gap #11 errors. createFixture
  // has its own retry for fixture creation itself; this covers the
  // subsequent runExec call which can also hit transient spawn ENOENT
  // at high parallelism.
  const MAX_ATTEMPTS = 4;
  let lastResult;
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    const fixture = await createFixture();
    try {
      lastResult = await runExec(program, args, { cwd: fixture });
    } finally {
      await destroyFixture(fixture);
    }
    if (!isTransient(lastResult)) break;
    await new Promise((r) => setTimeout(r, 150 * attempt));
  }
  return assertCliResult(lastResult, example.attrs);
}
