# Deploy Reference

`wheels deploy` ships a Dockerized Wheels app to production Linux servers via SSH. Ported from Basecamp Kamal's developer CLI — same `config/deploy.yml` schema, same on-server conventions (container names, labels, network, lock path), invokes the same `kamal-proxy` Go binary for zero-downtime rollover. No Ruby runtime required.

## Commands

```
wheels deploy init                     # scaffold config/deploy.yml + .kamal/secrets
wheels deploy setup                    # one-time server bootstrap + first deploy
wheels deploy                          # rolling deploy
wheels deploy --dry-run                # print commands without executing
wheels deploy rollback v1              # roll back to a previous version
wheels deploy config                   # print resolved config as YAML
wheels deploy version                  # show Kamal version this port mirrors
```

## Subcommands

```
wheels deploy app <verb>         # boot/start/stop/details/containers/images/logs/live/maintenance/remove
wheels deploy proxy <verb>       # boot/reboot/start/stop/restart/details/logs/remove
wheels deploy accessory <verb>   # boot/reboot/start/stop/restart/details/logs/remove (sidecars: db/redis/search)
wheels deploy build <verb>       # deliver/push/pull/create/remove/details/dev
wheels deploy registry <verb>    # setup/login/logout/remove
wheels deploy bootstrap          # install Docker on every host (flat alias — preferred)
wheels deploy exec "<cmd>"       # run a command on every host (flat alias — preferred)
wheels deploy server <verb>      # exec/bootstrap (legacy nested form — see #2677)
wheels deploy prune <verb>       # all/images/containers [--keep=N]
wheels deploy lock <verb>        # acquire/release/status (manual — normal deploys auto-lock)
wheels deploy fetch-secrets ...  # resolve KEY=VALUE lines from an adapter (flat alias — preferred)
wheels deploy extract-secrets    # pull one key from a KEY=VALUE block (flat alias — preferred)
wheels deploy print-secrets      # print resolved .kamal/secrets (flat alias — preferred)
wheels deploy secrets <verb>     # fetch/extract/print (legacy nested form — see #2697)
wheels deploy audit              # tail /tmp/kamal-audit.log on each server
wheels deploy details            # aggregate app + proxy + accessory status
wheels deploy remove --confirm   # teardown all app/proxy/accessory containers
wheels deploy docs [section]     # in-terminal config reference
```

## On-server parity contract (byte-compatible with Ruby Kamal)

- Container names: `<service>-<role>-<version>`
- Labels: `service=`, `role=`, `destination=`, `version=`
- Docker network: `kamal`
- Lock file: `/tmp/kamal_deploy_lock_<service>`
- Proxy config: `/home/<user>/.config/kamal-proxy/`
- Hook env prefix: `KAMAL_*` (never `WHEELS_*` — user hooks migrate unchanged)

A server managed by Ruby Kamal can be taken over by `wheels deploy` without cleanup.

## Architecture

```
cli/lucli/services/deploy/
├── cli/*.cfc             DeployMainCli + Deploy<App|Proxy|Accessory|Build|Registry|Server|Prune|Lock|Secrets>Cli
├── commands/*.cfc        Base + Docker/App/Proxy/Builder/Registry/Auditor/Lock/Hook/Accessory/PruneCommands
├── config/*.cfc          Config + Role/Env/Builder/Proxy/Registry/Ssh/Accessory/Validator/ConfigLoader
├── lib/*.cfc             JarLoader/Mustache/Yaml/SshClient/SshPool/FakeSshPool/Output/SecretResolver
└── secrets/*.cfc         BaseAdapter + OnePassword/Bitwarden/AwsSecrets/LastPass/Doppler adapters

cli/lucli/lib/deploy/*.jar  jmustache, snakeyaml, sshj + BouncyCastle transitives (URLClassLoader-isolated)
cli/lucli/templates/deploy/ Mustache templates for `wheels deploy init` output
```

Commands-are-strings invariant: every `*Commands.cfc` method returns a shell-command string; only `*Cli.cfc` and the orchestrator execute them. That's why `--dry-run` is trivial and unit tests run without network.

## Critical gotchas

