import { readFile, writeFile, mkdir, stat } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { dirname, isAbsolute, normalize, relative, resolve } from 'node:path';
import { spawn } from 'node:child_process';
import { GUIDES_DIR } from './guides.mjs';

const REPO_ROOT = resolve(new URL('../../..', import.meta.url).pathname);

const READ_ROOTS = [
  'vendor/wheels',
  'tools/docs-validation',
  'docs/api',
  '.ai',
  'app',
  'tests',
  'config',
  'CLAUDE.md',
  'web/sites/guides/src/content',
  'web/sites/guides/scripts/verify-docs',
];

const escapeRe = (s) => s.replace(/[.*+?^${}()|[\]\\/]/g, '\\$&');
const GUIDES_PAGE_RE = new RegExp(`^${escapeRe(GUIDES_DIR)}/.+\\.mdx?$`);

const WRITE_GLOBS = [
  /^vendor\/wheels\/public\/docs\/reference\/(controller|model|mapper|migration|migrator|deprecated|tabledefinition)\/[a-z][a-z0-9]*\.txt$/,
  GUIDES_PAGE_RE,
];

const EDIT_GLOBS = [
  /^vendor\/wheels\/.+\.cfc$/,
  GUIDES_PAGE_RE,
];

function withinRoot(absPath) {
  const norm = normalize(absPath);
  const rel = relative(REPO_ROOT, norm);
  if (rel.startsWith('..') || isAbsolute(rel)) return null;
  return rel;
}

function readAllowed(rel) {
  return READ_ROOTS.some((root) => rel === root || rel.startsWith(root + '/'));
}

function writeAllowed(rel) {
  return WRITE_GLOBS.some((re) => re.test(rel));
}

function editAllowed(rel) {
  return EDIT_GLOBS.some((re) => re.test(rel));
}

function resolveRel(path) {
  const abs = isAbsolute(path) ? path : resolve(REPO_ROOT, path);
  const rel = withinRoot(abs);
  if (!rel) throw new Error(`path escapes repo root: ${path}`);
  return { abs, rel };
}

export const TOOLS = [
  {
    name: 'read_file',
    description:
      'Read a whole file from the repo and return its full UTF-8 content (no line ranges, no truncation). ' +
      'Allowed roots: vendor/wheels, tools/docs-validation, docs/api, .ai, app, tests, config, CLAUDE.md, ' +
      'web/sites/guides/src/content, web/sites/guides/scripts/verify-docs. Paths outside these, directories, and missing files return {ok:false, error}. ' +
      'To find one phrase in a large file, run_bash with grep is cheaper.',
    input_schema: {
      type: 'object',
      properties: {
        path: { type: 'string', description: 'Repo-relative, or absolute inside the repo' },
      },
      required: ['path'],
    },
  },
  {
    name: 'write_file',
    description:
      'Create or overwrite a whole file (parent directories are created). Allowed targets: ' +
      'vendor/wheels/public/docs/reference/<scope>/<name>.txt, where <scope> is one of controller, model, mapper, migration, migrator, deprecated, tabledefinition ' +
      `and <name> is the lowercased function name (letters and digits only); and ${GUIDES_DIR}/**/*.md(x). ` +
      'Anything else returns {ok:false, error}. To change part of an existing file, use edit_file.',
    input_schema: {
      type: 'object',
      properties: {
        path: { type: 'string', description: 'Repo-relative target path' },
        content: { type: 'string', description: 'Complete new file content' },
      },
      required: ['path', 'content'],
    },
  },
  {
    name: 'edit_file',
    description:
      'Replace exactly one occurrence of old_string with new_string in an existing file. Allowed targets: vendor/wheels/**/*.cfc ' +
      `and ${GUIDES_DIR}/**/*.md(x). old_string must match verbatim including whitespace and occur exactly once; ` +
      'zero or multiple matches return {ok:false, error} and change nothing. Use it for docblock prose, narrow CFC body fixes, and guide annotation/prose edits.',
    input_schema: {
      type: 'object',
      properties: {
        path: { type: 'string', description: 'Repo-relative path of the file to edit' },
        old_string: { type: 'string', description: 'Exact existing text; include surrounding lines to make it unique' },
        new_string: { type: 'string', description: 'Replacement text' },
      },
      required: ['path', 'old_string', 'new_string'],
    },
  },
  {
    name: 'run_bash',
    description:
      'Run a command with `bash -lc` from the repo root; returns {ok, exit_code, timed_out, stdout, stderr}, each stream capped at 32,000 chars. ' +
      'Use for `wheels cfml "<expr>"` (bare CFML with no Wheels framework loaded, so a syntax check only), `bash tools/test-local.sh <scope>`, ' +
      '`pnpm verify:docs <page>` (from web/sites/guides), `git diff`, and `grep`. The whole process tree is killed at the timeout and ok is false.',
    input_schema: {
      type: 'object',
      properties: {
        command: { type: 'string', description: 'Shell command line' },
        timeout_seconds: { type: 'number', default: 60, description: 'Seconds before the command is killed; clamped to 1–180' },
      },
      required: ['command'],
    },
  },
  {
    name: 'report_outcome',
    description:
      'Terminal action: records the result for the current function or guide page and ends the run. Call exactly once, last. ' +
      'status=done: the reference example (api) or page annotations (guide) are written; status=needs_human: a doc/code conflict or fix remains that you could not apply safely (explain in notes); ' +
      'status=failed: you could not produce a usable result.',
    input_schema: {
      type: 'object',
      properties: {
        status: { enum: ['done', 'needs_human', 'failed'] },
        summary: { type: 'string', description: '1-2 sentence summary of what was done.' },
        files_changed: { type: 'array', items: { type: 'string' }, description: 'Repo-relative paths you wrote or edited' },
        notes: { type: 'string', description: 'Open questions, harness failure tails, or anything a reviewer should check' },
      },
      required: ['status', 'summary'],
    },
  },
];

