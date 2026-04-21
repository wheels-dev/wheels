# `wheels deploy secrets`

Resolve and inspect deploy-time secrets.

## Verbs

| Verb | Summary |
|------|---------|
| [`fetch`](./fetch.md) | Pull values from a secret manager (1Password, Bitwarden, AWS, LastPass, Doppler). |
| [`extract`](./extract.md) | Pull a single key from a KEY=VALUE text block. |
| [`print`](./print.md) | Resolve `.kamal/secrets` and print as KEY=VALUE. |

All three verbs run locally only — they don't SSH anywhere. Useful for debugging secrets resolution and for scripting integrations with secret managers that don't have a first-party adapter.

See the [secrets guide](../../../../working-with-wheels/deployment/secrets.md) for the `.kamal/secrets` file format and the five built-in adapters.
