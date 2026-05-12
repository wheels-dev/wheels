import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { runCli } from '../drivers/cli.mjs';

const TIMEOUT = 120_000;

test('runCli succeeds for wheels --version', { timeout: TIMEOUT }, async () => {
  const result = await runCli({
    file: 'test:inline',
    line: 1,
    language: 'bash',
    kind: 'cli',
    attrs: { cmd: 'wheels --version' },
    body: '',
  });
  assert.equal(result.ok, true, `cli failed: ${result.message ?? ''}`);
});

test('runCli honors asserts-stdout', { timeout: TIMEOUT }, async () => {
  const result = await runCli({
    file: 'test:inline',
    line: 1,
    language: 'bash',
    kind: 'cli',
    attrs: { cmd: 'wheels --version', 'asserts-stdout': 'Wheels' },
    body: '',
  });
  assert.equal(result.ok, true, `cli failed: ${result.message ?? ''}`);
});

test('runCli fails when asserts-stdout is missing', { timeout: TIMEOUT }, async () => {
  const result = await runCli({
    file: 'test:inline',
    line: 1,
    language: 'bash',
    kind: 'cli',
    attrs: { cmd: 'wheels --version', 'asserts-stdout': 'NotARealString_12345' },
    body: '',
  });
  assert.equal(result.ok, false);
  assert.match(result.message, /missing expected text/);
});

test('runCli reports missing cmd attr', async () => {
  const result = await runCli({
    file: 'test:inline',
    line: 1,
    language: 'bash',
    kind: 'cli',
    attrs: {},
    body: '',
  });
  assert.equal(result.ok, false);
  assert.match(result.message, /missing required attr: cmd/);
});
