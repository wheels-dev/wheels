import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { wheelsBinaryAttestation } from '../lib/exec.mjs';

const TIMEOUT = 120_000;

// The attestation line must state which MODE the run exercised (#3042):
// CI sets WHEELS_ATTEST_MODE when it overlays the checkout's cli/lucli
// module onto the installed CLI; without it the line must say the binary
// ran as-installed so a green run is never mistaken for branch coverage.

test('attestation includes mode from WHEELS_ATTEST_MODE', { timeout: TIMEOUT }, async () => {
  const prev = process.env.WHEELS_ATTEST_MODE;
  process.env.WHEELS_ATTEST_MODE = 'checkout cli/lucli module overlay @ deadbeef';
  try {
    const line = await wheelsBinaryAttestation();
    assert.match(line, /mode: checkout cli\/lucli module overlay @ deadbeef/);
  } finally {
    if (prev === undefined) delete process.env.WHEELS_ATTEST_MODE;
    else process.env.WHEELS_ATTEST_MODE = prev;
  }
});

test('attestation defaults to as-installed mode when WHEELS_ATTEST_MODE is unset', { timeout: TIMEOUT }, async () => {
  const prev = process.env.WHEELS_ATTEST_MODE;
  delete process.env.WHEELS_ATTEST_MODE;
  try {
    const line = await wheelsBinaryAttestation();
    assert.match(line, /mode: as-installed/);
    // Still carries the original path + resolution + version segments.
    assert.match(line, /wheels binary: /);
    assert.match(line, /\(via (WHEELS_BIN|PATH discovery)\)/);
  } finally {
    if (prev !== undefined) process.env.WHEELS_ATTEST_MODE = prev;
  }
});
