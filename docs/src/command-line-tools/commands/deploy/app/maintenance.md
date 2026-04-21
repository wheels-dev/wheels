# `wheels deploy app maintenance`

Put the app into maintenance mode.

## Synopsis

```bash
wheels deploy app maintenance --version=<tag> [--role=<name>] [--destination=<name>] [--dry-run]
```

## Description

Writes a marker file on each host that signals maintenance mode. Use `wheels deploy app live --version=<tag>` to exit.

**Implementation note:** the current Wheels port uses a marker file on the host — not `kamal-proxy`'s native maintenance mode. Full proxy-native parity with Ruby Kamal 2.8.2 lands in a Phase 3 follow-up. For scheduled maintenance windows the marker approach works; for instant cut-over during an outage, the semantics differ slightly.

## Flags

| Flag | Description |
|------|-------------|
| `--version=<tag>` | **Required.** |
| `--role=<name>` | Filter to a single role. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy app maintenance --version=abc123
wheels deploy app live --version=abc123
```
