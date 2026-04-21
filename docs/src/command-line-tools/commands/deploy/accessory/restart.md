# `wheels deploy accessory restart`

Stop then start a sidecar container.

## Synopsis

```bash
wheels deploy accessory restart <name|all> [--destination=<name>] [--dry-run]
```

## Description

Graceful `docker restart` of the accessory. The container identity, volumes, and env are preserved. Use to pick up changes delivered via a `SIGHUP`-style config reload.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy accessory restart redis
```
