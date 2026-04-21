# `wheels deploy proxy logs`

Tail `kamal-proxy` container logs.

## Synopsis

```bash
wheels deploy proxy logs [--tail=<N>] [--destination=<name>] [--dry-run]
```

## Description

Runs `docker logs --tail <N> kamal-proxy` on every host. Useful for diagnosing certificate issuance, routing failures, or upstream connection errors.

## Flags

| Flag | Description |
|------|-------------|
| `--tail=<N>` | Lines per host. Defaults to 100. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy proxy logs --tail=500
```
