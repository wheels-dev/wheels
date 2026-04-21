# `wheels deploy build`

Image-building commands. Most run locally on your dev machine.

## Verbs

| Verb | Summary | Runs |
|------|---------|------|
| [`deliver`](./deliver.md) | Build, push, then pull on all hosts. | Local + hosts |
| [`push`](./push.md) | Build and push to the registry. | Local |
| [`pull`](./pull.md) | Pull the image on every host. | Hosts |
| [`create`](./create.md) | Create a buildx builder instance. | Local |
| [`remove`](./remove.md) | Remove the buildx builder instance. | Local |
| [`details`](./details.md) | Describe the buildx builder. | Local |
| [`dev`](./dev.md) | Build for local development only (no push). | Local |

The typical deploy flow calls `build push` automatically; these commands exist for explicit control (e.g., building in CI and then pulling on hosts from a later job).
