import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { extractExamples } from '../lib/extract.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const fixture = join(here, 'fixtures/sample.mdx');

test('extractExamples finds tagged blocks and ignores illustrative ones', async () => {
  const examples = await extractExamples([fixture]);
  assert.equal(examples.length, 3);
});

test('extractExamples records source file and line', async () => {
  const examples = await extractExamples([fixture]);
  for (const ex of examples) {
    assert.equal(ex.file, fixture);
    assert.ok(typeof ex.line === 'number' && ex.line > 0);
  }
});

test('extractExamples parses {test:compile}', async () => {
  const examples = await extractExamples([fixture]);
  const compile = examples.find((e) => e.kind === 'compile');
  assert.ok(compile);
  assert.equal(compile.language, 'cfm');
  assert.match(compile.body, /component extends="Model"/);
});

test('extractExamples parses {test:cli} attrs', async () => {
  const examples = await extractExamples([fixture]);
  const cli = examples.find((e) => e.kind === 'cli');
  assert.ok(cli);
  assert.equal(cli.attrs.cmd, 'wheels --version');
  assert.equal(cli.attrs['asserts-stdout'], 'Wheels');
});

test('extractExamples parses {test:tutorial} attrs', async () => {
  const examples = await extractExamples([fixture]);
  const tut = examples.find((e) => e.kind === 'tutorial');
  assert.ok(tut);
  assert.equal(tut.attrs.step, '1');
  assert.equal(tut.attrs.file, 'app/models/Post.cfc');
});
