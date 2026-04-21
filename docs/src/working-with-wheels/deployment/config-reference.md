---
description: >-
  Complete reference for every top-level key in config/deploy.yml. Value shapes,
  defaults, and common patterns.
---

# `deploy.yml` Reference

`config/deploy.yml` is the single manifest that drives every `wheels deploy` command. It is a plain YAML file — no templating other than a restricted Mustache context (`{{env.NAME}}`, `{{destination}}`, `{{hostname}}`). If you have seen Kamal's `config/deploy.yml`, this file is byte-compatible apart from that one divergence.

The schema below mirrors [Kamal 2.4.0](https://kamal-deploy.org/docs/configuration/overview). Keys that do not appear here are either aliases, internal, or reserved for future use.

## `service` (required)

The service name. Used to derive container names (`<service>-<role>-<version>`), the proxy network name, the lock file path (`/tmp/kamal-lock-<service>`), and label values. Must match `[a-z0-9_-]+`.

```yaml
service: myapp
```

## `image` (required)

The Docker image repository name (without the registry prefix). Combined with `registry.server` and the version tag to form the full reference: `<server>/<image>:<version>`.

```yaml
image: alice/myapp/web
```

## `servers` (required)

The hosts the app runs on. Three shapes are accepted.

**Flat array** — every host gets the implicit `web` role:

```yaml
servers:
  - 10.0.0.1
  - 10.0.0.2
```

**Named roles** — one role per key, value is an array of hosts:

```yaml
servers:
  web:
    - 10.0.0.1
  job:
    - 10.0.0.2
```

**Role with options** — full form for per-role overrides:

```yaml
servers:
  web:
    hosts:
      - 10.0.0.1
    env:
      clear:
        RAILS_MAX_THREADS: 5
    options:
      memory: 2gb
      cpus: 2
    labels:
      tier: frontend
```

The `web` role is special — it is the only role that `kamal-proxy` routes public traffic to. Non-web roles (`job`, `worker`, etc.) start and stop just like `web` but stay internal to the host fleet.

## `registry`

Where Docker pushes and pulls images. Every host must be able to reach this registry.

```yaml
registry:
  server: ghcr.io        # optional; defaults to Docker Hub
  username: alice
  password:
    - KAMAL_REGISTRY_PASSWORD
```

`password:` is an array of **secret names**, not literal values. Each name is resolved from `.kamal/secrets` at deploy time. If you list multiple, the first one is used.

For ECR, the password rotates every 12 hours — wire up `.kamal/secrets` to shell out to `aws ecr get-login-password` so it is always fresh.

## `builder`

Controls how `docker build` runs. If omitted, defaults to a local build from `.` using `./Dockerfile`.

```yaml
builder:
  context: .
  dockerfile: Dockerfile
  arch:
    - amd64
    - arm64
  args:
    BUN_VERSION: 1.1.0
  remote: ssh://deploy@builder.example.com
```

- `arch:` list triggers a `docker buildx` multi-arch build. On a single-arch laptop, foreign architectures emulate through QEMU, which is slow.
- `remote:` delegates the build to a remote Docker host over SSH. Faster than emulated cross-compile.
- `args:` become `--build-arg` flags.

For advanced builder configuration (bake, secrets, SSH agent forwarding), see [Kamal's upstream docs](https://kamal-deploy.org/docs/configuration/builder).

## `env`

Environment variables shipped into containers. Two buckets: `clear` (literals, committed in git) and `secret` (names resolved from `.kamal/secrets`).

```yaml
env:
  clear:
    WHEELS_ENV: production
    DB_HOST: db.internal
  secret:
    - DATABASE_URL
    - WHEELS_RELOAD_PASSWORD
```

Per-role env overrides merge on top of top-level env. For a single key, the winner is whichever layer names it last: role `clear` > role `secret` > top-level `clear` > top-level `secret`. A running container keeps its original env — redeploy to pick up changes.

## `ssh`

SSH connection parameters. Sensible defaults (current user, default agent key) usually suffice.

```yaml
ssh:
  user: deploy
  port: 22
  proxy: bastion.example.com
  keys:
    - ~/.ssh/deploy_key
  forward_agent: true
```

`proxy:` maps to OpenSSH's `ProxyJump` — useful when hosts live behind a bastion. `forward_agent:` is off by default; turn it on only if a build step or hook needs your local agent inside the container.

## `proxy`

Configures the `kamal-proxy` container that fronts public traffic.

```yaml
proxy:
  host: app.example.com
  app_port: 8080
  healthcheck:
    path: /up
    interval: 1
    timeout: 30
  ssl: true
  forward_headers: true
  buffering:
    requests: true
    responses: true
```

- `host:` is the DNS name for SSL certificate issuance and `Host:` header routing.
- `app_port:` is the port inside the app container. Must match what your app listens on.
- `ssl: true` triggers automatic Let's Encrypt cert issuance.
- `healthcheck.path:` is polled before the proxy cuts traffic to a new container. Must return `200 OK`. If it fails, the old container stays authoritative.
- `forward_headers: true` passes `X-Forwarded-*` through to the app — required for the app to see the real client IP.

## `boot`

Controls the rolling restart. Optional.

```yaml
boot:
  limit: 1                # max parallel boots per role
  wait: 10                # seconds between each boot
```

`limit: 1` (the default) is safe — one container at a time, serially. Raise it only if you have enough capacity to run multiple old + new containers simultaneously.

## `healthcheck`

Top-level healthcheck — distinct from `proxy.healthcheck`. This one is the Docker `HEALTHCHECK` applied to the container itself and is checked at boot time before the proxy cut-over even begins.

```yaml
healthcheck:
  path: /up
  port: 8080
  interval: 3
  max_attempts: 7
```

In practice, set `proxy.healthcheck` for most apps — it's the one that gates the proxy cut-over, which is what users care about. The top-level `healthcheck` catches container crashes that never get far enough to respond.

## `hooks`

Controls local hook script behavior. Hook **scripts** live in `.kamal/hooks/` — the YAML block only customizes the directory or adds pre-connect gating.

```yaml
hooks:
  path: .kamal/hooks
  pre-connect:
    - echo "connecting..."
```

You rarely need this block. See the [hooks guide](./hooks.md) for the actual scripting model.

## `accessories`

Sidecar containers — databases, caches, queues. Each accessory is a named map with its own image, host(s), env, volumes, and port map.

```yaml
accessories:
  db:
    image: postgres:16
    host: 10.0.0.3
    port: 5432
    env:
      clear:
        POSTGRES_USER: app
      secret:
        - POSTGRES_PASSWORD
    volumes:
      - /data/pg:/var/lib/postgresql/data
    files:
      - config/init.sql:/docker-entrypoint-initdb.d/init.sql
  redis:
    image: redis:7
    host: 10.0.0.3
    port: 6379
```

Container names are `<service>-<accessory-name>` (`myapp-db`, `myapp-redis`). Accessories run lifecycle commands independently from the app — see [the accessories guide](./accessories.md) for when to use them and when not to.

## `volumes`

Host paths to mount into the app container on every role.

```yaml
volumes:
  - /var/log/myapp:/app/log
  - /var/myapp/uploads:/app/storage
```

The path left of the `:` is on the host, right side is inside the container. Host paths must exist (or be creatable by the SSH user).

## `logging`

Docker log driver and options applied to the app container.

```yaml
logging:
  driver: json-file
  options:
    max-size: 100m
    max-file: "3"
```

## `asset_path`

Used by the asset fingerprinting path rewriter — see Kamal's [upstream docs](https://kamal-deploy.org/docs/configuration/assets). Not commonly needed for Wheels apps that serve assets from `public/`.

## `labels`

Extra labels applied to the app container. Service, role, destination, and version labels are added automatically.

```yaml
labels:
  team: platform
  app.example.com/tier: frontend
```

## Multiple destinations

For staging and production, split the configuration into a base file plus per-destination overlays:

- `config/deploy.yml` — base, shared keys.
- `config/deploy.staging.yml` — staging overrides.
- `config/deploy.production.yml` — production overrides.

The overlay deep-merges on top of the base. Select with `--destination=<name>`:

```bash
wheels deploy --destination=staging
wheels deploy --destination=production
```

Common pattern — override only `servers`, `proxy.host`, and a handful of env values per destination while keeping `service`, `image`, `builder`, and `registry` in the base.

## Mustache expressions

A restricted set of Mustache expressions can appear in values:

- `{{env.VAR_NAME}}` — local environment variable at deploy time.
- `{{destination}}` — the `--destination` flag value.
- `{{hostname}}` — the target host (inside per-host contexts only).

This is a **deliberate** divergence from Ruby Kamal, which allows full ERB. Mustache keeps the config declarative and safe — a deploy config can be reviewed without worrying about arbitrary Ruby execution. If you relied on ERB in a Ruby Kamal config, you will need to rewrite those expressions — see the [migration guide](./migrating-from-kamal.md).

## Minimal example

The smallest useful `deploy.yml`:

```yaml
service: myapp
image: alice/myapp

servers:
  - 10.0.0.1

proxy:
  host: app.example.com
  ssl: true
  app_port: 8080

registry:
  username: alice
  password:
    - KAMAL_REGISTRY_PASSWORD
```

With a matching `.kamal/secrets`:

```bash
KAMAL_REGISTRY_PASSWORD=$(op read op://Deploy/DockerHub/password)
```

## Seeing the resolved config

After destination overlays, environment interpolation, and default filling, the effective config can be printed with:

```bash
wheels deploy config
wheels deploy config --destination=production
```

Diff two destinations to spot drift:

```bash
diff <(wheels deploy config --destination=staging) <(wheels deploy config --destination=production)
```
