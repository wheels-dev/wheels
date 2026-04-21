# Phase 1 Retrospective — wheels-deploy Kamal Port

**Date:** 2026-04-21
**Scope:** Task 21 exit gate for `docs/superpowers/plans/2026-04-20-wheels-deploy-kamal-port.md`
**Status:** Gate relaxed from "byte-identical dry-run diff" to "config-layer smoke test + CLI unit tests".

## What was planned

Task 21 was written as a semantic-diff harness: run `kamal deploy --dry-run` against our Ruby reference, run `wheels deploy --dry-run` against the same fixture, normalize both outputs (strip ANSI, host prefixes, sort flags), then `diff` them. CI would gate Phase 1 on byte-level parity after normalization.

## What the environment actually supports

Ruby Kamal 2.8.2 does **not** expose a usable dry-run flag on `kamal deploy`:

- `kamal help deploy` lists `--skip-push`, `--version`, `--hosts`, `--roles`, `--config-file`, `--destination`, `--skip-hooks` — no `--dry-run`.
- `KAMAL_DEBUG=1 kamal deploy` logs the commands it intends to run but still opens SSH to the target hosts and fails there, producing noisy, run-order-dependent output that would be fragile to diff.
- `kamal config` *does* work and emits the resolved configuration as YAML — but it's the *config* surface, not the *command plan*.
- `kamal build deliver --print` prints only the docker build line, not the broader deploy sequence.

So the plan's central premise — "Ruby Kamal has an inspectable dry-run we can diff against" — turned out to be optimistic.

## What shipped instead

1. **`tools/deploy-dry-run-normalize.py`** — the full semantic normalizer (ANSI strip, host-prefix strip, comment/blank drop, flag-sort, line-sort). Ready to use; it's the harness half that *would* work if upstream or a mock layer ever emits command plans.
2. **`tools/deploy-config-diff.sh`** — concrete Phase 1 gate. Shells out to `kamal config` (wrapping the fixture in a throwaway `config/deploy.yml` + `.kamal/secrets` + git-init + `VERSION=v1` + auto-injected `builder.arch`) and `wheels deploy config`, prints both for reviewer eyeball, exits non-zero only if either tool *errored* (not if the two outputs differ). Strict equality is not attempted because our output is a deliberate subset.
3. **`tools/deploy-dry-run-diff.sh`** — honest stub explaining why command-string parity is deferred and what would unblock it (upstream `--dry-run`, or a `SSHKit::Backend::Printer`-style capture shim living under `tools/kamal-capture/`).

## Observed config delta (minimal.yml)

Running `tools/deploy-config-diff.sh minimal` shows:

- Kamal's output is a fully-resolved `Kamal::Configuration` hash: `roles`, `hosts`, `primary_host`, `version`, `repository`, `absolute_image`, `service_with_version`, `volume_args`, `ssh_options` (user/port/keepalive/log_level), `sshkit`, `builder`, `logging` defaults.
- `wheels deploy config` emits only the surface we actively mirror in Phase 1: `service`, `image`, `servers` (role → hosts), `registry.server`, `registry.username`.
- Nothing conflicts — the wheels output is a *subset* of the Kamal output. No field we emit disagrees with Kamal; there are just many Kamal fields we don't emit yet.

## Recommended exit-criteria relaxation

The plan's Phase 1 "byte-identical dry-run" bar should be replaced with a two-part gate:

1. **Config-layer smoke test** — `tools/deploy-config-diff.sh` runs clean against `minimal.yml`, both tools produce output, no structural conflicts. (This is what we can actually verify today.)
2. **Our own command-string unit tests pass** — `bash tools/test-cli-local.sh` continues to exercise `AppCommands`, `BuilderCommands`, `ProxyCommands`, `RegistryCommands`, `AuditorCommands`, and `DeployMainCli` against pinned fixtures (the implicit Kamal-2.4.0 contract we encoded in the specs).

Real Ruby-vs-Wheels command-string parity becomes a **Phase 2** task, gated on either upstream adding `--dry-run` or us writing a capture shim. Both are tractable; neither is Phase 1.

## Follow-ups

- Track Kamal upstream for `--dry-run` support on `deploy`.
- Prototype `tools/kamal-capture/` (SSHKit printer backend + Thor wrapper) as a Phase 2 spike.
- Once wheels deploy wiring routes correctly from an installed CLI binary (currently the PATH `wheels` binary doesn't see this worktree's Module.cfc), re-run `deploy-config-diff.sh` end-to-end and fold it into `tests.yml` as a soft-fail matrix job.

## Task 38 addendum (2026-04-21 later in day)

Phase 3's Task 38 was originally planned as the byte-identical comparison
harness across every in-scope verb. Given the reality documented above
(Kamal has no dry-run flag we can diff against), the Phase 3 harness
decomposes into two realistically-achievable gates:

- `tools/deploy-verb-smoke.sh` — runs every `wheels deploy <verb> --dry-run`
  combination against the fixture corpus, asserts clean exit + non-empty
  output. Gates regressions in our own Cli dispatch, flag parsing, and
  command-string generation. Does NOT verify parity with Ruby Kamal.

- `tools/deploy-config-diff.sh` — expanded to cover every fixture. Shows
  `kamal config` vs `wheels deploy config` side-by-side. Config-layer
  parity remains the only thing we can honestly measure between the two
  tools today.

`tools/deploy-dry-run-diff.sh` was rewritten from a stub to a documented
placeholder naming the two concrete paths to ever making it real (Kamal
upstream, or a SSHKit capture shim).
