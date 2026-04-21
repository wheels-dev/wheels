/**
 * Asserts a spawned process result matches the attrs' expectations.
 * Shared by cli and tutorial drivers.
 *
 * attrs understood:
 *   asserts-exit    — expected exit code (default 0)
 *   asserts-stdout  — substring in stdout
 *   asserts-stderr  — substring in stderr
 *   asserts-output  — substring in stdout OR stderr
 *
 * Returns { ok: true } on match or { ok: false, message } on any mismatch.
 */
export function assertCliResult(result, attrs) {
  const expectedExit = attrs['asserts-exit'] !== undefined ? Number(attrs['asserts-exit']) : 0;
  if (result.code !== expectedExit) {
    return {
      ok: false,
      message: `expected exit ${expectedExit}, got ${result.code}\n--- stdout ---\n${result.stdout}\n--- stderr ---\n${result.stderr}`,
    };
  }
  const stdoutAssert = attrs['asserts-stdout'];
  const stderrAssert = attrs['asserts-stderr'];
  const outputAssert = attrs['asserts-output'];
  if (stdoutAssert !== undefined && !result.stdout.includes(stdoutAssert)) {
    return {
      ok: false,
      message: `stdout missing expected text "${stdoutAssert}"\n--- stdout ---\n${result.stdout}`,
    };
  }
  if (stderrAssert !== undefined && !result.stderr.includes(stderrAssert)) {
    return {
      ok: false,
      message: `stderr missing expected text "${stderrAssert}"\n--- stderr ---\n${result.stderr}`,
    };
  }
  if (outputAssert !== undefined && !(result.stdout.includes(outputAssert) || result.stderr.includes(outputAssert))) {
    return {
      ok: false,
      message: `combined output missing expected text "${outputAssert}"\n--- stdout ---\n${result.stdout}\n--- stderr ---\n${result.stderr}`,
    };
  }
  return { ok: true };
}
