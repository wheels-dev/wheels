# `wheels deploy accessory boot`

First-time install of one (or all) sidecar container.

## Synopsis

```bash
wheels deploy accessory boot <name|all> [--destination=<name>] [--dry-run]
```

## Description

Runs `docker run` for the accessory — creates the container, mounts its volumes and files, sets env, and attaches it to the `kamal` Docker network. Pass `all` to boot every accessory defined in `deploy.yml`.

Idempotent on the container name — calling `boot` when the accessory is already running is a no-op.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy accessory boot db
wheels deploy accessory boot redis
wheels deploy accessory boot all
```
