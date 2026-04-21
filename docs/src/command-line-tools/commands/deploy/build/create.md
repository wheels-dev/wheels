# `wheels deploy build create`

Create a local buildx builder instance.

## Synopsis

```bash
wheels deploy build create [--destination=<name>] [--dry-run]
```

## Description

Runs `docker buildx create` to set up a named builder for this service. Required once before the first multi-arch or remote build. Subsequent `build push` commands reuse the builder.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy build create
```
