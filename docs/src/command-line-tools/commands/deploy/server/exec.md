# `wheels deploy server exec`

Run a shell command on one or every host.

## Synopsis

```bash
wheels deploy server exec --cmd="<shell-command>" [--host=<name>] [--destination=<name>] [--dry-run]
```

## Description

Opens an SSH session to each host (filtered by `--host`, if given) and runs the literal command. Output is printed per-host, prefixed by host name.

Useful for one-off inspections (`uptime`, `docker logs`, `df -h`) without editing `deploy.yml`.

`--host=<name>` restricts to a single host; the hostname must appear in the resolved `servers:` list or the command errors.

## Flags

| Flag | Description |
|------|-------------|
| `--cmd="<cmd>"` | **Required.** Shell command to run. |
| `--host=<name>` | Target a single host. |
| `--destination=<name>` | Per-destination overlay. |
| `--dry-run` | Print, don't execute. |

## Examples

```bash
wheels deploy server exec --cmd="uptime"
wheels deploy server exec --cmd="docker ps" --host=10.0.0.1
wheels deploy server exec --cmd="df -h /var/lib/docker"
```
