import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
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

test('extractExamples handles indented fences inside Steps', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'extract-indent-'));
  const file = join(dir, 'indented.mdx');
  await writeFile(file,
    '<Steps>\n\n' +
    '1. Do the thing.\n\n' +
    '   ```cfm {test:compile}\n' +
    '   component { function ping() {} }\n' +
    '   ```\n\n' +
    '</Steps>\n',
  );
  try {
    const examples = await extractExamples([file]);
    assert.equal(examples.length, 1);
    assert.equal(examples[0].kind, 'compile');
    // Body must have the indent stripped — not re-prefixed with 3 spaces.
    assert.equal(examples[0].body, 'component { function ping() {} }');
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});

test('extractExamples handles mixed indented and unindented fences in one file', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'extract-mixed-'));
  const file = join(dir, 'mixed.mdx');
  await writeFile(file,
    '```bash {test:cli cmd="wheels --version"}\n' +
    'wheels --version\n' +
    '```\n\n' +
    '<Steps>\n\n' +
    '1. Next:\n\n' +
    '   ```cfm {test:compile}\n' +
    '   x = 1;\n' +
    '   ```\n\n' +
    '</Steps>\n',
  );
  try {
    const examples = await extractExamples([file]);
    assert.equal(examples.length, 2);
    const cli = examples.find((e) => e.kind === 'cli');
    const compile = examples.find((e) => e.kind === 'compile');
    assert.ok(cli);
    assert.ok(compile);
    assert.equal(cli.body, 'wheels --version');
    assert.equal(compile.body, 'x = 1;');
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});

test('extractExamples preserves internal indentation beyond the fence indent', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'extract-internal-'));
  const file = join(dir, 'nested.mdx');
  await writeFile(file,
    '<Steps>\n\n' +
    '1. Code:\n\n' +
    '   ```cfm {test:compile}\n' +
    '   component {\n' +
    '       function inner() {\n' +
    '           return 1;\n' +
    '       }\n' +
    '   }\n' +
    '   ```\n\n' +
    '</Steps>\n',
  );
  try {
    const examples = await extractExamples([file]);
    assert.equal(examples.length, 1);
    // The 3-space fence indent is stripped; the 4-space inner indent is preserved.
    assert.equal(
      examples[0].body,
      'component {\n    function inner() {\n        return 1;\n    }\n}',
    );
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});
