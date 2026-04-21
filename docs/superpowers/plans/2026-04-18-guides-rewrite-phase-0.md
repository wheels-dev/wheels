# Guides Rewrite — Phase 0 (Foundations) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the foundations for the Wheels 4.0 guides rewrite: sidebar scaffold with placeholder pages, writing style guide, doctest harness (compile + CLI drivers), four sample pages (one per Diátaxis type), and CI wiring. No tutorial content yet — that lands in Phase 1.

**Architecture:** Authored MDX lives directly at `web/sites/guides/src/content/docs/v4-0-0-snapshot/` (bypassing `generate-guides.mjs` for v4). A Node.js harness under `web/sites/guides/scripts/verify-docs/` walks MDX files, extracts fenced code blocks with `{test:*}` metadata, and validates them by invoking the `wheels` CLI via `spawn()` with an args array (no shell). Output is a pass/fail report with line-precise failure messages. CI runs the harness on every PR touching the guides.

**Tech Stack:**
- Astro 5 + Starlight 0.34 (existing)
- Node 22+ (existing, from `web/package.json` engines)
- pnpm 10.23 (existing)
- Node's built-in `node:test` runner (no new test framework)
- `wheels` CLI (must be installed locally; CI installs it)
- Regex-based MDX parsing for Phase 0 (good enough; upgrade to `@mdx-js/mdx` later if needed)

**Spec:** [docs/superpowers/specs/2026-04-18-guides-rewrite-v4-design.md](../specs/2026-04-18-guides-rewrite-v4-design.md)

**Security note:** The harness never invokes a shell. All process launches use `spawn(program, args, opts)` where `program` and `args` are parsed out of metadata — no `sh -c`, no template-string concatenation. Commands in `{test:cli cmd="..."}` are whitespace-tokenized; authors who need shell features (pipes, `&&`, redirects) must write an equivalent without them or mark the block illustrative.

---

## File Structure

### Content (under `web/sites/guides/src/content/docs/v4-0-0-snapshot/`)

```
v4-0-0-snapshot/
├── index.mdx
├── start-here/
│   ├── index.mdx
│   ├── welcome.mdx
│   ├── why-wheels.mdx
│   ├── installing.mdx
│   ├── first-15-minutes.mdx
│   └── tutorial/
│       ├── index.mdx
│       └── 01-hello-wheels.mdx              # SAMPLE page
├── core-concepts/
│   ├── index.mdx
│   └── request-lifecycle.mdx                # SAMPLE page
├── basics/index.mdx
├── digging-deeper/
│   ├── index.mdx
│   └── sending-email.mdx                    # SAMPLE page
├── testing/index.mdx
├── deployment/index.mdx
├── cli-reference/
│   ├── index.mdx
│   └── dbmigrate-latest.mdx                 # SAMPLE page
├── contributing/index.mdx
├── upgrading/index.mdx
└── glossary.mdx
```

### Sidebar, style guide, harness

```
web/sites/guides/
├── STYLE.md
├── src/sidebars/v4-0-0-snapshot.json        # hand-authored
└── scripts/verify-docs/
    ├── verify-docs.mjs                      # entrypoint
    ├── VALIDATION.md                        # metadata reference
    ├── lib/
    │   ├── extract.mjs                      # MDX walker
    │   ├── report.mjs                       # pretty-printer
    │   ├── fixtures.mjs                     # fresh-app creator
    │   └── exec.mjs                         # safe spawn wrapper
    ├── drivers/
    │   ├── compile.mjs                      # {test:compile}
    │   └── cli.mjs                          # {test:cli}
    └── test/                                # node:test suites
```

### CI

- `.github/workflows/docs-verify.yml` — runs on PRs touching `web/sites/guides/` or the harness.

### Deletions in Phase 0

- `web/sites/guides/src/content/docs/v4-0-0-snapshot/` — prior auto-generated output from `generate-guides.mjs`, wiped and rebuilt.
- `web/sites/guides/src/sidebars/v4-0-0-snapshot.json` — prior auto-generated sidebar replaced with hand-authored version.

---

## Conventions used in this plan

- Every code change is followed by a verification step (run dev server, run tests, or build) and a commit.
- Every new test uses Node's built-in `node:test` runner and `node:assert/strict`.
- Commit messages follow the repo's commitlint scopes. Docs work uses `docs(docs): ...`. Tooling/config work uses `chore(config): ...`. Per the repo CLAUDE.md: `security` is NOT a valid scope; use the layer it touches.
- All paths are relative to the repo root unless noted.
- When a step says "run dev server," the worker keeps it in the background and hits it with `curl`, not a browser.

---

## Task 1: Clear stale v4 content

**Files:**
- Delete: `web/sites/guides/src/content/docs/v4-0-0-snapshot/`
- Delete: `web/sites/guides/src/sidebars/v4-0-0-snapshot.json`

The existing v4-0-0-snapshot directory contains auto-generated content from a prior run of `generate-guides.mjs docs/src v4-0-0-snapshot`. We are replacing it with hand-authored MDX.

- [ ] **Step 1: Confirm the content is generated, not hand-edited**

Run:
```bash
git log --oneline -- web/sites/guides/src/content/docs/v4-0-0-snapshot/ | head -5
```

Expected: recent commits show `generate-guides.mjs` or "regenerate" in the message. Confirms we're not throwing away hand edits.

- [ ] **Step 2: Delete the directory and sidebar**

```bash
rm -rf web/sites/guides/src/content/docs/v4-0-0-snapshot/
rm -f web/sites/guides/src/sidebars/v4-0-0-snapshot.json
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "$(cat <<'EOF'
docs(docs): clear auto-generated v4-0-0-snapshot for hand-authored rewrite

Replaces the generate-guides.mjs output with hand-authored MDX per the
v4 guides rewrite spec.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Scaffold the v4 directory + sidebar with placeholders

**Files:** all under `web/sites/guides/src/content/docs/v4-0-0-snapshot/` plus the sidebar JSON. See File Structure above for the exact tree.

- [ ] **Step 1: Create the v4 landing `index.mdx`**

Write `web/sites/guides/src/content/docs/v4-0-0-snapshot/index.mdx`:

```mdx
---
title: Wheels 4.0
description: The official guides for Wheels 4.0, a CFML web framework that gets out of your way.
type: landing
---

Welcome to Wheels 4.0. These guides teach you the framework from zero — including CFML itself if you're new to the language.

**New here?** Start with [Welcome to Wheels](/v4-0-0-snapshot/start-here/welcome/).

**Coming from 3.x?** Read the [Upgrading to 4.0](/v4-0-0-snapshot/upgrading/) guide first.
```

- [ ] **Step 2: Create the Start Here section and its placeholders**

Write `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/index.mdx`:

```mdx
---
title: Start Here
description: Install Wheels, learn the basics, build your first app.
type: section
sidebar:
  order: 1
---

import { CardGrid, LinkCard } from '@astrojs/starlight/components';

The entry path for new Wheels developers. Follow it top to bottom.

<CardGrid>
  <LinkCard title="Welcome to Wheels" href="/v4-0-0-snapshot/start-here/welcome/" />
  <LinkCard title="Why Wheels?" href="/v4-0-0-snapshot/start-here/why-wheels/" />
  <LinkCard title="Installing Wheels" href="/v4-0-0-snapshot/start-here/installing/" />
  <LinkCard title="Your First 15 Minutes" href="/v4-0-0-snapshot/start-here/first-15-minutes/" />
  <LinkCard title="Tutorial: Build a Blog" href="/v4-0-0-snapshot/start-here/tutorial/" />
</CardGrid>
```

Write each of the following four placeholders with the shown frontmatter and a body of `Placeholder — content lands in Phase 1.`:

- `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/welcome.mdx`
  ```yaml
  title: Welcome to Wheels
  description: What Wheels is, who it's for, and how these guides are organized.
  type: concept
  sidebar: { order: 1 }
  ```
- `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/why-wheels.mdx`
  ```yaml
  title: Why Wheels?
  description: How Wheels compares to Rails, Laravel, and Django, and when to reach for it.
  type: concept
  sidebar: { order: 2 }
  ```
- `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/installing.mdx`
  ```yaml
  title: Installing Wheels
  description: Install the Wheels CLI on macOS, Windows, or Linux.
  type: howto
  sidebar: { order: 3 }
  ```
- `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/first-15-minutes.mdx`
  ```yaml
  title: Your First 15 Minutes
  description: A skim-level walkthrough that gets something running fast, before any concepts.
  type: tutorial
  sidebar: { order: 4 }
  ```

Write `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/index.mdx`:

```mdx
---
title: "Tutorial: Build a Blog"
description: A seven-part tutorial that builds a real Wheels 4.0 app end to end.
type: tutorial
sidebar:
  order: 5
