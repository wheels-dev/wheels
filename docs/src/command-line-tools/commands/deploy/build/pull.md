# `wheels deploy build pull`

Pull a specific image version onto every host.

## Synopsis

```bash
wheels deploy build pull [--version=<tag>] [--destination=<name>] [--dry-run]
```

## Description

Runs `docker pull <registry>/<image>:<version>` on every host in parallel. The image must already be pushed to the registry and the host must be logged in — `wheels deploy registry login` runs automatically as part of the main deploy flow.

## Flags

| Flag | Description |
|------|-------------|
| `--version=<tag>` | Tag to pull. Defaults to git short SHA. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy build pull
wheels deploy build pull --version=v1.2.3
```
