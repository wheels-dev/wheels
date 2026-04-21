# `wheels deploy lock status`

Show the current deploy lock state.

## Synopsis

```bash
wheels deploy lock status [--destination=<name>] [--dry-run]
```

## Description

Prints the contents of `/tmp/kamal-lock-<service>` — the user holding the lock and the message. If no lock is held, returns empty.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy lock status
```
