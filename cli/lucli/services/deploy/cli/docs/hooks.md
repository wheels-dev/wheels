# hooks

Hooks are plain shell scripts in `.kamal/hooks/` that run locally on the
control machine at specific points in a deploy. They are optional — if
the file doesn't exist, the hook is skipped.

## Supported hooks

- `pre-deploy` — before any host work starts. Abort the deploy by
  exiting non-zero.
- `post-deploy` — after a successful deploy.
- `post-deploy-failure` — after a deploy that raised. Useful for
  paging / notifying on failures.

## Environment variables

Every hook runs with these vars in its environment:

- `KAMAL_VERSION` — the version being deployed (git short sha by default)
- `KAMAL_HOSTS` — comma-separated list of hosts touched
- `KAMAL_RUNTIME` — seconds elapsed (post-deploy and post-deploy-failure)
- `KAMAL_ERROR` — error message (post-deploy-failure only)

## Example — Slack notification

    ##!/usr/bin/env bash
    ## .kamal/hooks/post-deploy
    curl -X POST "$SLACK_WEBHOOK_URL" \
      -H 'Content-Type: application/json' \
      -d "{\"text\":\":ship: Deployed $KAMAL_VERSION in ${KAMAL_RUNTIME}s\"}"

## Example — smoke test before deploy

    ##!/usr/bin/env bash
    ## .kamal/hooks/pre-deploy
    curl -sf https://staging.example.com/up || exit 1

## Making a hook executable

Hooks are invoked directly by `ProcessBuilder`, so the file must be
executable. After writing a hook:

    chmod +x .kamal/hooks/post-deploy

## Output

Hook stdout/stderr is merged and prefixed `[hook:<name>]` in the deploy
log. A non-zero exit from `pre-deploy` aborts the deploy; a non-zero
exit from `post-deploy` fails the deploy after-the-fact (useful for
smoke tests).

`post-deploy-failure` is best-effort: it runs on an already-failed
deploy, so a non-zero exit from the hook is logged
(`[hook:post-deploy-failure] ...`) and never replaces the original
deploy error. The deploy rethrows the real failure either way.
