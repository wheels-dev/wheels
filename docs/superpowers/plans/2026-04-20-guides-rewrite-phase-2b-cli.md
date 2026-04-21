# Wheels 4.0 Guides — Phase 2b-CLI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the CLI Reference section by rewriting all command documentation from source (LuCLI core + Wheels Module). The v4 CLI is LuCLI renamed with a Wheels Module bolted on — we document both surfaces. The legacy GitBook pages describe a defunct CommandBox-era CLI and are scaffolding reference only, not a migration source.

**Architecture:** Per-page subagent authoring against two authoritative sources: `~/GitHub/bpamiri/LuCLI/src/main/java/org/lucee/lucli/cli/commands/*.java` (picocli `@Command` annotations) for core, and `cli/lucli/Module.cfc` (public functions) for the Wheels Module. Each page's commands get verified against source for flags, arguments, output streams, and exit codes. `{test:cli}` harness exercises real invocations where ephemeral fixtures allow.

**Tech Stack:** Astro 5 + Starlight 0.34 + MDX. `wheels` CLI v0.3.5-SNAPSHOT+ (framework v4.0.0). LuCLI upstream at `~/GitHub/bpamiri/LuCLI/` (picocli-based Java). Verify-docs harness with `{test:cli}` primary driver.

**Base:** Branch `claude/lucid-thompson-b8c121` at Phase 2b-Testing head `8a814d2bd`. All commits land on this same branch; one final merge to develop happens at end of Phase 2c.

**Review model (unchanged from prior phases):**
- Content pages — subagent-driven; harness + build as verification gate
- Integration tasks (sidebar, landing page, directory rename) — inline
- End-of-phase final review — single `pr-review-toolkit:code-reviewer` subagent across the Phase 2b-CLI diff

**Prologue — policy decisions carried + new for this phase:**

1. **Directory canonicalization.** `cli-reference/` (Phase 0 samples: `index.mdx`, `info.mdx`) is retired. The canonical path is `command-line-tools/` — matches legacy GitBook, matches what `generate-guides.mjs` writes for other versions, matches the term users search for. Phase 0 samples are fabricated and will be deleted, not preserved.
2. **Cold rewrite from source, not migration.** The 103 legacy GitBook pages at `docs/src/command-line-tools/` describe the defunct CommandBox-era `wheels-cli` module (install path `~/.CommandBox/cfml/modules/wheels-cli/`, etc.). They are not authoritative for v4. Subagents may skim them for IA hints but must author against `Module.cfc` + LuCLI Java sources.
3. **Two-surface IA.** Top-level structure is `command-line-tools/` with child sections `wheels-commands/` (Module) and `core-commands/` (LuCLI native). Landing page explains the two-surface composition model.
4. **Command grouping over 1-page-per-command.** Related narrow commands (start/stop/reload; routes/info/stats/notes; analyze/validate) share pages to keep the section navigable. Headline commands (generate, migrate, test) get dedicated pages.
5. **Framework gap #11 must land before execution.** LuCLI parallel-spawn race (`Can't cast String [] to a value of type [Struct]` parsing `lucee.json` mid-write) will flake the `{test:cli}` harness across ~30+ content pages. Pre-flight Task 0 fixes or serializes the harness.
6. **Compile driver in fallback mode remains acceptable.** If LuCLI PR #56 hasn't merged by Phase 2b-CLI execution, bracket-balance-only validation is still useful. `{test:cli}` carries most of the verification load this phase since CLI output is directly assertable.
7. **`.ai/` deletion continues.** `.ai/wheels/cli/`, `.ai/wheels/mcp/`, and any scattered CLI references under `.ai/wheels/` are deleted in the task that supersedes them.

---

## File Structure

### New files — CLI Reference section (~22 pages)

All under `web/sites/guides/src/content/docs/v4-0-0-snapshot/command-line-tools/`:

**Top-level:**
| Path | Responsibility |
|------|----------------|
| `index.mdx` | Landing page — two-surface explanation (LuCLI core + Wheels Module), CardGrid to sub-sections |
| `installation.mdx` | `brew install wheels`, `choco install wheels`, manual Java 21 setup, PATH verification, `wheels --version` sanity check |
| `quick-start.mdx` | `wheels new myapp` → `wheels start` → open browser; first code-generation and migration commands |
| `configuration.mdx` | `lucee.json` schema, environment variables (`WHEELS_*`), profile selection, verbose/timing flags |
| `mcp-integration.mdx` | `wheels mcp wheels` stdio server, `wheels mcp setup` scaffolding, `.mcp.json` / `.opencode.json` contents, tool discovery |

**Wheels Commands (`wheels-commands/`):**
| Path | Covers |
|------|--------|
| `creating-a-project.mdx` | `wheels new`, `wheels create` — differences, options (--port, --db, --skip-*), generated structure |
| `code-generation.mdx` | `wheels generate` + subcommands: `model`, `controller`, `scaffold`, `migration`, `route`, `view`, `property`, `helper`, `snippet`, `api-resource`, `test`, `app` |
| `database.mdx` | `wheels migrate [latest\|up\|down\|info]`, `wheels seed [--environment]`, `wheels db [subcommand]`, `wheels generate migration` cross-link |
| `dev-server.mdx` | `wheels start`, `wheels stop`, `wheels reload` — server lifecycle, port selection, profile use |
| `testing.mdx` | `wheels test` flags (--filter, --db, --reporter, --verbose, --ci, --core), `wheels browser install`, cross-link to Testing section detail pages |
| `app-inspection.mdx` | `wheels routes`, `wheels info`, `wheels stats`, `wheels notes`, `wheels doctor` — read-only introspection commands |
| `code-quality.mdx` | `wheels analyze`, `wheels validate` — diagnostic + lint surfaces |
| `scaffold-cleanup.mdx` | `wheels destroy` (+ `d` alias) — reverse of generate, per-type removal |
| `console-and-repl.mdx` | `wheels console` — app-context REPL, difference from LuCLI's `repl` |
| `upgrade.mdx` | `wheels upgrade` — framework version migration, prerequisites, rollback |

