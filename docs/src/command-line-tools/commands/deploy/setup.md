# `wheels deploy setup`

First-time host setup. Boots the proxy and deploys the app.

## Synopsis

```bash
wheels deploy setup [--version=<tag>] [--destination=<name>] [--dry-run]
```

## Description

The "first deploy to a fresh host" entry point. Runs the same steps as `wheels deploy` and boots `kamal-proxy` if it isn't already running. Safe to run repeatedly — every step is idempotent.

After `wheels deploy server bootstrap` installs Docker on a fresh host, `wheels deploy setup` is the next command in the chain. Subsequent rolls use `wheels deploy`.

Accessories are **not** booted by `setup` — boot them explicitly with `wheels deploy accessory boot <name>` (or `all`).

## Flags

| Flag | Description |
|------|-------------|
| `--version=<tag>` | Image tag. Defaults to git short SHA. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy server bootstrap       # install Docker on hosts
wheels deploy setup                  # first-time deploy
wheels deploy accessory boot all     # bring up sidecars
```