1. **Kamal-compatible schema, ONE divergence.** ERB in `deploy.yml` is NOT supported (rendering it would require embedding a Ruby runtime). Kamal's native `${VAR}` env-var interpolation is preserved unchanged — uppercase-snake tokens resolve via `envOverride → .kamal/secrets → System.getenv → ""` (see `ConfigLoader.$interpolate`). Mustache (`{{...}}`) is used only by `wheels deploy init` to scaffold a fresh `deploy.yml`/`secrets`; it is NOT applied to `deploy.yml` at runtime. Everything else in `config/deploy.yml` is byte-identical to Kamal 2.4.0.
2. **Hook env prefix is `KAMAL_`, not `WHEELS_`.** Deliberate — Ruby Kamal users' existing `.kamal/hooks/` scripts work unchanged.
3. **`app live` / `app maintenance` use a marker file** (`/tmp/kamal-maintenance-<svc>`) rather than kamal-proxy native maintenance mode. Phase 2 simplification; Phase 3 follow-up will align with Kamal's proxy-native semantics.
4. **`wheels deploy remove` is destructive and requires `--confirm`.** Bare `wheels deploy remove` throws without touching anything.
5. **Lucee reserved scope names in subagent-authored deploy code.** `client`, `session`, `application` — use `ssh`/`sc`, `sess`, `app` instead. Bit us multiple times during the port.
6. **No `--dry-run` flag in Ruby Kamal 2.4.0.** The `tools/deploy-config-diff.sh` harness compares config-layer output only. Byte-identical command-string parity is aspirational; see `tools/deploy-dry-run-diff.sh` for the plan.
7. **`wheels deploy server <verb>` collides with LuCLI's top-level `server` command.** LuCLI (the picocli runtime under the wheels brand) registers `server` for Lucee dev-server lifecycle, so picocli grabs the `server` token before it can reach the deploy dispatcher. The wheels module exposes flat aliases `wheels deploy bootstrap` and `wheels deploy exec` that sidestep the collision — these are the canonical CLI form. The nested `server <verb>` branch is retained in `Module.cfc::deploy()` for MCP/programmatic callers. See [#2677](https://github.com/wheels-dev/wheels/issues/2677).
8. **`wheels deploy secrets <verb>` collides with LuCLI's top-level `secrets` command.** Same shape as #2677 — LuCLI registers `secrets` for its own credential store (init/set/list/rm/get/provider). The wheels module exposes flat aliases `wheels deploy fetch-secrets`, `wheels deploy extract-secrets`, and `wheels deploy print-secrets` that sidestep the collision — these are the canonical CLI form. The nested `secrets <verb>` branch is retained for MCP/programmatic callers. See [#2697](https://github.com/wheels-dev/wheels/issues/2697).

## Testing

`cli/lucli/tests/specs/deploy/` extends `wheels.wheelstest.system.BaseSpec`. Run with:

    bash tools/test-cli-local.sh

Fixtures at `cli/lucli/tests/_fixtures/deploy/configs/` (`minimal.yml`, `full.yml`, `with-accessories.yml`, `invalid/*.yml`). `FakeSshPool.cfc` records every command for offline assertions; no sshd needed for unit tests. `SshClientSpec` + `SshPoolSpec` exercise real SSH via the fixture at `cli/lucli/tests/_fixtures/deploy/sshd/` (brought up by `tools/deploy-sshd-up.sh`).

## Reference docs

- User guides: `web/sites/guides/src/content/docs/v4-0-0/deployment/` (first-deploy, production-config, accessories, secrets, hooks, migrating-from-kamal, security-hardening, docker-deployment)
- In-source CLI docs: `cli/lucli/services/deploy/cli/docs/` (per-verb)
- Design spec: [docs/superpowers/specs/2026-04-20-wheels-deploy-kamal-port-design.md](../../docs/superpowers/specs/2026-04-20-wheels-deploy-kamal-port-design.md)
- Implementation plan: [docs/superpowers/plans/2026-04-20-wheels-deploy-kamal-port.md](../../docs/superpowers/plans/2026-04-20-wheels-deploy-kamal-port.md)
- Retrospective: [docs/superpowers/plans/2026-04-21-phase1-retrospective.md](../../docs/superpowers/plans/2026-04-21-phase1-retrospective.md)