**LuCLI Core Commands (`core-commands/`):**
| Path | Covers |
|------|--------|
| `server.mdx` | `wheels server [start\|stop\|restart\|status\|list\|log\|info]` — underlying engine, port/profile semantics |
| `cfml-execution.mdx` | `wheels cfml <expr>`, `wheels run <script>`, `wheels repl` — three modes of executing CFML outside an app context |
| `system-and-secrets.mdx` | `wheels system [inspect\|paths\|clean\|backup]`, `wheels secrets`, `wheels daemon` — state management |
| `modules-and-deps.mdx` | `wheels modules [list\|add\|install\|update\|init\|run\|help]`, `wheels deps [install\|add\|prune]` |
| `ai-and-completion.mdx` | `wheels ai`, `wheels completion [bash\|zsh]` — IDE / shell integration utilities |

### Modified files

| Path | Change |
|------|--------|
| `web/sites/guides/src/sidebars/v4-0-0-snapshot.json` | Add new `CLI Reference` section with ~22 entries; remove stub `cli-reference/*` entries |
| `web/sites/guides/astro.config.mjs` (if redirect needed) | Add redirect `cli-reference/*` → `command-line-tools/*` only if external links exist; otherwise skip |

### Deleted files

| Path | Reason |
|------|--------|
| `web/sites/guides/src/content/docs/v4-0-0-snapshot/cli-reference/index.mdx` | Phase 0 sample — superseded by `command-line-tools/index.mdx` |
| `web/sites/guides/src/content/docs/v4-0-0-snapshot/cli-reference/info.mdx` | Phase 0 sample — fabricated `--json`/`--quiet` flags; superseded by `wheels-commands/app-inspection.mdx` |
| `web/sites/guides/src/content/docs/v4-0-0-snapshot/cli-reference/` (directory) | Empty after above |
| `.ai/wheels/cli/*` (any) | Consolidated into `command-line-tools/*` pages |
| `.ai/wheels/mcp/*` (any overlap) | Consolidated into `command-line-tools/mcp-integration.mdx` |

---

## Phase Layout

| Task | Page / Action | Source authority | Review mode |
|------|---------------|------------------|-------------|
| 0 | Pre-flight: fix framework gap #11 (LuCLI parallel-spawn race) | LuCLI harness | Inline |
| 1 | Delete Phase 0 `cli-reference/` + create `command-line-tools/` skeleton | — | Inline |
| 2 | `index.mdx` — Landing page | Module.cfc + LuCLI README | Subagent + harness |
| 3 | `installation.mdx` | Homebrew/Chocolatey formulas, README install sections | Subagent + harness |
| 4 | `quick-start.mdx` | Module.cfc `new`, `start`, `generate` | Subagent + harness |
| 5 | `configuration.mdx` | LuCLI `lucee.json` handling + Wheels profile env vars | Subagent + harness |
| 6 | `mcp-integration.mdx` | Module.cfc `mcp` + LuCLI `McpCommand.java` | Subagent + harness |
| 7 | `wheels-commands/creating-a-project.mdx` | Module.cfc `new` (L392), `create` (L466) | Subagent + harness |
| 8 | `wheels-commands/code-generation.mdx` | Module.cfc `generate` (L129) + subcommand dispatch | Subagent + harness |
| 9 | `wheels-commands/database.mdx` | Module.cfc `migrate` (L222), `seed` (L251), `db` (L1398) | Subagent + harness |
| 10 | `wheels-commands/dev-server.mdx` | Module.cfc `start` (L361), `stop` (L379), `reload` (L331) | Subagent + harness |
| 11 | `wheels-commands/testing.mdx` | Module.cfc `test` (L277), `browser` (L1469) | Subagent + harness |
| 12 | `wheels-commands/app-inspection.mdx` | Module.cfc `routes` (L502), `info` (L527), `stats` (L1285), `notes` (L1346), `doctor` (L1212) | Subagent + harness |
| 13 | `wheels-commands/code-quality.mdx` | Module.cfc `analyze` (L1001), `validate` (L1076) | Subagent + harness |
| 14 | `wheels-commands/scaffold-cleanup.mdx` | Module.cfc `destroy` (L1114), `d` (L1201) | Subagent + harness |
| 15 | `wheels-commands/console-and-repl.mdx` | Module.cfc `console` (L641) | Subagent + harness |
| 16 | `wheels-commands/upgrade.mdx` | Module.cfc `upgrade` (L1441) | Subagent + harness |
| 17 | `core-commands/server.mdx` | `ServerCommand.java` + subcommands | Subagent + harness |
| 18 | `core-commands/cfml-execution.mdx` | `CfmlCommand.java`, `RunCommand.java`, `ReplCommand.java` | Subagent + harness |
| 19 | `core-commands/system-and-secrets.mdx` | `SystemCommand.java`, `SecretsCommand.java`, `DaemonCommand.java` | Subagent + harness |
| 20 | `core-commands/modules-and-deps.mdx` | `ModulesCommand.java` + children, `DepsCommand.java` + children | Subagent + harness |
| 21 | `core-commands/ai-and-completion.mdx` | `AiCommand.java`, `CompletionCommand.java` | Subagent + harness |
| 22 | Sidebar + landing integration | — | Inline |
| 23 | `.ai/` CLI/MCP audit + cleanup | — | Inline |
| 24 | Full harness + build + Phase 2b-CLI report | — | Inline |
| 25 | Final code review | — | Subagent |

**26 tasks. Expected wall time: 3-4 sessions at Phase 2b-Testing cadence.**

---

## Shared conventions (carrying forward from Phase 2b-Testing)

All CLI pages use `type: reference` (new — Phase 2b-Testing used `howto`; reference is more honest for CLI docs). Open with "You'll use this for," close with "Related commands" CardGrid. Use `{test:cli}` for every command example that can run against an ephemeral fixture. Use fenced `bash` blocks (no harness) only for destructive or interactive commands (`wheels new`, `wheels upgrade`, `wheels console`).

Headings at `###` max. Second-person voice. No marketing copy.

Sidebar sort order matches the Phase Layout task numbers within each section.

Commit message pattern:
```
docs(docs): cli/<page-slug> — <imperative phrase>
```

### Verification template (every page)

```bash
export JAVA_HOME=/opt/homebrew/Cellar/openjdk@21/21.0.8/libexec/openjdk.jdk/Contents/Home
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/lucid-thompson-b8c121/web/sites/guides
pnpm verify:docs src/content/docs/v4-0-0-snapshot/command-line-tools/<page>.mdx
pnpm build 2>&1 | tail -5
```

### Cross-page consistency rules

