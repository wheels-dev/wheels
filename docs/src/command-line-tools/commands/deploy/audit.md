# `wheels deploy audit`

Tail the on-server audit log (`/tmp/kamal-audit.log`) from every host.

## Synopsis

```bash
wheels deploy audit [--tail=<N>] [--destination=<name>]
```

## Description

Each deploy appends timestamped entries to `/tmp/kamal-audit.log` on the host — who triggered the deploy, which version, which role, and the result. `audit` runs `tail -n <N>` on every host and aggregates the output, prefixed by host name.

## Flags

| Flag | Description |
|------|-------------|
| `--tail=<N>` | Lines per host. Defaults to 100. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy audit
wheels deploy audit --tail=500
wheels deploy audit --destination=staging --tail=50
```
