# `wheels deploy registry login`

Run `docker login` on every host.

## Synopsis

```bash
wheels deploy registry login [--password=<value>] [--destination=<name>] [--dry-run]
```

## Description

Authenticates every host with the configured registry. Username comes from `registry.username` in `deploy.yml`; password comes from `.kamal/secrets` via the first key listed under `registry.password:`, or from `--password` when explicitly provided (useful for tests).

Called automatically by the main deploy flow. Use manually to debug auth issues or to refresh ECR credentials between deploys.

## Flags

| Flag | Description |
|------|-------------|
| `--password=<value>` | Override the resolved password. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy registry login
```
