# `wheels deploy lock release`

Release a held deploy lock.

## Synopsis

```bash
wheels deploy lock release [--destination=<name>] [--dry-run]
```

## Description

Removes `/tmp/kamal-lock-<service>` on the fleet. After release, normal deploys resume.

Use to unstick a lock left by a crashed `wheels deploy` — `wheels deploy` releases via `try/finally` on any exception, but if the control machine itself dies mid-deploy the lock can remain.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy lock release
```