---

Placeholder — Parts 2–7 land in Phase 1. [Part 1 is available now.](/v4-0-0-snapshot/start-here/tutorial/01-hello-wheels/)
```

- [ ] **Step 3: Create the remaining section indexes**

For each of the following, create an `index.mdx` with the shown frontmatter and a body of `Placeholder — content lands in Phase 2.`:

| Path | title | description | type | order |
|---|---|---|---|---|
| `core-concepts/index.mdx` | Core Concepts | The mental model behind Wheels — request lifecycle, MVC, conventions, ORM, DI, middleware, routing, environments. | section | 2 |
| `basics/index.mdx` | The Basics | Task-oriented guides for routing, controllers, views, forms, validation, models, associations, migrations, seeding, and the query builder. | section | 3 |
| `digging-deeper/index.mdx` | Digging Deeper | Advanced features — auth, jobs, caching, mail, uploads, SSE, i18n, multi-tenancy, packages. | section | 4 |
| `testing/index.mdx` | Testing | How to write unit, functional, and browser tests for Wheels apps. | section | 5 |
| `deployment/index.mdx` | Deployment & Operations | Ship a Wheels app to production. | section | 6 |
| `cli-reference/index.mdx` | CLI Reference | Every command in the Wheels CLI, organized by use case. | section | 7 |
| `contributing/index.mdx` | Contributing & Project | How to contribute code, docs, and packages to Wheels. | section | 8 |
| `upgrading/index.mdx` | Upgrading | Upgrade guides for each Wheels release. | section | 9 |

And `glossary.mdx` (flat file, not a directory):

```mdx
---
title: Glossary
description: Wheels terminology, one-line definitions.
type: reference
sidebar:
  order: 10
---

Placeholder — content lands in Phase 2.
```

- [ ] **Step 4: Create the hand-authored sidebar JSON**

Write `web/sites/guides/src/sidebars/v4-0-0-snapshot.json`:

```json
[
  {
    "label": "Start Here",
    "link": "/v4-0-0-snapshot/start-here/",
    "items": [
      { "label": "Welcome to Wheels", "link": "/v4-0-0-snapshot/start-here/welcome/" },
      { "label": "Why Wheels?", "link": "/v4-0-0-snapshot/start-here/why-wheels/" },
      { "label": "Installing Wheels", "link": "/v4-0-0-snapshot/start-here/installing/" },
      { "label": "Your First 15 Minutes", "link": "/v4-0-0-snapshot/start-here/first-15-minutes/" },
      {
        "label": "Tutorial: Build a Blog",
        "link": "/v4-0-0-snapshot/start-here/tutorial/",
        "items": [
          { "label": "1. Hello, Wheels", "link": "/v4-0-0-snapshot/start-here/tutorial/01-hello-wheels/" }
        ]
      }
    ]
  },
  {
    "label": "Core Concepts",
    "link": "/v4-0-0-snapshot/core-concepts/",
    "items": [
      { "label": "The Request Lifecycle", "link": "/v4-0-0-snapshot/core-concepts/request-lifecycle/" }
    ]
  },
  {
    "label": "The Basics",
    "link": "/v4-0-0-snapshot/basics/",
    "items": []
  },
  {
    "label": "Digging Deeper",
    "link": "/v4-0-0-snapshot/digging-deeper/",
    "items": [
      { "label": "Sending Email", "link": "/v4-0-0-snapshot/digging-deeper/sending-email/" }
    ]
  },
  {
    "label": "Testing",
    "link": "/v4-0-0-snapshot/testing/",
    "items": []
  },
  {
    "label": "Deployment & Operations",
    "link": "/v4-0-0-snapshot/deployment/",
    "items": []
  },
  {
    "label": "CLI Reference",
    "link": "/v4-0-0-snapshot/cli-reference/",
    "items": [
      { "label": "wheels dbmigrate latest", "link": "/v4-0-0-snapshot/cli-reference/dbmigrate-latest/" }
    ]
  },
  {
    "label": "Contributing & Project",
    "link": "/v4-0-0-snapshot/contributing/",
    "items": []
  },
  {
    "label": "Upgrading",
    "link": "/v4-0-0-snapshot/upgrading/",
    "items": []
  },
  {
    "label": "Glossary",
    "link": "/v4-0-0-snapshot/glossary/"
  }
]
```

The sidebar references the four Phase 0 sample pages, created in Tasks 9–12. The astro build will fail until those pages exist — that's expected. We verify the build at the end of Task 13.

- [ ] **Step 5: Commit the scaffold**

```bash
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/ \
        web/sites/guides/src/sidebars/v4-0-0-snapshot.json
git commit -m "$(cat <<'EOF'
docs(docs): scaffold v4 guides directory + hand-authored sidebar

New IA per the v4 guides rewrite spec: Start Here / Core Concepts /
The Basics / Digging Deeper / Testing / Deployment / CLI Reference /
Contributing / Upgrading / Glossary. All placeholders; real content
arrives in Phase 1 (tutorial) and Phase 2 (everything else).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Write the style guide

**Files:**
- Create: `web/sites/guides/STYLE.md`

- [ ] **Step 1: Write the style guide**

Write `web/sites/guides/STYLE.md`:

```markdown
# Wheels Guides — Writing Style Guide

Governs every page in `src/content/docs/v4-0-0-snapshot/`. Contributors writing or reviewing docs treat it as enforceable.

## Voice & tone

- Second person ("you"), active voice. Never "we" except tutorial welcomes.
- No marketing copy ("powerful," "robust," "effortless"). Describe what the feature does.
- Short sentences. Split two-idea sentences.
- Assume the reader is smart and busy.

## Audience assumptions

Every non-intro page declares assumptions in a "You should already know" `<Aside>` when relevant.

- **Tutorial:** zero Wheels, zero CFML, some programming.
- **Core Concepts:** finished tutorial or equivalent.
- **How-tos:** finished tutorial; may require specific concept section.
- **Reference:** familiarity with the feature; no teaching.

## Code examples

- Complete and runnable wherever possible. Show context even if it's 10 extra lines.
- Real names (`Post`, `user.email`, `publishedAt`), not `foo`/`bar`/`someField`.
- Every code block declares its file path: ` ```cfm title="app/controllers/Posts.cfc" `.
- No placeholder comments like `// your code here`. Show the code or remove the block.
- Every non-illustrative block is tagged for the verify-docs harness (`{test:compile}`, `{test:cli}`, or `{test:tutorial}`). See `scripts/verify-docs/VALIDATION.md`.
- Illustrative blocks that cannot compile: ` ```cfm title="illustrative — do not type" `.

## Page structure

- Every page opens with a 1-sentence summary + 3-line "You'll learn" list.
- Tutorials end with "Checkpoint" and "Troubleshooting" (three common failure modes).
- How-tos end with "Related guides" `<CardGrid>`.
- Concepts end with "See also" link block.
- Reference pages: tables, lists, parameters — no narrative.

## Vocabulary

- "Wheels," never "CFWheels."
- "the `wheels` CLI," never "LuCLI" in user-facing docs. LuCLI appears only in contributor/internal docs.
- "migration," not "db migration." "Model," not "ORM model."
- Function names in code voice: `findAll()`, `hasMany()`. Concept in prose voice: "finders," "associations."

## Diátaxis purity

Every page frontmatter carries `type: tutorial | howto | concept | reference`. A future Vale rule rejects mixed types.

- **Tutorial** — learning-oriented. Hand-held. You build something.
- **How-to** — task-oriented. "How to X." You already know what you want.
- **Concept** — understanding-oriented. "Why Wheels does X." No commands, no steps.
- **Reference** — information-oriented. Dry. Tables and lists.

## Linking discipline

- Internal links relative to site root: `/v4-0-0-snapshot/core-concepts/request-lifecycle/`.
- External links checked by the link checker in CI.
- Every CLI command links to its reference page the first time it appears in a page.

## Starlight components to prefer

- `<Aside type="note|tip|caution|danger">` for callouts — not blockquotes.
- `<Tabs>` for OS-specific or engine-specific variations.
- `<Steps>` for numbered procedural lists.
- `<Card>` / `<CardGrid>` / `<LinkCard>` for "what to read next" blocks.
- `<FileTree>` for project structure diagrams.

## What we don't write

- No emojis.
- No "Note:" or "Important:" prefixed paragraphs — use `<Aside>`.
- No headings deeper than `###`. If a page needs `####`, split it.
- No tables of contents at the top — Starlight renders one on the right.
```

- [ ] **Step 2: Commit**

```bash
git add web/sites/guides/STYLE.md
git commit -m "$(cat <<'EOF'
docs(docs): add writing style guide for v4 guides

