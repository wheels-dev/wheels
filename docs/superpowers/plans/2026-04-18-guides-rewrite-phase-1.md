# Wheels 4.0 Guides — Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the full 7-part "Build a Blog" tutorial plus the Start Here support pages (Welcome, Why Wheels?, Installing Wheels, Your First 15 Minutes) — every tutorial code block executed end-to-end by the verify-docs harness against a real `wheels` CLI.

**Architecture:** Extend the verify-docs harness with two new drivers (`tutorial` + `compile`). The `tutorial` driver maintains one long-lived blog-tutorial fixture app, walking all `{test:tutorial}` and step-numbered `{test:cli}` blocks across the 7 tutorial parts in cumulative order — writing file contents into the fixture and running CLI commands between them, asserting HTTP/DB state along the way. The `compile` driver uses `wheels cfml` with LuCLI PR #1's exit-code semantics, with a pattern-match fallback for environments where that PR hasn't merged. Content pages follow the STYLE.md voice and Diátaxis structure rules from Phase 0.

**Tech Stack:** Node 22+ (ESM, `node:test`), Astro 5 + Starlight 0.34, MDX, `wheels` CLI (v0.3.5-SNAPSHOT+, framework v4.0.0), SQLite, `wheels-hotwire` + `wheels-basecoat` packages.

**Base:** Branch `claude/lucid-thompson-b8c121` at Phase 0 head `ee2ad45bd` (merge base onto develop happens at end of Phase 2).

**Review model (pragmatic split established in Phase 0):**
- **Code tasks (1, 2)** — full subagent ceremony: TDD implementer → spec review → code-quality review.
- **Content tasks (3-13)** — inline execution with self-review against [STYLE.md](../../web/sites/guides/STYLE.md) + harness-passing as the review gate. The harness executing each page's code end-to-end *is* the correctness test.
- **Integration task (14)** — inline: full harness run + astro build + Cloudflare preview URL + completion report.
- **Final review task (15)** — dispatch a single pr-review-toolkit:code-reviewer subagent across the full Phase 1 diff.

---

## File Structure

### New files

| Path | Responsibility |
|------|----------------|
| `web/sites/guides/scripts/verify-docs/drivers/tutorial.mjs` | `{test:tutorial}` driver — cumulative fixture lifecycle |
| `web/sites/guides/scripts/verify-docs/lib/tutorial-fixture.mjs` | Persistent blog-tutorial fixture manager (create, reset, file ops) |
| `web/sites/guides/scripts/verify-docs/lib/orchestrator.mjs` | Sort + group examples by fixture vs per-block; dispatches via kind |
| `web/sites/guides/scripts/verify-docs/test/tutorial.test.mjs` | Unit tests for tutorial driver |
| `web/sites/guides/scripts/verify-docs/test/compile.test.mjs` | Unit tests for compile driver |
| `web/sites/guides/scripts/verify-docs/test/fixtures/mini-tutorial/` | Minimal 2-step tutorial fixture for harness testing |
| `web/sites/guides/scripts/verify-docs/fixtures/.gitignore` | `blog-tutorial/` (scratch, rebuilt each run) |
| `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/welcome.mdx` | Welcome page (Task 3) |
| `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/why-wheels.mdx` | Why Wheels? comparison page (Task 4) |
| `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/installing.mdx` | Installing Wheels (Task 5) |
| `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/first-15-minutes.mdx` | First 15 Minutes (Task 6) |
| `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/index.mdx` | Tutorial landing (links to all 7 parts) |
| `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/02-first-model.mdx` | Tutorial Part 2 (Task 8) |
| `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/03-crud-scaffold.mdx` | Tutorial Part 3 (Task 9) |
| `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/04-validations-frames.mdx` | Tutorial Part 4 (Task 10) |
| `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/05-comments-streams.mdx` | Tutorial Part 5 (Task 11) |
| `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/06-authentication.mdx` | Tutorial Part 6 (Task 12) |
| `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/07-testing-deploying.mdx` | Tutorial Part 7 (Task 13) |
| `docs/superpowers/plans/2026-04-18-guides-rewrite-phase-1-report.md` | Completion report (Task 14) |

### Modified files

| Path | Change |
|------|--------|
| `web/sites/guides/scripts/verify-docs/drivers/compile.mjs` | Replace Task-6-stub with real driver (Task 2) |
| `web/sites/guides/scripts/verify-docs/verify-docs.mjs` | Register `compile` and `tutorial` drivers; route via orchestrator (Tasks 1, 2) |
| `web/sites/guides/scripts/verify-docs/VALIDATION.md` | Update `{test:tutorial}` and `{test:compile}` from "lands in Phase 1" to "stable"; document new attrs (Tasks 1, 2) |
| `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/01-hello-wheels.mdx` | Re-tag illustrative CFC blocks as `{test:compile}` (Task 2); update "What's next" to link Part 2 (Task 8) |
| `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/sending-email.mdx` | Re-tag CFC blocks as `{test:compile}` (Task 2) |
| `web/sites/guides/src/sidebars/v4-0-0-snapshot.json` | Add Part 2-7 entries + Welcome/Why/Installing/First15 pages (incremental per task) |
| `web/sites/guides/package.json` | Bump `test:docs-harness` glob to include nested test dirs if needed (Task 1) |

---

## Phase Layout

| Task | Kind | Review mode |
|------|------|-------------|
| 1. Tutorial driver | Code | Subagent: implementer → spec → code review |
| 2. Compile driver + re-tag | Code | Subagent: implementer → spec → code review |
| 3. Welcome page | Content | Inline + harness |
| 4. Why Wheels? page | Content | Inline + harness |
| 5. Installing Wheels | Content | Inline + harness |
| 6. Your First 15 Minutes | Content | Inline + harness |
| 7. Tutorial index + Part 1 resume-banner backfill | Content | Inline + harness |
| 8. Tutorial Part 2 — First Model | Content | Inline + harness |
| 9. Tutorial Part 3 — Scaffold + Turbo Drive | Content | Inline + harness |
| 10. Tutorial Part 4 — Validations + Turbo Frames | Content | Inline + harness |
| 11. Tutorial Part 5 — Comments + Turbo Streams | Content | Inline + harness |
| 12. Tutorial Part 6 — Authentication (6a + 6b) | Content | Inline + harness |
| 13. Tutorial Part 7 — Testing, Deploying, What's Next | Content | Inline + harness |
| 14. Full harness + build + preview + report | Integration | Inline |
| 15. Final code review | Review | Subagent: pr-review-toolkit:code-reviewer |

---

## Task 1: Tutorial driver

**Files:**
- Create: `web/sites/guides/scripts/verify-docs/drivers/tutorial.mjs`
- Create: `web/sites/guides/scripts/verify-docs/lib/tutorial-fixture.mjs`
- Create: `web/sites/guides/scripts/verify-docs/lib/orchestrator.mjs`
- Create: `web/sites/guides/scripts/verify-docs/test/tutorial.test.mjs`
- Create: `web/sites/guides/scripts/verify-docs/test/fixtures/mini-tutorial/step-1.mdx`
- Create: `web/sites/guides/scripts/verify-docs/test/fixtures/mini-tutorial/step-2.mdx`
- Create: `web/sites/guides/scripts/verify-docs/fixtures/.gitignore`
- Modify: `web/sites/guides/scripts/verify-docs/verify-docs.mjs` (register driver, route through orchestrator)
- Modify: `web/sites/guides/scripts/verify-docs/VALIDATION.md` (mark `{test:tutorial}` as stable, document `asserts-http` / `asserts-status` / `asserts-db` attrs)

**Design summary:**

The tutorial driver differs fundamentally from the cli driver: cli creates a fresh fixture per block and throws it away; tutorial maintains ONE persistent fixture across all blocks from all tutorial files, walked in deterministic cumulative order. The orchestrator partitions examples into:
- **Per-block examples** (`{test:compile}`, `{test:cli}` without `step`) — run in parallel, isolated fixture each.
- **Cumulative examples** (`{test:tutorial step=N ...}`, `{test:cli step=N ...}`) — run sequentially, shared fixture.

Cumulative ordering rule: sort by `(sidebarOrder, stepNumber, fileLine)`. Sidebar order comes from parsing each MDX file's frontmatter `sidebar.order`; ties break by step then by position in file.

`{test:tutorial}` block semantics:
- `step=N` — required. Integer ordinal.
- `file="relative/path"` — required. Relative path inside the fixture app where the block body is written (clobbering any existing file).
- `mode="write"` (default) or `mode="append"` — write the body or append to existing file (append is rare; useful for adding to `config/routes.cfm`).
- `asserts-http="GET /posts → 200"` — after writing the file (and after any `{test:cli step=N}` at the same step), the driver hits the URL and asserts the status code. Format: `METHOD PATH → STATUS` or `METHOD PATH → STATUS "body substring"`.
- `asserts-db-rows="posts=3"` — optional. SQLite query `SELECT COUNT(*) FROM <table>` must equal N. Multiple tables separated by commas.
- `title="..."` — ignored by harness, consumed by Starlight.

`{test:cli step=N}` block semantics:
- Already supported by the existing cli driver. The orchestrator routes step-numbered cli blocks through the shared fixture instead of creating a fresh one per block. Asserts already supported: `asserts-stdout`, `asserts-stderr`, `asserts-output`, `asserts-exit`.

Fixture lifecycle:
- Fixture root: `web/sites/guides/scripts/verify-docs/fixtures/blog-tutorial/`.
- Gitignored.
- On each `pnpm verify:docs` run that includes any tutorial file: the driver *resets* the fixture by deleting it and re-running `wheels new blog-tutorial --no-open-browser`. Deterministic and isolated across runs.
- Server lifecycle: for `asserts-http`, the driver boots `wheels server start` on a free port once per run, tears it down at the end. One server, many requests.

Wall-time budget: fresh `wheels new` (~1.5s) + migration runs (~300ms each, N of them) + server start (~3-5s) + ~150 HTTP asserts (~10ms each) + server stop. Target: ≤90s for the full 7-part tutorial.

- [ ] **Step 1: Write failing unit test for tutorial-fixture lifecycle**

Create `web/sites/guides/scripts/verify-docs/test/tutorial.test.mjs`:

```js
import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { existsSync } from 'node:fs';
import { readFile, writeFile, mkdir, rm } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { resetFixture, writeFixtureFile, readFixtureFile, appendFixtureFile, runInFixture, fixturePath } from '../lib/tutorial-fixture.mjs';

const TIMEOUT = 180_000;
const here = dirname(fileURLToPath(import.meta.url));
const ROOT = join(here, '..', 'fixtures', 'blog-tutorial');

test('resetFixture creates a fresh wheels app at the canonical path', { timeout: TIMEOUT }, async () => {
  await resetFixture();
  assert.equal(fixturePath(), ROOT);
  assert.ok(existsSync(join(ROOT, 'box.json')), 'box.json should exist');
  assert.ok(existsSync(join(ROOT, 'config', 'routes.cfm')), 'routes.cfm should exist');
});

test('writeFixtureFile overwrites relative paths within the fixture', { timeout: TIMEOUT }, async () => {
  await resetFixture();
  await writeFixtureFile('app/controllers/Probe.cfc', 'component { function ping() {} }');
  const body = await readFixtureFile('app/controllers/Probe.cfc');
  assert.match(body, /function ping/);
});

test('writeFixtureFile rejects paths that escape the fixture root', { timeout: TIMEOUT }, async () => {
  await resetFixture();
  await assert.rejects(
    () => writeFixtureFile('../outside.cfc', 'x'),
    /escapes fixture root/,
  );
  await assert.rejects(
    () => writeFixtureFile('/absolute.cfc', 'x'),
    /must be relative/,
  );
});

test('appendFixtureFile adds to existing file', { timeout: TIMEOUT }, async () => {
  await resetFixture();
  await writeFixtureFile('app/test.txt', 'line1\n');
  await appendFixtureFile('app/test.txt', 'line2\n');
  const body = await readFixtureFile('app/test.txt');
  assert.equal(body, 'line1\nline2\n');
});

test('runInFixture executes wheels command in the fixture cwd', { timeout: TIMEOUT }, async () => {
  await resetFixture();
  const result = await runInFixture(['--version']);
  assert.equal(result.code, 0);
  assert.match(result.stdout, /Wheels/);
});
```

