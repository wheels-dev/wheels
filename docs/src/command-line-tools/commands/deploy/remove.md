# `wheels deploy remove`

Destructive teardown of the entire deployment.

## Synopsis

```bash
wheels deploy remove --confirm [--destination=<name>]
```

## Description

Tears down every container for this service across the fleet: app containers (all versions), `kamal-proxy`, every accessory, plus a `docker logout` of the registry. **Requires `--confirm`** — without it the command errors out.

Use this to wipe a test environment. For production, prefer `wheels deploy app remove` / `wheels deploy proxy remove` / `wheels deploy accessory remove` individually so you can reason about what is destroyed.

Accessory **volumes** are not removed — data persisted on disk survives. To nuke data too, `ssh` to the host and `docker volume rm` explicitly.

## Flags

| Flag | Description |
|------|-------------|
| `--confirm` | **Required.** Acknowledge the destructive action. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy remove --confirm
wheels deploy remove --confirm --destination=staging
wheels deploy remove --dry-run     # plan without confirming
```
