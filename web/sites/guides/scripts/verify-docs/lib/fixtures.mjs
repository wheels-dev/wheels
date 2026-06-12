import { mkdtemp, readFile, rm, stat, writeFile } from 'node:fs/promises';
import { createServer } from 'node:net';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { runExec } from './exec.mjs';

function reserveClosedPort() {
  return new Promise((resolve, reject) => {
    const srv = createServer();
    srv.unref();
    srv.on('error', reject);
    srv.listen(0, () => {
      const { port } = srv.address();
      srv.close(() => resolve(port));
    });
  });
}

/**
 * Rewrite a freshly-scaffolded app's pinned ports to OS-assigned ephemeral
 * ports that nothing listens on, and strip any PORT-style keys from .env.
 *
 * Why: `wheels new` pins port 8080 in lucee.json — the same port the repo's
 * own demo app, docker-compose.dev.yml, and plenty of unrelated local
 * services occupy. The CLI's server detection trusts an OPEN pinned port
 * unconditionally, so a stray 8080 listener makes the documented
 * no-running-server refusals (`wheels routes` / `wheels migrate info` /
 * `wheels seed` in migrations/seeding/routing.mdx) attach to a foreign
 * process and go red locally (#3170 review). A closed ephemeral port makes
 * "no server running" deterministic regardless of what else the contributor
 * has listening. (The branch CLI additionally refuses the common-port probe
 * whenever a project pins a port; released CLIs ≤ 4.0.3 still probe
 * 8080/60000/3000/8500 for read-side commands — see VALIDATION.md.)
 */
export async function scrubFixturePorts(appRoot) {
  const cfgPath = join(appRoot, 'lucee.json');
  let raw;
  try {
    raw = await readFile(cfgPath, 'utf8');
  } catch (err) {
    if (err.code === 'ENOENT') {
      throw new Error(`lucee.json not found in fixture at ${cfgPath} — wheels new may have changed its layout`);
    }
    throw err;
  }
  const cfg = JSON.parse(raw);
  cfg.port = await reserveClosedPort();
  cfg.shutdownPort = await reserveClosedPort();
  await writeFile(cfgPath, JSON.stringify(cfg, null, 2), 'utf8');

  // The scaffold's .env carries no PORT today; strip defensively so a
  // future template change can't re-open the same hole via the .env arm
  // of the CLI's port detection.
  const envPath = join(appRoot, '.env');
  let env;
  try {
    env = await readFile(envPath, 'utf8');
  } catch (err) {
    if (err.code === 'ENOENT') return;
    throw err;
  }
  const scrubbed = env
    .split('\n')
    .filter((line) => !/^\s*[A-Za-z0-9_]*PORT\s*=/i.test(line))
    .join('\n');
  if (scrubbed !== env) await writeFile(envPath, scrubbed, 'utf8');
}

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
      await scrubFixturePorts(expected);
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
