# Wheels CLI Architecture

How `wheels <command>` reaches our code, and where we can intercept.

## The three layers

```
                      ┌──────────────────────────────────────┐
  $ wheels new myapp  │  1.  Wrapper script  (ours)          │
                      │      bash on macOS/Linux,            │
                      │      .cmd on Windows                 │
                      │      — module sync + JAVA_HOME +     │
                      │        exec the LuCLI binary         │
                      └──────────────┬───────────────────────┘
                                     │  exec
                      ┌──────────────▼───────────────────────┐
                      │  2.  LuCLI binary  (upstream)        │
                      │      installed under our name as     │
                      │      `libexec/wheels`. picocli       │
                      │      parses args, then routes to     │
                      │      a module via                    │
                      │      `modules run wheels …`          │
                      └──────────────┬───────────────────────┘
                                     │  executeModule
                      ┌──────────────▼───────────────────────┐
                      │  3.  cli/lucli/Module.cfc  (ours)    │
                      │      one public function per         │
                      │      subcommand: new(), start(),     │
                      │      migrate(), test(), …            │
                      └──────────────────────────────────────┘
```

## Layer 1 — the wrapper (ours)

The Homebrew formula in [`wheels-dev/homebrew-wheels`](https://github.com/wheels-dev/homebrew-wheels) and the Chocolatey package in [`wheels-dev/chocolatey-wheels`](https://github.com/wheels-dev/chocolatey-wheels) each generate a small wrapper that:

1. Stages the wheels module (`cli/lucli/`) into `~/.wheels/modules/wheels/` if `.module-version` has changed since last run.
2. Stages the framework source (`vendor/wheels/`) into `~/.wheels/modules/wheels/vendor/wheels/`.
3. Drops the SQLite JDBC driver into `~/.wheels/express/<version>/lib/ext/` (fresh-VM cliff fix; see commit `da9058f42`).
4. Sets `JAVA_HOME` and `LUCLI_HOME=$HOME/.wheels`.
5. **Intercepts arguments that picocli would short-circuit on** (see "Why intercept here" below).
6. `exec`s `libexec/wheels` (the renamed LuCLI native binary).

## Layer 2 — LuCLI binary (upstream)

The brew formula downloads `lucli-<version>-<os>` from [`cybersonic/LuCLI`](https://github.com/cybersonic/LuCLI/releases) and installs it as `libexec/wheels`. **We do not patch this binary.** It is upstream LuCLI, byte-for-byte, just renamed.

LuCLI's startup flow when invoked as `wheels`:

1. Reads `-Dlucli.binary.name` (set by the wrapper), normalises to `wheels`.
2. `CliProfile.forBinaryName("wheels")` returns a `WheelsProfile` — controls branding (`Wheels` display name, `~/.wheels` home dir, ASCII banner).
3. `prependBinaryNameIfAliased` rewrites `args` so the binary name becomes the first positional argument: `wheels new myapp` → `["wheels", "new", "myapp"]`.
4. picocli parses. If the first positional is a module name and `--help` is present, `preprocessModuleHelp` rewrites again to `["modules", "run", "wheels", "--help"]` so picocli routes to `ModulesRunCommandImpl`.
5. Otherwise picocli's `routeCommand(firstArg, …)` checks `ModuleCommand.moduleExists("wheels")` and dispatches via `LuceeScriptEngine.executeModule("wheels", subcommand_args)`.

## Layer 3 — `Module.cfc` (ours)

LuCLI's module dispatcher (`script_engine/executeModule.cfs`) does:

```cfml
modules = createObject("component", "modules.wheels.Module").init(...);
results = modules[subcommand](argumentCollection=argCollection);
// any non-null string return value is printed via StringOutput
```

So `wheels new myapp` becomes `modules.new("myapp")`. Each public function in [`Module.cfc`](Module.cfc) is a subcommand. Functions inherited from `BaseModule` (`init`, `version`, `showHelp`, `out`, `err`, `getEnv`, …) are excluded from auto-discovered help listing but are still callable.

## Where we can intercept

| Layer | Use it for | Cannot reach |
|-------|------------|--------------|
| **Wrapper** | Anything picocli would short-circuit on (`--version`, `--help`), or anything that needs to skip JVM startup for speed | n/a — wrapper sees raw args before LuCLI does |
| **LuCLI binary** | Untouchable per project policy (we don't patch upstream) | n/a |
| **`Module.cfc`** | Any subcommand that reaches `routeCommand` → module dispatch: `new`, `start`, `migrate`, `test`, `generate`, … Includes `wheels --help` (rewritten by `preprocessModuleHelp` to module dispatch) | picocli's root-level absorbed flags: `--version`, `--lucee-version`, `--verbose`, `--debug`, `--timing` |

### Why intercept in the wrapper

picocli treats `@Option(versionHelp = true)` and `@Option(usageHelp = true)` flags specially: it processes them **during argument parsing**, before the `call()` method runs. So `wheels --version` never reaches our module dispatch — picocli prints LuCLI's banner and exits. The same is true for `--help` if it appears alone (no positional first arg to trigger `preprocessModuleHelp`'s rewrite).

The wrapper is the only place upstream of picocli that we own. A short pattern-match on `$@` lets us emit our own banner / help and `exit 0` before `exec`ing LuCLI.

### Why duplicate `--help` and `--version` in `Module.cfc` too

When the user types `wheels version` or `wheels help` (subcommand form, no leading `--`), the wrapper does not match — those reach LuCLI normally and dispatch to our module. So we override `version()` and `showHelp()` in `Module.cfc` to emit the same content the wrapper does. Both paths converge on identical output.

## Examples

| User types | Path |
|------------|------|
| `wheels new myapp` | wrapper sync → LuCLI → `Module.new("myapp")` |
| `wheels start` | wrapper sync → LuCLI → `Module.start()` (which calls back into LuCLI's Java server APIs via `executeInProcess(["server", "run"])`) |
| `wheels --version` | wrapper intercept → exit (never reaches LuCLI) |
| `wheels version` | wrapper sync → LuCLI → `Module.version()` (overridden to emit banner) |
| `wheels --help` | wrapper intercept → exit (never reaches LuCLI) |
| `wheels help` | wrapper sync → LuCLI → `Module.showHelp()` (overridden) |
| `wheels generate model User` | wrapper sync → LuCLI → `Module.generate("model", "User")` |
| `wheels migrate latest --help` | wrapper sync → LuCLI → `preprocessModuleHelp` rewrites → `Module.showHelp("migrate")` |

## Testing the layers in isolation

- **Just the wrapper:** edit `bin/wheels` (brew) or `tools/wheels.cmd` (choco), run any command. The wrapper is plain shell — `bash -x bin/wheels --version` traces it.
- **Just LuCLI routing:** invoke the binary directly: `~/.wheels/libexec/wheels modules run wheels migrate latest`. This skips the wrapper but still goes through picocli + module dispatch.
- **Just `Module.cfc`:** unit tests in [`cli/lucli/tests/specs/`](tests/specs/) instantiate the module and invoke functions directly without LuCLI.
