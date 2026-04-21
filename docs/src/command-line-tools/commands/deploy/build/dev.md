# `wheels deploy build dev`

Build a local image for development without pushing to the registry.

## Synopsis

```bash
wheels deploy build dev [--destination=<name>] [--dry-run]
```

## Description

Runs `docker build` and tags the result for local use only. No registry push. Handy for sanity-checking your Dockerfile or debugging build args without triggering a real deploy.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy build dev
```
