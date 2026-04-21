# `wheels deploy proxy boot`

First-time install of the `kamal-proxy` container on every host.

## Synopsis

```bash
wheels deploy proxy boot [--destination=<name>] [--dry-run]
```

## Description

Runs the `docker run` that creates the singleton `kamal-proxy` container, binds ports 80 and 443, and sets up the `kamal` Docker network that app containers attach to. Idempotent — if the proxy is already booted, the command is a no-op.

Called automatically by `wheels deploy` when the proxy isn't running yet, so you usually don't need to call this directly. Use it for an explicit proxy-only setup on a new host.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy proxy boot
```
