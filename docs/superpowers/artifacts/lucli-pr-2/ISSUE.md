# Proposal: `lucli parse <file-or-expression> [--json]` — parse-only CFML check

## Summary

Add a new subcommand, `lucli parse`, that reports whether a given CFML
file or expression would compile — without executing it, without booting
an app context, and without side effects. Output is a single JSON object
(when `--json`) or a short human-readable report (default), and exit
code reflects pass/fail.

This fills a gap today where the only way to know "does this CFML
compile?" is to run it via `lucli cfml '…'` or `lucli run file.cfm`,
which fully evaluates the code (and therefore has side effects, loads
the script engine, mounts application state, etc.). Parsing should be
cheap, side-effect-free, and scriptable.

## Motivation

Four concrete use cases, all currently awkward or impossible with the
existing toolchain:

### 1. Editor / LSP integration

An LSP server for CFML wants to surface parse errors as the user types,
without running their code. Invoking `lucli cfml` risks state mutation;
invoking `lucli run` requires a file on disk and runs the template.
`lucli parse -` (stdin) with `--json` gives a fast, structured
diagnostic stream that an LSP can consume directly.

### 2. Pre-commit hooks

```bash
# .git/hooks/pre-commit
for f in $(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(cfc|cfm|cfs)$'); do
    lucli parse "$f" --json || exit 1
done
```

Catches syntax errors before they ever land in `develop`. No server,
no app context, no test run — just "is this parseable?"

### 3. Doctest harnesses (the direct motivator)

The Wheels 4.0 guides ship a [verify-docs harness](https://github.com/wheels-dev/wheels/tree/develop/web/sites/guides/scripts/verify-docs)
that extracts `{test:*}`-tagged code blocks from MDX and validates them.
The `{test:compile}` driver currently has no good target: `lucli cfml`
runs the code, `lucli run` needs a real file and runs it, and CFCs have
no run-in-isolation path at all. `lucli parse` with JSON diagnostics is
exactly the primitive the harness needs — one invocation per block,
structured pass/fail, no fixture app required.

### 4. CI guard on generated files

Generators (`wheels generate model`, etc.) occasionally emit invalid
CFML on edge cases. A CI step that parses every generator's output
protects against regressions without running the entire test suite.

## Proposed surface

### Invocation

```
lucli parse <PATH | ->  [--json] [--fail-on=error|warning|info]
lucli parse --expr '<CFML>'  [--json]
```

- `<PATH>` — file path (relative resolved via `getEffectiveRuntimeCwd()`,
  same rules as `lucli run`). Extensions supported: `.cfc`, `.cfm`,
  `.cfs`. Unknown extension: error.
- `-` — read source from stdin. Treated as `.cfs` by default; `--ext=cfc`
  overrides.
- `--expr '<CFML>'` — inline expression mode. Parses as if wrapped in a
  minimal `.cfs` script.
- `--json` — emit JSON diagnostics on stdout (see schema below).
  Default is a one-line human-readable summary.
- `--fail-on=<level>` — exit non-zero if any diagnostic at this level or
  higher appears. Default: `error`. Set to `warning` for stricter CI.

### Exit codes

| Code | Meaning |
|------|---------|
| 0 | Parsed cleanly, no diagnostics at `--fail-on` level or higher |
| 1 | Parse failed OR diagnostics at `--fail-on` level present |
| 2 | Invocation error (file not found, bad flag, unreadable stdin) |

### JSON schema (when `--json`)

```json
{
  "ok": false,
  "file": "/abs/path/to/file.cfc",
  "language": "cfc",
  "duration_ms": 42,
  "diagnostics": [
    {
      "level": "error",
      "category": "syntax",
      "message": "Expected '}' to close block",
      "line": 17,
      "column": 3,
      "length": 1,
      "snippet": "    return result\n}"
    }
  ]
}
```

- `ok` — boolean, `true` iff no diagnostics at or above `--fail-on`.
- `file` — absolute path, or `"<stdin>"`, or `"<expr>"`.
- `language` — `"cfc" | "cfm" | "cfs"`.
- `duration_ms` — integer, parse wall-time.
- `diagnostics[]` — ordered by file position. Always present (empty
  array on clean parse).
- `diagnostics[].level` — `"error" | "warning" | "info"`.
- `diagnostics[].category` — freeform short string from Lucee's
  compiler (`"syntax"`, `"semantic"`, `"deprecation"`, etc.).
- `diagnostics[].line`, `column` — 1-based, referring to the source
  exactly as provided.
- `diagnostics[].length` — optional, characters underlined.
- `diagnostics[].snippet` — optional, short source excerpt around the
  error (useful for LSP hover cards and terminal pretty-printing).

### Default (non-JSON) output

```
$ lucli parse app/models/User.cfc
OK  app/models/User.cfc  (42ms)

$ lucli parse app/models/Broken.cfc
FAIL  app/models/Broken.cfc  (38ms)
  error:syntax  line 17, col 3: Expected '}' to close block
    |     return result
    | 17: }
```

## Implementation sketch

Lucee's compiler API (`lucee.runtime.compiler.CFMLCompilerImpl` and
related classes) is the right entry point — it parses to AST without
executing. The trick is surfacing structured diagnostics; Lucee's
current compile path throws `PageException` with line/column metadata
accessible via `getLine()` / `getCatch()` / `getSource()`.