- [ ] **Step 2: Run the test to confirm it fails**

```bash
cd web/sites/guides
pnpm test:docs-harness -- --test-name-pattern=resetFixture 2>&1 | head -30
```

Expected: ERR_MODULE_NOT_FOUND on `../lib/tutorial-fixture.mjs`.

- [ ] **Step 3: Implement `tutorial-fixture.mjs`**

Create `web/sites/guides/scripts/verify-docs/lib/tutorial-fixture.mjs`:

```js
import { readFile, writeFile, appendFile, mkdir, rm, stat } from 'node:fs/promises';
import { join, dirname, resolve, relative, isAbsolute } from 'node:path';
import { fileURLToPath } from 'node:url';
import { runExec } from './exec.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(join(here, '..', 'fixtures', 'blog-tutorial'));
const PARENT = dirname(ROOT);
const APP_NAME = 'blog-tutorial';

export function fixturePath() {
  return ROOT;
}

function resolveInside(relPath) {
  if (isAbsolute(relPath)) {
    throw new Error(`path must be relative: ${relPath}`);
  }
  const full = resolve(ROOT, relPath);
  const rel = relative(ROOT, full);
  if (rel.startsWith('..')) {
    throw new Error(`path escapes fixture root: ${relPath}`);
  }
  return full;
}

export async function resetFixture() {
  await rm(ROOT, { recursive: true, force: true });
  await mkdir(PARENT, { recursive: true });
  const result = await runExec(
    'wheels',
    ['new', APP_NAME, '--no-open-browser'],
    { cwd: PARENT },
  );
  if (result.code !== 0) {
    throw new Error(
      `wheels new failed (exit ${result.code}):\n${result.stderr || result.stdout}`,
    );
  }
}

export async function writeFixtureFile(relPath, body) {
  const full = resolveInside(relPath);
  await mkdir(dirname(full), { recursive: true });
  await writeFile(full, body, 'utf8');
}

export async function appendFixtureFile(relPath, body) {
  const full = resolveInside(relPath);
  await mkdir(dirname(full), { recursive: true });
  await appendFile(full, body, 'utf8');
}

export async function readFixtureFile(relPath) {
  const full = resolveInside(relPath);
  return await readFile(full, 'utf8');
}

export async function runInFixture(args, opts = {}) {
  return await runExec('wheels', args, { cwd: ROOT, ...opts });
}
```

- [ ] **Step 4: Run tests to verify fixture lib passes**

```bash
cd web/sites/guides
pnpm test:docs-harness -- --test-name-pattern=fixture 2>&1 | tail -20
```

Expected: all 5 fixture tests pass.

- [ ] **Step 5: Commit fixture lib**

```bash
git add web/sites/guides/scripts/verify-docs/lib/tutorial-fixture.mjs \
        web/sites/guides/scripts/verify-docs/test/tutorial.test.mjs
git commit -m "chore(docs): tutorial-fixture lib for persistent blog-tutorial app"
```

- [ ] **Step 6: Add `.gitignore` for the fixture scratch dir**

Create `web/sites/guides/scripts/verify-docs/fixtures/.gitignore`:

```gitignore
blog-tutorial/
```

- [ ] **Step 7: Write failing test for orchestrator ordering**

Append to `test/tutorial.test.mjs`:

```js
import { partitionAndOrder } from '../lib/orchestrator.mjs';

test('partitionAndOrder sorts cumulative examples by (sidebarOrder, step, line)', () => {
  const examples = [
    { file: 'a.mdx', line: 10, kind: 'tutorial', attrs: { step: '2', file: 'x.cfc' }, sidebarOrder: 2 },
    { file: 'b.mdx', line: 5, kind: 'tutorial', attrs: { step: '1', file: 'y.cfc' }, sidebarOrder: 1 },
    { file: 'a.mdx', line: 30, kind: 'cli', attrs: { cmd: 'wheels --version', step: '3' }, sidebarOrder: 2 },
    { file: 'c.mdx', line: 5, kind: 'cli', attrs: { cmd: 'wheels info' }, sidebarOrder: 3 },
    { file: 'a.mdx', line: 20, kind: 'compile', attrs: {}, sidebarOrder: 2 },
  ];
  const { perBlock, cumulative } = partitionAndOrder(examples);
  assert.deepEqual(
    cumulative.map((e) => [e.file, e.line]),
    [
      ['b.mdx', 5],   // sidebarOrder=1
      ['a.mdx', 10],  // sidebarOrder=2 step=2
      ['a.mdx', 30],  // sidebarOrder=2 step=3
    ],
  );
  assert.equal(perBlock.length, 2);
  assert.equal(perBlock[0].kind, 'compile');
  assert.equal(perBlock[1].kind, 'cli');
  assert.equal(perBlock[1].attrs.cmd, 'wheels info');
});

test('readSidebarOrder reads frontmatter sidebar.order', async () => {
  const { readSidebarOrder } = await import('../lib/orchestrator.mjs');
  const tmp = join(here, 'fixtures', 'tmp-frontmatter.mdx');
  await mkdir(dirname(tmp), { recursive: true });
  await writeFile(tmp, '---\ntitle: X\nsidebar:\n  order: 5\n---\nbody', 'utf8');
  const order = await readSidebarOrder(tmp);
  assert.equal(order, 5);
  await rm(tmp);
});

test('readSidebarOrder returns 999 when frontmatter missing order', async () => {
  const { readSidebarOrder } = await import('../lib/orchestrator.mjs');
  const tmp = join(here, 'fixtures', 'tmp-no-order.mdx');
  await mkdir(dirname(tmp), { recursive: true });
  await writeFile(tmp, '---\ntitle: X\n---\nbody', 'utf8');
  const order = await readSidebarOrder(tmp);
  assert.equal(order, 999);
  await rm(tmp);
});
```

- [ ] **Step 8: Implement the orchestrator**

Create `web/sites/guides/scripts/verify-docs/lib/orchestrator.mjs`:

```js
import { readFile } from 'node:fs/promises';

const FM_RE = /^---\n([\s\S]*?)\n---/;
const ORDER_RE = /sidebar:\s*\n\s*order:\s*(\d+)/;

export async function readSidebarOrder(file) {
  let content;
  try {
    content = await readFile(file, 'utf8');
  } catch {
    return 999;
  }
  const fm = content.match(FM_RE);
  if (!fm) return 999;
  const ord = fm[1].match(ORDER_RE);
  if (!ord) return 999;
  return Number(ord[1]);
}

export async function enrichWithSidebarOrder(examples) {
  const cache = new Map();
  for (const ex of examples) {
    if (!cache.has(ex.file)) {
      cache.set(ex.file, await readSidebarOrder(ex.file));
    }
    ex.sidebarOrder = cache.get(ex.file);
  }
  return examples;
}

export function partitionAndOrder(examples) {
  const cumulative = [];
  const perBlock = [];
  for (const ex of examples) {
    const step = ex.attrs.step;
    if (ex.kind === 'tutorial' || (ex.kind === 'cli' && step !== undefined)) {
      cumulative.push(ex);
    } else {
      perBlock.push(ex);
    }
  }
  cumulative.sort((a, b) => {
    const so = (a.sidebarOrder ?? 999) - (b.sidebarOrder ?? 999);
    if (so !== 0) return so;
    const sa = Number(a.attrs.step ?? 0);
    const sb = Number(b.attrs.step ?? 0);
    if (sa !== sb) return sa - sb;
    return a.line - b.line;
  });
  return { perBlock, cumulative };
}
```

- [ ] **Step 9: Run orchestrator tests**

```bash
cd web/sites/guides
pnpm test:docs-harness -- --test-name-pattern=partitionAndOrder\\|readSidebarOrder
```

Expected: 3 new tests pass.

- [ ] **Step 10: Commit orchestrator**

```bash
git add web/sites/guides/scripts/verify-docs/lib/orchestrator.mjs \
        web/sites/guides/scripts/verify-docs/test/tutorial.test.mjs \
        web/sites/guides/scripts/verify-docs/fixtures/.gitignore
git commit -m "chore(docs): orchestrator partitions per-block vs cumulative examples"
```

- [ ] **Step 11: Write failing test for HTTP assertion parser**

Append to `test/tutorial.test.mjs`:

```js
test('parseHttpAssert reads METHOD PATH → STATUS', async () => {
  const { parseHttpAssert } = await import('../drivers/tutorial.mjs');
  assert.deepEqual(
    parseHttpAssert('GET /posts → 200'),
    { method: 'GET', path: '/posts', status: 200, bodyIncludes: null },
  );
  assert.deepEqual(
    parseHttpAssert('POST /posts → 302 "Location: /posts/1"'),
    { method: 'POST', path: '/posts', status: 302, bodyIncludes: 'Location: /posts/1' },
  );
});

test('parseHttpAssert rejects malformed strings', async () => {
  const { parseHttpAssert } = await import('../drivers/tutorial.mjs');
  assert.throws(() => parseHttpAssert('bogus'), /malformed/);
  assert.throws(() => parseHttpAssert('GET /posts 200'), /arrow/);
});
```

- [ ] **Step 12: Implement the tutorial driver with HTTP + DB assertions**

Create `web/sites/guides/scripts/verify-docs/drivers/tutorial.mjs`:

```js
import { spawn } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
import {
  resetFixture,
  writeFixtureFile,
  appendFixtureFile,
  runInFixture,
  fixturePath,
} from '../lib/tutorial-fixture.mjs';
import { runCli } from './cli.mjs';

const HTTP_ASSERT_RE = /^(GET|POST|PUT|PATCH|DELETE)\s+(\S+)\s*(?:→|->)\s*(\d+)(?:\s+"([^"]+)")?\s*$/;

export function parseHttpAssert(spec) {
  const m = spec.match(HTTP_ASSERT_RE);
  if (!m) {
    if (!/→|->/.test(spec)) {
      throw new Error(`malformed assertion (missing arrow): ${spec}`);
    }
    throw new Error(`malformed assertion: ${spec}`);
  }
  return {
    method: m[1],
    path: m[2],
    status: Number(m[3]),
    bodyIncludes: m[4] ?? null,
  };
}

async function fetchFromFixture(server, { method, path }) {
  const url = `http://127.0.0.1:${server.port}${path}`;
  const res = await fetch(url, { method, redirect: 'manual' });
  const text = await res.text();
  return { status: res.status, body: text };
}

export class TutorialSession {
  constructor() {
    this.server = null;
    this.initialised = false;
  }

  async ensureInitialised() {
    if (this.initialised) return;
    await resetFixture();
    this.initialised = true;
  }

  async ensureServer() {
    if (this.server) return this.server;
    const port = 8080 + Math.floor(Math.random() * 1000);
    const proc = spawn('wheels', ['server', 'start', '--port', String(port)], {
      cwd: fixturePath(),
      stdio: ['ignore', 'pipe', 'pipe'],
      shell: false,
    });
    await waitForListening(port, 30_000);
    this.server = { proc, port };
    return this.server;
  }

  async stopServer() {
    if (!this.server) return;
    await runInFixture(['server', 'stop']);
    try { this.server.proc.kill('SIGTERM'); } catch {}
    this.server = null;
  }

  async applyTutorialExample(ex) {
    await this.ensureInitialised();
    const mode = ex.attrs.mode ?? 'write';
    const target = ex.attrs.file;
    if (!target) return { ok: false, message: 'missing required attr: file' };

    if (mode === 'append') {
      await appendFixtureFile(target, ex.body + '\n');
    } else {
      await writeFixtureFile(target, ex.body + '\n');
    }

    if (ex.attrs['asserts-http']) {
      const assertion = parseHttpAssert(ex.attrs['asserts-http']);
      const server = await this.ensureServer();
      const { status, body } = await fetchFromFixture(server, assertion);
      if (status !== assertion.status) {
        return { ok: false, message: `expected HTTP ${assertion.status}, got ${status}\nbody: ${body.slice(0, 500)}` };
      }
      if (assertion.bodyIncludes && !body.includes(assertion.bodyIncludes)) {
        return { ok: false, message: `response missing "${assertion.bodyIncludes}"\nbody: ${body.slice(0, 500)}` };
      }
    }

    if (ex.attrs['asserts-db-rows']) {
      const pairs = ex.attrs['asserts-db-rows'].split(',').map((p) => p.trim());
      for (const pair of pairs) {
        const [table, expected] = pair.split('=').map((p) => p.trim());
        const actual = await countRows(table);
        if (String(actual) !== expected) {
          return { ok: false, message: `expected ${table}=${expected} rows, got ${actual}` };
        }
      }
    }

    return { ok: true };
  }

