---
description: >-
  Migration guide for users moving from Ruby Kamal to wheels deploy. One
  deliberate schema divergence, byte-compatible on-server state.
---

# Migrating from Ruby Kamal

`wheels deploy` is a Lucee/CFML port of [Basecamp's Kamal 2.4.0](https://github.com/basecamp/kamal) built into the Wheels CLI. It targets byte-level parity with the upstream on everything that matters — config shapes, on-server state, hook contract — with **one deliberate divergence**. This guide walks you through the migration.

## TL;DR

For most projects, migration is `git mv config/deploy.yml` and you're done. The exceptions:

1. **ERB templates in `deploy.yml` are not supported.** Replace with a restricted Mustache context (see below). This is the one thing that will break on migration.
2. **The `upgrade` verb (Kamal 1.x → 2.x upgrader) is not supported.** If you are on Kamal 1.x, upgrade via Ruby Kamal first, then switch to `wheels deploy`.
3. **A few verbs are not yet at full parity** — see the "parity gaps" section.

Everything else — `.kamal/secrets`, `.kamal/hooks/`, container names, labels, the lock file, the proxy network — is byte-compatible. A host deployed by Ruby Kamal can be taken over by `wheels deploy` without any server-side cleanup.

## `config/deploy.yml` — verbatim (almost)

The schema is identical to Kamal 2.4.0. Every top-level key works the same, with the same value shapes, same defaults, and same semantics:

- `service`, `image`
- `servers` (flat array, named roles, or full role-with-options form)
- `registry` (server, username, password as an array of secret names)
- `builder` (context, dockerfile, arch, args, remote)
- `env` (clear + secret, top-level and per-role)
- `ssh` (user, port, proxy, keys, forward_agent)
- `proxy` (host, app_port, healthcheck, ssl, forward_headers, buffering)
- `boot` (limit, wait)
- `healthcheck` (container-level)
- `accessories` (image, host/hosts, port, env, volumes, files, labels)
- `volumes`, `logging`, `asset_path`, `labels`

You can `git mv config/deploy.yml` from a Ruby Kamal project into a Wheels project and keep going — with the one exception below.

## The one schema divergence: no ERB

Ruby Kamal evaluates the entire `deploy.yml` as ERB before parsing:

```yaml
# Ruby Kamal — ERB in deploy.yml
servers:
  web:
    <% if ENV["STAGING"] %>
    - staging-1
    <% else %>
    - prod-1
    - prod-2
    <% end %>
```

`wheels deploy` **does not support ERB**. The parser is pure YAML with a restricted Mustache expression pass. Allowed expressions:

- `{{env.VAR_NAME}}` — read a local environment variable at deploy time.
- `{{destination}}` — the value of the `--destination` flag.
- `{{hostname}}` — the target host (inside per-host contexts only).

Arbitrary logic (`if`, loops, string manipulation, Ruby calls) is intentionally rejected. This is a deliberate design choice — a deploy config should be reviewable without worrying about what code runs when it's parsed.

### Migrating ERB to Mustache + destinations

Split conditional configs across destination overlays. Instead of:

```yaml
# Ruby Kamal
servers:
  web:
    <% if ENV["STAGING"] %>
    - staging-1
    <% else %>
    - prod-1
    - prod-2
    <% end %>
```

Use destination overlays:

```yaml
# config/deploy.yml — base
service: myapp
image: alice/myapp
# ... everything common

# config/deploy.staging.yml
servers:
  web:
    - staging-1

# config/deploy.production.yml
servers:
  web:
    - prod-1
    - prod-2
```

Then invoke with `wheels deploy --destination=staging` or `wheels deploy --destination=production`. The overlay deep-merges on top of the base.

For environment-variable interpolation:

```yaml
# Ruby Kamal
env:
  clear:
    RELEASE: <%= ENV["GIT_SHA"] %>

# wheels deploy
env:
  clear:
    RELEASE: "{{env.GIT_SHA}}"
```

If you have more complex logic (a loop, an inline transform), compute it outside the config — generate the final YAML in CI, or move the logic into a hook.

## `.kamal/secrets` — byte-compatible

The secrets file format is unchanged. Same `KEY=VALUE` shape, same `$(...)` shell expansion, same per-destination overlay (`.kamal/secrets.staging`). You do not need to touch this file.

```bash
# Works the same in Ruby Kamal and wheels deploy
KAMAL_REGISTRY_PASSWORD=$(op read op://Deploy/DockerHub/password)
DATABASE_URL=$(aws secretsmanager get-secret-value --secret-id prod/db --query SecretString --output text)
```

The five built-in adapters (1Password, Bitwarden, AWS Secrets Manager, LastPass, Doppler) match Kamal's adapter set. Adapter aliases (`op`/`1password`, `bw`/`bitwarden`, `lpass`/`lastpass`) work identically.

## `.kamal/hooks/` — byte-compatible

Your hook scripts keep working unchanged. The contract is identical:

- Directory is `.kamal/hooks/`.
- Supported hooks are `pre-deploy`, `post-deploy`, `post-deploy-failure`.
- Env vars are prefixed `KAMAL_*` (not `WHEELS_*`) — deliberately preserved.
- `KAMAL_VERSION`, `KAMAL_HOSTS`, `KAMAL_RUNTIME`, `KAMAL_ERROR` all have the same semantics.
- Exit codes have the same meaning — non-zero on `pre-deploy` aborts.

Hook parity gap: Ruby Kamal supports `pre-build`, `post-build`, `pre-connect` hooks. The current Wheels port wires up `pre-deploy`, `post-deploy`, and `post-deploy-failure` — the three that fire around a real deploy. The build/connect hooks land in a follow-up.

## On-server state — byte-compatible

Wheels deploy produces identical on-server state to Ruby Kamal:

- **Container names** — `<service>-<role>-<version>` for app, `kamal-proxy` for the proxy, `<service>-<accessory>` for accessories. Identical.
- **Labels** — `service=`, `role=`, `destination=`, `version=`. Identical.
- **Docker network name** — `kamal`. Identical.
- **Lock file** — `/tmp/kamal-lock-<service>`. Identical.
- **Audit log** — `/tmp/kamal-audit.log`. Identical format.

This means: **you can take over a host that was previously deployed by Ruby Kamal without cleaning it up first.** The first `wheels deploy` picks up the existing proxy, co-exists with existing containers, and cuts over seamlessly. The reverse is also true — a host `wheels deploy` managed can be taken back by Ruby Kamal.

## Parity gaps (not yet at full upstream behavior)

These verbs work but differ from Ruby Kamal in ways you should know about:

### `app live` / `app maintenance`

Ruby Kamal 2.8.2 implements live/maintenance by talking to `kamal-proxy` directly — the proxy routes to a maintenance response page without involving the app container. The current Wheels port uses a **marker file on the server** instead; the proxy-native behavior lands in a Phase 3 follow-up. For a scheduled maintenance window, the marker file approach works; for instant cut-over during an outage, the semantics are slightly different.

### `upgrade`

The `kamal upgrade` verb — used to migrate a Kamal 1.x host to Kamal 2.x semantics — is **not supported** by `wheels deploy`. If you are on Kamal 1.x:

1. Upgrade via Ruby Kamal first (`gem install kamal && kamal upgrade`).
2. Verify the deploy works on 2.x.
3. Switch to `wheels deploy`.

### Dry-run command byte-parity

The command strings printed by `wheels deploy --dry-run` are **aspirationally** byte-for-byte identical to Ruby Kamal's dry-run. A diff tool (`tools/deploy-dry-run-diff.sh`) exists for verification, but small differences may surface around quoting and flag order — the semantics are identical, the text output may drift by a few characters. Treat dry-run output as a deploy plan, not a regression harness.

## Not yet ported (optional features)

A handful of Kamal 2.4.0 features that we haven't ported yet — none are required for a basic deploy:

- **BuildKit bake** for multi-stage or matrix builds. Workaround — call `docker buildx bake` from a `pre-deploy` hook, then deploy.
- **Remote builder caching options** beyond the basic `builder.remote:` form.
- **Proxy-native maintenance mode** (see above — marker file alternative works today).
- **Asset precompile integration** (`asset_path`) is config-accepted but not fully wired through to the container boot.

Open an issue if you hit a gap that matters for your workflow.

## Migration checklist

Run through this list when switching a project from Ruby Kamal to `wheels deploy`:

1. **Install** the Wheels 4.0+ CLI. Verify `wheels deploy version` works.
2. **Inspect** `config/deploy.yml` for ERB tags. If present, replace with Mustache expressions or split into destination overlays. This is the only non-trivial migration step.
3. **Dry run** — `wheels deploy --dry-run` from the project root. The output should list the same SSH commands your Ruby Kamal deploy would issue.
4. **Compare config** — `wheels deploy config` prints the resolved configuration. Diff it against Ruby Kamal's `kamal config` output.
5. **Deploy to staging** — `wheels deploy --destination=staging`. Verify the app cuts over.
6. **Deploy to production** — once staging is clean.
7. **Remove Ruby Kamal** from `Gemfile` / CI if you want to commit to the migration. You can keep both installed side-by-side during the transition.

The only file that behaves meaningfully differently is `config/deploy.yml` — and only if you used ERB in it. Everything else — hooks, secrets, on-server state — is byte-compatible.

## Reporting issues

File parity bugs against the [Wheels repo](https://github.com/wheels-dev/wheels/issues) with:

- The `deploy.yml` snippet that reproduces.
- `wheels deploy --dry-run` output.
- What Ruby Kamal did instead.

We aim for behavioral parity on everything except the documented divergences above. If `wheels deploy` produces a different on-server outcome than Ruby Kamal for the same config, that's a bug.
