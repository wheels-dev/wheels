---
title: 'Porting Kamal to CFML: How wheels deploy Ships 4.0 Apps Without Ruby'
slug: wheels-deploy-kamal-port
publishedAt: '2026-04-27T07:00:00.000Z'
updatedAt: null
author: Peter Amiri
tags:
  - deployment
  - wheels-4
  - kamal
categories: []
excerpt: >-
  Wheels 4.0 ships with a new command: wheels deploy. It's a port of Basecamp's
  Kamal into the Wheels CLI — zero-downtime Dockerized deploys to Linux servers
  over plain SSH, no Ruby runtime required. This post covers what got ported,
  the one deliberate divergence from Kamal, and the byte-compatibility contract
  that lets you take over a Kamal-managed server without cleanup.
coverImage: null
---

# Porting Kamal to CFML: How `wheels deploy` Ships 4.0 Apps Without Ruby

_Peter Amiri, Wheels Core Team_

---

You just finished a Wheels app. You have a Docker image. You have a Linux server. You want to ship.

Before Wheels 4.0 the answer was whatever you had cobbled together — a shell script that SSHs in and runs `docker pull`, an Ansible playbook, maybe Capistrano if you had one lying around. The framework did not have an opinion about this step.

In 4.0 you type `wheels deploy`. One command, laptop to production, zero downtime, rolling cutover across however many Linux servers you have. It is built in, written entirely in CFML and Java, and it needs no Ruby runtime.

