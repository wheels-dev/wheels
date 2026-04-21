# `wheels deploy`

Build, push, and roll out the application to every host. The canonical deploy command.

## Synopsis

```bash
wheels deploy [--version=<tag>] [--destination=<name>] [--dry-run]
```

## Description

The default verb. Executes: lock acquire → `docker pull` on every host → boot `kamal-proxy` if needed → for each role and host, `docker run` the new container and cut over proxy traffic → lock release. Wrapped by `pre-deploy` / `post-deploy` / `post-deploy-failure` hooks if `.kamal/hooks/` entries exist.

If `--version` is omitted, the current `git rev-parse --short HEAD` is used as the image tag.

## Flags

| Flag | Description |
|------|-------------|
| `--version=<tag>` | Image tag to deploy. Defaults to git short SHA. |
| `--destination=<name>` | Layer `config/deploy.<name>.yml` on top. |
| `--configPath=<path>` | Alternate path to `deploy.yml`. |
| `--dry-run` | Print commands without executing. |

## Examples

```bash
wheels deploy
wheels deploy --destination=staging
wheels deploy --version=v1.4.2 --dry-run
```