Governs voice, tone, code examples, page structure, vocabulary,
Diátaxis typing, and Starlight component usage.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Harness skeleton + VALIDATION.md + safe exec wrapper

**Files:**
- Create: `web/sites/guides/scripts/verify-docs/verify-docs.mjs`
- Create: `web/sites/guides/scripts/verify-docs/lib/extract.mjs`
- Create: `web/sites/guides/scripts/verify-docs/lib/report.mjs`
- Create: `web/sites/guides/scripts/verify-docs/lib/fixtures.mjs`
- Create: `web/sites/guides/scripts/verify-docs/lib/exec.mjs`
- Create: `web/sites/guides/scripts/verify-docs/drivers/compile.mjs`
- Create: `web/sites/guides/scripts/verify-docs/drivers/cli.mjs`
- Create: `web/sites/guides/scripts/verify-docs/VALIDATION.md`
- Modify: `web/sites/guides/package.json`

- [ ] **Step 1: Create the safe exec wrapper** — central choke point for process launches; no shell ever.

Write `web/sites/guides/scripts/verify-docs/lib/exec.mjs`:

```js
import { spawn } from 'node:child_process';

/**
 * Launches `program` with the given argv array. Never invokes a shell.
 * Returns `{ code, stdout, stderr }`. `code` is the process exit code, or -1
 * on spawn error (stderr will contain the Node error message in that case).
 *
 * Why no shell: the harness runs command strings pulled from MDX metadata.
 * Using `sh -c` would be a shell-injection surface. All callers must
 * pre-tokenize into program + args.
 */
export function runExec(program, args = [], opts = {}) {
  return new Promise((resolve) => {
    const proc = spawn(program, args, { ...opts, stdio: ['ignore', 'pipe', 'pipe'] });
    let stdout = '';
    let stderr = '';
    proc.stdout.on('data', (d) => (stdout += d.toString()));
    proc.stderr.on('data', (d) => (stderr += d.toString()));
    proc.on('error', (err) => resolve({ code: -1, stdout, stderr: stderr + err.message }));
    proc.on('close', (code) => resolve({ code, stdout, stderr }));
  });
}

/**
 * Whitespace-tokenizes a command string into [program, ...args].
 * Phase 0 does not support quoted arguments or shell features. Authors
 * who need those must restructure the command or mark it illustrative.
 */
export function tokenize(command) {
  const parts = command.trim().split(/\s+/);
  if (parts.length === 0 || parts[0] === '') {
    throw new Error('empty command');
  }
  return parts;
}
```

- [ ] **Step 2: Create empty module stubs for the rest**

Write `web/sites/guides/scripts/verify-docs/lib/extract.mjs`:

```js
export async function extractExamples(files) {
  throw new Error('not implemented — see Task 5');
}
```

Write `web/sites/guides/scripts/verify-docs/lib/report.mjs`:

```js
export function printReport(results) {
  throw new Error('not implemented — see Task 8');
}
```

Write `web/sites/guides/scripts/verify-docs/lib/fixtures.mjs`:

```js
export async function createFixture(name) {
  throw new Error('not implemented — see Task 7');
}

export async function destroyFixture(fixturePath) {
  throw new Error('not implemented — see Task 7');
}
```

Write `web/sites/guides/scripts/verify-docs/drivers/compile.mjs`:

```js
export async function runCompile(example) {
  throw new Error('not implemented — see Task 6');
}
```

Write `web/sites/guides/scripts/verify-docs/drivers/cli.mjs`:

```js
export async function runCli(example) {
  throw new Error('not implemented — see Task 7');
}
```

Write `web/sites/guides/scripts/verify-docs/verify-docs.mjs`:

```js
#!/usr/bin/env node
/**
 * Entrypoint for `pnpm verify:docs`. Stub — real orchestrator lands in Task 8.
 */
console.log('verify-docs: not implemented yet — see Task 8');
process.exit(1);
```

- [ ] **Step 3: Create VALIDATION.md**

Write `web/sites/guides/scripts/verify-docs/VALIDATION.md`:

````markdown
# verify-docs — Metadata Reference

Every non-illustrative code block in the v4 guides carries a `{test:*}` meta
string the harness uses to validate it. Three flavors.

## `{test:compile}`

The block is written to a temp file and compiled against Lucee 7 via the
`wheels` CLI. Pass if compilation succeeds.

```cfm {test:compile}
component extends="Model" {
  function config() {
    validatesPresenceOf("title");
  }
}
```

## `{test:cli cmd="..."}`

The `cmd` is tokenized on whitespace and executed in a fresh fixture app.
Optional attrs:

- `asserts-stdout="text"` — stdout must contain `text`.
- `asserts-exit=N` — process must exit with code `N` (default 0).
- `step=N` — cumulative ordering within a file.

```bash {test:cli cmd="wheels dbmigrate latest" asserts-stdout="Migrating up"}
wheels dbmigrate latest
```

**Shell features not supported.** No pipes, redirects, `&&`, or quoted args
with spaces. The harness spawns the program directly. Authors who need
shell features must restructure the example or mark it illustrative.

## `{test:tutorial step=N file="path"}` — lands in Phase 1

Contents of the block are written to `file` inside the tutorial's fixture
app at step N. Follow-up CLI commands (`{test:cli step=N}`) see this state.
Phase 0 does not implement this driver; documented here so Phase 0 sample
content can forward-reference it.

## Shared attrs

- `step=N` — cumulative state ordering. Lower N runs first.
- `title="..."` — consumed by Starlight for code-block titles; ignored by the harness.

## Illustrative blocks

Blocks that cannot or should not compile:

```cfm title="illustrative — do not type"
someAPI.callThat.doesntExistYet();
```

The harness ignores blocks without a `{test:*}` meta flag.
````

- [ ] **Step 4: Add scripts to `web/sites/guides/package.json`**

Current `scripts` section:

```json
"scripts": {
  "dev": "astro dev --port 4323",
  "build": "astro build",
  "preview": "astro preview",
  "check": "astro check"
}
```

Replace with:

```json
"scripts": {
  "dev": "astro dev --port 4323",
  "build": "astro build",
  "preview": "astro preview",
  "check": "astro check",
  "verify:docs": "node scripts/verify-docs/verify-docs.mjs",
  "test:docs-harness": "node --test scripts/verify-docs/test/"
}
```

- [ ] **Step 5: Smoke-test the stubs**

```bash
cd web/sites/guides
pnpm verify:docs
```

Expected stdout (last line): `verify-docs: not implemented yet — see Task 8`
Expected exit code: 1

- [ ] **Step 6: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/youthful-montalcini-6ea95c
git add web/sites/guides/scripts/verify-docs/ web/sites/guides/package.json
git commit -m "$(cat <<'EOF'
chore(docs): scaffold verify-docs harness + VALIDATION reference

Empty stubs + safe exec wrapper (spawn-only, never sh -c). Behavior
lands in follow-up tasks: extract (T5), compile (T6), cli (T7),
orchestrator (T8).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Implement extract.mjs (MDX walker) with tests

