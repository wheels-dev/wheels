# Phase 2b-CLI Implementation Report

**Plan:** `2026-04-20-guides-rewrite-phase-2b-cli.md`
**Branch:** `claude/lucid-thompson-b8c121`
**PR:** #2169 (draft)
**Completion date:** 2026-04-20

---

## Summary

20 CLI reference content pages authored from scratch, source-verified against `cli/lucli/Module.cfc` + LuCLI Java sources + homebrew formula + Lucee AI engines. Two infrastructure pages (sidebar + `.ai/` audit) consolidated with the content work. 23 total commits on the phase.

**Deliverables:**
- 5 top-level pages: index, installation, quick-start, configuration, mcp-integration
- 10 wheels-commands pages: creating-a-project, code-generation, database, dev-server, testing, app-inspection, code-quality, scaffold-cleanup, console-and-repl, upgrade
- 5 core-commands pages (LuCLI): server, cfml-execution, system-and-secrets, modules-and-deps, ai-and-completion
- 1 sidebar update adding all 20 pages under a structured "CLI Reference" entry
- 8 `.ai/` files deleted (`.ai/wheels/cli/**`, `.ai/wheels/mcp/**`) — superseded by the new pages

**Final build:** 330 pages (up from 310 baseline after Task 1 cleanup).

**`{test:cli}` coverage:** 8 tagged blocks across 3 pages (app-inspection.mdx, cfml-execution.mdx, modules-and-deps.mdx, code-quality.mdx). All passing. Served as the first durable `{test:cli}` blocks on Phase 2b-CLI content — earlier phases relied heavily on `{test:compile}`.

---

## Commit log (23 content commits)

| # | SHA | Task | Page / action |
|---|-----|------|---------------|
| 1 | `54318386a` | 1 | Retire Phase 0 cli-reference, seed command-line-tools skeleton |
| 2 | `5fe71565...` | 2 | `cli/index` — two-surface landing page |
| 3 | `fbb91fa31` | 3 | `cli/installation` — homebrew, chocolatey, manual JAR |
| 4 | `de19032eb` | 4 | `cli/quick-start` — new, start, scaffold, migrate |
| 5 | `f6c33ef8e` | 5 | `cli/configuration` — lucee.json, profiles, env vars |
| 6 | `edcc0d531` | 6 | `cli/mcp-integration` — stdio server, setup, tool list |
| 7 | `973a59890` | 7 | `cli/creating-a-project` — wheels new + create reference |
| 8 | `2957422cc` | 8 | `cli/code-generation` — all generate subcommands |
| 9 | `893750240` | 9 | `cli/database` — migrate, seed, db utilities |
| 10 | `d074588f8` | 10 | `cli/dev-server` — start, stop, reload |
| 11 | `3aab007cf` | 11 | `cli/testing` — wheels test + browser install |
| 12 | `ff0c9d0a1` | 12 | `cli/app-inspection` — routes, info, stats, notes, doctor |
| 13 | `46db5a139` | 13 | `cli/code-quality` — analyze + validate |
| 14 | `6b735a93d` | 14 | `cli/scaffold-cleanup` — destroy + d alias |
| 15 | `fdc88b491` | 15 | `cli/console-and-repl` — interactive Wheels context |
| 16 | `15d6305d0` | 16 | `cli/upgrade` — framework version migration |
| 17 | `faff4a32e` | 17 | `cli/core/server` — LuCLI server command group |
| 18 | `3e0cb2639` | 18 | `cli/core/cfml-execution` — cfml, run, repl |
| 19 | `27955abaa` | 19 | `cli/core/system-and-secrets` — system, secrets, daemon |
| 20 | `687eb5538` | 20 | `cli/core/modules-and-deps` — modules + project deps |
| 21 | `7f29a0871` | 21 | `cli/core/ai-and-completion` — ai + shell completion |
| 22 | `ca7036af3` | 22 | cli — sidebar integration (5 top + 10 wheels + 5 core) |
| 23 | `8a958bf0e` | 23 | cli/.ai — drop cli/ and mcp/ superseded |

---

## Drift caught vs. the plan (source-verification wins)

Each content task verified claims against actual source, catching plan-level drift before it shipped. Notable corrections:

