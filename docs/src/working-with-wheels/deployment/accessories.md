---
description: >-
  Sidecar containers for databases, caches, and queues. When to use the
  accessories block — and when to reach for managed infrastructure instead.
---

# Accessories

Accessories are long-lived support containers — databases, caches, search engines, queues — that your app depends on but that are not part of the rolling application deploy. They are booted once and left alone until you explicitly reboot them.

## The `accessories:` block

Add each sidecar as a named entry under `accessories:` in `config/deploy.yml`:

```yaml
accessories:
  redis:
    image: redis:7
    host: 10.0.0.3
    port: 6379

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

  search:
    image: opensearchproject/opensearch:2
    hosts:
      - 10.0.0.4
      - 10.0.0.5
    port: 9200
    env:
      clear:
        discovery.type: single-node
```

The container is named `<service>-<accessory-name>` — the example above produces `myapp-redis`, `myapp-db`, and `myapp-search` containers. Labels follow the same schema as app containers so `wheels deploy details` lists them alongside the app.

## Lifecycle

Accessories have their own command surface — they do not boot, reboot, or roll alongside the main app:

```bash
wheels deploy accessory boot db          # first-time install
wheels deploy accessory reboot db        # stop, remove, boot again
wheels deploy accessory start db         # start after a stop
wheels deploy accessory stop db          # lifecycle stop, data preserved
wheels deploy accessory restart db       # stop then start
wheels deploy accessory details db       # docker ps for this accessory
wheels deploy accessory logs db --tail=100
wheels deploy accessory remove db        # tear down (preserves volumes)
```

Pass `all` as the name to fan out over every accessory:

```bash
wheels deploy accessory boot all
wheels deploy accessory details all
```

## Multi-host accessories

An accessory with `hosts:` (plural) runs an independent container on each listed host. There is no clustering logic — replication, sharding, or failover is the accessory image's responsibility.

```yaml
accessories:
  redis:
    image: redis:7
    hosts:
      - 10.0.0.3
      - 10.0.0.4
```

## Volumes and files

Persistent data belongs in a `volumes:` mount. The `files:` key (single-file bind mount, read-only) is useful for init SQL, config files, and seed data that you want to version-control:

```yaml
accessories:
  db:
    image: postgres:16
    host: 10.0.0.3
    volumes:
      - /data/pg:/var/lib/postgresql/data        # persistent
    files:
      - config/pg/init.sql:/docker-entrypoint-initdb.d/init.sql
      - config/pg/postgresql.conf:/etc/postgresql/postgresql.conf
```

The left side of `:` in `files:` is resolved **relative to the project root** on your dev machine and copied to the host at deploy time.

## Port exposure

Setting `port:` binds the accessory to the host's public interface on that port. Omit it to keep the accessory on the Docker network only — the app reaches it via the container name (e.g., `myapp-redis:6379`).

For production, keep accessories off the public interface unless you have a concrete reason:

```yaml
accessories:
  redis:
    image: redis:7
    host: 10.0.0.3
    # No port: block — reachable only at redis://myapp-redis:6379 from app containers
```

## When to use accessories

Accessories are a fit for:

- **Development and staging** — spin up a cheap Postgres/Redis per environment without provisioning managed infrastructure.
- **Small production deployments** — a single-host app with a co-located database is a legitimate stack for small tools and internal apps.
- **Caches and queues** — Redis, Memcached, RabbitMQ where replacing the accessory container is cheap and state loss is tolerable.
- **Dev-only sidecars** — Mailhog, local S3 emulators, log aggregators.

## When **not** to use accessories

Accessories are a poor fit for:

- **Production databases with real customer data.** Postgres, MySQL, MongoDB in production should live on managed infrastructure (RDS, Cloud SQL, Atlas) or on hosts that are themselves backed up, replicated, and monitored. An accessory in `deploy.yml` has no backup strategy, no point-in-time recovery, and no failover. `wheels deploy accessory remove` can wipe it in one command.
- **Anything that needs horizontal scaling.** Kubernetes, Nomad, and managed services handle scaling out; accessories are single-container-per-host.
- **Anything that needs cross-host state replication.** Elasticsearch clusters, Galera, MongoDB replica sets — accessories happily run the container but provide zero cluster-awareness.

A common production pattern: use `accessories:` for Redis and a small search index while pointing the app at an external RDS instance via `env.clear.DATABASE_URL`. The line between "cheap and rebuildable" and "protect this at all costs" is where accessories end and managed infrastructure begins.

## Interaction with the main deploy

`wheels deploy` **does not** touch accessories. It deploys the app and proxy only. Accessories are managed entirely through `wheels deploy accessory <verb>`. This separation is deliberate — you should never roll a database by pushing a new app version.

The exception is `wheels deploy remove --confirm`, which tears down everything including accessories — a destructive teardown for test environments.

## Inspecting accessories

```bash
wheels deploy details                    # app + proxy + all accessories
wheels deploy accessory details all
wheels deploy accessory logs db --tail=500 --follow
```

The accessory containers show up in `docker ps` on the host with the service and accessory-name labels, so you can filter manually:

```bash
ssh deploy@10.0.0.3 'docker ps --filter label=service=myapp'
```
