# `wheels deploy proxy`

Lifecycle commands for the `kamal-proxy` container.

## Verbs

| Verb | Summary |
|------|---------|
| [`boot`](./boot.md) | First-time install of `kamal-proxy`. |
| [`reboot`](./reboot.md) | Stop, remove, and boot again. |
| [`start`](./start.md) | Start a stopped proxy. |
| [`stop`](./stop.md) | Stop the proxy. |
| [`restart`](./restart.md) | Stop then start. |
| [`details`](./details.md) | `docker ps` for the proxy. |
| [`logs`](./logs.md) | Tail proxy logs. |
| [`remove`](./remove.md) | Tear down the proxy container. |

`kamal-proxy` runs as a single long-lived container per host. Every verb iterates all hosts across every role and dispatches the same command.

Port 80/443 collisions: `kamal-proxy` binds host ports :80 and :443 directly. If another web server (nginx, Traefik) already holds them, `boot` fails fast — stop the other service first.