### API inventory
- **`wheels create`, `wheels new`, `wheels generate app` — all three are aliases for the same dispatch.** (Task 7)
- **`wheels generate` has 13 subcommands, not 11.** Found: `app`, `model`, `controller`, `view`, `migration`, `scaffold`, `api-resource`, `route`, `test`, `property`, `helper`, `snippets` (plural, not `snippet`), `admin`. Plan listed "snippet" (singular) which doesn't exist. (Task 8)
- **`wheels db` subcommands are `reset`, `status`, `version` — not `create`/`drop`/`refresh`/`shell`.** (Task 9)
- **`wheels migrate up/down` take no step count argument.** (Task 9)
- **`wheels destroy` supports only 4 types** (`resource`, `model`, `controller`, `view`), not all 12 that `generate` covers. (Task 14)
- **`wheels destroy` argument order is `<name> [type]`, not `<type> <name>`.** (Task 14)
- **`wheels upgrade` is a read-only breakage scanner** with only `check` subcommand + `--to=<version>` flag. Not an actual upgrader; actual framework swap is still manual. (Task 16)
- **`wheels browser` has 2 subcommands: `install` and `test`.** Plan assumed `install` only. (Task 11)
- **`wheels server` (LuCLI core) has 18 subcommands**, not 7. (Task 17)
- **`wheels console` special commands are slash-prefixed (`/exit`, `/help`, `/env`, etc.), not dot-prefixed.** Plan assumed `.exit`. (Task 15)
- **`wheels ai` is a substantial AI front-end with 8 provider types** (openai/claude/gemini/copilot/deepseek/grok/ollama/perplexity). Not a stub. (Task 21)

### Fabricated-flag catches
- **`wheels info` has no `--json` or `--quiet` flags.** The Phase 0 sample had invented these. Page now documents "no flags; writes to stderr; exits 0". (Task 12)
- **`wheels analyze` has no `--verbose` flag.** Dropped it from the workflows section the task template prescribed. (Task 13)
- **`wheels validate` takes no args at all.** (Task 13)
- **`wheels mcp setup` does NOT exist.** The CLAUDE.md aspirational line was wrong. Page now documents manual `.mcp.json` setup honestly. (Task 6)

### Documented for the first time
- **`wheels routes/migrate/seed/db` all require a running server** (HTTP-dispatch to `/wheels/cli` or `/wheels/ai`). Documented prominently so users aren't confused by "no command found" without a server. (Tasks 9, 12)
- **`wheels console` requires a running server** (POSTs to `/wheels/console/eval`). (Task 15)
- **Dry-run-by-default safety pattern**: `system clean`, `backup prune`, `backup restore`, `db reset`, and `destroy` all require explicit `--force` to apply. (Tasks 14, 19)
- **LuCLI 0.3.7's profile system** already ships with `WheelsProfile` + `DefaultProfile` wired via binary-name-activated `CliProfile.forBinaryName()`. `WheelsProfile` sets `homeDirName() = ".wheels"`. (Task 5, Task 15)
- **`wheels secrets`** secrets live at `~/.lucli/secrets/local.json`; passphrase from `LUCLI_SECRETS_PASSPHRASE` env or interactive prompt; no OS keychain integration. (Task 19)
- **`wheels deps`** reads/writes `lucee.json` and maintains `lucee-lock.json`; influences `LUCEE_EXTENSIONS` env on server start. (Task 20)
- **`wheels completion`** supports bash/zsh/md; no fish/powershell. Generated zsh script is "bash + bashcompinit" glue — not a native zsh completer. Installed script still hard-codes `lucli` references internally. (Task 21)

### Chocolatey + homebrew reality-check
- **Chocolatey v2 (LuCLI-based) is NOT yet on the public feed.** Public package at `community.chocolatey.org/packages/wheels` is still v1.0.6 CommandBox-based. Page marks Windows "coming soon" honestly. (Task 3)
- **Formula JAVA_HOME fix landed during Phase 2b-CLI execution.** OS-branched for macOS (`opt_libexec/openjdk.jdk/Contents/Home`) vs Linux (`opt_libexec` direct). Also the wrapper now exports `LUCLI_HOME=$HOME/.wheels` eliminating the need for a CI override. (out-of-scope for the plan but wrapped in during CI debugging)

---

## Shared conventions applied

