# `wheels deploy accessory details`

Show status for a sidecar container.

## Synopsis

```bash
wheels deploy accessory details <name|all> [--destination=<name>] [--dry-run]
```

## Description

Runs `docker ps` filtered to the accessory's container name. With `all`, shows every accessory across every host.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy accessory details db
wheels deploy accessory details all
```
