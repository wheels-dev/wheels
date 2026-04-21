# `wheels deploy prune all`

Remove old containers and dangling images on every host.

## Synopsis

```bash
wheels deploy prune all [--keep=<N>] [--destination=<name>] [--dry-run]
```

## Description

Combines `prune containers` and `prune images` into one sweep. Keeps the N most recent versions per role; removes containers and images for older versions.

## Flags

| Flag | Description |
|------|-------------|
| `--keep=<N>` | Number of recent versions to keep per role. Defaults to 5. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy prune all
wheels deploy prune all --keep=10
```
