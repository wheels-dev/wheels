# E2E deploy fixture

End-to-end integration test fixture for `wheels deploy`. See
`cli/lucli/tests/specs/deploy/integration/E2EDeploySpec.cfc` for the tests
that consume this.

## Approach: mock docker shim

The fixture is a single `linuxserver/openssh-server` container on port
**22024** (distinct from the plain sshd fixture on 22022/22023 so both can
coexist). At container start, `install-shims.sh` runs via
`/custom-cont-init.d/` and copies `docker-shim.sh` into `/usr/local/bin/`
as both `docker` and `kamal-proxy`. Every invocation appends to
`/tmp/docker-invocations.log`.

This is approach **(c)** from Task 29's three options:

- **(a) docker-in-docker**: privileged mode + registry pulls = flaky on
  macOS Docker Desktop and GHA runners. Rejected.
- **(b) mount host docker socket**: requires installing a docker client
  binary in the sshd container + resolves to whatever dockerd the host is
  running, which isn't reproducible. Rejected.
- **(c) mock shim**: the `wheels deploy` code path through DeployMainCli →
  SshPool → SshClient → sshj → remote shell is exercised identically to
  production; only the thing executing on the remote is replaced. We lose
  the ability to curl a real HTTP "v1"/"v2" response, but we keep
  actionable assertions about which commands got dispatched where.

## Gating

The E2E spec is **skipped by default**. Set `DEPLOY_E2E=1` in the env to
run it:

```bash
DEPLOY_E2E=1 bash tools/test-cli-local.sh
```

Without that flag, the 3 specs early-return and count as passes — no
Docker involvement, no fixture lifecycle.

## Start / Stop

```bash
bash tools/deploy-e2e-up.sh
bash tools/deploy-e2e-down.sh
```

The spec's `beforeAll`/`afterAll` calls these via `DeployShellHelper`.

## Keys

`test_key` / `test_key.pub` / `authorized_keys` are copied verbatim from
the sibling `sshd/` fixture — a deterministic ed25519 keypair with NO
production value. Duplicating them keeps `DeployShellHelper`'s path
conventions happy without cross-fixture coupling.

## Phase 3 future work

- `app/Dockerfile.v1` / `Dockerfile.v2` are scaffolding for a future
  upgrade to real container execution (e.g. `docker save` + `docker load`
  into a dind sidecar, then assert against real HTTP responses).
- Swap the mock shim for a real dockerd and replace log-inspection
  assertions with `curl http://localhost:<proxy-port>` "v1" / "v2" checks.