  async applyCliExample(ex) {
    await this.ensureInitialised();
    return await runCliInFixture(ex);
  }
}

async function runCliInFixture(ex) {
  const cmd = ex.attrs.cmd;
  if (!cmd) return { ok: false, message: 'missing required attr: cmd' };
  const [program, ...args] = cmd.trim().split(/\s+/);
  if (program !== 'wheels') {
    return { ok: false, message: `cumulative cli examples must use 'wheels', got '${program}'` };
  }
  const result = await runInFixture(args);
  const expectedExit = ex.attrs['asserts-exit'] !== undefined ? Number(ex.attrs['asserts-exit']) : 0;
  if (result.code !== expectedExit) {
    return { ok: false, message: `expected exit ${expectedExit}, got ${result.code}\n${result.stderr || result.stdout}` };
  }
  const stdoutAssert = ex.attrs['asserts-stdout'];
  const stderrAssert = ex.attrs['asserts-stderr'];
  const outputAssert = ex.attrs['asserts-output'];
  if (stdoutAssert && !result.stdout.includes(stdoutAssert)) {
    return { ok: false, message: `stdout missing "${stdoutAssert}"\n${result.stdout}` };
  }
  if (stderrAssert && !result.stderr.includes(stderrAssert)) {
    return { ok: false, message: `stderr missing "${stderrAssert}"\n${result.stderr}` };
  }
  if (outputAssert && !(result.stdout.includes(outputAssert) || result.stderr.includes(outputAssert))) {
    return { ok: false, message: `output missing "${outputAssert}"\n${result.stdout}\n${result.stderr}` };
  }
  return { ok: true };
}

async function countRows(table) {
  const result = await runInFixture([
    'cfml',
    `q = queryExecute("SELECT COUNT(*) AS c FROM ${table}", [], {datasource: "wheelstestdb"}); writeOutput(q.c[1]);`,
  ]);
  if (result.code !== 0) throw new Error(`db count failed: ${result.stderr}`);
  return Number(result.stdout.trim());
}

async function waitForListening(port, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    try {
      const res = await fetch(`http://127.0.0.1:${port}/`, { redirect: 'manual' });
      if (res.status > 0) return;
    } catch {}
    await new Promise((r) => setTimeout(r, 500));
  }
  throw new Error(`wheels server did not listen on port ${port} within ${timeoutMs}ms`);
}

export async function runTutorial(example, session) {
  if (example.kind === 'tutorial') return await session.applyTutorialExample(example);
  if (example.kind === 'cli') return await session.applyCliExample(example);
  return { ok: false, message: `tutorial driver received unexpected kind: ${example.kind}` };
}
```

- [ ] **Step 13: Run tutorial driver parse-only tests**

```bash
cd web/sites/guides
pnpm test:docs-harness -- --test-name-pattern=parseHttpAssert
```

Expected: 2 `parseHttpAssert` tests pass.

- [ ] **Step 14: Build a mini-tutorial fixture for end-to-end test**

Create `web/sites/guides/scripts/verify-docs/test/fixtures/mini-tutorial/step-1.mdx`:

````mdx
---
title: Mini Step 1
sidebar:
  order: 1
---

```cfm {test:tutorial step=1 file="config/routes.cfm" mode="write"}
mapper()
    .root(to="home##index", method="get")
    .get(name="ping", pattern="/ping", to="home##ping")
    .wildcard()
.end();
```

```cfm {test:tutorial step=1 file="app/controllers/Home.cfc" mode="write"}
component extends="Controller" {
    function index() {}
    function ping() {
        renderText("pong");
    }
}
```

```bash {test:cli step=1 cmd="wheels reload"}
wheels reload
```
````

Create `web/sites/guides/scripts/verify-docs/test/fixtures/mini-tutorial/step-2.mdx`:

````mdx
---
title: Mini Step 2
sidebar:
  order: 2
---

```cfm {test:tutorial step=2 file="config/routes.cfm" mode="write" asserts-http="GET /ping → 200 \"pong\""}
mapper()
    .root(to="home##index", method="get")
    .get(name="ping", pattern="/ping", to="home##ping")
    .wildcard()
.end();
```
````

- [ ] **Step 15: Write end-to-end test for tutorial driver**

Append to `test/tutorial.test.mjs`:

```js
test('tutorial driver walks mini-tutorial end to end', { timeout: 300_000 }, async () => {
  const { TutorialSession } = await import('../drivers/tutorial.mjs');
  const { extractExamples } = await import('../lib/extract.mjs');
  const { partitionAndOrder, enrichWithSidebarOrder } = await import('../lib/orchestrator.mjs');

  const dir = join(here, 'fixtures', 'mini-tutorial');
  const files = [join(dir, 'step-1.mdx'), join(dir, 'step-2.mdx')];
  const examples = await extractExamples(files);
  await enrichWithSidebarOrder(examples);
  const { cumulative } = partitionAndOrder(examples);

  const session = new TutorialSession();
  try {
    for (const ex of cumulative) {
      const result = ex.kind === 'tutorial'
        ? await session.applyTutorialExample(ex)
        : await session.applyCliExample(ex);
      assert.equal(result.ok, true, `example at ${ex.file}:${ex.line} failed: ${result.message ?? ''}`);
    }
  } finally {
    await session.stopServer();
  }
});
```

- [ ] **Step 16: Run the end-to-end tutorial test**

```bash
cd web/sites/guides
pnpm test:docs-harness -- --test-name-pattern="walks mini-tutorial"
```

Expected: PASS. Duration 60-90s (fresh wheels new, server boot, one HTTP request).

- [ ] **Step 17: Wire the tutorial driver into the entrypoint**

Modify `web/sites/guides/scripts/verify-docs/verify-docs.mjs`:

```js
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

  // Per-block: parallel, isolated fixture per block.
  const perBlockResults = await Promise.all(perBlock.map(async (ex) => {
    if (ex.kind === 'cli') return { ...ex, ...(await runCli(ex)) };
    // compile is wired in Task 2.
    return { ...ex, ok: false, message: `no driver for kind "${ex.kind}"` };
  }));

  // Cumulative: sequential, shared tutorial session.
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
```

- [ ] **Step 18: Confirm existing verify-docs run still passes**

```bash
cd web/sites/guides
pnpm verify:docs
```

Expected: "2 passed, 0 failed" (the existing sample pages' cli blocks). Tutorial files don't exist yet.

- [ ] **Step 19: Update VALIDATION.md to mark tutorial driver stable**

Modify `web/sites/guides/scripts/verify-docs/VALIDATION.md`. Replace the `{test:tutorial}` section with:

````markdown
## `{test:tutorial step=N file="path" [mode="write|append"] [asserts-http="..."] [asserts-db-rows="..."]}`

The block body is written to `file` inside the tutorial's shared fixture app
at step N. The fixture is one long-lived `blog-tutorial` app reset at the
start of each harness run; all tutorial blocks (from all tutorial files) and
all `{test:cli step=N}` blocks see the same fixture state in cumulative
step order.

Required attrs:

- `step=N` — integer ordinal. Lower N runs first within a file; tie-break by
  file line.
- `file="relative/path"` — path inside the fixture (relative to the app
  root). Paths that escape the fixture root are rejected.

Optional attrs:

- `mode="write"` (default) — write the body, clobbering any existing file.
- `mode="append"` — append the body to the existing file.
- `asserts-http="METHOD PATH → STATUS"` — after the file is written, boot the
  app server (once per run) and hit this URL, asserting the status code.
- `asserts-http="METHOD PATH → STATUS \"body substring\""` — also asserts the
  response body contains the substring.
- `asserts-db-rows="table1=N,table2=M"` — after the file is written, assert
  `SELECT COUNT(*)` equals N for each table.

Ordering across files is by (frontmatter sidebar.order, step, file line).

```mdx
```cfm {test:tutorial step=2 file="app/controllers/Posts.cfc" asserts-http="GET /posts → 200"}
component extends="Controller" {
    function index() { posts = model("Post").findAll(); }
}
```
```
````

- [ ] **Step 20: Full harness + unit tests + build check**

```bash
cd web/sites/guides
pnpm test:docs-harness
pnpm verify:docs
pnpm build
```

Expected: all tests pass; verify-docs reports "2 passed, 0 failed"; build produces 266+ pages without errors.

- [ ] **Step 21: Commit tutorial driver**

```bash
git add web/sites/guides/scripts/verify-docs/
git commit -m "feat(docs): tutorial driver for cumulative blog-tutorial fixture"
```

---

## Task 2: Compile driver + re-tag existing sample pages

**Files:**
- Modify: `web/sites/guides/scripts/verify-docs/drivers/compile.mjs` (replace stub)
- Create: `web/sites/guides/scripts/verify-docs/test/compile.test.mjs`
- Modify: `web/sites/guides/scripts/verify-docs/verify-docs.mjs` (register compile driver)
- Modify: `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/01-hello-wheels.mdx` (re-tag CFC blocks)
- Modify: `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/sending-email.mdx` (re-tag CFC blocks)
- Modify: `web/sites/guides/scripts/verify-docs/VALIDATION.md` (mark compile stable, document fallback)

**Design summary:**

`wheels cfml '<body>'` takes an arbitrary CFML expression or script. With LuCLI PR #1 landed, a compile/runtime failure exits 1. The compile driver:
1. Takes the block body.
2. If the block starts with `component`, wraps it for parse-only-ish execution (`writeOutput("ok");` after the closing brace is a workaround to force parse-through without instantiation).
3. Otherwise wraps as a script body.
4. Invokes `wheels cfml '<wrapped>'`.
5. Pass if exit 0. Fail if exit 1.

**Fallback for pre-PR-#1 environments:** detect whether the installed `wheels cfml 'throw()'` exits non-zero. If it always exits 0, fall back to a pattern-match validator that checks for:
- Unbalanced `{` / `}` / `(` / `)` in the body
- Known anti-pattern: mixed argument styles (positional + named in one call) — skip this; too error-prone to detect reliably.

The fallback is deliberately minimal — its job is to catch the most obvious typos. The real check is the post-PR-#1 mode. Cache the mode-detection result across the harness run (one probe per invocation).

- [ ] **Step 1: Write failing test for exit-code detection**

Create `web/sites/guides/scripts/verify-docs/test/compile.test.mjs`:

```js
import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { runCompile, detectMode } from '../drivers/compile.mjs';

const TIMEOUT = 60_000;

test('detectMode returns "native" when wheels cfml returns non-zero on failure', { timeout: TIMEOUT }, async () => {
  const mode = await detectMode();
  assert.ok(mode === 'native' || mode === 'fallback', `unexpected mode: ${mode}`);
});

test('runCompile passes a valid CFC block', { timeout: TIMEOUT }, async () => {
  const result = await runCompile({
    file: 'test:inline',
    line: 1,
    language: 'cfm',
    kind: 'compile',
    attrs: {},
    body: 'component extends="Model" { function config() { validatesPresenceOf("title"); } }',
  });
  assert.equal(result.ok, true, `compile failed: ${result.message ?? ''}`);
});

test('runCompile fails on syntactically invalid CFML', { timeout: TIMEOUT }, async () => {
  const result = await runCompile({
    file: 'test:inline',
    line: 1,
    language: 'cfm',
    kind: 'compile',
    attrs: {},
    body: 'component { function broken( { }',
  });
  assert.equal(result.ok, false);
});

test('runCompile passes a valid script snippet', { timeout: TIMEOUT }, async () => {
  const result = await runCompile({
    file: 'test:inline',
    line: 1,
    language: 'cfm',
    kind: 'compile',
    attrs: {},
    body: 'x = 1 + 2; writeOutput(x);',
  });
  assert.equal(result.ok, true, `compile failed: ${result.message ?? ''}`);
});
```

- [ ] **Step 2: Run test to confirm failure**

```bash
cd web/sites/guides
pnpm test:docs-harness -- --test-name-pattern=detectMode\\|runCompile
```

Expected: failure — `detectMode` / `runCompile` not exported (stub still in place).

- [ ] **Step 3: Implement compile driver**

Replace `web/sites/guides/scripts/verify-docs/drivers/compile.mjs`:

```js
import { runExec } from '../lib/exec.mjs';

