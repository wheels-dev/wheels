import { readFile, writeFile, mkdir, stat } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { dirname, isAbsolute, normalize, relative, resolve } from 'node:path';
import { spawn } from 'node:child_process';

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
];

const WRITE_GLOBS = [
  /^vendor\/wheels\/public\/docs\/reference\/(controller|model|mapper|migration|migrator|deprecated|tabledefinition)\/[a-z][a-z0-9]+\.txt$/,
];

const EDIT_GLOBS = [/^vendor\/wheels\/.+\.cfc$/];

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
      'Read a file from the repo. Allowed roots: vendor/wheels, tools/docs-validation, docs/api, .ai, app, tests, config, CLAUDE.md.',
    input_schema: {
      type: 'object',
      properties: {
        path: { type: 'string', description: 'Repo-relative or absolute path' },
      },
      required: ['path'],
    },
  },
  {
    name: 'write_file',
    description:
      'Write a file. Allowed only for vendor/wheels/public/docs/reference/<scope>/<name>.txt. Anything else is rejected.',
    input_schema: {
      type: 'object',
      properties: {
        path: { type: 'string' },
        content: { type: 'string' },
      },
      required: ['path', 'content'],
    },
  },
  {
    name: 'edit_file',
    description:
      'Replace exactly one occurrence of old_string with new_string in a vendor/wheels/**/*.cfc file. old_string must be unique and match verbatim including whitespace. Use this to edit docblock prose or, when a behavior bug is unambiguous, function bodies.',
    input_schema: {
      type: 'object',
      properties: {
        path: { type: 'string' },
        old_string: { type: 'string' },
        new_string: { type: 'string' },
      },
      required: ['path', 'old_string', 'new_string'],
    },
  },
  {
    name: 'run_bash',
    description:
      'Run a shell command. Output is captured. Use for `wheels cfml "<expr>"` (compile-validates a CFML snippet), `bash tools/test-local.sh <scope>` (runs tests for a scope), `git diff`, `grep`, etc. Hard timeout: 180s.',
    input_schema: {
      type: 'object',
      properties: {
        command: { type: 'string' },
        timeout_seconds: { type: 'number', default: 60 },
      },
      required: ['command'],
    },
  },
  {
    name: 'report_outcome',
    description:
      'Terminal action. Reports the result for the current function. Call exactly once at the end. status=done means examples written and validated; status=needs_human means a fix is required but the agent cannot apply it safely; status=failed means validation failed.',
    input_schema: {
      type: 'object',
      properties: {
        status: { enum: ['done', 'needs_human', 'failed'] },
        summary: { type: 'string', description: '1-2 sentence summary of what was done.' },
        files_changed: { type: 'array', items: { type: 'string' } },
        notes: { type: 'string' },
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
    if (!editAllowed(rel)) return { ok: false, error: `edit denied for ${rel} (only vendor/wheels/**/*.cfc)` };
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
    const child = spawn('bash', ['-lc', command], { cwd: REPO_ROOT });
    let stdout = '';
    let stderr = '';
    let killed = false;
    const t = setTimeout(() => {
      killed = true;
      child.kill('SIGKILL');
    }, ms);
    child.stdout.on('data', (d) => (stdout += d.toString()));
    child.stderr.on('data', (d) => (stderr += d.toString()));
    child.on('close', (code) => {
      clearTimeout(t);
      const cap = (s) => (s.length > 32_000 ? s.slice(0, 32_000) + `\n[...truncated ${s.length - 32_000} bytes]` : s);
      resolveP({
        ok: !killed,
        exit_code: code,
        timed_out: killed,
        stdout: cap(stdout),
        stderr: cap(stderr),
      });
    });
  });
}
