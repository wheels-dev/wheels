# `wheels deploy build deliver`

Build the image locally, push to the registry, and pull on every host.

## Synopsis

```bash
wheels deploy build deliver [--version=<tag>] [--destination=<name>] [--dry-run]
```

## Description

Composite verb: runs `wheels deploy build push` followed by `wheels deploy build pull`. The image ends up cached on every host, ready for an `app boot` or `deploy`.

Useful when you want to pre-stage an image on every host before a deploy window — the actual deploy then skips the slow `docker pull` step.

## Flags

| Flag | Description |
|------|-------------|
| `--version=<tag>` | Tag to build. Defaults to git short SHA. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy build deliver
wheels deploy build deliver --version=v1.2.3
```
