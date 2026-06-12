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
ships `env.secret` values to each host as an env file
(`.kamal/apps/<service>/env/...`, locked to 600 permissions both before
and after the content upload) that
`docker run` references via `--env-file` — secret values never appear on a
command line. `env.clear` values ride as escaped `-e` pairs. Never check
`.kamal/secrets` in.

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
