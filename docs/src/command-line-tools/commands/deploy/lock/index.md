# `wheels deploy lock`

Manage the deploy lock manually.

## Verbs

| Verb | Summary |
|------|---------|
| [`acquire`](./acquire.md) | Create the lock file. |
| [`release`](./release.md) | Remove the lock file. |
| [`status`](./status.md) | Show current lock state. |

`wheels deploy` automatically acquires the lock at the start of every run and releases it at the end (even on failure, via `try/finally`). These verbs are for manual intervention — breaking a stuck lock after a crash, or blocking deploys during a maintenance window.

The lock file lives at `/tmp/kamal-lock-<service>` on the hosts. It contains the user who holds it and an optional message.
