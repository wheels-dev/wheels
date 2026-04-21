# `wheels deploy registry`

Manage Docker registry authentication on the fleet.

## Verbs

| Verb | Summary |
|------|---------|
| [`setup`](./setup.md) | Alias for `login`. |
| [`login`](./login.md) | `docker login` on every host. |
| [`logout`](./logout.md) | `docker logout` on every host. |
| [`remove`](./remove.md) | Alias for `logout`. |

Registry credentials are pulled from `.kamal/secrets` using the first key listed under `registry.password:` in `deploy.yml`. The main `wheels deploy` flow logs in automatically before `docker pull`, so you rarely need these verbs directly — they're useful for debugging auth failures.
