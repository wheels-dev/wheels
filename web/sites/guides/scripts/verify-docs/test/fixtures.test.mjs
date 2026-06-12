import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { connect } from 'node:net';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { scrubFixturePorts } from '../lib/fixtures.mjs';

// #3170 review: `wheels new` pins port 8080 in lucee.json, and the CLI's
// server detection trusts an OPEN pinned port unconditionally — so any
// stray local 8080 listener (the repo's own demo app among them) made the
// documented no-running-server refusal blocks attach to a foreign process
// and go red. scrubFixturePorts rewrites every fixture to closed ephemeral
// ports so "no server running" is deterministic on contributor machines.

function isPortClosed(port) {
  return new Promise((resolve) => {
    const sock = connect({ port, host: '127.0.0.1', timeout: 1000 });
    sock.on('connect', () => { sock.destroy(); resolve(false); });
    sock.on('timeout', () => { sock.destroy(); resolve(true); });
    sock.on('error', () => resolve(true));
  });
}

async function makeScaffold({ env } = {}) {
  const dir = await mkdtemp(join(tmpdir(), 'wheels-scrub-test-'));
  await writeFile(
    join(dir, 'lucee.json'),
    JSON.stringify({ name: 'fixture', port: 8080, shutdownPort: 8081, openBrowser: false }, null, 2),
    'utf8',
  );
  if (env !== undefined) await writeFile(join(dir, '.env'), env, 'utf8');
  return dir;
}

test('scrubFixturePorts moves lucee.json off the scaffold ports onto closed ones', async () => {
  const dir = await makeScaffold();
  try {
    await scrubFixturePorts(dir);
    const cfg = JSON.parse(await readFile(join(dir, 'lucee.json'), 'utf8'));
    assert.notEqual(cfg.port, 8080, 'port must be moved off the scaffold default');
    assert.notEqual(cfg.shutdownPort, 8081, 'shutdownPort must be moved off the scaffold default');
    assert.equal(cfg.name, 'fixture', 'other lucee.json keys must survive');
    assert.equal(await isPortClosed(cfg.port), true, `rewritten port ${cfg.port} must not be listening`);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});

test('scrubFixturePorts strips PORT-style keys from .env and keeps the rest', async () => {
  const dir = await makeScaffold({
    env: 'WHEELS_ENV=development\nPORT=8080\nSHUTDOWNPORT = 8081\nWHEELS_DATASOURCE=fixture\n',
  });
  try {
    await scrubFixturePorts(dir);
    const env = await readFile(join(dir, '.env'), 'utf8');
    assert.doesNotMatch(env, /PORT\s*=/i, '.env must not retain any PORT-style assignment');
    assert.match(env, /WHEELS_ENV=development/);
    assert.match(env, /WHEELS_DATASOURCE=fixture/);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});

test('scrubFixturePorts tolerates a fixture without .env', async () => {
  const dir = await makeScaffold();
  try {
    await scrubFixturePorts(dir); // must not throw
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});

test('scrubFixturePorts fails loudly when lucee.json is missing', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'wheels-scrub-test-'));
  try {
    await assert.rejects(
      () => scrubFixturePorts(dir),
      /lucee\.json not found in fixture/,
    );
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});
