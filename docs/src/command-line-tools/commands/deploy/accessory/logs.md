# `wheels deploy accessory logs`

Tail logs from a sidecar container.

## Synopsis

```bash
wheels deploy accessory logs <name|all> [--tail=<N>] [--follow] [--destination=<name>]
```

## Description

Runs `docker logs` on the accessory container. With `all`, logs every accessory in sequence.

## Flags

| Flag | Description |
|------|-------------|
| `--tail=<N>` | Lines. Defaults to 100. |
| `--follow` | Stream logs (long-lived SSH connection). |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy accessory logs db --tail=500
wheels deploy accessory logs redis --follow
```
