# `wheels deploy app images`

List available image tags for this service on each host.

## Synopsis

```bash
wheels deploy app images [--role=<name>] [--destination=<name>] [--dry-run]
```

## Description

Runs `docker images` filtered to the configured image repository on every host. Lists every tag cached locally on the host. A tag must appear here to be a valid `wheels deploy rollback --version=<tag>` target on that host.

Does **not** require `--version`.

## Flags

| Flag | Description |
|------|-------------|
| `--role=<name>` | Filter to a single role. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy app images --role=web
```
