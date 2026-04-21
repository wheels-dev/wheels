# `wheels deploy prune containers`

Remove old containers, keeping the N most recent versions.

## Synopsis

```bash
wheels deploy prune containers [--keep=<N>] [--destination=<name>] [--dry-run]
```

## Description

Lists containers filtered by the service label, sorts them by version, keeps the most recent `--keep` per role, and removes the rest. Only old (non-active) versions are considered — the currently running proxy target is preserved regardless.

## Flags

| Flag | Description |
|------|-------------|
| `--keep=<N>` | Versions to keep per role. Defaults to 5. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy prune containers
wheels deploy prune containers --keep=3
```