**Files:**
- Modify: `web/sites/guides/scripts/verify-docs/lib/extract.mjs`
- Create: `web/sites/guides/scripts/verify-docs/test/extract.test.mjs`
- Create: `web/sites/guides/scripts/verify-docs/test/fixtures/sample.mdx`

Regex-based. Upgrade later if we hit edge cases.

- [ ] **Step 1: Write a fixture MDX file**

Write `web/sites/guides/scripts/verify-docs/test/fixtures/sample.mdx`:

````mdx
---
title: Sample page
---

Sample page with tagged code blocks.

```cfm {test:compile}
component extends="Model" {}
```

An illustrative block that should be ignored:

```cfm title="illustrative"
someAPI.that.doesntExist();
```

A CLI block with asserts:

```bash {test:cli cmd="wheels --version" asserts-stdout="Wheels"}
wheels --version
```

A tutorial-tagged block (Phase 1 driver; extract still recognizes it):

```cfm {test:tutorial step=1 file="app/models/Post.cfc"}
component extends="Model" {
  function config() {
    validatesPresenceOf("title");
  }
}
```
````

- [ ] **Step 2: Write the failing tests**

Write `web/sites/guides/scripts/verify-docs/test/extract.test.mjs`:

```js
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
```

- [ ] **Step 3: Run tests — expect fail**

```bash
cd web/sites/guides
pnpm test:docs-harness
```

Expected: all five tests fail with `not implemented — see Task 5`.

- [ ] **Step 4: Implement extract.mjs**

Replace `web/sites/guides/scripts/verify-docs/lib/extract.mjs`:

```js
import { readFile } from 'node:fs/promises';

const FENCE_RE = /^```(\w+)([^\n]*)\n([\s\S]*?)\n```$/gm;

function parseMeta(meta) {
  const m = meta.match(/\{test:(\w+)\s*([^}]*)\}/);
  if (!m) return null;
  const kind = m[1];
  const rest = m[2].trim();
  const attrs = {};
  const ATTR_RE = /(\w[\w-]*)=(?:"([^"]*)"|(\S+))/g;
  let am;
  while ((am = ATTR_RE.exec(rest)) !== null) {
    attrs[am[1]] = am[2] !== undefined ? am[2] : am[3];
  }
  return { kind, attrs };
}

function lineAt(content, offset) {
  let line = 1;
  for (let i = 0; i < offset && i < content.length; i++) {
    if (content.charCodeAt(i) === 10) line++;
  }
  return line;
}

export async function extractExamples(files) {
  const out = [];
  for (const file of files) {
    const content = await readFile(file, 'utf8');
    FENCE_RE.lastIndex = 0;
    let m;
    while ((m = FENCE_RE.exec(content)) !== null) {
      const [, language, meta, body] = m;
      const parsed = parseMeta(meta);
      if (!parsed) continue;
      out.push({
        file,
        line: lineAt(content, m.index),
        language,
        kind: parsed.kind,
        attrs: parsed.attrs,
        body,
      });
    }
  }
  return out;
}
```

- [ ] **Step 5: Run tests — expect pass**

```bash
pnpm test:docs-harness
```

Expected: all five tests pass.

- [ ] **Step 6: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/youthful-montalcini-6ea95c
git add web/sites/guides/scripts/verify-docs/lib/extract.mjs \
        web/sites/guides/scripts/verify-docs/test/
git commit -m "$(cat <<'EOF'
chore(docs): implement extract.mjs MDX walker

Regex-based extraction of fenced code blocks with {test:*} metadata.
Records source file + line for failure reporting. Tests cover
compile, cli, tutorial kinds and attribute parsing.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Implement compile driver with tests

**Files:**
- Modify: `web/sites/guides/scripts/verify-docs/drivers/compile.mjs`
- Create: `web/sites/guides/scripts/verify-docs/test/compile.test.mjs`

- [ ] **Step 1: Discover the CFML syntax-check command**

Run:
```bash
wheels --help | grep -iE 'check|compile|parse|lint' || true
wheels check --help 2>&1 | head -20 || true
```

Expected: identify the right subcommand. The plan assumes `wheels check <file>` exists. If not, common fallbacks to try: `wheels lint`, or `wheels doctor <file>`. Document the chosen command in the commit message. If absolutely no syntax-check command exists, file an issue against the CLI and adapt `compile.mjs` to write the snippet into a fixture's `app/` folder and then run `wheels reload` to force a compile error to surface.

- [ ] **Step 2: Write the failing tests**

Write `web/sites/guides/scripts/verify-docs/test/compile.test.mjs`:

```js
import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { runCompile } from '../drivers/compile.mjs';

const TIMEOUT = 60_000;

test('runCompile returns ok=true for valid CFC', { timeout: TIMEOUT }, async () => {
  const result = await runCompile({
    file: 'test:inline', line: 1, language: 'cfm', kind: 'compile', attrs: {},
    body: 'component {\n  function hello() { return "world"; }\n}',
  });
  assert.equal(result.ok, true, `compile failed: ${result.message ?? ''}`);
});

test('runCompile returns ok=false for syntax error', { timeout: TIMEOUT }, async () => {
  const result = await runCompile({
    file: 'test:inline', line: 1, language: 'cfm', kind: 'compile', attrs: {},
    body: 'component { function hello() { return "world"; ', // missing brace
  });
  assert.equal(result.ok, false);
  assert.ok(result.message && result.message.length > 0);
});

test('runCompile returns ok=true for CFM script', { timeout: TIMEOUT }, async () => {
  const result = await runCompile({
    file: 'test:inline', line: 1, language: 'cfm', kind: 'compile', attrs: {},
    body: '<cfset x = 1 />',
  });
  assert.equal(result.ok, true);
});
```

- [ ] **Step 3: Run tests — expect fail**

```bash
pnpm test:docs-harness
```

Expected: three new tests fail with `not implemented — see Task 6`.

- [ ] **Step 4: Implement compile.mjs**

Replace `web/sites/guides/scripts/verify-docs/drivers/compile.mjs`:

```js
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { runExec } from '../lib/exec.mjs';

function inferExtension(body) {
  const trimmed = body.trimStart();
  if (/^component(\s|\{)/.test(trimmed) || /^interface(\s|\{)/.test(trimmed)) return 'cfc';
  return 'cfm';
}

/**
 * Compiles a single fenced code block by writing it to a temp file and
 * invoking `wheels check <file>` (or the subcommand identified in Task 6
 * Step 1). Returns `{ ok: true }` on success, `{ ok: false, message }` on
 * syntax error.
 */
export async function runCompile(example) {
  const ext = inferExtension(example.body);
  const dir = await mkdtemp(join(tmpdir(), 'wheels-doctest-'));
  const path = join(dir, `snippet.${ext}`);
  try {
    await writeFile(path, example.body, 'utf8');
    const result = await runExec('wheels', ['check', path]);
    if (result.code === 0) return { ok: true };
    return {
      ok: false,
      message: (result.stderr || result.stdout || `exit ${result.code}`).trim(),
    };
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}
```

If Step 1 identified a different subcommand, swap `['check', path]` for the right argv — everything else stays the same.

- [ ] **Step 5: Run tests — expect pass**

```bash
pnpm test:docs-harness
```

Expected: all extract + compile tests pass.

- [ ] **Step 6: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/youthful-montalcini-6ea95c
git add web/sites/guides/scripts/verify-docs/drivers/compile.mjs \
        web/sites/guides/scripts/verify-docs/test/compile.test.mjs
git commit -m "$(cat <<'EOF'
chore(docs): implement compile driver for verify-docs

Runs `wheels check <tempfile>` to validate CFML syntax. Handles both
CFC and CFM-script bodies via extension inference. Tests cover
valid CFC, syntax error, and CFM-script cases.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Implement fixtures + cli driver with tests

**Files:**
- Modify: `web/sites/guides/scripts/verify-docs/lib/fixtures.mjs`
- Modify: `web/sites/guides/scripts/verify-docs/drivers/cli.mjs`
- Create: `web/sites/guides/scripts/verify-docs/test/cli.test.mjs`

- [ ] **Step 1: Discover how to create a fresh app non-interactively**

Run:
```bash
wheels new --help
```

