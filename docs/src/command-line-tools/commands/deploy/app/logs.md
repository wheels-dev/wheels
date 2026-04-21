# `wheels deploy app logs`

Tail application container logs across the fleet.

## Synopsis

```bash
wheels deploy app logs [--tail=<N>] [--follow] [--container=<id>] [--role=<name>] [--destination=<name>]
```

## Description

Runs `docker logs` against each host's app container. Without `--container`, targets the most recently booted container for the service.

Does **not** require `--version`.

## Flags

| Flag | Description |
|------|-------------|
| `--tail=<N>` | Lines per host. Defaults to 100. |
| `--follow` | Stream logs (long-lived SSH connection). |
| `--container=<id>` | Specific container ID. Otherwise the latest. |
| `--role=<name>` | Filter to a single role. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy app logs --tail=500
wheels deploy app logs --follow --role=web
```
