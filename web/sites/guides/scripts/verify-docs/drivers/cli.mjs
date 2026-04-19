import { runExec, tokenize } from '../lib/exec.mjs';
import { createFixture, destroyFixture } from '../lib/fixtures.mjs';

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
export async function runCli(example) {
  const cmd = example.attrs.cmd;
  if (!cmd) return { ok: false, message: 'missing required attr: cmd' };

  const expectedExit =
    example.attrs['asserts-exit'] !== undefined
      ? Number(example.attrs['asserts-exit'])
      : 0;
  const expectedStdout = example.attrs['asserts-stdout'];
  const expectedStderr = example.attrs['asserts-stderr'];
  const expectedOutput = example.attrs['asserts-output'];

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
    if (expectedStderr !== undefined && !result.stderr.includes(expectedStderr)) {
      return {
        ok: false,
        message: `stderr missing expected text "${expectedStderr}"\n--- stderr ---\n${result.stderr}`,
      };
    }
    if (
      expectedOutput !== undefined &&
      !(result.stdout.includes(expectedOutput) || result.stderr.includes(expectedOutput))
    ) {
      return {
        ok: false,
        message: `combined output missing expected text "${expectedOutput}"\n--- stdout ---\n${result.stdout}\n--- stderr ---\n${result.stderr}`,
      };
    }
    return { ok: true };
  } finally {
    await destroyFixture(fixture);
  }
}
