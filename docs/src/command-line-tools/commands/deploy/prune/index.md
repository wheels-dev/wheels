# `wheels deploy prune`

Reclaim disk by cleaning up old images and containers on every host.

## Verbs

| Verb | Summary |
|------|---------|
| [`all`](./all.md) | Remove old containers and dangling images. |
| [`images`](./images.md) | Remove dangling images. |
| [`containers`](./containers.md) | Remove old containers, keeping the N most recent. |

Deploys generate container and image churn — each version keeps a container and a tagged image on every host. Prune weekly (or on a schedule) to keep hosts from filling up.