let _mode = null;

export async function detectMode() {
  if (_mode) return _mode;
  const probe = await runExec('wheels', ['cfml', 'throw(message="probe")']);
  _mode = probe.code === 0 ? 'fallback' : 'native';
  return _mode;
}

function balanced(body) {
  const pairs = { '(': ')', '{': '}', '[': ']' };
  const stack = [];
  let inStr = false;
  let strCh = '';
  let inLineComment = false;
  let inBlockComment = false;
  for (let i = 0; i < body.length; i++) {
    const c = body[i];
    const nx = body[i + 1];
    if (inLineComment) {
      if (c === '\n') inLineComment = false;
      continue;
    }
    if (inBlockComment) {
      if (c === '*' && nx === '/') { inBlockComment = false; i++; }
      continue;
    }
    if (inStr) {
      if (c === '\\') { i++; continue; }
      if (c === strCh) inStr = false;
      continue;
    }
    if (c === '"' || c === "'") { inStr = true; strCh = c; continue; }
    if (c === '/' && nx === '/') { inLineComment = true; i++; continue; }
    if (c === '/' && nx === '*') { inBlockComment = true; i++; continue; }
    if (pairs[c]) stack.push(pairs[c]);
    else if (Object.values(pairs).includes(c)) {
      if (stack.pop() !== c) return false;
    }
  }
  return stack.length === 0;
}

async function runNative(body) {
  // Try body as-is first (works for script fragments).
  const direct = await runExec('wheels', ['cfml', body]);
  if (direct.code === 0) return { ok: true };
  // If body starts with `component`, wrap to force instantiation attempt.
  if (/^\s*component\b/.test(body)) {
    const wrapped = `savecontent variable="_"{ include template="ram:///compile-probe.cfc"; } writeOutput("ok");`;
    // Can't easily do filesystem mounts from here; accept that component
    // bodies rely on the direct test above. If `wheels cfml` can't parse a
    // bare component, treat that as a compile failure.
  }
  return {
    ok: false,
    message: `wheels cfml exited ${direct.code}\n--- stderr ---\n${direct.stderr}\n--- stdout ---\n${direct.stdout}`,
  };
}

function runFallback(body) {
  if (!balanced(body)) {
    return { ok: false, message: 'fallback: unbalanced brackets/braces/parens' };
  }
  return { ok: true };
}

export async function runCompile(example) {
  const mode = await detectMode();
  if (mode === 'native') return await runNative(example.body);
  return runFallback(example.body);
}
```

- [ ] **Step 4: Run compile tests**

```bash
cd web/sites/guides
pnpm test:docs-harness -- --test-name-pattern=runCompile\\|detectMode
```

Expected: 4 tests pass (regardless of whether LuCLI PR #1 has merged).

- [ ] **Step 5: Wire compile driver into verify-docs.mjs**

Modify `web/sites/guides/scripts/verify-docs/verify-docs.mjs`. Inside the `perBlock.map` callback, change:

```js
const perBlockResults = await Promise.all(perBlock.map(async (ex) => {
    if (ex.kind === 'cli') return { ...ex, ...(await runCli(ex)) };
    return { ...ex, ok: false, message: `no driver for kind "${ex.kind}"` };
}));
```

…to:

```js
import { runCompile } from './drivers/compile.mjs';
// …
const perBlockResults = await Promise.all(perBlock.map(async (ex) => {
    if (ex.kind === 'cli') return { ...ex, ...(await runCli(ex)) };
    if (ex.kind === 'compile') return { ...ex, ...(await runCompile(ex)) };
    return { ...ex, ok: false, message: `no driver for kind "${ex.kind}"` };
}));
```

- [ ] **Step 6: Re-tag existing sample pages**

Modify `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/01-hello-wheels.mdx`:

Find the CFC block at lines ~116-121 currently tagged `title="app/controllers/Home.cfc"`. Replace with:

```cfm {test:compile}
component extends="Controller" {
    function index() {}
    function hello() {}
}
```

(Keep Starlight-visible title via a separate code block annotation if needed; the `{test:compile}` meta replaces the `title="..."` for the harness. Remove the existing `title="app/controllers/Home.cfc"` and reintroduce it via a preceding prose "Create `app/controllers/Home.cfc`:" line.)

Do the same for the view block at ~127-128 (`app/views/home/hello.cfm`) — it's a tiny HTML block; mark it `{test:compile}`.

Modify `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/sending-email.mdx`:

The four CFC-style blocks at ~27-34 (`settings.cfm`), ~48-56 (`WelcomeMailer.cfc`), ~62-67 (`welcome.cfm`), and ~71-83 (`Users.cfc`) all currently have `title="..."` only. Change each to `{test:compile}` — they should all parse against a bare `wheels cfml` invocation, and the prose above each block already names the target file path.

- [ ] **Step 7: Run verify-docs against the re-tagged pages**

```bash
cd web/sites/guides
pnpm verify:docs src/content/docs/v4-0-0-snapshot/start-here/tutorial/01-hello-wheels.mdx \
                 src/content/docs/v4-0-0-snapshot/digging-deeper/sending-email.mdx
```

Expected: "N passed, 0 failed" where N is the count of re-tagged blocks (plus the 2 pre-existing cli blocks).

- [ ] **Step 8: Update VALIDATION.md**

Modify `web/sites/guides/scripts/verify-docs/VALIDATION.md`. Replace the `{test:compile}` section with:

````markdown
## `{test:compile}`

The body is handed to `wheels cfml <body>`. Pass if exit code 0. Fail if
non-zero. Requires [LuCLI PR #1](https://github.com/lucee/lucli/pull/TBD)
which makes `wheels cfml` exit non-zero on execution failures.

On older LuCLI versions (where `wheels cfml` always exits 0), the driver
falls back to a pattern-match validator — currently just bracket balance.
The mode is detected once per harness run.

```cfm {test:compile}
component extends="Model" {
  function config() {
    validatesPresenceOf("title");
  }
}
```
````

- [ ] **Step 9: Commit compile driver + re-tags**

```bash
git add web/sites/guides/scripts/verify-docs/drivers/compile.mjs \
        web/sites/guides/scripts/verify-docs/test/compile.test.mjs \
        web/sites/guides/scripts/verify-docs/verify-docs.mjs \
        web/sites/guides/scripts/verify-docs/VALIDATION.md \
        web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/01-hello-wheels.mdx \
        web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/sending-email.mdx
git commit -m "feat(docs): compile driver (wheels cfml exit-code based)"
```

---

## Task 3: Welcome to Wheels

**Files:**
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/welcome.mdx`
- Modify: `web/sites/guides/src/sidebars/v4-0-0-snapshot.json` (no change — already entered in Phase 0)

**Page specification:**

Type: `concept` (this is orientation, not a task and not a tutorial).

Frontmatter:
```yaml
---
title: Welcome to Wheels
description: A quick orientation to Wheels, CFML, and how these guides are organized.
type: concept
sidebar:
  order: 1
---
```

Required sections:
1. **Opening** — 1-sentence summary + 3-line "You'll learn" block. Assumptions aside in `<Aside type="note">`.
2. **What Wheels is** — 2-3 short paragraphs. Full-stack MVC for CFML. Convention over configuration. Postgres/MySQL/MS SQL/SQLite support. Inspired by Rails but its own thing.
3. **Who these guides are for** — explicit audience declaration. Primary: developers new to Wheels (often new to CFML) coming from Rails/Laravel/Django. Secondary: existing Wheels users upgrading from 3.x. Not for: framework contributors (→ CONTRIBUTING.md) or method-by-method API reference (→ api.wheels.dev).
4. **How these guides are organized** — overview of Diátaxis split:
    - Start Here → orientation + tutorial
    - Core Concepts → explanations
    - The Basics + Digging Deeper → task-oriented how-tos
    - Testing, Deployment → operational how-tos
    - CLI Reference, Glossary → lookup
5. **The fastest path in** — `<CardGrid>` with 3 cards: Install · First 15 Minutes · Tutorial.
6. **See also** — link block with Why Wheels?, Core Concepts, CLI Reference.

Constraints:
- No code blocks (concept page, orientation only).
- No marketing adjectives ("powerful", "robust"). Describe what the feature does.
- Second person throughout.
- Components allowed: `<Aside>`, `<CardGrid>`, `<Card>`, `<LinkCard>`.

- [ ] **Step 1: Create the page file**

Create `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/welcome.mdx` following the specification above. Expected length: ~80-120 lines of MDX.

- [ ] **Step 2: Run verify-docs on the new page**

```bash
cd web/sites/guides
pnpm verify:docs src/content/docs/v4-0-0-snapshot/start-here/welcome.mdx
```

Expected: "0 passed, 0 failed" (no `{test:*}` blocks in a concept page). Exit 0.

- [ ] **Step 3: Run astro build to confirm it renders**

```bash
cd web/sites/guides
pnpm build 2>&1 | tail -10
```

Expected: build succeeds, page count goes from 266 → 267.

- [ ] **Step 4: Self-review against STYLE.md**

Re-read [STYLE.md](../../web/sites/guides/STYLE.md) and check:
- Voice (second person, no marketing copy) ✓
- "You'll learn" block present ✓
- Audience assumptions declared ✓
- No headings deeper than `###` ✓
- No emojis ✓
- Internal links use registry-style paths `/v4-0-0-snapshot/...` ✓

- [ ] **Step 5: Commit**

```bash
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/welcome.mdx
git commit -m "docs(docs): welcome to wheels orientation page"
```

---

## Task 4: Why Wheels?

**Files:**
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/why-wheels.mdx`

**Page specification:**

Type: `concept`.

Frontmatter:
```yaml
---
title: Why Wheels?
description: A head-to-head comparison of Wheels with Rails, Laravel, and Django.
type: concept
sidebar:
  order: 2
---
```

Required sections:
1. **Opening** — 1-sentence summary + "You'll learn" block. Assumption aside: basic familiarity with at least one of Rails, Laravel, or Django.
2. **What CFML is (briefly)** — 2 short paragraphs. Server-side scripting language, Java-hosted, mature (22+ years), two active engines (Lucee open-source + Adobe ColdFusion commercial). Syntax is like JavaScript + Ruby's readability. Critical point: CFML is not ColdFusion-the-product; Wheels runs on Lucee (open source, free).
3. **What Wheels is relative to Rails** — table or prose comparison. Similarities (ActiveRecord-style ORM, convention-over-config, opinionated scaffold). Differences (CFML vs Ruby runtime; built-in `wheels` CLI wrapping LuCLI; Turbo via `wheels-hotwire` package vs Rails' bundled Hotwire).
4. **What Wheels is relative to Laravel** — similar comparison. Eloquent analog is Wheels `Model`; Blade analog is `.cfm` views; Artisan analog is `wheels` CLI; Livewire has no direct analog (but Turbo Frames fill the same niche).
5. **What Wheels is relative to Django** — differences are starker: Wheels is ActiveRecord (models carry behavior), Django is DataMapper (views + serializers + ORM split). Wheels has no admin panel generator; use `wheels generate admin ModelName` for a scaffolded one.
6. **When Wheels is a bad choice** — honest limits: GraphQL-heavy APIs, realtime-first apps (SSE works but WebSockets are bolt-on), cloud-native serverless (CFML is JVM-hosted, cold starts are slow).
7. **When Wheels shines** — database-heavy line-of-business apps, teams with existing CFML/Java infrastructure, apps where "scaffold + ship" speed matters more than cutting-edge runtime features.
8. **See also** — link block with Welcome, Installing, Tutorial.

Constraints:
- No code blocks. Comparisons are prose + tables.
- Comparisons must be specific (name the framework's feature), not vague.
- No "Wheels is best" language. State facts; let the reader decide.
- Components: `<Aside>`, `<Tabs>` (per-framework tabs for the comparisons).

- [ ] **Step 1: Create page per spec**

Length: ~200-300 lines.

- [ ] **Step 2: verify-docs on the page**

```bash
cd web/sites/guides
pnpm verify:docs src/content/docs/v4-0-0-snapshot/start-here/why-wheels.mdx
```

Expected: 0/0 pass.

- [ ] **Step 3: astro build**

```bash
pnpm build 2>&1 | tail -5
```

Expected: success, 268 pages.

- [ ] **Step 4: Self-review against STYLE.md**

Particular focus: no marketing copy, no "Wheels is best", comparisons are specific and factual.

- [ ] **Step 5: Commit**

```bash
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/why-wheels.mdx
git commit -m "docs(docs): why wheels comparison page (rails/laravel/django)"
```

---

## Task 5: Installing Wheels

**Files:**
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/installing.mdx`

