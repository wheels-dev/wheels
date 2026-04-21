# `wheels deploy proxy restart`

Stop and then start the `kamal-proxy` container.

## Synopsis

```bash
wheels deploy proxy restart [--destination=<name>] [--dry-run]
```

## Description

Graceful `docker restart kamal-proxy` on every host. Use after editing proxy-related config that takes effect at process start. For an image upgrade, use `wheels deploy proxy reboot` instead.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy proxy restart
```
