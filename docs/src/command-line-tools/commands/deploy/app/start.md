# `wheels deploy app start`

Start a stopped container for a specific version.

## Synopsis

```bash
wheels deploy app start --version=<tag> [--role=<name>] [--destination=<name>] [--dry-run]
```

## Description

Runs `docker start <container>` on each host. The container must already exist — use `app boot` to create one. Useful for bringing a previously stopped rollback target back online without a full re-run.

## Flags

| Flag | Description |
|------|-------------|
| `--version=<tag>` | **Required.** Version whose container to start. |
| `--role=<name>` | Filter to a single role. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy app start --version=abc123 --role=web
```
