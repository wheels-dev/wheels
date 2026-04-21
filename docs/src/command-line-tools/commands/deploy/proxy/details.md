# `wheels deploy proxy details`

Show status of the `kamal-proxy` container on every host.

## Synopsis

```bash
wheels deploy proxy details [--destination=<name>] [--dry-run]
```

## Description

Runs `docker ps` filtered to the `kamal-proxy` name. Useful for quickly confirming that the proxy is running on every host in the fleet.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy proxy details
```
