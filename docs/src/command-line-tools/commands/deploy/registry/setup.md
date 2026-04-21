# `wheels deploy registry setup`

Alias for `wheels deploy registry login`.

## Synopsis

```bash
wheels deploy registry setup [--password=<value>] [--destination=<name>] [--dry-run]
```

## Description

Behaves identically to [`login`](./login.md). The `setup` alias exists for symmetry with `wheels deploy setup` — first-time setup routines.

## Flags

| Flag | Description |
|------|-------------|
| `--password=<value>` | Override resolved password. For testing. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy registry setup
```
