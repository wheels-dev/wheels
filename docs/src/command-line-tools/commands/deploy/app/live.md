# `wheels deploy app live`

Take the app out of maintenance mode.

## Synopsis

```bash
wheels deploy app live --version=<tag> [--role=<name>] [--destination=<name>] [--dry-run]
```

## Description

The inverse of `wheels deploy app maintenance`. Removes the on-server marker file that the current Wheels port uses to signal maintenance mode — the app starts accepting traffic normally on the next proxy check.

The current implementation uses a marker file on the host. A Phase 3 follow-up will switch to `kamal-proxy`-native maintenance for parity with Ruby Kamal 2.8.2.

## Flags

| Flag | Description |
|------|-------------|
| `--version=<tag>` | **Required.** |
| `--role=<name>` | Filter to a single role. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy app live --version=abc123
```