Identify flags for: app name, database (SQLite preferred), skip-git, silence interactive prompts. The plan's placeholder is `wheels new <name> --db=sqlite --skip-git --quiet`. If flag names differ, adjust `createFixture()` accordingly.

- [ ] **Step 2: Implement fixtures.mjs**

Replace `web/sites/guides/scripts/verify-docs/lib/fixtures.mjs`:

```js
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { runExec } from './exec.mjs';

/**
 * Creates a fresh SQLite-backed Wheels app in a tmp directory.
 * Returns the absolute path to the app root.
 */
export async function createFixture(name = 'fixture') {
  const parent = await mkdtemp(join(tmpdir(), 'wheels-doctest-'));
  const result = await runExec(
    'wheels',
    ['new', name, '--db=sqlite', '--skip-git', '--quiet'],
    { cwd: parent },
  );
  if (result.code !== 0) {
    throw new Error(`wheels new failed (exit ${result.code}):\n${result.stderr || result.stdout}`);
  }
  return join(parent, name);
}

export async function destroyFixture(fixturePath) {
  const parent = join(fixturePath, '..');
  await rm(parent, { recursive: true, force: true });
}
```

- [ ] **Step 3: Implement cli.mjs**

Replace `web/sites/guides/scripts/verify-docs/drivers/cli.mjs`:

```js
import { runExec, tokenize } from '../lib/exec.mjs';
import { createFixture, destroyFixture } from '../lib/fixtures.mjs';

/**
 * Runs a `wheels` command in a fresh fixture app and asserts stdout + exit.
 *
 * attrs:
 *   cmd              — command string, whitespace-tokenized (required)
 *   asserts-stdout   — substring that must appear in stdout (optional)
 *   asserts-exit     — expected exit code (default 0)
 */
export async function runCli(example) {
  const cmd = example.attrs.cmd;
  if (!cmd) return { ok: false, message: 'missing required attr: cmd' };

  const expectedExit = example.attrs['asserts-exit'] !== undefined
    ? Number(example.attrs['asserts-exit'])
    : 0;
  const expectedStdout = example.attrs['asserts-stdout'];

  let tokens;
  try {
    tokens = tokenize(cmd);
  } catch (err) {
    return { ok: false, message: `tokenize failed: ${err.message}` };
  }
  const [program, ...args] = tokens;

  const fixture = await createFixture();
  try {
    const result = await runExec(program, args, { cwd: fixture });
    if (result.code !== expectedExit) {
      return {
        ok: false,
        message: `expected exit ${expectedExit}, got ${result.code}\n--- stdout ---\n${result.stdout}\n--- stderr ---\n${result.stderr}`,
      };
    }
    if (expectedStdout !== undefined && !result.stdout.includes(expectedStdout)) {
      return {
        ok: false,
        message: `stdout missing expected text "${expectedStdout}"\n--- stdout ---\n${result.stdout}`,
      };
    }
    return { ok: true };
  } finally {
    await destroyFixture(fixture);
  }
}
```

- [ ] **Step 4: Write cli driver tests**

Write `web/sites/guides/scripts/verify-docs/test/cli.test.mjs`:

```js
import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { runCli } from '../drivers/cli.mjs';

const TIMEOUT = 120_000;

test('runCli succeeds for wheels --version', { timeout: TIMEOUT }, async () => {
  const result = await runCli({
    file: 'test:inline', line: 1, language: 'bash', kind: 'cli',
    attrs: { cmd: 'wheels --version' }, body: '',
  });
  assert.equal(result.ok, true, `cli failed: ${result.message ?? ''}`);
});

test('runCli honors asserts-stdout', { timeout: TIMEOUT }, async () => {
  const result = await runCli({
    file: 'test:inline', line: 1, language: 'bash', kind: 'cli',
    attrs: { cmd: 'wheels --version', 'asserts-stdout': 'Wheels' }, body: '',
  });
  assert.equal(result.ok, true, `cli failed: ${result.message ?? ''}`);
});

test('runCli fails when asserts-stdout is missing', { timeout: TIMEOUT }, async () => {
  const result = await runCli({
    file: 'test:inline', line: 1, language: 'bash', kind: 'cli',
    attrs: { cmd: 'wheels --version', 'asserts-stdout': 'NotARealString_12345' }, body: '',
  });
  assert.equal(result.ok, false);
  assert.match(result.message, /missing expected text/);
});

test('runCli reports missing cmd attr', async () => {
  const result = await runCli({
    file: 'test:inline', line: 1, language: 'bash', kind: 'cli',
    attrs: {}, body: '',
  });
  assert.equal(result.ok, false);
  assert.match(result.message, /missing required attr: cmd/);
});
```

- [ ] **Step 5: Run tests — expect pass**

```bash
pnpm test:docs-harness
```

Expected: all extract + compile + cli tests pass. Total runtime 1–2 minutes (CLI tests actually spin up fixtures).

If `wheels new` flags differ from what `createFixture()` assumes, cli tests fail with a fixture error. Adjust flags based on `wheels new --help` output, re-run.

- [ ] **Step 6: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/youthful-montalcini-6ea95c
git add web/sites/guides/scripts/verify-docs/lib/fixtures.mjs \
        web/sites/guides/scripts/verify-docs/drivers/cli.mjs \
        web/sites/guides/scripts/verify-docs/test/cli.test.mjs
git commit -m "$(cat <<'EOF'
chore(docs): implement cli driver + fixture management

createFixture() spins up a fresh SQLite-backed Wheels app in a tmp
dir; runCli() tokenizes and spawns the command (no shell) inside
it, checks stdout + exit. Each CLI example gets its own fixture.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Orchestrator + report + end-to-end harness run

**Files:**
- Modify: `web/sites/guides/scripts/verify-docs/verify-docs.mjs`
- Modify: `web/sites/guides/scripts/verify-docs/lib/report.mjs`
- Create: `web/sites/guides/scripts/verify-docs/test/orchestrator.test.mjs`

- [ ] **Step 1: Implement report.mjs**

Replace `web/sites/guides/scripts/verify-docs/lib/report.mjs`:

```js
export function printReport(results) {
  let pass = 0;
  let fail = 0;
  const failures = [];
  for (const r of results) {
    if (r.ok) pass++;
    else {
      fail++;
      failures.push(r);
    }
  }
  if (fail > 0) {
    console.log('\n--- Failures ---');
    for (const f of failures) {
      console.log(`\n[${f.kind}] ${f.file}:${f.line}`);
      console.log(f.message);
    }
  }
  console.log(`\n${pass} passed, ${fail} failed`);
  return fail;
}
```

- [ ] **Step 2: Implement verify-docs.mjs**

Replace `web/sites/guides/scripts/verify-docs/verify-docs.mjs`:

```js
#!/usr/bin/env node
/**
 * Usage:
 *   node verify-docs.mjs                       # entire v4 tree
 *   node verify-docs.mjs path/to/file.mdx ...  # specific files
 *   node verify-docs.mjs src/content/docs/v4-0-0-snapshot/start-here/
 */
import { readdir, stat } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { extractExamples } from './lib/extract.mjs';
import { printReport } from './lib/report.mjs';
import { runCompile } from './drivers/compile.mjs';
import { runCli } from './drivers/cli.mjs';

const DEFAULT_TARGET = 'src/content/docs/v4-0-0-snapshot';

async function collectMdx(target) {
  const s = await stat(target);
  if (s.isFile()) return target.endsWith('.mdx') || target.endsWith('.md') ? [target] : [];
  if (!s.isDirectory()) return [];
  const out = [];
  for (const entry of await readdir(target, { withFileTypes: true })) {
    const full = join(target, entry.name);
    if (entry.isDirectory()) out.push(...(await collectMdx(full)));
    else if (entry.isFile() && (full.endsWith('.mdx') || full.endsWith('.md'))) out.push(full);
  }
  return out;
}

const DRIVERS = {
  compile: runCompile,
  cli: runCli,
  // tutorial: runTutorial,   // Phase 1
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
        return { ...ex, ok: false,
          message: `no driver for kind "${ex.kind}" (available: ${Object.keys(DRIVERS).join(', ')})` };
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
```

- [ ] **Step 3: Write the orchestrator test**

