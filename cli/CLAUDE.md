# CLAUDE.md — Wheels CLI (`cli/`)

This file guides Claude Code when working in the Wheels CLI directory.

## What This Is

The Wheels CLI is the **LuCLI runtime rebranded as `wheels`** — it is NOT a CommandBox
module. There is no separate `lucli` binary on a normal install; `libexec/wheels` IS the
LuCLI binary, name-routed to the `wheels` module via its `$0` basename (`-Dlucli.binary.name=wheels`).
Install is via Homebrew / Scoop / apt / yum (see `tools/distribution-drafts/` and the
sibling distribution repos) — **not** `box install`.

> Anything in older docs mentioning `box`, `CommandBox`, `box install wheels-cli`, `/cli/src/`,
> `wheels init`, or `wheels g app` predates the LuCLI rebrand and is wrong. Scaffold with
> `wheels new <name>`.

## Code Map

```
cli/lucli/
  Module.cfc          The CLI itself. Each PUBLIC function is a subcommand
                      (generate, g, migrate, seed, test, reload, start, stop, new,
                      create, routes, info, mcp, console, analyze, validate, destroy, d,
                      doctor, deploy, packages, stats, notes, db, upgrade, browser,
                      version, showHelp). Private functions are internal helpers.
  module.json         Module manifest (name=wheels, main=Module.cfc).
  ARCHITECTURE.md     Deep architectural reference — read this first.
  services/           Service objects the subcommands delegate to:
                        ArgSpec.cfc        typed, declarative argument/flag parser
                        Scaffold.cfc       generate/scaffold/api-resource
                        CodeGen.cfc        model/controller/view/test generation
                        Templates.cfc      template rendering
                        MigrationRunner.cfc, Analysis.cfc, Doctor.cfc, Stats.cfc,
                        Destroy.cfc, ServerRegistry.cfc, ReleaseChannel.cfc,
                        UpdateChecker.cfc, Helpers.cfc, SemVer.cfc, …
                        deploy/            Kamal-compatible deploy port (DeployMainCli +
                                           App/Proxy/Build/Registry/Lock/Prune/Secrets/Server CLIs,
                                           config/, secrets/ adapters)
                        packages/          package registry/install (Installer, Registry, …)
  templates/          Code-generation templates (app scaffold, codegen, app tests).
  tests/specs/        CLI test suite (commands/, services/, integration/, deploy/, packages/).
```

## Argument Parsing

Subcommands parse args via the **ArgSpec service** (`services/ArgSpec.cfc`) — a typed,
declarative spec builder (`.option()`, `.flag()`, `.parse()`). Build the command's ArgSpec
to enumerate its real flags/options/defaults. (Historical note: the legacy `getArgs()`
argv round-trip was removed in the #2861/#2875 ArgSpec migration.)

LuCLI reserves some tokens before the module sees them: `--help`/`-h`, bare `help`,
`--verbose`/`-v`, `--version`, and verbs like `run`/`install`/`mcp` and nested `server`/`secrets`.
Be aware these can be intercepted by the runtime/launcher rather than reaching `Module.cfc`.

## Running & Testing

- Run a command against a checkout: the CLI loads the module from `$LUCLI_HOME/modules/wheels`.
- CLI test suite: `bash tools/test-cli-local.sh` (boots a server, hits `/wheels/cli/tests`),
  or the in-server endpoint `/wheels/cli/tests?format=json`. End-to-end lifecycle smoke:
  `tools/test-cli-e2e.sh`. Deploy verb smoke (dry-run): `tools/deploy-verb-smoke.sh`.
- Build/distribution: `tools/build/scripts/build-cli.sh` packages the module; the Homebrew/
  Scoop/apt launchers stage `libexec/wheels` + the module zip and generate the `wheels` wrapper.

## Code Style

- **Language**: CFML. Components, CamelCase names. Internal helpers use a `$` prefix and
  must be `public` only when they need to be reachable as mixins/specs — otherwise keep them
  `private` so they don't surface as MCP tools.
- **Cross-engine**: the CLI runs on the bundled Lucee; still avoid the engine traps in the
  root `CLAUDE.md` (e.g. `(.+)` matching newlines in `reFind` — use `[^\r\n]+`).
- **Error handling**: try/catch with actionable messages; throw typed errors for usage
  failures so the runtime maps them to a non-zero exit.
- **Code generation**: follow existing template patterns; strip CFML comments before any
  source-scanning (anti-pattern #14).

## MCP

`wheels mcp wheels` launches the stdio MCP server. Tools are auto-discovered from `Module.cfc`
public functions; stateful/interactive commands are hidden via `mcpHiddenTools()`. There is
no `wheels mcp setup` command — write `.mcp.json` manually. See the root `CLAUDE.md`
"CLI / MCP" section and `web/.../command-line-tools/mcp-integration` for details.

## Things to remember
- Don't add the Claude signature to commit messages.
- Don't add the Claude signature to PR reviews.