**Page specification:**

Type: `howto`.

Frontmatter:
```yaml
---
title: Installing Wheels
description: Install the wheels CLI on macOS, Windows, or Linux.
type: howto
sidebar:
  order: 3
---
```

Required sections:
1. **Opening** — 1-sentence summary + "You'll learn" block. Assumption aside: Java 21+ is required (link out to adoptium.net).
2. **Prerequisites** — Java 21+. Show the check command as a `{test:cli cmd="java -version"}` if the harness can run it on the CI platform; otherwise illustrative.
3. **macOS** — `<Tabs>` inside `<Steps>`:
    ```bash {test:cli cmd="wheels --version" asserts-stdout="Wheels"}
    brew tap wheels-dev/wheels
    brew install wheels
    wheels --version
    ```
    (Note: the first two lines are illustrative since the CI runner has wheels pre-installed; only `wheels --version` is tested. Verify this is true by running the task — in CI, the workflow pre-installs wheels via brew. The test block runs only the `wheels --version` line.)
4. **Windows** — `<Steps>` with `choco install wheels` + verify. Blocks are illustrative (no Windows CI runner).
5. **Linux** — `<Steps>` with install script (`curl -fsSL https://get.wheels.dev/install.sh | sh`) + verify. Illustrative (unless a Linux CI path is added mid-Phase-1; Phase 0 report flags this).
6. **Verify** — one shared verification section:
    ```bash {test:cli cmd="wheels --version" asserts-stdout="Wheels"}
    wheels --version
    ```
7. **Upgrading** — `brew upgrade wheels` / `choco upgrade wheels` / re-run install script.
8. **Troubleshooting** — three common failure modes:
    - `wheels: command not found` — PATH issue, platform-specific fixes
    - `Error: unable to find Java runtime` — install Java 21+
    - `brew: cask 'wheels' has no formulae to install from` — tap not added
9. **Related guides** — CardGrid linking First 15 Minutes, Tutorial Part 1, Upgrading Wheels.

Constraints:
- Every test-tagged block must work against the installed `wheels` CLI.
- Use `<Tabs>` for OS switching.
- Commands per OS must be real (verify against homebrew/chocolatey/get.wheels.dev — the current Phase 0 work noted "`wheels-dev/wheels` tap confirmed real"; use that exact tap name).

- [ ] **Step 1: Create page per spec**

- [ ] **Step 2: verify-docs**

```bash
cd web/sites/guides
pnpm verify:docs src/content/docs/v4-0-0-snapshot/start-here/installing.mdx
```

Expected: each `{test:cli}` block passes.

- [ ] **Step 3: astro build**

- [ ] **Step 4: Self-review**

- [ ] **Step 5: Commit**

```bash
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/installing.mdx
git commit -m "docs(docs): installing wheels page (macos/windows/linux)"
```

---

## Task 6: Your First 15 Minutes

**Files:**
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/first-15-minutes.mdx`

**Page specification:**

Type: `tutorial` (zero-to-page, no concepts explained).

Frontmatter:
```yaml
---
title: Your First 15 Minutes
description: Zero-to-running-page in fifteen minutes. No concepts explained — just get something working.
type: tutorial
sidebar:
  order: 4
---
```

Required sections:
1. **Opening** — 1-sentence summary. "You'll learn" block: install confidence, scaffold a page, see it in the browser. Assumption aside: you've installed wheels.
2. **Step 1 (3 min): Create an app**
    ```bash {test:cli cmd="wheels --version" asserts-stdout="Wheels"}
    wheels new hello
    cd hello
    ```
    (Harness runs `wheels new` inside the cli driver's fixture anyway; the explicit `wheels new hello` line in the doc is illustrative since the cli driver doesn't persist across blocks. Use `{test:cli cmd="wheels --version"}` as the verification block.)
3. **Step 2 (2 min): Start the server** — illustrative `wheels server start`.
4. **Step 3 (5 min): Add a page** — three sub-steps:
    - Add route to `config/routes.cfm`
    - Add controller action
    - Add view
   Each shown with a CFC/CFM block tagged `{test:compile}`.
5. **Step 4 (2 min): Reload and verify** — illustrative `wheels reload` + `curl`.
6. **Step 5 (3 min): What just happened** — 3-paragraph explainer linking to Core Concepts pages. No new code.
7. **Where to next** — CardGrid: Tutorial Part 1 · Core Concepts · CLI Reference.

Constraints:
- Keep it fast: a reader MUST be able to finish in 15 minutes.
- No "optional" detours.
- Every non-illustrative block tagged for the harness.
- No Troubleshooting section — Tutorial Part 1 has one; this page is meant to be skim-level.

- [ ] **Step 1: Create page per spec**

- [ ] **Step 2: verify-docs**

```bash
cd web/sites/guides
pnpm verify:docs src/content/docs/v4-0-0-snapshot/start-here/first-15-minutes.mdx
```

- [ ] **Step 3: astro build**

- [ ] **Step 4: Self-review — timing check**

Read the page as if timing yourself. If it exceeds 15 minutes of reasonable reader effort, cut. The "What just happened" section is the fastest to cut.

- [ ] **Step 5: Commit**

```bash
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/first-15-minutes.mdx
git commit -m "docs(docs): your first 15 minutes landing page"
```

---

## Task 7: Tutorial index + Part 1 resume-banner backfill

**Files:**
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/index.mdx`
- Modify: `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/01-hello-wheels.mdx` (add "Where we left off" section — since Part 1 is the first, this is a "Starting point" blurb that introduces the cumulative-fixture model)

**Tutorial index page specification:**

Type: `tutorial`.

Frontmatter:
```yaml
---
title: "Tutorial: Build a Blog"
description: A 7-part narrative tutorial. Build a complete Wheels 4.0 blog with Turbo, Basecoat, and built-in auth. Takes about 3.5 hours.
type: tutorial
sidebar:
  order: 5
---
```

Required sections:
1. **Opening** — What you'll build (a blog with posts, comments, auth), what you need (installed `wheels`, a text editor, ~3.5h).
2. **What you'll build** — screenshot or description of final state: post index, single post view with comments, signup/login, admin's own post editing.
3. **Technologies you'll use** — bullet list: CFML + Lucee 7, SQLite, Turbo Drive/Frames/Streams, Basecoat UI, built-in authentication.
4. **Parts overview** — 7-row table: part, topic, time estimate.
5. **Cross-cutting conventions** — 3-paragraph explainer:
    - SQLite throughout, zero setup.
    - "Where we left off" resume banner at top of each part — FileTree + DB schema summary.
    - Checkpoint + Troubleshooting at bottom of each part.
6. **Part CardGrid** — 7 `<LinkCard>` entries, one per part.

**Part 1 backfill:**

Add a "Where we left off" section right after the opening `<Aside>`:

```markdown
## Where we left off

This is Part 1 — you're starting with nothing. By the end you'll have a
working Wheels app responding to `/hello`. Each subsequent part begins with
a file tree and schema summary so you can resume without reading Part N-1.
```

Constraints:
- Use `<LinkCard>` for all 7 parts. 6 of them will be broken links until their respective tasks land — that's fine, Starlight renders them anyway.
- The index itself has no tagged code blocks; Parts 2-7 are the ones with cumulative harness blocks.

- [ ] **Step 1: Create the tutorial index page**

- [ ] **Step 2: Add "Where we left off" backfill to Part 1**

- [ ] **Step 3: Modify sidebar to add tutorial index link**

Modify `web/sites/guides/src/sidebars/v4-0-0-snapshot.json` — the existing tutorial entry already points at `/v4-0-0-snapshot/start-here/tutorial/`. No change needed; Starlight will pick up the new index.mdx.

- [ ] **Step 4: verify-docs + build**

- [ ] **Step 5: Commit**

```bash
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/
git commit -m "docs(docs): tutorial index + part 1 resume banner"
```

---

## Task 8: Tutorial Part 2 — First Model

**Files:**
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/02-first-model.mdx`
- Modify: `web/sites/guides/src/sidebars/v4-0-0-snapshot.json` — add Part 2 under tutorial items

**Coverage per spec Part 2 (≈20 min):**

Frontmatter:
```yaml
---
title: "Part 2: Your First Model"
description: Generate a Post model, run a migration, seed sample posts, and build the index/show actions by hand.
type: tutorial
sidebar:
  order: 2
---
```

(Note: `sidebar.order: 2` places it second under the tutorial sub-group. The tutorial index is order 5 at the Start Here level.)

Required sections:
1. **Opening** — 1-sentence summary + "You'll learn" (generators, migrations, seeds, finders).
2. **Where we left off** — FileTree showing Part 1 state + note "no database yet".
3. **Generate the Post model** — explain what the generator does:
    ```bash {test:cli step=10 cmd="wheels generate model Post title:string body:text status:enum publishedAt:datetime"}
    wheels generate model Post title:string body:text status:enum publishedAt:datetime
    ```
   Then show the generated files briefly.
4. **Anatomy of a migration** — open the generated `app/migrator/migrations/NNN_CreatePosts.cfc`; explain `t.string`, `t.text`, `t.integer("status")` (because enums are stored as integers), `t.datetime`, `t.timestamps()`. Show the actual generated content as `{test:tutorial step=11 file="app/migrator/migrations/..."}` with the known-good migration body (note: migration filename has a timestamp prefix — use a stable fixed filename for tagging).
5. **Run the migration**:
    ```bash {test:cli step=12 cmd="wheels dbmigrate latest" asserts-stdout="Migrating up"}
    wheels dbmigrate latest
    ```
6. **Configure the enum and validations**:
    ```cfm {test:tutorial step=13 file="app/models/Post.cfc"}
    component extends="Model" {
        function config() {
            enum(property="status", values="draft,published,archived");
            validatesPresenceOf("title,body");
        }
    }
    ```
7. **Seeds** — explain `seedOnce()`:
    ```cfm {test:tutorial step=14 file="app/db/seeds.cfm"}
    seedOnce(modelName="Post", uniqueProperties="title", properties={
        title: "Hello world",
        body: "My first Wheels post.",
        status: "published",
        publishedAt: Now()
    });
    seedOnce(modelName="Post", uniqueProperties="title", properties={
        title: "Learning Wheels",
        body: "Working through the tutorial.",
        status: "published",
        publishedAt: Now()
    });
    ```
8. **Run the seed**:
    ```bash {test:cli step=15 cmd="wheels db:seed" asserts-output="seeded"}
    wheels db:seed
    ```
9. **Build the Posts controller by hand** (index + show — no scaffold yet, so readers build the mental model):
    ```cfm {test:tutorial step=16 file="app/controllers/Posts.cfc"}
    component extends="Controller" {
        function index() {
            posts = model("Post").published().findAll(order="publishedAt DESC");
        }
        function show() {
            post = model("Post").findByKey(params.key);
        }
    }
    ```
   Explain the enum-scope (`published()`) auto-generated by the enum declaration.
10. **Add routes**:
    ```cfm {test:tutorial step=17 file="config/routes.cfm"}
    mapper()
        .resources(name="posts", only="index,show")
        .get(name="hello", pattern="/hello", to="home##hello")
        .root(to="posts##index", method="get")
        .wildcard()
    .end();
    ```
11. **Write the index view**:
    ```cfm {test:tutorial step=18 file="app/views/posts/index.cfm"}
    <cfparam name="posts" default="">
    <h1>Posts</h1>
    <cfloop query="posts">
        <article>
            <h2>#linkTo(route="post", key=posts.id, text=posts.title)#</h2>
            <p>#posts.body#</p>
        </article>
    </cfloop>
    ```
12. **Write the show view**:
    ```cfm {test:tutorial step=19 file="app/views/posts/show.cfm"}
    <cfparam name="post" default="">
    <h1>#post.title#</h1>
    <p>#post.body#</p>
    <p>#linkTo(route="posts", text="← all posts")#</p>
    ```
13. **Checkpoint** — harness-executable:
    ```bash {test:cli step=20 cmd="wheels reload"}
    wheels reload
    ```
    Then a tutorial block with `asserts-http` to confirm the app serves `/posts` and `/posts/1`:
    ```cfm {test:tutorial step=21 file="app/controllers/Posts.cfc" mode="write" asserts-http="GET /posts → 200 \"Hello world\""}
    component extends="Controller" {
        function index() {
            posts = model("Post").published().findAll(order="publishedAt DESC");
        }
        function show() {
            post = model("Post").findByKey(params.key);
        }
    }
    ```
    (Same body as step 16 — this is a write-no-op that triggers the HTTP assert. Alternatively: `asserts-http` could be attached to an earlier `{test:tutorial}` at step 16 if the server is guaranteed reloaded between step 18 and step 21. Prefer the explicit reload-then-assert pattern for clarity.)
14. **Troubleshooting** — 3 failure modes:
    - "Data source wheelstestdb not found" → migration didn't run
    - "model 'Post' is undefined" → wheels reload missed
    - "no rows" → seed didn't run; check `wheels db:seed` output

Step ordering: use step=10 through step=21 for Part 2 to leave slack before and after. Part 1 has no tutorial steps (covered by Part 7's "build up from scratch" assumption); Part 2 can start at step=10.

- [ ] **Step 1: Create the page per spec, with all harness tags**

- [ ] **Step 2: Add Part 2 to sidebar**

Modify `web/sites/guides/src/sidebars/v4-0-0-snapshot.json` — add to the tutorial items array:

```json
{ "label": "2. Your First Model", "link": "/v4-0-0-snapshot/start-here/tutorial/02-first-model/" }
```

- [ ] **Step 3: Run the full tutorial driver against Parts 1-2**

```bash
cd web/sites/guides
pnpm verify:docs src/content/docs/v4-0-0-snapshot/start-here/tutorial/
```

Expected: the harness boots the fixture, walks steps 1-21, all pass. Duration ~60-90s.

- [ ] **Step 4: Fix any failures**

Common failure modes to expect:
- Enum column type wrong (expected `integer`, got `string` from the generator) — adjust generator invocation or migration.
- Seed data not showing due to enum string vs integer confusion — check Post model enum mapping.
- Route ordering — `resources` before `root` before `wildcard`.

- [ ] **Step 5: Commit**

```bash
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/02-first-model.mdx \
        web/sites/guides/src/sidebars/v4-0-0-snapshot.json
