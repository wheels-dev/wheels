# `wheels deploy secrets print`

Resolve `.kamal/secrets` and print the result as `KEY=VALUE` lines.

## Synopsis

```bash
wheels deploy secrets print [--destination=<name>]
```

## Description

Reads `.kamal/secrets` (plus the per-destination overlay if `--destination` is passed), evaluates every `$(...)` subshell, and prints the final values.

The debugging workhorse for secret resolution. If a deploy fails because a registry password didn't resolve, run this to see exactly what your secrets file expanded to — any empty value or missing key jumps out immediately.

The output contains actual secret values — never redirect it into a file that could be committed or shared.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Layer `.kamal/secrets.<name>` on top. |

## Examples

```bash
wheels deploy secrets print
wheels deploy secrets print --destination=staging
wheels deploy secrets print | grep KAMAL_REGISTRY_PASSWORD
```
