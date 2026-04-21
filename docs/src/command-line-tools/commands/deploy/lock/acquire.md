# `wheels deploy lock acquire`

Manually acquire the deploy lock.

## Synopsis

```bash
wheels deploy lock acquire [--message=<text>] [--destination=<name>] [--dry-run]
```

## Description

Creates `/tmp/kamal-lock-<service>` on the host fleet with the current user as owner and an optional message. Subsequent `wheels deploy` calls refuse with a lock-held error until `release` is called.

Use to block deploys during a maintenance window, a database migration, or an active investigation.

## Flags

| Flag | Description |
|------|-------------|
| `--message=<text>` | Explanation recorded in the lock file. Defaults to "manual acquire". |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy lock acquire --message="db migration in flight — talk to alice"
```
