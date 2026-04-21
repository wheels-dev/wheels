---
description: >-
  Resolve secrets from .kamal/secrets at deploy time. Five first-party adapters
  (1Password, Bitwarden, AWS Secrets Manager, LastPass, Doppler) plus $(...)
  shell expansion.
---

# Secrets

Secrets enter a deploy through a single file: `.kamal/secrets`. It is a plain-text `KEY=VALUE` file that lives in your project root, is **never** committed to git, and is read locally by `wheels deploy` right before the image is shipped to your hosts.

## The file format

```bash
# .kamal/secrets
KAMAL_REGISTRY_PASSWORD=dckr_pat_abc123...
DATABASE_URL=postgres://app:hunter2@db.internal/app_production
WHEELS_RELOAD_PASSWORD=correct-horse-battery-staple
```

Any key listed under `env.secret` in `deploy.yml` or under an accessory's `env.secret` must be defined here. Referenced keys that are missing from `.kamal/secrets` cause the deploy to fail early, before any SSH happens.

## `$(...)` shell expansion

A value wrapped in `$(...)` is executed as a shell command at deploy time. This is the primary mechanism for delegating to a secret manager — you get the same deploy-time resolution regardless of which vault you use:

```bash
# 1Password
KAMAL_REGISTRY_PASSWORD=$(op read op://Deploy/DockerHub/password)

# AWS Secrets Manager
DATABASE_URL=$(aws secretsmanager get-secret-value --secret-id prod/database-url --query SecretString --output text)

# A file on disk
DATABASE_URL=$(cat /etc/myapp/database.url)

# A simple inline value (fine for first tests)
RAILS_MASTER_KEY=abc123def456
```

Each `$(...)` runs once per deploy. Resolution happens on the control machine, not the target hosts. If a subshell exits non-zero or produces empty output, the deploy aborts with that key marked.

## Per-destination secret overlays

If `.kamal/secrets.<destination>` exists, its values layer on top of `.kamal/secrets` when you pass `--destination=<name>`:

```bash
.kamal/secrets              # base — shared across destinations
.kamal/secrets.staging      # staging overrides
.kamal/secrets.production   # production overrides
```

Use overlays to keep production secrets out of staging's file and vice versa.

## The `secrets` subcommand

The deployer ships with three secrets verbs for fetching and inspecting values. All three run locally only.

```bash
wheels deploy secrets print                    # resolve .kamal/secrets, print KEY=VALUE
wheels deploy secrets fetch --adapter=op KEY1 KEY2
wheels deploy secrets extract KEY --from "<block>"
```

`secrets print` is the debugging workhorse — if a deploy fails with "password not resolved", run this to see exactly what your secrets file expanded to.

## Built-in adapters

Five secret managers are supported natively. The `secrets fetch` verb delegates to each via its vendor CLI — you still need `op`, `bw`, `aws`, `lpass`, or `doppler` on your PATH, but the deployer drives them uniformly.

### 1Password (`op` / `1password`)

```bash
wheels deploy secrets fetch \
  --adapter=op \
  --from=Deploy \
  KAMAL_REGISTRY_PASSWORD \
  DATABASE_URL
```

- `--from` is the vault name (default `Deploy`).
- `--account` is the 1Password account shorthand (for multi-account setups).
- Each key resolves against `op://<from>/<key>/password`.
- Requires `op` CLI v2 with a valid session (`op signin`).

Aliases: `op`, `1password`.

### Bitwarden (`bw` / `bitwarden`)

```bash
wheels deploy secrets fetch \
  --adapter=bw \
  KAMAL_REGISTRY_PASSWORD
```

- Each key resolves against `bw get password <key>`.
- Requires `bw` CLI with `BW_SESSION` set (run `bw unlock` first).
- Does **not** attempt interactive unlock — fail-fast if locked.

Aliases: `bw`, `bitwarden`.

### AWS Secrets Manager (`aws`)

```bash
wheels deploy secrets fetch \
  --adapter=aws \
  --from=us-west-2 \
  prod/database-url \
  prod/registry-password
```

- `--from` is the AWS region (default `us-east-1`).
- Each key is passed as `--secret-id`; AWS returns the SecretString.
- Requires `aws` CLI with credentials (`aws configure` or IAM role).
- For ECR registry auth, prefer a direct subshell in `.kamal/secrets` —
  `KAMAL_REGISTRY_PASSWORD=$(aws ecr get-login-password --region us-east-1)` —
  because the ECR password rotates every 12 hours.

Alias: `aws`.

### LastPass (`lpass` / `lastpass`)

```bash
wheels deploy secrets fetch \
  --adapter=lpass \
  KAMAL_REGISTRY_PASSWORD
```

- Each key resolves against `lpass show -p <key>`.
- Requires `lpass` CLI logged in (`lpass login user@example.com`).

Aliases: `lpass`, `lastpass`.

### Doppler (`doppler`)

```bash
wheels deploy secrets fetch \
  --adapter=doppler \
  --from=my-project \
  KAMAL_REGISTRY_PASSWORD
```

- `--from` is the Doppler project name (optional — falls back to the configured default).
- Each key resolves against `doppler secrets get <key> --plain`.
- Requires `doppler` CLI with `doppler login` and a configured service token or scope.

Alias: `doppler`.

## Wiring an adapter into `.kamal/secrets`

Shell substitution is the joining layer. The most common pattern is calling the same adapter on every line:

```bash
# .kamal/secrets — everything from 1Password
KAMAL_REGISTRY_PASSWORD=$(op read op://Deploy/DockerHub/password)
DATABASE_URL=$(op read op://Deploy/Database/url)
WHEELS_RELOAD_PASSWORD=$(op read op://Deploy/Reload/password)
```

You can also use `wheels deploy secrets fetch` once and capture its output to avoid repeated provider calls — but `$(...)` is simpler for everyday use.

## The `secret_helper` escape hatch

For providers we don't ship an adapter for, write a small shell script and call it from `.kamal/secrets`:

```bash
# .kamal/secrets
DATABASE_URL=$(./bin/fetch-from-vault database/prod-url)
```

```bash
#!/usr/bin/env bash
# bin/fetch-from-vault
curl -sf -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/$1" \
  | jq -r '.data.value'
```

Any exit-zero subshell that prints the value on stdout works.

## Security notes

- `.kamal/secrets` must be in `.gitignore`. The `wheels deploy init` scaffold adds it if your project has a `.gitignore`.
- Resolved secrets are passed to containers via `docker run --env KEY=VALUE`. They are visible inside the container's process environment but are never written to the host filesystem.
- The `kamal-proxy` container does not see your app env — secrets are isolated to app containers and accessories that explicitly reference them.
- Deploy audit logs on the host (`/tmp/kamal-audit.log`) record the **names** of secrets used, never the values.

## Debugging

```bash
wheels deploy secrets print                    # resolved file as KEY=VALUE
wheels deploy secrets print --destination=staging
```

Common failures:

- **Empty value** — the `$(...)` subshell returned empty. Run it by hand in your shell to see what it prints.
- **Subshell exited non-zero** — you will see the failure in the deploy output before any SSH happens. Usually a vault session expired or a permission is missing.
- **Registry login fails despite a resolved password** — the `registry.password[]` name in `deploy.yml` doesn't match the key in `.kamal/secrets`. Both must match character-for-character.
