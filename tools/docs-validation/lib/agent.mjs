import Anthropic from '@anthropic-ai/sdk';
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { TOOLS, makeExecutor } from './tools.mjs';
import { locateFunction } from './source-map.mjs';
import { readReferenceAnyScope } from './reference-store.mjs';

const PROMPT_PATH = resolve(new URL('../agent/prompt.md', import.meta.url).pathname);

const DEFAULT_MODEL = process.env.WHEELS_DOCS_MODEL ?? 'claude-sonnet-4-6';
const MAX_TURNS = Number(process.env.WHEELS_DOCS_MAX_TURNS ?? 16);
const MAX_TOKENS = Number(process.env.WHEELS_DOCS_MAX_TOKENS ?? 8192);

let SYSTEM_PROMPT;
async function getSystemPrompt() {
  SYSTEM_PROMPT ??= await readFile(PROMPT_PATH, 'utf8');
  return SYSTEM_PROMPT;
}

async function userPayload(fn) {
  const candidates = await locateFunction(fn.name);
  const existingRef = await readReferenceAnyScope(fn.name, fn.availableIn ?? []);
  const lines = [
    `# Function: ${fn.name}`,
    '',
    `**Signature:** \`${fn.name}()\` returns \`${fn.returntype || 'void'}\``,
    `**Available in:** ${(fn.availableIn ?? []).join(', ')}`,
    `**Section / Category:** ${fn.tags?.section || '?'} / ${fn.tags?.category || '?'}`,
    `**Slug:** ${fn.slug}`,
    '',
    '## Source candidates (from index scan)',
    '',
  ];
  if (candidates.length === 0) {
    lines.push('_(no candidates found — fall back to grep)_');
  } else {
    for (const c of candidates) lines.push(`- ${c.file}:${c.line} (${c.access})`);
  }
  lines.push('');
  lines.push('## Existing reference example');
  lines.push('');
  if (existingRef) {
    lines.push(`Path: \`vendor/wheels/public/docs/reference/${existingRef.scope.toLowerCase()}/${fn.name.toLowerCase()}.txt\``);
    lines.push('');
    lines.push('```cfm');
    lines.push(existingRef.body);
    lines.push('```');
  } else {
    lines.push('_(none — author one for the most specific scope in availableIn)_');
  }
  lines.push('');
  lines.push('## Documented hint');
  lines.push('');
  lines.push(fn.hint || '_(none)_');
  lines.push('');
  lines.push('## Documented parameters');
  lines.push('');
  if (!fn.parameters?.length) {
    lines.push('_(none)_');
  } else {
    lines.push('| Name | Type | Required | Default | Hint |');
    lines.push('| --- | --- | --- | --- | --- |');
    for (const p of fn.parameters) {
      const def = p.default === undefined ? '' : p.default === '' ? '(empty)' : String(p.default);
      lines.push(
        `| ${p.name} | ${p.type ?? ''} | ${p.required ? 'yes' : 'no'} | ${def} | ${(p.hint ?? '').replace(/\|/g, '\\|')} |`,
      );
    }
  }
  lines.push('');
  lines.push('## Your task');
  lines.push('');
  lines.push(
    'Follow the workflow in the system prompt for THIS function only. Use `read_file` to inspect the CFC source. Validate any examples you generate. End by calling `report_outcome` exactly once.',
  );
  return lines.join('\n');
}

export async function runAgentForFunction(fn, { logger = console.log } = {}) {
  const client = new Anthropic();
  const system = await getSystemPrompt();
  const outcome = { value: null };
  const runState = { filesChanged: new Set(), referencesWritten: new Set() };
  const exec = makeExecutor({ outcome, runState });

  const messages = [{ role: 'user', content: await userPayload(fn) }];
  let turn = 0;
  let usage = { input_tokens: 0, output_tokens: 0, cache_creation_input_tokens: 0, cache_read_input_tokens: 0 };

  while (turn < MAX_TURNS) {
    turn++;
    const resp = await client.messages.create({
      model: DEFAULT_MODEL,
      max_tokens: MAX_TOKENS,
      system: [
        { type: 'text', text: system, cache_control: { type: 'ephemeral' } },
      ],
      tools: TOOLS.map((t, i) =>
        i === TOOLS.length - 1 ? { ...t, cache_control: { type: 'ephemeral' } } : t,
      ),
      messages,
    });

    for (const k of Object.keys(usage)) usage[k] += resp.usage?.[k] ?? 0;

    messages.push({ role: 'assistant', content: resp.content });

    const toolUses = resp.content.filter((b) => b.type === 'tool_use');
    if (toolUses.length === 0) {
      logger(`[turn ${turn}] no tool use; stop_reason=${resp.stop_reason}`);
      break;
    }

    const toolResults = [];
    for (const use of toolUses) {
      logger(`[turn ${turn}] -> ${use.name}(${truncate(JSON.stringify(use.input), 200)})`);
      const result = await exec(use.name, use.input);
      logger(`[turn ${turn}] <- ${truncate(JSON.stringify(result), 200)}`);
      toolResults.push({
        type: 'tool_result',
        tool_use_id: use.id,
        content: typeof result === 'string' ? result : JSON.stringify(result),
        is_error: result?.ok === false,
      });
    }
    messages.push({ role: 'user', content: toolResults });

    if (outcome.value) {
      logger(`[turn ${turn}] outcome reported: ${outcome.value.status}`);
      break;
    }
  }

  if (!outcome.value) {
    const filesChanged = [...runState.filesChanged];
    const refsWritten = [...runState.referencesWritten];
    const exhausted = turn >= MAX_TURNS;
    const cause = exhausted
      ? `exhausted turn budget (${MAX_TURNS})`
      : `stopped at turn ${turn}/${MAX_TURNS} (model returned no tool_use)`;

    if (refsWritten.length > 0) {
      outcome.value = {
        status: 'done',
        summary: `Auto-finalized: agent wrote ${refsWritten.length} reference file(s) but ${cause} before calling report_outcome.`,
        files_changed: filesChanged,
        notes: `auto_finalized=true; review the diff carefully — agent did not self-validate before stopping. references=${refsWritten.join(',')}`,
      };
    } else if (filesChanged.length > 0) {
      outcome.value = {
        status: 'needs_human',
        summary: `Edits made to ${filesChanged.length} file(s) but no reference example was written; ${cause} before report_outcome.`,
        files_changed: filesChanged,
        notes: `auto_finalized=true; CFC-only edits without a reference write. Possible causes: edit→revert flow, partial work, or agent stopped early. Review and decide.`,
      };
    } else {
      outcome.value = {
        status: 'failed',
        summary: `Agent did not call report_outcome and produced no file edits; ${cause}.`,
        files_changed: [],
        notes: '',
      };
    }
  }

  return { outcome: outcome.value, usage, turns: turn };
}

function truncate(s, n) {
  return s.length > n ? s.slice(0, n) + '…' : s;
}
