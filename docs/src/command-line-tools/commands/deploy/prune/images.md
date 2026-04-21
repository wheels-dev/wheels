# `wheels deploy prune images`

Remove dangling Docker images on every host.

## Synopsis

```bash
wheels deploy prune images [--destination=<name>] [--dry-run]
```

## Description

Runs `docker image prune` on each host to remove images not referenced by any container. Reclaims disk after many deploys.

Does **not** remove tagged images that still have an associated container — use `prune all` or `prune containers` first to clear those.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy prune images
```
