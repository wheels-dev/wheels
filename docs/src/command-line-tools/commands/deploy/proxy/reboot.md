# `wheels deploy proxy reboot`

Stop, remove, and re-install the `kamal-proxy` container.

## Synopsis

```bash
wheels deploy proxy reboot [--destination=<name>] [--dry-run]
```

## Description

Use after a `kamal-proxy` image upgrade or to recover from a stuck proxy state. Current connections are dropped; the proxy is recreated from scratch and app containers remain running throughout (they don't depend on the proxy's process lifetime).

For a graceful stop + start without re-pulling the image, use `wheels deploy proxy restart`.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy proxy reboot
```
