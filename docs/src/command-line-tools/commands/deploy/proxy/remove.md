# `wheels deploy proxy remove`

Tear down the `kamal-proxy` container on every host.

## Synopsis

```bash
wheels deploy proxy remove [--destination=<name>] [--dry-run]
```

## Description

Runs `docker rm -f kamal-proxy` on every host. Public traffic stops reaching the fleet. Use when re-provisioning a host, or when you want to hand the host's port 80/443 back to something else.

Called as part of `wheels deploy remove --confirm`.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy proxy remove
```