This post explains why we chose to port [Basecamp's Kamal](https://kamal-deploy.org/) rather than write something new, what we kept byte-compatible with the Ruby original, where we deliberately diverged, and what the developer workflow looks like now.

## The problem with writing a new deploy tool

The temptation, when building a deploy story for a framework, is to invent. You know your framework's specifics. You can design the on-server layout around them. You can make the common path easy.

The problem is that the "common path" for shipping a Dockerized web app to Linux servers is a well-explored space. Basecamp spent three years building Kamal in the open. It handles zero-downtime rolling deploys, container-based orchestration, a battle-tested on-server convention for where things live, sidecar services (databases, caches), secret management adapters for 1Password, Bitwarden, AWS Secrets Manager, LastPass, and Doppler, and zero-downtime traffic cutover through a dedicated Go proxy binary.

Every one of those pieces is a tarpit. Traffic cutover alone — draining active connections from a version being retired, atomically switching, draining back on rollback — is a couple of months of work by itself, and it is the thing that makes or breaks a "zero-downtime" claim. Kamal's proxy ([kamal-proxy](https://github.com/basecamp/kamal-proxy)) solves this. It is already a standalone Go binary with no Ruby dependency. Writing our own and calling it "equivalent" would have been a year-long detour from the actual Wheels work.

So we did not write a new deploy tool. We ported Kamal's developer-side orchestrator — the CLI that opens SSH connections, uploads config, and runs `docker` commands remotely — into the Wheels CLI. The Go proxy is unchanged; we invoke the same `basecamp/kamal-proxy:v0.8.6` image Kamal does.

## The byte-compatibility contract

The design bet for the port was this: a server that has been managed by Ruby Kamal can be taken over by `wheels deploy` without any cleanup, and vice versa. Container names, labels, Docker network, proxy config directory, lock file paths, the `.kamal/` directory layout — all match the Kamal 2.4.0 contract exactly.

| Concern | Value |
|---|---|
| Container name | `<service>-<role>-<version>` (e.g. `myapp-web-abc1234`) |
| Container labels | `service=`, `role=`, `destination=`, `version=` |
| Docker network | `kamal` |
| Proxy image | `basecamp/kamal-proxy:v0.8.6` |
| Proxy config dir | `/home/<user>/.config/kamal-proxy/` |
| Lock file path | `/tmp/kamal_deploy_lock_<service>` |
| Audit log | `/tmp/kamal-audit.log` |
| Hook directory | `.kamal/hooks/` |
| Hook environment prefix | `KAMAL_*` |
| Secret file | `.kamal/secrets`, `.kamal/secrets.<destination>` |

The subtle choice in that table is the hook environment prefix. Every hook script that anyone has ever written for Ruby Kamal reads environment variables named `KAMAL_SERVICE`, `KAMAL_VERSION`, `KAMAL_DESTINATION`, and so on. Renaming them to `WHEELS_*` would have been slightly more aesthetically consistent with the Wheels CLI — and it would have broken every user's existing hook scripts for zero benefit. So we did not rename them.

The same reasoning applies to the `.kamal/` directory name. It could have been `.wheels/deploy/`. It is not, because anyone evaluating the switch from Kamal to `wheels deploy` can sit on both tools during the transition — `kamal deploy` and `wheels deploy` read the same secrets, the same hooks, the same config file. There is no migration step. There is no point of no return.

This matters for adoption. If the first thing a user has to do is rename every file in their existing setup, the friction cost of trying `wheels deploy` is close to the cost of rewriting everything. If they can point `wheels deploy` at their existing `config/deploy.yml` and watch it work, the cost of trying drops to zero.

## The one divergence

`config/deploy.yml` does not support ERB. This is the only schema-level incompatibility with Ruby Kamal, and it is deliberate.

Ruby Kamal lets you embed ERB inside `deploy.yml`:

```yaml
service: <%= ENV["APP_NAME"] %>
image: <%= ENV["REGISTRY"] %>/<%= ENV["APP_NAME"] %>
```

ERB is Ruby template code. The template engine runs arbitrary Ruby at render time. To support it, `wheels deploy` would need to embed a Ruby runtime — which is the thing the whole port exists to avoid. So we replaced ERB with a restricted Mustache context.

```yaml
service: {{env.APP_NAME}}
image: {{env.REGISTRY}}/{{env.APP_NAME}}
```

The context is deliberately small: `{{env.FOO}}` for environment variables, `{{destination}}` for the destination name, `{{hostname}}` for the target hostname. No function calls, no conditionals, no interpolated Ruby. For most `deploy.yml` files in the wild the conversion is mechanical — `<%= ENV["X"] %>` becomes `{{env.X}}`. For the handful of cases that use ERB for control flow or computed values, the migration is more involved, and the [migrating-from-kamal guide](https://guides.wheels.dev/v4-0-0-snapshot/deployment/migrating-from-kamal/) walks through each pattern.

We considered preserving ERB by shelling out to a system Ruby. The problem is that it turns a single-binary install into a "works if you also have Ruby" story, and every user who does not have Ruby installed gets a cryptic error the first time they deploy. The divergence felt worth naming up front.

## What the workflow looks like

First deploy:

```bash
wheels deploy init      # scaffold config/deploy.yml + .kamal/secrets
# edit config/deploy.yml — servers, image, registry, env
wheels deploy setup     # one-time server bootstrap + first deploy
```

Every deploy after that:

```bash
wheels deploy
```

Need a rollback?

```bash
wheels deploy app details        # see which versions exist per host
wheels deploy rollback v1        # atomic cutover to the named version
```

The full verb surface mirrors Kamal's top level: `init`, `setup`, `rollback`, `config`, `version`, `details`, `audit`, `remove`, `docs`, plus sub-command groups for `app`, `proxy`, `accessory` (sidecars like Postgres or Redis), `build`, `registry`, `server`, `prune`, `lock`, and `secrets`.

Every verb supports `--dry-run`, which prints the exact shell commands that would be run remotely without opening an SSH connection. That means the commands-layer test suite runs offline — no Docker, no sshd, no network. `--dry-run` is also the fastest way to understand what `wheels deploy` is about to do before you let it do it.

Secret management has adapters for 1Password, Bitwarden, AWS Secrets Manager, LastPass, and Doppler. The API is the same as Kamal's (`wheels deploy secrets fetch`, `wheels deploy secrets extract`, `wheels deploy secrets print`), and the on-disk format of `.kamal/secrets` is unchanged. If you are currently fetching Kamal secrets from 1Password, nothing in your workflow changes.

## What `wheels deploy` is not

Naming the limits matters as much as naming the capabilities.

`wheels deploy` is not a Kubernetes integration. It drives `docker` remotely over SSH. For k8s, use whatever pipeline you already have. The deployment docs cover Docker image hygiene for that world, but the orchestrator side is not in scope.

It is not a systemd-native deployer. If your production target is a VM with a servlet container under systemd — CommandBox, Tomcat, Jetty — stay on that path. The VM deployment guide covers it. `wheels deploy` is Docker-only on the server side. It will not grow a systemd mode.

It is not a Compose-only tool. For single-host Docker Compose setups, the Docker deployment guide is the shorter path. `wheels deploy` adds value once you have two or more servers to coordinate.

It does not support Windows servers. Kamal does not either, and we inherited that limitation. Linux targets only. Windows developer workstations are best-effort.

It is not Ruby-Kamal-plugin-compatible. Ruby plugins use `Kamal::Commands` extension points — those are Ruby-specific. Shell-script hooks in `.kamal/hooks/` are language-agnostic and work unchanged.

## The engineering underneath

A few details for readers curious about the port itself.

The CFML code lives in `cli/lucli/services/deploy/`. Three required JARs — `snakeyaml` for YAML, `jmustache` for template rendering, `sshj` with BouncyCastle transitives for SSH — load through a URL-isolated classloader so they do not collide with the rest of the JVM. Every command is a plain string returned by a pure function; only the CLI layer and the orchestrator actually execute them. That is what makes `--dry-run` trivial and what lets the test suite run without network.

Tests live in `cli/lucli/tests/specs/deploy/` and extend the same `wheels.wheelstest` base class the rest of the framework uses. A `FakeSshPool` records every command for offline assertions. A real-SSH fixture (`tools/deploy-sshd-up.sh`) brings up a disposable sshd for the couple of specs that need to exercise real transport.

The full architecture reference — covering the code layout, the commands-are-strings invariant, the URLClassLoader JAR isolation, and the non-goals — lives in the guides under [Architecture of `wheels deploy`](https://guides.wheels.dev/v4-0-0-snapshot/deployment/architecture/). It is the place to start if you want to extend, debug, or evaluate the implementation.

## Where to go next

- [Your first deploy](https://guides.wheels.dev/v4-0-0-snapshot/deployment/first-deploy/) is the hands-on walkthrough — scaffold through first rollout.
- [Migrating from Kamal](https://guides.wheels.dev/v4-0-0-snapshot/deployment/migrating-from-kamal/) is the guide for teams coming from Ruby Kamal, including the full compatibility contract and the ERB-to-Mustache conversion.
- [Architecture of `wheels deploy`](https://guides.wheels.dev/v4-0-0-snapshot/deployment/architecture/) covers the port strategy, the commands-are-strings invariant, and the classloader isolation in depth.
- [Deployment landing page](https://guides.wheels.dev/v4-0-0-snapshot/deployment/) covers when to reach for `wheels deploy` versus the VM or Compose paths.
- [Config reference](https://guides.wheels.dev/v4-0-0-snapshot/deployment/config-reference/), [secrets](https://guides.wheels.dev/v4-0-0-snapshot/deployment/secrets/), [hooks](https://guides.wheels.dev/v4-0-0-snapshot/deployment/hooks/), [accessories](https://guides.wheels.dev/v4-0-0-snapshot/deployment/accessories/).

If you are currently running a Wheels app in production with ad-hoc deploy tooling — or running Ruby Kamal alongside Wheels — we would love to hear what the switch to `wheels deploy` is like. The command is new, the design space for polish in 4.0.x is open, and the feedback loop from early adopters is what will shape it.
