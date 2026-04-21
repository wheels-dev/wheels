# accessories

Accessories are long-lived support containers — databases, caches,
queues — that your app depends on but that are not part of the rolling
application deploy. They are booted once (or on demand) and left alone.

## Minimal — Redis

    accessories:
      redis:
        image: redis:7
        host: 1.2.3.5
        port: 6379

## Postgres with volume and env

    accessories:
      db:
        image: postgres:16
        host: 1.2.3.5
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

## Named containers

Accessory containers are named `<service>-<accessory>`, e.g. the
example above yields `myapp-db` and `myapp-redis` containers. Labels
follow the same schema as app containers, so `wheels deploy details`
can list them alongside the app.

## Lifecycle

    wheels deploy accessory boot db              # first-time install
    wheels deploy accessory reboot db            # stop+remove+boot
    wheels deploy accessory start|stop db        # lifecycle
    wheels deploy accessory details|logs db      # observability
    wheels deploy accessory remove db            # tear down

## Multi-host accessories

    accessories:
      redis:
        image: redis:7
        hosts:
          - 1.2.3.5
          - 1.2.3.6

Each host gets its own independent container. No clustering logic —
that's your accessory's job.
