#!/usr/bin/env node
/**
 * Usage:
 *   node verify-docs.mjs                             # entire v4 tree
 *   node verify-docs.mjs path/to/file.mdx ...        # specific files
 *   node verify-docs.mjs src/content/docs/v4-0-0-snapshot/start-here/
 *                                                    # directory walk
 *
 * Phase 0 drivers: cli only. {test:compile} and {test:tutorial} tags
 * parse correctly but report "no driver for kind X" at run time.
 */
import { readdir, stat } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { extractExamples } from './lib/extract.mjs';
import { printReport } from './lib/report.mjs';
import { runCli } from './drivers/cli.mjs';

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

const DRIVERS = {
  cli: runCli,
  // compile: deferred — needs a `wheels check <file>` CLI subcommand. See
  //   Phase 0 completion report for the follow-up.
  // tutorial: lands in Phase 1.
};

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
  console.log(`verify-docs: found ${examples.length} tagged block(s)`);

  const results = await Promise.all(
    examples.map(async (ex) => {
      const driver = DRIVERS[ex.kind];
      if (!driver) {
        return {
          ...ex,
          ok: false,
          message: `no driver for kind "${ex.kind}" (available: ${Object.keys(DRIVERS).join(', ')})`,
        };
      }
      const result = await driver(ex);
      return { ...ex, ...result };
    }),
  );

  const failures = printReport(results);
  process.exit(failures > 0 ? 1 : 0);
}

main().catch((err) => {
  console.error('verify-docs: fatal error');
  console.error(err);
  process.exit(2);
});
