# `wheels deploy registry logout`

Run `docker logout` on every host.

## Synopsis

```bash
wheels deploy registry logout [--destination=<name>] [--dry-run]
```

## Description

Clears cached Docker credentials on every host. Called automatically as part of `wheels deploy remove --confirm`. Use manually after rotating credentials — subsequent deploys will be forced to re-log in with the new secret.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy registry logout
```
