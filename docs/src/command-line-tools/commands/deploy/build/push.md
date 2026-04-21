# `wheels deploy build push`

Build and push the image to the registry.

## Synopsis

```bash
wheels deploy build push [--version=<tag>] [--destination=<name>] [--dry-run]
```

## Description

Runs `docker build` (or `docker buildx build` if multi-arch) against the configured `builder.context` and `builder.dockerfile`, tags with `<registry>/<image>:<version>`, and pushes. Runs entirely locally (or on `builder.remote:` if configured).

## Flags

| Flag | Description |
|------|-------------|
| `--version=<tag>` | Tag. Defaults to git short SHA. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy build push
wheels deploy build push --version=v1.2.3
```
