#!/usr/bin/env node
import { parseArgs } from 'node:util';
import { loadSnapshot, listSections, functionsInSection, findFunction } from './lib/snapshot.mjs';
import { loadState, saveState, setItem, getItem, shouldAttempt, summary } from './lib/state.mjs';

const USAGE = `Usage:
  node orchestrate.mjs --list-sections
  node orchestrate.mjs --section "Model Class" [--list | --dry-run | --force | --limit=N]
  node orchestrate.mjs --function findEach   [--dry-run | --force]
  node orchestrate.mjs --status

Env:
  ANTHROPIC_API_KEY=sk-...        required for live runs (not --dry-run / --list)
  WHEELS_DOCS_MODEL=claude-...    override agent model (default: claude-sonnet-4-6)
  WHEELS_DOCS_MAX_TURNS=N         per-function turn cap (default: 16)
`;

const { values } = parseArgs({
  options: {
    section: { type: 'string' },
    function: { type: 'string' },
    'list-sections': { type: 'boolean' },
    list: { type: 'boolean' },
    status: { type: 'boolean' },
    'dry-run': { type: 'boolean' },
    force: { type: 'boolean' },
    limit: { type: 'string' },
    help: { type: 'boolean', short: 'h' },
  },
});

if (values.help) {
  console.log(USAGE);
  process.exit(0);
}

const snap = await loadSnapshot();
const state = await loadState();

if (values['list-sections']) {
  for (const s of listSections(snap)) {
    const fns = functionsInSection(snap, s);
    console.log(`${s.padEnd(28)} ${String(fns.length).padStart(4)} functions`);
  }
  process.exit(0);
}

if (values.status) {
  const counts = summary(state);
  const total = Object.values(counts).reduce((a, b) => a + b, 0);
  console.log(`State: ${total} items tracked`);
  for (const [k, v] of Object.entries(counts)) console.log(`  ${k.padEnd(12)} ${v}`);
  process.exit(0);
}

let targets = [];
if (values.function) {
  const fn = findFunction(snap, values.function);
  if (!fn) {
    console.error(`function not found in snapshot: ${values.function}`);
    process.exit(1);
  }
  targets = Array.isArray(fn) ? fn : [fn];
} else if (values.section) {
  if (!listSections(snap).includes(values.section)) {
    console.error(`section not found: ${values.section}`);
    console.error(`available: ${listSections(snap).join(', ')}`);
    process.exit(1);
  }
  targets = functionsInSection(snap, values.section);
} else {
  console.error(USAGE);
  process.exit(2);
}

if (values.list) {
  for (const fn of targets) {
    const item = getItem(state, 'function', fn.name);
    const status = item?.status ?? 'pending';
    console.log(`  ${status.padEnd(12)} ${fn.name.padEnd(36)} (${(fn.availableIn ?? []).join(',')})`);
  }
  process.exit(0);
}

const limit = values.limit ? Number(values.limit) : Infinity;
const queue = targets.filter((fn) => values.force || shouldAttempt(state, 'function', fn.name)).slice(0, limit);

console.log(`Processing ${queue.length} function(s) (skipped ${targets.length - queue.length} already-done).`);

if (values['dry-run']) {
  for (const fn of queue) {
    console.log(`  [dry-run] would validate: ${fn.name} (${(fn.availableIn ?? []).join(',')})`);
  }
  process.exit(0);
}

if (!process.env.ANTHROPIC_API_KEY) {
  console.error('ANTHROPIC_API_KEY is not set. Refusing to start agent runs.');
  process.exit(3);
}

const { runAgentForFunction } = await import('./lib/agent.mjs');

let totalUsage = { input_tokens: 0, output_tokens: 0, cache_creation_input_tokens: 0, cache_read_input_tokens: 0 };

for (const fn of queue) {
  console.log(`\n=== ${fn.name} (${fn.tags?.section} / ${fn.tags?.category}) ===`);
  setItem(state, 'function', fn.name, { status: 'in_progress', attempts: (getItem(state, 'function', fn.name)?.attempts ?? 0) + 1 });
  await saveState(state);
  try {
    const { outcome, usage, turns } = await runAgentForFunction(fn);
    for (const k of Object.keys(totalUsage)) totalUsage[k] += usage[k] ?? 0;
    setItem(state, 'function', fn.name, {
      status: outcome.status,
      summary: outcome.summary,
      files_changed: outcome.files_changed,
      notes: outcome.notes,
      turns,
      usage,
    });
    await saveState(state);
    console.log(`  -> ${outcome.status} in ${turns} turn(s): ${outcome.summary}`);
  } catch (err) {
    console.error(`  -> error: ${err.message ?? err}`);
    setItem(state, 'function', fn.name, { status: 'failed', summary: `agent error: ${err.message ?? err}` });
    await saveState(state);
  }
}

console.log('\nUsage totals:');
for (const [k, v] of Object.entries(totalUsage)) console.log(`  ${k.padEnd(32)} ${v}`);