- Frontmatter `type: reference` on every page (vs Phase 2b-Testing's `howto`); a new type for CLI docs that worked cleanly with Starlight.
- "You'll use this for" opening on every page.
- "Related commands" CardGrid closing on every page.
- Headings at `###` max (some H4 for sub-subcommands, used sparingly).
- Second-person voice throughout.
- "the CLI" or `wheels` — never "Wheels CLI" as a proper noun.
- LuCLI named explicitly only on the 4 pages where it's the natural subject: `index.mdx`, `configuration.mdx`, `mcp-integration.mdx`, and all 5 `core-commands/` pages.
- Fenced `bash` for stateful/destructive commands; `{test:cli}` reserved for read-only commands safe in a fresh fixture.

---

## Known issues / carryover

### Framework gap #11 — LuCLI parallel-spawn race (DEFERRED, not closed)

**Symptom:** `Can't cast String [] to a value of type [Struct]` when `lucee.json` is written concurrently by parallel LuCLI processes.

**State during Phase 2b-CLI:**
- Hit once during Task 12 `{test:cli}` execution — retry succeeded.
- Hit once during Task 24 full-harness verify — retry succeeded.
- All 8 `{test:cli}` blocks pass on retry.

**Risk for CI:** moderate. Current CI has `continue-on-error: true` on verify steps (see docs-verify.yml), so a single flake doesn't block the build. When the harness eventually runs at scale (Phase 2c Deployment + full re-run pre-merge), gap #11 may surface more often.

**Next steps (outside Phase 2b-CLI scope):**
- Fix LuCLI upstream: make `lucee.json` write atomic (write-to-tmp + rename).
- OR serialize the `{test:cli}` driver's per-fixture-dir spawns in `web/sites/guides/scripts/verify-docs/drivers/cli.mjs`.

### Node 22 test-runner spawn ENOENT (WORKAROUND in place)

Node 22's `--test` worker spawn returns ENOENT on some child-process calls. Captured in a spawn_task for upstream investigation. `continue-on-error: true` in `docs-verify.yml` keeps CI green; harness unit tests pass locally. Not a Phase 2b-CLI content issue.

### Homebrew auto-update bot (FIX PENDING)

A regression in the formula auto-update workflow briefly set `MODULE_VERSION = ""` in homebrew-wheels master. Fixed ad-hoc. Defensive guards added by user in a follow-up PR (`peter/fix-auto-update-guards` branch on homebrew-wheels).

### LuCLI argv[0]-aware profile (TRACKED UPSTREAM)

User filed a task for LuCLI to auto-detect binary name from `ProcessHandle` so `wheels` and `lucli` coexist without requiring the wrapper to pass `-Dlucli.binary.name=wheels`. Not blocking; current profile system works via explicit system property.

### Placeholder cross-links

A few CardGrid entries link to pages that don't exist yet (e.g., `./upgrade/` was created in Task 16 but referenced by earlier-task cards; `wheels-commands/` and `core-commands/` directory indexes don't exist yet). Build still passes because Starlight doesn't error on missing sibling links; they just 404 on click. Phase 2c or a targeted follow-up could create directory-level landing pages.

### Deployment cross-links (Phase 2c carryover)

Several pages reference deployment docs as "coming in Phase 2c" — acceptable for now since Phase 2c is explicitly next.

---

## Metrics

| Metric | Value |
|--------|-------|
| Content pages shipped | 20 |
| Content + integration commits | 23 |
| Total branch commits (including earlier phases) | 118 |
| Baseline page count | 310 |
| Final page count | 330 |
| `{test:cli}` blocks shipped | 8 |
| `{test:compile}` blocks shipped | 0 (CLI content is prose + bash, minimal CFML) |
| `.ai/` files consolidated | 8 |
| Tasks fully completed | 24 / 26 (Task 0 deferred, Task 25 follows) |
| Wall time | ~2 sessions (inline + subagent-driven hybrid) |

---

## Next steps

1. **Task 25 (final code review)** — dispatch `pr-review-toolkit:code-reviewer` on the Phase 2b-CLI diff. Capture fixes in a `review-fixes` commit.
2. **Phase 2c planning** — Deployment (Kamal), Contributing, Upgrading, Glossary, final `.ai/` audit. Roughly 10-15 pages.
3. **Merge to develop** — once Phase 2c completes + full review signs off. Currently the entire v4 guides rewrite (118 commits) lives on `claude/lucid-thompson-b8c121`.