- **Two-surface naming.** Always refer to the CLI as `wheels` when invoking. Never "Wheels CLI" in command prose; use "the CLI" or omit. Explain "LuCLI" only in `index.mdx`, `configuration.mdx`, and the `core-commands/` landing.
- **Flag style.** Long flags with `=`: `wheels test --filter=models`, `wheels generate model User --migration=true`. Short flags without `=`: `wheels test -v`. Match Module.cfc `parseGeneratorArgs()` expectations.
- **Exit codes.** Report actual exit codes from source. `wheels info` returns empty string but sets no exit code (per Phase 0 audit — it's effectively exit 0). Don't invent exit codes.
- **Output streams.** `{test:cli}` blocks should assert against the stream the command actually uses. `wheels info` writes to stderr — assertions need `stream=stderr` or the full combined-output match.
- **Hidden commands.** 7 commands in `mcpHiddenTools()` (`mcp`, `d`, `new`, `console`, `start`, `stop`, `browser`) are CLI-only. Document them, note they're excluded from MCP in the relevant page.
- **Subagent instructions include the Module.cfc / Java line range** where each command's implementation lives so the author doesn't have to search.

---

## Task 0: Pre-flight — Fix LuCLI parallel-spawn race (framework gap #11)

**Files:**
- Investigate: `~/GitHub/bpamiri/LuCLI/src/main/java/org/lucee/lucli/` — locate `lucee.json` write path
- Investigate: `web/sites/guides/scripts/verify-docs/drivers/cli.mjs` — harness driver that spawns LuCLI

**Context:** The `{test:cli}` driver spawns an ephemeral LuCLI fixture per block. At 30+ blocks per run, two concurrent spawns race the `lucee.json` write and one fails with `Can't cast String [] to a value of type [Struct]`. Phase 2b-Testing hit this at ~283 blocks and got by with retry. Phase 2b-CLI will have ~100+ new blocks where most are net-new `{test:cli}` invocations.

- [ ] **Step 1: Reproduce locally**

Run harness at concurrency > 1 against a small test fixture:
```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/lucid-thompson-b8c121/web/sites/guides
pnpm verify:docs --concurrency=4 src/content/docs/v4-0-0-snapshot/testing/*.mdx
```
Expected: at least one block fails with the lucee.json cast error.

- [ ] **Step 2: Identify the race in LuCLI**

Open `~/GitHub/bpamiri/LuCLI/src/main/java/org/lucee/lucli/` and grep for `lucee.json` writers. Find the write path (likely `ServerCommand` startup or `SystemCommand` profile setup). Check whether the write is atomic (write-to-tmp + rename) or direct.

Report what you find. Two likely options:
- **Option A (upstream fix):** make write atomic — PR to LuCLI. If this is quick, do it.
- **Option B (harness workaround):** serialize `{test:cli}` blocks that spawn fixtures. Add a mutex/semaphore per fixture dir in `cli.mjs`.

- [ ] **Step 3: Implement chosen fix**

If Option A: open PR at `https://github.com/bpamiri/LuCLI`, reference framework gap #11 in the description, land it, bump the pin in this repo if needed.

If Option B: edit `web/sites/guides/scripts/verify-docs/drivers/cli.mjs` to add per-fixture-dir serialization. Keep global concurrency for different fixture dirs.

- [ ] **Step 4: Re-run reproduction**

```bash
pnpm verify:docs --concurrency=4 src/content/docs/v4-0-0-snapshot/testing/*.mdx
```
Expected: no cast errors across 3 consecutive runs.

- [ ] **Step 5: Commit + mark gap closed**

```bash
git add web/sites/guides/scripts/verify-docs/drivers/cli.mjs docs/superpowers/plans/2026-04-19-framework-gaps-from-guides-phase-1.md
git commit -m "fix(cli): serialize lucee.json writes in verify-docs driver"
```

Update `docs/superpowers/plans/2026-04-19-framework-gaps-from-guides-phase-1.md` gap #11 status to "shipped" with commit hash.

---

## Task 1: Delete Phase 0 `cli-reference/` + create `command-line-tools/` skeleton

**Files:**
- Delete: `web/sites/guides/src/content/docs/v4-0-0-snapshot/cli-reference/index.mdx`
- Delete: `web/sites/guides/src/content/docs/v4-0-0-snapshot/cli-reference/info.mdx`
- Delete: `web/sites/guides/src/content/docs/v4-0-0-snapshot/cli-reference/` (directory)
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/command-line-tools/` (directory)
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/command-line-tools/wheels-commands/` (directory)
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/command-line-tools/core-commands/` (directory)

- [ ] **Step 1: Confirm no internal links point at `cli-reference/`**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/lucid-thompson-b8c121
grep -rn "cli-reference/" web/sites/guides/src/ --include="*.mdx" --include="*.json"
```
Expected: no results (or only the files being deleted).

If any results: update the offending pages to reference `command-line-tools/<slug>` instead.

- [ ] **Step 2: Delete the Phase 0 directory**

```bash
rm -rf web/sites/guides/src/content/docs/v4-0-0-snapshot/cli-reference/
```

- [ ] **Step 3: Create skeleton directories**

```bash
mkdir -p web/sites/guides/src/content/docs/v4-0-0-snapshot/command-line-tools/wheels-commands
mkdir -p web/sites/guides/src/content/docs/v4-0-0-snapshot/command-line-tools/core-commands
```

- [ ] **Step 4: Remove cli-reference from sidebar**

Edit `web/sites/guides/src/sidebars/v4-0-0-snapshot.json` — remove the `CLI Reference` section (or whatever section points at `cli-reference/`). The full `CLI Reference` section gets added back in Task 22 with all the new page entries.

- [ ] **Step 5: Verify build still succeeds**

```bash
cd web/sites/guides
pnpm build 2>&1 | tail -10
```
Expected: build succeeds, no broken-link errors.

- [ ] **Step 6: Commit**

```bash
git add -A web/sites/guides/src/content/docs/v4-0-0-snapshot/cli-reference web/sites/guides/src/content/docs/v4-0-0-snapshot/command-line-tools web/sites/guides/src/sidebars/v4-0-0-snapshot.json
git commit -m "docs(docs): retire phase 0 cli-reference samples, seed command-line-tools skeleton"
```

---

## Task 2: `index.mdx` — Landing page (two-surface explanation)

**Files:**
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/command-line-tools/index.mdx`

**Source authority:**
- `cli/lucli/Module.cfc` (lines 1-128) for the module contract
- `cli/lucli/module.json` for module metadata
- `~/GitHub/bpamiri/LuCLI/README.md` for LuCLI overview

**Subagent brief:**

```
Write the landing page for the CLI Reference section in Wheels v4 guides.

File: web/sites/guides/src/content/docs/v4-0-0-snapshot/command-line-tools/index.mdx
Frontmatter: title="CLI Reference", type=reference (or Starlight equivalent)

Content structure (headings at ### max):

1. "You'll use this for" — three bullets covering: project creation, dev loop
   (generate/migrate/test/server), inspection + diagnostics.

2. "Two surfaces in one command" — explain that `wheels` is LuCLI renamed
   with a Wheels Module bolted on. LuCLI provides server / REPL / CFML
   execution / system / modules / deps. The Wheels Module adds generate /
   migrate / seed / test / etc. A single invocation like `wheels test` routes
   to the Module; `wheels server` routes to LuCLI core. No separate binaries,
   no separate install.

3. "Getting started" — CardGrid with 3 cards: Installation, Quick Start,
   Configuration. Use Starlight <LinkCard> or <CardGrid><Card>.

4. "Wheels commands" — CardGrid with entries for each wheels-commands/ page:
   Creating a Project, Code Generation, Database, Dev Server, Testing, App
   Inspection, Code Quality, Scaffold Cleanup, Console & REPL, Upgrade.

5. "Core commands (LuCLI)" — CardGrid for each core-commands/ page: Server,
   CFML Execution, System & Secrets, Modules & Deps, AI & Completion.

6. "MCP integration" — one-paragraph teaser with link to mcp-integration.mdx.
   Note `wheels mcp wheels` is the canonical stdio surface; the deprecated
   HTTP endpoint gets a deprecation mention with link to the migration doc.

Verify against source:
- Module.cfc has exactly these public commands: (list from source, don't
  invent). Hidden-from-MCP commands are enumerated by mcpHiddenTools().
- Do NOT claim any command exists that isn't in Module.cfc or LuCLI Java.

Do NOT:
- Invent flags or subcommands.
- Use "Wheels CLI" as a proper noun — say "the CLI" or "wheels" (the binary).
- Link to pages that don't exist yet — use relative paths to sibling pages
  that this phase will create (all listed in Task 2-21).
```

- [ ] **Step 1: Dispatch subagent**

Use `Agent` with `subagent_type: general-purpose`. Full brief above, working directory `/Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/lucid-thompson-b8c121`.

- [ ] **Step 2: Run verify-docs harness**

```bash
cd web/sites/guides
pnpm verify:docs src/content/docs/v4-0-0-snapshot/command-line-tools/index.mdx
```
Expected: all blocks pass. No `{test:cli}` blocks expected on a landing page — `{test:compile}` for any snippets.

- [ ] **Step 3: Build**

```bash
pnpm build 2>&1 | tail -5
```
Expected: success, no broken-link warnings.

- [ ] **Step 4: Commit**

```bash
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/command-line-tools/index.mdx
git commit -m "docs(docs): cli/index — explain two-surface command composition"
```

---

## Task 3: `installation.mdx` — Install paths + PATH sanity

**Files:**
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/command-line-tools/installation.mdx`

**Source authority:**
- Homebrew formula at `~/GitHub/wheels-dev/homebrew-wheels/`
- Chocolatey formula at `~/GitHub/wheels-dev/chocolatey-wheels/`
- LuCLI README for manual JAR install
- Java 21 requirement from `pom.xml`

**Subagent brief:**

```
Write the installation page for the Wheels CLI.

File: web/sites/guides/src/content/docs/v4-0-0-snapshot/command-line-tools/installation.mdx
Frontmatter: title="Installation", type=reference

Content:

1. "You'll use this for" — initial setup, verifying install, upgrading CLI.

2. "Requirements" — Java 21 (`brew install openjdk@21` on macOS,
   equivalent on Linux/Windows). Check with `java -version`. JAVA_HOME
   must be set on macOS (Homebrew JDK isn't linked by default).

3. "macOS / Linux (Homebrew)" — `{test:cli}`-safe where possible
   (probably not, since brew install isn't ephemeral — use fenced bash).
   Show: `brew tap wheels-dev/wheels` (verify tap name from formula repo),
   `brew install wheels`, `wheels --version`.

4. "Windows (Chocolatey)" — `choco install wheels`, `wheels --version`.
   Verify package name against chocolatey-wheels repo.

5. "Manual JAR install" — download from LuCLI releases, note the wheels
   module gets bundled separately (check homebrew formula for how the
   two artifacts combine). PATH setup.

6. "Verifying installation" — `wheels --version` output format, what to
   check. `wheels info` (cross-link to app-inspection.mdx).

7. "Troubleshooting" — JAVA_HOME not set, old Java detected, PATH missing
   homebrew prefix on macOS Apple Silicon.

Verify against source:
- Check actual tap/package names in ~/GitHub/wheels-dev/homebrew-wheels
  and chocolatey-wheels.
- Java version from cli/lucli/module.json or LuCLI pom.xml.
- `wheels --version` output format by running it: what does it print?

Do NOT:
- Claim install commands that haven't been verified against the formula repos.
- Invent PATH setup steps — check what the formulas actually do.
```

- [ ] **Step 1: Subagent runs**

- [ ] **Step 2: Verify harness**

```bash
pnpm verify:docs src/content/docs/v4-0-0-snapshot/command-line-tools/installation.mdx
```

- [ ] **Step 3: Build**

- [ ] **Step 4: Commit**

```bash
git commit -m "docs(docs): cli/installation — homebrew, chocolatey, manual JAR, PATH"
```

---

## Task 4: `quick-start.mdx` — New app → first request in 90 seconds

**Files:**
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/command-line-tools/quick-start.mdx`

**Source authority:**
- `cli/lucli/Module.cfc:392` (`new`), `L466` (`create`), `L361` (`start`), `L129` (`generate`), `L222` (`migrate`)

**Subagent brief:**

```
Write the Quick Start page for the Wheels CLI.

File: web/sites/guides/src/content/docs/v4-0-0-snapshot/command-line-tools/quick-start.mdx
Frontmatter: title="Quick Start", type=reference

Target: reader has CLI installed, wants first working app in under 2 minutes.

Content:

1. "You'll ship" — one sentence: a running Wheels app with one CRUD resource.

2. Seven ordered sub-sections, each a single {test:cli} block where possible,
   fenced-bash otherwise:

   a. Create the app (`wheels new myblog` — pick flags that don't prompt).
      Fenced bash (new is interactive / stateful).
   b. cd myblog, wheels start (fenced bash — starts a server).
   c. Generate a scaffold (wheels generate scaffold Post title:string body:text).
      Use {test:cli} against an ephemeral fixture if the harness can set this up.
   d. Run the migration (wheels migrate latest).
   e. Open http://localhost:<port>/posts in your browser.
   f. Run the test that scaffold generated (wheels test --filter=posts).
   g. What next — CardGrid links to: Code Generation, Database, Testing, Dev Server.

3. "Common next steps" — two-liner each, linking to the relevant page:
   - Add authentication (Authentication Patterns in digging-deeper)
   - Configure your database (Configuration + Database)
   - Deploy (Deployment — Phase 2c)

Verify against source:
- `wheels new` flag list from Module.cfc:392-465. Don't invent flags.
- `wheels generate scaffold` field syntax from Module.cfc generate dispatch.
- Default port from `wheels start` implementation at Module.cfc:361.

Do NOT:
- Skip the {test:cli} blocks that are feasible — pick at least 2 that
  exercise real commands against an ephemeral fixture.
- Use `wheels g` short form in primary text; use full `wheels generate`.
  Mention the `g` alias once in a sidebar/callout.
```

- [ ] **Step 1: Subagent runs**

- [ ] **Step 2: Verify harness**

```bash
pnpm verify:docs src/content/docs/v4-0-0-snapshot/command-line-tools/quick-start.mdx
```
Expected: any `{test:cli}` blocks pass against ephemeral fixture.

- [ ] **Step 3: Build**

- [ ] **Step 4: Commit**

```bash
git commit -m "docs(docs): cli/quick-start — new → start → scaffold → migrate"
```

---

## Task 5: `configuration.mdx` — lucee.json, env vars, profiles

**Files:**
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/command-line-tools/configuration.mdx`

**Source authority:**
- `~/GitHub/bpamiri/LuCLI/src/main/java/org/lucee/lucli/` — lucee.json schema / profile handling
- `cli/lucli/Module.cfc:18-37` (init reads moduleConfig) + `resolveProjectRoot`
- Any WHEELS_* env vars referenced in Module.cfc

**Subagent brief:**

```
Write the Configuration page for the Wheels CLI.

File: web/sites/guides/src/content/docs/v4-0-0-snapshot/command-line-tools/configuration.mdx
Frontmatter: title="Configuration", type=reference

Content:

1. "You'll use this for" — pinning Lucee/Wheels versions, switching
   profiles (dev/test/prod), toggling verbose/timing output.

2. "lucee.json" — location (project root, auto-created), purpose, top-level
   keys. Don't invent keys — read actual LuCLI schema. Show a minimal
   example and an annotated-maximal example.

3. "Profiles" — what they are, how to create one, how to select one
   (--profile=name or equivalent flag — verify from LuCLI Java).

4. "Environment variables" — list every WHEELS_* or LUCLI_* env var that
   Module.cfc or LuCLI actually reads. Grep the sources; don't guess.
   Expected candidates (verify each): WHEELS_ENV, JAVA_HOME,
   LUCLI_HOME (if exists), WHEELS_BROWSER_CI_ENABLE (from Phase 2b-Testing).

5. "Verbose and timing" — --verbose / -v flag, --timing flag if exists.
   Verify from LuCLI Java top-level options.

6. "Per-project config vs global" — where LuCLI stores global state
   (~/.lucli/ or wherever), vs lucee.json in project.

Verify against source:
- Every config key listed must exist in the LuCLI schema.
- Every env var listed must actually be read somewhere in LuCLI Java or
  Module.cfc. Grep to prove it.

Do NOT:
- Invent config keys or env vars. Better to ship a short page than a
  fabricated long one.
```

- [ ] **Step 1: Subagent runs**
- [ ] **Step 2: Verify harness**
- [ ] **Step 3: Build**
- [ ] **Step 4: Commit**

```bash
git commit -m "docs(docs): cli/configuration — lucee.json, profiles, env vars"
```

---

## Task 6: `mcp-integration.mdx`

**Files:**
- Create: `web/sites/guides/src/content/docs/v4-0-0-snapshot/command-line-tools/mcp-integration.mdx`

**Source authority:**
- `cli/lucli/Module.cfc:617-640` (`mcp` function)
- `cli/lucli/Module.cfc:110-128` (`mcpHiddenTools`)
- `~/GitHub/bpamiri/LuCLI/src/main/java/org/lucee/lucli/cli/commands/McpCommand.java`
- Existing guidance in CLAUDE.md MCP Server section

**Subagent brief:**

```
Write the MCP Integration page.

File: web/sites/guides/src/content/docs/v4-0-0-snapshot/command-line-tools/mcp-integration.mdx
Frontmatter: title="MCP Integration", type=reference

Content:

1. "You'll use this for" — letting Claude Code / Cursor / another AI IDE
   invoke `wheels` commands deterministically.

2. "How it works" — two-sentence explanation: LuCLI's `mcp` command
   exposes any module's public functions as MCP tools over stdio JSON-RPC.
   `wheels mcp wheels` runs the wheels Module's public functions
   (minus mcpHiddenTools()) as tools.

3. "Setup" — `wheels mcp setup` generates .mcp.json + .opencode.json.
   Show generated content. Note: the exact setup flow is in Module.cfc:617
   — verify the actual generated files by reading the function or invoking
   it against a temp dir.

4. "Manual config" — raw JSON for .mcp.json if you prefer manual setup.

5. "Tools exposed" — list the Module.cfc public functions that are NOT in
   mcpHiddenTools(). From source:
     - generate, migrate, seed, test, reload, create, routes, info, analyze,
       validate, destroy, doctor, stats, notes, db, upgrade
   Hidden: mcp, d, new, console, start, stop, browser. Explain WHY each
   is hidden (stateful, interactive, side-effect-heavy).

6. "Deprecated HTTP endpoint" — per CLAUDE.md, /wheels/mcp HTTP route is
   deprecated. One paragraph + link to migration guide if one exists.

Verify against source:
- Module.cfc:110 mcpHiddenTools() contents.
- Module.cfc:617 mcp() function output.
- Run `wheels mcp setup` against a temp dir and paste the actual generated
  JSON, don't invent it.

Do NOT:
- Document tools that don't exist.
- Copy CLAUDE.md text verbatim — reword for user-facing voice.
```

- [ ] **Step 1: Subagent runs**
- [ ] **Step 2: Verify harness**
- [ ] **Step 3: Build**
- [ ] **Step 4: Commit**

```bash
git commit -m "docs(docs): cli/mcp-integration — stdio MCP server, setup, tool list"
```

---

## Tasks 7-16: Wheels Commands pages

Each task follows the same 4-step pattern:

**Per-task checklist:**

- [ ] **Step 1: Dispatch subagent** with brief (spec below per task)
- [ ] **Step 2: Verify harness**: `pnpm verify:docs src/content/docs/v4-0-0-snapshot/command-line-tools/wheels-commands/<page>.mdx`
- [ ] **Step 3: Build**: `pnpm build 2>&1 | tail -5`
- [ ] **Step 4: Commit** with message `docs(docs): cli/wheels-commands/<slug> — <imperative>`

**Subagent brief template (per task):**

```
Write the <page title> page for the Wheels CLI Reference.

File: web/sites/guides/src/content/docs/v4-0-0-snapshot/command-line-tools/wheels-commands/<page>.mdx
Frontmatter: title="<title>", type=reference

Source authority: cli/lucli/Module.cfc at line <line_range>

Content structure:

1. "You'll use this for" — 2-4 bullets.

2. One section per command covered by this page (### heading per command).
   Each command section contains:
   - Synopsis: `wheels <command> [<args>] [<flags>]`
   - Description (1-3 sentences from the function's hint or doc comment)
   - Arguments (positional) — table of name, required?, description
   - Flags (named) — table of flag, default, description
   - Example invocation in a {test:cli} block if feasible (ephemeral fixture),
     fenced bash otherwise
   - Output sample (trimmed if large)
   - Exit code / error conditions

3. "Common workflows" — 2-3 mini-recipes combining the page's commands.

4. "Related commands" — CardGrid to sibling pages.

Verify against source (CRITICAL):
- Every flag listed must exist at the given Module.cfc line range.
- Every argument must be accepted by the function's parseGeneratorArgs or
  equivalent dispatch.
- Output samples must come from actually running the command — don't
  reproduce from memory or legacy docs.

Do NOT:
- Invent flags, defaults, or exit codes.
- Use CommandBox-era concepts (ForgeBox, CommandBox Module Root, etc.).
- Link to pages in wheels-commands/ or core-commands/ that don't exist yet
  in this phase — check the plan Task list for page slugs.
```

### Task 7: `wheels-commands/creating-a-project.mdx` — `new`, `create`

**Source lines:** Module.cfc `new` at L392-465, `create` at L466-501.

Commands: `wheels new <name>`, `wheels create app <name>` (plus any `create <type>` variants).

Subagent brief additions:
- Explain the difference between `new` and `create app` (if any — verify from source).
- Cover flags: `--port`, `--db`, `--skip-*` variants that actually exist.
- Show generated directory tree (from actual output of `wheels new test`).

### Task 8: `wheels-commands/code-generation.mdx` — `generate` + all subcommands

**Source lines:** Module.cfc `generate` at L129-221. Subcommand dispatch likely in a separate service — trace from L129.

Commands: `wheels generate model|controller|scaffold|migration|route|view|property|helper|snippet|api-resource|test|app`.

Subagent brief additions:
- One H3 per subcommand type.
- Attribute syntax (`name:type`, `name:type:index`) — verify from source.
- `{test:cli}` blocks for at least `model`, `controller`, `scaffold`.
- Cross-link to `destroy` (Task 14) and `database.mdx` (Task 9) for migrations.

### Task 9: `wheels-commands/database.mdx` — `migrate`, `seed`, `db`

**Source lines:** `migrate` L222-250, `seed` L251-276, `db` L1398-1440.

Commands: `wheels migrate [latest|up|down|info]`, `wheels seed [--environment=<env>]`, `wheels db <subcommand>`.

Subagent brief additions:
- Document `wheels db` subcommands — read L1398-1440 to enumerate.
- Seed idempotency via `seedOnce()` — cross-link to Seeding guide in Basics.
- `{test:cli}` for at least `migrate info` and `migrate latest`.

### Task 10: `wheels-commands/dev-server.mdx` — `start`, `stop`, `reload`

**Source lines:** `start` L361-378, `stop` L379-391, `reload` L331-360.

Commands: `wheels start`, `wheels stop`, `wheels reload`.

Subagent brief additions:
- Port selection (default, --port flag if exists).
- Profile awareness (does `start` respect the current profile? Verify).
- Reload vs restart — `reload` triggers framework reload URL, does not restart JVM.
- Fenced bash (not `{test:cli}`) since these are stateful server operations.

### Task 11: `wheels-commands/testing.mdx` — `test`, `browser`

**Source lines:** `test` L277-330, `browser` L1469+.

Commands: `wheels test [--filter] [--db] [--reporter] [--verbose] [--ci] [--core]`, `wheels browser install`.

Subagent brief additions:
- Flags exhaustively from Module.cfc:277-330. Note from Phase 2b-Testing: `--format=json` is phantom, `--reporter` is parsed but not consumed.
- Cross-link heavily to Testing section pages for HOW to write tests — this page only covers invocation.
- `wheels browser install` (no colon) — verify from L1469+.

### Task 12: `wheels-commands/app-inspection.mdx` — `routes`, `info`, `stats`, `notes`, `doctor`

**Source lines:** `routes` L502-526, `info` L527-616, `stats` L1285-1345, `notes` L1346-1397, `doctor` L1212-1284.

Subagent brief additions:
- `info` is the fabricated Phase 0 page — document it honestly: no `--json` or `--quiet` flags. Writes to stderr (verify).
- `routes` output format — table vs list, which columns.
- `stats` — what it counts; `notes` — what it searches for (TODOs, FIXMEs?).

### Task 13: `wheels-commands/code-quality.mdx` — `analyze`, `validate`

**Source lines:** `analyze` L1001-1075, `validate` L1076-1113.

Subagent brief additions:
- Difference between `analyze` and `validate`.
- `analyze` target param (all, code, performance) — verify from L1001+.

### Task 14: `wheels-commands/scaffold-cleanup.mdx` — `destroy`, `d`

**Source lines:** `destroy` L1114-1200, `d` L1201-1211.

Subagent brief additions:
- Every generator type that has a corresponding destroy.
- `d` alias — note it exists, don't duplicate the content; just `wheels d` = `wheels destroy`.

### Task 15: `wheels-commands/console-and-repl.mdx` — `console`

**Source lines:** `console` L641-1000.

Subagent brief additions:
- App context loaded (vs LuCLI's `repl` which doesn't load a Wheels app).
- What's available at the prompt: `model()`, `service()`, request/session scopes (verify).
- How to exit.
- Cross-link to `core-commands/cfml-execution.mdx` for the no-app-context REPL.

### Task 16: `wheels-commands/upgrade.mdx` — `upgrade`

**Source lines:** `upgrade` L1441-1468.

Subagent brief additions:
- What it upgrades — framework version only? CLI? Both?
- Prerequisites (git clean, backup?).
- Rollback path.

---

## Tasks 17-21: LuCLI Core Commands pages

Same 4-step pattern, same subagent brief template. Source authority is the Java `@Command` classes at `~/GitHub/bpamiri/LuCLI/src/main/java/org/lucee/lucli/cli/commands/`.

### Task 17: `core-commands/server.mdx`

**Source:** `ServerCommand.java` + `ServerMonitorCommandImpl.java` + any picocli-subcommanded classes.

Commands: `wheels server`, `wheels server start`, `server stop`, `server status`, `server restart`, `server list`, `server log`, `server info`.

Subagent brief additions:
- Each subcommand gets an H3.
- Engine version selection, port assignment, logs dir — verify from @Option annotations.
- Distinguish `wheels server start` from `wheels start` (the Module's).

### Task 18: `core-commands/cfml-execution.mdx`

**Source:** `CfmlCommand.java`, `RunCommand.java`, `ReplCommand.java`.

Commands: `wheels cfml <expression>`, `wheels run <script>`, `wheels repl`.

Subagent brief additions:
- Three execution modes side by side: inline, script, interactive.
- Note this is distinct from `wheels console` (which loads a Wheels app).
- `{test:cli}` for `wheels cfml` with a trivial expression.

### Task 19: `core-commands/system-and-secrets.mdx`

**Source:** `SystemCommand.java`, `SecretsCommand.java`, `DaemonCommand.java`.

Commands: `wheels system [inspect|paths|clean|backup]`, `wheels secrets`, `wheels daemon`.

Subagent brief additions:
- `system paths` — where LuCLI stores state.
- `secrets` — briefly, cross-link to any deeper secrets doc.
- `daemon` — mention JSON / LSP modes from LuCLI README.

### Task 20: `core-commands/modules-and-deps.mdx`

**Source:** `ModulesCommand.java` + all `Modules*CommandImpl.java`, `DepsCommand.java` + `deps/*CommandImpl.java`.

Commands: `wheels modules [list|add|install|update|init|run|help]`, `wheels deps [install|add|prune]`.

Subagent brief additions:
- How the Wheels Module itself is registered (callback to index.mdx explanation).
- When to use `modules install` vs `deps install`.

### Task 21: `core-commands/ai-and-completion.mdx`

**Source:** `AiCommand.java`, `CompletionCommand.java`.

Commands: `wheels ai`, `wheels completion bash|zsh`.

Subagent brief additions:
- `completion` — how to install the generated script per shell.
- `ai` — briefly document what it does (Lucee AI endpoints per LuCLI README).
- Skip: `versions-list`, `parrot`, `xml` (experimental / internal).

---

## Task 22: Sidebar + landing page integration

**Files:**
- Modify: `web/sites/guides/src/sidebars/v4-0-0-snapshot.json`
- Modify: `web/sites/guides/src/content/docs/v4-0-0-snapshot/index.mdx` (if CLI link exists on site home)

- [ ] **Step 1: Add CLI Reference sidebar section**

Sidebar JSON entry shape:
```json
{
  "label": "CLI Reference",
  "items": [
    {"label": "Overview", "link": "/v4-0-0-snapshot/command-line-tools/"},
    {"label": "Installation", "link": "/v4-0-0-snapshot/command-line-tools/installation/"},
    {"label": "Quick Start", "link": "/v4-0-0-snapshot/command-line-tools/quick-start/"},
    {"label": "Configuration", "link": "/v4-0-0-snapshot/command-line-tools/configuration/"},
    {"label": "MCP Integration", "link": "/v4-0-0-snapshot/command-line-tools/mcp-integration/"},
    {
      "label": "Wheels Commands",
      "items": [
        {"label": "Creating a Project", "link": "/v4-0-0-snapshot/command-line-tools/wheels-commands/creating-a-project/"},
        {"label": "Code Generation", "link": "/v4-0-0-snapshot/command-line-tools/wheels-commands/code-generation/"},
        {"label": "Database", "link": "/v4-0-0-snapshot/command-line-tools/wheels-commands/database/"},
        {"label": "Dev Server", "link": "/v4-0-0-snapshot/command-line-tools/wheels-commands/dev-server/"},
        {"label": "Testing", "link": "/v4-0-0-snapshot/command-line-tools/wheels-commands/testing/"},
        {"label": "App Inspection", "link": "/v4-0-0-snapshot/command-line-tools/wheels-commands/app-inspection/"},
        {"label": "Code Quality", "link": "/v4-0-0-snapshot/command-line-tools/wheels-commands/code-quality/"},
        {"label": "Scaffold Cleanup", "link": "/v4-0-0-snapshot/command-line-tools/wheels-commands/scaffold-cleanup/"},
        {"label": "Console & REPL", "link": "/v4-0-0-snapshot/command-line-tools/wheels-commands/console-and-repl/"},
        {"label": "Upgrade", "link": "/v4-0-0-snapshot/command-line-tools/wheels-commands/upgrade/"}
      ]
    },
    {
      "label": "Core Commands (LuCLI)",
      "items": [
        {"label": "Server", "link": "/v4-0-0-snapshot/command-line-tools/core-commands/server/"},
        {"label": "CFML Execution", "link": "/v4-0-0-snapshot/command-line-tools/core-commands/cfml-execution/"},
        {"label": "System & Secrets", "link": "/v4-0-0-snapshot/command-line-tools/core-commands/system-and-secrets/"},
        {"label": "Modules & Deps", "link": "/v4-0-0-snapshot/command-line-tools/core-commands/modules-and-deps/"},
        {"label": "AI & Completion", "link": "/v4-0-0-snapshot/command-line-tools/core-commands/ai-and-completion/"}
      ]
    }
  ]
}
```

Place the CLI Reference section after `Testing` and before `Deployment` (if Deployment exists yet) or before `Upgrading`/`Contributing` sections.

- [ ] **Step 2: Verify all sidebar links resolve**

```bash
cd web/sites/guides
pnpm build 2>&1 | tee /tmp/build.log | tail -20
grep -i "broken\|not found\|error" /tmp/build.log
```
Expected: no broken link errors. All ~20 CLI links resolve to pages built in Tasks 2-21.

- [ ] **Step 3: Check site home for any CLI references**

```bash
grep -n "cli-reference\|command-line-tools" web/sites/guides/src/content/docs/v4-0-0-snapshot/index.mdx
```
If a CLI link exists on home, point it at `command-line-tools/` instead of `cli-reference/`.

- [ ] **Step 4: Commit**

```bash
git add web/sites/guides/src/sidebars/v4-0-0-snapshot.json web/sites/guides/src/content/docs/v4-0-0-snapshot/index.mdx
git commit -m "docs(docs): cli — sidebar + home integration for command-line-tools"
```

---

## Task 23: `.ai/` CLI + MCP audit

**Files:**
- Scan: `.ai/wheels/cli/` (if exists)
- Scan: `.ai/wheels/mcp/` (if exists)
- Scan: `.ai/wheels/` for stragglers mentioning CLI commands

- [ ] **Step 1: Inventory remaining .ai/ CLI content**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/lucid-thompson-b8c121
find .ai -name "*.md" | xargs grep -l -i "wheels \(generate\|migrate\|test\|start\|stop\|info\|routes\|doctor\|console\|repl\)" 2>/dev/null
ls -la .ai/wheels/cli/ 2>/dev/null
ls -la .ai/wheels/mcp/ 2>/dev/null
```

- [ ] **Step 2: Per file, decide keep / delete / merge**

For each file found:
- If fully superseded by a `command-line-tools/` page: `git rm`
- If contains info not in any user doc: move unique content into appropriate `command-line-tools/` page via Edit, then `git rm`
- If reference-only (e.g., internal architecture notes): leave it

- [ ] **Step 3: Verify no orphaned links**

```bash
grep -rn "\.ai/wheels/cli\|\.ai/wheels/mcp" web/sites/guides/src/ 2>/dev/null
```
Expected: no results.

- [ ] **Step 4: Commit**

```bash
git add -A .ai/ web/sites/guides/
git commit -m "docs(docs): cli/.ai audit — consolidate into command-line-tools/"
```

---

## Task 24: Full harness + build + Phase 2b-CLI report

**Files:**
- Create: `docs/superpowers/plans/2026-04-20-guides-rewrite-phase-2b-cli-report.md`

- [ ] **Step 1: Full harness run**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/lucid-thompson-b8c121/web/sites/guides
export JAVA_HOME=/opt/homebrew/Cellar/openjdk@21/21.0.8/libexec/openjdk.jdk/Contents/Home
pnpm verify:docs src/content/docs/v4-0-0-snapshot/command-line-tools/**/*.mdx src/content/docs/v4-0-0-snapshot/command-line-tools/*.mdx 2>&1 | tee /tmp/phase2b-cli-verify.log | tail -30
```
Expected: all blocks pass. Note block count for report.

- [ ] **Step 2: Full build**

```bash
pnpm build 2>&1 | tee /tmp/phase2b-cli-build.log | tail -20
```
Expected: success. Note total page count for report.

- [ ] **Step 3: Write report**

Use prior phase reports as template (`docs/superpowers/plans/2026-04-20-guides-rewrite-phase-2b-testing-report.md`). Structure:
- Summary (commit count, page count, block count)
- Per-task notes (drift caught per page, notable corrections)
- Framework gaps opened (anything new discovered)
- Framework gaps closed (should include #11 from Task 0)
- Known issues / carryover to Phase 2c
- Ready-to-review link to PR

- [ ] **Step 4: Commit report**

```bash
git add docs/superpowers/plans/2026-04-20-guides-rewrite-phase-2b-cli-report.md
git commit -m "docs(plan): phase 2b-cli report"
```

- [ ] **Step 5: Push**

```bash
git push origin claude/lucid-thompson-b8c121
```

---

## Task 25: Final code review

- [ ] **Step 1: Dispatch `pr-review-toolkit:code-reviewer` subagent**

```
Agent call:
- subagent_type: pr-review-toolkit:code-reviewer
- Focus: the full Phase 2b-CLI diff (Tasks 0-24 commits)
- Prompt includes:
  - Branch: claude/lucid-thompson-b8c121
  - Base: Phase 2b-Testing head `8a814d2bd`
  - Per-task source-authority map (Module.cfc line ranges, Java class names)
  - Red flags to watch for:
    a. Any flag documented that doesn't exist in source
    b. Any command documented that's not in Module.cfc or LuCLI @Command
    c. CommandBox-era terminology (ForgeBox, CommandBox Module Root, etc.)
    d. Fabricated exit codes or output streams
    e. Broken cross-page links
```

- [ ] **Step 2: Triage findings**

For each finding:
- Confirmed issue → fix inline in a follow-up commit
- False positive → respond in review thread
- Out of scope → log in Phase 2c carryover

- [ ] **Step 3: Ship fix commit(s)**

```bash
git commit -m "docs(docs): cli/review-fixes — <scope>"
git push
```

- [ ] **Step 4: Update PR description with Phase 2b-CLI summary**

```bash
gh pr edit 2169 --body-file - <<'EOF'
...updated summary with CLI Reference section complete...
EOF
```

---

## Unresolved questions

- Does `wheels server` (LuCLI) and `wheels start` (Module) conflict or cleanly compose? Tasks 10 and 17 need to establish which owns the Wheels dev server loop. Expected: `wheels start` wraps `wheels server start` with Wheels-specific profile + app bootstrap. Confirm in Task 10.
- Is `wheels mcp wheels` the documented invocation pattern or can users run `wheels mcp` alone from within a wheels project? Check Module.cfc:617 for the positional-arg handling. Task 6 resolves.
- Homebrew tap name: `wheels-dev/wheels` vs `wheels-dev/tap`? Task 3 verifies against the formula repo.
- Does `wheels upgrade` exist in a working state, or is it a stub? Task 16 verifies; if stub, document as "planned" or remove from scope.
- Phase 0 sample `cli-reference/index.mdx` — is its content worth preserving any of into `command-line-tools/index.mdx`? Read once in Task 1 before deleting.