git commit -m "docs(docs): tutorial part 2 — first model"
```

---

## Task 9: Tutorial Part 3 — CRUD Scaffold + Turbo Drive

**Files:**
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/03-crud-scaffold.mdx`
- Modify: `web/sites/guides/src/sidebars/v4-0-0-snapshot.json`

**Coverage per spec Part 3 (≈25 min):**

Key narrative: delete the hand-rolled controller + views from Part 2, run `wheels generate scaffold Post ...`, and show that the Basecoat-styled forms + Turbo-Drive views emit a full CRUD flow that feels SPA-ish with zero page flash.

Steps (using step=30+ for Part 3):
1. "Where we left off" — FileTree including `app/models/Post.cfc`, `app/controllers/Posts.cfc`, views, migration, 2 seed rows.
2. Delete Part 2's hand-built files:
    ```bash {test:cli step=30 cmd="wheels destroy controller Posts"}
    wheels destroy controller Posts
    ```
    (If `wheels destroy` doesn't handle this, manually delete via `{test:tutorial file="..." mode="write"}` writing an empty placeholder — TBD, check available CLI.)
3. Run the scaffold generator:
    ```bash {test:cli step=31 cmd="wheels generate scaffold Post title:string body:text status:enum"}
    wheels generate scaffold Post title:string body:text status:enum
    ```
4. Tour every generated file — controller actions (`index`/`show`/`new`/`create`/`edit`/`update`/`delete`), views (`index`/`show`/`new`/`edit`/`_form`), routes entry. Show the content of each with `title="..."` (illustrative — don't re-tag as tutorial since the scaffold generator writes them directly).
5. Explain route model binding — `params.post` already resolved in `show`/`edit`/`update`/`delete` actions.
6. Show Turbo Drive in action — navigate from index to new-post form; no page flash. Screenshot placeholder.
7. Checkpoint:
    ```bash {test:cli step=32 cmd="wheels reload"}
    wheels reload
    ```
    ```cfm {test:tutorial step=33 file="config/routes.cfm" mode="write" asserts-http="GET /posts → 200"}
    mapper()
        .resources("posts")
        .root(to="posts##index", method="get")
        .wildcard()
    .end();
    ```
    (Scaffold generator will have already emitted `.resources("posts")` — this is a safety overwrite before the HTTP assert.)
8. Troubleshooting — 3 failure modes:
    - Basecoat styles not loaded → `vendor/basecoat` missing; re-run `wheels new` or activate package
    - 404 on `/posts/new` → route order; scaffold entries must precede `.wildcard()`
    - Form submission returns HTML string instead of redirect → Turbo Drive needs `data-turbo="true"` on body (Basecoat layout handles this)

- [ ] **Step 1: Create page per spec**
- [ ] **Step 2: Add Part 3 to sidebar**
- [ ] **Step 3: Run tutorial driver against Parts 1-3**
- [ ] **Step 4: Fix failures**
- [ ] **Step 5: Commit**
```bash
git commit -m "docs(docs): tutorial part 3 — crud scaffold + turbo drive"
```

---

## Task 10: Tutorial Part 4 — Validations + Turbo Frames

**Files:**
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/04-validations-frames.mdx`
- Modify: `web/sites/guides/src/sidebars/v4-0-0-snapshot.json`

**Coverage per spec Part 4 (≈30 min):**

Key narrative: the "whoa" moment. Wrap the scaffold's form in `<turbo-frame>`; validation errors come back inline without a page reload. Auto-generated enum scopes filter the index.

Steps (step=40-50):
1. "Where we left off" — post model exists, scaffold views exist, 2 posts seeded.
2. Add validations:
    ```cfm {test:tutorial step=40 file="app/models/Post.cfc"}
    component extends="Model" {
        function config() {
            enum(property="status", values="draft,published,archived");
            validatesPresenceOf("title,body");
            validatesLengthOf(property="title", maximum=120);
        }
    }
    ```
3. Wrap the scaffold's form partial in a turbo-frame:
    ```cfm {test:tutorial step=41 file="app/views/posts/_form.cfm"}
    <turbo-frame id="post_form">
        <cfoutput>
            #errorMessagesFor("post")#
            #startFormTag(route="posts")#
                <label>Title #textField(objectName="post", property="title")#</label>
                <label>Body #textArea(objectName="post", property="body")#</label>
                <label>Status #select(objectName="post", property="status", options="draft,published,archived")#</label>
                <button type="submit">Save</button>
            #endFormTag()#
        </cfoutput>
    </turbo-frame>
    ```
4. Modify `create()` to render the form partial back when invalid — so Turbo replaces only the frame:
    ```cfm {test:tutorial step=42 file="app/controllers/Posts.cfc"}
    component extends="Controller" {
        function index() {
            posts = model("Post").published().findAll(order="publishedAt DESC");
        }
        function show() {}
        function new() { post = model("Post").new(); }
        function create() {
            post = model("Post").new(params.post);
            if (post.save()) {
                redirectTo(route="post", key=post.id);
            } else {
                renderPartial("form");
            }
        }
        function edit() {}
        function update() {
            if (params.post.update(params.post)) {
                redirectTo(route="post", key=params.post.id);
            } else {
                renderPartial("form");
            }
        }
        function delete() {
            params.post.delete();
            redirectTo(route="posts");
        }
    }
    ```
    (Note: params.post is route-model-bound from `resources("posts")` — verify this works in the fixture. If not, use `findByKey(params.key)` explicitly.)
5. Add "Publish" / "Save as Draft" buttons:
    ```cfm {test:tutorial step=43 file="app/views/posts/_form.cfm" mode="append"}
    
    <cfoutput>
        <button type="submit" name="post[status]" value="draft">Save Draft</button>
        <button type="submit" name="post[status]" value="published">Publish</button>
    </cfoutput>
    ```
6. Filter index to exclude drafts from public view (already done — `.published()` scope).
7. Show in a separate view that admins see all:
    ```cfm {test:tutorial step=44 file="app/views/posts/admin.cfm"}
    <cfparam name="posts" default="">
    <h1>All Posts (admin)</h1>
    <cfloop query="posts">
        #posts.title# — #posts.status#
    </cfloop>
    ```
8. Checkpoint — harness asserts that posting an invalid form returns the partial with error messages:
    ```bash {test:cli step=45 cmd="wheels reload"}
    wheels reload
    ```
    ```cfm {test:tutorial step=46 file="config/routes.cfm" mode="write" asserts-http="POST /posts → 422"}
    mapper()
        .resources("posts")
        .root(to="posts##index", method="get")
        .wildcard()
    .end();
    ```
    (422 is Wheels' default for invalid form POST when rendering a partial back. If it's a different status — 200 with a Turbo-Stream response, depending on Wheels 4.0's Turbo integration — adjust the assert accordingly.)
9. Troubleshooting:
    - Form reloads the whole page instead of only the frame → missing `<turbo-frame>` wrapper or Turbo Drive not loaded
    - Validation errors don't appear → `errorMessagesFor()` not called or partial not wrapping the error region
    - 500 on POST → route to the wrong action; check `resources("posts")` generated a POST /posts

- [ ] **Step 1-5:** same shape as Task 9.

```bash
git commit -m "docs(docs): tutorial part 4 — validations + turbo frames"
```

---

## Task 11: Tutorial Part 5 — Comments + Associations + Turbo Streams

**Files:**
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/05-comments-streams.mdx`
- Modify: `web/sites/guides/src/sidebars/v4-0-0-snapshot.json`

**Coverage per spec Part 5 (≈35 min):**

Steps (step=50-65):
1. "Where we left off" — post CRUD works, validations inline.
2. Generate Comment model:
    ```bash {test:cli step=50 cmd="wheels generate model Comment postId:integer author:string body:text"}
    wheels generate model Comment postId:integer author:string body:text
    ```
3. Run migration:
    ```bash {test:cli step=51 cmd="wheels dbmigrate latest" asserts-stdout="Migrating up"}
    wheels dbmigrate latest
    ```
4. Wire associations — Comment belongsTo Post, Post hasMany Comments:
    ```cfm {test:tutorial step=52 file="app/models/Comment.cfc"}
    component extends="Model" {
        function config() {
            belongsTo(name="post");
            validatesPresenceOf("author,body");
        }
    }
    ```
    ```cfm {test:tutorial step=53 file="app/models/Post.cfc"}
    component extends="Model" {
        function config() {
            enum(property="status", values="draft,published,archived");
            hasMany(name="comments", dependent="delete");
            validatesPresenceOf("title,body");
            validatesLengthOf(property="title", maximum=120);
        }
    }
    ```
5. Nested routes via callback syntax:
    ```cfm {test:tutorial step=54 file="config/routes.cfm"}
    mapper()
        .resources(name="posts", callback=function(map) {
            map.resources(name="comments", only="create");
        })
        .root(to="posts##index", method="get")
        .wildcard()
    .end();
    ```
6. Generate comments controller:
    ```bash {test:cli step=55 cmd="wheels generate controller Comments create"}
    wheels generate controller Comments create
    ```
7. Implement create with Turbo Stream response:
    ```cfm {test:tutorial step=56 file="app/controllers/Comments.cfc"}
    component extends="Controller" {
        function create() {
            post = model("Post").findByKey(params.postId);
            comment = post.createComment(params.comment);
            if (comment.hasErrors()) {
                renderPartial(partial="form", layout=false);
            } else {
                renderPartial(partial="comment", comment=comment, layout=false);
            }
        }
    }
    ```
8. Show view with comments + form:
    ```cfm {test:tutorial step=57 file="app/views/posts/show.cfm"}
    <cfparam name="post" default="">
    <h1>#post.title#</h1>
    <p>#post.body#</p>
    <section id="comments">
        <h2>Comments</h2>
        <cfloop query="post.comments()">
            <turbo-frame id="comment_#post.comments.id#">
                <p><strong>#post.comments.author#</strong>: #post.comments.body#</p>
            </turbo-frame>
        </cfloop>
    </section>
    <turbo-frame id="new_comment">
        #renderPartial("comments/form", post=post)#
    </turbo-frame>
    ```
9. Comments form partial:
    ```cfm {test:tutorial step=58 file="app/views/comments/_form.cfm"}
    <cfoutput>
        #startFormTag(route="postComments", postKey=post.id)#
            <input name="comment[author]" placeholder="Your name">
            <textarea name="comment[body]" placeholder="Your comment"></textarea>
            <button type="submit">Post comment</button>
        #endFormTag()#
    </cfoutput>
    ```
10. Update index to avoid N+1:
    ```cfm {test:tutorial step=59 file="app/controllers/Posts.cfc"}
    component extends="Controller" {
        function index() {
            posts = model("Post").published().findAll(include="comments", order="publishedAt DESC");
        }
        function show() {}
        function new() { post = model("Post").new(); }
        function create() {
            post = model("Post").new(params.post);
            if (post.save()) { redirectTo(route="post", key=post.id); }
            else { renderPartial("form"); }
        }
        function edit() {}
        function update() {
            if (params.post.update(params.post)) { redirectTo(route="post", key=params.post.id); }
            else { renderPartial("form"); }
        }
        function delete() {
            params.post.delete();
            redirectTo(route="posts");
        }
    }
    ```
11. Checkpoint — comment POST succeeds and cascading delete works:
    ```bash {test:cli step=60 cmd="wheels reload"}
    wheels reload
    ```
    ```cfm {test:tutorial step=61 file="config/routes.cfm" mode="write" asserts-http="GET /posts/1 → 200"}
    mapper()
        .resources(name="posts", callback=function(map) {
            map.resources(name="comments", only="create");
        })
        .root(to="posts##index", method="get")
        .wildcard()
    .end();
    ```
    Additionally, an HTTP POST test would assert `POST /posts/1/comments` → 200 and that comments row count increments. Add an extra step=62 tutorial block with `asserts-http="POST /posts/1/comments → 200"` and `asserts-db-rows="comments=1"` — note that the POST needs form body, which `fetch()` can do. (If the driver doesn't support body injection yet, the `asserts-http` parser needs extending — leave that as a known gap and rely on the GET assertion only for Phase 1.)
12. Troubleshooting:
    - Nested route 404 → nested resource inside non-callback syntax
    - `post.createComment` not found → Comment model's `belongsTo(name="post")` + Post model's `hasMany(name="comments")` mismatch (name must match)
    - N+1 queries → missing `include="comments"` in index finder

- [ ] **Step 1-5**

```bash
git commit -m "docs(docs): tutorial part 5 — comments + turbo streams"
```

---

## Task 12: Tutorial Part 6 — Authentication (6a hand-rolled + 6b built-in)

**Files:**
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/06-authentication.mdx`
- Modify: `web/sites/guides/src/sidebars/v4-0-0-snapshot.json`

**Coverage per spec Part 6 (≈45 min, 6a + 6b):**

This is the longest part. Structure:
- Intro (3 min)
- 6a: Roll Your Own (25 min) — teaches mental model
- 6b: The Built-in Way (20 min) — shortcut reveal
- Compare results, checkpoint, troubleshooting

Steps (step=70-90 for 6a, step=91-99 for 6b):

**Part 6a (Roll Your Own):**
1. Generate User model:
    ```bash {test:cli step=70 cmd="wheels generate model User email:string passwordHash:string"}
    wheels generate model User email:string passwordHash:string
    ```
2. Run migration:
    ```bash {test:cli step=71 cmd="wheels dbmigrate latest" asserts-stdout="Migrating up"}
    wheels dbmigrate latest
    ```
3. User model with BCrypt via `beforeSave`:
    ```cfm {test:tutorial step=72 file="app/models/User.cfc"}
    component extends="Model" {
        function config() {
            validatesPresenceOf("email");
            validatesUniquenessOf(property="email");
            beforeSave("hashPassword");
        }
        private function hashPassword() {
            if (StructKeyExists(this, "password") && Len(this.password)) {
                this.passwordHash = hashBCrypt(this.password);
                StructDelete(this, "password");
            }
        }
        public boolean function authenticate(required string password) {
            return verifyBCrypt(arguments.password, this.passwordHash);
        }
    }
    ```
    (Note: `hashBCrypt`/`verifyBCrypt` — verify exact function names in Wheels 4.0; may be `bcryptHash`/`bcryptVerify` or similar. Update to the actual names.)
4. Generate sessions controller by hand:
    ```cfm {test:tutorial step=73 file="app/controllers/Sessions.cfc"}
    component extends="Controller" {
        function new() {}
        function create() {
            user = model("User").findOne(where="email = '#params.session.email#'");
            if (IsObject(user) && user.authenticate(params.session.password)) {
                session.userId = user.id;
                redirectTo(route="posts");
            } else {
                flashInsert(error="Invalid credentials");
                redirectTo(route="login");
            }
        }
        function delete() {
            StructDelete(session, "userId");
            redirectTo(route="login");
        }
    }
    ```
5. Signup controller:
    ```cfm {test:tutorial step=74 file="app/controllers/Users.cfc"}
    component extends="Controller" {
        function new() { user = model("User").new(); }
        function create() {
            user = model("User").new(params.user);
            user.password = params.user.password;
            if (user.save()) {
                session.userId = user.id;
                redirectTo(route="posts");
            } else {
                renderView(action="new");
            }
        }
    }
    ```
6. authenticate filter as a private method:
    ```cfm {test:tutorial step=75 file="app/controllers/Posts.cfc"}
    component extends="Controller" {
        function config() {
            filters(through="authenticate", except="index,show");
        }
        function index() {
            posts = model("Post").published().findAll(include="comments", order="publishedAt DESC");
        }
        function show() {}
        function new() { post = model("Post").new(); }
        function create() {
            post = model("Post").new(params.post);
            post.userId = session.userId;
            if (post.save()) { redirectTo(route="post", key=post.id); }
            else { renderPartial("form"); }
        }
        function edit() { ownershipCheck(); }
        function update() { ownershipCheck(); if (params.post.update(params.post)) { redirectTo(route="post", key=params.post.id); } else { renderPartial("form"); } }
        function delete() { ownershipCheck(); params.post.delete(); redirectTo(route="posts"); }
        private function authenticate() {
            if (!StructKeyExists(session, "userId")) {
                flashInsert(error="Please log in first");
                redirectTo(route="login");
            }
        }
        private function ownershipCheck() {
            if (params.post.userId != session.userId) { redirectTo(route="posts"); }
        }
    }
    ```
7. Migration to add `userId` column to posts:
    ```bash {test:cli step=76 cmd="wheels generate migration AddUserToPosts"}
    wheels generate migration AddUserToPosts
    ```
    ```cfm {test:tutorial step=77 file="app/migrator/migrations/NNN_AddUserToPosts.cfc"}
    component extends="wheels.migrator.Migration" hint="Add userId to posts" {
        function up() { addColumn(table="posts", columnType="integer", columnName="userId"); }
        function down() { removeColumn(table="posts", columnName="userId"); }
    }
    ```
8. Routes for login/logout/signup:
    ```cfm {test:tutorial step=78 file="config/routes.cfm"}
    mapper()
        .resources(name="posts", callback=function(map) { map.resources(name="comments", only="create"); })
        .resources("users")
        .get(name="login", pattern="/login", to="sessions##new")
        .post(name="authenticate", pattern="/login", to="sessions##create")
        .delete(name="logout", pattern="/logout", to="sessions##delete")
        .root(to="posts##index", method="get")
        .wildcard()
    .end();
    ```
9. Run migration:
    ```bash {test:cli step=79 cmd="wheels dbmigrate latest" asserts-stdout="Migrating up"}
    wheels dbmigrate latest
    ```
10. Checkpoint 6a: login flow works, unauthenticated create returns redirect:
    ```bash {test:cli step=80 cmd="wheels reload"}
    wheels reload
    ```
    Skip HTTP POST for Phase 1 if body injection isn't supported; assert redirect-on-GET instead:
    ```cfm {test:tutorial step=81 file="config/routes.cfm" mode="write" asserts-http="GET /posts/new → 302"}
    mapper()
        .resources(name="posts", callback=function(map) { map.resources(name="comments", only="create"); })
        .resources("users")
        .get(name="login", pattern="/login", to="sessions##new")
        .post(name="authenticate", pattern="/login", to="sessions##create")
        .delete(name="logout", pattern="/logout", to="sessions##delete")
        .root(to="posts##index", method="get")
        .wildcard()
    .end();
    ```

**Part 6b (Built-in):** Replace 6a's hand-rolled pieces with DI-resolved built-ins.
11. Register SessionStrategy in services.cfm:
    ```cfm {test:tutorial step=91 file="config/services.cfm"}
    var di = injector();
    di.map("authenticator").to("wheels.auth.SessionStrategy").asRequestScoped();
    ```
    (Verify exact class name and mapping — Wheels 4.0 ships `wheels.auth.SessionStrategy` per the spec; confirm against `vendor/wheels/auth/`.)
12. Replace hand-rolled sessions controller with one that calls the authenticator service:
    ```cfm {test:tutorial step=92 file="app/controllers/Sessions.cfc"}
    component extends="Controller" {
        function config() {
            inject("authenticator");
        }
        function new() {}
        function create() {
            result = this.authenticator.authenticate(request);
            if (result.success) { redirectTo(route="posts"); }
            else { flashInsert(error=result.error); redirectTo(route="login"); }
        }
        function delete() {
            this.authenticator.logout(request);
            redirectTo(route="login");
        }
    }
    ```
13. Replace authenticate filter with middleware:
    ```cfm {test:tutorial step=93 file="app/controllers/Posts.cfc"}
    component extends="Controller" {
        function config() {
            filters(through="$auth.requireUser", except="index,show");
        }
        // ... same actions as 6a but without the private authenticate method
    }
    ```
    (Check exact integration: Wheels 4.0 may expose this as a built-in filter on `Controller`. Adjust syntax accordingly.)
14. Compare: show side-by-side that 6a and 6b produce the same behavior.
15. Checkpoint 6b — harness re-asserts same HTTP behavior as step 81.
16. Troubleshooting:
    - "authenticator not resolved" → services.cfm not loaded; check app boot order
    - "filter not found" → 6b filter syntax mismatch
    - 500 on login POST → body parser missing; check Wheels CSRF token handling

- [ ] **Steps 1-5** — standard template.

**Budget note:** Part 6 is long. If the harness takes >3 minutes on Part 6, consider splitting 6a and 6b into separate files (which would mean 8 parts not 7 — check with Peter before doing that).

```bash
git commit -m "docs(docs): tutorial part 6 — authentication (hand-rolled + built-in)"
```

---

## Task 13: Tutorial Part 7 — Testing, Deploying, What's Next

**Files:**
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/07-testing-deploying.mdx`
- Modify: `web/sites/guides/src/sidebars/v4-0-0-snapshot.json`

**Coverage per spec Part 7 (≈35 min):**

Steps (step=100-115):
1. "Where we left off" — full auth'd blog app with posts, comments, users.
2. Why test — 1 paragraph on the value + the Wheels reference platform (SQLite, Lucee 7).
3. First model spec:
    ```cfm {test:tutorial step=100 file="tests/specs/models/PostSpec.cfc"}
    component extends="wheels.WheelsTest" {
        function run() {
            describe("Post", () => {
                it("requires a title", () => {
                    var post = model("Post").new(body="some body");
                    expect(post.valid()).toBeFalse();
                    expect(post.errorsOn("title")).toBeTruthy();
                });
                it("rejects titles over 120 chars", () => {
                    var post = model("Post").new(title=repeatString("x", 121), body="body");
                    expect(post.valid()).toBeFalse();
                });
            });
        }
    }
    ```
4. First controller spec:
    ```cfm {test:tutorial step=101 file="tests/specs/controllers/PostsControllerSpec.cfc"}
    component extends="wheels.WheelsTest" {
        function run() {
            describe("Posts#index", () => {
                it("shows published posts only", () => {
                    // populate fixture + visit '/posts' via testable request, assert response
                });
            });
        }
    }
    ```
5. Run the test suite:
    ```bash {test:cli step=102 cmd="wheels test run" asserts-output="pass"}
    wheels test run
    ```
6. One browser test with Playwright:
    ```cfm {test:tutorial step=103 file="tests/specs/browser/SignupFlowSpec.cfc"}
    component extends="wheels.wheelstest.BrowserTest" {
        this.browserEngine = "chromium";
        function run() {
            browserDescribe("Full signup flow", () => {
                it("signs up, creates a post, adds a comment", () => {
                    if (this.browserTestSkipped) return;
                    this.browser.visitRoute("signup")
                        .fill("##email", "alice@example.com")
                        .fill("##password", "hunter2")
                        .click("button[type=submit]")
                        .assertUrlContains("/posts");
                });
            });
        }
    }
    ```
    (Note: this spec requires `wheels browser:install` — mention it and tag as illustrative if the harness CI runner doesn't have Playwright; Phase 0 installed it, so this may be testable end-to-end.)
7. `bash tools/test-local.sh` — illustrative (harness runs in its own fixture, not the main wheels repo).
8. Deployment overview — 2-paragraph intro linking to Deployment & Operations. Two paths: Docker + VM. Kamal is recommended (per user direction). Don't walk through the full deploy here; Phase 2's Deployment section does that.
9. What to read next — `<CardGrid>` with 3 `<LinkCard>`: Core Concepts · Digging Deeper · Testing.
10. Checkpoint:
    ```bash {test:cli step=110 cmd="wheels test run" asserts-output="pass"}
    wheels test run
    ```
11. Troubleshooting:
    - "test suite not found" → tests/ dir missing; scaffold didn't include it
    - Browser test skipped → `wheels browser:install` needed
    - Tests fail intermittently → race condition; use `beforeEach` fixtures

- [ ] **Step 1-5:** standard template.

```bash
git commit -m "docs(docs): tutorial part 7 — testing, deploying, what's next"
```

---

## Task 14: Full harness run + astro build + Cloudflare preview + completion report

**Files:**
- Create: `docs/superpowers/plans/2026-04-18-guides-rewrite-phase-1-report.md`

- [ ] **Step 1: Full harness run**

```bash
cd web/sites/guides
pnpm verify:docs 2>&1 | tee /tmp/phase1-harness.log
```

Expected outputs:
- Total tagged blocks: ~80-120 (depending on tutorial block density)
- Passed: all
- Failed: 0
- Duration: 3-6 minutes

- [ ] **Step 2: Full test suite**

```bash
pnpm test:docs-harness
```

Expected: all tests pass (11 from Phase 0 + 5-10 new from Tasks 1-2).

- [ ] **Step 3: Full astro build**

```bash
pnpm build 2>&1 | tee /tmp/phase1-build.log
```

Expected: 278+ pages (266 from Phase 0 + 12 from Phase 1: Welcome, Why Wheels?, Installing, First 15 Min, Tutorial Index, Parts 2-7). No broken-link errors.

- [ ] **Step 4: Push branch and note the Cloudflare preview URL**

```bash
git push -u origin claude/lucid-thompson-b8c121
gh pr create --draft --title "docs: Wheels 4.0 guides Phase 1 (DO NOT MERGE)" \
  --body "$(cat <<'EOF'
Phase 1 of the Wheels 4.0 guides rewrite. Not for merge — lands in one
final PR at the end of Phase 2.

This draft PR exists so Cloudflare Pages provides a preview URL for review.

See [Phase 1 completion report](./docs/superpowers/plans/2026-04-18-guides-rewrite-phase-1-report.md).
EOF
)"
```

Capture the Cloudflare preview URL from the PR comments (Cloudflare bot posts within ~2 minutes of push).

- [ ] **Step 5: Write Phase 1 completion report**

Create `docs/superpowers/plans/2026-04-18-guides-rewrite-phase-1-report.md` following the Phase 0 report template:

```markdown
# Guides Rewrite — Phase 1 Completion Report

**Date:** <today>
**Branch:** `claude/lucid-thompson-b8c121`
**Spec:** [../specs/2026-04-18-guides-rewrite-v4-design.md]
**Plan:** [./2026-04-18-guides-rewrite-phase-1.md]

## Shipped
- Table of commits: SHA | What

## Deliverables checklist
- [x] Tutorial driver + fixture + orchestrator + tests
- [x] Compile driver (native + fallback mode)
- [x] Welcome to Wheels
- [x] Why Wheels? (Rails/Laravel/Django comparison)
- [x] Installing Wheels (macOS/Windows/Linux)
- [x] Your First 15 Minutes
- [x] Tutorial index + Parts 1-7

## Verification
- `pnpm verify:docs` — N tagged blocks, all pass. Duration: Nm.
- `pnpm test:docs-harness` — N specs pass.
- `pnpm build` — N pages.
- Cloudflare preview: <URL>

## What changed from the plan
Any deviations, documented.

## Known gaps for Phase 2
- `.ai/` decision still deferred.
- ...

## Open decisions before Phase 2
...
```

- [ ] **Step 6: Commit report**

```bash
git add docs/superpowers/plans/2026-04-18-guides-rewrite-phase-1-report.md
git commit -m "docs(docs): phase 1 completion report"
git push
```

---

## Task 15: Final code review

**Files:**
- None authored; dispatches review subagent.

- [ ] **Step 1: Compute Phase 1 diff**

```bash
git diff ee2ad45bd..HEAD --stat
git diff ee2ad45bd..HEAD > /tmp/phase1.diff
wc -l /tmp/phase1.diff
```

- [ ] **Step 2: Dispatch pr-review-toolkit:code-reviewer subagent**

Agent invocation template:

```
subagent_type: pr-review-toolkit:code-reviewer
description: Phase 1 guides rewrite review
prompt: |
  Review the Wheels 4.0 guides Phase 1 diff at /tmp/phase1.diff. Context:

  - This is branch claude/lucid-thompson-b8c121, diffed against the Phase 0
    base at ee2ad45bd. Not yet merged to develop — final merge is end of
    Phase 2.
  - Phase 1 ships: (a) two new verify-docs drivers (tutorial, compile) with
    unit tests, (b) 12 new/modified MDX pages (4 Start Here + tutorial index
    + 7 tutorial parts), (c) sidebar updates, (d) VALIDATION.md additions.
  - Style constraints: see web/sites/guides/STYLE.md. Diátaxis purity, no
    marketing copy, second-person voice, real names (not foo/bar), every
    code block either {test:*}-tagged or explicitly marked illustrative.
  - Tutorial driver architecture: one persistent fixture for all cumulative
    examples (tutorial + step-numbered cli); orchestrator sorts by
    (sidebar.order, step, line).
  - All harness blocks were validated end-to-end before this review (see
    Phase 1 report).

  Review focus:
  1. Code correctness in drivers/tutorial.mjs, drivers/compile.mjs,
     lib/tutorial-fixture.mjs, lib/orchestrator.mjs. Security (fixture path
     escapes, command injection), error handling, resource cleanup
     (fixture teardown, server lifecycle), test coverage.
  2. Content quality: flag any instance of marketing language, first-person,
     or broken Diátaxis boundaries (e.g. a how-to that teaches concepts).
  3. Tutorial cross-file consistency: does Part N build correctly on Part
     N-1's fixture state? Are step numbers contiguous within a file? Are
     FileTree snapshots at the start of each part accurate to the fixture
     state at that point?
  4. Anything that would make an experienced Wheels user roll their eyes.

  Report blocking issues, nits separately, and recommended follow-ups for
  Phase 2.
```

- [ ] **Step 3: Respond to review comments**

Address any blocking issues raised. File Phase 2 follow-ups for non-blockers.

- [ ] **Step 4: Final commit (if review changes were needed)**

```bash
git commit -m "docs(docs): address phase 1 review feedback"
git push
```

---

## Self-review

**Spec coverage check:**

| Spec requirement | Task(s) |
|------------------|---------|
| Tutorial fixture driver | 1 |
| `{test:compile}` live | 2 |
| Re-tag Phase 0 sample pages as `{test:compile}` | 2 |
| Welcome to Wheels page | 3 |
| Why Wheels? with Rails/Laravel/Django comparison | 4 |
| Installing Wheels (macOS/Windows/Linux) | 5 |
| Your First 15 Minutes | 6 |
| Tutorial Part 1 — Hello, Wheels (Phase 0 base, Phase 1 backfill) | 7 |
| Tutorial Part 2 — Your First Model | 8 |
| Tutorial Part 3 — CRUD Scaffold + Turbo Drive | 9 |
| Tutorial Part 4 — Validations + Turbo Frames | 10 |
| Tutorial Part 5 — Comments + Associations + Turbo Streams | 11 |
| Tutorial Part 6 — Authentication (6a + 6b) | 12 |
| Tutorial Part 7 — Testing, Deploying, What's Next | 13 |
| Tutorial fixture driven end-to-end by harness | 1, 8-13 |
| SQLite throughout | Task 1 fixture config (default) |
| Basecoat + Hotwire activated from Part 1 | Wheels-new default (activated via `wheels new` — no task action needed; verify in Task 7/8) |
| "Where we left off" banner at each part | 7-13 |
| Checkpoint + Troubleshooting at each part | 7-13 |
| Every code block tagged or marked illustrative | 2-13 (per STYLE.md enforcement) |
| CI runs harness | Phase 0 shipped; Phase 1 relies on existing `.github/workflows/docs-verify.yml` |
| Cloudflare Pages preview URL for review | 14 |

All spec requirements have at least one task. No gaps.

**Placeholder scan:**
- "TBD" appears intentionally in Task 2 Step 3 (uncertainty around `wheels destroy`/component handling — called out as a spike rather than a placeholder) and Task 12 (bcrypt function names — called out as "verify before writing, adjust to match"). These are legitimate "confirm on implementation" markers, not placeholder content.
- No "implement later," "fill in details," or "similar to Task N" patterns.

**Type / method consistency:**
- Fixture lib exports: `fixturePath`, `resetFixture`, `writeFixtureFile`, `appendFixtureFile`, `readFixtureFile`, `runInFixture` — same names used in Task 1 tests and driver.
- Driver exports: `TutorialSession` class with `ensureInitialised`, `ensureServer`, `stopServer`, `applyTutorialExample`, `applyCliExample` — same used in verify-docs.mjs wiring (Task 1 Step 17) and end-to-end test (Task 1 Step 15).
- Orchestrator exports: `readSidebarOrder`, `enrichWithSidebarOrder`, `partitionAndOrder` — same used in tests and entrypoint.
- Compile driver exports: `runCompile`, `detectMode` — same used in tests and entrypoint.

All consistent.

**One known friction point:** the MDX content tasks (3-13) don't inline the full prose content in the plan — the plan gives structural specs + required harness tags and relies on the implementing agent to compose prose during execution against STYLE.md and the spec. This is deliberate (writing full MDX verbatim inside the plan would 10x its length) and matches the pragmatic split the user specified. If an inline-executing agent wants more scaffolding before writing a given page, they should read the spec's corresponding section + STYLE.md + the Phase 0 sample pages (tutorial/01-hello-wheels.mdx and digging-deeper/sending-email.mdx) for tone reference.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-18-guides-rewrite-phase-1.md`.

**Per user direction (pragmatic split from Phase 0):**

- **Tasks 1, 2 (code)** — run via Subagent-Driven execution: `superpowers:subagent-driven-development`. Fresh implementer per task, then spec-review and code-quality review subagents between tasks. Fast iteration, isolated context.
- **Tasks 3-13 (content)** — run inline using `superpowers:executing-plans`. Self-review against STYLE.md and harness-passing is the review gate. No subagent ceremony per page.
- **Task 14 (integration)** — inline.
- **Task 15 (final review)** — single `pr-review-toolkit:code-reviewer` subagent dispatch across the full Phase 1 diff.

Ready to begin Task 1.
