# `wheels deploy app boot`

Boot a container for a specific version on every host in each role.

## Synopsis

```bash
wheels deploy app boot --version=<tag> [--role=<name>] [--destination=<name>] [--dry-run]
```

## Description

Runs `docker run` on each host for the given version, producing a container named `<service>-<role>-<version>`. Does **not** cut over proxy traffic — use `wheels deploy` for a full rolling release, or wire in `wheels deploy proxy ...` manually.

## Flags

| Flag | Description |
|------|-------------|
| `--version=<tag>` | **Required.** Image tag to boot. |
| `--role=<name>` | Filter to a single role. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy app boot --version=abc123
wheels deploy app boot --version=abc123 --role=web
```
