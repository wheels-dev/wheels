import { spawn } from 'node:child_process';
import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import {
  resetFixture,
  writeFixtureFile,
  appendFixtureFile,
  runInFixture,
  fixturePath,
} from '../lib/tutorial-fixture.mjs';
import { runCli } from './cli.mjs';

async function rewriteLuceePorts(port, shutdownPort) {
  const p = join(fixturePath(), 'lucee.json');
  const raw = await readFile(p, 'utf8');
  const cfg = JSON.parse(raw);
  cfg.port = port;
  cfg.shutdownPort = shutdownPort;
  cfg.openBrowser = false;
  await writeFile(p, JSON.stringify(cfg, null, 2), 'utf8');
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
    // Random free port. Avoids 8080/8081 which are commonly held on
    // developer machines (Docker etc.). Also updates lucee.json so the
    // lucli-driven Tomcat actually binds there.
    const port = 9000 + Math.floor(Math.random() * 500);
    const shutdownPort = port + 1;
    await rewriteLuceePorts(port, shutdownPort);
    const proc = spawn('wheels', ['start'], {
      cwd: fixturePath(),
      stdio: ['ignore', 'pipe', 'pipe'],
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
  const expectedExit = ex.attrs['asserts-exit'] !== undefined ? Number(ex.attrs['asserts-exit']) : 0;
  if (result.code !== expectedExit) {
    return { ok: false, message: `expected exit ${expectedExit}, got ${result.code}\n${result.stderr || result.stdout}` };
  }
  const stdoutAssert = ex.attrs['asserts-stdout'];
  const stderrAssert = ex.attrs['asserts-stderr'];
  const outputAssert = ex.attrs['asserts-output'];
  if (stdoutAssert && !result.stdout.includes(stdoutAssert)) {
    return { ok: false, message: `stdout missing "${stdoutAssert}"\n${result.stdout}` };
  }
  if (stderrAssert && !result.stderr.includes(stderrAssert)) {
    return { ok: false, message: `stderr missing "${stderrAssert}"\n${result.stderr}` };
  }
  if (outputAssert && !(result.stdout.includes(outputAssert) || result.stderr.includes(outputAssert))) {
    return { ok: false, message: `output missing "${outputAssert}"\n${result.stdout}\n${result.stderr}` };
  }
  return { ok: true };
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

export async function runTutorial(example, session) {
  if (example.kind === 'tutorial') return await session.applyTutorialExample(example);
  if (example.kind === 'cli') return await session.applyCliExample(example);
  return { ok: false, message: `tutorial driver received unexpected kind: ${example.kind}` };
}
