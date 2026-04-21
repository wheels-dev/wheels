---
description: >-
  End-to-end walkthrough: scaffold deploy.yml, configure a registry, bootstrap
  a Linux host, and run your first zero-downtime deploy.
---

# Your First Deploy

This tutorial walks through a minimal single-server deploy: one host, one image, one proxy, a real public URL. It assumes you can open an SSH session to a Linux machine and push to a Docker registry. No prior Kamal experience is required.

## What you will need

- A Wheels application (any version on 4.0 or newer).
- Docker installed locally.
- A container registry login (Docker Hub, GitHub Container Registry, ECR — anything Docker can `push` to).
- A Linux host you can reach by SSH as a user with `sudo` or Docker privileges.
- A DNS record pointing at that host's public IP (for SSL).

The example below uses `myapp` as the service name, Docker Hub for the registry, and `app.example.com` as the public hostname. Substitute your own values.

## Step 1 — Scaffold the configuration

Inside your Wheels project, run:

```bash
wheels deploy init
```

This creates two files:

- `config/deploy.yml` — the deployment manifest, committed to git.
- `.kamal/secrets` — a plain-text secrets file, **never** committed.

It also creates `.kamal/hooks/` (empty for now) for optional lifecycle scripts.

The generated `deploy.yml` is a starting point:

```yaml
service: myapp
image: myapp/web

servers:
  web:
    - 192.168.0.1

proxy:
  ssl: true
  host: app.example.com
  app_port: 8080
  healthcheck:
    path: /up
    interval: 1
    timeout: 30

registry:
  username: changeme
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  clear:
    DB_HOST: 192.168.0.2
  secret:
    - WHEELS_RELOAD_PASSWORD

ssh:
  user: deploy
```

## Step 2 — Edit `config/deploy.yml`

Open the file and update four things:

1. **`servers.web`** — replace `192.168.0.1` with your host IP or hostname.
2. **`proxy.host`** — replace `app.example.com` with your DNS name.
3. **`proxy.app_port`** — match the port your Wheels app listens on inside the container (usually `8080` with the default Docker image).
4. **`registry.username`** — your Docker Hub / GHCR / ECR username.

The `image:` key is the repository name that will be prefixed by the registry server. For Docker Hub with username `alice`, `image: myapp/web` resolves to `docker.io/alice/myapp/web`. For GHCR, add `registry.server: ghcr.io`.

Leave the `healthcheck.path` at `/up` — your Wheels app should respond `200 OK` to that route. Add a trivial controller action if you don't have one:

```cfml
// app/controllers/Up.cfc
component extends="Controller" {
    function index() {
        renderText("ok");
    }
}
```

Routed with:

```cfml
// config/routes.cfm
.get(name="healthcheck", pattern="/up", to="up##index")
```

## Step 3 — Populate `.kamal/secrets`

Open `.kamal/secrets` and fill in the registry password. You can paste the value directly (fine for a first test) or use `$(...)` to shell out to a secret manager:

```bash
# Plain value (development / first test)
KAMAL_REGISTRY_PASSWORD=dckr_pat_abc123...

# Or delegated to 1Password
KAMAL_REGISTRY_PASSWORD=$(op read op://Deploy/DockerHub/password)

# Or delegated to AWS Secrets Manager
KAMAL_REGISTRY_PASSWORD=$(aws secretsmanager get-secret-value --secret-id deploy/dockerhub --query SecretString --output text)
```

Any key listed under `env.secret` in `deploy.yml` must also appear here. The template ships with `WHEELS_RELOAD_PASSWORD` as an example — fill it in or remove the reference from `deploy.yml`.

## Step 4 — Bootstrap the host

Your target host needs Docker. If it is a fresh Linux VM, run:

```bash
wheels deploy server bootstrap
```

This SSHes to every host in `servers:` and runs:

```bash
which docker >/dev/null 2>&1 || curl -fsSL https://get.docker.com | sh
```

The command is idempotent — hosts that already have Docker are left alone.

## Step 5 — Dry run

Before deploying for real, print the commands that would fire:

```bash
wheels deploy --dry-run
```

You will see an ordered list of SSH-prefixed `docker` commands — `docker pull`, a `kamal-proxy` boot check, `docker run` for the app container, and the proxy cut-over. Read it top to bottom. If a host name is wrong or an image tag looks off, fix the config and dry-run again.

## Step 6 — Deploy

Run the real thing:

```bash
wheels deploy
```

The deploy proceeds in these stages, each printed to your terminal:

1. **pre-deploy hook** (skipped if you have none).
2. **lock acquire** — `/tmp/kamal-lock-myapp` created on one host.
3. **image pull** — fans out over every host in parallel.
4. **proxy boot** — first-time install of `kamal-proxy` (no-op on redeploys).
5. **app run + proxy deploy** — per host, per role: start the new container and cut over traffic.
6. **lock release**.
7. **post-deploy hook** (skipped if you have none).

The first deploy is slower (cold image pull, proxy install, certificate issuance). Subsequent deploys of the same size typically complete in 15-30 seconds.

## Step 7 — Verify

After the deploy returns, open `https://app.example.com/up` in a browser. You should see `ok`. The certificate is issued automatically by Let's Encrypt via `kamal-proxy` because you set `proxy.ssl: true`.

If the health check fails, `kamal-proxy` refuses to cut over and the previous container remains authoritative — you will see a non-zero exit and the post-deploy-failure hook will fire (if you have one). Fix the image, redeploy, and the old container stays running until the new one is healthy.

Inspect running containers and recent audit activity:

```bash
wheels deploy details            # docker ps for app, proxy, and accessories
wheels deploy audit --tail=50    # recent deploy actions per host
wheels deploy app logs --tail=100 --role=web
```

## Step 8 — Ship a change

Commit a code change, then:

```bash
wheels deploy
```

The tag defaults to the current git short SHA. The new image builds, pushes, pulls on every host, and cuts over container-by-container. Your previous version stays cached on the hosts for rollback:

```bash
wheels deploy rollback --version=<previous-sha>
```

## Where to go from here

- Add a database, Redis, or search engine as an [accessory](./accessories.md).
- Wire up a secret manager with the [secrets adapters](./secrets.md).
- Add Slack notifications or smoke tests with [hooks](./hooks.md).
- Split staging and production with the `--destination=<name>` flag — see the [config reference](./config-reference.md#multiple-destinations).

## Troubleshooting

**`docker login` fails on the host** — The password isn't resolving. Run `wheels deploy secrets print` to see the resolved `.kamal/secrets`. Any blank value indicates a failed `$(...)` subshell.

**`Connection refused` on port 80/443** — `kamal-proxy` binds these ports directly. Stop any other web server (nginx, Apache, Traefik) on the host, then `wheels deploy proxy boot`.

**Healthcheck fails** — Increase `proxy.healthcheck.timeout` for a slow-starting app, or verify `/up` is reachable inside the container with `wheels deploy app exec "curl localhost:8080/up"`.

**SSH key not found** — `ssh.user` in `deploy.yml` must match a user whose public key is in `~/.ssh/authorized_keys` on the host. The SSH agent is consulted for the private key.

For deeper trouble, run with `--dry-run` and diff the commands against a known-good deploy, or use `wheels deploy server exec "docker logs <container>"` to inspect a specific container.
