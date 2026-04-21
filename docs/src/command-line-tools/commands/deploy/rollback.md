# `wheels deploy rollback`

Roll back to a previously deployed version.

## Synopsis

```bash
wheels deploy rollback --version=<tag> [--destination=<name>] [--dry-run]
```

## Description

Targets a specific prior version and switches proxy traffic back to it. The old image must still be present on the hosts — rollbacks only work for versions that haven't been pruned. For each role and host, runs `docker start` on the old container and issues a proxy cut-over.

`--version` is **required** — there is no implicit "previous version" tracking. Inspect `wheels deploy app images --role=web` to see available versions on the fleet.

## Flags

| Flag | Description |
|------|-------------|
| `--version=<tag>` | **Required.** Version to roll back to. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy app images --role=web   # find an older tag
wheels deploy rollback --version=abc123
```
