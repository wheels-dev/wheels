# `wheels deploy server bootstrap`

Install Docker on every host that doesn't have it.

## Synopsis

```bash
wheels deploy server bootstrap [--destination=<name>] [--dry-run]
```

## Description

Runs a single idempotent command on every host in `servers:`:

```bash
which docker >/dev/null 2>&1 || curl -fsSL https://get.docker.com | sh
```

Hosts that already have Docker are skipped. The first command you run on a fresh Linux VM. After it succeeds, run `wheels deploy setup`.

Assumes `curl` is available on the host and the SSH user has `sudo` without password (or Docker installation permission). For hosts with custom provisioning needs, install Docker through your own tool and skip this verb.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy server bootstrap
```
