# Wheels 4.x Candidate Backlog

**Status:** current-version candidate list, compiled 2026-08-30 from a full
audit of the (since-removed) plans corpus. These are the only items from
those plans that were NOT implemented. Everything else shipped or was
deliberately superseded. The 5.0 scope lives separately in
[wheels-5-roadmap.md](wheels-5-roadmap.md).

## Shipped-era leftovers (small, concrete)

1. **`wheels dbmigrate diff` CLI** — the auto-migration rename-detection
   framework layer is fully done (`vendor/wheels/migrator/RenameDetector.cfc`,
   39 specs, MCP `migrate(action="diff")`, `CliBridge.diff`), but the command
   was never wired into the live `wheels` CLI: `cli/lucli/Module.cfc` migrate
   actions are `latest|up|down|info|doctor|forget|pretend|rename-system-tables`.
   Source: `docs/superpowers/plans/2026-04-15-auto-migration-rename-detection.md`
   (removed).
2. **Bot pipeline squash-only** — set `allow_merge_commit=false` on
   `wheels-dev/wheels` (2026-06-03 bot-pipeline-unblock plan Task 2); the repo
   still reports `allow_merge_commit=true`.
3. **Deploy-secrets regression tests** — the flat-alias dispatch shipped, but
   the acceptance blocks in `cli/lucli/tests/specs/commands/DeployCommandSpec.cfc`
   (~lines 94, 130, 158) are `xdescribe` (disabled). Enable them.
4. **Fresh-VM finding #1 (batch F)** — unify the version surface: the Homebrew
   formula should stamp the release version so the dev debug bar stops showing
   `0.0.0-dev` (`vendor/wheels/BuildInfo.cfc:43` returns it whenever `isDev()`).
5. **Packages phase-1 leftovers** — delete the empty `packages/basecoat/` and
   `packages/hotwire/` shells (only `.DS_Store` remains).
6. **Kamal boot strategy** — `cli/lucli/services/deploy/config/Boot.cfc` never
   landed; `config/Validator.cfc:17` still comments "doesn't implement yet
   (boot, logging, retain_containers, hooks, …)".
7. **RocketUnit deprecation warning** — wheels-5-roadmap §5.4 promised a 4.x
   runtime warning in `vendor/wheels/Test.cfc`; none exists yet (the legacy
   `Plugins.cfc` path already warns).
8. **Vestigial `wheels-dev/wheels-cli-lucli` repo** — single 2026-04-04 seed
   commit; its sync workflow was removed when the distribution moved to the
   branded `wheels` binary. Archive or delete (external action).

## Framework gaps flagged by the guides phase-1 rewrite (2026-04-19) — still absent

9. bcrypt password-hash helper (#4)
10. `wheels.auth.enableSession` facade (#6)
11. `wheels migrate --offline` (#10)
12. `wheels generate --dry-run` (#14)
13. route `bindBy=` (#19)
14. DI `toFactory()` (#20)
15. i18n package / primitives (#18, #21)
16. `services.cfm` scaffold stub (#7)
17. `user-mailer.txt` codegen snippet extends a nonexistent `wheels.Mailer` (#17)

## Uncertain / needs a decision

18. `stripTags()` / `stripLinks()` encoding-default review (4.0-audit
    follow-up; the question was raised but never resolved).
19. LuCLI upstream (external): parallel-spawn race (#11) and the
    compile-driver PR #56 merge state.
20. Wheels 5 §7 `wheels doctor` checks (raw-`params` mass assignment, legacy
    test base, legacy plugins) could land in a 4.x ahead of 5.0 — see the
    5.0 roadmap.

The full per-plan audit trail lives in git history (the plans were removed
in the 2026-08-30 cleanup commit).
