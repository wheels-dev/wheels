# fix(cfml): return exit 1 when expression execution fails

## Problem

`lucli cfml '<expr>'` swallows CFML execution errors. The catch block at
`src/main/java/org/lucee/lucli/cli/commands/CfmlCommand.java:68-71` logs
the error to stderr but doesn't return — control falls through to
`return result`, where `result` is still `null`.

`CfmlCommand.call()` is typed `Callable<Object>`. picocli's
exit-code-from-Callable rule only triggers when the return value is an
`Integer`. A `null` Object return maps to exit code 0. So:

```bash
$ lucli cfml 'throw(message="boom")'
Error in cfml command: boom
$ echo $?
0                                       # ← wrong
```

This silently defeats every caller that checks exit codes:
- Shell pipelines (`lucli cfml '…' && next-step`)
- CI jobs (failed expressions pass the build)
- Pre-commit hooks
- Doctest harnesses — including the Wheels 4.0 guides `verify-docs`
  harness, where this PR is motivated from

## Fix

One line: `return 1;` at the end of the catch block.

```diff
         catch (Exception e) {
             System.err.println("Error in cfml command: " + e.getMessage());
             LuCLI.debugStack(e);
+            return 1;
         }
```

After the change, picocli sees `Integer 1` from `call()` and exits with
code 1. The `finally` block still runs (`Timer.stop`), and the
`setExecutionResult(result)` / `return result` block after the catch is
skipped — which is correct, since there's nothing useful to expose to
programmatic callers on failure.

## Testing

Before:
```bash
$ lucli cfml 'throw(message="boom")'; echo "exit=$?"
Error in cfml command: boom
exit=0
```

After:
```bash
$ lucli cfml 'throw(message="boom")'; echo "exit=$?"
Error in cfml command: boom
exit=1
```

Success path unchanged:
```bash
$ lucli cfml '1 + 2'; echo "exit=$?"
3
exit=0
```

## Scope notes

I audited `RunCommand.java` at the same time because the same failure mode
was reported there. Each catch in `RunCommand` already contains
`return 1;`:

- `src/main/java/org/lucee/lucli/cli/commands/RunCommand.java:96`
- `src/main/java/org/lucee/lucli/cli/commands/RunCommand.java:105`
- `src/main/java/org/lucee/lucli/cli/commands/RunCommand.java:118`

So `lucli run bad.cfm` should already exit non-zero on any exception
propagating out of `engine.executeCFMFile()` / `executeCFSFile()` /
`executeLucliScript()`. If empirical testing shows `lucli run bad.cfm`
still exits 0 on CFML parse errors, the swallow is happening inside the
script engine (compile-time errors not propagating as exceptions) and
needs a separate fix at that layer — not in `RunCommand`.

## Changelog

```
### Fixed
- `lucli cfml` now exits with code 1 when the CFML expression throws. It
  was previously swallowing errors and reporting success to the caller.
```

## Commits

One commit, conventional-commit style:

```
fix(cfml): return exit 1 when expression execution fails
```

## Follow-up (separate PR)

A proposal issue is filed separately for a dedicated `lucli parse`
subcommand — parse-only, no side effects, JSON diagnostics — to serve
LSP, pre-commit hooks, and doctest harnesses without spinning up the
script engine.
