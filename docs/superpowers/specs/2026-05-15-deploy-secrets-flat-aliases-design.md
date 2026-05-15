# Design: `wheels deploy secrets` flat aliases (issue #2697)

**Status:** approved
**Date:** 2026-05-15
**Authors:** Peter Amiri
**Related:** [#2697](https://github.com/wheels-dev/wheels/issues/2697), prior art [#2677](https://github.com/wheels-dev/wheels/issues/2677)/[#2690](https://github.com/wheels-dev/wheels/pull/2690), [#2674](https://github.com/wheels-dev/wheels/issues/2674)/[#2691](https://github.com/wheels-dev/wheels/pull/2691)

## Problem

`wheels deploy secrets <verb>` (fetch/extract/print) never reaches the deploy
dispatcher. The shell user gets LuCLI's generic secrets help output instead.

LuCLI's picocli root registers `secrets` as a top-level subcommand with its own
verb tree (init / set / list / rm / get / provider). When the user types
`wheels deploy secrets fetch`, picocli intercepts `secrets` before the
`deploy()` switch at `cli/lucli/Module.cfc:1966` can dispatch on it. The
nested `case "secrets":` branch is therefore reachable only via MCP or direct
programmatic invocation — not from the shell.

Identical shape to issue #2677 (`server` collision, fixed via flat aliases in
#2690) and #2674 (`--version` collision, fixed via `--release` alias in #2691).

## Fix

Add three flat aliases to the `deploy()` dispatcher at the top level (sibling
to `bootstrap`/`exec`):

| Flat alias | Dispatches to | Positional consumption |
|---|---|---|
| `wheels deploy fetch-secrets [KEY...]` | `DeploySecretsCli.fetch` | `opts.keys = positional[2..]` |
| `wheels deploy extract-secrets [KEY]` | `DeploySecretsCli.extract` | `opts.key = positional[2] ?? ""` |
| `wheels deploy print-secrets` | `DeploySecretsCli.print` | none |

Flag parsing (`--adapter`, `--from`, `--account`, `--destination`) is already
handled by `DeployArgsParser.cfc` — no parser changes needed.

The existing `case "secrets":` branch is **retained unchanged** for MCP and
programmatic callers (same treatment as `case "server":`).

## Naming choice

Verb-noun (`fetch-secrets`) over bare verb (`fetch`). Three reasons:

1. **Namespace safety.** `fetch` and `print` are generic enough that future
   deploy subcommands could legitimately claim them (image pull, log print).
2. **Discoverability.** The three secrets verbs sort adjacently in
   `wheels deploy --help` and in alphabetized command lists.
3. **Pattern match.** Mirrors the bot's fix sketch on the issue and the
   conceptual mapping is obvious for users who know the nested form.

The trade-off is verbosity — `fetch-secrets` is longer than `fetch` — but
matches the `kebab-case` convention LuCLI already uses for multi-word verbs.

## Tests

Extend `cli/lucli/tests/specs/commands/DeployCommandSpec.cfc` (the existing
`#2677` regression spec) with a new `describe` block per flat alias:

- `wheels deploy fetch-secrets` — dispatches with positional keys, throws
  `UnknownAdapter` when `--adapter` is missing.
- `wheels deploy extract-secrets` — dispatches with positional key, returns
  the matched value from `--from` block, returns empty when key is missing.
- `wheels deploy print-secrets` — dispatches to `DeploySecretsCli.print`, no
  crash on missing `.kamal/secrets`.
- Regression: legacy `case "secrets":` still routes when called directly
  (MCP / programmatic path).

The existing `DeploySecretsCliSpec.cfc` already covers the CLI methods
themselves — these new tests are pure dispatcher routing.

## Docs & changelog

- **CLAUDE.md** — extend the existing "critical gotchas" §7 entry about
  `wheels deploy server` collision to also mention the `secrets` collision and
  the three new aliases. Update the canonical CLI form note in the
  `wheels deploy secrets` quick-reference (§ Subcommands) to point at the flat
  aliases.
- **v4-0-1-snapshot docs** — add a `:::caution` block to each of the four
  nested-form pages (`secrets/{index,fetch,extract,print}.mdx`) recommending
  the flat alias as the canonical CLI form, mirroring the treatment applied to
  `server/bootstrap.mdx` in #2690.
- **v4-0-0 docs** — left untouched (frozen).
- **CHANGELOG.md** — add an entry under `[Unreleased] § Fixed`.

## Non-goals

- **Args parser changes.** The pre-existing `--key=` documented form
  (`wheels deploy secrets extract --key=B`) doesn't actually parse — the flag
  is stripped but `DeployArgsParser` has no `--key` branch. That's a separate
  bug, out of scope for this PR.
- **MCP surface.** The nested `case "secrets":` continues to work; MCP /
  programmatic callers are unaffected.
- **Other shadowed commands.** If LuCLI registers other top-level commands
  that shadow `deploy` subcommands, they're separate issues with their own
  flat aliases.

## Risks

- **Picocli boundary unchanged.** The flat aliases sidestep the collision; they
  don't fix picocli's eager subcommand resolution. If LuCLI later registers
  a top-level `fetch-secrets`/`print-secrets`/`extract-secrets` command, the
  collision reappears — unlikely, given the verb-noun specificity.
- **Help-output inconsistency.** Help text from `wheels deploy --help` will
  list both the legacy `secrets <verb>` form and the flat aliases. The doc
  caution blocks call this out explicitly.

## Acceptance criteria

- [ ] `wheels deploy fetch-secrets --adapter=op KEY1 KEY2` returns KEY=VALUE lines from the adapter (verified locally; CI test covers dispatch).
- [ ] `wheels deploy extract-secrets KEY --from="A=1\nB=2"` returns the matched value (verified locally; CI test covers dispatch).
- [ ] `wheels deploy print-secrets` prints resolved `.kamal/secrets` or empty.
- [ ] `wheels deploy secrets <verb>` still works when invoked via MCP / programmatically (regression guard test).
- [ ] CLAUDE.md §7 mentions the `secrets` collision and the flat aliases.
- [ ] v4-0-1-snapshot doc pages have `:::caution` blocks.
- [ ] `CHANGELOG.md [Unreleased] § Fixed` has an entry.
- [ ] Local `bash tools/test-local.sh` passes; `DeployCommandSpec` green.

## Unresolved questions

None — pattern, naming, and scope all follow the established #2690 / #2691
precedent.
