# `wheels deploy init`

Scaffold `config/deploy.yml` and `.kamal/secrets` in the project root.

## Synopsis

```bash
wheels deploy init [--service=<name>] [--image=<repo>] [--registryUsername=<user>] [--force]
```

## Description

Creates:

- `config/deploy.yml` — starter deployment manifest.
- `.kamal/secrets` — starter secrets file (placeholder values).
- `.kamal/hooks/` — empty directory for lifecycle scripts.

If `config/deploy.yml` already exists, the command refuses to overwrite without `--force`. The generated files are starting points — expect to edit `servers`, `proxy.host`, and `registry.username` before the first deploy.

## Flags

| Flag | Description |
|------|-------------|
| `--service=<name>` | Service name. Defaults to the current directory name. |
| `--image=<repo>` | Docker repository. Defaults to `<service>/web`. |
| `--registryUsername=<user>` | Registry username. Defaults to `changeme`. |
| `--force` | Overwrite `config/deploy.yml` if it exists. |

## Examples

```bash
wheels deploy init
wheels deploy init --service=myapp --image=alice/myapp --registryUsername=alice
wheels deploy init --force
```
