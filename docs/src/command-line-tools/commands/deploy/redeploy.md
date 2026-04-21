# `wheels deploy redeploy`

Redeploy the current version without rebuilding.

## Synopsis

```bash
wheels deploy redeploy [--version=<tag>] [--destination=<name>] [--dry-run]
```

## Description

Equivalent to `wheels deploy` but intended for re-running a deploy of the same image — for example, to pick up an updated `.kamal/secrets` value or to recover from a partial failure. The full lock / pull / roll sequence runs; no build step is involved.

## Flags

| Flag | Description |
|------|-------------|
| `--version=<tag>` | Image tag. Defaults to git short SHA. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy redeploy
wheels deploy redeploy --version=abc123
```
