# Wheels 4.x Candidate Backlog

**Status:** current-version candidate list, compiled 2026-08-30 from a full
audit of the (since-removed) plans corpus. Everything else shipped or was
deliberately superseded. The 5.0 scope lives separately in
[wheels-5-roadmap.md](wheels-5-roadmap.md).

> Items marked **Done** shipped on the 2026-08-30/31 4.x-backlog branch
> series (PRs #3452–#3455); items marked **Deferred** are deliberately out
> of scope for now (see reasons).

## Shipped-era leftovers

1. ~~`wheels dbmigrate diff` CLI~~ — **Done.** `wheels migrate diff` /
   `dbmigrate diff` wired to the `CliBridge`/`AutoMigrator` diff surface,
   with `--rename`/`--hints`/`--threshold`/`--write`; MCP `migrate` action
   registration fixed.
2. ~~Bot pipeline squash-only~~ — **Done.** `allow_merge_commit=false` applied to
   `wheels-dev/wheels` (squash + rebase only).
3. ~~Deploy-secrets regression tests~~ — **Done.** `fetch/extract/print-secrets`
   flat-alias spec blocks enabled, plus the underlying fixes: the command-spec
   harness (`mod.__arguments`) now consumes the `this`-scope shape
   `structuredArgs` was missing; `deploy()` constructs `DeployMainCli` lazily;
   `$deploySecretsVerb` defaults `projectRoot` to the module cwd.
4. ~~Fresh-VM finding #1 (batch F)~~ — **Done.** `BuildInfo.version()` now falls
   back to the sibling `wheels.json`/`box.json` version when the
   `@build.version@` placeholder is unstamped, so released installs show the
   real version in the debug bar instead of `0.0.0-dev`.
5. ~~Packages phase-1 leftovers~~ — **Done.** Empty `packages/basecoat|hotwire/`
   shells deleted.
6. ~~Kamal boot strategy~~ — **Done.** `config/Boot.cfc` (`limit` 10, `wait` 5,
   string/percentage tolerant) + `Config.boot()` accessor + validator allowlist.
7. ~~RocketUnit deprecation warning~~ — **Done.** `wheels.Test` emits a
   one-time `$deprecated` warning on DI instantiation.
8. ~~Vestigial `wheels-dev/wheels-cli-lucli` repo~~ — **Done.** Archived.

## Framework gaps flagged by the guides phase-1 rewrite (2026-04-19)

9. ~~bcrypt password-hash helper (#4)~~ — **Done.** Pure-CFML `bcryptHash` /
   `bcryptVerify` / `bcryptNeedsRehash` in `vendor/wheels/global/security.cfm`
   (standard `$2b$` 60-char hashes, OpenBSD-compatible) on
   Lucee/Adobe/BoxLang; RustCFML, which ships `bcryptHash`/`bcryptVerify` as
   native builtins, serves the same API and gets `bcryptNeedsRehash` from the
   always-included `security-extra.cfm`.
10. ~~`wheels.auth.enableSession` facade (#6)~~ — **Done.** `enableSession()`
    global helper wires the authenticator + session strategy singletons and
    registers the `session` strategy idempotently from `config/services.cfm`.
11. ~~`wheels migrate --offline` (#10)~~ — **Done.** `WHEELS_OFFLINE=1` /
    `--offline` accepted on migrate/db; update-check skipped and the package
    registry fails fast with a clear message when offline.
12. ~~`wheels generate --dry-run` (#14)~~ — **Done.** `--dry-run` prints
    would-be paths across all generators and writes nothing.
13. ~~route `bindBy=` (#19)~~ — **Done.** `bindBy="slug"` resolves the route
    param via the parameterized `findOneBy<Property>()` finder, orthogonal to
    `binding=`.
14. ~~DI `toFactory()` (#20)~~ — **Done.** `map("x").toFactory(function(ctx){...})`
    with transient/singleton/request-scoped interplay, snapshot/restore
    integration, and interface coverage.
15. **i18n package / primitives (#18, #21)** — **Deferred.** A framework-level
    i18n package is a separate product decision (the `wheels-i18n` repo is
    tracked in the packages registry); no primitives shipped in this pass.
16. ~~`services.cfm` scaffold stub (#7)~~ — **Done.** `wheels new` now emits
    `config/services.cfm` (auto-included by `onapplicationstart`).
17. ~~`user-mailer.txt` codegen snippet extends a nonexistent `wheels.Mailer` (#17)~~ —
    **Done.** Snippet + `app/mailers/README.md` rewritten to the real pattern
    (plain CFCs wrapping `sendEmail()` via the `controller()` factory).

## Uncertain / decisions

18. ~~`stripTags()` / `stripLinks()` encoding-default review~~ — **Resolved.**
    `encode` stays opt-in (default false, configurable per-function); the doc
    comments now state the contract and point to `h()`/`hAttr()` for escaping.
19. **LuCLI upstream (external)** — **Deferred.** Parallel-spawn race (#11) and
    compile-driver PR #56 remain upstream items; nothing actionable in-repo.
20. ~~Wheels 5 §7 `wheels doctor` checks~~ — **Done.** `wheels doctor` now warns
    on legacy `wheels.Test`/`wheels.Testbox` specs, non-empty `plugins/`
    directories, and raw `params.` mass assignment into `create`/`update`/`save`
    (warn-only, comment-stripped scan).

The full per-plan audit trail lives in git history (the plans were removed
in the 2026-08-30 cleanup commit).