Write `web/sites/guides/scripts/verify-docs/test/orchestrator.test.mjs`:

```js
import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const entry = join(here, '..', 'verify-docs.mjs');
const fixture = join(here, 'fixtures/sample.mdx');

function runEntry(args) {
  return new Promise((resolve) => {
    const proc = spawn('node', [entry, ...args], { stdio: ['ignore', 'pipe', 'pipe'] });
    let stdout = '';
    let stderr = '';
    proc.stdout.on('data', (d) => (stdout += d.toString()));
    proc.stderr.on('data', (d) => (stderr += d.toString()));
    proc.on('close', (code) => resolve({ code, stdout, stderr }));
  });
}

test('verify-docs reports pass/fail counts', { timeout: 180_000 }, async () => {
  const { code, stdout } = await runEntry([fixture]);
  // Fixture has compile (pass), cli (pass if wheels installed), and tutorial
  // (fail — no driver in Phase 0). Expect non-zero exit.
  assert.equal(code, 1);
  assert.match(stdout, /passed/);
  assert.match(stdout, /failed/);
  assert.match(stdout, /no driver for kind "tutorial"/);
});

test('verify-docs exits 2 when no files match', async () => {
  const { code } = await runEntry(['/nonexistent/path/does/not/exist.mdx']);
  assert.equal(code, 2);
});
```

- [ ] **Step 4: Run tests — expect pass**

```bash
pnpm test:docs-harness
```

Expected: all harness tests pass.

- [ ] **Step 5: Smoke-test an empty target**

```bash
pnpm verify:docs src/content/docs/v4-0-0-snapshot/basics/
```

Expected: `scanning 1 file(s)`, `found 0 tagged block(s)`, `0 passed, 0 failed`, exit 0.

- [ ] **Step 6: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/youthful-montalcini-6ea95c
git add web/sites/guides/scripts/verify-docs/verify-docs.mjs \
        web/sites/guides/scripts/verify-docs/lib/report.mjs \
        web/sites/guides/scripts/verify-docs/test/orchestrator.test.mjs
git commit -m "$(cat <<'EOF'
chore(docs): wire verify-docs orchestrator + report

Walks directories for .mdx/.md, dispatches examples to drivers in
parallel, aggregates into a readable report. Unknown kinds report
as failures with a clear message.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Sample tutorial page — Part 1 (Hello, Wheels)

**Files:**
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/01-hello-wheels.mdx`

- [ ] **Step 1: Write Part 1**

Write `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/01-hello-wheels.mdx`:

````mdx
---
title: "Part 1: Hello, Wheels"
description: Install Wheels, create your first app, and render a page. No concepts yet — just get something running in 20 minutes.
type: tutorial
sidebar:
  order: 1
---

import { Aside, Steps, FileTree } from '@astrojs/starlight/components';

You'll install the Wheels CLI, create a new app called `blog`, start the dev server, and render a custom page. By the end, `curl localhost:3000/hello` returns "Hello, World."

**You'll learn:**

- How to install Wheels on your machine
- What `wheels new` scaffolds
- How to add a route, controller, and view

<Aside type="note">
  This is Part 1 of the [Build a Blog tutorial](/v4-0-0-snapshot/start-here/tutorial/). You don't need any Wheels or CFML experience — just general programming.
</Aside>

## Install the Wheels CLI

If you haven't installed Wheels yet, see [Installing Wheels](/v4-0-0-snapshot/start-here/installing/) for macOS, Windows, and Linux.

Verify your install:

```bash {test:cli cmd="wheels --version" asserts-stdout="Wheels"}
wheels --version
```

You should see a Wheels version number. If not, revisit the install guide.

## Create the app

<Steps>

1. Create a new app called `blog`:

   ```bash title="run in a fresh directory"
   wheels new blog
   ```

   This scaffolds a Wheels 4.0 app with Turbo and Basecoat pre-activated.

2. Move into the new directory:

   ```bash title="your shell"
   cd blog
   ```

3. Start the dev server:

   ```bash title="your shell"
   wheels server start
   ```

   You'll see `Wheels server running at http://localhost:3000`.

</Steps>

Open `http://localhost:3000` in your browser. You'll see the Wheels welcome page.

## What got created?

<FileTree>
- blog
  - app
    - controllers/
    - models/
    - views/
  - config
    - routes.cfm
    - settings.cfm
  - vendor
    - wheels/
    - hotwire/
    - basecoat/
  - box.json
</FileTree>

Three directories matter right now:

- `app/controllers/` — request-handling code
- `app/views/` — templates
- `config/routes.cfm` — URL-to-controller mapping

## Add a `/hello` route

<Steps>

1. Open `config/routes.cfm`. You'll see:

   ```cfm title="config/routes.cfm (illustrative — do not type)"
   mapper()
       .root(to="home##index", method="get")
       .wildcard()
   .end();
   ```

2. Add a new line before `.wildcard()`:

   ```cfm {test:compile} title="config/routes.cfm"
   mapper()
       .root(to="home##index", method="get")
       .get(name="hello", pattern="/hello", to="home##hello")
       .wildcard()
   .end();
   ```

   `.get(...)` declares: when a GET hits `/hello`, run the `hello` action on the `Home` controller.

3. Open `app/controllers/Home.cfc`. Add a `hello` action:

   ```cfm {test:compile} title="app/controllers/Home.cfc"
   component extends="Controller" {
       function index() {}
       function hello() {}
   }
   ```

   Wheels renders the view at `app/views/home/hello.cfm`.

4. Create `app/views/home/hello.cfm`:

   ```cfm title="app/views/home/hello.cfm"
   <h1>Hello, World</h1>
   ```

5. Reload:

   ```bash title="your shell"
   wheels reload
   ```

</Steps>

## Checkpoint

Your app should now respond to `/hello`:

```bash title="verify"
curl -s http://localhost:3000/hello
```

Expected: `<h1>Hello, World</h1>` in the response.

<Aside type="tip">
  Click between the welcome page and `/hello`. No page flash — that's Turbo Drive handling page transitions without a reload.
</Aside>

## Troubleshooting

**`wheels: command not found`** — PATH doesn't see the CLI. See [Installing Wheels](/v4-0-0-snapshot/start-here/installing/).

**`Route '/hello' not found`** — you added the route but didn't reload. Run `wheels reload`.

**Blank page at `/hello`** — the view file is in the wrong place. It must be at `app/views/home/hello.cfm` (lowercase `home`).

## What's next

In Part 2 (lands in Phase 1), you'll add your first model, run a migration, and seed real data.
````

- [ ] **Step 2: Run the harness against Part 1**

```bash
cd web/sites/guides
pnpm verify:docs src/content/docs/v4-0-0-snapshot/start-here/tutorial/01-hello-wheels.mdx
```

Expected: three tagged blocks (one `cli`, two `compile`), all pass. Exit 0.

- [ ] **Step 3: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/youthful-montalcini-6ea95c
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/01-hello-wheels.mdx
git commit -m "$(cat <<'EOF'
docs(docs): add tutorial Part 1 — Hello, Wheels

First real content in the v4 rewrite. Exercises the harness
end-to-end: compile checks on routes.cfm and Home.cfc fragments,
CLI check on `wheels --version`. Tone reference for all future
tutorial content.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: Sample how-to page — Sending Email

