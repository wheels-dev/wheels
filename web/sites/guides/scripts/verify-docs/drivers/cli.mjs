import { runExec, tokenize } from '../lib/exec.mjs';
import { createFixture, destroyFixture } from '../lib/fixtures.mjs';

/**
 * Runs a `wheels` command in a fresh fixture app and asserts stdout + exit.
 *
 * attrs:
 *   cmd              — command string, whitespace-tokenized (required)
 *   asserts-stdout   — substring that must appear in stdout (optional)
 *   asserts-exit     — expected exit code (default 0)
 */
export async function runCli(example) {
  const cmd = example.attrs.cmd;
  if (!cmd) return { ok: false, message: 'missing required attr: cmd' };

  const expectedExit =
    example.attrs['asserts-exit'] !== undefined
      ? Number(example.attrs['asserts-exit'])
      : 0;
  const expectedStdout = example.attrs['asserts-stdout'];

  let tokens;
  try {
    tokens = tokenize(cmd);
  } catch (err) {
    return { ok: false, message: `tokenize failed: ${err.message}` };
  }
  const [program, ...args] = tokens;

  const fixture = await createFixture();
  try {
    const result = await runExec(program, args, { cwd: fixture });
    if (result.code !== expectedExit) {
      return {
        ok: false,
        message: `expected exit ${expectedExit}, got ${result.code}\n--- stdout ---\n${result.stdout}\n--- stderr ---\n${result.stderr}`,
      };
    }
    if (expectedStdout !== undefined && !result.stdout.includes(expectedStdout)) {
      return {
        ok: false,
        message: `stdout missing expected text "${expectedStdout}"\n--- stdout ---\n${result.stdout}`,
      };
    }
    return { ok: true };
  } finally {
    await destroyFixture(fixture);
  }
}
