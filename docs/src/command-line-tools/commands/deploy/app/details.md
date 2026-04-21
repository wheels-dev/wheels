# `wheels deploy app details`

Print status for containers of a specific version.

## Synopsis

```bash
wheels deploy app details --version=<tag> [--role=<name>] [--destination=<name>] [--dry-run]
```

## Description

Runs `docker ps` filtered to the service + version labels. Useful for confirming whether a specific version's container is running on every expected host.

## Flags

| Flag | Description |
|------|-------------|
| `--version=<tag>` | **Required.** |
| `--role=<name>` | Filter to a single role. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy app details --version=abc123
```
