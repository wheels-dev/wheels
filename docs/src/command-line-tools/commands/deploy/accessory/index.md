# `wheels deploy accessory`

Lifecycle commands for sidecar containers (databases, caches, queues).

## Verbs

| Verb | Summary |
|------|---------|
| [`boot`](./boot.md) | First-time install of the accessory. |
| [`reboot`](./reboot.md) | Stop, remove, and re-install. |
| [`start`](./start.md) | Start a stopped accessory. |
| [`stop`](./stop.md) | Stop a running accessory. |
| [`restart`](./restart.md) | Stop then start. |
| [`details`](./details.md) | `docker ps` for the accessory. |
| [`logs`](./logs.md) | Tail accessory logs. |
| [`remove`](./remove.md) | Tear down the accessory container. |

Every verb takes a positional accessory name — one of the keys under `accessories:` in `deploy.yml`, or the literal `all` to fan out across every accessory.

Accessories are decoupled from the main deploy rhythm — they run their own lifecycle, on their own hosts, with their own volumes. See the [accessories guide](../../../../working-with-wheels/deployment/accessories.md) for when to use them (and when to reach for managed infrastructure instead).
