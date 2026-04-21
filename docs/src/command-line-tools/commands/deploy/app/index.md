# `wheels deploy app`

Manage app-container lifecycle without running a full deploy.

## Verbs

| Verb | Summary |
|------|---------|
| [`boot`](./boot.md) | Boot a container for a specific version. |
| [`start`](./start.md) | Start an existing stopped container. |
| [`stop`](./stop.md) | Stop a running container. |
| [`details`](./details.md) | Docker `ps` for this service. |
| [`containers`](./containers.md) | List all container IDs. |
| [`images`](./images.md) | List available image tags on the host. |
| [`logs`](./logs.md) | Tail container logs. |
| [`live`](./live.md) | Take containers out of maintenance mode. |
| [`maintenance`](./maintenance.md) | Put containers into maintenance mode (marker-file based). |
| [`remove`](./remove.md) | Remove containers for a specific version. |

All verbs fan out across every host in the relevant role, optionally filtered by `--role=<name>` and `--host=<name>`. Most require `--version=<tag>`; `containers`, `images`, and `logs` do not.
