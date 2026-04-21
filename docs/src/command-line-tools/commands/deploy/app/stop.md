# `wheels deploy app stop`

Stop a running container for a specific version.

## Synopsis

```bash
wheels deploy app stop --version=<tag> [--role=<name>] [--destination=<name>] [--dry-run]
```

## Description

Runs `docker stop <container>` on each host for the given version. Traffic routing is not affected — the proxy continues pointing at whatever container it last cut over to. If you stop the active container without cutting over first, public traffic breaks.

## Flags

| Flag | Description |
|------|-------------|
| `--version=<tag>` | **Required.** |
| `--role=<name>` | Filter to a single role. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy app stop --version=old123
```
