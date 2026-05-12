import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { runCompile, detectMode } from '../drivers/compile.mjs';

const TIMEOUT = 60_000;

test('detectMode returns "native" or "fallback"', { timeout: TIMEOUT }, async () => {
  const mode = await detectMode();
  assert.ok(mode === 'native' || mode === 'fallback', `unexpected mode: ${mode}`);
});

test('runCompile passes a valid CFC block', { timeout: TIMEOUT }, async () => {
  const result = await runCompile({
    file: 'test:inline',
    line: 1,
    language: 'cfm',
    kind: 'compile',
    attrs: {},
    body: 'component extends="Model" { function config() { validatesPresenceOf("title"); } }',
  });
  assert.equal(result.ok, true, `compile failed: ${result.message ?? ''}`);
});

test('runCompile fails on syntactically invalid CFML', { timeout: TIMEOUT }, async () => {
  const result = await runCompile({
    file: 'test:inline',
    line: 1,
    language: 'cfm',
    kind: 'compile',
    attrs: {},
    body: 'component { function broken( { }',
  });
  assert.equal(result.ok, false);
});

test('runCompile passes a valid script snippet', { timeout: TIMEOUT }, async () => {
  const result = await runCompile({
    file: 'test:inline',
    line: 1,
    language: 'cfm',
    kind: 'compile',
    attrs: {},
    body: 'x = 1 + 2; writeOutput(x);',
  });
  assert.equal(result.ok, true, `compile failed: ${result.message ?? ''}`);
});
