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

  const fixture = await createFixture();
  try {
    const result = await runExec(program, args, { cwd: fixture });
    return assertCliResult(result, example.attrs);
  } finally {
    await destroyFixture(fixture);
  }
}
