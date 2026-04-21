# `wheels deploy build details`

Describe the configured buildx builder.

## Synopsis

```bash
wheels deploy build details [--destination=<name>] [--dry-run]
```

## Description

Runs `docker buildx inspect`. Shows which arches the builder supports, whether it's local or remote, and its current state. Useful for debugging cross-arch build issues.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy build details
```
