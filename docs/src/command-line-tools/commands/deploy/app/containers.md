# `wheels deploy app containers`

List all app containers for this service, across every version.

## Synopsis

```bash
wheels deploy app containers [--role=<name>] [--destination=<name>] [--dry-run]
```

## Description

Runs `docker ps -a` filtered by the service label. Shows every version that still has a container on the host — running, stopped, and crashed. Use this to find rollback targets.

Does **not** require `--version`.

## Flags

| Flag | Description |
|------|-------------|
| `--role=<name>` | Filter to a single role. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy app containers
wheels deploy app containers --role=web
```
