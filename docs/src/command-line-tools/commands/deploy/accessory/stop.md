# `wheels deploy accessory stop`

Stop a running sidecar container.

## Synopsis

```bash
wheels deploy accessory stop <name|all> [--destination=<name>] [--dry-run]
```

## Description

Runs `docker stop` on the accessory container. Data in volumes is preserved. If the app depends on the accessory, the app will begin erroring immediately — use for maintenance windows, not hotfixes.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy accessory stop redis
```
