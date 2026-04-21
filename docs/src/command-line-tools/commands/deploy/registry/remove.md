# `wheels deploy registry remove`

Alias for `wheels deploy registry logout`.

## Synopsis

```bash
wheels deploy registry remove [--destination=<name>] [--dry-run]
```

## Description

Behaves identically to [`logout`](./logout.md). The `remove` alias exists for symmetry with the overall `remove` teardown pattern.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy registry remove
```
