# servers

Your `deploy.yml` `servers:` key defines which hosts the app runs on.

## Simple array (single "web" role)

    servers:
      - 1.2.3.4
      - 1.2.3.5

## Named roles

    servers:
      web:
        - 1.2.3.4
      job:
        - 1.2.3.5

## Role with env overrides

    servers:
      web:
        hosts:
          - 1.2.3.4
        env:
          clear:
            RAILS_MAX_THREADS: 5

## Role with options and labels

    servers:
      web:
        hosts:
          - 1.2.3.4
        options:
          memory: 2gb
          cpus: 2
        labels:
          my-label: value

## How role semantics flow

The `web` role is special — it is the only role the proxy routes public
traffic to. Non-web roles (like `job`, `worker`) are started and stopped
just like `web` but do not get a `kamal-proxy deploy` call, so they are
not reachable from outside the host fleet.

Containers are named `<service>-<role>-<version>`. Every container gets
labels for `service=`, `role=`, `destination=`, and `version=`, which
Kamal uses to locate containers for `app details`, `app remove`, and
rollback.

`servers:` is the minimum required block in `deploy.yml` — without it,
`wheels deploy` has nowhere to run. You can also split environment
overrides using the `--destination=<env>` flag, which pulls in a
`deploy.<env>.yml` overlay on top of this file.