**Files:**
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/sending-email.mdx`

- [ ] **Step 1: Write the how-to**

Write `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/sending-email.mdx`:

````mdx
---
title: Sending Email
description: Send transactional email from a Wheels controller or mailer.
type: howto
sidebar:
  order: 1
---

import { Aside, CardGrid, LinkCard } from '@astrojs/starlight/components';

This page shows you how to send email from a Wheels app. You'll configure SMTP, write a mailer, and send a welcome message after signup.

**You'll learn:**

- How to configure SMTP in `config/settings.cfm`
- How to define a mailer in `app/mailers/`
- How to send mail from a controller action

<Aside type="note">
  You should already know: basic Wheels controllers, generators, and the `params` struct. Finish the [tutorial](/v4-0-0-snapshot/start-here/tutorial/) first.
</Aside>

## Configure SMTP

Open `config/settings.cfm` and set your SMTP credentials:

```cfm {test:compile} title="config/settings.cfm"
set(mailerSettings = {
    server: "smtp.example.com",
    port: 587,
    username: "you@example.com",
    password: application.wo.env("SMTP_PASSWORD")
});
```

Use an environment variable loader for secrets — don't commit passwords to source.

## Generate a mailer

```bash title="your shell"
wheels generate mailer WelcomeMailer welcome
```

Creates `app/mailers/WelcomeMailer.cfc` and `app/views/welcomemailer/welcome.cfm`.

## Write the mailer

```cfm {test:compile} title="app/mailers/WelcomeMailer.cfc"
component extends="Mailer" {
    function welcome(required struct user) {
        this.from = "no-reply@example.com";
        this.to = arguments.user.email;
        this.subject = "Welcome to #arguments.user.firstName#!";
    }
}
```

The function sets headers and hands off rendering to the view.

## Write the template

```cfm title="app/views/welcomemailer/welcome.cfm"
<cfoutput>
<p>Hi #user.firstName#,</p>
<p>Welcome to the blog. Log in any time at #linkTo(route='login')#.</p>
</cfoutput>
```

## Send it from a controller

```cfm {test:compile} title="app/controllers/Users.cfc"
component extends="Controller" {
    function create() {
        user = model("User").create(params.user);
        if (user.hasErrors()) {
            renderView(action="new");
            return;
        }
        sendMail(mailer="WelcomeMailer", method="welcome", user=user);
        redirectTo(route="login", success="Welcome! Please log in.");
    }
}
```

`sendMail()` runs synchronously by default. For production, enqueue it as a background job so the request returns fast.

## Related guides

<CardGrid>
  <LinkCard title="Background Jobs" href="/v4-0-0-snapshot/digging-deeper/" description="Send mail in the background." />
  <LinkCard title="Configuration and Secrets" href="/v4-0-0-snapshot/core-concepts/" description="How Wheels loads environment-specific settings." />
</CardGrid>
````

- [ ] **Step 2: Run the harness**

```bash
pnpm verify:docs src/content/docs/v4-0-0-snapshot/digging-deeper/sending-email.mdx
```

Expected: three compile blocks, all pass. Exit 0.

- [ ] **Step 3: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/youthful-montalcini-6ea95c
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/sending-email.mdx
git commit -m "$(cat <<'EOF'
docs(docs): add how-to sample — Sending Email

Phase 0 sample for the how-to Diátaxis type. Exercises compile
checks on settings, mailer, and controller fragments.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 11: Sample concept page — The Request Lifecycle

**Files:**
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/core-concepts/request-lifecycle.mdx`

- [ ] **Step 1: Write the concept page**

Write `web/sites/guides/src/content/docs/v4-0-0-snapshot/core-concepts/request-lifecycle.mdx`:

```mdx
---
title: The Request Lifecycle
description: What Wheels does between an incoming HTTP request and the response your user sees.
type: concept
sidebar:
  order: 1
---

import { Aside } from '@astrojs/starlight/components';

When a request arrives at your Wheels app, it flows through five stages before your controller action runs — and three more before the response goes back. Understanding this pipeline tells you where to put code for every problem: auth goes in middleware, request-shape changes go in filters, view decoration goes in helpers.

**You should already know:** what a controller action is, what a filter is. If not, finish the [tutorial](/v4-0-0-snapshot/start-here/tutorial/) first.

## The pipeline

```text
HTTP request
    │
    ▼
(1) Middleware              — before controller exists
    │
    ▼
(2) Dispatch + route match  — pick controller + action
    │
    ▼
(3) Controller instantiation — config() runs, filters registered
    │
    ▼
(4) beforeAction filters    — load records, enforce ownership
    │
    ▼
(5) Controller action       — your code
    │
    ▼
(6) afterAction filters
    │
    ▼
(7) View rendering          — layouts, partials, helpers
    │
    ▼
(8) Response sent
```

## Why this order matters

**Middleware runs before the controller exists.** That's why rate limiting and auth go there — they can short-circuit without paying the cost of instantiating a controller.

**`beforeAction` filters run after `config()`.** That's why they can rely on injected services (`this.emailService`) — the DI container has already resolved them.

**View rendering is inside the controller's request.** Helpers called from views access the same `params`, `flash`, and `session` that the action saw. The view is not a separate process.

## A concrete request

An authenticated user posts a new comment:

1. **Middleware.** RequestId stamps a correlation ID. Cors validates the Origin. SecurityHeaders prepares response headers.
2. **Dispatch.** `POST /posts/42/comments` matches `comments#create`.
3. **Instantiation.** `Comments.cfc` instantiated; `config()` registers `authenticate` filter, injects `commentService`.
4. **Filter.** `authenticate` checks the session; user is logged in, does nothing.
5. **Action.** `create()` reads `params.comment`, builds a Comment, saves it.
6. **afterAction.** A filter logs the event.
7. **Rendering.** `redirectTo(post)` short-circuits rendering, returns a 302.
8. **Response.** Correlation ID + CORS + security headers from step 1 applied.

<Aside type="tip">
  When deciding where to put new code, picture this pipeline and ask: when does this need to run? Before the controller exists? Middleware. Before every action in a controller? `beforeAction`. Once for a specific action? Action code.
</Aside>

## See also

- [Middleware Pipeline](/v4-0-0-snapshot/core-concepts/) — writing your own middleware
- [MVC in Wheels](/v4-0-0-snapshot/core-concepts/) — where each layer lives
- [How Routing Works](/v4-0-0-snapshot/core-concepts/) — step 2 in depth
```

- [ ] **Step 2: Run the harness**

```bash
pnpm verify:docs src/content/docs/v4-0-0-snapshot/core-concepts/request-lifecycle.mdx
```

Expected: zero tagged blocks, `0 passed, 0 failed`, exit 0.

- [ ] **Step 3: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/youthful-montalcini-6ea95c
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/core-concepts/request-lifecycle.mdx
git commit -m "$(cat <<'EOF'
docs(docs): add concept sample — The Request Lifecycle

Phase 0 sample for the concept Diátaxis type. Prose-first, no
executable examples. Tone reference for all future concept pages.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 12: Sample reference page — wheels dbmigrate latest

**Files:**
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/cli-reference/dbmigrate-latest.mdx`

- [ ] **Step 1: Write the reference page**

Write `web/sites/guides/src/content/docs/v4-0-0-snapshot/cli-reference/dbmigrate-latest.mdx`:

````mdx
---
title: wheels dbmigrate latest
description: Run every pending migration in order.
type: reference
sidebar:
  order: 1
---

## Synopsis

```bash
wheels dbmigrate latest [options]
```

Runs every pending migration in order until the schema is at the most recent version.

## Options

| Flag              | Default       | Description                                                  |
| ----------------- | ------------- | ------------------------------------------------------------ |
| `--environment=E` | `development` | Use the database configured for environment `E`.             |
| `--dry-run`       | off           | Print the migrations that would run; execute nothing.        |
| `--quiet`         | off           | Suppress per-migration output.                               |

## Exit codes

| Code | Meaning                                                     |
| ---- | ----------------------------------------------------------- |
| `0`  | Ran successfully, or no migrations pending.                 |
| `1`  | A migration raised an error; schema may be partially applied. |
| `2`  | Configuration error (missing DB, bad environment).          |

## Examples

Migrate development to the latest schema:

```bash {test:cli cmd="wheels dbmigrate latest"}
wheels dbmigrate latest
```

Preview without applying:

```bash {test:cli cmd="wheels dbmigrate latest --dry-run"}
wheels dbmigrate latest --dry-run
```

Migrate production from a deploy script:

```bash title="deploy.sh"
wheels dbmigrate latest --environment=production --quiet
```

## See also

- [`wheels dbmigrate up`](/v4-0-0-snapshot/cli-reference/) — apply one migration
- [`wheels dbmigrate down`](/v4-0-0-snapshot/cli-reference/) — revert one migration
- [`wheels dbmigrate info`](/v4-0-0-snapshot/cli-reference/) — show migration status
- [Migrations (concept)](/v4-0-0-snapshot/basics/) — how migrations work
````

- [ ] **Step 2: Run the harness**

