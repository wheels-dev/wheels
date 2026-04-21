# `wheels deploy app remove`

Remove containers for a specific version.

## Synopsis

```bash
wheels deploy app remove --version=<tag> [--role=<name>] [--destination=<name>] [--dry-run]
```

## Description

Runs `docker rm -f` for the matching `<service>-<role>-<version>` containers on every host. Does not touch the image cache — use `wheels deploy prune images` to reclaim disk.

Useful for cleaning up a failed deploy or removing a specific old version from the host's container list.

## Flags

| Flag | Description |
|------|-------------|
| `--version=<tag>` | **Required.** |
| `--role=<name>` | Filter to a single role. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy app remove --version=failed123
```
