#!/usr/bin/env node
import { readdir, stat } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { extractExamples } from './lib/extract.mjs';
import { printReport } from './lib/report.mjs';
import { runCli } from './drivers/cli.mjs';
import { TutorialSession } from './drivers/tutorial.mjs';
import { enrichWithSidebarOrder, partitionAndOrder } from './lib/orchestrator.mjs';

const DEFAULT_TARGET = 'src/content/docs/v4-0-0-snapshot';

async function collectMdx(target) {
  const s = await stat(target);
  if (s.isFile()) {
    return target.endsWith('.mdx') || target.endsWith('.md') ? [target] : [];
  }
  if (!s.isDirectory()) return [];
  const out = [];
  for (const entry of await readdir(target, { withFileTypes: true })) {
    const full = join(target, entry.name);
    if (entry.isDirectory()) out.push(...(await collectMdx(full)));
    else if (entry.isFile() && (full.endsWith('.mdx') || full.endsWith('.md'))) {
      out.push(full);
    }
  }
  return out;
}

async function main() {
  const args = process.argv.slice(2);
  const targets = args.length > 0 ? args.map((p) => resolve(p)) : [resolve(DEFAULT_TARGET)];

  const files = [];
  for (const t of targets) files.push(...(await collectMdx(t)));
  if (files.length === 0) {
    console.error('verify-docs: no .mdx/.md files found');
    process.exit(2);
  }

  console.log(`verify-docs: scanning ${files.length} file(s)`);
  const examples = await extractExamples(files);
  await enrichWithSidebarOrder(examples);
  console.log(`verify-docs: found ${examples.length} tagged block(s)`);

  const { perBlock, cumulative } = partitionAndOrder(examples);

  const perBlockResults = await Promise.all(perBlock.map(async (ex) => {
    if (ex.kind === 'cli') return { ...ex, ...(await runCli(ex)) };
    return { ...ex, ok: false, message: `no driver for kind "${ex.kind}"` };
  }));

  const cumulativeResults = [];
  const session = cumulative.length > 0 ? new TutorialSession() : null;
  try {
    for (const ex of cumulative) {
      const result = ex.kind === 'tutorial'
        ? await session.applyTutorialExample(ex)
        : await session.applyCliExample(ex);
      cumulativeResults.push({ ...ex, ...result });
    }
  } finally {
    if (session) await session.stopServer();
  }

  const failures = printReport([...perBlockResults, ...cumulativeResults]);
  process.exit(failures > 0 ? 1 : 0);
}

main().catch((err) => {
  console.error('verify-docs: fatal error');
  console.error(err);
  process.exit(2);
});
