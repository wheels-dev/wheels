# `wheels deploy accessory reboot`

Stop, remove, and re-install a sidecar container.

## Synopsis

```bash
wheels deploy accessory reboot <name|all> [--destination=<name>] [--dry-run]
```

## Description

Recreates the accessory from the current `deploy.yml` definition. Useful after bumping an image tag or changing env/volumes. **Named volumes persist** — data isn't touched. Bind mounts also persist (they are on the host filesystem).

For an image upgrade of Postgres, you generally don't want `reboot` — run a tested upgrade path. For Redis and stateless caches, `reboot` is typically safe.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy accessory reboot redis
```
