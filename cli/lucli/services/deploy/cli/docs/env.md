# env

Environment variables ship in two buckets: `clear` (baked into deploy.yml)
and `secret` (resolved from `.kamal/secrets` at deploy time).

## Top-level env

    env:
      clear:
        RAILS_ENV: production
        RAILS_LOG_TO_STDOUT: 1
      secret:
        - DATABASE_URL
        - RAILS_MASTER_KEY

## Per-role env overrides

    servers:
      web:
        hosts:
          - 1.2.3.4
        env:
          clear:
            RAILS_MAX_THREADS: 5

## `.kamal/secrets` — plain-text file, out of git

`.kamal/secrets` is a simple KEY=value file. Deploy reads it locally, then
ships values into containers via `--env`. Never check it in.

    # .kamal/secrets
    DATABASE_URL=postgres://user:pass@db/app
    RAILS_MASTER_KEY=abc123...

## `$(...)` command substitution

Inside `.kamal/secrets` you can shell out to pull secrets from anywhere:

    DATABASE_URL=$(op read op://Production/app/database-url)
    RAILS_MASTER_KEY=$(cat config/master.key)

Kamal evaluates `$(...)` once per deploy on the control machine. Your
secret store (1Password, Doppler, Vault, `op`, `aws ssm`) is the system
of record — `.kamal/secrets` is just a glue layer.

## Precedence

Role-level env merges over top-level env. For a single key, the winner is
whichever layer names it last: role `clear` > role `secret` > top-level
`clear` > top-level `secret`. Re-deploy to pick up changes — running
containers keep their original env.
