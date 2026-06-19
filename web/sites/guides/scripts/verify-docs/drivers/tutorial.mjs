import { spawn } from 'node:child_process';
import { createServer } from 'node:net';
import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import {
  resetFixture,
  writeFixtureFile,
  appendFixtureFile,
  runInFixture,
  fixturePath,
} from '../lib/tutorial-fixture.mjs';
import { assertCliResult } from '../lib/cli-assert.mjs';
import { RESOLVED_WHEELS } from '../lib/exec.mjs';

function findFreePort() {
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

async function rewriteLuceePorts(port, shutdownPort) {
  const cfgPath = join(fixturePath(), 'lucee.json');
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
  cfg.port = port;
  cfg.shutdownPort = shutdownPort;
  cfg.openBrowser = false;
  await writeFile(cfgPath, JSON.stringify(cfg, null, 2), 'utf8');
}

const HTTP_ASSERT_RE = /^(GET|POST|PUT|PATCH|DELETE)\s+(\S+)\s*(?:→|->)\s*(\d+)(?:\s+"([^"]+)")?\s*$/;

export function parseHttpAssert(spec) {
  const m = spec.match(HTTP_ASSERT_RE);
  if (!m) {
    if (!/→|->/.test(spec)) {
      throw new Error(`malformed assertion (missing arrow): ${spec}`);
    }
    throw new Error(`malformed assertion: ${spec}`);
  }
  return {
    method: m[1],
    path: m[2],
    status: Number(m[3]),
    bodyIncludes: m[4] ?? null,
  };
}

async function fetchFromFixture(server, { method, path }) {
  const url = `http://127.0.0.1:${server.port}${path}`;
  const res = await fetch(url, { method, redirect: 'manual' });
  const text = await res.text();
  return { status: res.status, body: text };
}

export class TutorialSession {
  constructor() {
    this.server = null;
    this.initialised = false;
  }

  async ensureInitialised() {
    if (this.initialised) return;
    await resetFixture();
    this.initialised = true;
  }

  async ensureServer() {
    if (this.server) return this.server;
    // Ask the OS for a free port so we don't collide with random services.
    // Tiny TOCTOU window between close+bind is acceptable in practice; if CI
    // ever sees flakes, wrap this in a bounded retry loop.
    const port = await findFreePort();
    const shutdownPort = await findFreePort();
    await rewriteLuceePorts(port, shutdownPort);
    // stdio is fully ignored: nothing here consumes the pipes, and leaving
    // them as 'pipe' risks Lucee's boot logs filling the ~64KB pipe buffer
    // and deadlocking the child (which would surface as a spurious
    // waitForListening timeout). The timeout error message alone is
    // diagnostic enough; add an env-gated log capture later if needed.
    //
    // Spawn RESOLVED_WHEELS, not bare 'wheels': this is the only spawn
    // site that can't go through runExec() (we need the long-running
    // child handle), and a bare PATH lookup here would let the tutorial
    // dev server run a different binary than the one the attestation
    // line names (and would ignore WHEELS_BIN). See #3042.
    const proc = spawn(RESOLVED_WHEELS, ['start'], {
      cwd: fixturePath(),
      stdio: ['ignore', 'ignore', 'ignore'],
      shell: false,
    });
    try {
      await waitForListening(port, 60_000);
    } catch (err) {
      try { proc.kill('SIGTERM'); } catch {}
      throw err;
    }
    this.server = { proc, port };
    return this.server;
  }

  async stopServer() {
    if (!this.server) return;
    await runInFixture(['stop']);
    try { this.server.proc.kill('SIGTERM'); } catch {}
    this.server = null;
  }

  async applyTutorialExample(ex) {
    await this.ensureInitialised();
    const mode = ex.attrs.mode ?? 'write';
    const target = ex.attrs.file;
    if (!target) return { ok: false, message: 'missing required attr: file' };

    if (mode === 'append') {
      await appendFixtureFile(target, ex.body + '\n');
    } else {
      await writeFixtureFile(target, ex.body + '\n');
    }

    if (ex.attrs['asserts-http']) {
      const assertion = parseHttpAssert(ex.attrs['asserts-http']);
      const server = await this.ensureServer();
      const { status, body } = await fetchFromFixture(server, assertion);
      if (status !== assertion.status) {
        return { ok: false, message: `expected HTTP ${assertion.status}, got ${status}\nbody: ${body.slice(0, 500)}` };
      }
      if (assertion.bodyIncludes && !body.includes(assertion.bodyIncludes)) {
        return { ok: false, message: `response missing "${assertion.bodyIncludes}"\nbody: ${body.slice(0, 500)}` };
      }
    }

    if (ex.attrs['asserts-db-rows']) {
      const pairs = ex.attrs['asserts-db-rows'].split(',').map((p) => p.trim());
      for (const pair of pairs) {
        const [table, expected] = pair.split('=').map((p) => p.trim());
        const actual = await countRows(table);
        if (String(actual) !== expected) {
          return { ok: false, message: `expected ${table}=${expected} rows, got ${actual}` };
        }
      }
    }

    return { ok: true };
  }

  async applyCliExample(ex) {
    await this.ensureInitialised();
    return await runCliInFixture(ex);
  }
}

async function runCliInFixture(ex) {
  const cmd = ex.attrs.cmd;
  if (!cmd) return { ok: false, message: 'missing required attr: cmd' };
  const [program, ...args] = cmd.trim().split(/\s+/);
  if (program !== 'wheels') {
    return { ok: false, message: `cumulative cli examples must use 'wheels', got '${program}'` };
  }
  const result = await runInFixture(args);
  return assertCliResult(result, ex.attrs);
}

async function countRows(table) {
  const result = await runInFixture([
    'cfml',
    `q = queryExecute("SELECT COUNT(*) AS c FROM ${table}", [], {datasource: "wheelstestdb"}); writeOutput(q.c[1]);`,
  ]);
  if (result.code !== 0) throw new Error(`db count failed: ${result.stderr}`);
  return Number(result.stdout.trim());
}

async function waitForListening(port, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    try {
      const res = await fetch(`http://127.0.0.1:${port}/`, { redirect: 'manual' });
      if (res.status > 0) return;
    } catch {}
    await new Promise((r) => setTimeout(r, 500));
  }
  throw new Error(`wheels server did not listen on port ${port} within ${timeoutMs}ms`);
}
