---
description: >-
  Lifecycle scripts in .kamal/hooks/. The KAMAL_* environment contract and
  common recipes — Slack notifications, smoke tests, cache purges.
---

# Hooks

Hooks are plain shell scripts in `.kamal/hooks/` that run locally on your dev machine (or CI runner) at specific points in a deploy. They are optional — if the file doesn't exist, the hook is skipped without complaint.

## Supported lifecycle points

Three hooks are supported today:

| Hook | Fires | Can abort? |
|------|-------|------------|
| `pre-deploy` | Before any host work starts. | Yes — non-zero exit aborts the deploy. |
| `post-deploy` | After a successful deploy completes. | No — deploy has already shipped. |
| `post-deploy-failure` | After a deploy that raised. | No — deploy has already failed. |

Hook files in `.kamal/hooks/` that don't match a supported name are ignored. Additional hooks (`pre-build`, `post-build`, `pre-connect`) that exist in Ruby Kamal are **not wired up** in the current Wheels port — create an issue or a PR if you need one.

## The `KAMAL_*` environment contract

Every hook runs with these environment variables set:

| Variable | Set for | Value |
|----------|---------|-------|
| `KAMAL_VERSION` | all hooks | Version being deployed (git short SHA by default). |
| `KAMAL_HOSTS` | all hooks | Comma-separated list of hosts touched. |
| `KAMAL_RUNTIME` | post-deploy, post-deploy-failure | Seconds elapsed since deploy started. |
| `KAMAL_ERROR` | post-deploy-failure | Error message from the failed step. |

The variables are prefixed `KAMAL_` (not `WHEELS_`) to stay byte-compatible with hooks written for Ruby Kamal. You can port a `.kamal/hooks/` directory across without changing a line.

Your own environment is inherited — `PATH`, `HOME`, `USER`, any secrets or tokens your shell has, plus anything you export before running `wheels deploy`. Use this to pull credentials from the local environment:

```bash
export SLACK_WEBHOOK_URL=...
wheels deploy
# pre-deploy / post-deploy hooks see SLACK_WEBHOOK_URL
```

## Writing a hook

Hooks are invoked directly — no wrapper shell, so the first line must be a shebang and the file must be executable:

```bash
mkdir -p .kamal/hooks
cat > .kamal/hooks/post-deploy <<'SH'
#!/usr/bin/env bash
set -euo pipefail

curl -fsS -X POST "$SLACK_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d "{\"text\":\":ship: Deployed ${KAMAL_VERSION} in ${KAMAL_RUNTIME}s\"}"
SH
chmod +x .kamal/hooks/post-deploy
```

Any language with a shebang works — Ruby, Python, Node, a compiled Go binary. The file just has to be executable.

## Common recipes

### Slack notification on deploy

```bash
#!/usr/bin/env bash
# .kamal/hooks/post-deploy
curl -X POST "$SLACK_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d "{\"text\":\":ship: Deployed \`${KAMAL_VERSION}\` in ${KAMAL_RUNTIME}s\"}"
```

### Page on deploy failure

```bash
#!/usr/bin/env bash
# .kamal/hooks/post-deploy-failure
curl -X POST "$PAGERDUTY_EVENTS_URL" \
  -H 'Content-Type: application/json' \
  -d "$(cat <<JSON
{
  "routing_key": "$PAGERDUTY_ROUTING_KEY",
  "event_action": "trigger",
  "payload": {
    "summary": "Deploy failure: $KAMAL_ERROR",
    "severity": "error",
    "source": "$KAMAL_HOSTS"
  }
}
JSON
)"
```

### Smoke test before deploy

```bash
#!/usr/bin/env bash
# .kamal/hooks/pre-deploy
set -euo pipefail

# Check staging is healthy before promoting
curl -sf https://staging.example.com/up > /dev/null || {
  echo "Staging is not healthy — refusing to deploy production."
  exit 1
}
```

A non-zero exit from `pre-deploy` aborts the deploy before any SSH happens. Use it to gate on CI status, schema migrations, or a manual confirmation step.

### Purge a CDN cache

```bash
#!/usr/bin/env bash
# .kamal/hooks/post-deploy
curl -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE/purge_cache" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"purge_everything": true}'
```

### Record the deploy in a database

```bash
#!/usr/bin/env bash
# .kamal/hooks/post-deploy
psql "$DATABASE_URL" <<SQL
INSERT INTO deploys (version, hosts, runtime_seconds, deployed_at)
VALUES ('$KAMAL_VERSION', '$KAMAL_HOSTS', $KAMAL_RUNTIME, NOW());
SQL
```

## Hook output

Hook stdout and stderr are merged and prefixed `[hook:<name>]` in the deploy log:

```
[hook:pre-deploy] Checking staging health...
[hook:pre-deploy] ok
[hook:post-deploy] Deploy of abc123 completed in 22s
```

Keep hook output terse. A verbose hook makes the deploy log harder to read — prefer `set -e` plus a single success line over stepwise narration.

## Exit codes and deploy semantics

- `pre-deploy` exit 0 → deploy proceeds.
- `pre-deploy` exit non-zero → deploy aborts with that exit code. No hosts are touched.
- `post-deploy` exit 0 → deploy reports success.
- `post-deploy` exit non-zero → the deploy is marked failed **after** the containers already cut over. Containers stay in place; use this for soft smoke tests.
- `post-deploy-failure` exit code is ignored — the deploy is already failed.

If you need a post-deploy smoke test that **reverses** the deploy on failure, run it inside the hook and call `wheels deploy rollback --version=<previous-sha>` on failure.

## Dry-run behavior

Under `wheels deploy --dry-run`, hooks are printed (not executed):

```
[local] hook pre-deploy .kamal/hooks/pre-deploy
...
[local] hook post-deploy .kamal/hooks/post-deploy
```

This lets you verify the deploy plan without firing off Slack pings.

## Directory layout

```
.kamal/
  secrets                      # KEY=VALUE, never in git
  hooks/
    pre-deploy                 # executable, any language
    post-deploy                # executable
    post-deploy-failure        # executable
```

A project can safely commit `.kamal/hooks/` to git — the hooks themselves are not secrets. `.kamal/secrets` is the one file that must stay out.
