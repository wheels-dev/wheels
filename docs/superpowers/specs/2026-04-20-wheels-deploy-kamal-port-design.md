# `wheels deploy` — Kamal Port Design

**Status:** Approved
**Date:** 2026-04-20
**Target release:** Wheels v4.1 (post-4.0 production deploy docs)
**Unblocks:** Production deployment docs page deliberately deferred from the 4.0 ship.

## 1. Problem

Wheels 4.0 ships with a LuCLI-based `wheels` binary (CFML + Java, no Ruby
dependency). We want users to run `wheels deploy` to ship their app to
production Linux servers — without `gem install kamal`, without a Ruby
runtime, without a second CLI to learn.

Basecamp's [Kamal](https://github.com/basecamp/kamal) already solved the
hard parts of this problem: zero-downtime rolling deploys, container-based
orchestration, a battle-tested on-server convention. Its proxy component
([kamal-proxy](https://github.com/basecamp/kamal-proxy)) is a standalone Go
binary with no Ruby runtime. What is Ruby-specific is only the
developer-side orchestrator — the CLI that opens SSH connections, uploads
config, and runs `docker` commands.

This design ports that orchestrator into the Wheels CLI while leaving
kamal-proxy untouched.

## 2. Goals

1. **`wheels deploy` is the single command users run** to ship a Dockerized
   Wheels app to one or more Linux servers. No external Ruby, no gems.
2. **Near-parity with Kamal's top-level verb surface** (~25 verbs across
   `main`, `app`, `proxy`, `accessory`, `build`, `registry`, `secrets`,
   `server`, `prune`, `lock`). Hidden/internal verbs not in scope.
3. **Byte-compatible with Ruby Kamal on-server state** — identical
   container naming (`<service>-<role>-<version>`), labels, network name
   (`kamal`), proxy config directory, lock file path. A server managed by
   Ruby Kamal can be taken over by `wheels deploy` (and vice versa) during
   evaluation. See §7 for the one deliberate schema divergence.
4. **Config schema verbatim** — `config/deploy.yml` loads Kamal's existing
   format unchanged. `.kamal/secrets` and `.kamal/hooks/*` supported as-is.
5. **Testable offline** — a `--dry-run` flag emits every command that would
   be run remotely without opening an SSH connection. The whole
   commands-layer test suite runs without network or Docker.
6. **Cross-engine** — Lucee 6/7 and Adobe CF 2023/2025. No Windows server
   support (Kamal doesn't either); Windows developer workstations
   best-effort.

## 3. Non-goals

1. **Not replacing kamal-proxy.** We invoke the Go binary remotely; we do
   not rewrite its traffic-draining or SSL termination.
2. **Not supporting Kubernetes.** Kamal itself doesn't.
3. **Not supporting Windows *servers*.** Linux servers only.
4. **Not building a deploy UI / TUI.** CLI + logs. Host-prefixed streaming
   stdout/stderr; no progress bars.
5. **Not writing a new YAML parser.** Embed `snakeyaml`.
6. **Not inventing a new config schema.** Kamal's `deploy.yml` is the
   contract (with one Mustache-for-ERB divergence — §5.5).
7. **Not building a secret vault.** `secrets fetch` shells out to external
   adapters (1Password, Bitwarden, AWS Secrets Manager) exactly as Kamal
   does.
8. **Not supporting non-Docker deploys.** No systemd-native, no Nix, no
   "rsync a jar." Docker + kamal-proxy is the substrate.
9. **Not a Wheels reload mechanism.** `wheels deploy` ships the container;
   the in-process `?reload=true` endpoint and related coordination are a
   separate concern.
10. **Not Ruby-Kamal-plugin-compatible.** The Ruby plugin API
    (`Kamal::Commands` extension points) is Ruby-specific. Shell-script
    hooks in `.kamal/hooks/` ARE supported since they're language-agnostic.
11. **Not shipping to LuCLI core in v1.** All code lives in the Wheels
    module. Promotion to LuCLI core is a post-ship decision gated on
    non-Wheels user demand (§9, Phase 4).

## 4. Architecture

### 4.1 Placement

All code lives in the Wheels module in the `wheels` repo:

- `cli/lucli/services/deploy/**` — CFML sources.
- `cli/lucli/templates/deploy/**` — Mustache templates for rendered
  artifacts (systemd units, compose fragments, env files, proxy config).
- `cli/lucli/lib/deploy/` — bundled JARs (`sshj` + transitive, `jmustache`,
  `snakeyaml`). Loaded via URLClassLoader isolation using the same pattern
  established for Playwright in v4.0's browser testing work.

### 4.2 Layering

```
┌───────────────────────────────────────────────────────────┐
│ Module.cfc :: public string function deploy()             │  CLI entry (thin)
│   args parse → dispatch to DeployCli                      │
├───────────────────────────────────────────────────────────┤
│ services/deploy/cli/*.cfc                                 │  Verb surface
│   DeployMainCli, DeployAppCli, DeployProxyCli,            │  (one per
│   DeployAccessoryCli, DeployBuildCli, DeployRegistryCli,  │   Kamal
│   DeploySecretsCli, DeployServerCli, DeployPruneCli,      │   lib/kamal/cli/*.rb)
│   DeployLockCli                                           │
├───────────────────────────────────────────────────────────┤
│ services/deploy/commands/*.cfc                            │  Pure string builders.
│   AppCommands, ProxyCommands, AccessoryCommands,          │  NO SSH, NO I/O.
│   BuilderCommands, RegistryCommands, AuditorCommands,     │  Testable offline.
│   LockCommands, HookCommands, DockerCommands              │  Mirror
│   + Base.cfc (docker/combine/pipe/chain helpers)          │  lib/kamal/commands/*
├───────────────────────────────────────────────────────────┤
│ services/deploy/config/*.cfc                              │  deploy.yml → typed tree
│   Config (root), Role, Accessory, Env, Builder, Proxy,    │  Mirror
│   Registry, Ssh, Validator                                │  lib/kamal/configuration/*
├───────────────────────────────────────────────────────────┤
│ services/deploy/lib/*.cfc                                 │  Generic primitives
│   SshClient (sshj facade), SshPool (parallel fan-out),    │
│   Mustache (jmustache facade), Yaml (snakeyaml facade),   │
│   Output (host-prefixed streaming logs), Auditor,         │
│   FakeSshPool (test double)                               │
└───────────────────────────────────────────────────────────┘
```

### 4.3 Dispatch

`wheels deploy [subcommand] [args...]` routes through `Module.deploy()`,
which peels the first positional token:

- `app`, `proxy`, `accessory`, `build`, `registry`, `secrets`, `server`,
  `prune`, `lock` → matching `Deploy<Area>Cli.cfc`.
- Everything else (`setup`, `deploy`, `redeploy`, `rollback`, `config`,
  `init`, `docs`, `details`, `audit`, `remove`, `upgrade`, `version`)
  → `DeployMainCli.cfc`.

Each `*Cli.cfc` parses flags, loads config (cached per process), builds the
relevant `*Commands.cfc`, and runs it via `SshPool`.

### 4.4 The "commands are strings" invariant

`*Commands.cfc` methods return strings or structs of the form
`{cmd: "docker run ...", shell: true, env: {...}, raiseOnNonzero: true}`.
They never open an network connection. Only `cli/*.cfc` and the
orchestrator composes and runs them.

Consequences:

- `--dry-run` is trivial: print what `*Commands` returned; skip execution.
- Unit tests assert on generated strings: no network, no Docker, no sshd.
- Porting each Kamal Ruby method is mechanical — translate the string
  template, preserve arg order and quoting.

### 4.5 Kamal source ↔ Wheels source mapping

| Kamal Ruby | Wheels CFML |
|---|---|
| `lib/kamal/cli/main.rb` | `services/deploy/cli/DeployMainCli.cfc` |
| `lib/kamal/cli/app.rb` | `services/deploy/cli/DeployAppCli.cfc` |
| `lib/kamal/cli/proxy.rb` | `services/deploy/cli/DeployProxyCli.cfc` |
| `lib/kamal/cli/accessory.rb` | `services/deploy/cli/DeployAccessoryCli.cfc` |
| `lib/kamal/cli/build.rb` | `services/deploy/cli/DeployBuildCli.cfc` |
| `lib/kamal/cli/registry.rb` | `services/deploy/cli/DeployRegistryCli.cfc` |
| `lib/kamal/cli/secrets.rb` | `services/deploy/cli/DeploySecretsCli.cfc` |
| `lib/kamal/cli/server.rb` | `services/deploy/cli/DeployServerCli.cfc` |
| `lib/kamal/cli/prune.rb` | `services/deploy/cli/DeployPruneCli.cfc` |
| `lib/kamal/cli/lock.rb` | `services/deploy/cli/DeployLockCli.cfc` |
| `lib/kamal/commands/app.rb` | `services/deploy/commands/AppCommands.cfc` |
| `lib/kamal/commands/proxy.rb` | `services/deploy/commands/ProxyCommands.cfc` |
| `lib/kamal/commands/accessory.rb` | `services/deploy/commands/AccessoryCommands.cfc` |
| `lib/kamal/commands/builder.rb` | `services/deploy/commands/BuilderCommands.cfc` |
| `lib/kamal/commands/registry.rb` | `services/deploy/commands/RegistryCommands.cfc` |
| `lib/kamal/commands/auditor.rb` | `services/deploy/commands/AuditorCommands.cfc` |
| `lib/kamal/commands/lock.rb` | `services/deploy/commands/LockCommands.cfc` |
| `lib/kamal/commands/hook.rb` | `services/deploy/commands/HookCommands.cfc` |
| `lib/kamal/commands/docker.rb` | `services/deploy/commands/DockerCommands.cfc` |
| `lib/kamal/commands/base.rb` | `services/deploy/commands/Base.cfc` |
| `lib/kamal/configuration/*.rb` | `services/deploy/config/*.cfc` (same names) |

Each `*Commands.cfc` carries a top-of-file comment pinning the Kamal
version mirrored plus the path to the Ruby source. When Kamal changes,
that comment is the diff target for our audit.

## 5. Config layer

### 5.1 Load pipeline

```
deploy.yml (bytes)
  → Yaml.parse() via snakeyaml              → plain struct
  → Env.interpolate()                       → ${VAR} resolved from
                                              ENV + .kamal/secrets
                                              + .kamal/secrets.<destination>
  → ConfigLoader.build()                    → typed Config component tree
  → Validator.validate()                    → throws DeployConfigError
  → Config (immutable)                      → passed to every consumer
```

### 5.2 Components

Each CFC mirrors a Kamal `lib/kamal/configuration/*.rb` module — no new
concepts invented.

| CFC | Role |
|---|---|
| `Config.cfc` | Root. `.servers`, `.roles`, `.accessories`, `.registry`, `.builder`, `.env`, `.ssh`, `.proxy`, `.boot`, `.healthcheck`, `.hooks`. |
| `Role.cfc` | A named server group (`web`, `job`, …) with its own env/cmd/options. |
| `Accessory.cfc` | Sidecar service (db, redis, search). |
| `Env.cfc` | `clear:` / `secret:` / `tags:` env merging per role. |
| `Builder.cfc` | Image build config (context, dockerfile, args, secrets, remote builder). |
| `Registry.cfc` | Image registry + credentials. |
| `Proxy.cfc` | kamal-proxy config (host, SSL, forward headers, buffering, healthcheck). |
| `Ssh.cfc` | user, port, keys, proxy host, log level. |
| `Validator.cfc` | Loud early failures. Unknown keys and missing required fields both error. |

### 5.3 Destinations

`--destination production` loads `deploy.yml` → deep-merges
`deploy.production.yml` on top. Matches Kamal's exact behavior. No new schema.

### 5.4 Secret resolution

`${FOO}` in `deploy.yml` resolves in order:

1. Process environment.
2. `.kamal/secrets` file (`KEY=value` lines).
3. `.kamal/secrets.<destination>` file.

Users can declare `export FOO=$(op read op://vault/item/field)` inside
`.kamal/secrets`; we run the file through the system shell at load time.
This preserves Kamal's contract — no embedded vault.

### 5.5 Deliberate divergence: Mustache replaces ERB inside `deploy.yml`

Kamal supports ERB inside `deploy.yml`:

```yaml
service: <%= ENV["APP_NAME"] %>
```

We cannot support ERB. Our replacement is a restricted Mustache context:

```yaml
service: {{env.APP_NAME}}
```

Only `env.*`, `destination`, and `hostname` are exposed. No arbitrary
logic (no loops, no conditionals, no method calls). This is the single
schema divergence from Kamal and is called out in the migration guide.

### 5.6 Errors

Every validation failure goes through `Validator.cfc` and emits a
line-scoped message, not a stack trace:

```
deploy.yml:42 servers.web[0]: "1.2.3.4.5" is not a valid host
```

## 6. Primitives (`lib/`)

### 6.1 `SshClient.cfc`

Facade over sshj's `SSHClient`. One instance per remote host.

```
ssh = new SshClient(host, {user, port, keys, proxyJump})
result = ssh.run(cmd, {pty: false, env: {}, stdin: ""})
           → {exitCode, stdout, stderr, durationMs}
ssh.upload(localPath, remotePath, {mode: 0644})
ssh.uploadString(content, remotePath, {mode: 0600})
ssh.download(remotePath, localPath)
ssh.stream(cmd, onStdoutLine, onStderrLine)
ssh.close()
```

- Key discovery: `~/.ssh/id_*`, `ssh-agent` via sshj's `AgentProxy`.
- Config: sshj's `OpenSSHConfig` parses `~/.ssh/config`.
- Host verification: `~/.ssh/known_hosts`.
- `ProxyJump` supported.
- Sudo wrapping: if `ssh.user != "root"`, root-requiring commands are
  wrapped as `sudo -n <cmd>`. A `sudo: a password is required` failure is
  converted to `"passwordless sudo not configured on <host>"`.

### 6.2 `SshPool.cfc`

Parallel fan-out across hosts. Java `ExecutorService` with configurable
parallelism (default = host count, capped at 10 to match SSHKit's
default runner). Connections cached per `user@host:port` and reused
across commands.

```
pool.onEach(hosts, function(ssh, host){ ... })   // all hosts, await all
pool.onAny(hosts, function(ssh, host){ ... })    // first success wins
pool.sequential(hosts, function(ssh, host){ ... })  // explicit serial
```

Output is line-buffered and prefixed with `[<host>]`.

### 6.3 `Mustache.cfc`

Facade over jmustache. Load-once template cache keyed by path. Default
rendering follows Mustache spec (missing key → empty). `renderStrict()`
variant throws on missing keys for config-critical templates.

### 6.4 `Yaml.cfc`

Facade over snakeyaml with `SafeConstructor` (no arbitrary Java class
instantiation — security baseline). Preserves key order on emit for
diff-friendly config writes.

### 6.5 `FakeSshPool.cfc`

Test double that records every `.run(cmd, host)` / `.upload(...)` /
etc. call without connecting. All `*Commands.cfc` tests and most
`*Cli.cfc` tests use this. Real SSH is exercised only by the nightly
integration tier.

### 6.6 Classloader isolation

JARs load via the two-parent URLClassLoader pattern already working for
Playwright: `PlatformClassLoader` as parent, TCCL swap during sshj calls.
snakeyaml and jmustache are pure-Java with no conflicting transitives
and don't need isolation. sshj requires care because of its BouncyCastle
transitive, which collides with Lucee's crypto loading when not isolated.

## 7. On-server parity contract

These conventions MUST match Kamal exactly. Deviations break the
coexistence guarantee.

| Concern | Value |
|---|---|
| Container name | `<service>-<role>-<version>` (e.g. `myapp-web-abc1234`) |
| Labels | `service=`, `role=`, `destination=`, `version=` |
| Docker network | `kamal` |
| Proxy config dir | `/home/<user>/.config/kamal-proxy/` |
| Lock file path | `/tmp/kamal_deploy_lock_<service>` |
| Dev-machine hooks | `.kamal/hooks/*` (executable shell scripts) |
| Hook env prefix | `KAMAL_*` (NOT `WHEELS_*` — preserves user hook compatibility) |

`kamal-proxy` is invoked remotely as `docker exec kamal-proxy kamal-proxy
deploy <service> --target <container-ip>:<port> --health-check-path
<path> ...`. This is the single load-bearing hand-off point. The producer
is ours (`ProxyCommands.deploy`); the switch is theirs.

## 8. Commands-as-classes layer

### 8.1 Pattern

Each Kamal `lib/kamal/commands/<area>.rb` becomes
`services/deploy/commands/<Area>Commands.cfc` with one public method per
shell-command-producing Ruby method.

```cfm
component extends="Base" {

    function run(required struct role, required string version) {
        var image = variables.config.absoluteImage(version);
        return docker(
            "run",
            "--detach",
            "--restart unless-stopped",
            "--name #containerNameFor(role, version)#",
            "--network kamal",
            labelArgs(role, version),
            envArgs(role),
            healthArgs(role),
            image,
            role.cmd
        );
    }

    function start(required string version) { ... }
    function stop(required string version)  { ... }
    function logs(required struct opts)     { ... }
    function containers() {
        return docker("ps", "--filter", "label=service=#config.service#");
    }
}
```

### 8.2 Base helpers

`Base.cfc` provides `docker(args...)`, `combine(cmds)`, `pipe(cmds)`,
`chain(cmds)`, `appendIf(cond, args)`. Names mirror `Kamal::Commands::Base`.

### 8.3 Orchestration

`DeployMainCli.deploy()` composes commands into a flow:

1. Run `before_deploy` hooks on the dev machine.
2. Acquire lock (`LockCommands.acquire` via `pool.onAny`).
3. Build + push image (`BuilderCommands`).
4. Pull image on every host in parallel (`pool.onEach`).
5. Boot proxy if absent (`ProxyCommands.boot`).
6. Rolling app boot: for each host in sequence, `AppCommands.run` →
   `ProxyCommands.deploy` (traffic switch) → next host.
7. Prune old containers (`PruneCommands`).
8. Release lock.
9. Run `after_deploy` hooks.

### 8.4 Hook contract

Hooks in `.kamal/hooks/` run on the dev machine with a `KAMAL_*`
env block matching Kamal's contract verbatim (`KAMAL_VERSION`,
`KAMAL_PERFORMER`, `KAMAL_HOSTS`, `KAMAL_ROLE`, `KAMAL_DESTINATION`,
`KAMAL_RUNTIME`). Prefix stays `KAMAL_` for compatibility; this is not
renameable without breaking every user's existing hooks.

### 8.5 Testing

- **Unit** (the bulk): assert on command strings produced by
  `*Commands.cfc`. No network, no Docker, no sshd.
- **Cli** (medium): `FakeSshPool` asserts on sequence and host dispatch.
- **Integration** (small, nightly only): dockerized sshd + dockerd
  fixture. Full deploy of an nginx container; flip to v2; rollback.
  Not run per-PR.
- **Dry-run comparison harness** (gating): for each fixture `deploy.yml`,
  run `kamal <verb> --dry-run` (Ruby) and `wheels deploy <verb> --dry-run`
  (ours) and semantic-diff the command lists. Normalization: tokenize each
  command → sort flags within a command → diff. Phase 1 and Phase 3 are
  gated on this harness passing for all in-scope verbs.

## 9. Phased plan

### Phase 0 — Foundations (no user-visible surface)

1. Vendor JARs at `cli/lucli/lib/deploy/` behind URLClassLoader.
2. `Yaml.cfc`, `Mustache.cfc` with full unit tests.
3. `SshClient.cfc`, `SshPool.cfc`, `FakeSshPool.cfc`.
4. Cross-engine smoke on Lucee 6/7 + Adobe 2023/2025 via dockerized sshd.

**Exit:** `new SshPool().onEach(["localhost"], (ssh) => ssh.run("uname -a"))`
green on both engines. No `wheels deploy` verb yet.

### Phase 1 — Config + dry-run `deploy` (surface: `wheels deploy --dry-run`)

1. Full `services/deploy/config/**`. Load Kamal's example `deploy.yml`
   verbatim as a fixture.
2. Minimum commands for the happy path: `AppCommands`, `ProxyCommands`,
   `RegistryCommands`, `BuilderCommands`, `DockerCommands`,
   `AuditorCommands`, `Base`.
3. `DeployMainCli` implementing `setup`, `deploy`, `redeploy`, `rollback`,
   `config`, `init`, `version`. Only `--dry-run` end-to-end.
4. `Module.deploy()` wiring.
5. Dry-run comparison harness vs. Ruby Kamal.

**Exit:** every command we would run matches Ruby Kamal byte-for-byte
(after semantic normalization) across the fixture corpus. No real deploys.

### Phase 2 — End-to-end deploy (surface: `wheels deploy` runs for real)

1. `SshPool` orchestration, hook dispatch, lock management,
   `.kamal/secrets` resolution, destination overlays.
2. `DeployAppCli` (boot/start/stop/logs/containers/images/live/
   maintenance/remove), `DeployProxyCli`, `DeployRegistryCli`.
3. Integration test: dockerized sshd + dockerd, deploy trivial app, flip
   v1→v2, rollback.
4. Dogfood: ship wheels.dev with `wheels deploy`.
5. Docs: 4.0 production deploy page finally lands.

**Exit:** new user can `wheels g new` → `wheels deploy init` → edit
`deploy.yml` → `wheels deploy setup` → `wheels deploy` → running app.

### Phase 3 — Parity fillout (near-parity target)

1. `DeployAccessoryCli` + `Accessory` config + `AccessoryCommands`.
2. `DeployBuildCli` (deliver/push/pull/create/remove/details/dev).
3. `DeploySecretsCli` with external adapter shell-outs (1Password,
   Bitwarden, AWS Secrets Manager).
4. `DeployServerCli`, `DeployPruneCli`, `DeployLockCli`.
5. Streaming `app logs`, remote-command running via `app exec`.
6. `audit`, `docs`, `details`, `remove`, `upgrade` top-level verbs.
7. Comparison harness expanded to every in-scope verb.

**Exit:** verb table fully green. Ruby Kamal users can move by swapping
the binary.

### Phase 4 — Post-ship hardening (demand-driven, optional)

1. Promote `Ssh`, `Mustache`, `Yaml` to LuCLI core if non-Wheels users
   ask.
2. Windows workstation polish (named-pipe ssh-agent).
3. Hook-contract extensions beyond `KAMAL_*`.
4. Parallelism tuning informed by real deploy telemetry.
5. Possibly revisit TUI (non-goal #4).

### Dogfooding gate

Phase 2 exits only when wheels.dev has been shipped using `wheels deploy`.
If we can't deploy our own docs site, we don't ask anyone else to.

## 10. Risks

1. **sshj on Adobe CF.** BouncyCastle transitive collisions are a known
   hazard despite the Playwright precedent. Mitigation: Phase 0 exit
   criterion is green on both engines; fallback is a BC-free subset of
   sshj or a switch to `apache-mina-sshd`. Cost: ~1 week, not a rewrite.
2. **Drift from a moving target.** Kamal ships breaking on-server
   behavioral changes without SemVer signalling (e.g. 2.1 proxy boot).
   Mitigation: each `*Commands.cfc` pinned by header comment to a Kamal
   version; comparison harness runs against that version; "Kamal 2.X is
   out" is an audit event, not an auto-upgrade.
3. **kamal-proxy version coupling.** The `kamal-proxy deploy <svc>
   --target` CLI is the hand-off contract. Mitigation: pin the
   kamal-proxy image tag in our default template; treat as external API.
4. **Dry-run parity is aspirational.** Byte-identical output vs. Ruby
   Kamal will fail on arg ordering, quote style, whitespace. Comparison
   harness uses semantic diff (tokenize → sort flags within a command →
   diff) from the start.
5. **Secrets shell-out on Windows.** `op`, `bw`, `aws` CLIs assume the
   user's adapter is installed locally. Windows without WSL is worse;
   accepted as best-effort.
6. **Lock file race.** `/tmp/kamal_deploy_lock_<service>` atomicity
   depends on the remote filesystem's `ln -s` semantics. Inherited from
   Kamal. Documented limitation.
7. **Near-parity verb sprawl.** ~25 top-level + ~60 subcommand methods
   across Phase 2 + 3. Risk: lose momentum before parity, ship a "mostly
   Kamal" tool with sharp edges. Mitigation: comparison harness is the
   stop-ship gate — verbs that don't pass don't ship. No half-verbs.

### Non-risks (named to avoid over-investing)

- YAML edge cases (snakeyaml is battle-hardened).
- Template engine bugs (jmustache is tiny, stable).
- Parallel SSH (2–20 hosts, thread-pool + sshj — not a research problem).
- Docker CLI compatibility (stable).

## 11. Open questions

- First dogfood target — wheels.dev, or a smaller internal app first?
- Vendor a specific kamal-proxy image tag, or always `basecamp/kamal-proxy:latest`? (Lean: pin explicit version.)
- Config filename — `config/deploy.yml` (exact Kamal) or `.kamal/deploy.yml` (matches `.kamal/secrets`, `.kamal/hooks` siblings)?
- `wheels deploy init` templates — Wheels-flavored default (health-check `/up`, Lucee-tuned Dockerfile) or bare Kamal stub?
- Failure surfacing — exit code only, or also an on-dev-machine `wheels deploy audit` log?
- Relationship to existing `wheels server` local-dev loop — separate concerns or overlap?
- Telemetry — opt-in anonymous deploy-success counter? (Lean: no telemetry, off-brand for OSS Wheels.)

## 12. Decision log

| # | Decision | Rationale |
|---|---|---|
| 1 | Near-parity verb surface (~25 verbs) | Migration story for Kamal users; commits us to mechanical porting |
| 2 | Embedded SSH via sshj | Structured I/O, no shell-out fragility, deterministic across platforms |
| 3 | Commands-as-classes mirroring Kamal's split | Enables dry-run, unit testing without network, mechanical port |
| 4 | Mustache (jmustache) for non-CFML templates | No CFML `##` escaping pain; logic-free enforces command-class boundary |
| 5 | YAML schema verbatim | Users `mv config/deploy.yml` and migrate |
| 6 | On-server bit-compatible with Ruby Kamal | Coexistence escape hatch during evaluation |
| 7 | Code lives in Wheels module, not LuCLI core | Derisks LuCLI 1.0; promote later if demand |
| 8 | Mustache replaces ERB inside `deploy.yml` | One deliberate schema divergence; ERB not renderable in Java |
| 9 | Hook env prefix stays `KAMAL_*` | User hooks work unchanged |
