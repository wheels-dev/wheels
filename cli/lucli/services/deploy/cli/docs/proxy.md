# proxy

`kamal-proxy` is the zero-downtime reverse proxy that routes public traffic
into app containers. It runs as a single long-lived container on every
host that serves a `web` role, and it is booted once at deploy time.

## Minimal config

    proxy:
      host: myapp.example.com
      ssl: true

## All options

    proxy:
      host: myapp.example.com
      app_port: 3000           # port inside the app container
      healthcheck:
        path: /up
        timeout: 30
      ssl: true                # automatic Let's Encrypt cert
      forward_headers: true    # pass X-Forwarded-* to app
      buffering:
        requests: true
        responses: true

## Zero-downtime deploys

When a new version boots, `wheels deploy` calls
`docker exec kamal-proxy kamal-proxy deploy <service>` with the new
container's name. Proxy drains in-flight requests to the old container
and begins routing fresh traffic to the new one. If the new container
fails the health check, the proxy refuses to cut over, and the old
container stays authoritative.

## Commands

    wheels deploy proxy boot       # first-time install
    wheels deploy proxy reboot     # stop, remove, reinstall
    wheels deploy proxy start|stop # lifecycle
    wheels deploy proxy details    # docker ps for kamal-proxy
    wheels deploy proxy logs       # tail proxy logs
    wheels deploy proxy remove     # tear down

## Port 80/443 collisions

`kamal-proxy` binds the host's :80 and :443 directly. If another service
(nginx, Traefik) is already there, the boot fails fast. Stop the other
service before `wheels deploy proxy boot`.
