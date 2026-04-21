# `wheels deploy details`

Aggregate container status across app, proxy, and accessories.

## Synopsis

```bash
wheels deploy details [--destination=<name>]
```

## Description

For every host in the fleet, runs `docker ps` filtered by the service label (`app.containers`), then `proxy.details` for `kamal-proxy`, then `accessory.details` for every accessory. One-shot snapshot of the whole deployment.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy details
wheels deploy details --destination=production
```
