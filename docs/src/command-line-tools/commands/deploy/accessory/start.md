# `wheels deploy accessory start`

Start a stopped sidecar container.

## Synopsis

```bash
wheels deploy accessory start <name|all> [--destination=<name>] [--dry-run]
```

## Description

Runs `docker start` on the accessory container. The container must already exist — use `boot` to create one.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy accessory start db
```
