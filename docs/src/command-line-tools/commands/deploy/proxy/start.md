# `wheels deploy proxy start`

Start a stopped `kamal-proxy` container.

## Synopsis

```bash
wheels deploy proxy start [--destination=<name>] [--dry-run]
```

## Description

Runs `docker start kamal-proxy` on every host. The container must already exist — use `wheels deploy proxy boot` to create one.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy proxy start
```
