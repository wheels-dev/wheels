---
description: >-
  Deploy Wheels applications to one or more Linux hosts with zero-downtime
  rolling releases using the built-in wheels deploy toolchain.
---

# Deployment

`wheels deploy` is a first-party deployment toolchain for shipping a Wheels application to one or more Linux hosts. It builds a Docker image, pushes it to a registry, pulls it onto every server in your fleet, and performs a zero-downtime cut-over behind `kamal-proxy`.

The toolchain is a Lucee/CFML port of [Basecamp's Kamal 2.4.0](https://kamal-deploy.org/), down to the on-server state (container names, labels, lock file, network name). A server deployed by Ruby Kamal can be taken over by `wheels deploy` without cleanup, and vice versa. Every configuration file, hook script, and secrets file is byte-compatible with the upstream.

## When to use it

Reach for `wheels deploy` when you want:

- A small number of long-lived Linux hosts (one to a few dozen).
- Zero-downtime rolling deploys with automatic rollback on health-check failure.
- A configuration file you read end-to-end, not a cloud console you click through.
- Plain SSH + Docker on the server — no agents, no orchestrator, no cluster state.

Reach for something else (Kubernetes, Nomad, Fly, Render, Heroku) when you need autoscaling, multi-region failover, or managed database/queue infrastructure baked into the platform.

## What it does, start to finish

A single `wheels deploy` invocation does the following, in order:

1. **Load** `config/deploy.yml` (plus any `deploy.<destination>.yml` overlay).
2. **Resolve** `.kamal/secrets` locally — evaluating `$(...)` subshells against your secret manager.
3. **Run** `.kamal/hooks/pre-deploy` locally (if present).
4. **Acquire** a deploy lock on the fleet so concurrent deploys refuse.
5. **Pull** the new image on every host over SSH.
6. **Boot** `kamal-proxy` on each host if it is not already running.
7. **Start** the new container for each role on each host, then **cut over** proxy traffic.
8. **Release** the deploy lock.
9. **Run** `.kamal/hooks/post-deploy` locally on success (or `post-deploy-failure` with `KAMAL_ERROR` set if it raised).

Every step is printable up-front with `--dry-run`.

## Documentation layout

The deployment documentation is organized as a shallow tree: one tutorial, one config reference, and a handful of topic guides. Command-by-command documentation lives in the [CLI reference](../../command-line-tools/commands/deploy/).

- [Your first deploy](./first-deploy.md) — end-to-end tutorial. Start here.
- [deploy.yml reference](./config-reference.md) — every top-level key and its value shape.
- [Accessories](./accessories.md) — sidecar containers (Postgres, Redis, search).
- [Secrets](./secrets.md) — `.kamal/secrets`, secret managers, and the five built-in adapters.
- [Hooks](./hooks.md) — lifecycle scripts in `.kamal/hooks/`.
- [Migrating from Kamal](./migrating-from-kamal.md) — for users coming from Ruby Kamal.

## Getting unstuck

Every verb accepts `--dry-run` so you can inspect the exact `docker` / SSH commands that would fire without touching your fleet. Every verb can be scoped to a single destination with `--destination=<name>`, which layers in `config/deploy.<name>.yml` on top of the base file. The audit trail at `/tmp/kamal-audit.log` on each host records every deploy action with timestamp and the user who initiated it.

When in doubt:

```bash
wheels deploy docs                 # list embedded topic docs
wheels deploy docs hooks           # read a single topic doc
wheels deploy config               # print the resolved config
wheels deploy audit --tail=50      # recent deploy activity per host
```

## Prerequisites

- Docker installed locally (for the build step).
- A container registry you can push to.
- One or more Linux hosts reachable by SSH.
- `git` available locally (the default image tag is the short SHA).

See [your first deploy](./first-deploy.md) for the full walkthrough.