Proposed file layout (matching existing LuCLI conventions):

```
src/main/java/org/lucee/lucli/
├── cli/commands/
│   └── ParseCommand.java         # picocli @Command, flag handling, output
└── parser/
    ├── CfmlParser.java           # thin wrapper around Lucee compiler API
    ├── Diagnostic.java           # record: level, category, msg, line, col, len, snippet
    └── DiagnosticJson.java       # serialises to the JSON shape above
```

Approximate LOC: ~250 excluding tests. Picocli wiring is ~50 LOC
(mirroring `CfmlCommand`/`RunCommand`); the parser wrapper is the meat.

### Open implementation questions

1. **Which Lucee compile entry point exactly?** Needs a spike against
   the current bundled Lucee version to confirm which API gives
   structured diagnostics for all three file types (`.cfc`, `.cfm`,
   `.cfs`) without requiring a full `ConfigWeb` / app context.
2. **CFC semantic checks** — `extends="Model"` with no `Model.cfc` on
   the mapping: parse error or semantic warning? Initial proposal:
   parse-only means "lexically and syntactically valid"; semantic
   resolution (component resolution, mapping lookup) is out of scope
   for v1. If the compiler API surfaces those as diagnostics for free,
   emit them at `level: "warning"` with `category: "semantic"`.
3. **Inclusion of non-error diagnostics** — Lucee emits deprecation
   warnings through the same pipeline. Surface them as `level:
   "warning"` / `category: "deprecation"`. `--fail-on=warning` lets
   strict CI promote them to failures.
4. **Stdin EOF behaviour** — block on read until EOF, same as standard
   Unix filters. Empty input: exit 0 with `diagnostics: []`.

## Non-goals for v1

- **Running the code.** If you want execution + error reporting, use
  `lucli cfml` or `lucli run`.
- **Formatting or linting.** Style rules belong in a separate linter
  (e.g. a future `lucli fmt` or `lucli lint`). `parse` only answers
  "does this compile."
- **Cross-file resolution.** A CFC that `extends="app.models.Foo"`
  parses in isolation even if `Foo` doesn't exist. That's a semantic
  check, not a parse check, and belongs in a later pass.
- **Performance tuning.** v1 can spin up the Lucee classloader per
  invocation (same cost as `lucli cfml`); batching and daemon-mode
  speedups come later.

## Alternatives considered

1. **Repurpose `lucli cfml` with a `--no-exec` flag.** Conflates two
   concepts on one surface; harder for LSP/IDE users to discover.
   Rejected.
2. **Wrap the existing `lucli validate` (Wheels-specific).** That
   command is tied to a Wheels app context. The need here is generic
   CFML. Rejected.
3. **Ship this as a Wheels-specific CLI subcommand.** The motivation
   starts with Wheels docs but the primitive is purely CFML. Putting
   it in LuCLI serves every downstream CFML tool (Wheels, Preside,
   Mura, raw CFML projects) with one implementation.

## Rollout

1. **Issue (this)** — agree the surface.
2. **PR #1: minimal implementation** — `ParseCommand` + `CfmlParser`
   wrapper, `.cfm` + `.cfs` file parsing, `--json` output, 20+ unit
   tests covering the diagnostic shapes. Ships without `--expr` and
   without `.cfc`-specific handling.
3. **PR #2: CFC + stdin + `--expr`** — extend coverage once v1 lands.
4. **Wheels 4.0 docs harness picks it up** — `{test:compile}` driver
   in the guides harness swaps from placeholder pattern-match to real
   `lucli parse --json` calls.

## Related

- Wheels 4.0 guides rewrite spec:
  [docs/superpowers/specs/2026-04-18-guides-rewrite-v4-design.md](https://github.com/wheels-dev/wheels/blob/develop/docs/superpowers/specs/2026-04-18-guides-rewrite-v4-design.md)
- Wheels verify-docs harness:
  [web/sites/guides/scripts/verify-docs/](https://github.com/wheels-dev/wheels/tree/develop/web/sites/guides/scripts/verify-docs)
- Companion fix PR (exit codes for `lucli cfml`): filed separately.

## Labels

`enhancement`, `proposal`, `compiler`, `needs-design-review`