```bash
pnpm verify:docs src/content/docs/v4-0-0-snapshot/cli-reference/dbmigrate-latest.mdx
```

Expected: two CLI blocks, both pass. Exit 0.

If the fixture has no migrations and `dbmigrate latest` exits non-zero, swap the second example to an illustrative block.

- [ ] **Step 3: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/youthful-montalcini-6ea95c
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/cli-reference/dbmigrate-latest.mdx
git commit -m "$(cat <<'EOF'
docs(docs): add reference sample — wheels dbmigrate latest

Phase 0 sample for the reference Diátaxis type. Tables + exit codes,
no narrative.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 13: Astro build smoke test

**Files:** none modified — verification only.

- [ ] **Step 1: Build the guides site**

```bash
cd web/sites/guides
pnpm build
```

Expected: Astro builds without errors. All v4 sidebar pages resolve.

If a "Could not find page for link" error appears, a sidebar entry points at a missing page. Create the placeholder or remove the sidebar entry.

- [ ] **Step 2: Run the dev server and hit the sample pages**

```bash
pnpm dev &
sleep 5
curl -sf http://localhost:4323/v4-0-0-snapshot/ | head -20
curl -sf http://localhost:4323/v4-0-0-snapshot/start-here/tutorial/01-hello-wheels/ | head -20
curl -sf http://localhost:4323/v4-0-0-snapshot/digging-deeper/sending-email/ | head -20
curl -sf http://localhost:4323/v4-0-0-snapshot/core-concepts/request-lifecycle/ | head -20
curl -sf http://localhost:4323/v4-0-0-snapshot/cli-reference/dbmigrate-latest/ | head -20
kill %1
```

Expected: all four curls return HTML containing the page title.

- [ ] **Step 3: Run the full harness against v4**

```bash
pnpm verify:docs
```

Expected: finds all tagged blocks across the four sample pages, all pass. Exit 0.

- [ ] **Step 4: Commit any fixes surfaced by the build**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/youthful-montalcini-6ea95c
git status
# If changes: git add -A && git commit with a descriptive message.
# Otherwise: skip.
```

---

## Task 14: CI workflow

**Files:**
- Create: `.github/workflows/docs-verify.yml`

- [ ] **Step 1: Write the workflow**

Write `.github/workflows/docs-verify.yml`:

```yaml
name: Verify docs

on:
  pull_request:
    branches: [develop]
    paths:
      - 'web/sites/guides/src/content/docs/v4-0-0-snapshot/**'
      - 'web/sites/guides/scripts/verify-docs/**'
      - 'web/sites/guides/package.json'
      - '.github/workflows/docs-verify.yml'

jobs:
  verify:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up pnpm
        uses: pnpm/action-setup@v4
        with:
          version: 10.23.0

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: pnpm
          cache-dependency-path: web/pnpm-lock.yaml

      - name: Install Node deps
        working-directory: web
        run: pnpm install --frozen-lockfile

      - name: Set up Java 21 (required by Wheels CLI)
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 21

      - name: Install Wheels CLI
        run: |
          # Adjust install mechanism per project convention if this script
          # is not the canonical path — e.g. download a release tarball from
          # the wheels-dev/wheels repo and add its bin to PATH.
          curl -fsSL https://install.wheels.dev/linux.sh | bash
          echo "$HOME/.wheels/bin" >> "$GITHUB_PATH"

      - name: Smoke-test the CLI
        run: wheels --version

      - name: Run harness unit tests
        working-directory: web/sites/guides
        run: pnpm test:docs-harness

      - name: Verify v4 docs
        working-directory: web/sites/guides
        run: pnpm verify:docs

      - name: Build guides site
        working-directory: web/sites/guides
        run: pnpm build
```

The `install.wheels.dev/linux.sh` URL is a placeholder. If the actual install mechanism differs (e.g., tarball download, `setup-wheels` action), substitute it — rest of the workflow unchanged.

- [ ] **Step 2: Verify the YAML parses**

```bash
python3 -c 'import yaml; yaml.safe_load(open(".github/workflows/docs-verify.yml"))'
```

Expected: no output (successful parse).

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/docs-verify.yml
git commit -m "$(cat <<'EOF'
chore(config): add docs-verify CI workflow

Runs verify-docs harness + astro build on every PR touching v4
guides or the harness. Installs the Wheels CLI in CI so {test:cli}
examples can actually execute.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 15: Phase 0 completion report

**Files:**
- Create: `docs/superpowers/plans/2026-04-18-guides-rewrite-phase-0-report.md`

A one-pager for Peter's review before Phase 1 starts.

- [ ] **Step 1: Write the report**

Write `docs/superpowers/plans/2026-04-18-guides-rewrite-phase-0-report.md`:

```markdown
# Guides Rewrite — Phase 0 Completion Report

**Date:** YYYY-MM-DD (fill in at commit)
**Branch:** claude/youthful-montalcini-6ea95c
**Spec:** [../specs/2026-04-18-guides-rewrite-v4-design.md](../specs/2026-04-18-guides-rewrite-v4-design.md)

## Shipped

- New IA scaffold at `web/sites/guides/src/content/docs/v4-0-0-snapshot/` with placeholder MDX per top-level section.
- Hand-authored sidebar JSON matching the new IA.
- Writing style guide at `web/sites/guides/STYLE.md`.
- verify-docs harness at `web/sites/guides/scripts/verify-docs/`:
  - `extract.mjs` — MDX walker (regex-based)
  - `exec.mjs` — safe spawn wrapper (no shell)
  - `compile.mjs` driver — `{test:compile}`
  - `cli.mjs` driver — `{test:cli}` with fixture isolation
  - orchestrator + report
  - unit tests under `test/`
- Four sample pages, one per Diátaxis type:
  - Tutorial: Part 1 — Hello, Wheels
  - How-to: Sending Email
  - Concept: The Request Lifecycle
  - Reference: `wheels dbmigrate latest`
- CI workflow at `.github/workflows/docs-verify.yml`.

## What was surprising

(Fill in after execution. Common surprises: CLI flag naming, fixture quirks, MDX edge cases the regex didn't handle.)

## Known blockers for Phase 1

- `{test:tutorial}` driver not implemented. Must land before Phase 1 tutorial content can validate end-to-end.
- (Add any others discovered during Phase 0.)

## What to review

1. Read the four sample pages in order (tutorial → how-to → concept → reference). Does tone feel right? Is voice consistent?
2. Skim `STYLE.md`. Anything missing or wrong?
3. Run `pnpm verify:docs` locally.
4. Open a Cloudflare preview URL if available; click through the sidebar.

Once approved, Phase 1 starts: the full 7-part tutorial + supporting Start Here pages.
```

- [ ] **Step 2: Commit**

```bash
git add docs/superpowers/plans/2026-04-18-guides-rewrite-phase-0-report.md
git commit -m "$(cat <<'EOF'
docs(docs): Phase 0 completion report template

For Peter's review before Phase 1 starts.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-review

**Spec coverage:**

- ✅ Starlight-native MDX at `web/sites/guides/src/content/docs/v4-0-0-snapshot/` — Tasks 2, 9–12
- ✅ Style guide — Task 3
- ✅ Directory scaffold with placeholder MDX per IA section — Task 2
- ✅ Harness v1 with compile + cli drivers (tutorial driver deferred to Phase 1 per spec) — Tasks 4–8
- ✅ One sample page per Diátaxis type — Tasks 9–12
- ✅ CI integration — Task 14
- ✅ Phase 0 completion report — Task 15

**Placeholder scan:** none found. Discovery steps (Tasks 6.1, 7.1) explicitly ask the worker to confirm CLI command surface rather than hardcode assumptions — that's intentional, not a placeholder.

**Type consistency:** example object `{file, line, language, kind, attrs, body}` stable across extract → drivers → orchestrator. Driver return shape `{ok, message?}` stable across compile + cli.

**Ambiguity:** The Wheels CLI install URL in Task 14 is a placeholder (`install.wheels.dev/linux.sh`); flagged inline with guidance to substitute.

**Security:** No shell invocation anywhere. All process launches go through `runExec(program, args, opts)` in `lib/exec.mjs`, which uses `spawn` with an args array. `tokenize()` documents that shell features are explicitly unsupported.
