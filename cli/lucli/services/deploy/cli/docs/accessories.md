# accessories

Accessories are long-lived support containers — databases, caches,
queues — that your app depends on but that are not part of the rolling
application deploy. They are booted once (or on demand) and left alone.

## Minimal — Redis

    accessories:
      redis:
        image: redis:7
        host: 1.2.3.5
        port: "127.0.0.1:6379:6379"

## Postgres with volume and env

    accessories:
      db:
        image: postgres:16
        host: 1.2.3.5
        port: "127.0.0.1:5432:5432"
        env:
          clear:
            POSTGRES_USER: app
          secret:
            - POSTGRES_PASSWORD
        volumes:
          - /data/pg:/var/lib/postgresql/data
        files:
          - config/init.sql:/docker-entrypoint-initdb.d/init.sql

`port:` must name a bind address: "<address>:<host port>:<container
port>" (IPv4, or bracketed IPv6), optionally ending in /tcp, /udp or
/sctp. Use 127.0.0.1 for the host only, a private address such as
10.0.0.20 for other hosts on a private network, or 0.0.0.0 to publish
it on every interface. A bare `port: 5432` fails validation. App
containers on the same host don't need `port:`: they reach the
accessory as `<service>-<name>` over the kamal network.

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
