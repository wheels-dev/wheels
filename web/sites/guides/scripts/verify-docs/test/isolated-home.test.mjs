import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync, lstatSync, rmSync } from 'node:fs';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createIsolatedHome, enterIsolatedHome, isolatedEnv, sourceHome } from '../lib/isolated-home.mjs';

// verify:docs runs every {test:cli} block with a real `wheels` binary. Against the
// developer's own CLI home those blocks change it: `wheels packages registry refresh`
// deletes <home>/cache/packages, and fixture apps register servers. The harness
// therefore runs the CLI in a throwaway home built from the real one.

function fakeSource() {
  const source = mkdtempSync(join(tmpdir(), 'verify-docs-source-'));
  mkdirSync(join(source, 'modules', 'wheels'), { recursive: true });
  writeFileSync(join(source, 'modules', 'wheels', 'Module.cfc'), 'component {}');
  mkdirSync(join(source, 'express', '7.0.0.1', 'lib', 'ext'), { recursive: true });
  writeFileSync(join(source, 'express', '7.0.0.1', 'lib', 'ext', 'lucee.jar'), 'jar');
  mkdirSync(join(source, 'cache', 'packages'), { recursive: true });
  writeFileSync(join(source, 'cache', 'packages', 'manifest.json'), '{}');
  return source;
}

test('the isolated home is a new directory with a copy of the modules', () => {
  const source = fakeSource();
  const home = createIsolatedHome({ source });
  try {
    assert.notEqual(home, source);
    assert.equal(readFileSync(join(home, 'modules', 'wheels', 'Module.cfc'), 'utf8'), 'component {}');
    // A block that changes modules changes the copy, not the real ones.
    writeFileSync(join(home, 'modules', 'wheels', 'Module.cfc'), 'changed');
    assert.equal(readFileSync(join(source, 'modules', 'wheels', 'Module.cfc'), 'utf8'), 'component {}');
  } finally {
    rmSync(home, { recursive: true, force: true });
    rmSync(source, { recursive: true, force: true });
  }
});

test('the Lucee express runtime is a copy, so writes and downloads stay in the isolated home', () => {
  const source = fakeSource();
  const home = createIsolatedHome({ source });
  try {
    assert.equal(lstatSync(join(home, 'express')).isSymbolicLink(), false);
    assert.equal(readFileSync(join(home, 'express', '7.0.0.1', 'lib', 'ext', 'lucee.jar'), 'utf8'), 'jar');
    // A new runtime download, and a driver staged into an existing runtime, land in the copy only.
    mkdirSync(join(home, 'express', '7.9.9.9'));
    writeFileSync(join(home, 'express', '7.0.0.1', 'lib', 'ext', 'sqlite.jar'), 'driver');
    assert.equal(existsSync(join(source, 'express', '7.9.9.9')), false);
    assert.equal(existsSync(join(source, 'express', '7.0.0.1', 'lib', 'ext', 'sqlite.jar')), false);
  } finally {
    rmSync(home, { recursive: true, force: true });
    rmSync(source, { recursive: true, force: true });
  }
});

test('the real cache is left out', () => {
  const source = fakeSource();
  const home = createIsolatedHome({ source });
  try {
    assert.equal(existsSync(join(home, 'cache')), false);
    rmSync(home, { recursive: true, force: true });
    assert.ok(existsSync(join(source, 'cache', 'packages', 'manifest.json')));
  } finally {
    rmSync(home, { recursive: true, force: true });
    rmSync(source, { recursive: true, force: true });
  }
});

test('the CLI is pointed at the isolated home through LUCLI_JAVA_ARGS and LUCLI_HOME', () => {
  // The Homebrew launcher overwrites LUCLI_HOME, so the JVM property carries the home.
  const env = isolatedEnv('/tmp/iso-home', { LUCLI_JAVA_ARGS: '-Xmx1g', PATH: '/bin' });
  assert.equal(env.LUCLI_HOME, '/tmp/iso-home');
  assert.equal(env.LUCLI_JAVA_ARGS, '-Xmx1g -Dlucli.home=/tmp/iso-home');
  assert.equal(env.PATH, '/bin');
  assert.equal(isolatedEnv('/tmp/iso-home', {}).LUCLI_JAVA_ARGS, '-Dlucli.home=/tmp/iso-home');
});

test('the real home defaults to LUCLI_HOME, then ~/.wheels', () => {
  assert.equal(sourceHome({ LUCLI_HOME: '/x/home' }), '/x/home');
  assert.match(sourceHome({}), /[\\/]\.wheels$/);
});

test('a process that inherits an isolated home keeps it', () => {
  const prev = { ...process.env };
  process.env.WHEELS_VERIFY_DOCS_HOME = '/tmp/parent-home';
  process.env.WHEELS_VERIFY_DOCS_SOURCE_HOME = '/x/source';
  try {
    assert.deepEqual(enterIsolatedHome(), { home: '/tmp/parent-home', source: '/x/source' });
  } finally {
    for (const k of ['WHEELS_VERIFY_DOCS_HOME', 'WHEELS_VERIFY_DOCS_SOURCE_HOME']) {
      if (prev[k] === undefined) delete process.env[k];
      else process.env[k] = prev[k];
    }
  }
});

test('harness test processes run in the isolated home', () => {
  // test:docs-harness preloads test/isolated-home-setup.mjs.
  assert.ok(process.env.WHEELS_VERIFY_DOCS_HOME, 'WHEELS_VERIFY_DOCS_HOME is not set');
  assert.equal(process.env.LUCLI_HOME, process.env.WHEELS_VERIFY_DOCS_HOME);
  assert.match(process.env.LUCLI_JAVA_ARGS, /-Dlucli\.home=/);
});

for (const signal of ['SIGINT', 'SIGTERM']) {
  test(`the isolated home is removed when the run is stopped with ${signal}`, { timeout: 30_000 }, async () => {
    const source = fakeSource();
    const lib = fileURLToPath(new URL('../lib/isolated-home.mjs', import.meta.url));
    const env = { ...process.env, LUCLI_HOME: source };
    delete env.WHEELS_VERIFY_DOCS_HOME;
    delete env.WHEELS_VERIFY_DOCS_SOURCE_HOME;
    const child = spawn(process.execPath, [
      '--input-type=module', '-e',
      `const { enterIsolatedHome } = await import(${JSON.stringify(lib)}); console.log(enterIsolatedHome().home); setInterval(() => {}, 1000);`,
    ], { env, stdio: ['ignore', 'pipe', 'inherit'] });
    try {
      const home = await new Promise((resolve, reject) => {
        child.stdout.once('data', (d) => resolve(String(d).trim()));
        child.once('exit', () => reject(new Error('child exited before reporting its home')));
      });
      assert.ok(existsSync(home), 'the child created its home');
      const exited = new Promise((resolve) => child.once('exit', resolve));
      child.kill(signal);
      await exited;
      assert.equal(existsSync(home), false, `${signal} left ${home} behind`);
    } finally {
      try { child.kill('SIGKILL'); } catch {}
      rmSync(source, { recursive: true, force: true });
    }
  });
}
