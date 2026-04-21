# `wheels deploy build remove`

Remove the local buildx builder instance.

## Synopsis

```bash
wheels deploy build remove [--destination=<name>] [--dry-run]
```

## Description

Runs `docker buildx rm`. Use when switching between remote and local builders, or when a corrupted builder needs to be rebuilt.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy build remove
```
