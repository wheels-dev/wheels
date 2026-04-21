# `wheels deploy accessory remove`

Tear down a sidecar container.

## Synopsis

```bash
wheels deploy accessory remove <name|all> [--destination=<name>] [--dry-run]
```

## Description

Runs `docker rm -f` on the accessory container. **Named volumes are preserved** — accessory data stored in a named Docker volume survives a `remove` and will be re-attached on the next `boot`. Anonymous volumes are gone.

To delete accessory data too, `ssh` to the host and `docker volume rm <volume-name>` explicitly.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy accessory remove redis
wheels deploy accessory remove all
```
