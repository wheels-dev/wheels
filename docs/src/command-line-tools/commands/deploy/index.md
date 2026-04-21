---
description: >-
  CLI reference for the wheels deploy toolchain. Every verb, organized by
  subcommand group.
---

# `wheels deploy`

The `wheels deploy` surface is a CFML port of [Kamal 2.4.0](https://kamal-deploy.org/). It deploys a Wheels application to one or more Linux hosts over SSH, using Docker + `kamal-proxy` for zero-downtime rolling releases.

For the conceptual overview and getting-started walkthrough, see the [deployment guide](../../../working-with-wheels/deployment/index.md). The pages below are the command reference.

## Top-level verbs

| Verb | Summary |
|------|---------|
| [`deploy`](./deploy.md) | Build, push, and roll out the app to every host. |
| [`redeploy`](./redeploy.md) | Redeploy the current version (no build). |
| [`rollback`](./rollback.md) | Roll back to a previously-deployed version. |
| [`setup`](./setup.md) | First-time setup: boot accessories + deploy. |
| [`init`](./init.md) | Scaffold `config/deploy.yml` and `.kamal/secrets`. |
| [`config`](./config.md) | Print the resolved deploy configuration. |
| [`version`](./version.md) | Print the version and upstream Kamal commit. |
| [`audit`](./audit.md) | Tail the `/tmp/kamal-audit.log` on every host. |
| [`details`](./details.md) | Aggregate `app.containers` + `proxy.details` + accessories. |
| [`docs`](./docs.md) | Print embedded topic docs. |
| [`remove`](./remove.md) | Destructive teardown. Requires `--confirm`. |

## Subcommand groups

| Group | Scope |
|-------|-------|
| [`app`](./app/index.md) | App container lifecycle (boot, start, stop, logs, containers, images, live, maintenance, remove). |
| [`proxy`](./proxy/index.md) | `kamal-proxy` lifecycle (boot, reboot, start, stop, restart, details, logs, remove). |
| [`accessory`](./accessory/index.md) | Sidecar container lifecycle (boot, reboot, start, stop, restart, details, logs, remove). |
| [`build`](./build/index.md) | Image building (deliver, push, pull, create, remove, details, dev). |
| [`registry`](./registry/index.md) | Registry auth (setup, login, logout, remove). |
| [`server`](./server/index.md) | Host-level ops (exec, bootstrap). |
| [`prune`](./prune/index.md) | Cleanup (all, images, containers). |
| [`lock`](./lock/index.md) | Manual deploy-lock ops (acquire, release, status). |
| [`secrets`](./secrets/index.md) | Secret resolution (fetch, extract, print). |

## Common flags

Every `wheels deploy` verb accepts these:

- `--dry-run` — Print the `docker`/SSH commands that would fire, without touching the fleet.
- `--destination=<name>` — Layer `config/deploy.<name>.yml` on top of the base config.
- `--configPath=<path>` — Override the default config path (`config/deploy.yml`).
- `--version=<tag>` — Target a specific version. Defaults to `git rev-parse --short HEAD`.

Role- and host-scoped verbs add `--role=<name>` and `--host=<name>` filters where applicable.

## The verb hierarchy at a glance

```
wheels deploy                      # build + push + rolling deploy
wheels deploy redeploy             # same image, fresh containers
wheels deploy rollback --version=abc123

wheels deploy app boot|start|stop|logs|containers|images|live|maintenance|remove
wheels deploy proxy boot|reboot|start|stop|restart|details|logs|remove
wheels deploy accessory boot|reboot|start|stop|restart|details|logs|remove <name|all>
wheels deploy build deliver|push|pull|create|remove|details|dev
wheels deploy registry setup|login|logout|remove
wheels deploy server exec "<cmd>" [--host=<name>]
wheels deploy server bootstrap
wheels deploy prune all|images|containers
wheels deploy lock acquire|release|status
wheels deploy secrets fetch|extract|print
```
