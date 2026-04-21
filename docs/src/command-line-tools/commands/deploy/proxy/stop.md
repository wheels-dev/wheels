# `wheels deploy proxy stop`

Stop the `kamal-proxy` container.

## Synopsis

```bash
wheels deploy proxy stop [--destination=<name>] [--dry-run]
```

## Description

Runs `docker stop kamal-proxy` on every host. Public traffic stops reaching app containers until the proxy is started or rebooted. Use with intention — this is a full outage for the duration.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy proxy stop
```
