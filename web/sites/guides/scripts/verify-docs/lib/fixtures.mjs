import { mkdtemp, rm, stat } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { runExec } from './exec.mjs';

/**
 * Creates a fresh SQLite-backed Wheels app in a tmp directory.
 * Returns the absolute path to the app root.
 *
 * Phase 0: invokes `wheels new <name> --no-open-browser`. SQLite is the
 * default datasource; no other flags required. The app boots to a working
 * state (migrations, controllers, routes) in ~1.5s locally.
 */
export async function createFixture(name = 'fixture') {
  // Retry loop for framework gap #11 — LuCLI parallel-spawn race:
  // When multiple `wheels new` fixtures are created concurrently, LuCLI's
  // `lucee.json` writer occasionally races and fails with:
  //   "Can't cast String [] to a value of type [Struct]"
  // or similar "engine is null" errors from the Lucee script engine init.
  // The error is transient; retry once or twice resolves it. Upstream fix
  // (atomic lucee.json write in LuCLI) is tracked but not shipped.
  const MAX_ATTEMPTS = 4;
  const TRANSIENT_PATTERNS = [
    /Can't cast String \[\] to a value of type \[Struct\]/,
    /because "engine" is null/,
    /ScriptEngine\.put/,
    // When many fixtures spawn concurrently, posix_spawn occasionally
    // returns ENOENT on the wrapper path even though it exists + is
    // executable. Appears to be a Linuxbrew + parallel-JVM contention
    // issue. Transient; retry resolves.
    /^spawn .* ENOENT$/m,
    /spawn \/home\/linuxbrew.*ENOENT/,
  ];
  let lastError;
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    const parent = await mkdtemp(join(tmpdir(), 'wheels-doctest-'));
    const result = await runExec(
      'wheels',
      ['new', name, '--no-open-browser'],
      { cwd: parent },
    );
    const expected = join(parent, name);
    if (result.code === 0) {
      // `wheels new` can exit 0 even when framework lookup fails (it prints
      // an error, cleans up the partial scaffold, and still returns 0). If
      // we don't catch that here, downstream spawns run with cwd=<missing>
      // and Node surfaces misleading "spawn PROGRAM ENOENT" errors that
      // point at the executable instead of the cwd. See #2178.
      try {
        await stat(expected);
      } catch {
        await rm(parent, { recursive: true, force: true });
        throw new Error(
          `wheels new reported success (exit 0) but did not create ${expected}.\n` +
          `Likely cause: the wheels CLI could not locate the framework source. ` +
          `Set WHEELS_FRAMEWORK_PATH to a vendor/wheels/ directory (e.g., the ` +
          `wheels repo checkout) before running the harness.\n` +
          `--- wheels stderr ---\n${result.stderr || ''}\n` +
          `--- wheels stdout ---\n${result.stdout || ''}`,
        );
      }
      return expected;
    }
    await rm(parent, { recursive: true, force: true });
    const combined = `${result.stderr || ''}${result.stdout || ''}`;
    const transient = TRANSIENT_PATTERNS.some((p) => p.test(combined));
    lastError = new Error(
      `wheels new failed (exit ${result.code}, attempt ${attempt}/${MAX_ATTEMPTS}):\n${combined}`,
    );
    if (!transient) break;
    // Back off briefly before retrying (200ms, 400ms).
    await new Promise((r) => setTimeout(r, 200 * attempt));
  }
  throw lastError;
}

/**
 * Removes the fixture's parent tmp dir (which contains the app).
 */
export async function destroyFixture(fixturePath) {
  const parent = join(fixturePath, '..');
  await rm(parent, { recursive: true, force: true });
}