export function makeExecutor({ outcome, runState }) {
  return async function execute(name, input) {
    if (name === 'read_file') return doRead(input.path);
    if (name === 'write_file') {
      const r = await doWrite(input.path, input.content);
      if (r.ok && runState) {
        runState.filesChanged.add(r.path);
        runState.referencesWritten.add(r.path);
      }
      return r;
    }
    if (name === 'edit_file') {
      const r = await doEdit(input.path, input.old_string, input.new_string);
      if (r.ok && runState) runState.filesChanged.add(r.path);
      return r;
    }
    if (name === 'run_bash') return doBash(input.command, input.timeout_seconds);
    if (name === 'report_outcome') {
      outcome.value = {
        status: input.status,
        summary: input.summary,
        files_changed: input.files_changed ?? [],
        notes: input.notes ?? '',
      };
      return { ok: true, message: 'outcome recorded' };
    }
    return { ok: false, error: `unknown tool: ${name}` };
  };
}

async function doRead(path) {
  try {
    const { abs, rel } = resolveRel(path);
    if (!readAllowed(rel)) return { ok: false, error: `read denied for ${rel}` };
    if (!existsSync(abs)) return { ok: false, error: `not found: ${rel}` };
    const s = await stat(abs);
    if (!s.isFile()) return { ok: false, error: `not a file: ${rel}` };
    const content = await readFile(abs, 'utf8');
    return { ok: true, path: rel, bytes: content.length, content };
  } catch (e) {
    return { ok: false, error: String(e.message ?? e) };
  }
}

async function doWrite(path, content) {
  try {
    const { abs, rel } = resolveRel(path);
    if (!writeAllowed(rel)) return { ok: false, error: `write denied for ${rel} (only reference/<scope>/<name>.txt allowed)` };
    await mkdir(dirname(abs), { recursive: true });
    await writeFile(abs, content, 'utf8');
    return { ok: true, path: rel, bytes: content.length };
  } catch (e) {
    return { ok: false, error: String(e.message ?? e) };
  }
}

async function doEdit(path, oldStr, newStr) {
  try {
    const { abs, rel } = resolveRel(path);
    if (!editAllowed(rel)) return { ok: false, error: `edit denied for ${rel} (only vendor/wheels/**/*.cfc and ${GUIDES_DIR} pages)` };
    if (!existsSync(abs)) return { ok: false, error: `not found: ${rel}` };
    const current = await readFile(abs, 'utf8');
    const occurrences = current.split(oldStr).length - 1;
    if (occurrences === 0) return { ok: false, error: `old_string not found in ${rel}` };
    if (occurrences > 1) return { ok: false, error: `old_string matches ${occurrences} times in ${rel}; provide more context to make it unique` };
    const next = current.replace(oldStr, newStr);
    await writeFile(abs, next, 'utf8');
    return { ok: true, path: rel, bytes_before: current.length, bytes_after: next.length };
  } catch (e) {
    return { ok: false, error: String(e.message ?? e) };
  }
}

function doBash(command, timeoutSeconds = 60) {
  return new Promise((resolveP) => {
    const ms = Math.min(Math.max((timeoutSeconds | 0) || 60, 1), 180) * 1000;
    // detached:true puts the child into its own process group so we can kill
    // the whole tree (bash -> pnpm -> node -> harness -> wheels -> lucli ...)
    // by signalling the negative pid. Without this, SIGKILL on bash leaves
    // descendants orphaned to init and they keep stdio open, so close never
    // fires and the agent loop deadlocks waiting for tool output.
    const child = spawn('bash', ['-lc', command], { cwd: REPO_ROOT, detached: true });
    let stdout = '';
    let stderr = '';
    let killed = false;
    let resolved = false;
    const finish = (result) => {
      if (resolved) return;
      resolved = true;
      clearTimeout(timer);
      clearTimeout(graceTimer);
      resolveP(result);
    };
    const cap = (s) => (s.length > 32_000 ? s.slice(0, 32_000) + `\n[...truncated ${s.length - 32_000} bytes]` : s);
    const killTree = (signal) => {
      try { process.kill(-child.pid, signal); } catch {}
      try { child.kill(signal); } catch {}
    };
    const timer = setTimeout(() => {
      killed = true;
      killTree('SIGKILL');
    }, ms);
    // Backstop: if descendants still hold stdio open after SIGKILL, force-resolve
    // 5s after the timeout fires so the agent loop never hangs forever on a
    // single tool call.
    const graceTimer = setTimeout(() => {
      finish({
        ok: false,
        exit_code: null,
        timed_out: true,
        stdout: cap(stdout),
        stderr: cap(stderr) + '\n[doBash: forced resolve after SIGKILL — descendants still holding stdio]',
      });
    }, ms + 5000);
    child.stdout.on('data', (d) => (stdout += d.toString()));
    child.stderr.on('data', (d) => (stderr += d.toString()));
    child.on('close', (code) => {
      finish({
        ok: !killed,
        exit_code: code,
        timed_out: killed,
        stdout: cap(stdout),
        stderr: cap(stderr),
      });
    });
    child.on('error', (err) => {
      finish({ ok: false, exit_code: null, timed_out: false, stdout: cap(stdout), stderr: cap(stderr) + `\n[spawn error: ${err.message}]` });
    });
  });
}
