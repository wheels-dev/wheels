import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync, lstatSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createIsolatedHome, isolatedEnv, sourceHome } from '../lib/isolated-home.mjs';

// verify:docs runs every {test:cli} block with a real `wheels` binary. Against the
// developer's own CLI home those blocks change it: `wheels packages registry refresh`
// deletes <home>/cache/packages, and fixture apps register servers. The harness
// therefore runs the CLI in a throwaway home built from the real one.

function fakeSource() {
  const source = mkdtempSync(join(tmpdir(), 'verify-docs-source-'));
  mkdirSync(join(source, 'modules', 'wheels'), { recursive: true });
  writeFileSync(join(source, 'modules', 'wheels', 'Module.cfc'), 'component {}');
  mkdirSync(join(source, 'express'));
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

test('the Lucee express runtime is linked, and the real cache is left out', () => {
  const source = fakeSource();
  const home = createIsolatedHome({ source });
  try {
    assert.ok(lstatSync(join(home, 'express')).isSymbolicLink());
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
