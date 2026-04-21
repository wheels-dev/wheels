# registry

The `registry:` block tells `wheels deploy` where to push and pull
container images. Every host in your fleet must be able to reach this
registry.

## Docker Hub (default)

    registry:
      username: my-dockerhub-user
      password:
        - KAMAL_REGISTRY_PASSWORD

The `password:` list names environment variables resolved from
`.kamal/secrets` at deploy time — never the literal password.

## GitHub Container Registry

    registry:
      server: ghcr.io
      username: my-gh-user
      password:
        - KAMAL_REGISTRY_PASSWORD

## AWS ECR, GCR, private registries

    registry:
      server: 123456789.dkr.ecr.us-east-1.amazonaws.com
      username: AWS
      password:
        - ECR_REGISTRY_PASSWORD

For ECR the password rotates every 12 hours — wire up `secrets helper`
to shell out to `aws ecr get-login-password` so it is always fresh.

## How login/logout works

At deploy time `wheels deploy` emits a `docker login` on every host
before pulling, and a `docker logout` at the end of `wheels deploy
remove`. Credentials are never persisted on the hosts beyond the
deploy window.

## Commands

    wheels deploy registry login    # one-off manual login
    wheels deploy registry logout   # clear cached credentials
