# Changelog

All notable changes to this project will be summarized in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

----
## About the CFWheels → Wheels Rebrand

**Note:** Starting with version 3.0.0, the project has been renamed from "CFWheels" to "Wheels" as part of our evolution and modernization efforts. This rebrand includes:

- **Project Name**: CFWheels → Wheels
- **GitHub Organization**: `cfwheels/cfwheels` → `wheels-dev/wheels`
- **Domain**: `cfwheels.org` → `wheels.dev`

All historical references to "CFWheels" in this changelog have been preserved for accuracy. When you see "CFWheels" in entries below, that was the project name at the time of that release.

----

# [Unreleased]

### Fixed

- CLI services in `Module.cfc` now instantiate via the module-relative path (`new services.X()`) instead of the absolute FQN (`new cli.lucli.services.X()`), so `wheels new` and the other subcommands resolve their service classes when running from the installed distribution. The module tarball is built with `tar -C cli/lucli .`, which flattens the module root so services live at `<module-root>/services/` with no `cli/lucli/` tree and no `cli.lucli` mapping — the absolute form only resolved against the source-tree layout. That split is why the `fast-test` job (which runs from source, where both forms resolve) stayed green while the snapshot smoke test — which installs the built tarball and runs `wheels new` — failed on every `develop` push since #2861 with `could not find component or class with name [cli.lucli.services.ArgSpec]`. All 8 absolute references (7× `ArgSpec`, 1× the latent `TestRunner` call) are converted to the relative form the 17 sibling services already use; the `ArgSpec` docblock example is updated to match so it cannot re-seed the pattern (#2873)
- Oracle `DROP TABLE` / `DROP VIEW` in the migrator now work on Oracle 19c/21c. `wheels.databaseAdapters.Oracle.OracleMigrator::dropTable()` emitted `DROP TABLE IF EXISTS <name> CASCADE CONSTRAINTS` and `dropView()` inherited `DROP VIEW IF EXISTS` from `Abstract`, but Oracle only added the `IF EXISTS` DDL modifier in 23c — on 19c/21c both are a hard parse error (ORA-00933). Because the `remove-table` migration template re-throws on error, `migrate down`, rollbacks, `force`-create, and migrator test re-runs failed outright on pre-23c Oracle. Both helpers now emit the version-agnostic Oracle PL/SQL idiom — `BEGIN EXECUTE IMMEDIATE 'DROP TABLE <name> CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;` — which runs the bare DROP and swallows ORA-00942 ("table or view does not exist"), preserving "drop if exists" semantics on every supported Oracle version with no version detection. `$execute` (`vendor/wheels/migrator/Base.cfc`) never splits on `;` and deliberately omits the trailing-semicolon append for Oracle, so the anonymous block reaches the driver intact. Framework-side counterpart to the demo-app test-populate fix in #2864 (#2869)
- `application.wheels.protectedControllerMethods` is now populated at application start from the public method surface of `wheels.Global` plus the `wheels.controller.*` and `wheels.view.*` mixin components, so framework helpers like `env()`, `model()`, `findAll()`, `redirectTo()`, and `linkTo()` can no longer be invoked as controller actions from a URL. The list was previously initialized to an empty string (the orphaned `local.allowedGlobalMethods = "get,set,mapper"` line in `onapplicationstart.cfc` pointed to the intent but never wired it up), so `$callAction()`'s allow-list check was a no-op. Any unauthenticated `GET /<anyController>/env` request reached the global `env()` helper directly and raised `"The parameter [name] to function [env] is required but was not passed in."` as a 500; other helper names dispatched into unintended code paths. Derived from `getMetaData().functions` on each source component (excluding `$`-prefixed internal methods, which are already gated separately), so the list stays in sync with the framework's mixin surface automatically. Reaching one of these names now throws `Wheels.ActionNotAllowed` and falls through to the missing-action / 404 path, matching every other non-existent action. **Migration note:** applications that defined controller actions with the same name as a public framework helper (e.g. `env`, `model`, `redirectTo`) will need to rename those actions — they now return 404 rather than dispatching, since the protection gate at `processing.cfc:132` fires before the `StructKeyExists(this, action)` lookup that would otherwise reach a same-named user action (#2844)

### Added

- wheels-bot can now review **fork PRs** (external / first-time contributors), which it previously could not. GitHub withholds both the `vars` context and `secrets` from `pull_request` runs triggered by a forked repository, so Reviewer A's `vars.WHEELS_BOT_ENABLED == 'true'` job gate read empty and the job skipped — and Reviewer B, which only fires after A submits a review, never ran. A new `bot-review-a-fork.yml` workflow runs the initial Reviewer A review via `pull_request_target` (which executes in the base-repo context, where vars + secrets are available) for fork PRs that a maintainer has tagged with the `bot-review` label. Hardened against the `pull_request_target` "pwn-request" class: it checks out the **base** branch only and reviews the fork's changes through `gh pr diff`, never checking out or executing fork-controlled code, so the local `./.github/actions/wheels-bot-skip-check` composite action always resolves to trusted base code (the fork's commit objects are fetched read-only via `refs/pull/<n>/head` so the review's git commands still resolve). `bot-review-b.yml` is hardened the same way — it previously checked out `github.event.review.commit_id` (a fork commit on fork PRs) and then ran that local composite action, a latent pwn-request that was unexploitable only because Reviewer A never started the loop on forks; it now checks out the base branch with `persist-credentials: false`. The `bot-review` label (appliable only by write-access users) is the human-in-the-loop vet of the fork diff, and Reviewer A's tool surface stays read-only (#2871)
- `cli.lucli.services.ArgSpec` — a typed argument-spec builder for Wheels CLI subcommands. LuCLI hands every module function a structured argument map (positionals as `arg1, arg2, ...`; `--key=value` as `key=value`; `--no-key` normalized to `key=false`), but `Module.cfc::argsFromCollection()` has historically flattened that map back to argv so each of ~18 subcommands could re-parse it with a hand-rolled token loop. The flatten step was the root cause of #2855 (it silently dropped every `false` value, so `--no-sqlite`/`--no-routes`/`--no-test-db`/`--no-open-browser` never survived the round trip) and is structurally lossy — it cannot distinguish a genuine `--no-X` negation from an explicit `--X=false`. `ArgSpec` consumes the structured handoff directly: a command declares its positionals, flags, and options up front (`.positional(name, required, default, type)`, `.flag(name, default)`, `.option(name, default, type)`), then calls `.parse(arguments)` to receive a typed result struct — no flatten, no re-parse, no lossy `false` round trip. Designed for incremental adoption: `getArgs()` and `argsFromCollection()` remain in place as a deprecated shim until every call site is converted, and each command that adopts `ArgSpec` drops its hand-rolled token loop in the same change. Cross-engine clean (no closures, no struct-member collisions, no `application`-scope function storage, no `attributeCollection = arguments`); boolean coercion handles both the string `"false"` LuCLI normally emits and a literal `false` value, so Lucee/Adobe/BoxLang all agree on the parsed semantics. Required-positional violations throw `Wheels.CLI.MissingArgument` with the positional's declared name in the message. The cross-framework research that informed the API surface (Rails/Thor, Laravel/Artisan, Django/argparse, Phoenix/Mix, Spring/picocli, Symfony Console) is recorded on the issue (#2861)
- A "Reserved scope names" section in the Controllers and Actions guide documenting identifiers (`client`, `url`, `form`, `session`, `cgi`, `request`, `application`, `cookie`, `server`, `arguments`, `variables`, `local`, `this`) that must not be used as local variable names in Wheels controllers (and CFML components generally). Specifically calls out `client` — the most confusing case — because Lucee 7 throws `"client scope is not enabled"` when `clientManagement` is off, making the error look like an application misconfiguration rather than a bad variable name (#2833)
- RustCFML is now recognized as a first-class engine in the engine-adapter layer. Wheels detects it via `server.coldfusion.productName == "RustCFML"` (it exposes no `server.lucee`/`server.boxlang`), instantiates a `RustCFMLAdapter` (extends `Base`, whose defaults are Lucee-shaped, matching RustCFML's semantics) ordered before the Adobe ColdFusion fallback, and accepts any version in `$checkMinimumVersion` (RustCFML is pre-1.0 and rapidly evolving, so the usual minimum-version guard doesn't apply). Because RustCFML does not yet implement the `cfcache` built-in, the framework's cfcache-backed template/static cache degrades gracefully to a no-op when the adapter reports `supportsCfcache() = false`, so requests still render (cacheless-but-working). The new `supportsCfcache()` capability defaults to `true` on Lucee/Adobe/BoxLang, leaving their behavior unchanged. Support is best-effort: RustCFML is a young, JVM-free CFML interpreter and is not yet part of the CI matrix (#2837)
- The built-in `/_browser/login-as` browser-test fixture (mounted by `set(loadBrowserTestFixtures = true)`) now honors an `application.wheels.browserLoginAsHandler` override. Set it in `config/settings.cfm` — `set(browserLoginAsHandler = "AuthFixture##loginAs")` — and the framework dispatches `/_browser/login-as` to that controller##action instead of the default `BrowserTestLogin##create`, letting apps with richer session shapes (e.g. `session.member = { id, email, firstName, lastName }`) drive the fixture without forking the vendor tree or duplicating the route + env-gate boilerplate. Env-gating moves to a new `wheels.middleware.BrowserTestFixtureGuard` middleware attached to the `/_browser` scope so the gate still applies under override. The setting falls back to `BrowserTestLogin##create` when unset or empty (#2830)

### Changed

- Eight leaf CLI subcommands — `new`, `seed`, `notes`, `analyze`, `doctor`, `stats`, `upgrade`, and `destroy` — now consume LuCLI's structured `argCollection` directly via `cli.lucli.services.ArgSpec` (`.parse(structuredArgs(arguments))`) instead of flattening it back to argv and re-parsing with a hand-rolled token loop (the round trip tracked in #2861, whose `ArgSpec` foundation shipped in #2862). Beyond removing the per-command parsing duplication, this fixes a latent bug the round trip masked: the legacy `getArgs()` only rebuilt argv when a positional `arg1` was present, so **named-only** invocations were silently dropped one layer in — `wheels seed --environment=production`, `wheels doctor --verbose`, `wheels stats --verbose`, and `wheels notes --annotations=...` all ran with defaults regardless of what the user passed. Consuming the structured map directly means the named keys (and `--no-X` negations) survive. **One deliberate behavioral delta:** `wheels new` with options but no app name (e.g. `wheels new --no-sqlite`) now errors with the #2214 `Wheels.InvalidArguments` "app name required" exception instead of falling through to the usage guide — previously the `arg1`-gate dropped the named-only args, leaving an empty arg list that took the usage branch. Everything else is preserved: each command keeps its usage branches and the #2214 throw, `destroy`'s `<type> <name>` / `<name> <type>` smart reorder (now gap-tolerant, so `--force` may appear before or after the positionals), `upgrade`'s `check`-gate and `--dry-run` / `--to` "did you mean" nudge, and `doctor` / `stats`'s `-v` shorthand (which LuCLI delivers as a positional, not a flag). A new private `structuredArgs()` / `argvToCollection()` helper pair sources the collection — preferring LuCLI's live handoff and reconstructing it from the instance-level `__arguments` fallback for internal delegation (e.g. `create` → `new`) and unit tests. The migrated parse logic is covered by server-free specs in `cli/lucli/tests/specs/commands/CommandArgParsingSpec.cfc` (via `ModuleArgvProbe`). `getArgs()` / `argsFromCollection()` remain as the deprecated shim for the not-yet-migrated commands — the dispatchers (`generate`, `create`, `db`, `browser`), the parser-delegating `deploy` / `packages`, `migrate`, and the space-separated-flag `test` / `console` — and the shim is removed once those are converted (#2861)
- Reconcile bot pipeline unblock plan doc with shipped implementation: mark checkboxes as historically complete and align the allowlist note with the final `classify-conflicts.sh`
- Version switcher now labels the 4.0 stable docs "v4.0 (current)" (was "v4.0.0"); the vestigial pre-GA `v4-0-1-snapshot` guides tree is removed and its one unique page, "Reading the Changelog", is salvaged into `v4-0-0/upgrading/`. Both sites deploy from `develop`, so in-progress patch docs already live in the `v4-0-0` tree; a separate `*-snapshot` tree is only warranted when a different minor/major (e.g. `v4-1-snapshot`) is under development. Courtesy redirects cover the high-traffic `/v4-0-1-snapshot/*` paths (#2827)
- CLI path normalisation now lives in a single, unit-tested `Helpers.normalizePath()`; `Module.$normalizePath()` (added in #2835 to fix the Windows `Resource provider [c]` crash) delegates to it instead of carrying a private copy, so the regression coverage exercises the real bootstrap path rather than a decoy. The CLI installation guide also gains a Windows troubleshooting entry for the original `there is no Resource provider available with the name [c]` error (#2841)

### Fixed

- wheels-bot no longer re-fires Reviewer A/B on commits it has already reviewed. The review idempotency markers (`<!-- wheels-bot:review-a:<pr>:<sha> -->` / `review-b`) embedded a SHA the skill prompts re-derived at review time via `gh pr view --json headRefOid`, which races with pushes that land mid-session: between the workflow's checkout and the model's `gh pr view` call a new push could move the PR head, so the emitted marker SHA lagged the commit the review actually ran against. The skip-check gate then failed to recognise an already-reviewed head and Reviewer A re-fired on superseded commits while Reviewer B emitted contradictory verdicts on different SHAs (observed across the #2847 review cycle, where Reviewer B self-diagnosed the drift twice). The workflows now capture the head SHA exactly once and thread it into the prompts as an explicit `<head-sha>` argument: `bot-review-a.yml` passes the already-checked-out `steps.pr.outputs.sha` into `/review-pr` and `/respond-to-critique`, and `bot-review-b.yml` keys its checkout, skip-check marker-pattern, and `/review-the-review` invocation off `github.event.review.commit_id` (the commit Reviewer A's review was attached to, immune to head drift from concurrent pushes). The prompts emit the marker from that argument instead of re-deriving it — the Reviewer A/B Bash allowlist is `gh` + read-only `git` (no `echo`/`printenv`), so a step-level env var would be unreadable by the model and the SHA must travel in the prompt text, the same channel the PR number already uses. A structural spec, `vendor/wheels/tests/specs/cli/BotReviewMarkerShaThreadingSpec.cfc`, guards the wiring across both workflow YAMLs and all three prompts (#2848)
- wheels-bot's convergence/deadlock loop now emits its idempotency markers from a workflow-captured head SHA, closing the same stale-SHA race fixed for Reviewer A/B (#2848) in the two commands that were out of scope there because they fire on the convergence/deadlock trigger path rather than the `pull_request` / review-submitted paths. `/address-review` (the consensus implementer) and `/advise-on-deadlock` (the senior advisor) previously re-derived the marker SHA via `gh pr view --json headRefOid`, which floats to the PR's current head when a push lands between the workflow's checkout and the model's call — so the emitted `wheels-bot:address-review:<pr>:<sha>`, `wheels-bot:advisor:<pr>:<sha>`, and `converged-approve`/`converged-changes` markers could lag the commit actually being addressed, defeating the per-SHA idempotency gate. `bot-advisor.yml` now threads its already-resolved `steps.pr.outputs.sha` into `/advise-on-deadlock`; `bot-address-review.yml` gains an equivalent resolve step that captures `headRefOid` alongside the head ref it already needed for the branch checkout and threads `steps.pr.outputs.sha` into `/address-review` (its checkout stays branch-name-keyed because that stage commits and pushes back, so the captured SHA is the head at run start — the marker's `<sha-before>`). Both prompts take an explicit `<head-sha>` argument and emit every marker from it; as with #2848 the prohibition is scoped narrowly to "don't re-derive the SHA" — `gh pr view` remains the normal way to read comments, reviews, and the diff, because a blanket ban made Reviewer A flood permission denials and post nothing. A structural spec, `vendor/wheels/tests/specs/cli/BotConvergenceMarkerShaThreadingSpec.cfc`, guards the wiring across both workflow YAMLs and both prompts (#2848)
- `wheels new <app> --no-sqlite`, `wheels generate admin <Model> --no-routes`, `wheels test --no-test-db` and every other `--no-*` flag the CLI documents now reach their command-level parsers again. LuCLI normalizes `--no-key` on the command line to `key=false` in the arg collection it hands modules, and `Module.cfc::argsFromCollection()` was silently dropping `false` entries — so the literal-token matchers in `new()`, `g admin`, and `test()` never saw the user's negation and the defaults stuck (SQLite still scaffolded, routes still generated, test DB still applied). The rebuild now re-emits `--no-<key>` for `false` values, so all four `--no-*` flags surface to the command handlers unchanged. `--nosqlite` (no hyphen) was never affected because LuCLI does not strip a leading `no` that lacks the hyphen. Spotted in #2855 after the prior `--no-sqlite` plumbing fix in #2624.
- `wheels new <name>` no longer crashes on a fresh Windows (Scoop) install with `lucee.runtime.exp.NativeException: there is no Resource provider available with the name [c]` before any module output appears. LuCLI hands `Module.init()` a `cwd` of the JVM's `user.dir` (e.g. `C:\Users\cy`, backslashes), and the early scaffold path concatenated `cwd & "/" & appName` into a mixed-slash string like `C:\Users\cy/blog`. Lucee 7's `ResourceUtil` runs a URI scheme-detection regex (`^[a-zA-Z][a-zA-Z0-9+.-]*:`) ahead of its Windows drive-letter special case on this code path, matches `c:`, extracts `c` as a resource-provider scheme, finds none (only `ftp` / `zip` / `tar` / `tgz` / `http` / `https` / `ram` / `s3`), and throws — pure-backslash and pure-forward-slash paths both work, only the mixed form fails. A new `$normalizePath()` replaces backslashes with forward slashes on `variables.cwd` in `init()` and on every `java.io.File.getCanonicalPath()` result in `resolveProjectRoot()` / `resolveFrameworkSource()`, so `C:/Users/cy/blog` matches Lucee's Windows-path detection before the URI regex ever runs; a `$safeDirExists()` wrapper adds a `java.io.File.isDirectory()` fallback for any path that still reaches a `directoryExists()` check with a drive-letter prefix (a user-supplied `WHEELS_FRAMEWORK_PATH`, a CFML mapping). Both no-op on macOS/Linux, where paths carry no `<letter>:` prefix. Latent since the Scoop install first shipped, but masked until the `-Dlucli.binary.name=wheels` routing fix (`wheels-dev/scoop-wheels@30ea6e5`) let `wheels new` actually reach this code (#2835)
- Running the `wheels` CLI with no arguments no longer errors out with `Component [modules.wheels.Module] has no function with name [main]`. LuCLI dispatches a bare `wheels` invocation to a `main()` subcommand on the module; previously `cli/lucli/Module.cfc` only defined `showHelp()`, so picocli's routing surfaced the missing-method exception. `Module.cfc` now defines `main()` as a thin delegate to `showHelp()` (and the function is added to `mcpHiddenTools()` so it doesn't appear as an MCP tool), restoring the expected behavior of printing the help banner when no subcommand is supplied (#2840)
- `wheels new` no longer commits a reload-password secret to source control. The scaffold hard-coded the generated random password as a literal in `config/settings.cfm` (a tracked file) and repeated it in a comment, and wrote it to `.env` as `RELOAD_PASSWORD` while the deployment guides and the `wheels deploy` secrets contract used `WHEELS_RELOAD_PASSWORD` — so pasting the documented `env()` snippet into a fresh app silently resolved to `""` and tripped the "reloadPassword is empty" boot warning. Generated `config/settings.cfm` (and both `app/snippets/*.txt`) now read `set(reloadPassword=env("WHEELS_RELOAD_PASSWORD", ""))`, so the random value the generator creates lives only in the git-ignored `.env`; the scaffold `.env` and the `examples/starter-app` reference now emit `WHEELS_RELOAD_PASSWORD` (the starter-app previously committed a guessable `reloadPassword="changeme"`). The CLI's `detectReloadPassword()` accepts both the prefixed and legacy unprefixed key, so apps generated before the rename keep working, and the configuration + deployment guides are reconciled on the bare `env()` accessor and the `WHEELS_RELOAD_PASSWORD` name (replacing an insecure docker example that used `Server.System.getEnv("RELOAD_PASSWORD") ?: "changeme"`). The scaffolded `lucee.json` also stops embedding the literal — its Lucee Server Admin password reads `#env:WHEELS_LUCEE_ADMIN_PASSWORD#` (a distinct generated secret written to `.env`, separate from the reload password), which LuCLI resolves from `.env` at server start via its native `#env:VAR#` interpolation, so no committed file carries it. **Heads-up for existing apps:** the CFML `env()` lookup is exact-match (only the CLI carries the back-compat alias), so if you adopt the new `config/settings.cfm` form or a guide snippet, rename your `.env` key from `RELOAD_PASSWORD` to `WHEELS_RELOAD_PASSWORD` (#2857)
- Auto-derived model property names now preserve the database's reported column casing again, instead of being force-lowercased on every engine. When a model declares no `property()` mappings, Wheels infers its properties from the database column metadata; a change in the 3.0 line (`Model.cfc`, intended to normalize Oracle's fixed-case identifiers) began calling `lCase()` on every derived property name unconditionally, so an `isHidden` column surfaced as the property `ishidden` on SQL Server, MySQL, SQLite, etc. — silently breaking case-sensitive consumers of serialized model output (`returnAs="structs"`, `renderWith()`, `serializeJSON()`) for anyone upgrading from CFWheels 2.x (the same code preserved case in 2.5 on the same engine + database). Casing is now preserved by default and only lowercased on adapters whose database folds unquoted identifiers to a non-meaningful UPPERCASE default, gated by a new `$lowerCaseColumnNames()` capability on the database adapter (`Base` default `false`; `OracleModel` and `H2Model` override to `true`). So SQL Server / MySQL / SQLite preserve the declared case, PostgreSQL / CockroachDB use the database's own lowercase-folded name, and Oracle / H2 keep the lowercased behavior they have today. Models that explicitly declare `property(name="isHidden", column="isHidden")` were always unaffected and remain so. **Reverse-migration heads-up:** apps that adopted Wheels 3.x/4.x and adapted to the force-lowercased property names — e.g. JSON consumers, view templates, or client-side code that expects `{"ishidden": 1}` — will see that output revert to the originally declared casing (`{"isHidden": 1}`) after applying this patch on SQL Server / MySQL / SQLite. Review any serialized model output consumers before upgrading (#2852)
- The Debian/Ubuntu `apt` install instructions now pipe the distribution key through `sudo gpg --dearmor` before writing `/usr/share/keyrings/wheels.gpg` instead of `tee`-ing it verbatim. The key published at `apt.wheels.dev/wheels.gpg` is ASCII-armored, and modern `apt` rejects an armored key in a `signed-by=` keyring with an "unsupported filetype" warning followed by `NO_PUBKEY` — so `apt update` failed signature verification and the install never worked. Corrected across the install guide, the CLI installation reference, the release-channels guide, the `apt.wheels.dev` landing page, and the `tools/distribution-drafts/` repo templates (#2838)
- The `apt.wheels.dev` publishing template (`tools/distribution-drafts/apt-repo/`) no longer wipes the `stable` package index when a `bleeding-edge` snapshot publishes. `regenerate-apt-metadata.sh` rebuilt *both* channels on every run while the workflow synced only the dispatched channel's pool into the runner, so a frequent bleeding-edge publish scanned an empty local `pool/stable/`, produced an empty `Packages`, and the unscoped upload overwrote the good stable index on R2 — leaving `apt install wheels` with "Unable to locate package wheels" even though the `.deb` was present in the pool. The regen now honors a `CHANNELS` env (the workflow passes only the dispatched channel) and the upload is scoped to that channel's `dists/` subtree, so the two channels can no longer clobber each other (#2838)
- The Wheels CLI test suite (`cli/lucli/tests/specs`, served at `/wheels/cli/tests`) is green again after the BDDRunner error-count fix unmasked 13 pre-existing failures the old `-1` bundle-error sentinel had been arithmetically cancelling (a negative error total netted real failures down to `<= 0`, so the CI gate read the suite as passing). The eight `*CommandSpec` bundles that instantiate `new cli.lucli.Module()` no longer fail to load with `can't find component [modules.BaseModule]`: a lightweight `BaseModule` test double under `cli/lucli/tests/_modules/` plus a `/modules` mapping (added alongside the existing `/modules/wheels`, which longest-prefix resolution keeps authoritative for the wheels module) lets `Module.cfc` instantiate under TestBox — resurrecting the Db/Info command specs as real behavioral coverage. The stale `AdminSpec` route assertion now expects `.namespace("admin")` (the service's current named-route-prefixed output) instead of the legacy `.scope(path="admin")`. Command specs that need the LuCLI runtime, a running Wheels server, CodeGen harness fixtures, or the CLI bash wrapper (Deploy/Destroy/Generate/Packages, plus the server-dependent Migrate/Test cases) and the unbuilt-feature specs (Doctor #2260 mixin-detail, Scaffold route-model-binding) are `xdescribe`/`xit`-skipped with documented reasons, pending a command-by-command CLI test audit. Finally, `tools/ci/run-tests.sh` now clamps a negative error count for its pass/fail decision and fails explicitly when it sees one, so this masking class of bug can never silently turn a red suite green again (#2829)
- WheelsTest BDD runner now captures spec-load and bundle-execution errors against the offending bundle instead of bubbling out as an anonymous `BundleRunnerMajorException`, and reports the resulting error count as a positive number (was the `-1` sentinel) so summaries read "1 error(s)" with the bundle path and `globalException` populated — covers both `it()` called outside a `describe()` body and a `beforeAll()` that throws during spec load (#2829)
- `application.wheels.protectedControllerMethods` is now populated at application start from the public method surface of `wheels.Global` plus the `wheels.controller.*` and `wheels.view.*` mixin components, so framework helpers like `env()`, `model()`, `findAll()`, `redirectTo()`, and `linkTo()` can no longer be invoked as controller actions from a URL. The list was previously initialized to an empty string (the orphaned `local.allowedGlobalMethods = "get,set,mapper"` line in `onapplicationstart.cfc` pointed to the intent but never wired it up), so `$callAction()`'s allow-list check was a no-op. Any unauthenticated `GET /<anyController>/env` request reached the global `env()` helper directly and raised `"The parameter [name] to function [env] is required but was not passed in."` as a 500; other helper names dispatched into unintended code paths. Derived from `getMetaData().functions` on each source component (excluding `$`-prefixed internal methods, which are already gated separately), so the list stays in sync with the framework's mixin surface automatically. Reaching one of these names now throws `Wheels.ActionNotAllowed` and falls through to the missing-action / 404 path, matching every other non-existent action. **Migration note:** applications that defined controller actions with the same name as a public framework helper (e.g. `env`, `model`, `redirectTo`) will need to rename those actions — they now return 404 rather than dispatching, since the protection gate at `processing.cfc:132` fires before the `StructKeyExists(this, action)` lookup that would otherwise reach a same-named user action (#2844)

----

# [4.0.2](https://github.com/wheels-dev/wheels/releases/tag/v4.0.2) => 2026-05-27

> **Wheels 4.0.2** — second patch on the 4.0 line. Adds shared-development-database migrator reconciliation (`wheels migrate doctor` / `forget` / `pretend`, orphan-version auto-detection, and `name` / `applied_at` enrichment of the `wheels_migrator_versions` tracking table) plus `columnNames` aliases across `t.references()`, `t.primaryKey()`, and the `Migration.cfc` command helpers; ships native GPG-signed Linux package repositories at `apt.wheels.dev` and `yum.wheels.dev` (Cloudflare R2); resolves `BrowserTest` base URLs through a layered instance-time lookup; and greens the compatibility matrix across BoxLang and Adobe ColdFusion 2023/2025. ~30 PRs since the 4.0.1 GA (2026-05-20).

### Added

- Native Linux package repositories are now live at `apt.wheels.dev` and `yum.wheels.dev`, GPG-signed and served from Cloudflare R2. Debian/Ubuntu installs fetch the key with `curl -fsSL https://apt.wheels.dev/wheels.gpg | sudo tee /usr/share/keyrings/wheels.gpg` (later corrected in #2846 — pipe through `gpg --dearmor` instead of `tee`), add a `deb [signed-by=/usr/share/keyrings/wheels.gpg] https://apt.wheels.dev stable main` source, then `sudo apt install wheels`; Fedora/RHEL installs add the repo via `dnf config-manager --add-repo https://yum.wheels.dev/wheels.repo` then `dnf install wheels`, and upgrades collapse to a single `apt upgrade wheels` / `dnf upgrade wheels` with no version pinning. The buckets are backed by R2 rather than Cloudflare Pages because the `.deb` (80 MB) and `.rpm` (81 MB) artifacts exceed Pages' 25 MiB per-file limit, while R2 has no object-size limit and still supports custom-domain serving. The install and release-channel guides now lead with the native sources, keeping the one-off GitHub-Release download behind an aside for air-gapped use (#2814)
- `t.primaryKey()` in the migrator now accepts `columnName` and `columnNames` as aliases for the legacy `name` parameter, matching the argument-naming convention of every other column helper in `TableDefinition.cfc`. The legacy `name=` form keeps working (it's still what `init()` passes when adding the conventional `id` primary key). Plural `columnNames` wins when both aliases are supplied, mirroring `addReference()` / `dropReference()` precedence semantics. Unlike sibling helpers, `columnNames` here does NOT accept a comma-separated list — `primaryKey()` always creates one PK column, so `columnNames="a,b"` produces a single column literally named `a,b`; call `t.primaryKey()` multiple times for composite PKs (#2812)
- `t.references()` in the migrator now accepts `columnNames` as an alias for the legacy `referenceNames` argument, matching every sibling column helper (`t.string`, `t.integer`, …) that uses `$combineArguments` to take both the plural and singular forms. The new `useUnderscoreReferenceColumns` setting (boolean, framework default `false`, `wheels new` template default `true`) controls whether `t.references(columnNames="user")` produces `user_id` (matching Wheels model `belongsTo` defaults) or the legacy `userid` (no underscore) suffix; polymorphic references follow the same flag for the `<name>_type` / `<name>type` column. `Migration.cfc::addReference()` and `removeColumn(referenceName=)` respect the flag too. Existing apps keep working unchanged since the framework default is `false`; only new apps generated by `wheels new` opt into the underscore form (#2802)
- The command-version migrator helpers in `Migration.cfc` now accept the same plural/singular column-name aliases as the `TableDefinition` helpers fixed in #2802, via `$combineArguments`: `addColumn` / `changeColumn` / `removeColumn` take `columnNames` as an alias for `columnName`, `addReference` / `dropReference` take `columnName` / `columnNames` as aliases for `referenceName`, and `addForeignKey` takes `columnName` as an alias for `column`. Legacy parameter names keep working. Two hard-coded `& "id"` concatenations (in `removeColumn` and `addReference`) now route through `useUnderscoreReferenceColumns`, so an app that opted into the underscore convention and created `user_id` via `t.references()` can also drop or constrain that column through the command-version helpers. `changeColumn`'s original required-argument enforcement is preserved for non-reference column types via a conditional `required` on `$combineArguments` (#2804)
- Two new advisory checks in `wheels upgrade check`: a `t.references()` opt-in suggestion (fires when an app uses `t.references(` in migrations without `set(useUnderscoreReferenceColumns=true)`) and a mixed-convention warning (fires when the flag is set so users audit legacy migrations for `<name>id` columns that pre-date the opt-in). Both surface in the "Recommended Improvements" section introduced by the upgrade-tier scaffolding — advisory severity, never gates CI. The opt-in advisory is suppressed when the flag is already set in `config/settings.cfm` to avoid contradicting the mixed-convention warning. The shared grep loop now strips CFML comments before pattern matching (Anti-Pattern #14), so commented-out code can't trip any check — a framework-wide improvement that benefits every existing breaking-change check too (#2807)
- Three new `wheels migrate` subcommands for manual reconciliation against the tracking table — Flyway `validate` / `repair` / `SkipExecutingMigrations` analogues. `wheels migrate doctor` prints a single-command health report covering applied/pending/orphan versions plus a human-readable summary; pure read, never mutates. `wheels migrate forget <version> --yes` removes a single orphan row from `wheels_migrator_versions` (refuses if a matching local file exists — use `migrate down` for legitimate rollbacks — and refuses if the version isn't in the table). `wheels migrate pretend <version> --yes` records a version as applied without running its `up()` (refuses if already applied or if no local file matches, so future `down()` calls still work). Both `forget` and `pretend` require explicit `--yes` to mutate; without it they print what would happen and exit. Implementation lives in `Migrator.cfc::doctor()`, `forgetVersion()`, `pretendVersion()`. Covers the shared-dev-DB pattern surfaced in #2780 beyond what the orphan auto-detection in #2798 could resolve automatically (#2799)

### Changed

- `wheels upgrade check` output now distinguishes opt-in recommendations from breaking changes. Each check struct in `cli/lucli/Module.cfc::runUpgradeCheck()` accepts a new optional `severity` field (default `"breaking"`, the existing behavior); matches with `severity: "advisory"` bucket into a separate `Recommended Improvements (N found):` section that renders alongside `Breaking Changes (N found):` and `All Clear (N checks):`. The same-major short-circuit was also removed so advisories can fire on point-release upgrades — the "no known breaking changes" message still prints, but execution continues into the checks loop. Scaffolding-only; advisory-annotated entries land in a follow-up PR (#2805)
- `wheels_migrator_versions` gains two additive nullable columns: `name VARCHAR(255)` (the migration's human-readable name, e.g. `create_users`) and `applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP` (when the migration was applied). Added automatically on the first migrator call after upgrade via the new `Migrator.$ensureTrackingColumns()` helper — idempotent, gated by `application[appKey].$trackingColumnsEnsured` so the ALTER runs once per app process, and non-fatal (legacy schema continues to work if the ALTER fails). Newly applied migrations populate both columns; existing rows pre-dating the enrichment stay NULL. `wheels migrate info` and `wheels migrate doctor` now show `[?] <version> <name> (applied <timestamp>)` for orphan rows when the columns are populated, instead of just the literal `********** NO FILE **********` — letting you see *what* a peer applied and *when* even though the file isn't in your branch yet. SQLite skips the column DEFAULT (not supported on existing-table ADD COLUMN) and gets explicit timestamps from CFML on insert. Per-engine SQL covers MySQL, PostgreSQL, SQLite, MSSQL, Oracle, H2, and CockroachDB (#2800)

### Fixed

- The Wheels Compatibility Matrix is green again for BoxLang and Adobe CF 2023/2025 ahead of the v4.0.2 cut. **BoxLang** (17 fail / 72 error on every database) traced to a single root cause: `Global.cfc`'s pseudo-constructor seeded `local.varKey = ""` for its include-injected-UDF promotion loop, and BoxLang materializes that as `variables.local`, which then shadows the function-local `local` scope of every mixed-in `$`-helper — so `Migrator`/`Model` calls like `local.appKey = $appKey()` resolved against `{varKey}` and threw `KeyNotFoundException: The key [APPKEY] was not found in the struct. Valid keys are ([VARKEY])`. Lucee/Adobe keep `local` reserved to the function scope so they never saw it; the loop now lives in a real function (`$promoteIncludedGlobalsToThis()`). **Adobe CF 2023/2025** were crashing the whole suite (HTTP 404 + ~1MB HTML prefix corrupting the result JSON) because `InvokeMethodSpec` invoked `Public.index()`, rendering the congratulations welcome page into the test-runner response buffer, which Adobe commits mid-run — now captured with `cfsavecontent`. Five further Adobe-specific bugs: `RequestId` middleware wrote `request.wheels.requestId` through a `request` parameter that shadows the scope on Adobe (Anti-Pattern #11, now a `request`-less helper); `TestClient` emitted a `cfhttp` POST with no `cfhttpparam` for empty bodies (Adobe requires at least one); `ParallelRunner.$collectFailures` relied on array-by-reference mutation that Adobe passes by value (returns the array now); `$reincludeGlobals` re-`include`d an already-bound file, tripping "Routines cannot be declared more than once" (now evaluated in a throwaway `GlobalIncludeLoader`); `RewriteConfigInstallerSpec` compared file content to a literal string where Adobe 2025's `fileWrite`/`fileRead` round-trip appends a newline (compares to a normalized baseline now); and `OuterTransactionSignalSpec`'s cleanup `queryExecute` bound the row id as `cf_sql_integer`, which overflows on Adobe when CockroachDB's default `unique_rowid()` PK returns a ~60-bit value (`cf_sql_bigint` now). Verified on the full matrix CI across all engines × databases (#2817)
- `model().create()` / `.update()` / `.deleteAll()` inside a migration's `up()` or `down()` no longer silently roll back. The Migrator wraps every `up()` / `down()` invocation in its own outer `cftransaction`, and Wheels Model's default `transaction="commit"` opened a nested `cftransaction` whose JDBC nested-transaction semantics differ per adapter — most acutely on MSSQL, where the inner commit didn't release the row and the eventual outer commit dropped it, leaving the user with orphan FK rows referencing IDs that never persisted. `Migrator.cfc` now sets `request.$wheelsTransactionWrapper = true` around each `up()` / `down()` / `migrateIndividual()` invocation and `Model::invokeWithTransaction()` reads that signal, treating the call as `alreadyopen` and skipping the nested `cftransaction` entirely. The flag is request-scope and cleared in both the success and error paths of every migrator code path, so it never leaks past the migration's outer transaction (#2810)
- `migrateIndividual()` no longer issues a spurious `transaction action="commit"` on the error path after its `catch` block has already issued `transaction action="rollback"`. Unlike `migrateTo()`'s loops there was no enclosing `for` to `break` out of, so control always fell through to the commit; the fix `return`s from inside the `catch` after the rollback, mirroring `migrateTo()`'s early-exit. On Lucee the second action against a closed transaction is a silent no-op, but on Adobe CF 2023/2025 (and potentially BoxLang) the JDBC driver could throw a "transaction not active" error that masked the real migration failure. Follow-up to #2810 (#2813)
- `wheels upgrade check` underscore-references opt-in advisory no longer contradicts the mixed-convention warning when `set(useUnderscoreReferenceColumns=true)` lives in an environment override file (e.g. `config/production/settings.cfm`) rather than the root `config/settings.cfm`. The pre-check guard in `cli/lucli/Module.cfc::runUpgradeCheck()` now walks all of `config/` recursively (matching advisory #2's `scanDir: "config"` scope) instead of reading only `config/settings.cfm`, so the opt-in advisory is suppressed whenever the flag is set anywhere in the config tree. Comment-stripping still runs per file so a commented-out `set(useUnderscoreReferenceColumns=true);` cannot satisfy the guard (Anti-Pattern #14) (#2809)
- `wheels migrate latest` no longer takes a misleading "down" branch and silently no-ops when `wheels_migrator_versions` records a version whose migration file isn't in the current checkout (shared dev DB / peer migration not yet pulled). `Migrator.migrateTo()` now diffs the tracking table against `app/migrator/migrations/` via the new `$getOrphanVersions()` helper and branches on orphan-at-top before the existing direction check — applying pending local migrations with a clear warning when all DB versions above target are orphans, emitting "Nothing to do" naming target vs current when none are pending, and warning + letting the existing down loop continue in mixed cases (orphan rows skip naturally because the loop iterates files). `wheels migrate info` also now shows orphan rows with `[?] <version> ********** NO FILE **********` (Rails-style) and a footer explaining the cause (#2798)
- `tools/test-local.sh` silently aborted with `EXIT=1` (no `/tmp/wheels-test-server.log` written, no diagnostic printed) on every install since the `lucli` → `wheels` rebrand window closed — i.e. anyone whose `~/.lucli/express/` directory never existed. Line 81 ran `LUCEE_LIB=$(find ~/.wheels/express ~/.lucli/express -path "*/lib/ext" -type d 2>/dev/null | head -1)` under `set -euo pipefail`; `find` exits non-zero whenever any path argument doesn't exist (stderr suppressed via `2>/dev/null`, but the exit status survives), `pipefail` propagated it through `head -1`, and the assignment tripped `set -e`. The cleanup trap then fired with no server to clean up, leaving the user staring at "Starting Wheels CLI server on port 8080…" with no further output. Dropped the now-dead `~/.lucli/express` fallback (the rename landed in 3.0 and recent CLI releases extract Lucee Express to `~/.wheels/express/` only) and added `|| true` for defense in depth so a missing directory (e.g. a truly fresh install before `wheels start` has ever run) leaves `LUCEE_LIB` empty and the downstream `[ -n "$LUCEE_LIB" ]` guard skips the JDBC pre-install cleanly (#2796)
- Routes registered inside `.namespace("foo")` (or equivalent `.scope()` / `.package()`) with a redundant namespace prefix in the controller path — e.g. `to="foo/dashboard##index"` instead of `to="dashboard##index"` — previously silently produced a `foo.foo/dashboard` lookup that downstream flattened to a `Foodashboard`-style class name with an opaque `Wheels.ViewNotFound` error. The Mapper now rejects this at route-registration time with `Wheels.MapperArgumentInvalid`, naming the namespace and the offending value and pointing at the correct shorter form, so users can find the bad route definition instead of chasing the symptom (#2794)
- `WheelsTest` auto-bind missed user-defined global helpers added via `include` in `app/global/functions.cfm`. The pseudo-constructor used `getMetaData(application.wo).functions`, which only enumerates methods declared directly on the CFC and skips symbols merged in via `cfinclude`. Specs that called custom helpers (e.g. `can()`, `hasRole()`) had to manually rebind each one in `beforeAll()`. The auto-bind now iterates `application.wo` as a struct and binds every UDF via `isCustomFunction()`, preserving the existing public-only filter for declared methods (#2793)
- Model layer SELECT clause builder now routes column identifiers through the adapter's `$quoteIdentifier`, so reserved-word column names (e.g. `key`, `order`, `group`) survive on every supported dialect instead of breaking `findAll` / `findOne` / dynamic finders with cryptic SQL syntax errors. The WHERE / ORDER BY paths already quoted columns; `$createSQLFieldList` and the empty-pagination column-list extraction in `read.cfc` now match (#2787)
- `wheels packages install <name>` is now a transparent alias for `wheels packages add <name>` on every caller path that actually reaches `Module.cfc` (stdio MCP server, scripted in-process clients, spec suite). Previously the dispatch layer's `case "install":` branch printed a yellow warning to stdout and returned `""` without installing anything — so even though `PackagesMainCli.install()` itself had been a true alias for `add()` since #2729, any caller routing through the CLI module's verb dispatch silently no-op'd. The shell-facing `wheels packages install <name>` form is still intercepted by LuCLI's built-in extension installer upstream of module dispatch and remains broken on that path (and is documented as such in the module-owned help text), but MCP tool calls and programmatic callers now behave identically to `add`. Both branches now share a single fall-through body so the validation, error shape, and install behavior cannot drift apart again (#2786)
- `wheels.wheelstest.BrowserTest` now throws a clear `Wheels.BrowserTest.NotWired` error — naming `browserDescribe()` as the fix — when a spec calls a DSL method on `this.browser` from a plain `describe()` block. Previously the uninitialized `this.browser` was an empty string, producing the misleading `function [visitUrl] does not exist in the String` on every newcomer's first BrowserTest spec. A sentinel `UnwiredBrowserGuard` is now installed at `this.browser` before `browserDescribe()` wires the real `BrowserClient` and after `$endBrowserContext()` tears it down (#2782)
- `BrowserTest`'s default base URL is no longer hardcoded to `http://localhost:8080`. `$resolveBaseUrl()` now consults a layered lookup at instance time: `this.baseUrl` (per-spec override, set in the component pseudo-constructor) → `get("browserTestBaseUrl")` (Wheels setting) → `-Dwheels.browserTest.baseUrl=...` (JVM system property) → `WHEELS_BROWSER_TEST_BASE_URL` env var → `cgi.server_name`/`cgi.server_port` auto-detect → `http://localhost:8080` default. Specs running against a non-8080 server (Titan on 60050, `wheels new` scaffolds on 60080) can set `this.baseUrl` in the pseudo-constructor or rely on the CGI auto-detect instead of comparing `getBaseUrl()` against a sentinel string. The bare-env-var approach still works for CI but is no longer the only escape hatch (the JVM caches env vars at process start, so post-launch `export` had no effect). Regression spec at `vendor/wheels/tests/specs/wheelstest/BrowserTestBaseUrlResolutionSpec.cfc` (#2783)
- Linux `.deb` / `.rpm` packages double-nested the framework at `/opt/wheels/module/vendor/wheels/wheels/` instead of `/opt/wheels/module/vendor/wheels/`. `wheels-core-VER.zip` carries a top-level `wheels/` directory that `unzip` preserves; the nfpm `type: tree` rule then copied the entire `build/framework/` tree (wrapper and all) into the destination, leaving `Injector.cfc` one level too deep. Every fresh `wheels new` install on Ubuntu/Fedora then crashed on first request with `could not find component or class with name [wheels.Injector]`, cascading into the cryptic `The key [WO] does not exist.` error in `onError`. The brew formula handles this correctly via `(share/"wheels/framework/wheels").install Dir["*"]`; the Linux nfpm configs now pin `src` at `./build/framework/wheels/` to match. Regression spec at `vendor/wheels/tests/specs/cli/LinuxPackageStagingSpec.cfc` (#2776)
- `onError` in the generated app template and demo `public/Application.cfc` now guards `application.wo` with `StructKeyExists(application, "wo")` after the recovery try/catch. When `new wheels.Injector(...)` fails during `onApplicationStart` (e.g. a stale `/wheels` mapping under Lucee Express 7), the original error is preserved via a minimal HTML fallback instead of cascading into the cryptic "The key [WO] does not exist" exception that hit "Your First 15 Minutes" tutorial users on fresh installs (#2774)
- Bare `?reload=true` now auto-detects changes to `app/global/*.cfm` in development and re-evaluates `app/global/functions.cfm` (plus any files it `<cfinclude>`s) when any tracked file's mtime has changed, so new helpers added to `app/global/functions.cfm` (or any file it includes) are picked up without the password-gated `applicationStop()` path. Wheels snapshots the include directory on application start and re-evaluates the include via a new `application.wo.$reincludeGlobals()` hook when `$globalIncludesChanged()` detects an added/removed/touched file. Opt out with `set(reloadOnGlobalChange=false)` in `config/settings.cfm` (#2795)
- The documented Linux bleeding-edge install commands in the guides 404'd after #2759 renamed the snapshot artifacts from `wheels_*` to `wheels-be_*` (deb) / `wheels-be-*` (rpm) to differentiate the channel by package name. All six affected pages — three unique (`start-here/installing`, `start-here/release-channels`, `command-line-tools/installation`) mirrored across the v4-0-0 and v4-0-1-snapshot doc versions — now point at the correct `wheels-be_*` assets, and the "switching channels" snippets reflect the real `Conflicts: wheels` package metadata instead of assuming same-package-name `--allow-downgrades` / `dnf downgrade` transitions (#2777)
- Stale `schema_migrations` table-name references in the v4 migration and seeding guides (`v4-0-0/basics/seeding`, `v4-0-1-snapshot/basics/migrations`, `v4-0-1-snapshot/basics/seeding`) now read `wheels_migrator_versions`, matching the on-disk table name since the `c_o_r_e_*` → `wheels_*` rename — no `schema_migrations` table exists anywhere in `vendor/wheels/`, `cli/`, or `app/`. Carryover from #2799 (#2801)

---

# [4.0.1](https://github.com/wheels-dev/wheels/releases/tag/v4.0.1) => 2026-05-20

> **Wheels 4.0.1** — first patch on the 4.0 line. Hardens Adobe ColdFusion 2023/2025 compatibility (Adobe-specific `cfheader` attributeCollection rejection, `env()` reserved-word parameter, Vite asset-walk array-by-value), fixes the Windows Scoop install regressions (`wheels.cmd` cmd.exe pre-parser, `.zip.sha512` sidecar layout), and adds `viewStyle` framework presets to `paginationNav()` plus plural `mappings` aliases to `package.json`. ~100 PRs since the 4.0.0 GA (2026-05-12).

### Added

- `paginationNav()` and `pageNumberLinks()` now accept a `viewStyle` argument with named CSS-framework presets (`"plain"`, `"bootstrap5"`, `"bootstrap4"`, `"tailwind"`). Bootstrap presets emit the canonical `<nav><ul class="pagination"><li class="page-item active" aria-current="page"><span class="page-link">N</span></li>` structure — with the active class on the `<li>` wrapper and a `<span>` (not anchor) for the current page — so Bootstrap-styled apps no longer need a `Replace()` regex hack to move the active class off the anchor. `viewStyle` defaults to `"plain"`, preserving today's output byte-for-byte (#2718)
- Docs: added "Reading the Changelog" guide page under the Upgrading section explaining where `CHANGELOG.md` lives (repo root, not inside `vendor/wheels/`), how to look up PR references cited in upgrade guides, and how to access the changelog offline when working with a vendored copy of the framework (#2719)
- Document CORS allow-list defaults drift when migrating from 3.x `set(accessControlAllow*)` global settings to `wheels.middleware.Cors`; add header comparison table, explicit-constructor-args fix, and common-issues entry to the 3.x→4.x upgrade guide and a migration callout to the CORS reference page (#2708)
- `PackageLoader` now derives a per-package CFML mapping from `package.json` and reflects it into `application.mappings`, so CFCs inside a hyphenated package (e.g. `vendor/wheels-sentry/`) can reference siblings via a static identifier (`new wheelsSentry.SentryClient()`) instead of `CreateObject("component", "vendor.wheels-sentry.SentryClient")`. The alias defaults to lower-camel-case of the manifest `name` (`wheels-sentry` → `wheelsSentry`, `wheels_legacy_adapter` → `wheelsLegacyAdapter`) and is overridable via a `mapping` field in `package.json`. Two packages computing the same alias are caught at load time — the first claimant keeps the mapping and the second is recorded in `getFailedPackages()` so the conflict is visible. Exposed via `PackageLoader.getPackageMappings()` (#2712)
- `wheels deploy init` now scaffolds a starter `Dockerfile` (Lucee 7 + Java 21 multi-stage, `/up` HEALTHCHECK aligned with the generated `kamal-proxy` healthcheck) and a `.dockerignore` alongside `config/deploy.yml` and `.kamal/secrets`. `--force` also gates the `Dockerfile` — an existing user-authored Dockerfile aborts the init without `--force`, while an existing `.dockerignore` is silently preserved (since it's commonly user-curated even before adopting `wheels deploy`). The npm builder stage works for any Wheels app — projects without a JS pipeline pass through unchanged; projects with a `package.json` install + build automatically. Secrets (reload password, DB password, registry password) are injected at deploy time via `.kamal/secrets`, never baked into the image (#2673)
- `package.json` now also accepts a `mappings` struct (plural) so a package can register additional dotted CFML mapping aliases beyond the singular `mapping` identifier. Keys are dotted names (e.g. `plugins.sentry`); values are paths relative to the package directory (`"."` for the root, `"sub"` for a subdirectory). Lets a package keep legacy callsites like `new plugins.sentry.SentryClient()` resolving when it's installed at `vendor/wheels-sentry/` instead of `plugins/sentry/`. Each dotted segment must match `[A-Za-z_][A-Za-z0-9_]*`; absolute paths and `..` traversal are rejected. Collisions with any existing alias (singular or plural, same or different package) fail the package and unwind its singular registration so the mapping registries stay internally consistent (#2739)

### Changed

- `lockingSpec` now consults the new `$supportsAdvisoryLocks()` model adapter capability and skips the `withAdvisoryLock` describe block via `beforeEach { skip(...) }` instead of erroring on adapters that don't support standalone advisory locks (H2, SQL Server, Oracle, CockroachDB). PostgreSQL, MySQL, and SQLite (no-op) report `true`; SQL Server reports `false` until its lock path grows an implicit-transaction wrapper. Compat-matrix can now distinguish "lock implementation broken" from "lock not applicable to this DB"
- Reconcile upgrade docs: blog skeleton now lists all eleven canonical breaking changes (matching the canonical upgrade guide), fixes the `wheels.Test` → `wheels.WheelsTest` test-base-class rename description (previously mislabeled as a "testbox namespace" move), and adds the previously-missing `application.wirebox` → `application.wheelsdi` and Vite manifest strictness entries; stats table "Breaking defaults hardened | 7" corrected to "Breaking changes | 11" with four detail-row delta labels updated from Changed/Renamed/New to Breaking (#2632)
- Compat-matrix CF-engine readiness probe now tracks the last observed HTTP status, surfaces partial progress every 10 attempts, and on timeout distinguishes "engine never bound" (HTTP 000) from "engine bound but returning 5xx" (e.g. issue #2646's `$blockInProduction` symptom) — printing the response body and a stack-frame-stripped log slice when the latter occurs. Previously a 5-minute timeout dumped `tail -50` of raw container logs, dominated by ~30 lines of undertow/runwar stack frames, hiding the actual root cause

### Fixed

- The Scoop `wheels.cmd` wrapper (both `wheels` and `wheels-be` channels) was failing on Windows 11 build 10.0.26200.8457 with `The filename, directory name, or volume label syntax is incorrect.` before LuCLI could run, due to two compounding bugs: (1) `call "%~dp0lucli-<ver>.bat" %*` made cmd.exe pre-parse the entire bat-jar concatenation (~915 KB of bat preamble + `:JAR_BOUNDARY` + raw JAR ZIP bytes) looking for labels, and the pre-parser tripped on byte sequences in the ZIP tail; (2) `JAVA_HOME=%~dp0share\jdk` pointed at a location Scoop's extraction didn't reliably produce — on at least one machine the inlined OpenJDK 21 zip landed at `%~dp0jdk-21.0.2` (the ZIP's root layout, as if `extract_to=share/jdk` were ignored) instead. The fix landed directly in the canonical bucket via wheels-dev/scoop-wheels#6: the wrapper now dispatches LuCLI via `"%JAVA_HOME%\bin\java.exe" -client -jar "%~dp0lucli-<ver>.bat" %*` (java reads the JAR via stream and skips the bat preamble, bypassing cmd's pre-parser entirely), and a one-line fallback `if not exist "%JAVA_HOME%\bin\java.exe" set "JAVA_HOME=%~dp0jdk-21.0.2"` handles the broken-extraction case. As part of the same cleanup, the stale Scoop manifest drafts at `tools/distribution-drafts/scoop/` (`build-manifests.py`, `validate.py`, `wheels.json`, `wheels-be.json`, and the local README), plus the regression spec at `vendor/wheels/tests/specs/cli/ScoopWrapperSpec.cfc` that pinned against those drafts, are removed — the live bucket has had its own self-hosted autoupdate workflow and an inline-JDK layout since scoop-wheels@3f22250 and the in-repo drafts had silently diverged on every meaningful axis (inline JDK vs. `depends:`, real hashes vs. placeholder zeros, autoupdate strategy, wrapper template). `tools/distribution-drafts/README.md` is updated to note that the scoop bucket is now canonical and no longer mirrored here. Closes #2765 (#2767)
- Release artifacts (`wheels-core`, `wheels-cli`, `wheels-base-template`, `wheels-starter-app`) now ship `*.zip.sha512` / `*.zip.md5` checksum sidecars (was `*.sha512` / `*.md5`) so the scoop-wheels `autoupdate` config — which expects the `.zip.sha512` shape via `$url.sha512` substitution — no longer 404s on every non-module artifact. `wheels-module` already used the correct shape; this brings the other four artifacts and both release workflows (`release.yml`, `release-candidate.yml`, plus the `snapshot.yml` reusable-workflow chain) into line. Closes the Windows install regression reported in #2758 + scoop-wheels#2 (#2761)
- Docs: Windows install steps in `start-here/installing.mdx` and `command-line-tools/installation.mdx` now call out `scoop bucket add java` as a prerequisite. Scoop's `depends:` declaration does not auto-add the dependency bucket on the user's behalf, so users hit `Couldn't find manifest for 'openjdk21' from 'java' bucket` before they could proceed (#2761)
- `$viteResolveAssets()` on Adobe CF 2023/2025 returned empty `preloads` and `styles` arrays when the manifest included transitive imports with CSS chunks. Root cause: Adobe CF copies arrays by value when they are passed directly from a struct literal — `$viteWalkImports(preloads = local.rv.preloads, styles = local.rv.styles, ...)` handed the walker independent copies on Adobe CF, so every `ArrayAppend(arguments.preloads, ...)` inside the recursion wrote to garbage and `local.rv` came back empty. Lucee and BoxLang share the array references, so the bug was Adobe-only. Fix: pass the parent `rv` struct and mutate `arguments.rv.preloads` / `arguments.rv.styles` — struct references are shared on every engine (Cross-Engine Invariant #6). Affects every helper that walks transitive imports: `viteScriptTag`, `viteStyleTag`, `vitePreloadTag`, and `$viteHtmlHead`. Existing viteSpec assertions on transitive-import walk, diamond-dependency dedup, and cyclic-import termination serve as the regression catch (#2756)
- `env("KEY")` and `env("KEY", "fallback")` now return the correct value on Adobe CF 2023/2025. The second parameter was named `default`, a CFML reserved word (switch/case/default), and Adobe CF refuses to bind a parameter with that name at all — neither the signature default nor a caller-supplied positional value populates `arguments.default`, so the function silently returned `""` for every call. Lucee and BoxLang bind it correctly, which is why the bug was Adobe-only and only surfaced once this PR's dispatch + test-runner layers (`$header()`, BaseReporter `reset()`, `runner.cfm` migration) stopped the `cfheader` cascade from masking the real test failures (`UndefinedElementException` on `env("KEY")` for `envHelperSpec.cfc:28`, then `Expected [custom_default] but received []` on `env("KEY", "custom_default")` for `envHelperSpec.cfc:33` once defensive access closed the first symptom). The fix renames the parameter to `defaultValue` — the only portable shape on Adobe — and the docstring is updated to match. Back-compat for the legacy named-arg form `env(name = "X", default = "Y")` is preserved by checking the `arguments` scope for the literal `default` key first: named arguments land in the arguments scope under their literal name regardless of the declared parameter list, so the legacy named-arg form still resolves correctly. Positional callers (the only shape in the framework's own specs and the documented usage pattern) are unaffected by the rename (#2756)
- `$content()` in `vendor/wheels/Global.cfc` and the bare `cfheader`/`cfcontent` calls in `vendor/wheels/tests/runner.cfm` now defer to the defensive `application.wo.$header()` / `application.wo.$content()` helpers so the test-runner response setup degrades gracefully when the response is already committed. After the BaseReporter `reset()` fix above let TestBox produce its JSON report, the runner's post-test `cfcontent(type="application/json")` / `cfheader(name="Access-Control-Allow-Origin", value="*")` calls at `runner.cfm:159-160` started throwing `InvalidHeaderException: Failed to add HTML header` on Adobe CF 2023/2025 — by that point the response buffer has flushed mid-`testBox.run()` (any test output crossing the engine's buffer threshold commits the response), so the headers can't be modified. `$content()` picks up the same `$responseCommitted()` short-circuit as `$header()`, and the six `cfheader` / four `cfcontent` sites in `runner.cfm` now route through the framework helpers. The status-code header is the signal CI parsers key on, so best-effort is the right contract — a committed response keeps whatever statuscode the engine already wrote, and the JSON body still appends. Companion to the dispatch `$header()` and BaseReporter `reset()` fixes in this PR; the residual Adobe-CF outer-status bleed when an inner `processRequest()` spec sets `statusCode = 404` is tracked as a follow-up. The 16 MB buffer pre-sizing in `runner.cfm` (this PR) helps keep the response uncommitted long enough for the runner's own end-of-suite `$header(statusCode = 200|417)` to land in typical suites, but Adobe CF's default `getStatus() == 0` initial state (Undertow's "not set" sentinel) makes a clean `processRequest()`-level save/restore harder than expected — restoring to the captured 0 confuses downstream `renderText(status = $statusCode())` defaults that throw on invalid codes — so that path is deferred to a separate PR with a deeper redesign (#2756)
- `BaseReporter.resetHTMLResponse()` in the vendored TestBox no longer takes down the request when the response is already committed. `JSONReporter.runReport()` (called from `vendor/wheels/tests/runner.cfm:155`) invokes `resetHTMLResponse()` to clear `cfheader`/`cfhtmlhead` state before emitting the JSON report — but on Adobe CF 2023/2025 (Undertow servlet engine), the bare `getPageContextResponse().reset()` at `BaseReporter.cfc:54` throws `IllegalStateException: UT010019: Response already commited` whenever the response buffer has flushed during test setup (populate.cfm output, partial integration-test rendering, etc.). The adjacent Lucee-only `resetHTMLHead()` call a few lines up was already swallowed in a `try/catch`; extend the same shape to the bare `reset()` call. If the reset fails the reporter still emits its JSON, just appended to whatever already flushed; the structured JSON body is what `runner.cfm` consumes downstream so the test-results contract is preserved. Root cause behind every adobe2023/adobe2025 compat-matrix HTML-error page since the matrix was added — only visible after PR #2756 stopped `$header()` from masking it with the `cfheader` cascade (#2756)
- `$header()` in `vendor/wheels/Global.cfc` no longer masks the original exception when called from inside `onError`. On Adobe CF 2023/2025, the response buffer can already be committed by the time `$runOnError` (`EventMethods.cfc:113`) calls `$header(name = "Content-Type", value = "application/json")` — any partial output from a view that errored mid-render flushes at the engine's default threshold. `cfheader` then threw `InvalidHeaderException: Failed to add HTML header`, which replaced the upstream exception with the header-failure stack and turned every adobe2023/adobe2025 compat-matrix job into an opaque `cfheader` cascade. `$header()` now probes `response.isCommitted()` and short-circuits when the buffer has flushed; a wrapping `try/catch` re-runs the probe on engines where it races and rethrows the `cfheader` rejection only when the response is still uncommitted (so genuine caller bugs still surface). New companion helper `$responseCommitted()` sits next to `$header()` so other tag wrappers (`$content`, `$location`, `$cache`, ...) can adopt the same short-circuit incrementally. Spec coverage in `vendor/wheels/tests/specs/global/headerSpec.cfc` confirms the helper returns a boolean without throwing on every engine in the matrix. Follow-up to #2750 (which addressed the unrelated `attributeCollection = arguments` rejection on the same code path) — that fix is preserved; this one closes the orthogonal "response already committed" failure mode (#2756)
- `Migrator.renameSystemTables()` now works on Oracle. The function wrapped its DDL in `transaction action="begin" { ... commit }`, but Oracle implicitly commits DDL and closes the JDBC statement — so the subsequent `transaction action="commit"` raised `ORA: Closed statement`. The transaction wrapper is now skipped on Oracle (the existing code comment already acknowledged it was a no-op there); PostgreSQL and SQLite (via SAVEPOINT) keep the wrapper and roll back on error, while MySQL's path stays atomic via the multi-pair `RENAME TABLE a TO a', b TO b'` form (MySQL DDL also implicitly commits, so the wrapper itself is a no-op there — but the multi-rename is a single atomic statement, so no partial-rename scenario arises). Follow-up to #2749 which fixed the companion `model.insertAll()` Oracle failure from the same compat-matrix run (#2745)
- `model.insertAll()` on Oracle no longer errors with `ORA: returning clause is not allowed with INSERT and Table Value Constructor` (and the related `ORA: no statement parsed` follow-on). The bulk-insert SQL was always emitted as the SQL-standard multi-row table value constructor — `INSERT INTO t (cols) VALUES (?,?), (?,?), ...` — which Oracle 23 rejects in combination with the JDBC driver's implicit `RETURN_GENERATED_KEYS` handling (the driver expands `RETURN_GENERATED_KEYS` into a `RETURNING ROWID` clause, and Oracle 23 disallows `RETURNING` paired with multi-row VALUES). Bulk-insert SQL generation moved off the model mixin (`vendor/wheels/model/bulk.cfc::$buildBulkInsertSQL`, removed) onto the database adapter (`$bulkInsertSQL` on `databaseAdapters/Base.cfc`, mirroring the existing `$upsertSQL` pattern), so adapters can override per-engine. `databaseAdapters/Oracle/OracleModel.cfc` overrides it to emit Oracle's idiomatic multi-row form — `INSERT ALL INTO t (cols) VALUES (...) INTO t (cols) VALUES (...) SELECT 1 FROM dual` — which neither uses the table value constructor nor triggers the RETURNING expansion. Non-Oracle adapters (MySQL, Postgres, SQLite, H2, SQL Server, CockroachDB) keep the standard multi-row VALUES shape unchanged. The migrator-rename "Closed statement" error in the same compat-matrix run is a separate Oracle JDBC lifecycle issue and remains tracked under the parent issue (#2745)
- `addColumnOptionsSpec` now branches on `adapter.adapterName() == "MySQL"` for the `text` + non-empty default assertion, matching the existing `isPostgresFamily` carve-out. MySQL's `MySQLMigrator.optionsIncludeDefault` returns false for `text` / `mediumtext` / `longtext` / `float`, so the Abstract `addColumnOptions` short-circuits the entire DEFAULT clause for those types — emitting `NULL` rather than `DEFAULT '<value>'`. The spec previously asserted `toInclude("DEFAULT")` unconditionally and failed on every MySQL leg of the compat matrix (lucee6/mysql, lucee7/mysql, boxlang/mysql). The MySQL adapter's `optionsIncludeDefault` doc-comment now also explains the legacy pre-8.0.13 TEXT/BLOB constraint that motivates the suppression and references the spec contract. Follow-up to #2661/#2669
- `CockroachDBModel` now overrides `$supportsAdvisoryLocks()` to return `false`, so the four `lockingSpec` `withAdvisoryLock` tests skip cleanly on CockroachDB instead of erroring with `CockroachDB does not support advisory locks.`. The PR that introduced the capability flag (#2670) claimed CockroachDB in its CHANGELOG entry but never added the override — CockroachDB inherits from `PostgreSQLModel`, which reports `true`, so the spec's `beforeEach` skip-guard never fired and the four specs proceeded to call `$acquireAdvisoryLock`, which the adapter throws from by design. Compat-matrix legs `lucee6/cockroachdb`, `lucee7/cockroachdb`, and `boxlang/cockroachdb` now report 4 skips where they previously reported 4 errors. No spec changes needed — the capability-flag layer added in #2670 already does the right thing once the flag is correct (#2743)
- `Global.cfc` helpers now copy the `arguments` scope into a plain struct before passing it to `attributeCollection` on the underlying tag, so Adobe CF 2023 no longer rejects every request with `Failed to add HTML header`. Adobe 2023 is stricter than Lucee/BoxLang/Adobe 2021 about the shape passed to `attributeCollection` — the raw `arguments` scope is no longer accepted — which prevented any test request from booting past application init in the compat-matrix Adobe 2023 job (recorded `0 pass / 0 fail / 0 err` because no test endpoint completed its request). `$header()` is the visible blocker on the dispatch path, but the same engine-level restriction applies to every other helper that forwarded the raw scope (`$cache`, `$content`, `$mail`, `$directory`, `$file`, `$invoke`, `$location`, `$htmlhead`, `$wddx`, `$zip`, `$image`, `$dbinfo`), so the fix is applied uniformly across all twelve sites — covering both the string-interpolated form (`attributeCollection = "##arguments##"`) and the CFScript direct-struct form (`attributeCollection = arguments`). `$dbinfo()` rebuilds the local copy before each of its four `cfdbinfo` calls because the catch path mutates the `arguments` scope between calls. The existing `statusText` strip in `$header()` (added for Adobe CF 2025) collapses into the same single unconditional copy. Regression coverage in `vendor/wheels/tests/specs/global/headerSpec.cfc` (#2741)
- `lockingSpec :: "releases lock even when callback throws an exception"` now passes on BoxLang × MySQL/Postgres/SQLite — the missing leg of issue #2665 that #2670 intentionally deferred. The test was tracking exception propagation through `local.exceptionThrown = true` inside the `catch` block; on BoxLang, writes to the `local` scope inside a catch don't survive past the block (the catch body runs under a nested `local` that gets discarded on exit), so the post-catch `expect(local.exceptionThrown).toBeTrue()` always read the un-touched outer value and failed with "Expected [false] to be true". Switched to the same struct-field pattern `TenantResolverSpec` already uses for the equivalent assertion (`var state = {exceptionThrown = false}; ... state.exceptionThrown = true;`), which targets a heap object and survives the scope transition on every engine. `vendor/wheels/model/locking.cfc` is unchanged — the lock-release contract was already correct via the existing `try { callback() } finally { release }`. Adjacent to #2743/#2746 (CockroachDB advisory-lock skip) but a different fix shape — that PR fixed the capability flag, this one fixes the spec's BoxLang-incompatible state-tracking. New cross-engine compatibility doc entry covers the BoxLang catch-scope quirk so future spec authors don't re-hit it (#2744)
- `wheels.middleware.Cors` now short-circuits unmatched `OPTIONS` preflight requests at the dispatch layer, preserving the legacy `set(allowCorsRequests=true)` contract under the new middleware pipeline. Previously, `$findMatchingRoute()` ran before middleware, so a preflight against a path that only declared `POST` (or any non-`OPTIONS` verb) 404'd with `Wheels.RouteNotFound` before the CORS middleware's preflight branch could fire — leaving the middleware strictly less capable than the 3.x global setting it was meant to replace and breaking cross-origin `POST`/`PUT`/`PATCH`/`DELETE` from configured browsers. `Dispatch.$request()` now checks for an `OPTIONS` verb plus a `wheels.middleware.Cors` instance in the global pipeline and, if both are present, runs the pipeline against a no-op core handler before route matching. Dispatch behavior for `OPTIONS` without CORS middleware (still 404s) and for non-`OPTIONS` verbs (still routed normally) is unchanged (#2703)
- `paginationNav()` `showFirst` / `showLast` / `showPrevious` / `showNext` args now accept the tri-state strings `"auto"` / `"always"` / `"never"` (with backwards-compatible boolean coercion: `true` → `"always"`, `false` → `"never"`) and default to `"auto"`. Under `"auto"` the first/last anchors only render when the visible page-number window does not already reach the boundary — restoring the legacy 3.x `paginationLinks(alwaysShowAnchors=false)` semantics that a like-for-like swap to `paginationNav()` previously lost. Under `"auto"` the previous/next anchors always delegate to `previousPageLink()` / `nextPageLink()`, which render a disabled `<span class="disabled">` at the boundary by default — preserving the legacy `showPrevious=true` / `showNext=true` boundary indicator unless callers opt out with `"never"`. Adds a `windowSize` arg on `paginationNav()` so the auto-mode predicates stay coherent with `pageNumberLinks()`'s window (now passed explicitly to `pageNumberLinks()` instead of leaking through the anchor sub-helpers). Invalid strings throw `Wheels.InvalidArgument` at the call site
- `QueryBuilder.whereIn()` / `whereNotIn()` with an empty array no longer emit malformed SQL (`property IN ()`). Previously, passing an empty list or array to either method produced syntactically invalid SQL that surfaced as a generic JDBC syntax error from the database, with no pointer back to the call site that built the empty collection. `whereIn(prop, [])` now sets an `$alwaysEmpty` flag on the builder so every terminal method (`count`, `findAll`, `findOne`, `first`, `exists`, `updateAll`, `deleteAll`, `findEach`, `findInBatches`) short-circuits to the appropriate zero-row sentinel before going through the finder. `whereNotIn(prop, [])` is a no-op (exclude-none = match-all), so the chain proceeds normally. Matches the user-facing behaviour every mature ORM converged on (Rails, Sequel, Django, Laravel Eloquent: empty `IN` matches no rows, empty `NOT IN` matches every row). The flag-based design avoids a runtime trap from Wheels' WHERE-clause parser (`vendor/wheels/model/sql.cfc` runs a property-extraction regex over every clause it sees — a raw `1 = 0` literal would be parsed as property `1` and trip `Wheels.ColumnNotFound`). Fourteen new specs in `vendor/wheels/tests/specs/model/queryBuilderSpec.cfc` cover empty-array, empty-list, composition with other clauses, the `whereNotIn` mirrors, every patched terminal (`findAll`, `first` / `findOne`, `exists`, `count`, `updateAll`, `deleteAll`, `findEach`, `findInBatches`), and the documented `select()` / `include()` silent-ignore caveat on the short-circuit path. Both copies of the query-builder guide were updated to document the short-circuit in the methods table (#2736)
- `wheels mcp setup` now writes a stdio-based `.opencode.json` instead of one pointing at the deprecated HTTP MCP endpoint. `cli/src/templates/OpenCodeConfig.json` — the file the setup command actually reads from (`setup.cfc:53`) — still carried the pre-4.0 shape: `"url": "http://localhost:{PORT}/wheels/mcp", "type": "remote"`, with `{PORT}` left as an unsubstituted literal string. OpenCode users running `wheels mcp setup` ended up with a config trying to connect to a host called `{PORT}` against an endpoint that emits a deprecation warning on every call. The template now uses the same stdio form already shipped in `tools/build/base/.opencode.json`: `"type": "local", "command": ["wheels", "mcp", "wheels"]`. The companion monorepo reference copy at `app/snippets/OpenCodeConfig.json` (not read by the setup command, but kept in sync for consistency) was updated to match. The CHANGELOG entry from when the stdio shift originally landed claimed all template copies had been updated; this closes the two that were missed (#2735)
- `wheels packages --help` / `wheels packages help` / `wheels packages -h` now emit a module-owned help string that documents `add` as the canonical install verb and explains why typing `install` does not work (LuCLI's built-in extension installer intercepts the literal verb before dispatch reaches the module — same trap that hit `wheels browser install` → `wheels browser setup` in #2345). Previously the auto-introspected help drifted from the real CLI surface, advertising an `install <name> [--force]` row that never actually installed anything (#2713)
- Package manifest field reference in `web/sites/guides/.../packages.mdx` (both v4-0-0 and v4-0-1-snapshot copies) and `CLAUDE.md`: the inter-package dependency field is `requires`, not `dependencies`. The legacy 3.x plugin shape used `dependencies` in `box.json`; the modern `PackageLoader` (`vendor/wheels/ModuleGraph.cfc`) has always read `requires`, plus `replaces` (exclusion / migration path) and `suggests` (soft load-order edge). Copying the old example manifest would have shipped a package that loaded but silently ignored its declared dependencies — no error, no warning, just a missing-dep failure at the first runtime call into the absent dependency. All three docs now use `requires` and the previously undocumented `replaces` / `suggests` fields are covered alongside. Same PR also tightens the guide's description of `wheelsVersion` mismatches: not just "logged" but a hard skip — incompatible packages are excluded from the load order before their CFC is instantiated and recorded in `failedPackages` with the constraint and running version named in the log (#2734)
- `paginationLinks()` now emits a one-time per-request `WriteLog(type="warning", ...)` deprecation notice pointing 3.x → 4.x upgraders at `paginationNav()` (the all-in-one helper) and the individual `firstPageLink`/`previousPageLink`/`pageNumberLinks`/`nextPageLink`/`lastPageLink` composables. `wheels upgrade check --to=4.0.0` now also greps `app/views/` for `paginationLinks(` and flags every hit with a remediation pointer, closing the silent-rot gap surfaced by titan Phase 2.4 (#2714)
- `paginationNav()` now throws `Wheels.PaginationNav.InvalidArgument` when passed an argument that none of its sub-helpers (`paginationInfo`, `firstPageLink`, `previousPageLink`, `pageNumberLinks`, `nextPageLink`, `lastPageLink`) accept. Previously, typos such as `prependToList="<ul>"` were silently dropped by CFML's `argumentCollection` dispatch, leaving users to wonder why a styling argument had no effect. The check is gated on `application.wheels.showErrorInformation` so production is unaffected; development environments fail fast and the error names both the rejected arguments and the full allowlist of accepted pass-through keys (#2717)
- `wheels --help` no longer summarises the `packages` command as `Install, update, search Wheels packages` — that phrasing nudged users to type `wheels packages install <name>`, which LuCLI's built-in extension installer intercepts before module dispatch and silently no-ops (`[INFO] No git or extension dependencies to install`, exit 0, nothing under `vendor/`). The summary now leads with the canonical verb (`Add, update, search ...`) and parenthesises the gotcha so the doc surface stops contradicting the runtime. Same trap that earlier renamed `wheels browser install` to `wheels browser setup` (#2706)
- `wheels.middleware.Cors` now emits `Vary: Origin` alongside the reflected `Access-Control-Allow-Origin` header so CDN, reverse-proxy, and browser disk caches key the response on the request Origin instead of serving a cached response with the wrong ACAO to a different origin. Matches the behavior of the legacy 3.x `Global.cfc::$setCORSHeaders` path (vendor/wheels/Global.cfc:3565). The header is only emitted when an origin is actually being reflected — wildcard (`allowOrigins="*"`) responses and disallowed-origin responses are unchanged (#2707)
- `wheels.middleware.Cors` no longer emits the raw comma-delimited `allowOrigins` list as the `Access-Control-Allow-Origin` header value when a request arrives with no `Origin` header (same-origin, server-to-server, or curl-without-`-H`). Previously, the default `local.allowOrigin = variables.allowOrigins` seeded the raw list, and the `Origin`-header guard only reassigned it when an `Origin` was present — so multi-origin configurations like `allowOrigins="https://a.com,https://b.com"` shipped that exact string in the response header, violating the CORS spec requirement that `Access-Control-Allow-Origin` be a single origin or `*`. Origin resolution is now extracted into `$resolveAllowOrigin()` and only returns a value when the incoming `Origin` is in the allowlist (or when `allowOrigins == "*"`); same-origin and S2S responses no longer carry the header at all (#2704)
- `paginationNav()` now accepts `prepend` / `append` (outer-wrap HTML inside `<nav>`), `prependToPage` / `appendToPage` (per-anchor wrappers that now apply to first / previous / next / last as well as the numbered links — previously only the numbered links were wrapped), `addActiveClassToPrependedParent` (injects `active ` into the current-page `prependToPage` `class=` attribute, mirroring legacy `paginationLinks()`), and `anchorDivider` (replaces the hardcoded space between sub-helper sections). Bootstrap-styled 3.x apps can now do a like-for-like swap of `paginationLinks()` → `paginationNav()` by passing `prepend='<ul class="pagination">'` / `append='</ul>'` / `prependToPage='<li class="page-item">'` / `appendToPage='</li>'` / `class='page-link'` / `classForCurrent='active'` / `addActiveClassToPrependedParent=true`. `pageNumberLinks()` gained the same `addActiveClassToPrependedParent` arg so the Bootstrap idiom flows through when the helpers are composed manually. `paginationNav()` and `pageNumberLinks()` also strip event-handler attributes (`on\w+=`) and `javascript:` URIs from caller-supplied `prependToPage` / `appendToPage` after decoding HTML numeric entities — mirroring the defense-in-depth that legacy `paginationLinks()` applied — so a Bootstrap-style migration cannot silently lose XSS protection (#2715, #2730)
- `wheels` `.deb` / `.rpm` Linux packages now ship the lucli-native `wheels-module` artifact, version + channel stamps, and a wrapper that routes through the bundled module — fixing the three v4.0.0 rpm regressions that broke `wheels start` on Rocky Linux during the titan production cutover. (1) `build-linux-packages.sh` now untars `wheels-module-${WHEELS_VERSION}.tar.gz` into `/opt/wheels/module/` instead of unzipping the CommandBox-shaped `wheels-cli-${WHEELS_VERSION}.zip`. (2) The LuCLI binary is staged as `/opt/wheels/wheels` so `basename(argv[0])` is `wheels` when the wrapper execs it — mirroring the brew formula and making LuCLI's module dispatcher resolve `wheels start` against the bundled module. (3) `nfpm-wheels.yaml` and `nfpm-wheels-be.yaml` now declare `/opt/wheels/.version` and `/opt/wheels/.channel` under `contents:` so `wheels --version` no longer returns `unknown (stable)`. (4) `tar` is declared as an rpm + deb runtime dependency since Rocky Linux 10 minimal cloud images do not ship it and any role that unpacks a tarball payload fails silently without it (#2700)
- `wheels.middleware.RateLimiter` now validates `windowSeconds > 0` and `maxRequests >= 0` at construction. Previously, `windowSeconds = 0` leaked a generic CFML `You cannot divide by zero` exception out of the `fixedWindow` and `tokenBucket` strategies (and let every request through on `slidingWindow`), with no pointer back to the misconfigured `set(middleware = [...])` line. The constructor now throws `Wheels.RateLimiter.InvalidConfiguration` with a message naming the bad parameter — matching the pattern already used for `strategy`, `storage`, and `proxyStrategy`. `maxRequests = 0` remains legal (kill-switch idiom for "block every request") (#2693)
- `wheels deploy --version=v1.2.3` (the form documented in the Kamal migration guide) no longer fails with `Invalid value for option '--version': 'v1.2.3' is not a boolean`. picocli treats `--version` as a `versionHelp = true` root flag and absorbs it during arg parsing before `Module.cfc` ever sees the subcommand, so the literal Kamal form was unreachable. The deploy parser now accepts `--release` as a picocli-safe alias (extracted into `cli/lucli/services/deploy/cli/DeployArgsParser.cfc` for unit-testability), and the brew/scoop wrappers rewrite `--version[=val]` → `--release[=val]` when `deploy` is the first positional — so the documented `--version` form keeps working on a current-channel wrapper, and users on an older wrapper can pass `--release` directly (#2674)
- `wheels deploy bootstrap` and `wheels deploy exec` flat aliases for host-level deploy operations. The Kamal-style nested `wheels deploy server <verb>` form was being shortcut into LuCLI's top-level `server` command (Lucee instance lifecycle) by picocli before module dispatch could reach the deploy switch, so the bootstrap/exec verbs were unreachable from the shell. The flat aliases sidestep the collision; the nested `server <verb>` branch is retained for MCP and programmatic callers (#2677)
- `wheels deploy fetch-secrets`, `wheels deploy extract-secrets`, and `wheels deploy print-secrets` flat aliases for secret-store operations. Same shape as #2677 — picocli registers `secrets` as its own top-level subcommand (the LuCLI credential store: init/set/list/rm/get/provider) and intercepts the three-token Kamal-style `wheels deploy secrets <verb>` form before deploy can see it, so reporters got LuCLI's secrets help instead of a fetch/extract/print result. The flat aliases sidestep the collision; the nested `secrets <verb>` branch is retained for MCP and programmatic callers (#2697)
- `$gitShortSha()` in the deploy CLI no longer leaks git's `fatal: not a git repository...` stderr text as the version label when `wheels deploy` is run outside a git repository. Both copies (`DeployMainCli.cfc` and `DeployBuildCli.cfc`) now check the git process exit code and return `"unknown"` on non-zero, matching the existing `catch` fallback. The `DeployMainCli` copy also fixes a latent stream-drain ordering bug where `proc.waitFor()` was called before reading stdout (#2671)
- `wheels deploy` (every subcommand) now honors the `ssh:` block in `config/deploy.yml`. Previously every `new SshPool()` instantiation in `cli/lucli/Module.cfc::deploy()` passed no arguments, so the pool collapsed to the hardcoded defaults baked into `SshPool::init()` (`root@host:22`, no private key) regardless of what the user configured. `ssh.user`, `ssh.port`, and the first `ssh.keys[]` entry are now propagated through a new `$deployBuildSshPool(configPath)` helper that loads the config once and seeds the pool. Tilde (`~/`) expansion is performed against the JVM `user.home` because sshj's `loadKeys(String)` reads via `java.io.File` and doesn't expand the shell shortcut. When the config is missing (the `wheels deploy init` pre-config path) or malformed, the helper silently falls back so the verb itself can surface config errors with proper formatting (#2672)
- `TextReporter` (used by the test runner's `format=txt` output) now renders its plain-text report inline instead of including a vendored asset template that was never carried over from upstream TestBox. Selecting `format=txt` against `/wheels/app/tests` or `/wheels/core/tests` no longer throws `Page [/wheels/wheelstest/system/reports/assets/text.cfm] not found`; `html`, `json`, and `junit` were unaffected
- `wheels deploy init` no longer fails in a freshly generated user app with `file or directory [<app>/cli/lucli/templates/deploy/init/deploy.yml.mustache] does not exist`. The init verb was resolving its Mustache templates via `expandPath("/cli/lucli/templates/deploy/init")`, which uses the running app's mapping root — so inside a generated app the path pointed at a non-existent location under the user's project, not at the CLI install. `DeployMainCli` now anchors template resolution to its own CFC location (mirrors `JarLoader.cfc`), and `$docsPath` follows the same pattern so `wheels deploy docs <section>` also works from any app context (#2658)
- `vendor/wheels/tests/specs/migrator/addColumnOptionsSpec.cfc` is now adapter-aware: assertions for empty `default=""` on string-like types and for the boolean-default literal branch on `DEFAULT 1` vs `DEFAULT true` per adapter family (Abstract-based MySQL / SQLite / H2 / Oracle / MSSQL vs PostgreSQL / CockroachDB), unblocking the bundle on the cockroachdb + postgres compat-matrix legs. Also fixes the PostgreSQL `addColumnOptions` empty-string branch to prepend a leading space — without it, the `ALTER COLUMN ... SET DEFAULT ''` path produced the invalid token `SETDEFAULT ''`
- Binary-column property assignment via `setProperties()` / `new()` / `update()` no longer trips the scalar-column type guard on BoxLang or Lucee 6. `FileReadBinary()` and multipart uploads surface byte content as a CFML array on those engines (Lucee 7 / Adobe expose it as `byte[]`), and the model property setter was rejecting any array bound for a real DB column without consulting the column type. Binary columns (`blob`, `longblob`, `bytea`, `varbinary`, `clob`) are now exempt from the guard so the array shape passes through to the JDBC layer. Previously this manifested as `Cannot assign a array value to scalar column 'fileData' on the 'photo' model.` across `wheels.tests.specs.model.crudSpec` and `wheels.tests.specs.global.internalSpec` on every engine + DB except SQLite
- Narrow the binary-column carve-out added in #2668 to array-shape only. The original guard `&& !$propertyIsBinaryColumn(arguments.property)` short-circuited the entire `else if` to false for any binary column, so a struct bound to a blob/bytea/longblob column silently reached the JDBC layer and produced an opaque Java-level exception instead of the friendly `Wheels.PropertyIsIncorrectType` from #2412. The exemption now only covers *arrays* on binary columns — the actual case BoxLang / Lucee 6 file uploads hit — while structs on binary columns still throw, preserving the #2412 protection. CLOB columns remain in the carve-out group only because `$getValidationType` maps `CF_SQL_CLOB` to `"binary"` for guard-exemption purposes; the developer-facing doc now flags this explicitly to avoid conflating CLOB (character data) with byte storage.
- `bulkOperationsSpec.cfc` no longer asserts `toBeInstanceOf("component")` against `findOne()` results — Lucee/Adobe return the literal string `"component"` from `getMetadata().type`, but BoxLang returns the fully-qualified class name (e.g. `wheels.tests._assets.models.BulkItem`), so the assertion failed under BoxLang across every database (cockroachdb/mysql/postgres/sqlite). Replaced with a new portable `toBeWheelsModel()` matcher on `wheels.wheelstest.system.Expectation` that asserts against the framework `Model` base class via `IsInstanceOf`, which walks the inheritance chain identically on Lucee, Adobe, and BoxLang
- Core test runner result page (`/wheels/core/tests`) now initializes the Semantic UI "Failures / Errors / Passed" tabs inline, immediately after the menu markup, instead of relying solely on `_footer.cfm`. On the full-suite path the footer-bundled tab activator did not always reach the browser, leaving every tab but the default-active one un-clickable
- `vendor/wheels/public/docs/guides.cfm` and `vendor/wheels/public/views/ai.cfm` now discover the active guides sidebar by globbing `web/sites/guides/src/sidebars/*.json` and picking the highest-versioned filename instead of hardcoding `v4-0-0-snapshot.json` (which was removed when v4.0.0 went GA, causing the in-app Guides view to render an empty sidebar for monorepo contributors). The external redirect URL on `docs/guides.cfm` is now derived from the same active slug so the two never drift apart again
- Internal Wheels routes (`/wheels/info`, `/wheels/routes`, `/wheels/packages`, `/wheels/guides`, `/wheels/tests`, ...) no longer 500 on BoxLang with `Function [$blockInProduction] not found`. The BoxLang engine adapter's `invokeMethod` was splitting the dispatch into `local.method = obj[name]; local.method()`, which stripped the component receiver under BoxLang's JS-style dispatch — so every `Public.cfc` handler's first call to `$blockInProduction()` (added in #2241) failed to resolve. The dispatch is now a single-expression bracket-call that preserves the receiver. Lucee and Adobe were never affected (they take `Base.cfc::invoke()`). Regression test at `vendor/wheels/tests/specs/dispatch/InvokeMethodSpec.cfc` (#2646)
- `engineAdapter.getStatusCode()` no longer throws `Error getting method [getStatus] for class [ortus.boxlang.servlet.BoxPageContext]` on BoxLang. The BoxLang adapter overrides `getResponse()` to return the `PageContext` (so `getContentType()` can reach back to the request side for its Content-Type lookup), but the inherited `Base.cfc::getStatusCode()` then resolved to `PageContext.getStatus()` — which `BoxPageContext` does not expose. The adapter now provides its own `getStatusCode()` override that reaches the underlying `HttpServletResponse` via `GetPageContext().getResponse().getStatus()`. This was the single largest source of BoxLang test errors in the compat matrix (~600 errors across `renderingSpec`, `csrf.cookieSpec`, `csrf.sessionSpec`, `sseSpec`, and six other bundles × five databases). Lucee and Adobe were never affected (they don't override `getResponse()`). Regression assertion added to `vendor/wheels/tests/specs/engineAdapterSpec.cfc`
- Stop the generated app's `_gitignore` and `app/plugins/README.md` from advertising the broken `wheels packages install` / `wheels install` verbs; point users at the canonical `wheels packages add` verb (#2610)
- Use the Adobe-safe 3-argument `mid()` form when stripping the `wheels` prefix in the MCP command executor and its security spec; the prior 2-arg call crashed the entire `security/` test bundle on Adobe ColdFusion (#2613)
- Replace Lucee-only `directoryCreate(path, true)` calls in `BrowserTest.$captureFailureArtifacts` and `McpServer` test-file generation with `java.io.File.mkdirs()` so artifact directory creation no longer trips Adobe ColdFusion's `DIRECTORYCREATE` single-argument validator (#2614)
- Generated `Application.cfc` (and the in-repo `public/`, `examples/tweet/`, `examples/starter-app/` copies) now assigns the injector directly to `application.wheelsdi` in `onApplicationStart()` and `onError()` instead of an orphan local `injector` variable, matching the documented 4.0 DI container name and the way every other reference in the file reads (#2622)
- Legacy CommandBox `box wheels upgrade` command (`cli/src/commands/wheels/upgrade.cfc`) now prints a deprecation banner pointing at the new Wheels CLI (`brew install wheels-dev/wheels/wheels` → `wheels upgrade check`) and short-circuits before its stale hardcoded version list that maxed at 3.1.0; the post-upgrade-recommendations URL is updated to the canonical v4.0 guide. The CommandBox `wheels-cli` module remains scheduled for removal in v5.0 (#2634)
- Interpolate plugin and package names in the "Loading plugin..." / "Loading package..." `wheels_security.log` INFO lines so operators can read which plugin/package was being loaded; the call sites were double-escaping the pound signs (`##var##`) and emitting literal `#var#` placeholders instead of resolved values (#2630)
- Update the scaffolded `config/routes.cfm` doc-URL comment in `cli/src/templates/ConfigRoutes.txt` and `cli/lucli/templates/app/app/snippets/ConfigRoutes.txt` from the dead `https://guides.wheels.dev/docs/routing` path to the canonical `https://guides.wheels.dev/v4-0-0-snapshot/handling-requests-with-controllers/routing` URL, so freshly scaffolded apps no longer ship a broken link (#2635)
- `wheels new --no-sqlite` now suppresses the SQLite datasource pair in the scaffolded `lucee.json` so Lucee no longer auto-creates `db/development.sqlite` / `db/test.sqlite` on first connection (#2621)
- Extend `wheels upgrade check` for 3.x → 4.x to scan seven additional documented breakers (CORS deny-all default, RateLimiter hardened defaults, `allowEnvironmentSwitchViaUrl`, missing `csrfEncryptionKey`, legacy `wheels snippets` invocations in build/CI scripts, `tests/specs/functions/` rename, `viteStrictManifest` default flip); previously the tool only flagged the legacy plugin directory, `wheels.Test` base class, and `application.wirebox` references — silence on the rest read as a green light (#2628)
- Align `wheels upgrade` help with the command's actual behavior: the top-level `wheels --help` summary now describes the command as a read-only scanner, the docblock hint matches, and the in-function usage block expands to cover the `check` subcommand, the supported `--to=<version>` flag, an explicit note that `--dry-run` is not supported (and never was), and a pointer to `brew upgrade wheels` / `scoop update wheels` for the actual install. Running `wheels upgrade --dry-run` or `wheels upgrade --to=4.0.0` (without `check`) now also prints a `Did you mean: wheels upgrade check ...` nudge (#2629)
- `wheels start` now drops the working `rewrite.config` template at the project root when one is missing, so 3.x → 4.0 upgrades stop 404-ing static assets that live under non-default dirs like `/miscellaneous/`, `/javascripts/`, `/stylesheets/`, `/files/`. LuCLI's bundled default uses a narrow allow-list plus negated `RewriteCond` chains that Tomcat's RewriteValve doesn't honour; the project override sidesteps it. Existing project rewrite.config files are left untouched (#2626)

### Documentation

- Upgrade guide item 10 (`application.wirebox` → `application.wheelsdi`) now includes a callout that `wheels-legacy-adapter` does not shim this rename; apps must update direct `application.wirebox` access and `new wirebox.system.ioc.Injector(...)` bootstrap code regardless of adapter installation (#2627)
- Clarify that the 3.x global `set(allowCorsRequests=true)` path is still honored in 4.0 and document the precedence when both the global setting and `wheels.middleware.Cors` are active (#2633)
- Legacy Compatibility Adapter section now lists what the adapter covers versus what requires manual remediation, and adds a boot-failure entry to Common Issues for the removed `wirebox` package path (#2627)
- Document that `reloadPassword` must be wired through `config/settings.cfm` via `set(reloadPassword = env("WHEELS_RELOAD_PASSWORD", ""))` — a value in `.env` alone is not wired into framework settings automatically, and the fail-closed boot warning will fire regardless (#2631)
- Upgrade guide (v4-0-0 and v4-0-1-snapshot) item 4 now documents the `config/environment.cfm` load-order gap: `application.env.environment` is not reliably populated before that file runs, causing production servers to resolve `environment=""` and emit `environment=development` to Sentry and the debug bar. The canonical fix (`set(environment=env("environment", "production"))`) and its deliberate `"production"` fail-safe default are documented alongside the existing `reloadPassword` guidance. A matching "Common issues" entry is added for discoverability (#2709)

---

# [4.0.0](https://github.com/wheels-dev/wheels/releases/tag/v4.0.0) => 2026-05-12

> **Wheels 4.0** — the release that started as 3.1 and grew into a major version. Closes multiple framework-maturity gaps against Rails, Laravel, and Django. See [docs/releases/wheels-4.0-audit.md](docs/releases/wheels-4.0-audit.md) for the full audit trail (260+ merged PRs since 3.0.0). Contributors: @bpamiri, @zainforbjs, @chapmandu, @mlibbe, @MukundaKatta.

### Added

**Documentation**
- Correct landing page license text from "MIT licensed" to "Apache 2.0 licensed"
- Add Debug Panel guide covering each tab, configuration settings, and when the bar appears
- Clarify BoxLang server management in cfml-engines guide; update vm-deployment tip to distinguish CommandBox server management from the `wheels` dev CLI

**ORM & data layer**
- Chainable query builder with `where()`, `orWhere()`, `whereNull()`, `whereBetween()`, `whereIn()`, `whereNotIn()`, `orderBy()`, `limit()`, and more for injection-safe fluent queries (#1922)
- Enum support with `enum()` for named property values, auto-generated `is*()` checkers, auto-scopes, and inclusion validation (#1921)
- Query scopes with `scope()` for reusable, composable query fragments in models (#1920)
- Batch processing with `findEach()` and `findInBatches()` for memory-efficient record iteration (#1919)
- Bulk insert/upsert operations (`insertAll()` / `upsertAll()`) with per-adapter native UPSERT syntax across MySQL, PostgreSQL, SQL Server, SQLite, H2, CockroachDB, and Oracle (#2101)
- Polymorphic associations via `belongsTo(polymorphic=true)` and `hasMany(as=...)` with type-discriminator JOINs (#2104)
- Advisory locks (`withAdvisoryLock(name, callback)`) and pessimistic locking (`.forUpdate()` on QueryBuilder) for `SELECT ... FOR UPDATE` (#2103)
- CockroachDB database adapter — seventh supported database, with `unique_rowid()` PK convention and `RETURNING` clause identity select (#1876, #1986, #1993, #1999)
- `throwOnColumnNotFound` config setting for strict column validation in WHERE clauses (#1938)
- SQL identifier quoting for reserved-word conflicts in table/column names (#1874)

**Migrations**
- Auto-migration generation from model/DB schema diff (`AutoMigrator.diff(modelName)`, `writeMigration()`) (#2102)
- Auto-migration rename detection via explicit hints plus heuristic suggestions (normalized-token + Levenshtein) with new `wheels dbmigrate diff` CLI command and MCP integration (#2112)

**Routing**
- Router modernization: `group()` helper, typed constraints (`whereNumber`, `whereAlpha`, `whereUuid`, `whereSlug`, `whereIn`), API versioning via `.version(1)`, performance indexes (#1891, #1894)
- Route model binding with `binding=true` on resource routes or `set(routeModelBinding=true)` globally to auto-resolve model instances from route key parameters (#1929)

**Middleware pipeline (new core framework)**
- Middleware pipeline: closure-based chain running at dispatch level before controller instantiation, route-scoped via `.scope(middleware=[...])` or global via `set(middleware=[...])` (#1924)
- Rate limiting middleware with `wheels.middleware.RateLimiter` supporting fixed window, sliding window, and token bucket strategies with in-memory and database storage (#1931)
- SecurityHeaders middleware emits Content-Security-Policy, HSTS, and Permissions-Policy headers (#2036)
- `hsts` argument on `SecurityHeaders` middleware to suppress the `Strict-Transport-Security` header entirely, for apps behind TLS-terminating proxies that emit HSTS themselves (#2174)
- Multi-tenant support with per-request datasource switching (#1951)

**Views**
- Composable pagination view helpers: `paginationInfo()`, `previousPageLink()`, `nextPageLink()`, `firstPageLink()`, `lastPageLink()`, `pageNumberLinks()`, and `paginationNav()` for building custom pagination UIs (#1930)
- XSS helpers formalized: `h()`, `hAttr()`, `stripTags()`, `stripLinks()` (#2097)
- Redesigned v4.0 congratulations page for scaffolded apps (#2098)
- `vitePreloadTag()` view helper emits `<link rel="modulepreload">` for a Vite entrypoint and its transitive chunk imports, suitable for Turbo Drive hover-preload patterns
- `viteScriptTag()` and `viteStyleTag()` now resolve transitive chunk imports from the Vite manifest: modulepreload links for JS chunks are emitted into `<head>`, and CSS from transitive chunks is included in the stylesheet tags (brings parity with Rails/Laravel Vite integrations)
- `viteStrictManifest` setting (default `true`) — missing manifest entries now throw `Wheels.ViteAssetNotFound` in production. Set to `false` to restore 3.x silent behavior.

**Background jobs & real-time**
- Job worker daemon with CLI commands (`wheels jobs work/status/retry/purge/monitor`) for persistent background job processing with optimistic locking, timeout recovery, and live monitoring (#1934)
- Configurable exponential backoff for jobs via `this.baseDelay` and `this.maxDelay` with formula `Min(baseDelay * 2^attempt, maxDelay)` (#1934)
- Pub/sub channels for SSE: `subscribeToChannel()`, `publish()`, `poll()`, with DatabaseAdapter and in-memory implementations (#1940)

**Dependency injection**
- Expanded DI container with `asRequestScoped()` for per-request service instances, `service()` global helper, declarative `inject()` in controller config, `bind()` interface binding, auto-wiring of init() arguments, and `config/services.cfm` for service registration (#1933)

**Testing infrastructure**
- HTTP test client (`TestClient`) for integration testing with fluent assertions: `visit()`, `assertOk()`, `assertSee()`, `assertJson()`, `assertJsonPath()`, cookie tracking, session support (#2099)
- Parallel test execution runner (`ParallelRunner`) partitioning bundles across `cfthread` workers (#2100)
- Browser testing via Playwright Java with `BrowserTest` base class, fluent DSL (navigation, interaction, keyboard, waiting, scoping, cookies, auth, dialogs, viewport, script, screenshots, assertions), and `wheels browser:install` command (#2113, #2115, #2116, #2121)

**Package system**
- Package system (`PackageLoader`) with `packages/` → `vendor/` activation model, `package.json` manifests with `provides.mixins` targets, per-package error isolation (#1995)
- Module system with dependency graph (requires/replaces/suggests topological sort) and lazy loading (#2017)
- LuCLI module distribution via wheels-cli-lucli repo (#2018)
- `/wheels/packages` developer page now shows a "Browse registry" section listing all packages available from `wheels-dev/wheels-packages` — package name, description, latest version, and a copy-to-clipboard `wheels packages install <name>` snippet per row. Rows matching an already-installed package show a `✓ Installed` badge. Dev/testing only; `$blockInProduction()` gate keeps it off production servers. Registry data comes from the CLI's `Registry.listAll()` with 24h app-scope cache (#2271, partial — wheels.dev/packages static-site work deferred)

**Engine adapters & cross-engine**
- Engine adapter modules encapsulating Lucee, Adobe CF, and BoxLang engine-specific behavior (#2016)
- Interface-driven design contracts for framework extension points (#2014)

**Migration & legacy**
- Legacy compatibility adapter for 3.x → 4.0 migration soft-landing (#2015)

**CLI & LuCLI**
- `wheels new` now prints a non-blocking hint at the end of app scaffolding when a newer Wheels release is available on the user's channel (stable, bleeding-edge). Channel-aware (skips dev/rc), 24h-cached at `$LUCLI_HOME/.update-check.json`, 5s HTTP timeout, silent on any failure — never delays or breaks `wheels new`. (#2556)
- `wheels doctor` now detects a stale installed CLI module at `~/.wheels/modules/wheels/` that shadows a source checkout and warns with a remediation command (symlink). Previously, contributors running `wheels` from a checkout could silently execute a pre-install Module.cfc, making merged fixes appear not to take effect. (#2223)
- LuCLI Phase 2: zero-Docker local testing via `tools/test-local.sh` (#2063)
- LuCLI Phase 2: service layer, generators, MCP annotations (#1941)
- LuCLI Phase 3–4: scaffold, seed, in-process services (#2065)
- LuCLI-native Lucee 7 + SQLite CI pipeline (#2032)
- LuCLI tier 1 commands module + WheelsTest test suite (#2092, #2093)
- Playwright CLI commands for browser testing (#2013, #2021)

**Distribution (new in 4.0)**
- **macOS** — Homebrew tap at [`wheels-dev/homebrew-wheels`](https://github.com/wheels-dev/homebrew-wheels) with separate formulae for stable (`wheels`) and bleeding-edge (`wheels-be`) channels. Daily auto-update workflow polls the upstream release feeds and opens PRs.
- **Windows** — Scoop bucket at [`wheels-dev/scoop-wheels`](https://github.com/wheels-dev/scoop-wheels) with `wheels` / `wheels-be` manifests. Hourly auto-update via the community Excavator bot. Legacy Chocolatey `wheels` package on `community.chocolatey.org` (CommandBox-based v1.x) is no longer maintained — see [Windows install docs](web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/installing.mdx) for the migration. (#2545, #2552)
- **Linux** — `.deb` and `.rpm` packages built by `nfpm` on every release and uploaded to the GitHub Release alongside the existing zip artifacts. The package installs `/usr/bin/wheels`, depends on OpenJDK 21, and on first run syncs the framework module into `~/.wheels/`. Native `apt`/`yum` repositories at `apt.wheels.dev` / `yum.wheels.dev` are planned for 4.0.x. (#2545)
- **WinGet** — manifest drafts for `Wheels.Wheels` and `Wheels.WheelsBE` staged for post-GA submission to the `microsoft/winget-pkgs` community repo. (#2557)

**Configuration & developer experience**
- `env()` helper for cross-scope environment variable access (#1985)
- Pre-request logging (#1895)
- Debug panel redesign (W-001, W-002) (#2000, #2001)
- Gap migration detection in `migrateTo()` — detects and runs previously-skipped migrations, not just the endpoint (#1928)
- Calculated property SQL validation at model config time (#2067)
- GROUP BY validation with dot-notation, matching ORDER BY parser (#2084)
- Adopt the [Developer Certificate of Origin](https://developercertificate.org/) for contributions — `Signed-off-by:` trailer required on every commit via `git commit -s`; enforced by the [DCO GitHub App](https://github.com/apps/dco) on new PRs only (existing commits grandfathered); `CONTRIBUTING.md`, PR template, and `wheels-bot` rails updated (#2575)

### Changed

- Project-level docs and the `tools/test-local.sh` script now refer to the CLI as `wheels` rather than `lucli`. Wheels is built on the LuCLI runtime, but the rebranded `wheels` binary is the only thing end users install — `brew install wheels`, `wheels server run`, `~/.wheels/express`. CLAUDE.md adds an explicit "wheels IS the CLI" callout so future Claude sessions and new contributors don't go looking for a separate `lucli` install when `tools/test-local.sh` fails. References to LuCLI as the upstream runtime project (e.g. installation docs explaining the relationship, runtime-specific env vars like `LUCLI_HOME`) are intentionally retained.
- **Breaking:** CORS middleware default changed from wildcard `*` to deny-all. Apps must explicitly configure `allowOrigins` or set an explicit wildcard. (#2039)
- **Breaking:** `viteStrictManifest` defaults to `true` — a missing Vite manifest entry now throws `Wheels.ViteAssetNotFound` in production instead of silently falling back (3.x behavior). Rebuild Vite assets during the upgrade window; to retain 3.x silent behavior, `set(viteStrictManifest=false)`. (#2133)
- **Breaking:** `allowEnvironmentSwitchViaUrl` defaults to `false` in production (#2076)
- **Breaking:** Reload password must be non-empty for environment switching in production (#2082)
- **Breaking:** HSTS header defaults on in production (#2081)
- **Breaking:** CSRF cookie now sets `SameSite` attribute (#2035)
- **Breaking:** RateLimiter `trustProxy` default changed from `true` to `false` (#2024)
- **Breaking:** RateLimiter proxy strategy default changed to `last` (#2088)
- **Breaking:** `wheels snippets` CLI command renamed to `wheels generate snippets` (#1852)
- **Breaking:** Test base class namespace renamed: new tests extend `wheels.WheelsTest` (old `wheels.Test` preserved during 4.0 as a deprecation path) (#1889)
- **Breaking:** Tests directory `tests/specs/functions/` renamed to `tests/specs/functional/` (#1872)
- **Breaking:** `application.wirebox` renamed to `application.wheelsdi` (#1888)
- CFWheels branding removed from active code and metadata (continuation of the 3.0 rebrand) (#2064)
- Project version bumped to 4.0.0-SNAPSHOT (#2066)
- Internal rim modernized: WireBox/TestBox replaced; `init()` decomposed (#1883)
- Monorepo flattened to clone-and-run structure (#1885)
- Architecture hardening: XSS helpers consolidated, error hooks added, interface verification (#2097)
- CSRF cookie encryption key auto-generated when empty (apps should still set their own for stable cross-deploy cookies) (#2054)
- CI engine testing restructured: 42 jobs reduced to 8 via engine-grouped testing (#1939)
- `wheels mcp wheels` MCP surface curated — 7 CLI-only commands (`mcp`, `d`, `new`, `console`, `start`, `stop`, `browser`) hidden from MCP `tools/list` via the `mcpHiddenTools()` convention (requires LuCLI 0.3.4+). All remain reachable as CLI subcommands. Tool count drops from 23 to 16 for agent consumers.
- LuCLI stdio MCP (`wheels mcp wheels`) is now the canonical AI-agent surface for Wheels. `wheels mcp setup` generates `.mcp.json` and `.opencode.json` pointing at the stdio transport. No port or running dev server required. Updated templates: `cli/src/templates/McpConfig.json`, `app/snippets/McpConfig.json`, `tools/build/base/.mcp.json`, `tools/build/base/.opencode.json`.
- Package lazy-loading (`"lazy": true` in `package.json`) retained and documented in the [Packages](web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/packages.mdx) guide. Audit of all six first-party packages (`wheels-sentry`, `wheels-hotwire`, `wheels-basecoat`, `wheels-legacy-adapter`, `wheels-i18n`, `wheels-seo-suite`) found no candidates — all provide controller mixins, which require eager load to populate the mixin tables. The feature remains valid for third-party service-only packages. Added a defensive test that a package declaring `lazy: true` alongside mixins or middleware is still loaded eagerly (the loader's existing `canBeLazy` gate). (#2249)

### Deprecated

- Legacy `plugins/` folder — superseded by the new `packages/` → `vendor/` activation model. Plugins still load, with a deprecation warning. Scheduled for removal in v5.0. (#1995)
- RocketUnit test style for new tests — BDD syntax (via WheelsTest) is required going forward. Existing RocketUnit specs continue to run. (#1925)
- `wheels.Test` test base class — extend `wheels.WheelsTest` instead (#1889)
- In-dev-server HTTP MCP endpoint at `/wheels/mcp` — superseded by the LuCLI stdio MCP server (`wheels mcp wheels`). Emits a deprecation warning to the `wheels_mcp` log on first request and advertises `deprecated: true` in the `serverInfo` handshake. Scheduled for removal in a future release. Migrate existing projects with `wheels mcp setup --force`.
- Legacy CommandBox `wheels-cli` module (`wheels g app`, `wheels new` via the CommandBox wizard) — superseded by LuCLI's canonical `wheels new`. Emits a deprecation banner on every invocation. Scheduled for removal in v5.0. (#2227)

### Removed

- Legacy RocketUnit core test scaffolding (existing app specs still run; framework-level runner removed) (#1925)
- Railo compatibility workaround from `$initializeMixins` — Railo is no longer a target (#1987)
- `server.cfc` file (#1902)
- Stale monorepo artifacts after repository flatten (#1988)
- `cli/lucli/services/MCP.cfc` parallel schema registry — never wired into LuCLI's MCP discovery, drifted out of sync with `Module.cfc`. Rich parameter schemas will return via typed parameters directly on Module.cfc functions in a follow-up PR.
- Undocumented per-file `checksums` field from `package.json` manifest and its verification code in `PackageLoader` — superseded by the registry-level tarball sha256 pinned at publish time. No migration required (no shipped package used it). (#2248)

### Fixed

- `scoop install wheels` / `scoop install wheels-be` on Windows no longer aborts with `Can't shim 'wheels.cmd': File doesn't exist.` Scoop's install order is `pre_install` → bin shim creation → `post_install`, but the bucket's manifest generator (`tools/distribution-drafts/scoop/build-manifests.py`) emitted the `wheels.cmd` launcher in `post_install` — so the shim step ran first, failed because the file wasn't there yet, and aborted before the launcher was ever written. Moved the launcher emit into `pre_install` (both `wheels` and `wheels-be` manifests are byte-identical apart from the renamed key). (#2603)
- Model `$setProperty` now throws `Wheels.PropertyIsIncorrectType` when a struct or array value is mass-assigned to a property that isn't declared as a nested association, instead of silently overwriting `this.<property>` and producing a confusing `Can't cast Complex Object Type Struct to String` deep inside a user callback. The most common upstream cause is form data shaped by a curl POST whose body uses bracket-nested keys without an `=` separator (e.g. `--data-urlencode "user[email][badkey]"`); Lucee's form parser turns that into a nested-struct path so `params.user.email` arrives shaped like a struct. Legitimate nested-attribute assignments (`hasOne`/`hasMany`/`belongsTo` with `nestedProperties()` enabled) continue to work unchanged. Also corrects the chapter 6 tutorial's curl gotcha note: the failure mode is the missing `=` separator, not `@` encoding per se. (#2412)
- `wheels test` preamble no longer prints `<base>_test_test` for apps that only declare `coreTestDataSourceName`. `$resolveAppTestDataSource` in `cli/lucli/Module.cfc` searched `config/settings.cfm` with the regex `dataSourceName\s*=\s*"([^"]*)"`, which case-insensitively matched the trailing substring inside `set(coreTestDataSourceName="testappdb_test")` and then re-appended `_test`. The matcher now uses `\bdataSourceName\b` and strips CFML comments before the lookup (matching the pattern already used by `info()`), and guards against re-appending `_test` if the resolved base already ends in `_test`. Extracted the app-runner's `?directory=` regex into a `TestDirectoryResolver` helper alongside `TestDbResolver` so the silent-fallback path (a bare `?directory=models` collapsing to `tests.specs`) is unit-testable instead of HTTP-only. (#2489)
- Core test suite no longer crashes on Adobe ColdFusion 2023/2025 with `java.lang.ArrayStoreException: coldfusion.compiler.ASTcffunction`. `vendor/wheels/tests/specs/middleware/RateLimiterSpec.cfc` passed 12 inline `keyFunction = function(req) { ... }` literals as named arguments to `new wheels.middleware.RateLimiter(...)`; Adobe CF's bytecode generator (`ExprAssembler.invokeNew` → `generateSetVarCode`) rejects function-AST nodes in that array slot and the failure fires from `getComponentMetadata()`, eagerly crashing every CFC in the bundle directory and forcing every database matrix cell on `adobe2023`/`adobe2025` to HTTP 500. All 12 closures are now hoisted into local `var keyFn = ...` declarations above the constructor call, matching the existing workaround in `SessionStrategySpec.cfc`. No behavior change on Lucee/BoxLang. Trap documented in `.ai/wheels/cross-engine-compatibility.md` and `CLAUDE.md` "Known cross-engine gotchas" list. (#2568, #2599)
- `LICENSE` and `NOTICE` are now bundled into the `wheels-core`, `wheels-cli`, and `wheels-starter-app` release artifacts so every distributed scaffold ships with Apache 2.0 §4(a) license text and §4(d) NOTICE attribution. Previously only the base-template artifact bundled them — derivatives published from the other three prepare scripts left downstream redistributors out of compliance.
- `/wheels/guides` redirect page no longer throws "Unable to add text to HTML HEAD tag" on Adobe ColdFusion. The docs view injected its 3-second meta refresh via `cfhtmlhead` from inside `vendor/wheels/public/docs/guides.cfm`, but the wrapper view (`vendor/wheels/public/views/guides.cfm`) includes the layout header before the docs view runs — so by the time `cfhtmlhead` executes the response has already streamed past `</head>`. Lucee tolerates this; Adobe rejects it. Replaced the head-injection with a body-level JS redirect that reads its target from a `data-url` attribute (still encoded with `encodeForHTMLAttribute`, matching the visible anchor), so the redirect works identically on every engine. (#2569)
- Tools → Packages page no longer 500s on Adobe ColdFusion. `$ensureDir` in `vendor/wheels/services/packages/ManifestCache.cfc` called `DirectoryCreate(path, true)`, but the `createPath` flag is a Lucee-only extension — Adobe CF rejects the second argument with `"The function takes 1 parameter"`, crashing the first request after a fresh install when `~/.wheels/cache/` does not yet exist. The recursive mkdir now routes through `java.io.File.mkdirs()`, which has stable JVM-level semantics on every supported engine. Mirrored into the CLI-side `cli/lucli/services/packages/ManifestCache.cfc` to keep the deliberately paired files in sync. (#2567)
- `wheels validate` no longer passes models or controllers whose only `extends="Model"` / `extends="Controller"` declaration is inside a CFML comment. `validateModel()` / `validateController()` in `cli/lucli/services/Analysis.cfc` performed a substring search over the raw file content, so a line like `// component extends="Model" {` above a commentless `component { … }` satisfied the inheritance check incorrectly. The validators now strip line, block, and tag-style CFML comments before testing for the `extends=` token.
- `wheels console` slash commands `/models`, `/routes`, `/version`, and `/datasource` no longer fail with `Cannot cast Object type [url] to a value of type [string]`. The `consoleExec` helper in `cli/lucli/Module.cfc` declared a parameter named `url`, which CFML's reserved URL scope shadowed at the call to `makeHttpPost(url, body)` — so the function received the URL scope struct in place of the request URL. Renamed the parameter to `requestUrl` to match `makeHttpPost`'s own signature.
- Routes UI now classifies the framework's `/_browser/*` browser-test fixture routes as Internal instead of leaking them into the Application tab. The bucket predicate in `vendor/wheels/public/views/routes.cfm` previously matched only `controller == "wheels.public"` or `pattern == "/wheels/app/tests"`, so the fixture routes (which use controllers like `BrowserTestHome`) fell through to App and made the route list noisier in dev/test environments that opt into `loadBrowserTestFixtures`.
- Tools → Packages listing page's "View Tests" link now passes the test directory through `urlFor`'s `params` argument instead of concatenating `&directory=...` onto the URL. The old form produced a path like `/wheels/core/tests&directory=vendor.foo.tests` (the `&` ended up inside the path segment), and the router responded "Could not find a route that matched this request." The fix mirrors the same pattern already used by the per-package detail page's "Run Package Tests" button. (#2428)
- `wheels generate api-resource` now produces a controller with resolved identifiers instead of literal `#objectNamePlural#` / `#objectNameSingular#` placeholders. The framework snippet at `app/snippets/ApiControllerContent.txt` was still using the legacy hash-token form that the CLI's `Templates.processTemplate()` does not substitute, while the CLI-bundled copy already used the pipe-delimited `|ObjectNamePlural|` / `|ObjectNameSingular|` tokens it understands. Aligned the framework-level snippet with the CLI-bundled one. (#2468)
- Framework dev pages (`/wheels/guides`, `/wheels/info`, `/wheels/migrator`, `/wheels/packages`, error screens) now render Semantic UI icons instead of empty bordered squares. The dev layouts inline `semantic.min.css` into a `<style>` block, so its relative URLs to `themes/default/assets/fonts/icons.woff2` resolved against the page URL and 404'd — every `<i class="...icon">` rendered as the fallback square. `_header.cfm` and `_header_simple.cfm` now read the woff2 once at application scope, base64-encode it, and emit a `@font-face` override after the inlined Semantic CSS. Initialization uses double-checked locking on `application.wheels.iconsFontDataUri` so concurrent first-requests can't read an intermediate empty value. (#2563)
- Debug bar Tools → Packages page now lists packages available from the `wheels-dev/wheels-packages` registry in fresh apps generated with `wheels new`. The previous gate (`FileExists("/cli/lucli/services/packages/Registry.cfc")`) silently returned an empty list because user apps don't ship the CLI alongside the framework. The registry reader now lives at `vendor/wheels/services/packages/{Registry,HttpClient,ManifestCache}.cfc` and ships with every generated app. The registry list stays scoped to the standalone Tools → Packages page; the inline debug-bar Environment panel shows installed packages only, so the bar stays compact and doesn't trigger a registry walk on every dev-mode page load. (#2530)
- `Registry.fetchManifest()` now validates that a manifest contains a non-empty `versions` array before returning, throwing `Wheels.Packages.RegistryMalformed` instead of letting a downstream `local.m.versions[ArrayLen(...)]` access crash with an unhandled `Expression` error. The per-package skip-on-malformed catch in `listAll()` now actually catches every malformed shape, so the Tools → Packages page degrades gracefully when the registry serves a partial manifest. Mirrored into the CLI's `cli/lucli/services/packages/Registry.cfc` to keep both copies in sync. (#2530)
- Installed-package indicator on the Tools → Packages page now renders correctly. The badge previously used Semantic UI's icon-font `<i class="check icon">`, which the bundled `semantic.min.css` declares only with `.eot` and `.svg` font sources (no `.woff`/`.woff2`) and is referenced via relative URLs broken by the page's inlined-CSS approach — so the glyph never loaded in modern browsers. Replaced with an inline SVG checkmark, matching the pattern used by every other icon in the same view. (#2423)
- Snapshot pre-releases on `develop` now publish the full artifact set (`wheels-core-*.zip`, `wheels-base-template-*.zip`, `wheels-cli-*.zip`, `wheels-starter-app-*.zip`) alongside `wheels-module-*`. Previously only the module tarball was attached, which broke Homebrew/Chocolatey distributions that depend on fetching `wheels-core-*.zip` as a companion artifact: users scaffolded a new app and hit "Could not locate the Wheels framework source" at chapter 1 of the tutorial. Snapshots now mirror the main-branch release contents exactly, flagged as pre-release.
- `wheels doctor` now detects when the installed CLI module has no companion framework source (vendor/wheels/) on disk — catches broken package distributions before they surface as a cryptic scaffold error. Previously `doctor` would report missing project directories and recommend `wheels new`, but `wheels new` would then fail with "Could not locate the Wheels framework source." The new `checkFrameworkSourceBundled` check walks the same search paths as `Module.cfc`'s `resolveFrameworkSource()` and reports a CRITICAL issue when none resolve, replacing the misleading `wheels new` recommendation with guidance to reinstall or set `WHEELS_FRAMEWORK_PATH`.
- `wheels new` framework-not-found error now links to the real guides page (`/v4-0-0-snapshot/start-here/installing/`) instead of a 404 (`/docs/getting-started`), and mentions Homebrew/Chocolatey packaging explicitly so users can tell the difference between "I'm in the wrong directory" and "my install is incomplete."
- `PackageLoader` now enforces `wheelsVersion` constraints from `package.json`. Packages whose constraint is not satisfied by the running Wheels version are skipped with a warning and recorded in `failedPackages`, preventing silent API incompatibility when a package built for an older major version lands in `vendor/`. Dev builds (unstamped `@build.version@`) remain permissive so local development doesn't break. (#2231)
- `wheels doctor` mixin-collision scan now honors per-method `mixin="..."` attributes (including `mixin="none"`), follows each package's in-package `extends` chain to pick up inherited methods, and strips block comments so function-like text inside docblocks no longer produces false-positive collisions. Runtime detection in `PackageLoader.$collectMixins` remains authoritative; this brings the pre-boot `wheels doctor` visibility pass closer to runtime semantics. (#2260)
- `wheels routes`, `reload`, `test`, `console`, `migrate`, `seed`, `db status`, `db version`, and `generate admin` now exit non-zero when no Wheels dev server is running. Previously these commands printed a red diagnostic but returned `""`, producing exit 0 — MCP clients and shell automation couldn't distinguish "succeeded with no output" from "server down, nothing ran". A shared `$requireRunningServer()` helper now throws a typed `Wheels.ServerNotRunning` exception that LuCLI's `ExecutionExceptionHandler` maps to exit 1. (#2229)
- Legacy CommandBox `wheels g app` now scaffolds a 4.0 app by default — the `wheels-base-template` default was pinned at `@^3.1.0`, so `box install wheels-cli && wheels g app myapp` produced a 3.x scaffold at 4.0 GA. Updated default (and the `WheelsBaseTemplate` shortcut + wizard default selection) to `@^4.0.0`, fixed the stale "Default is Bleeding Edge" docstring, and added a deprecation banner pointing users at LuCLI's `wheels new`. (#2227)
- `changeColumn` on SQLite now works by implementing the SQLite-standard recreate-table pattern in `SQLiteMigrator`. Previously, SQLite migrations inherited MySQL's `ALTER TABLE ... CHANGE` syntax from `Abstract.cfc` and failed with `near "CHANGE": syntax error`. The migrator's `$execute` now accepts an array of statements so adapters can return multi-step DDL. v1 limitations: foreign-key constraints declared inline on `CREATE TABLE` and triggers are not preserved across the recreate. (#2207)
- Framework-internal browser-test fixture controllers, views, and the `/_browser/*` routes no longer leak into application-level files. Moved from `app/controllers/BrowserTest*.cfc`, `app/views/browsertest*/`, and `config/routes.cfm` into `vendor/wheels/public/browser-fixtures/`, auto-mounted by `$lockedLoadRoutes` when environment is `testing` or `development` and the new opt-in setting `loadBrowserTestFixtures=true` is set. Apps upgrading from a 4.0 snapshot that had custom `/_browser/*` routes must opt in explicitly or re-declare them in `config/routes.cfm`. (#2135, #2138)
- Stray `app/mailers/UserNotificationsMailer.cfc` demo removed from the framework repo root (byte-identical copies remain in the example apps under `examples/tweet/` and `examples/starter-app/`). (#2138)
- View lookup after `renderText()` / `renderWith()` no longer breaks subsequent partial rendering (#1991)
- Scaffolded apps from `wheels new` now boot correctly (#2096)
- `wheels stats` crash on Lucee 7 — private `sprintf()` helper called `Left(result, 0)` when the format string started with a placeholder. Lucee 7 throws where Lucee 6 returned empty silently. Added a ternary guard per the project's cross-engine compatibility pattern.
- CockroachDB primary key uses `unique_rowid()` instead of `SERIAL` (#1986)
- CockroachDB SQL generation fixes and soft-fail removed from test matrix (#1999)
- CockroachDB `RETURNING` clause identity select (#1993)
- `$canonicalize` catches `IllegalArgumentException` for malformed percent-encoded sequences (#2006)
- Base template build no longer fails on `vendor/.keep` gitignore negation (#1994)
- Adobe Oracle coercion preserved after adapter module refactor (#2030, #2031)
- Engine adapter startup + cross-engine compatibility fixes across Lucee/Adobe/BoxLang (#2028)
- Enum scope WHERE clauses escape single quotes correctly (#2023)
- Numerous CLI, docker, installer, and documentation fixes landed across ~25 PRs not itemized here; see `git log v3.0.0+33..HEAD --merges` for the full list.

### Security

This release includes 40+ security-hardening PRs. Key themes:

- **SQL injection defenses** — QueryBuilder property + operator validation (#2025); ORDER BY clause hardening (#2026); `$quoteValue()` single-quote escaping (#2033); scope handler argument sanitization and blacklist expansion (#2043, #2045, #2061, #2070, #2090); geography property / WKT handling (#2044, #2055); enum scope WHERE clauses (#2056, #2070); `include` param in UPDATE queries (#2047); index hints via `$indexHint` (#2058).
- **Path traversal** — partial template rendering (#2071); `guideImage` endpoint (#2037); MCP documentation reader (#2049, #2062); encoded-bypass attempts (#2089).
- **Session, cookie, CSRF** — SameSite attribute on CSRF cookie (#2035); auto-generated CSRF encryption key when empty (#2054); session fixation prevention on login (#2034); open-redirect prevention in `redirectTo()` (#2038); CSRF key enforced in production (#2079).
- **Console & reload endpoints** — `consoleeval` POST-only + robust IPv6 + Content-Type checks (#2059); rate limiting and constant-time comparison on reload (#2077); hash-based reload password comparison (#2022); hardened console REPL endpoint (#2046).
- **CORS middleware** — wildcard → deny-all default (#2039); wildcard+credentials rejected (#2053); CORS + CSRF cookie defaults hardened (#2027).
- **Rate limiter** — memory exhaustion and IP spoofing mitigations (#2041, #2048, #2080); fail-closed on lock timeout (#2069); proxy strategy default changed to `last` (#2088).
- **SSE** — newline injection prevention in event fields and data (#2051).
- **MCP endpoint** — auth gate + input validation (#2050); command injection blocklist replaced with structural allowlist (#2083); CSRNG session tokens (#2087); exception detail suppression (#2072); port validation (#2075); unnecessary CORS headers removed (#2074).
- **XSS (pagination)** — HTML entity encoding bypass (#2057); `prependToPage` / `anchorDivider` / `appendToPage` sanitization (#2042, #2060).
- **JWT** — algorithm claim validation to prevent algorithm confusion (#2079); constant-time signature verification (#2086).
- **CLI shell argument validation** — deploy command sanitization (#2068, #2073); quote blocking and box fallback fix (#2073); command injection in `db shell` (#2040).
- **Public GUI production gate** — `/wheels/*` routes (`info`, `routes`, `testbox`, `runner`, `consoleeval`, `migrator`, `build`, etc.) now hard-abort with HTTP 404 in `production` even when a developer has explicitly set `enablePublicComponent=true`. The dispatch-layer gate also returns 404 with a `Not Found` body instead of a silent blank HTTP 200, so the surface can no longer be fingerprinted. Only `index()` (the congratulations page) remains respect-the-toggle, so dev/testing ergonomics are unchanged. (#2233)
- **Known security limitations** documented for operators (#2078).

---


# [3.0.0](https://github.com/wheels-dev/wheels/releases/tag/v3.0.0) => 2026-01-10

**Wheels 3.0.0 - Stable Release**

This is the first stable release of Wheels 3.0, featuring the rebrand from CFWheels to Wheels and major architecture improvements.

## 🎉 Major Changes in 3.0.0

### Rebrand: CFWheels → Wheels
- Project renamed from "CFWheels" to "Wheels"
- New domain: wheels.dev (from cfwheels.org)
- New GitHub organization: wheels-dev/wheels (from cfwheels/cfwheels)

### Architecture Changes
- **New Project Structure**: Wheels core moved outside app root for cleaner separation
- **Updated Mappings**: Application.cfm paths restructured for better organization
- **CLI Enhancements**: New `wheels` CLI tool with enhanced commands
  - `wheels init` - Initialize new Wheels projects with Docker support
  - `wheels env setup` - Environment configuration and switching
  - `wheels db create/drop` - Database management with Oracle support
- **macOS Installer**: Complete macOS installer package with automated setup
- **VSCode Extension API**: Enhanced API for better IDE integration

### Model Enhancements
- **ignoreColumns()**: New model config method to exclude columns from mapping
- **Improved Model Initialization**: Better race condition handling with automatic recovery
- **Performance Improvements**: Significant findAll() performance optimizations
- **Query Enhancements**: Native query returnType support
- **Calculated Properties**: Fixed invalidation issues for better reliability

### View Enhancements
- **paginationLinks()**: Enhanced to set active class on parent elements

### Testing & Development
- **Rewritten TestUI**: Modern Vue-based test runner interface
- **Database Support**: Updated to latest versions of MySQL, PostgreSQL, SQL Server
- **Oracle Support**: Full Oracle database support in CLI commands
- **Migration System**: Updated null property handling (null → allowNull)

### Bug Fixes
- Fixed model datasource bugs
- Fixed updateAll() missing JOIN statements with include argument
- Fixed checkbox bugs when checkedValue is not true
- Fixed ambiguous column names using wheels alias
- Fixed duplicate component issues
- Fixed default route handling
- Fixed numeric primary key return values
- Fixed afterFind callback in findAll for structs
- Fixed reload password check for URL IP exceptions

### Documentation
- Extensive guide updates and improvements
- Added WHERE clause nested query limitations
- Updated beginner tutorials
- Added ignored columns documentation
- Spelling and grammar fixes throughout
- Test framework functions added to documentation

### Testing Infrastructure
- Added Lucee 6 and 7 support
- Added Adobe 2021, 2023, 2025 support
- Updated to Docker Compose v2 syntax
- Enhanced GitHub Actions testing matrix

### Potentially Breaking Changes
⚠️ **Important**: Review these changes before upgrading from 2.x

- **Project Structure**: Wheels core location changed - requires Application.cfm updates
- **Mappings**: New mapping structure in Application.cfm
- **CLI Commands**: New command syntax for database operations
- **Dependencies**: Updated WireBox (^7.0.0) and TestBox (^6.0.0) requirements

---

## Detailed Changes

### CLI Enhancements
- PR-1764-Oracle database support for db create and drop commands [#1764](https://github.com/wheels-dev/wheels/pull/1764) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1760-CLI parameter improvements and required attribute updates [#1760](https://github.com/wheels-dev/wheels/pull/1760) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1755-CLI test commands parameter updates and guides [#1755](https://github.com/wheels-dev/wheels/pull/1755) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1753-CLI commands parameters development and guides updates [#1753](https://github.com/wheels-dev/wheels/pull/1753) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1751-CLI generate test command implementation [#1751](https://github.com/wheels-dev/wheels/pull/1751) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1748-CLI commands parameters development enhancements [#1748](https://github.com/wheels-dev/wheels/pull/1748) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1746-CLI commands parameters development updates [#1746](https://github.com/wheels-dev/wheels/pull/1746) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1743-Fix wheels env setup command base parameter and comprehensive documentation [#1743](https://github.com/wheels-dev/wheels/pull/1743) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1741-CLI commands parameters development improvements [#1741](https://github.com/wheels-dev/wheels/pull/1741) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1737-CLI parameters updates in init and dbmigrate create commands [#1737](https://github.com/wheels-dev/wheels/pull/1737) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1734-CLI JDBC connection verification function without actual DB name [#1734](https://github.com/wheels-dev/wheels/pull/1734) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1732-CLI guides updated with fixes based on post-testing issues [#1732](https://github.com/wheels-dev/wheels/pull/1732) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1727-Fix Wheels plugin management commands and documentation [#1727](https://github.com/wheels-dev/wheels/pull/1727) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1720-CLI test watch command implementation [#1720](https://github.com/wheels-dev/wheels/pull/1720) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1718-Add resolveTestDirectory function and update TestBox CLI guides [#1718](https://github.com/wheels-dev/wheels/pull/1718) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1712-CLI runner.cfm updated with new logic [#1712](https://github.com/wheels-dev/wheels/pull/1712) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1710-CLI update generate test command [#1710](https://github.com/wheels-dev/wheels/pull/1710) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1709-CLI removed extra arguments and updated guides [#1709](https://github.com/wheels-dev/wheels/pull/1709) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1706-CLI test run command implementation [#1706](https://github.com/wheels-dev/wheels/pull/1706) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1698-Wheels CLI fixes and improvements [#1698](https://github.com/wheels-dev/wheels/pull/1698) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1694-Enable parameter support for config and env commands [#1694](https://github.com/wheels-dev/wheels/pull/1694) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1691-Wheels CLI fixes and enhancements [#1691](https://github.com/wheels-dev/wheels/pull/1691) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1690-Add CLI command guides for wheels get settings/environment and clean commands [#1690](https://github.com/wheels-dev/wheels/pull/1690) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1687-Wheels CLI fixes and updates [#1687](https://github.com/wheels-dev/wheels/pull/1687) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1683-Wheels CLI fixes and improvements [#1683](https://github.com/wheels-dev/wheels/pull/1683) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1674-Wheels CLI guides updated with known issues [#1674](https://github.com/wheels-dev/wheels/pull/1674) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1667-Wheels CLI guides updates [#1667](https://github.com/wheels-dev/wheels/pull/1667) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1660-Fix bugs in multiple CLI commands [#1660](https://github.com/wheels-dev/wheels/pull/1660) - [Zain Ul Abideen](https://github.com/zainforbjs)

### BoxLang Compatibility
- PR-1705-BoxLang version upgrade to 1.5 [#1705](https://github.com/wheels-dev/wheels/pull/1705) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1695-Add BoxLang support for Oracle [#1695](https://github.com/wheels-dev/wheels/pull/1695) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1684-BoxLang compatibility with 1.4.x and PostgreSQL [#1684](https://github.com/wheels-dev/wheels/pull/1684) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1676-BoxLang compatibility documentation [#1676](https://github.com/wheels-dev/wheels/pull/1676) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1662-BoxLang support documentation updates [#1662](https://github.com/wheels-dev/wheels/pull/1662) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1659-Add BoxLang compatibility support [#1659](https://github.com/wheels-dev/wheels/pull/1659) - [Zain Ul Abideen](https://github.com/zainforbjs)

### Oracle Support
- PR-1769-Oracle database support [#1769](https://github.com/wheels-dev/wheels/pull/1769) - [Zain Ul Abideen](https://github.com/zainforbjs)

### VSCode Extension
- PR-1768-VSCode extension API function description updates [#1768](https://github.com/wheels-dev/wheels/pull/1768) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1750-VSCode extension upgrades and enhancements [#1750](https://github.com/wheels-dev/wheels/pull/1750) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1747-Fix code snippets suggestion issue [#1747](https://github.com/wheels-dev/wheels/pull/1747) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1745-API documentation extension for VSCode [#1745](https://github.com/wheels-dev/wheels/pull/1745) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1742-VSCode extension updates [#1742](https://github.com/wheels-dev/wheels/pull/1742) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1729-VSCode extension changelog update for v1.0.3 [#1729](https://github.com/wheels-dev/wheels/pull/1729) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1726-VSCode extension changelog entry for v1.0.2 [#1726](https://github.com/wheels-dev/wheels/pull/1726) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1724-VSCode extension changelog entry for v1.0.1 [#1724](https://github.com/wheels-dev/wheels/pull/1724) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1721-VSCode extension function front look description update [#1721](https://github.com/wheels-dev/wheels/pull/1721) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1711-Add VSCode extension for Wheels [#1711](https://github.com/wheels-dev/wheels/pull/1711) - [Zain Ul Abideen](https://github.com/zainforbjs)

### Installer & Tooling
- PR-1767-macOS installer update with .dmg file [#1767](https://github.com/wheels-dev/wheels/pull/1767) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1765-Complete macOS installer package with automated setup [#1765](https://github.com/wheels-dev/wheels/pull/1765) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1739-Add Wheels framework installers for Windows [#1739](https://github.com/wheels-dev/wheels/pull/1739) - [Zain Ul Abideen](https://github.com/zainforbjs)

### Build & Release Process
- PR-1758-Rebrand CFWheels to Wheels for 3.0.0 release [#1758](https://github.com/wheels-dev/wheels/pull/1758) - [Peter Amiri](https://github.com/bpamiri)
- PR-1757-Improve release workflow and prepare for 3.0.0 release [#1757](https://github.com/wheels-dev/wheels/pull/1757) - [Peter Amiri](https://github.com/bpamiri)
- PR-1754-Update docs-sync.yml workflow [#1754](https://github.com/wheels-dev/wheels/pull/1754) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1719-Update wheels path in build configuration [#1719](https://github.com/wheels-dev/wheels/pull/1719) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1699-Fix build release button [#1699](https://github.com/wheels-dev/wheels/pull/1699) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1673-Release starter app to ForgeBox [#1673](https://github.com/wheels-dev/wheels/pull/1673) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1672-Check contents for build-wheels-starterApp folder [#1672](https://github.com/wheels-dev/wheels/pull/1672) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1671-Push starter app to ForgeBox [#1671](https://github.com/wheels-dev/wheels/pull/1671) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1669-Fix starter app issues [#1669](https://github.com/wheels-dev/wheels/pull/1669) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1668-Sync images from docs to wheels.dev [#1668](https://github.com/wheels-dev/wheels/pull/1668) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1666-Update snapshot.yml workflow [#1666](https://github.com/wheels-dev/wheels/pull/1666) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1665-Docs sync with wheels.dev [#1665](https://github.com/wheels-dev/wheels/pull/1665) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1664-ForgeBox release fix [#1664](https://github.com/wheels-dev/wheels/pull/1664) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1663-CLI ForgeBox release fix [#1663](https://github.com/wheels-dev/wheels/pull/1663) - [Zain Ul Abideen](https://github.com/zainforbjs)

### TestBox/Testing Infrastructure
- PR-1759-Update TestBox version to 6.0 and update file names [#1759](https://github.com/wheels-dev/wheels/pull/1759) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1744-Insert Wheels functions in TestBox scope [#1744](https://github.com/wheels-dev/wheels/pull/1744) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1728-Bump vite from 6.3.5 to 6.3.6 in testui [#1728](https://github.com/wheels-dev/wheels/pull/1728) - [dependabot](https://github.com/dependabot)
- PR-1749-Bump tar-fs from 3.1.0 to 3.1.1 in testui [#1749](https://github.com/wheels-dev/wheels/pull/1749) - [dependabot](https://github.com/dependabot)
- PR-1725-Fix scope resolution for plugins using WireBox in tests [#1725](https://github.com/wheels-dev/wheels/pull/1725) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1717-Add test suite for $dbinfo() function [#1717](https://github.com/wheels-dev/wheels/pull/1717) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1703-Fix randomly failing test case on GitHub Actions [#1703](https://github.com/wheels-dev/wheels/pull/1703) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1702-Fix for issue #1022 Docker GitHub workflow [#1702](https://github.com/wheels-dev/wheels/pull/1702) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1689-Update to run legacy tests in Wheels 3.0 [#1689](https://github.com/wheels-dev/wheels/pull/1689) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1688-Move TestBox folder [#1688](https://github.com/wheels-dev/wheels/pull/1688) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1680-Add legacy test buttons to debug console [#1680](https://github.com/wheels-dev/wheels/pull/1680) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1675-Update app level testing process [#1675](https://github.com/wheels-dev/wheels/pull/1675) - [Zain Ul Abideen](https://github.com/zainforbjs)

### Architecture Changes
- PR-1735-Add MCP (Model Context Protocol) integration to Wheels CLI [#1735](https://github.com/wheels-dev/wheels/pull/1735) - [Peter Amiri](https://github.com/bpamiri)
- PR-1679-Get plugins from root directory [#1679](https://github.com/wheels-dev/wheels/pull/1679) - [Zain Ul Abideen](https://github.com/zainforbjs)

### Controller Enhancements

### Model Enhancements
- PR-1326-ignoreColumns model config method [#1326](https://github.com/cfwheels/cfwheels/pull/1326) - [Adam Chapman](https://github.com/chapmandu)
- PR-1568-issue #432 improved model initialization to handle race conditions with better error handling and automatic recovery [#1568](https://github.com/wheels-dev/wheels/pull/1568) - [Zain Ul Abideen](https://github.com/zainforbjs)
- **SQLite Support**: Added full support for SQLite database adapter with automatic datetime conversion to ISO 8601 text format, proper type mapping, and comprehensive test coverage across Lucee, Adobe ColdFusion, and BoxLang

### View Enhancements

### Bug Fixes
- PR-1327-issue #1319 model datasource bug [#1327](https://github.com/cfwheels/cfwheels/pull/1327) - [Adam Chapman](https://github.com/chapmandu)
- PR-1360-updateAll() is missing JOIN statement(s) when passing a value for the include argument [#1360](https://github.com/cfwheels/cfwheels/pull/1360) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1752-Adobe ColdFusion 2025 compatibility [#1752](https://github.com/wheels-dev/wheels/pull/1752) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1756-Update H2 driver to latest version [#1756](https://github.com/wheels-dev/wheels/pull/1756) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1763-Update databases to latest versions [#1763](https://github.com/wheels-dev/wheels/pull/1763) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1762-Update null to allowNull in migrations [#1762](https://github.com/wheels-dev/wheels/pull/1762) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1761-Update cfwheels to wheels and fix container names [#1761](https://github.com/wheels-dev/wheels/pull/1761) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1740-Update argument name for migrator functions [#1740](https://github.com/wheels-dev/wheels/pull/1740) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1738-Remove use of findBySql function as it does not exist [#1738](https://github.com/wheels-dev/wheels/pull/1738) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1731-Remove duplicate test command menu items from side menu [#1731](https://github.com/wheels-dev/wheels/pull/1731) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1730-Optimize ListGetAt loops across framework for significant performance improvement [#1730](https://github.com/wheels-dev/wheels/pull/1730) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1722-Add local prefix to variable [#1722](https://github.com/wheels-dev/wheels/pull/1722) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1704-Fix URL rewrite off issues [#1704](https://github.com/wheels-dev/wheels/pull/1704) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1700-Fix missing icons [#1700](https://github.com/wheels-dev/wheels/pull/1700) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1697-Update test icons [#1697](https://github.com/wheels-dev/wheels/pull/1697) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1693-Update migrator table name [#1693](https://github.com/wheels-dev/wheels/pull/1693) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1692-Update cfwheels to wheels branding [#1692](https://github.com/wheels-dev/wheels/pull/1692) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1682-Update tag format to script format [#1682](https://github.com/wheels-dev/wheels/pull/1682) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1681-Fix missing mail part in email content [#1681](https://github.com/wheels-dev/wheels/pull/1681) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1766-**SQLite Datetime Compatibility**: Fixed issue where SQLite would reject JDBC timestamp literals by implementing automatic conversion to ISO 8601 text format in the SQLite adapter
- PR-1766-**SQLite Locking on Adobe ColdFusion**: Addressed intermittent SQLITE_LOCKED errors during migrations by skipping foreign key enumeration that triggered metadata queries with lingering file locks

### Miscellaneous
- PR-1316-Feature/fix testui container [#1316](https://github.com/cfwheels/cfwheels/pull/1316) - [Peter Amiri](https://github.com/bpamiri)
- PR-1328-Backport datasource changes to develop branch [#1328](https://github.com/cfwheels/cfwheels/pull/1328) - [Peter Amiri](https://github.com/bpamiri)
- PR-1329-use github build vars to remove the hardcoded version number [#1329](https://github.com/cfwheels/cfwheels/pull/1329) - [Peter Amiri](https://github.com/bpamiri)
- PR-1317-Rewrite the Vue based TestUI app [#1317](https://github.com/cfwheels/cfwheels/pull/1317) - [Zain Ul Abideen](https://github.com/zainforbjs)
- **SQLite Test Suite**: Added SQLite to the continuous integration test matrix for Lucee, Adobe ColdFusion, and BoxLang with comprehensive migrator and model tests

### Guides
- PR-1304-Update beginner-tutorial-hello-database.md [#1304](https://github.com/cfwheels/cfwheels/pull/1304) - [MvdO79](https://github.com/MvdO79)
- PR-1305-Update beginner-tutorial-hello-database.md [#1305](https://github.com/cfwheels/cfwheels/pull/1305) - [MvdO79](https://github.com/MvdO79)
- PR-1308-Added: "Nested queries not allowed" in WHERE clause documentation [#1308](https://github.com/cfwheels/cfwheels/pull/1308) - [MvdO79](https://github.com/MvdO79)
- PR-1313-Spelling checks [#1313](https://github.com/cfwheels/cfwheels/pull/1313) - [MvdO79](https://github.com/MvdO79)
- PR-1323-Update guides with description of the templates directory [#1323](https://github.com/cfwheels/cfwheels/pull/1323) - [MvdO79](https://github.com/MvdO79)
- PR-1350-Update documentation for  Reading Rrecords [#1350](https://github.com/cfwheels/cfwheels/pull/1350) - [MvdO79](https://github.com/MvdO79)
- PR-1355-Add examples for IgnoredColumns attribute by creating ignoredcolumns.txt [#1355](https://github.com/cfwheels/cfwheels/pull/1355) - [MvdO79](https://github.com/MvdO79)
- PR-1736-Update use of ORM functions in claude.md files [#1736](https://github.com/wheels-dev/wheels/pull/1736) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1733-Update md files with clear arguments [#1733](https://github.com/wheels-dev/wheels/pull/1733) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1701-Update guides for Docker instructions [#1701](https://github.com/wheels-dev/wheels/pull/1701) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1686-Documentation updates for datasources [#1686](https://github.com/wheels-dev/wheels/pull/1686) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1685-Testing application documentation [#1685](https://github.com/wheels-dev/wheels/pull/1685) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1661-Update CONTRIBUTING.md [#1661](https://github.com/wheels-dev/wheels/pull/1661) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1766-**SQLite Documentation**: Added comprehensive guide for using SQLite with Wheels, covering setup, configuration, data types, datetime handling, migrations, associations, testing strategies, performance optimization, and troubleshooting

### Potentially Breaking Changes
- PR-1240-Feature/move wheels outside the app root and make changes to mappings [#1240](https://github.com/cfwheels/cfwheels/pull/1240) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1310-update paths in application.cfm [#1310](https://github.com/cfwheels/cfwheels/pull/1310) - [Peter Amiri](https://github.com/bpamiri)
- PR-1314-Added some missing mappings [#1314](https://github.com/cfwheels/cfwheels/pull/1314) - [Zain Ul Abideen](https://github.com/zainforbjs)

---

# [2.5.0](https://github.com/cfwheels/cfwheels/releases/tag/v2.5.0) => 2023.11.01

<!-- ### Controller Enhancements -->

### Model Enhancements
- PR-1183-Allow datasource argument in finders [#1183](https://github.com/cfwheels/cfwheels/pull/1183) - [Adam Chapman]
- PR-1201-Issue #929 validate not nullable columns with default [#1201](https://github.com/cfwheels/cfwheels/pull/1201) - [Adam Chapman]
- PR-1202-Remove old oracle test workaround [#1202](https://github.com/cfwheels/cfwheels/pull/1202) - [Adam Chapman]
- PR-1205-issue-1182-adds-simplelock-to-sql-caching [#1205](https://github.com/cfwheels/cfwheels/pull/1205) - [Adam Chapman]
- PR-1222-Findall() performance bottleneck [#1222](https://github.com/cfwheels/cfwheels/pull/1222) - [Adam Chapman]
- PR-1223-refactor-queryCallback-with-inbuilt-query-functions [#1223](https://github.com/cfwheels/cfwheels/pull/1223) - [Adam Chapman]
- PR-1226-Invalid column not throwing exception in select argument [#1226](https://github.com/cfwheels/cfwheels/pull/1226) - [Zain Ul Abideen]
- PR-1265-improve-performance-refactor-out-listfind [#1265](https://github.com/cfwheels/cfwheels/pull/1265) -  [Adam Chapman]
- PR-1260-Adds support for native query returnType [#1260](https://github.com/cfwheels/cfwheels/pull/1260) - [Adam Chapman]
- PR-1249-Removed the original IF/ELSE condition that invalidates calculated props and added condition [#1240](https://github.com/cfwheels/cfwheels/pull/1249) - [Zain Ul Abideen]

### View Enhancements
- PR-1254-issue 908 enable paginationLinks() to set active class on parent [#1254](https://github.com/cfwheels/cfwheels/pull/1254) - [Zain Ul Abideen]

### Bug Fixes
- PR-1227-Return a numeric value if the primary key is Numeric [#1227](https://github.com/cfwheels/cfwheels/pull/1227) - [Zain Ul Abideen]
- PR-1257-Checkbox bug when checkedvalue is not true [#1257](https://github.com/cfwheels/cfwheels/pull/1257) - [Adam Chapman]
- PR-1246-set the default route if it is not passed in the function [#1246](https://github.com/cfwheels/cfwheels/pull/1246) - [Zain Ul Abideen]
- PR-1256-issue 889 unable to duplicate component [#1256](https://github.com/cfwheels/cfwheels/pull/1256) - [Zain Ul Abideen]
- PR-1253-Issue 580 select ambiguous column name using the wheels alias [#1253](https://github.com/cfwheels/cfwheels/pull/1253) - [Zain Ul Abideen]
- PR-1245-Added afterFind callback hook in the findAll function in case of structs [#1245](https://github.com/cfwheels/cfwheels/pull/1245) - [Zain Ul Abideen]
- PR-1302-Check for Reload Password when setting a url IP exception [#1302](https://github.com/cfwheels/cfwheels/pull/1302) - Peter Amiri

### Miscellaneous
- PR-1175-restoreTestRunnerApplicationScope setting [#1175](https://github.com/cfwheels/cfwheels/pull/1175) - [Adam Chapman]
- PR-1176-fix text in core readme file [#1176](https://github.com/cfwheels/cfwheels/pull/1176) - [Per Djurner]
- PR-1177-fix text in base template readme file [#1177](https://github.com/cfwheels/cfwheels/pull/1177) - [Per Djurner]
- PR-1178-fix text in default template file [#1178](https://github.com/cfwheels/cfwheels/pull/1178) - [Per Djurner]
- PR-1185-adds-root-docker-volume [#1185](https://github.com/cfwheels/cfwheels/pull/1185) - [Adam Chapman]
- PR-1200-Update the docker-compose command to docker compose v2 syntax [#1200](https://github.com/cfwheels/cfwheels/pull/1200/) - [Adam Chapman, Peter Amiri]
- PR-1204-Add Lucee 6 to test matrix on local Docker test suite [#1204](https://github.com/cfwheels/cfwheels/pull/1204/) - [Peter Amiri]
- PR-1203-ensure testing params maintained [#1203](https://github.com/cfwheels/cfwheels/pull/1203) - [Adam Chapman]
- PR-1228-Adding addClass attribute in the function textField [#1228](https://github.com/cfwheels/cfwheels/pull/1228) - [Zain Ul Abideen]
- PR-1230-Add Adobe 2021 Support to local Docker and GitHub Actions testing - [#1230](https://github.com/cfwheels/cfwheels/pull/1230) - Peter Amiri
- PR-1264-update Lucee 6 version used for tests to latest [#1264](https://github.com/cfwheels/cfwheels/pull/1264) - [Zac Spitzer -  * *New Contributor* *]
- PR-1241-Fix spelling and remove whitespace from link [#1241](https://github.com/cfwheels/cfwheels/pull/1241) - [John Bampton]
- PR-1247-show the current git branch in the debug layout [#1247](https://github.com/cfwheels/cfwheels/pull/1247) - [Michael Diederich]
- PR-1250-Added test framework functions in the docs [#1250](https://github.com/cfwheels/cfwheels/pull/1250) - [Zain Ul Abideen]
- PR-1255-issue 1179 Downloaded the CDN files and changed paths in files [#1255](https://github.com/cfwheels/cfwheels/pull/1255) - [Zain Ul Abideen]

### Guides
- PR-1198-Documentation-fixes [#1198](https://github.com/cfwheels/cfwheels/pull/1198) - [Adam Chapman]

<!-- ### Potentially Breaking Changes -->

----

# [2.4.0](https://github.com/cfwheels/cfwheels/releases/tag/v2.4.0%2B1) => 2022.08.17

<!-- ### Controller Enhancements -->

<!-- ### Model Enhancements -->

<!-- ### View Enhancements -->

### Bug Fixes
- issue-1091-wheels-paths-in-error-template [#1091](https://github.com/cfwheels/cfwheels/issues/1091) - [Adam Chapman]
- issue-1082-validations should not trim properties [#1082](https://github.com/cfwheels/cfwheels/issues/1082) - [Adam Chapman]
- issue-1088-Adds SQL parsing regex tweak which correctly handles whitespace [#1088](https://github.com/cfwheels/cfwheels/issues/1088) - [Adam Chapman, Adam Cameron]

### Miscellaneous
- Adds cfformat ignore marker comments around core "view" cfm files that contain html markup - [Adam Chapman]
- Adds the ability to scroll large items horizontally in the test runner UI [#1130](https://github.com/cfwheels/cfwheels/pull/1130) - [Adam Chapman]
- Fix cfformat ignore markers [#1129](https://github.com/cfwheels/cfwheels/pull/1129) - [Adam Chapman]
- Enable finder model methods to returnAs "sql", mainly for debugging [#1141](https://github.com/cfwheels/cfwheels/pull/1141) - [Adam Chapman]
- Show the Test Runner buttons in the CFWheels GUI on the Package List screen allowing the developer to run the entire test suite instead of one package at a time. - [Peter Amiri]
- The Base Template now contains all necessary placeholders for the CLI to interact with the application and be able to inject code properly. - [Peter Amiri]
- By default the Core tests will run in the application datasource, but the developer can setup a different database for running the Core tests to ensure there is no side effects from running the tests. If you do end up setting a different database for the coreTestDatasourceName, make sure to reload your application after running the Core tests. - [Peter Amiri]
- Fix two broken links in README. [#1150] - [John Bampton -  * *New Contributor* *]
- Fix spelling [#1151][#1158] - [John Bampton -  * *New Contributor* *]
- Add .env parser to parse .env files and add the properties found in the file to this.env scope. [#1157](https://github.com/cfwheels/cfwheels/pull/1157) - [Peter Amiri]
- Update the local test suite to supported ARM architecture docker images to make the suite compatible with the Apple Silicon Macs. [#1143](https://github.com/cfwheels/cfwheels/pull/1143) - [Peter Amiri]

### Guides
- Fix broken links throughout the guides. - [Peter Amiri]
- Fixed mailto link in CONTRIBUTING.md [#1123](https://github.com/cfwheels/cfwheels/pull/1123) - [Coleman Sperando * *New Contributor* *]
- Fix test guides examples [#1125](https://github.com/cfwheels/cfwheels/pull/1125) [Adam Chapman]
- Fix typos in the guides [#1161](https://github.com/cfwheels/cfwheels/pull/1161) [Adam Chapman]

<!-- ### Potentially Breaking Changes -->

----

# [2.3.0](https://github.com/cfwheels/cfwheels/releases/tag/v2.3.0) => 2020.05.11

This release finalizes the 2.3.0 release and doesn't include any new enhancements or bug fixes. Below is the change log from the 2.3.0.rc.1 release.

### View Enhancements
- Adds association error support via `includeAssociations` argument [#1080](https://github.com/cfwheels/cfwheels/issues/1080) - [Nikolaj Frey]

### Bug Fixes

- onerror handler should increase user defined requestTimeout value [#1056](https://github.com/cfwheels/cfwheels/issues/1056) - [Adam Chapman]
- deletedAt should also respect timestamp mode (UTC) [#1063](https://github.com/cfwheels/cfwheels/issues/1063) - [David Belanger]
- Fixes No output from `Debug()` usage in plugin test cases [#1061](https://github.com/cfwheels/cfwheels/issues/1063) - [Tom King]
- Development mode will now properly return a 404 status if view not found [#1067](https://github.com/cfwheels/cfwheels/issues/1067) - [Adam Cameron, Tom King]
- 404 status now properly returned without URL rewriting [#1067](https://github.com/cfwheels/cfwheels/issues/1067) - [Adam Cameron, Tom King]
- Internal Docs in ACF2018 should now not display duplicate categories [Tom King]
- Internal Docs search now resets itself properly on backspace with empty value [#982](https://github.com/cfwheels/cfwheels/issues/982) - [Brandon Shea, Tom King]
- `ValidatesConfirmationOf()` now correctly enforces prescence of confirmation property [#1070](https://github.com/cfwheels/cfwheels/issues/1070) - [Adam Cameron, Tom King]
- `resource()`/`resources()` now allows empty `only` property to utilise as non-route parent [#1083](https://github.com/cfwheels/cfwheels/issues/1083) - [Brian Ramsey]
- Handle XSS Injection in development environment - [Michael Diederich]
- Fix params bug in CLI API [#1106] - [Peter Amiri]

### Miscellaneous

- Update Docker Lucee Commandbox version to 5.2.0 - [Adam Chapman, Tom King]
- Minor internal obsolete reference to modelComponentPath removed - [Adam Chapman, Tom King]
- Minor visual fix for long migration logs overflow in modal (scroll) - [Brian Ramsey]
- Add test suite for Lucee and H2 Database to the GitHub Actions test suite. - [Peter Amiri]
- On going changes to update the H2 drivers [#1107] - [Peter Amiri]
- Fixes some syntax formatting introduced by cfformat [#1111] - [Adam Chapman]
- Minimum ColdFusion version is now ColdFusion (2018 release) Update 3 (2018,0,03,314033) / ColdFusion (2016 release) Update 10 (2016,0,10,314028) / ColdFusion 11 Update 18 (11,0,18,314030) [#923](https://github.com/cfwheels/cfwheels/issues/923) - [Michael Diederich]
- Wheels save(allowExplicitTimestamps=true) doesn't produce the expected result [#1113] - [SebastienFCT]

### Potentially Breaking Changes

- Automatic Time Stamps: the **deletedAt** column was using the server's local time for the timestamp while **createdAt** / **updatedAt** were using the timestamp selected for the timestamp mode. The default for CFWheels' timestamp mode is UTC and therefore all future **deletedAt** timestamps will be in UTC unless you've changed the default.  Please review any SQL that uses **deletedAt** for datetime comparison.

----

# [2.3.0-rc.1](https://github.com/cfwheels/cfwheels/releases/tag/v2.3.0-rc.1) => 2020.05.03

<!-- ### Controller Enhancements -->

<!-- ### Model Enhancements -->

### View Enhancements
- Adds association error support via `includeAssociations` argument [#1080](https://github.com/cfwheels/cfwheels/issues/1080) - [Nikolaj Frey]

### Bug Fixes

- onerror handler should increase user defined requestTimeout value [#1056](https://github.com/cfwheels/cfwheels/issues/1056) - [Adam Chapman]
- deletedAt should also respect timestamp mode (UTC) [#1063](https://github.com/cfwheels/cfwheels/issues/1063) - [David Belanger]
- Fixes No output from `Debug()` usage in plugin test cases [#1061](https://github.com/cfwheels/cfwheels/issues/1063) - [Tom King]
- Development mode will now properly return a 404 status if view not found [#1067](https://github.com/cfwheels/cfwheels/issues/1067) - [Adam Cameron, Tom King]
- 404 status now properly returned without URL rewriting [#1067](https://github.com/cfwheels/cfwheels/issues/1067) - [Adam Cameron, Tom King]
- Internal Docs in ACF2018 should now not display duplicate categories [Tom King]
- Internal Docs search now resets itself properly on backspace with empty value [#982](https://github.com/cfwheels/cfwheels/issues/982) - [Brandon Shea, Tom King]
- `ValidatesConfirmationOf()` now correctly enforces prescence of confirmation property [#1070](https://github.com/cfwheels/cfwheels/issues/1070) - [Adam Cameron, Tom King]
- `resource()`/`resources()` now allows empty `only` property to utilise as non-route parent [#1083](https://github.com/cfwheels/cfwheels/issues/1083) - [Brian Ramsey]
- Handle XSS Injection in development environment - [Michael Diederich]
- Fix params bug in CLI API [#1106] - [Peter Amiri]

### Miscellaneous

- Update Docker Lucee Commandbox version to 5.2.0 - [Adam Chapman, Tom King]
- Minor internal obsolete reference to modelComponentPath removed - [Adam Chapman, Tom King]
- Minor visual fix for long migration logs overflow in modal (scroll) - [Brian Ramsey]
- Add test suite for Lucee and H2 Database to the GitHub Actions test suite. - [Peter Amiri]
- On going changes to update the H2 drivers [#1107] - [Peter Amiri]
- Fixes some syntax formatting introduced by cfformat [#1111] - [Adam Chapman]
- Minimum ColdFusion version is now ColdFusion (2018 release) Update 3 (2018,0,03,314033) / ColdFusion (2016 release) Update 10 (2016,0,10,314028) / ColdFusion 11 Update 18 (11,0,18,314030) [#923](https://github.com/cfwheels/cfwheels/issues/923) - [Michael Diederich]
- Wheels save(allowExplicitTimestamps=true) doesn't produce the expected result [#1113] - [SebastienFCT]

### Potentially Breaking Changes

- Automatic Time Stamps: the **deletedAt** column was using the server's local time for the timestamp while **createdAt** / **updatedAt** were using the timestamp selected for the timestamp mode. The default for CFWheels' timestamp mode is UTC and therefore all future **deletedAt** timestamps will be in UTC unless you've changed the default.  Please review any SQL that uses **deletedAt** for datetime comparison.

----

<a name="2.2"></a>

# [2.2](https://github.com/cfwheels/cfwheels/releases/tag/v2.2.0) => 2020.11.22

### Controller Enhancements

- Added the `status` argument to all `render*()` functions to force returning a specific HTTP status code [#1025](https://github.com/cfwheels/cfwheels/issues/1025) - [Adam Chapman, Tom King]
- CORS `accessControlAllowOrigin` can now match subdomain wildcards [#1031](https://github.com/cfwheels/cfwheels/issues/1031) - [Tom King]

### Model Enhancements

- Experimental adapter for Oracle database - [Andrei B]
- Added `automaticValidations` argument to the `property` method - [Per Djurner]
- Support named second argument in `findOneBy[Property]And[Property]` and `findAllBy[Property]And[Property]` - [Per Djurner]
- Support `value` argument in `findOrCreateBy[Property]` - [Per Djurner]
- Minor fix for `full null support` - [Michael Diederich]

### View Enhancements

- Added the `required` argument to `imageTag` to suppress exceptions if using non-existent files [#979](https://github.com/cfwheels/cfwheels/issues/979) - [Adam Chapman, Michael Diederich]

### Bug Fixes

- Removed authenticity token id attribute to avoid non-unique id warnings in Chrome [#953](https://github.com/cfwheels/cfwheels/issues/953) - [Per Djurner]
- Fixes regular expression bug when using the SQL `IN` operator [#944](https://github.com/cfwheels/cfwheels/issues/944) - [Adam Chapman, Per Djurner]
- Display content in maintenance mode on newer Lucee versions [#848](https://github.com/cfwheels/cfwheels/issues/848) - [Per Djurner]
- `validatesUniquenessOf` does not respect allowBlank [#914](https://github.com/cfwheels/cfwheels/issues/914) - [Adam Chapman]
- `Wheels.RouteNotFound` Error page now escapes the `arguments.path` to prevent XSS attacks - [Michael Diederich]
- `buttonTo()` now uses `<button>` internally instead of `<input>` allowing for html in content - [#798](https://github.com/cfwheels/cfwheels/issues/798) - [Tom Sucaet, Tom King, Per Djurner]
- Minor SQL preview fix in GUI - [#992](https://github.com/cfwheels/cfwheels/issues/992) - [Brandon Shea, Tom King]

### Miscellaneous

- Added the `refresh` url parameter for auto refreshing test framework html - [#986](https://github.com/cfwheels/cfwheels/issues/986) - [Adam Chapman]
- Allow custom migrator templates by scanning the `/migrator/templates` directory - [Adam Chapman]
- Minimum Lucee 5 version is now 5.3.2.77 - Tests added - [Michael Diederich]
- Use `http_x_forwarded_proto` to determine if the application is running behind a loadbalancer that is performing SSL offloading - [Peter Amiri]
- Allow the combination of `url` and `params` arguments with `redirectTo` - [Adam Chapman]
- Fixed some variable scoping - [Michael Diederich]
- Github Actions CI Pipeline - [Adam Chapman, Tom King]
- Flash Cookie can now be disabled via `set(flashStorage="none")` [#978](https://github.com/cfwheels/cfwheels/issues/978) [Tom King]
- `processRequest()` accepts a route param -[#1030](https://github.com/cfwheels/cfwheels/issues/1030) - [Adam Chapman]
- Migration files are written with 664 mode -[#1034](https://github.com/cfwheels/cfwheels/issues/1034) - [Adam Chapman]

----

<a name="2.1"></a>

# [2.1](https://github.com/cfwheels/cfwheels/releases/tag/v2.1.0) => 2020.04.12

### Bug Fixes

- Fixed pagination order ambiguous column name exception - [#980](https://github.com/cfwheels/cfwheels/issues/#980) [Adam Chapman, Mike Lange]
- Renames findLast() to findLastOne() for lucee5.3.5+92 upwards compatibility [#988](https://github.com/cfwheels/cfwheels/issues/#988)

----

<a name="2.1.0-beta"></a>

# [2.1.0-Beta](https://github.com/cfwheels/cfwheels/releases/tag/v2.1.0-beta) => 2020.02.24

### Potentially Breaking Changes

- The new CFWheels internal GUI is more isolated and runs in it's own component: previously this was extending the developers main `Controller.cfc` which caused multiple issues. The migrator, test runner and routing GUIs have therefore all been re-written.
- The plugins system behaviour no longer chains multiple functions of the same name as this was a major performance hit. It's recommended that plugin authors check their plugins to run on 2.1
- HTTP Verb/Method switching is now no longer allowed via GET requests and must be performed via POST (i.e via `_method`)

### Model Enhancements

- Migrator now automatically manages the timestamp columns on `addRecord()` and `updateRecord()` calls - [#852](https://github.com/cfwheels/cfwheels/pull/852) [Charley Contreras]
- Migrator correctly honors CFWheels Timestamp configuration settings (`setUpdatedAtOnCreate, softDeleteProperty, timeStampMode, timeStampOnCreateProperty, timeStampOnUpdateProperty`) - [#852](https://github.com/cfwheels/cfwheels/pull/852) [Charley Contreras]
- `MSSQL` now uses `NVARCHAR(max)` instead of `TEXT` [#896](https://github.com/cfwheels/cfwheels/pull/896) [Reuben Brown]
- Allow createdAt and updatedAt to be explicitly assigned using the `allowExplicitTimestamps=true` argument - [#887](https://github.com/cfwheels/cfwheels/issues/887) - [Adam Chapman]

### Controller Enhancements

- New `set(flashAppend=true)` option allows for appending of a Flash key instead of replacing - [#855](https://github.com/cfwheels/cfwheels/pull/855) - [Tom King]
- `flashMessages()` now checks for an array of strings or just a string and outputs appropriately - [#855](https://github.com/cfwheels/cfwheels/pull/855) - [Tom King]
- `flashInsert()` can now accept a one dimensional array - [#855](https://github.com/cfwheels/cfwheels/pull/855) - [Tom King]

### Bug Fixes

- Allow uppercase table names containing reserved substrings like `OR` and `AND` - [#765](https://github.com/cfwheels/cfwheels/issues/765) [Dmitry Yakhnov, Adam Chapman]
- Calculated properties can now override an existing property - [#764](https://github.com/cfwheels/cfwheels/issues/764) [Adam Chapman, Andy Bellenie]
- Filters are now correctly called if there is more than one after filter - [#853](https://github.com/cfwheels/cfwheels/issues/853) [Brandon Shea, Tom King, Adam Chapman]
- Minor fix for duplicate debug output in the test suite - [#176](https://github.com/cfwheels/cfwheels/issues/176) [Adam Chapman, Tom King]
- Convert `handle` to a valid variable name so it doesn't break when using dot notation - [#846](https://github.com/cfwheels/cfwheels/issues/846) [Per Djurner]
- The `validatesUniquenessOf()` check now handles cases when duplicates already exist - [#480](https://github.com/cfwheels/cfwheels/issues/480) [Randall Meeker, Per Djurner]
- `validatesConfirmationOf()` now has a `caseSensitive` argument to optionally perform a case sensitive comparison - [#918](https://github.com/cfwheels/cfwheels/issues/918) [Tom King]
- `sendFile()` no longer expands an already expanded directory on ACF2016 - [#873](https://github.com/cfwheels/cfwheels/issues/873) [David Paul Belanger, Tom King, strubenstein]
- Automatic database migrations onApplicationStart now correctly reference appropriate Application scope - [#870](https://github.com/cfwheels/cfwheels/issues/870) [Tom King]
- `usesLayout()` now can be called more than once and properly respects the order called - [#891](https://github.com/cfwheels/cfwheels/issues/891) [David Paul Belanger]
- Migrator MSSQL adapter now respects `Time` and `Timestamp` Column Types - [#906](https://github.com/cfwheels/cfwheels/issues/906) [Reuben Brown]
- Automatic migrations fail on application start - [#913](https://github.com/cfwheels/cfwheels/issues/913) [Adam Chapman]
- Default `cacheFileChecking` to `true` in development mode - [Adam Chapman, Steve Harvey]
- Migrator columnNames list values are now trimmed - [#919](https://github.com/cfwheels/cfwheels/issues/#919) [Adam Chapman]
- Fixes bug when httpRequestData content is a JSON array - [#926](https://github.com/cfwheels/cfwheels/issues/#926) [Adam Chapman]
- When httpRequestData content is a JSON array, contents are now automatically added to `params._json` - [#939](https://github.com/cfwheels/cfwheels/issues/#939) [Tom King]
- Fixes bug where Migrator \$execute() always appends semi-colon - [#924](https://github.com/cfwheels/cfwheels/issues/#924) [Adam Chapman]
- Fixes bug where model createdAt property is changed upon update - [#927](https://github.com/cfwheels/cfwheels/issues/#927) [Brandon Shea, Adam Chapman]
- Fixed silent application.wheels scope exception hampering autoMigrateDatabase - [#957](https://github.com/cfwheels/cfwheels/issues/#957) [Adam Chapman, Tom King]

### Miscellaneous

- Added the ability to pass `&lock=false` in the URL for when reload requests won't work due to locking - [Per Djurner]
- Basic 302 redirects now available in mapper via `redirect` argument for `GET/PUT/PATCH/POST/DELETE` - [#847](https://github.com/cfwheels/cfwheels/issues/847) - [Tom King]
- `.[format]` based routes can now be turned off in `resources()` and `resource()` via `mapFormat=false` - [#899](https://github.com/cfwheels/cfwheels/issues/899) - [Tom King]
- `mapFormat` can now be set as a default in `mapper()` for all child `resources()` and `resource()` calls - [#899](https://github.com/cfwheels/cfwheels/issues/899) - [Tom King]
- `HEAD` requests are now aliased to `GET` requests [#860](https://github.com/cfwheels/cfwheels/issues/860) - [Tom King]
- Added the `includeFilters` argument to the `processRequest` function for skipping execution of filters during controller unit tests - [Adam Chapman]
- Added the `useIndex` argument to finders for adding table index hints [#864](https://github.com/cfwheels/cfwheels/issues/864) - [Adam Chapman]
- HTTP Verb/Method switching is now no longer allowed via `GET` requests and must be performed via `POST` [#886](https://github.com/cfwheels/cfwheels/issues/886) - [Tom King]
- CORS Header `Access-Control-Allow-Origin` can now be set either via a simple value or list in `accessControlAllowOrigin()` [#888](https://github.com/cfwheels/cfwheels/issues/888) [Tom King]
- CORS Header `Access-Control-Allow-Methods` can now be set via `accessControlAllowMethods(value)` [#888](https://github.com/cfwheels/cfwheels/issues/888) [Tom King]
- CORS Header `Access-Control-Allow-Credentials` can now be turned on via `accessControlAllowCredentials(true)`; [#888](https://github.com/cfwheels/cfwheels/issues/888) [Tom King]
- `accessControlAllowMethodsByRoute()` now allows for automatic matching of available methods for a route and sets CORS Header `Access-Control-Allow-Methods` appropriately [#888](https://github.com/cfwheels/cfwheels/issues/888) [Tom King]
- CORS Header can now be set via `accessControlAllowHeaders(value)` [#888](https://github.com/cfwheels/cfwheels/issues/888) [Tom King]
- Performance Improvement: Scanning of Models and Controllers [#917](https://github.com/cfwheels/cfwheels/issues/917) [Adam Chapman]
- Added the `authenticityToken()` function for returning the raw CSRF authenticity token [#925](https://github.com/cfwheels/cfwheels/issues/925) [Adam Chapman]
- Adds `enablePublicComponent`, `enableMigratorComponent`,`enablePluginsComponent` environment settings to completely disable those features [#926](https://github.com/cfwheels/cfwheels/issues/936) [Tom King]
- New CFWheels Internal GUI [#931](https://github.com/cfwheels/cfwheels/issues/931) [Tom King]
- `pluginRunner()` now removed in favour of 1.x plugin behaviour for performance purposes [#916](https://github.com/cfwheels/cfwheels/issues/916) [Core Team]
- Adds `validateTestPackageMetaData` environment setting for skipping test package validation on large test suites [#950](https://github.com/cfwheels/cfwheels/issues/950) [Adam Chapman]
- Added aliases for `migrator.TableDefinition` functions to allow singular variant of the `columnNames` property [#922](https://github.com/cfwheels/cfwheels/issues/922) [Sébastien FOCK CHOW THO]
- `onAbort` is now supported via `events/onabort.cfm` [#962](https://github.com/cfwheels/cfwheels/issues/962) [Brian Ramsey]

----

<a name="2.0.1"></a>

# [2.0.1](https://github.com/cfwheels/cfwheels/releases/tag/v2.0.1) => 2018.01.31

### Bug Fixes

- Fixes reload links on application test suite page - [#820](https://github.com/cfwheels/cfwheels/issues/820) [Michael Diederich]
- Set `dbname` in `cfdbinfo` calls when using custom database connection string - [#822](https://github.com/cfwheels/cfwheels/issues/822) [Per Djurner]
- Fixes `humanize()` function - [#663](https://github.com/cfwheels/cfwheels/issues/663) [Chris Peters, Per Djurner, kmd1970]
- Enables the `rel` attribute for `stylesheetlinkTag()` - [#834](https://github.com/cfwheels/cfwheels/pull/834) [Michael Diederich]
- Returning a `NULL` value from a query with NULL support enabled no longer throws an error - [#834](https://github.com/cfwheels/cfwheels/pull/834) [Michael Diederich]
- Accessing a route with incorrect verb now provides a more useful error message - [#800](https://github.com/cfwheels/cfwheels/issues/800) [Tom King]
- Fixed bug with arrays in URLs - [#836](https://github.com/cfwheels/cfwheels/issues/836) [Michael Diederich, Per Djurner]
- startFormTag now properly applies the method attribute - [#837](https://github.com/cfwheels/cfwheels/issues/837) [David Paul Belanger]
- Incompatible plugin notice now ignores patch releases unless specified - [#840](https://github.com/cfwheels/cfwheels/issues/840) [Risto, Tom King]

----

<a name="2.0.0"></a>

# [2.0.0](https://github.com/cfwheels/cfwheels/releases/tag/v2.0.0) => 2017.09.30

### Bug Fixes

- Support passing in `encode="attributes"` to `submitTag()`, `buttonTag()`, `paginationLinks()`, `checkBoxTag()`, and `checkBox()` - [#816](https://github.com/cfwheels/cfwheels/issues/816) [Per Djurner, Tom King]
- Support passing in `encode="attributes"` to date helpers - [#818](https://github.com/cfwheels/cfwheels/issues/818) [Per Djurner]

### Breaking Changes

- Support for Oracle has been dropped.

----

<a name="2.0.0-rc.1"></a>

# [2.0.0 RC 1](https://github.com/cfwheels/cfwheels/releases/tag/v2.0.0-rc.1) => 08/21/2017.08.21

### Model Enhancements

- Added global setting (`createMigratorTable`) for creating migrations table - [#796](https://github.com/cfwheels/cfwheels/issues/796) [Adam Chapman, Per Djurner]

### View Enhancements

- Use association to create automatic property labels on `belongsTo()` - [#618](https://github.com/cfwheels/cfwheels/issues/618) [Andy Bellenie, Chris Peters]
- The output of all view helpers is now encoded by default - [#777](https://github.com/cfwheels/cfwheels/issues/777) [Per Djurner]

### Controller Enhancements

- Added global setting (`allowCorsRequests`) for allowing CORS requests to go through - [#623](https://github.com/cfwheels/cfwheels/issues/623) [Chris Peters, David Belanger, Per Djurner, Tom King]

### Bug Fixes

- Support CSRF in `buttonTo()` - [#808](https://github.com/cfwheels/cfwheels/issues/808) [Per Djurner, Tom King]
- Fix encoding on `buttonTo()` - [#798](https://github.com/cfwheels/cfwheels/issues/798) [Per Djurner]
- Fix error when creating default table for migrations - [#791](https://github.com/cfwheels/cfwheels/issues/791) [Adam Chapman, Per Djurner]
- Fix so calling `usesLayout()` in `Controller.cfc` does not affect layout of internal CFWheels pages - [#793](https://github.com/cfwheels/cfwheels/issues/793) [Adam Chapman, Per Djurner]
- Fix slow performance of findAll - [#806](https://github.com/cfwheels/cfwheels/issues/806) [Andy Bellenie]

### Breaking Changes

- Minimum version when running Lucee 5 is now 5.2.1.9 (can be disabled with the `disableEngineCheck` setting).
- Minimum version when running ACF 2016 is now 2016,0,04,302561 (can be disabled with the `disableEngineCheck` setting).
- includePartial() now requires the `partial` and `query` arguments to be set (if using a query)

----

<a name="2.0.0-beta.1"></a>

# [2.0.0 Beta 1](https://github.com/cfwheels/cfwheels/releases/tag/v2.0.0-beta.1) => 2017.05.31

### Model Enhancements

- Support for passing in `select=false` to `property()` to not include a calculated property by default in SELECT clauses - [#122](https://github.com/cfwheels/cfwheels/issues/122) [Adam Chapman, Per Djurner]
- Support for setting calculated properties to a specific data type - [Per Djurner]
- Support for boolean `returnIncluded` argument in `properties()` for returning nested properties - [Adam Chapman]
- Support for calling `updateProperty()` with dynamic argument, e.g. `updateProperty(firstName="Per")` - [Per Djurner]
- Support for using boolean transaction argument, e.g. `update(transaction=false)` - [#654](https://github.com/cfwheels/cfwheels/issues/654) [Adam Chapman]
- Model instance `isPersisted()` and `propertyIsBlank()` methods - [#559](https://github.com/cfwheels/cfwheels/issues/559) [Chris Peters]
- Database Migrations (dbmigrate) now available in the core (See Breaking Changes) - [#664](https://github.com/cfwheels/cfwheels/issues/664) [Adam Chapman, Tom King, Mike Grogan]
- Databases can now be automatically migrated to the latest version on application start - [#766](https://github.com/cfwheels/cfwheels/issues/766) [Tom King]
- New `timeStampMode` setting (`"utc"`, `"local"` or `"epoch"`) for the `createdAt` and `updatedAt` columns - [Andy Bellenie]
- Allow nested transactions - [#732](https://github.com/cfwheels/cfwheels/issues/732) [Andy Bellenie]
- The `handle` argument to finders now set the variable name for the query so it's easier to find in the debug output - [Per Djurner]
- Support added for HAVING when using aggregate functions in the `where` argument - [#483](https://github.com/cfwheels/cfwheels/issues/483) [Per Djurner]
- Added support for the JSON data type in the MySQL adapter - [#759](https://github.com/cfwheels/cfwheels/issues/759) [Joel Stobart]
- Corrected mapping for text types in the MySQL adapter - [#759](https://github.com/cfwheels/cfwheels/issues/759) [Joel Stobart]
- Added global setting, `lowerCaseTableNames`, to always lower case table names in SQL statements - [Per Djurner]

### View Enhancements

- `flashMessages()` are now in default layout.cfm - [#650](https://github.com/cfwheels/cfwheels/issues/650) [Tom King]
- Added ability to override value in `textField()`, `passwordField()` and `hiddenField()` - [#633](https://github.com/cfwheels/cfwheels/issues/633) [Per Djurner, Chris Peters]
- Support for the `method` argument in `buttonTo()` helper - [#761](https://github.com/cfwheels/cfwheels/issues/761) [Adam Chapman]

### Controller Enhancements

- Support for HTTP verbs, scopes, namespaces, and resources in routes (ColdRoute) [Don Humphreys, James Gibson, Tom King]
- Support for passing in `ram://` resources to `sendFile()` - [#566](https://github.com/cfwheels/cfwheels/issues/566) [Tom King]
- Extended `sendMail()` so that it can return the text and/or html content of the email - [#122](https://github.com/cfwheels/cfwheels/issues/122) [Adam Chapman]
- `renderWith()` can now set http status codes in header with the `status` argument - [#549](https://github.com/cfwheels/cfwheels/issues/549) [Tom King]
- Cross-Site Request Forgery (CSRF) protection - [#613](https://github.com/cfwheels/cfwheels/issues/613) [Chris Peters]
- Parse JSON body and add to params struct - [Tom King, Per Djurner]

### Bug Fixes

- Fixes skipped model instantiation due to Linux file case sensitivity - [#643](https://github.com/cfwheels/cfwheels/issues/643) [Adam Chapman, Tom King]
- Avoid double redirect error when doing delayed redirects from a verification handler function - [Per Djurner]
- Fixes attempts to insert nulls for blank strings - [#654](https://github.com/cfwheels/cfwheels/issues/654) [Andy Bellenie, Per Djurner]
- Fix for using `validatePresenceOf()` with default on update - [Andy Bellenie]
- Fixes so paginated finder calls with no records include column names - [#722](https://github.com/cfwheels/cfwheels/issues/722) [Per Djurner]
- Fixes "invalid data" error when using unsigned integers in MySQL - [#768](https://github.com/cfwheels/cfwheels/issues/768) [Per Djurner]

### Plugins

- Plugins now distributed via forgebox.io [Tom King]
- Update to the plugin system to allow overriding of the same framework method multiple times - [#681](https://github.com/cfwheels/cfwheels/issues/681) [James Gibson, Tom King]
- Added ability to turn off incompatible plugin warnings from showing - [Danny Beard]
- Plugins now have any java lib/class files automatically mapped onApplicationStart [731](https://github.com/cfwheels/cfwheels/issues/731) [Andy Bellenie, Tom King]
- Plugins now read version number off their `box.json` files and are displayed in debug area [#68](https://github.com/cfwheels/cfwheels/issues/68) [Tom King]
- Plugin meta data as set in `box.json` now available in `application.wheels.pluginMeta` scope [#68](https://github.com/cfwheels/cfwheels/issues/68) [Tom King]

### Miscellaneous

- Redirect away after a reload request - [Chris Peters]
- Support checking IP in `http_x_forwarded_for` when doing maintenance mode exclusions - [Per Djurner]
- Support checking user agent string when doing maintenance mode exclusions - [Per Djurner]
- Added JUnit and JSON format test results - [Adam Chapman]
- Added empty application test directories - [Chris Peters, Adam Chapman]
- Added `beforeAll()`, `afterAll()`, `packageSetup()`, `packageTeardown()` methods to test framework #651 - [Adam Chapman]
- Added `errorEmailFromAddress` and `errorEmailToAddress` config settings - [#95](https://github.com/cfwheels/cfwheels/issues/95) [Andy Bellenie, Tony Petruzzi, Per Djurner]
- Support for passing in any "truthy" value to `assert()` in tests - [Per Djurner]
- Added `/app/` mapping pointing to the root of the application - [Per Djurner]
- Added a `processRequest()` function that simplifies testing controllers - [Per Djurner]
- Added new embedded documentation viewer/generator for JavaDoc - [#734](https://github.com/cfwheels/cfwheels/issues/734) [Tom King]
- Removes all references to Railo - [#656](https://github.com/cfwheels/cfwheels/issues/656) (Adam Chapman)
- Made uncountable and irregular words configurable - [#739](https://github.com/cfwheels/cfwheels/issues/739) [Per Djurner]
- Removed `design` mode - [Per Djurner]
- Removed `cacheRoutes` setting - [Per Djurner]
- The `cacheFileChecking` and `cacheImages` settings are now turned off in development mode - [Per Djurner]
- Added `includeErrorInEmailSubject` setting - [Per Djurner]
- Environment switching via URL can now be turned off via `allowEnvironmentSwitchViaUrl` - [#766](https://github.com/cfwheels/cfwheels/issues/766) [Tom King]

### Breaking Changes

- Minimum Lucee version is now 4.5.5.006.
- Minimum ACF version is now 10.0.23 / 11.0.12.
- Support for Railo has been dropped.
- Rewrite and config files for IIS and Apache have been removed and has to be added manually instead.
- The `events/functions.cfm` file has been moved to `global/functions.cfm`.
- The `models/Model.cfc` file should extend `wheels.Model` instead of `Wheels` (`models/Wheels.cfc` can be deleted).
- The `controllers/Controller.cfc` file should extend `wheels.Controller` instead of `Wheels` (`controllers/Wheels.cfc` can be deleted).
- The `init` function of controllers and models should now be named `config` instead.
- The global setting `modelRequireInit` has been renamed to `modelRequireConfig`.
- The global setting `cacheControllerInitialization` has been renamed to `cacheControllerConfig`.
- The global setting `cacheModelInitialization` has been renamed to `cacheModelConfig`.
- The global setting `clearServerCache` has been renamed to `clearTemplateCache`.
- The `updateProperties()` method has been removed, use `update()` instead.
- Form labels automatically generated based on foreign key properties will drop the "Id" from the end (e.g., the label for the "userId" property will be "User", not "User Id").
- Routes need to be updated to use the new routing system by calling `mapper()`.
- JavaScript arguments like `confirm` and `disable` have been removed from the link and form helper functions (use the [JS Confirm](https://github.com/perdjurner/cfwheels-js-confirm) and [JS Disable](https://github.com/perdjurner/cfwheels-js-disable) plugins to reinstate the old behaviour).
- Timestamping (`createdAt`, `updatedAt`) is now in UTC by default (set the global `timeStampMode` setting to `local` to reinstate the old behaviour).
- Blank strings in SQL are now converted to null checks (e.g. `where="x=''"` becomes `where="x IS NULL"`).
- Tags are now closed in HTML5 style (e.g. `<img src="x">` instead of `<img src="x" />`).
- The `encode` argument to `mailTo` now encodes tag content and attributes instead of outputting JavaScript.
- Class output is now dasherized (e.g. `field-with-errors` instead of `fieldWithErrors`).
- The `renderPage` function has been renamed to `renderView`.
- `dbmigrate` is now named `Migrator`
- Automatic database migrations are disabled by default. Use `autoMigrateDatabase` setting to enable.
- Migrator does not write .sql files by default. Use `writeMigratorSQLFiles` to enable
- Migrator does not allow 'down' migrations outside of the 'development' environment by default. Use `allowMigrationDown` to enable.

----

<a name="1.4.6"></a>

## [1.4.6](https://github.com/cfwheels/cfwheels/releases/tag/v1.4.6) => 2017.10.01

### Bug Fixes

- Made humanize() keep spaces in input - #663 [Per Djurner, Chris Peters]
- Added spatial datatypes for MySQL - #660 [Norman Cesar]
- Scope variable to avoid object being returned as NULL - #783 [Adam Larsen, Dmitry Yakhnov]
- Include "MariaDB" in database check connection string - #563 [Adam Chapman]
- Fixes MySQL attempts to insert nulls for blank strings - #680 [Andy Bellenie]

----

<a name="1.4.5"></a>

## [1.4.5](https://github.com/cfwheels/cfwheels/releases/tag/v1.4.5) => 2016.03.30

### Bug Fixes

- Display URL correctly in error email when on HTTPS - [Per Djurner]
- Added the `datetimeoffset` data type to the Microsoft SQL Server adapter - [Danny Beard]
- Fix for test link display in debug footer - [#588](https://github.com/cfwheels/cfwheels/issues/588) [Tom King]
- Don't include query string when looking for image on file through `imageTag()` - [Per Djurner]
- Format numbers in `paginationLinks()` - [Per Djurner]
- Correct plugin filename case on application startup - [#586](https://github.com/cfwheels/cfwheels/issues/586) [Chris Peters]
- Clear out cached queries on reload - [#585](https://github.com/cfwheels/cfwheels/issues/585) [Andy Bellenie]

----

<a name="1.4.4"></a>

## [1.4.4](https://github.com/cfwheels/cfwheels/releases/tag/v1.4.4) => 2015.02.10

### Bug Fixes

- Check global "cacheActions" setting - [#572](https://github.com/cfwheels/cfwheels/issues/572) [Andy Bellenie, Per Djurner]
- Fixed parsing for SQL IN parameters - [#564](https://github.com/cfwheels/cfwheels/issues/564) [Lee Bartelme, Per Djurner]
- Pass through all arguments properly when using findOrCreateBy - [#561](https://github.com/cfwheels/cfwheels/issues/561) [Per Djurner]
- Make it possible to disable session management on a per request basis - [#493](https://github.com/cfwheels/cfwheels/issues/493) [Andy Bellenie, Per Djurner]
- Allow mailParams to be passed through to sendEmail() - [#565](https://github.com/cfwheels/cfwheels/issues/565) [Tom King]
- Fixed inconsistency in form helpers for nested properties - [Marc Funaro, Per Djurner, Chris Peters]
- Fixed issue with grouping on associated models - [Song Lin, Per Djurner]
- Made the pagination() function available globally - [#560](https://github.com/cfwheels/cfwheels/issues/560) [Chris Peters, Per Djurner]

----

<a name="1.4.3"></a>

## [1.4.3](https://github.com/cfwheels/cfwheels/releases/tag/v1.4.3) => 2015.10.16

### Bug Fixes

- Fix for using cfscript operators in condition and unless arguments - [Per Djurner]
- Added try / catch on getting host name since CreateObject("java") can be unavailable for security reasons - [Per Djurner]
- Fixed bug with cache keys always changing even though the input was the same - [Per Djurner]
- Remove white space character in output - [Bill Tindal, Per Djurner]
- Use correct path info in error email and debug area - [Per Djurner]
- Fixed plugin injection issue on start-up - [#556](https://github.com/cfwheels/cfwheels/issues/556) [Adam Chapman, Per Djurner]
- Skip calculated properties that are aggregate SQL functions in the GROUP BY clause - [#554](https://github.com/cfwheels/cfwheels/issues/554) [Adam Chapman, Per Djurner]
- Fixed error when trying to validate uniqueness on blank numeric properties - [#558](https://github.com/cfwheels/cfwheels/issues/558) [Chris Peters, Per Djurner]

----

<a name="1.4.2"></a>

## [1.4.2](https://github.com/cfwheels/cfwheels/releases/tag/v1.4.2) => 2015.08.31

### Bug Fixes

- Fix for selecting distinct with calculated property - [Edward Chanter, Per Djurner]
- Fixed so default values are applied to non persistent properties - [#519](https://github.com/cfwheels/cfwheels/issues/519) [Andy Bellenie]
- Fixed missing var scope causing error on Lucee - [Russ Michaels, Tom King]
- Don't show debug info on AJAX requests - [#496](https://github.com/cfwheels/cfwheels/issues/496) [Leroy Mah, Per Djurner]
- Fixed permissions issue with imageTag() when running on shared hosting - [Per Djurner]
- Removed use of ExpandPath() in debug file since it was causing file permission issues - [Peter Hopman, Per Djurner]
- Skip setting object property when NULL is passed in - [#507](https://github.com/cfwheels/cfwheels/issues/507) [Andy Bellenie, Per Djurner]
- Fixed edge case issue with calling dynamic association methods - [#501](https://github.com/cfwheels/cfwheels/issues/501) [Dominik Hofer, Per Djurner]
- Fixed lock name in onSessionEnd event - [#499](https://github.com/cfwheels/cfwheels/issues/499) [Per Djurner]
- Ignore white space in the "where" argument to finders - [#503](https://github.com/cfwheels/cfwheels/issues/503) [Per Djurner]
- Ignore spaces in the "keys" argument to hasManyCheckBox() and hasManyRadioButton() - [Song Lin, Per Djurner]
- Skip running callbacks when validating uniqueness and similar situations - [#492](https://github.com/cfwheels/cfwheels/issues/492) [Andy Bellenie, Per Djurner]
- Avoid plugin directory exception during first application load - [#541](https://github.com/cfwheels/cfwheels/issues/541) [Adam Chapman, Per Djurner]
- Fix for using cfscript operators in "condition" and "unless" argument on ACF 8 - [#531](https://github.com/cfwheels/cfwheels/issues/531) [Per Djurner]
- afterSave and afterCreate callbacks are not firing on nested objects - [#525](https://github.com/cfwheels/cfwheels/issues/525) [Adam Chapman, Chris Peters, Per Djurner]
- Fix for rolling back nested properties - [#539](https://github.com/cfwheels/cfwheels/issues/539) [James Gibson, Chris Peters, Per Djurner]
- Ability to pass in list to "includeBlank" argument on dateSelect() and similar functions - [#502](https://github.com/cfwheels/cfwheels/issues/502) [Thorsten Eilers, Per Djurner]
- Ability to set attributes on the input element created by buttonTo() - [Per Djurner]
- Added missing "onlyPath" argument to imageTag() - [#508](https://github.com/cfwheels/cfwheels/issues/508) [Per Djurner]
- Corrected output of property labels in error messages - [#494](https://github.com/cfwheels/cfwheels/issues/494) [Andy Bellenie]

----

<a name="1.4.1"></a>

## [1.4.1](https://github.com/cfwheels/cfwheels/releases/tag/v1.4.1) => 2015.05.30

### Bug Fixes

- Skip callbacks when running calculation methods - [#488](https://github.com/cfwheels/cfwheels/issues/488) [Adam Chapman, Per Djurner]
- Fixed rewrite rules so base URL is rewritten correctly on Apache - [#367](https://github.com/cfwheels/cfwheels/issues/367) [Jeremy Keczan, Per Djurner]
- Removed incorrect path info information set by Apache - [#367](https://github.com/cfwheels/cfwheels/issues/367) [David Belanger, Per Djurner]
- Fixed routing bug when running from a sub folder on Adobe ColdFusion 10 - [Brant Nielsen, Per Djurner]
- Made sure error emails never depend on application variables being set - [Per Djurner]
- Fix for using cfscript operators in "condition" and "unless" argument on ACF 8 - [Per Djurner]

### Miscellaneous

- Removed tests folder - [Per Djurner]
- Updates to framework utility pages - Update logo, Fix links on congrats page to point to new documentation site - [Chris Peters]

----

<a name="1.4"></a>

# [1.4](https://github.com/cfwheels/cfwheels/releases/tag/v1.4) => 2015.05.08

### Model Enhancements

- Allow spaces in list passed in to the "include" argument on finders - [#150](https://github.com/cfwheels/cfwheels/issues/150) [Per Djurner]
- Added findOrCreateBy[Property](), findAllKeys(), findFirst() and findLast() finder methods - [Per Djurner]
- Add support for "GROUP BY" in sum(), average() etc. - [#464](https://github.com/cfwheels/cfwheels/issues/464) [Per Djurner]
- Made exists() check for any record when "key" and "where" is not passed in [Per Djurner]
- Added clearChangeInformation() for clearing knowledge of object changes - [#433](https://github.com/cfwheels/cfwheels/issues/433) [Jeremy Keczan, Per Djurner]
- Evaluate validation error messages at runtime - [#470](https://github.com/cfwheels/cfwheels/issues/470) [Per Djurner]

### View Enhancements

- Respect blank "text" argument in linkTo() - [#365](https://github.com/cfwheels/cfwheels/issues/365) [Adam Chapman, Tony Petruzzi, Per Djurner]
- Allow styleSheetLinkTag() and JavaScriptIncludeTag() to reference files starting from the root - [Per Djurner]
- Added "monthNames" and "monthAbbreviations" arguments to form helpers for easy localization - [Per Djurner]

### Controller Enhancements

- Ability to prepend functions to the filter chain instead of appending - [#321](https://github.com/cfwheels/cfwheels/issues/321) [Per Djurner]
- Pass in "appendToKey" to caches() to cache content separately - [#439](https://github.com/cfwheels/cfwheels/issues/439) [Per Djurner]
- Allow external attachments with sendEmail() - [Adam Chapman, Tony Petruzzi]
- Ability to redirect to a specific URL - [Simon Allard]
- Option to correct JSON output by passing in x="string" or x="integer" to renderWith() - [Per Djurner]

### Bug Fixes

- Fix for blank path_info in CGI scope - [#447](https://github.com/cfwheels/cfwheels/issues/447) [Tim Badolato, Tony Petruzzi, Per Djurner]
- Fix for accessing request scope key that does not exist from session - [#446](https://github.com/cfwheels/cfwheels/issues/446) [Brent Alexander, Per Djurner]
- Removed "validate" property that was incorrectly set when calling create() - [Per Djurner]
- Pass through "parameterize" in exists() [Per Djurner]
- Do not remove "AS" when it's in the SQL for a calculated property - [#453](https://github.com/cfwheels/cfwheels/issues/453) [Jean Duteau, Per Djurner]
- Obfuscate parameters in named route patterns when URL rewriting is off - [#455](https://github.com/cfwheels/cfwheels/issues/455) [Amber Cline, Per Djurner]
- Pass through "includeSoftDeletes" argument correctly - [#451](https://github.com/cfwheels/cfwheels/issues/451) [Jon Brose]

### Miscellaneous

- Support for the Lucee server - [Tom King]
- Made "development" the default environment mode - [Per Djurner]
- Removed deprecation work-around for the "if" argument on validation helpers - [Per Djurner]
- Removed deprecation work-around for the "class" argument on association initialization methods - [Per Djurner]
- Removed the "lib" folder - [Per Djurner]
- Removed the h() function, use XMLFormat() instead - [Per Djurner]

----

<a name="1.3.4"></a>

## [1.3.4](https://github.com/cfwheels/cfwheels/releases/tag/v1.3.4) => 2015.02.30

### Miscellaneous

- Removed unnecessary tests folder [Brant Nielsen, Per Djurner]

----

<a name="1.3.3"></a>

## [1.3.3](https://github.com/cfwheels/cfwheels/releases/tag/v1.3.3) => 2015.02.02

### Bug Fixes

- Correct output of boolean HTML attributes using new global "booleanAttributes" setting - [#377](https://github.com/cfwheels/cfwheels/issues/377) [James Hayes, Per Djurner]
- Make sure locks cannot be affected by other applications running on the same server - [Jonathan Smith, Per Djurner]
- Fixed bug with updating an integer column from NULL to 0 - [#436](https://github.com/cfwheels/cfwheels/issues/436) [Simon Allard, Per Djurner]
- Fixed potential permissions issue when running on shared hosting - [John Bliss, Per Djurner]

----

<a name="1.3.2"></a>

## [1.3.2](https://github.com/cfwheels/cfwheels/releases/tag/v1.3.2) => 2014.11.11

### Bug Fixes

- Fixed regression bug with setting unique id for nested properties - [Simon Allard, Per Djurner]
- Fixed reversed usage for setting option text / value when passing in an array of structs to select() / selectTag() - [Per Djurner]
- Tableless models should not require dataSourceName - [#351](https://github.com/cfwheels/cfwheels/issues/351) [Jeremy Keczan, Singgih Cahyono]
- Fixed issue with using group by with calculated properties - [#89](https://github.com/cfwheels/cfwheels/issues/89) [Adam Chapman, Per Djurner, Singgih Cahyono]
- Fixed ORM incorrectly parsing a property value as NULL - [#209](https://github.com/cfwheels/cfwheels/issues/209) [Chris Peters, Per Djurner]
- Fixed bug with application scope when sharing name across applications - [#359](https://github.com/cfwheels/cfwheels/issues/359) [Singgih Cahyono]
- Fix for removing "AS" from ORDER BY clause in Microsoft SQL Server - [#132](https://github.com/cfwheels/cfwheels/issues/132) [Troy Murray, Tony Petruzzi, Charley Contreras, Per Djurner]
- Calling valid() will now correctly validate all associations when using nested properties - [#284](https://github.com/cfwheels/cfwheels/issues/284) [Adam Chapman, Per Djurner]
- Fixed issue with save() causing callbacks to run twice when using nested properties - [#284](https://github.com/cfwheels/cfwheels/issues/284) [Adam Chapman, Per Djurner]
- Fixed race condition issue with caching - [#376](https://github.com/cfwheels/cfwheels/issues/376) [Brian Parks, Tom King, Per Djurner]
- Fixed number parsing in WHERE strings - [Per Djurner]

----

<a name="1.3.1"></a>

## [1.3.1](https://github.com/cfwheels/cfwheels/releases/tag/v1.3.1) => 2014.08.25

### Bug Fixes

- Fixed issue with calling addFormat() on application start-up - [#333](https://github.com/cfwheels/cfwheels/issues/333) [Tom King, Per Djurner]
- Fixed so that Railo outputs ids for nested properties as integers instead of exponents - [Jordan Clark]
- Make sure that ids for nested properties are unique - [Sam Hakimi, Tony Petruzzi]
- Allow models to be created with no properties - [Tony Petruzzi, Singgih Cahyono]
- Added missing "prepend" and "append" arguments on startFormTag() and endFormTag() - [Per Djurner]
- Fix for fetching inserted primary key value from an Oracle database when using Adobe ColdFusion - [Per Djurner]
- When using autoLink(), make sure that links beginning with "www" have a protocol - [Benjamin Melançon, Tony Petruzzi]
- Plugin folder name should be lower case as per convention - [#320](https://github.com/cfwheels/cfwheels/issues/320) [Singgih Cahyono]
- Clear statically cached pages on reload - [Per Djurner]
- Do not run filters and verifications when caching actions statically - [Per Djurner]
- Fixed a bug where trying to obfuscate a high number was throwing an error - [Per Djurner]
- Fixed bug with static caching on Adobe ColdFusion 9 - [#332](https://github.com/cfwheels/cfwheels/issues/332) [Charley Contreras]
- Allow for format auto-detection when HTTP ACCEPT contains multiple values - [#297](https://github.com/cfwheels/cfwheels/issues/297) [Raul Riera, Singgih Cahyono]
- Fixed so that sendEmail() can use the "remove" attribute to delete attachments - [#339](https://github.com/cfwheels/cfwheels/issues/339) [Simon Allard]
- Fixed bugs with using the "twelveHour" argument on form helpers - [#342](https://github.com/cfwheels/cfwheels/issues/342), #343 [Jeremy Keczan, Per Djurner]
- Fixed issue with using non-ascii characters in routes - [#138](https://github.com/cfwheels/cfwheels/issues/138) [Chris Ogden, Singgih Cahyono, Per Djurner]

----

# [1.3] => 2014.08.05

### Model Enhancements

- Support for tableless models - [Tony Petruzzi]
- Alias table names using the association name in the "FROM" clause of a query when needed - [James Gibson, Per Djurner]
- New global "modelRequireInit" setting that you can set to "true" to require an init function specified in all models - [Jonathan Smith]
- Place surrounding parentheses on calculated properties in "where" and "order by" clauses - [Andy Bellenie, Per Djurner]
- Check to see if a given primary key already exists before adding it through setPrimaryKey() - [Mark Moran]

### View Enhancements

- Made it possible to set global defaults on autoLink(), excerpt(), wordTruncate() and simpleFormat() - [Chris Peters]
- Added server host name to debug info and error email - [Colin MacAllister]
- Made it possible to set a global default for the "twelveHour" argument on date / time helpers - [Per Djurner]
- Added "prepend / "append" arguments on buttonTag() - [Per Djurner]
- New "aroundRight" option on the "labelPlacement" argument that places the label text to the right of the form input - [Adam Chapman, Per Djurner]
- Support for HTML5 "type" argument in form field helpers - [Per Djurner]
- Support for HTML5 boolean attributes - [Per Djurner]
- Ability to remove media / type attributes when using styleSheetLinkTag and JavaScriptIncludeTag - [Per Djurner]
- Support for implicit protocol in JavaScriptIncludeTag and styleSheetLinkTag - [Per Djurner]
- Setting to convert, for example, dataDomCache or data_dom_cache (default) view helper argument names to data-dom-cache attribute names - [Per Djurner]
- Allow the class attribute for paginationLinks helper anchor tags - [Adam Chapman]

### Controller Enhancements

- Added the ability to pass through arguments from the view to the data Function in the controller - [Per Djurner]
- Made setPagination() available from the controller layer - [Per Djurner]

### Bug Fixes

- Fixed issue with double camel-casing of already singular strings [Don Humphreys]
- Fixes issue with running CFWheels with strict scope cascading enabled in Railo - [Jason Weible]
- Prevent stack overflow error with named arguments on dynamic update - [Tony Petruzzi]
- Fixes pagination bug when using association methods with a blank "where" clause - [Andy Bellenie]
- Added missing "validate" argument to create() - [Andy Bellenie]
- Fixed issue with deleting plugins on case sensitive systems - [Mark Moran]
- Make sure the latest version of a plugin is unpacked if multiple versions exists - [Tony Petruzzi]
- Fixed so the "onApplicationEnd" and "onSessionEnd" events pass through the arguments scope [Per Djurner]
- Fixed so the "onSessionEnd" event fires correctly - [#172](https://github.com/cfwheels/cfwheels/issues/172) [Per Djurner]
- Added geometry and geography datatypes (SQLServer) - [Simon Allard]
- Allow blank values to be passed through when validating uniqueness - [Per Djurner]
- Added work-around for "FastHashRemoved" struct bug found in ColdFusion 8 - [Per Djurner]
- Removed old bug fix to make redirectTo() respect anchors - [Per Djurner]
- Correct controller action caching - [#153](https://github.com/cfwheels/cfwheels/issues/153) [Tobias Reiter, Per Djurner]
- Fix for creating objects from the root folder on Railo 4 - [Jordan Clark, Adam Chapman]
- Fix for detecting that Microsoft SQL Server is used - [Tony Petruzzi, Adam Chapman]
- Don't assume null is false for boolean properties - [Adam Chapman]
- Allow to pass in encoded versions of "&"" and "=" (%26 and %3D) to the params argument - [#173](https://github.com/cfwheels/cfwheels/issues/173) [Mark Gaulin, Per Djurner]
- Avoid error when the first request to the app is an invalid one - [#222](https://github.com/cfwheels/cfwheels/issues/222) [Maxime de Visscher, Per Djurner]
- Get the error location from the correct exception struct - [#223](https://github.com/cfwheels/cfwheels/issues/223) [Adam Chapman, Per Djurner]
- Do not trim primary key values - [#213](https://github.com/cfwheels/cfwheels/issues/213) [Jeremy Keczan, Per Djurner]
- Incorrect pagination query with Oracle - [#93](https://github.com/cfwheels/cfwheels/issues/93) [crsedgar, Tony Petruzzi, Singgih Cahyono]
- Repair Oracle test failures #187 (Tony Petruzzi, Singgih Cahyono)
- Plugins with global mixin are ignored in unit tests - [Singgih Cahyono, Tony Petruzzi]
- Automatic validation should validate primary key - [#143](https://github.com/cfwheels/cfwheels/issues/143) [Adam Chapman, Tony Petruzzi]

### Miscellaneous

- Made application start-up thread safe - [Per Djurner]
- Performance improvement for locking - [Per Djurner]
- Case insensitive loading of controllers and models - [Per Djurner]
- Browse test packages for core, app and plugins - [Adam Chapman, Tony Petruzzi]
- Refactored to avoid a Duplicate() call when sending error email - [Per Djurner]

----

## [1.1.8] => 2012.05.21

### Model Enhancements

- Add boolean type to validatesFormatOf() - [Andy Bellenie]

### View Enhancements

- Add delimiter parameter to the highlight() function - [#826](https://github.com/cfwheels/cfwheels/issues/826) [Per Djurner, Tony Petruzzi]
- Use mark tag in highlight - [#836](https://github.com/cfwheels/cfwheels/issues/836) [Per Djurner, Tony Petruzzi]
- Add parameters append and prepend to the submitTag() - [#593](https://github.com/cfwheels/cfwheels/issues/593) [Per Djurner, Tony Petruzzi]

### Bug Fixes

- Turned off URL rewriting in IIS 7 by default - [Per Djurner, Tony Petruzzi]
- Add CFFileServlet to the pattern list, of the rewrite rules file, to be able to display an image when using <cfimage action='writeToBrowser'> - [ellor1138]
- radioButtonTag() checked attribute is ignored if value attribute is empty - [#733](https://github.com/cfwheels/cfwheels/issues/733) [Per Djurner, Tony Petruzzi]
- make cached queries respect the 'maxrows' argument (findAll) - [#824](https://github.com/cfwheels/cfwheels/issues/824) [Per Djurner, Tony Petruzzi]

### Miscellaneous

- Update web.config, htaccess to ignore favicon.ico - [Cathy Shapiro, Tony Petruzzi]
- Route with only format specified was throwing error - [jjallen, Tony Petruzzi]

----

## [1.1.7] => 12/11/2011.12.11

### Bug Fixes

- Filter controller and action params - [Pete Freitag, Andy Bellenie, Tony Petruzzi]

----

## [1.1.6] => 2011.10.08

### Model Enhancements

- validatesUniquenessOf only selects primary keys - [Jordan Clark, Don Humphreys]

### View Enhancements

- Allow removal height and/or width attributes from imageTag when set to false - [downtroden, Tony Petruzzi]
- Allow delimiter to be specified for stylesheets and javascripts - [Derek, Tony Petruzzi]

### Bug Fixes

- hasChanged was incorrectly evaluating boolean values - [Jordan Clark, Don Humphreys]
- Do not perform update when no changes have been made to the properties of a model - [#786](https://github.com/cfwheels/cfwheels/issues/786) [Mohamad El-Husseini, Tony Petruzzi]
- OnlyPath argument of urlFor does not correctly recognise HTTPS urls - [Andy Bellenie, Tony Petruzzi]
- Pagination clause wasn't enclosed - [Karl Deterville, Tony Petruzzi]
- Pagination endrow was incorrectly calculated - [Karl Deterville, Tony Petruzzi]

----

## [1.1.5] => 2011.08.01

### View Enhancements

- Escape html entities in text and value of select options - [#767](https://github.com/cfwheels/cfwheels/issues/767) [Richard Herbert, Tony Petruzzi]

### Bug Fixes

- Fix plugins not loading when application is in a subdirectory - [Mike Craig, Tony Petruzzi]

----

## [1.1.4] => 2011.07.20

### Model Enhancements

- Update to belongsTo(), hasOne() and hasMany() for the new argument joinKey. - [James Gibson, Tony Petruzzi]
- You can pass an unlimited number properties when using dynamic finders - [Tony Petruzzi]
- Dynamic finders now support passing in an array for values - [Tony Petruzzi]
- Added the delimiter argument to dynamic finders, this allow you to change the delimiter - [Tony Petruzzi]
- Added validationTypeForProperty() method - [Tony Petruzzi]

### View Enhancements

- Allow an array of structs to used for options in selectTag() - [Adam Chapman, Tony Petruzzi]
- Added secondStep parameter to date/time select tags - [Tom King, Tony Petruzzi]

### Bug Fixes

- Incorrect MIME type for JSON - [#751](https://github.com/cfwheels/cfwheels/issues/751) [daniel.mcq, Tony Petruzzi]
- Route with format will cause exception when route is selected and format is not provided - [#738](https://github.com/cfwheels/cfwheels/issues/738) [Danny Beard, Tony Petruzzi]
- Raise renderError when template is not found for format - [#759](https://github.com/cfwheels/cfwheels/issues/759) [Mike Henke, Tony Petruzzi]
- LabelClass should split up the list of classes and attach one class for each label - [#757](https://github.com/cfwheels/cfwheels/issues/757) [Mohamad El-Husseini, Tony Petruzzi]
- Transactions would not close when used with the dependent argument of hasMany() - [#739](https://github.com/cfwheels/cfwheels/issues/739) [Andy Bellenie]
- Soft deletes do not work correctly with outer joins - [#762](https://github.com/cfwheels/cfwheels/issues/762) [Andy Bellenie]
- Better error message when supplying a query param of type string and omitting single quotes - [#763](https://github.com/cfwheels/cfwheels/issues/763) [Adam Chapman, Tony Petruzzi]
- Allow commas in dynamic finders - [#771](https://github.com/cfwheels/cfwheels/issues/771) [Joshua, Tony Petruzzi]
- AMPM select displaying twice - [#768](https://github.com/cfwheels/cfwheels/issues/768) [John Bliss, Tony Petruzzi]
- \$request argumentsCollection: should be argumentCollection - [#772](https://github.com/cfwheels/cfwheels/issues/772) [William Fisk, Tony Petruzzi]
- Pagination pull incorrect number of results with compounded keys - [#725](https://github.com/cfwheels/cfwheels/issues/725) [Jeff Greenhouse, Tony Petruzzi]
- Update hasChanged() to properly check floats - [Andy Bellenie, Tony Petruzzi]
- Date tags selected date throws out of range error - [Ben Garrett, Tony Petruzzi]

### Miscellaneous

- Added proper HTTP status headers - [#705](https://github.com/cfwheels/cfwheels/issues/705) [Randy Johnson , Andy Bellenie]
- Plugin development no longer requires a zip file. - [Tony Petruzzi]

----

## [1.1.3] => 2011.03.24

### Model Enhancements

- You can now have bracket markers for all validation arguments - [#706](https://github.com/cfwheels/cfwheels/issues/706) [Tony Petruzzi]
- Columns marked as not null should allow for blank strings - [Tony Petruzzi]

### View Enhancements

- Allows for relative url linking to be turned off in autolink() - [James Gibson, Tony Petruzzi]

### Controller Enhancements

- Allow for default argument on sendmail for from, to and subject - [#727](https://github.com/cfwheels/cfwheels/issues/727) [Andy Bellenie, Tony Petruzzi]

### Bug Fixes

- Fixed issue with $create supplying incorrect keys to $query - [Don Humphreys, Tony Petruzzi]
- The original transaction mode would not be respected during during callbacks - [Andy Bellenie, Tony Petruzzi]
- "none" transaction modes would never close - [Andy Bellenie, Tony Petruzzi]
- Incorrect \$cache argument - [#671](https://github.com/cfwheels/cfwheels/issues/671) [William Fisk, Tony Petruzzi]
- Route formats prevented fullstops from being used in params - [#666](https://github.com/cfwheels/cfwheels/issues/666) [Tom King, Raul Riera, Tony Petruzzi]
- Controller in params should be upper camel case - [#703](https://github.com/cfwheels/cfwheels/issues/703) [William Fisk, Tony Petruzzi]
- Application scope would not initialize in sub - [#721](https://github.com/cfwheels/cfwheels/issues/721) [Adam Chapman, Tony Petruzzi]
- ValidatesUniquenessOf doesn't read soft-deletes - [#719](https://github.com/cfwheels/cfwheels/issues/719) [Andy Bellenie, Tony Petruzzi]
- PaginationLinks(): routes with page number marker variable would produce the wrong links - [Kenneth Barrett, Tony Petruzzi]

----

## [1.1.2] => 2011.01.29

### Model Enhancements

- Add 'when' argument to validate() - [#643](https://github.com/cfwheels/cfwheels/issues/643) [Andy Bellenie, Tony Petruzzi]

### View Enhancements

- Select, SelectTag allow an array of structs to be passed to options - [#680](https://github.com/cfwheels/cfwheels/issues/680) [William Fisk, Tony Petruzzi]

### Controller Enhancements

- Changed "default" argument on includeContent() to "defaultValue" - [#663](https://github.com/cfwheels/cfwheels/issues/663) [Tony Petruzzi]

### Bug Fixes

- Added the varchar_ignorecase type to the H2 adapter - [#664](https://github.com/cfwheels/cfwheels/issues/664) [Per Djurner]
- Fix so that the full tablename is always returned - [#667](https://github.com/cfwheels/cfwheels/issues/667) [Tony Petruzzi]
- Pagaination with parameterize set to false for numeric keys - [#656](https://github.com/cfwheels/cfwheels/issues/656) [levi730, Tony Petruzzi]
- Blank should be the selected value when includeBlank is set - [#633](https://github.com/cfwheels/cfwheels/issues/633) [Tony Petruzzi]
- validatesLengthOf failed when both maximum and minimum were specified - [Tony Petruzzi]

----

## [1.1.1] => 2010.11.21

### Bug Fixes

- Added number formatting on the value passed in to "count" in the pluralize() function - [Per Djurner]
- Fixed renderWith() so that it works in all environment modes when returning JSON - [#644](https://github.com/cfwheels/cfwheels/issues/644) [Tony Petruzzi]
- Fixed belongsTo association code when using composite keys - [#641](https://github.com/cfwheels/cfwheels/issues/641) [James Gibson, Andy Bellenie]
- Allow cfthread to be used in views - [#612](https://github.com/cfwheels/cfwheels/issues/612) [Cathy Shapiro, Tony Petruzzi]
- Fixed paging code for non-parameterized queries - [#656](https://github.com/cfwheels/cfwheels/issues/656) [Mike Lester, Tony Petruzzi]
- Corrected bug in request verification when session management was disabled in Railo - [#658](https://github.com/cfwheels/cfwheels/issues/658) [Russ Sivak, Per Djurner]
- Changed "if" to "condition" on all validation methods to get around the fact that "if" is a reserved word in cfscript - [#660](https://github.com/cfwheels/cfwheels/issues/660) [Mohamad El-Husseini, Per Djurner]
- Fixed autolink() so that it correctly links and escapes relative paths - [#646](https://github.com/cfwheels/cfwheels/issues/646) [Tony Petruzzi]
- Fixed so including partials with layouts does not cause duplicated content - [#659](https://github.com/cfwheels/cfwheels/issues/659) [Per Djurner]

----

# [1.1] => 2010.11.19

### Bug Fixes

- Don't use the cfzip "overwrite" attribute when unzipping plugins since it updates the date on the files on Railo - [William Fisk, Per Djurner]
- Update to the error template to make sure errors are not thrown while trying to send out error emails - [James Gibson]
- Fixes a bug with obfuscation on Railo that happens when the mathematical constant "e" is in the string together with no other letters - [Jon Lynch, Tony Petruzzi, Per Djurner]
- Transaction="none" would throw an error if methods within a callback chain also attempted to make database changes - [#613](https://github.com/cfwheels/cfwheels/issues/613) [Andy Bellenie]
- Fixed bug that prevented the use of custom labels on calculated or non-persisted properties in form helpers and error messages - [#630](https://github.com/cfwheels/cfwheels/issues/630) [Andy Bellenie, Mike Henke]
- Update to renderwith() to return the content if "returnAs" equals "string" - [James Gibson, W. Scott Hayes]
- Removed case-sensitivity on labelXXX arguments passed through to form helpers - [Andy Bellenie]

----

# [1.1 RC 1] => 2010.10.27

### Bug Fixes

- The full tag context of an error was missing from the error emails, fixed now - [Andy Bellenie]
- Fixed bug in nested properties related to deleting children via object array - [#595](https://github.com/cfwheels/cfwheels/issues/595) [Adam Michel, Tony Petruzzi]
- Make sure transactions are rolled back and marker gets closed on error - [Tony Petruzzi]
- Fixed so deprecation notices only gets set when the debug info is to be displayed - [John C. Bland II, Per Djurner]
- Fix to make preserveSingleQuotes() call work in Railo 3.2 - [Raul Riera, Per Djurner]
- Fixed bug with dynamic finders where we were looking for a non existing data type on a calculated property - [Brian Ward, Per Djurner]
- Fix to make sure findOne() does not query the database for more records than needed - [#605](https://github.com/cfwheels/cfwheels/issues/605) [Per Djurner, Tony Petruzzi]
- Corrected H2, Oracle and PostgreSQL code for when GROUP BY clause needs to contain columns from the ORDER BY clause - [Per Djurner]
- Correction to get exactly one record when we're dealing with single associations instead of basing it on the "joinType" argument - [Per Djurner]
- Update to error handling to make sure the "rootCause" data exists before trying to use it - [James Gibson]
- Corrections and improvements to Oracle support - [Ryan Hoppitt, Tony Petruzzi, Per Djurner]
- Fixed so the "Message" part is also in lower case when "lowerCaseDynamicClassValues" is "true" in flashMessages() - [John C. Bland II, Per Djurner]
- Case corrections to ensure compatibility with Linux - [Per Djurner]
- Fix for using layouts on AJAX calls when usesLayout() has not been called - [Per Djurner]
- Added missing dependency operation remove with instantiation - [Andy Bellenie]
- Fixed bug with pagination and renamed primary keys - [Tony Petruzzi]

### Miscellaneous

- Added "errorClass" argument to form helpers and set the default to "fieldWithErrors" to make the naming consistent - [Per Djurner]

----

# [1.1 Beta 2] => 2010.10.05

### Bug Fixes

- Corrected some bugs related to case, ordering and pagination on the H2 database - [Per Djurner]
- made it possible to use plugins on the H2 database - [Per Djurner]
- Fixed autoLink() so that it can handle all types of domains - [#560](https://github.com/cfwheels/cfwheels/issues/560) [Tom King, Tony Petruzzi]
- Corrected deobfuscation logic so that it... umm... works :) - [#577](https://github.com/cfwheels/cfwheels/issues/577) [Per Djurner, James Gibson]
- Fix for obfuscateParam() related to leading zeros in integer values on Railo - [#578](https://github.com/cfwheels/cfwheels/issues/578) [Tony Petruzzi]
- Fixed so correct defaults are set for "valueField" and "textField" on select() when dealing with objects - [#445](https://github.com/cfwheels/cfwheels/issues/445) [Per Djurner]
- Adapters now only fall backs on native code for getting the last inserted key when Railo/ACF can't do it automatically - [#562](https://github.com/cfwheels/cfwheels/issues/562) [Per Djurner]
- simpleFormat() now produce the exact same output regardless of the operating system - [#570](https://github.com/cfwheels/cfwheels/issues/570) [Raul Riera, Tony Petruzzi, Per Djurner]
- imageTag() was outputting the "id" attribute twice when caching was on, fixed now - [#582](https://github.com/cfwheels/cfwheels/issues/582) [Andy Bellenie, Per Djurner]
- Changed to using SCOPE_IDENTITY() as fallback for SQL Server - [Tony Petruzzi, Per Djurner]
- Fixed overwrite problem when using composite keys - [#587](https://github.com/cfwheels/cfwheels/issues/587) [Andy Bellenie, Per Djurner]
- Fixed bug with upper case input in humanize() and allow exception list for when abbreviations aren't caught - [#587](https://github.com/cfwheels/cfwheels/issues/587) [Andy Bellenie, Tony Petruzzi, Per Djurner]
- Made it possible to call model (and other) methods on application / session start - [W. Scott Hayes, Per Djurner]
- Fixed bug in setPagination() where floats could be passed in for the numeric values - [Tony Petruzzi]
- Fixed so labels on dateTimeSelectTags() and dateTimeSelect() get applied correctly to all six possible form inputs - [#531](https://github.com/cfwheels/cfwheels/issues/531) [Raul Riera, Tony Petruzzi, Chris Peters, Per Djurner]
- Made it possible to call the controller data function from a partial located in the root or sub folder - [Per Djurner, Chris Peters]
- Fixed a PostgreSQL pagination query that would fail under certain conditions (edge case) - [Per Djurner]
- Fixed deleting in nested properties - [#579](https://github.com/cfwheels/cfwheels/issues/579) [Adam Michel, Tony Petruzzi]

### Miscellaneous

- Removed the `afterFindCallbackLegacySupport` setting and made the new way introduced in Beta 1 the only way - [#580](https://github.com/cfwheels/cfwheels/issues/580) [Per Djurner]
- Changed "class" attribute on flashMessages(), errorMessageOn() and errorMessagesFor() to be camelCased - [#554](https://github.com/cfwheels/cfwheels/issues/554) [Per Djurner]
- Added better error reporting when passing in one primary key value when multiple are expected - [#540](https://github.com/cfwheels/cfwheels/issues/540) [Adam Michel, Tony Petruzzi]

----

# [1.1 Beta 1] => 2010.09.10

### Model Enhancements

- Support for automatic validations based on database settings (column does not allow nulls, has a maximum length etc) - [James Gibson, Andy Bellenie, Tony Petruzzi]
- Support for handling binary data columns - [#133](https://github.com/cfwheels/cfwheels/issues/133) [Tony Petruzzi]
- Callbacks are not pre-loaded anymore - [#388](https://github.com/cfwheels/cfwheels/issues/388) [Andy Bellenie]
- Support for NOT IN, IN, NOT LIKE, IS NULL, IS NOT NULL in where clause with proper use of cfqueryparam - [Per Djurner, Tony Petruzzi]
- Made it possible to use a blank value as a property default - [Andy Bellenie]
- Ability to skip validation when saving, e.g. save(validate=false) - [Tony Petruzzi]
- Added argument for model methods to be able to turn off callbacks, e.g. save(callbacks=false) - [#236](https://github.com/cfwheels/cfwheels/issues/236) [Andy Bellenie]
- Ability to set a default value for column statistics with "ifNull" argument - [#330](https://github.com/cfwheels/cfwheels/issues/330) [Andy Bellenie]
- Support for nested properties (saving data in associated model objects through the parent) - [James Gibson]
- Added automatic deletion of dependent models - [#367](https://github.com/cfwheels/cfwheels/issues/367) (Per Djurner, Andy Bellenie]
- Added "setUpdatedAtOnCreate" to tell CFWheels if it should update the "updatedAt" property when creating new records - [James Gibson]
- New setting "useExpandedColumnAliases" that you can set to "true" to prepend included model properties with their model name in queries - [#442](https://github.com/cfwheels/cfwheels/issues/442) [Andy Bellenie]
- Arguments are now always passed in to "afterFind" callback methods and you can return them to set both queries and objects - [Tony Petruzzi]
- Updated findAll() to allow for more than one association as long as they are direct (i.e. include="assoc1,assoc2" works but not include="assoc1(assoc2)) - [James Gibson]
- Update to add GROUP BY functionality in finders - [James Gibson]
- Allow overriding of soft-deletes - [#324](https://github.com/cfwheels/cfwheels/issues/324) [Andy Bellenie]
- Added accessibleProperties() and protectedProperties() to protect model variables from mass assignment - [James Gibson]
- Ability to set defaults on a model using the "defaultValue" argument to property() - [#244](https://github.com/cfwheels/cfwheels/issues/244) [Andy Bellenie]
- Added transaction handling support, use the "transaction" argument on save(), updateAll() etc, callbacks are automatically wrapped in a transaction - [#325](https://github.com/cfwheels/cfwheels/issues/325) [Andy Bellenie]
- Added a position argument to primaryKeys() for easier retrieval - [Tony Petruzzi]
- Added a setPagination() function to make it possible to use paginationLinks() and similar functions for custom queries (i.e. ones not created with the CFWheels ORM) - [Tony Petruzzi]
- Allow database views to be used as a model by calling setPrimaryKey() - [#390](https://github.com/cfwheels/cfwheels/issues/390) [Tony Petruzzi]

### View Enhancements

- Labels will now be added automatically for form helpers based on the object's property name (or a custom label set in the model) - [Andy Bellenie]
- Added default for "action" argument on linkTo() - [#321](https://github.com/cfwheels/cfwheels/issues/321) [Andy Bellenie]
- Added 12-hour format to date/time select helpers - [#551](https://github.com/cfwheels/cfwheels/issues/551) [Tony Petruzzi]
- Added a flashMessages() function that outputs all key/values from the Flash - [Per Djurner]
- Added support for inherited / nested layout templates through includeLayout() - [Per Djurner]
- Added "head" argument to styleSheetLinkTag() and JavaScriptIncludeTag() - [Per Djurner]
- flashMessages() can now pass a list of keys that controls which messages to display as well as the order they are displayed in - [Chris Peters]
- Ability for years to display in descending order in date select form tags - [Tony Petruzzi]
- Support for an automatic "assetQueryString" which can be used to force local browser caches to refresh when there is an update to your assets (CSS, JavaScript etc) - [James Gibson]
- Added buttonTag() form helper - [Tony Petruzzi]
- Added "disabled" and "readonly" arguments to form input helpers [Andy Bellenie]
- Allows disabling error elements appearing on form fields by setting "errorElement" - [Andy Bellenie]
- Updates to checkBoxTag() and checkBox() to allow for unchecked values - [James Gibson]
- Added "pageNumberAsParam" argument to paginationLinks() that decides whether the page parameter should be part of the route or just a regular parameter - [James Gibson]
- Added contentFor() and includeContent() used to set/display content - [Tony Petruzzi, Per Djurner]
- Added hasManyRadioButton() and hasManyCheckBox() used to easily add radio buttons / checkboxes for a hasMany relationship on a model when using nested properties. - [James Gibson]
- New global defaults for truncate() and wordTruncate() - [James Gibson]
- Added a toXHTML() function that returns an XHTML compliant string - [Tony Petruzzi]
- Added "dataFunction" argument to includePartial() for getting data from a controller function automatically - [Per Djurner]
- Added a h() function for sanitizing user output - [Tony Petruzzi]
- Added support for external links in linkTo(), startFormTag(), javaScriptIncludeTag() and styleSheetLinkTag() - [Tony Petruzzi]

### Controller Enhancements

- Updated the request processing to not call the action if a before filter has rendered content - [James Gibson]
- Support for using an onMissingMethod() inside controllers - [James Gibson]
- redirectTo() now accepts a "delay" argument which can be used to delay the redirection until after the action code has completed (useful for testing) - [James Gibson, Tony Petruzzi]
- Added addDefaultRoutes(), used to control exactly where in the route order to place the default routes - [Per Djurner]
- New setting called "loadDefaultRoutes" which you can set to false when you want to use addDefaultRoutes() to load the routes manually - [Per Djurner]
- Added the ability to attach files with sendEmail() - [Per Djurner]
- Added "directory" and "deleteFile" arguments to sendFile() - [#323](https://github.com/cfwheels/cfwheels/issues/323) [Tony Petruzzi]
- Added the ability to set wildcard routes - [Andy Bellenie]
- Controllers can now respond to different formats such as "xml", "json", "csv", "pdf" and "xls" - [James Gibson]
- Ability to store Flash in cookies - [Per Djurner]
- Ability to add Flash messages when redirecting - [Per Djurner]
- redirecTo(back=true) can now fall back on a route/controller/action when the referrer is blank instead of throwing an error - [Per Djurner]
- Support for "format" parsing in route patterns ([controller]/[action].[format]) - [James Gibson]
- Ability to pass through arguments to filters - [Per Djurner]
- Added flashKeep() function for keeping Flash contents for one additional request - [Per Djurner]
- You can now validate type on incoming parameters using verifies() - [Tony Petruzzi]
- Defaulted day to 1 and month to 1 when submitting forms - [Tony Petruzzi]
- Added usesLayout() for specifying a controller specific layout - [Tony Petruzzi, Per Djurner]
- You can now perform a redirect instead of aborting the request using verifies(), any extra arguments passed in are passed through to redirectTo() - [Tony Petruzzi]

### Bug Fixes

- Session scope is now locked when accessing the Flash - [#275](https://github.com/cfwheels/cfwheels/issues/275) [James Gibson, Per Djurner]
- Corrected the "id" attribute for radioButton() when value is blank - [#373](https://github.com/cfwheels/cfwheels/issues/373) [Tony Petruzzi]
- findByKey() now correctly returns "false" when passed a blank "key" argument - [#514](https://github.com/cfwheels/cfwheels/issues/514) [Andy Bellenie]
- Fixed so hasChanged() compares dates correctly - [#515](https://github.com/cfwheels/cfwheels/issues/515) [Tony Petruzzi]
- validatesUniquenessOf() now recognizes soft-deleted columns as well - [#532](https://github.com/cfwheels/cfwheels/issues/532) [Andy Bellenie]
- Corrected a bad throw in onMissingMethod() - [#555](https://github.com/cfwheels/cfwheels/issues/555) [Per Djurner, Adam Michel]
- Corrected count() to always return 0 if no records are found - [Per Djurner]
- Removed differences in params structure for form / URL variables - [#232](https://github.com/cfwheels/cfwheels/issues/232) [Mike Henke, Tony Petruzzi]

### Miscellaneous

- Allowed plugins to run in maintenance mode - [James Gibson]
- Added "excludeFromErrorEmail" setting - [#447](https://github.com/cfwheels/cfwheels/issues/447) [Per Djurner]
- New setting, "errorEmailSubject", that allows you to customize the subject line of error emails - [#392](https://github.com/cfwheels/cfwheels/issues/392) [Per Djurner]
- New setting, "deletePluginDirectories" that tells CFWheels whether to delete plugin directories if no corresponding ZIP file exists - [#385](https://github.com/cfwheels/cfwheels/issues/385) [Per Djurner]
- Added a "cachePlugins" setting to allow developers to not cache plugins during the development of them - [#304](https://github.com/cfwheels/cfwheels/issues/304) [Andy Bellenie]
- Allow setting multiple argument defaults at once, e.g. set(functionName="textField,textArea,select", labelPlacement="before" - [#426](https://github.com/cfwheels/cfwheels/issues/426) [Raul Riera, Per Djurner]
- A full testing framework is now included in Wheels, unit tests can be created in the "tests" folder - [Tony Petruzzi]
- Adobe ColdFusion 8.0.1 or Railo 3.1.2.020 is now required [Tony Petruzzi, Per Djurner]
- Deprecated the "class" argument on association methods (belongsTo(), hasMany(), hasOne()), use "modelName" instead. - [Per Djurner]
- Refactor to avoid polluting the Application.cfc's this scope with the "rootDir" variable - [Per Djurner]

----

## [1.0.5] => 2010.06.18

### Bug Fixes

- Fixed the handling for the "errorEmailServer" setting so that error emails can now be sent without having to set the server in the ColdFusion administrator - [Per Djurner]
- Corrected pluralize rules - [#450](https://github.com/cfwheels/cfwheels/issues/450) [Joshua Clingenpeel, Tony Petruzzi]
- Remove possible spaces in list passed in to callback registration - [#448](https://github.com/cfwheels/cfwheels/issues/448) [Raul Riera]
- Check to see that a function has a declaration in the settings before setting defaults - [James Gibson]
- Update to capitalize() to return nothing if the passed in string is empty - [James Gibson]
- validatesPresenceOf() now takes whitespace into account - [Tony Petruzzi]
- Fix for lock timeouts occurring during race conditions in the "design" and "development" modes - [#467](https://github.com/cfwheels/cfwheels/issues/467) [John C. Bland II, Andy Bellenie, Tony Petruzzi]
- Fix so CFWheels uses passed in width/height in imageTag() when only one of them is passed in - [#328](https://github.com/cfwheels/cfwheels/issues/328) [Andy Bellenie, Per Djurner]
- Don't append .css, .js to asset files when they end in .cfm - [Tony Petruzzi]
- Update to reload to catch the query blank boolean error - [James Gibson]
- onCreate validations do not run when onSave validations fail - [#455](https://github.com/cfwheels/cfwheels/issues/455) [Andy Bellenie]
- Fixes bug with nullable foreign keys in where clause - [Andy Bellenie]
- Update to clean up variables from all scopes after running plugin injection - [James Gibson]
- Updated PostgreSQL types - [Jaroslaw Krzemienski, Per Djurner]
- Fix for race condition when checking for existing controller files in the "design" and "development" modes - [#360](https://github.com/cfwheels/cfwheels/issues/360) [Andrea Campolonghi, Per Djurner]
- Error in SQL Server pagination with mapped columns - [#456](https://github.com/cfwheels/cfwheels/issues/456) [Don Humphreys, Tony Petruzzi]
- Updated hasChanged() for a race condition that wasn't met - [James Gibson]
- Fixed pagination error in Oracle when using the "include" argument - [#449](https://github.com/cfwheels/cfwheels/issues/449) [Per Djurner]
- Fixed incorrect layout rendering for renderPartial() and includePartial() - [#488](https://github.com/cfwheels/cfwheels/issues/488) [Jordan Sitkin, Per Djurner]
- Fix for complex "include" strings - [#453](https://github.com/cfwheels/cfwheels/issues/453) [Jordan Sitkin, Andy Bellenie]
- Fixed naming conflict occurring for properties starting with the same name as its model on included objects - [#461](https://github.com/cfwheels/cfwheels/issues/461) [Tony Petruzzi, Per Djurner, Raul Riera]
- Fixed pluralization issue related to partials used with object(s)/queries and removed the limitation of the file being tied to the model name - [#427](https://github.com/cfwheels/cfwheels/issues/427) [Per Djurner, James Gibson]
- Prevent additional errors from occurring during display of CFML errors - [#466](https://github.com/cfwheels/cfwheels/issues/466) [John C. Bland II, Per Djurner, Tony Petruzzi]

----

## [1.0.4] => 2010.04.21

### Bug Fixes

- Added missing support for passing in array of model objects as options to select() - [#411](https://github.com/cfwheels/cfwheels/issues/411) [John C. Bland II, Tony Petruzzi]
- Fixed so "afterFind" callback methods are only called once during pagination - [#435](https://github.com/cfwheels/cfwheels/issues/435) [Bucky Schwarz, Doug Giles, Per Djurner]
- Added "prependOnAnchor" and "appendOnAnchor" arguments to paginationLinks() to get around an issue where the "appendToPage" string was added on anchor pages - [#434](https://github.com/cfwheels/cfwheels/issues/434) [Joshua Clingenpeel, Per Djurner]
- Fixed bug in paginationLinks() when using "appendToPage" with single page result - [Joshua Clingenpeel, Per Djurner]
- Fixed bug with count() when using composite primary keys - [Per Djurner]
- Fixed concurrency issue related to setting the model name on associations - [#419](https://github.com/cfwheels/cfwheels/issues/419) [John C. Bland II, Per Djurner]
- Fix for skipping duplicate columns returned from cfdbinfo when using Oracle - [#437](https://github.com/cfwheels/cfwheels/issues/437) & #439 [Mike Henke, Per Djurner]
- Fix for race conditions when setting the join clause in an application scoped model object - [#432](https://github.com/cfwheels/cfwheels/issues/432) [James Gibson, Per Djurner]
- Fixed so URLFor() is not duplicating controller and action when URL rewriting is off - [#433](https://github.com/cfwheels/cfwheels/issues/433) [Per Djurner]
- Added support to imageTag() for all image types that the CFML engine supports - [Cathy Shapiro, Per Djurner]

----

## [1.0.3] => 2010.03.26

### Bug Fixes

- Added support for more domains in autoLink() and also fixed linking when the URL starts at the very beginning of the string - [#424](https://github.com/cfwheels/cfwheels/issues/424) [Per Djurner]
- Corrected the order in which object properties are set when based on a query result - [#404](https://github.com/cfwheels/cfwheels/issues/404) & #422 [Raul Riera, Per Djurner]
- Fixed so the "appendToPage" and "prependToPage" arguments in paginationLinks() apply to the anchor pages - [#417](https://github.com/cfwheels/cfwheels/issues/417) [Raul Riera, Per Djurner]
- Changed so developer supplied arguments to URLFor() are not converted to lowercase - [#415](https://github.com/cfwheels/cfwheels/issues/415) [Per Djurner]
- Made sure you can only reload based on the URL when a reload password exists (either empty or set) - [#410](https://github.com/cfwheels/cfwheels/issues/410) [John C. Bland II, Per Djurner]
- Added escaping on strings used in JavaScript - [#393](https://github.com/cfwheels/cfwheels/issues/393) [Tony Petruzzi]
- Changed so the dispatch object is created with a reference from the root of the CFWheels application instead of the entire website - [Per Djurner]
- Fixed so sendEmail() automatically sets the "type" argument to "text" or "html" when only one template is in use - [Per Djurner]
- Fixed so creating SELECT clause works when there are 10 tables or more in use - [#421](https://github.com/cfwheels/cfwheels/issues/421) [Don Humphreys, Tony Petruzzi]
- Fixed a regression bug in the dateTimeSelect() function - [#413](https://github.com/cfwheels/cfwheels/issues/413) [Andy Bellenie]
- Fixed bug in dynamic belongsTo() methods - [#420](https://github.com/cfwheels/cfwheels/issues/420) [Andy Bellenie]
- Fixed error with a call to http://localhost/badtemplate.cfm not showing the output of the onmissingtemplate.cfm file - [Clarke Bishop, Andy Bellenie, Per Djurner]
- Corrected link in error email when URL rewriting is on - [Andy Bellenie]

----

## [1.0.2] => 2010.02.19

### Bug Fixes

- Added work-around for CF9 / OSX related "extends" bug in MySQL adapter - [#378](https://github.com/cfwheels/cfwheels/issues/378) [Russ Johnson, Jordan Sitkin, John C. Bland II, Per Djurner]
- Fixed call to non existing function in URLFor() - [Andy Bellenie, Per Djurner]

----

## [1.0.1] => 2010.02.16

### Bug Fixes

- Fixed bug in MS SQL adapter when paginating and ordering on identically named columns from two tables - [#355](https://github.com/cfwheels/cfwheels/issues/355) [Don Bellamy, Per Djurner]
- Fixed bug where soft deleted rows were returned when using the include argument - [#344](https://github.com/cfwheels/cfwheels/issues/344) [Andy Bellenie, Per Djurner]
- Fixed bug where humanize() would add a space at the beginning of the string if it started with an upper case character - [#359](https://github.com/cfwheels/cfwheels/issues/359) [Per Djurner]
- To fix bugs with change tracking CFWheels will now only check for changes to properties that exist on the model object - [#353](https://github.com/cfwheels/cfwheels/issues/353) [James Gibson, Per Djurner]
- Fixed so the keys we use for caching always return identical results so they do not break the cache unnecessarily - [Andy Bellenie, Per Djurner]
- Fixed so average() with integer values work in Railo - [#331](https://github.com/cfwheels/cfwheels/issues/331) [Raul Riera, James Gibson, Per Djurner]
- Fixed so the "for" attribute on form helpers always matches the "id" attribute when it's passed in by the developer - [#340](https://github.com/cfwheels/cfwheels/issues/340) [Chris Peters, Per Djurner]
- Fixed so findAll() afterFind callbacks run when one record is returned - [#327](https://github.com/cfwheels/cfwheels/issues/327) [Ryan Hoppitt, Per Djurner]
- Wrapped debug output completely in "cfoutput" tags so that it works when "enableCFOutputOnly" has been set to true - [William Fisk, Per Djurner]
- Fixed a bug with pagination with outer joins that was creating SQL errors when no records were returned from the pagination query - [James Gibson]
- Made the "objectName" argument check for the object in the "variables" scope by default instead of unscoped - [#365](https://github.com/cfwheels/cfwheels/issues/365) [John C. Bland II, Per Djurner]
- Fixed so the this.dataSource setting is picked up by CFWheels when used - [#333](https://github.com/cfwheels/cfwheels/issues/333) [Chris Peters, Per Djurner]
- Fixed so you can use the built-in validation methods for properties that does not exist in the database table - [#362](https://github.com/cfwheels/cfwheels/issues/362) [Andy Bellenie, Per Djurner]
- Fixed so primary key column is not added to order clause when paginating if it has already been specified with tableName.columnName syntax - [Per Djurner]
- Fixed so pluralization/singularization works with camelCased variable names - [Chris Peters, Per Djurner]
- Added line break to stylesheetLinkTag and javaScriptIncludeTag output - [#372](https://github.com/cfwheels/cfwheels/issues/372) [Tony Petruzzi]
- Fixed bug with select() and selectTag() failing with empty collections as options - [#374](https://github.com/cfwheels/cfwheels/issues/374) [Tony Petruzzi]
- Added missing option "variableName" to validatesFormatOf() options - [#337](https://github.com/cfwheels/cfwheels/issues/337) [Raul Riera, Per Djurner]
- Get disallowed methods from Wheels.cfc instead to allow methods in Controller.cfc to be executed as actions - [Per Djurner]
- Fixed so all callbacks run when the valid() method is called - [#303](https://github.com/cfwheels/cfwheels/issues/303) [Tony Petruzzi]
- Allow private methods to be used as controller filters - [#380](https://github.com/cfwheels/cfwheels/issues/380) [Tony Petruzzi]
- Fixed so the date form helpers can accept a blank string as the default value - [#391](https://github.com/cfwheels/cfwheels/issues/391) [Andy Bellenie]
- Fixed so that the "for" and "id" HTML attributes match when passing an empty string in "tagValue" - [#303](https://github.com/cfwheels/cfwheels/issues/303) [Tony Petruzzi]
- Added the datetime2 data type to the Microsoft SQL Server adapter - [#401](https://github.com/cfwheels/cfwheels/issues/401) [Per Djurner]
- Fixed so queries created in afterFind callbacks can be referenced from view helpers - [James Gibson]
- Fixed so links are properly hyphenated when controller/action is part of the placeholder route values. - [William Fisk, Per Djurner]

----

# [1.0] => 2009.11.24

### Model Enhancements

- Added "xml" datatype for SQL Server 2005/2008 - [#295](https://github.com/cfwheels/cfwheels/issues/295) [Andy Bellenie, Per Djurner]
- Added the Railo specific cfquery attribute called "psq" to make CFWheels run on a default installation of Railo - [Raul Riera, Per Djurner]
- Changed setProperties() to allow any passed in variable to be set on the object - [Per Djurner]
- Changed properties() so that it returns anything in the this scope that is not a function - [Per Djurner]
- Modified so SUM, AVG, MIN, MAX returns blank string and COUNT returns 0 when no records are found - [Tony Petruzzi, Per Djurner]
- Support for "if"/"unless" in validate(), validateOnCreate() and validateOnUpdate() - [Per Djurner]
- Support for built-in CFML types in validatesFormatOf() - [Raul Riera, Per Djurner]
- Added "allowBlank" argument on validatesUniquenessOf() - [#271](https://github.com/cfwheels/cfwheels/issues/271) [Per Djurner]
- Removed a query in findAll that didn't need to run when the join type was set to inner - [Mike Henke, Per Djurner]
- Updated model error functions to take and perform actions with properties and name errors - [Tony Petruzzi]

### View Enhancements

- Consistent style and reload links added to debug area - [Per Djurner]
- Trimmed final output's white space - [#279](https://github.com/cfwheels/cfwheels/issues/279) [Chris Peters, Per Djurner]
- Humanized list / array items in \$optionsForSelect() - [#267](https://github.com/cfwheels/cfwheels/issues/267) [James Gibson]

### Controller Enhancements

- Rewrite Rules for IIS7 - [Sameer Gupta, Mike Rampton, Per Djurner]
- Rewrite support in sub folders in Apache - [Peter Amiri]
- Turned off rewriting for "robots.txt" file - [#278](https://github.com/cfwheels/cfwheels/issues/278) [Chris Peters, Per Djurner]

### Bug Fixes

- Fixed AVG SQL calculation when dealing with integer values - [Tony Petruzzi, Per Djurner]
- Fixed so that CFID and CFTOKEN values do not get obfuscated when passed in the URL - [James Gibson]
- Fixed so javaScriptIncludeTag and styleSheetLinkTag can work with files with multiple dots in them - [#312](https://github.com/cfwheels/cfwheels/issues/312) [Mike Henke, Tony Petruzzi]
- Included calculated properties in the propertyNames(), reload(), updateAll(), deleteAll(), includePartial() and renderPartial() methods - [Per Djurner]
- Allow dynamic methods to be called through callbacks - [James Gibson, Per Djurner]
- Fixed so you can pass in the "properties" argument to dynamic methods (it was overridden previously) - [Per Djurner]
- Allow passing along the original where clause when paginating with a criteria on a joined table - Groups [Don Humphreys, Per Djurner]
- Removed unnecessary singularization for associations - Groups [Don Humphreys, Per Djurner]
- Fixed so validations respect the "allowBlank" setting - Groups [Raul Riera, Per Djurner]
- Corrected execution time report when reloading application - [Tony Petruzzi, Per Djurner]
- Allowing negative values in where clause - Groups [Don Humphreys, Tony Petruzzi]
- Work-around for a Railo mapping bug that was causing slowness - [#268](https://github.com/cfwheels/cfwheels/issues/268) [Tony Petruzzi, Per Djurner]
- Fixed an includePartial() error with caching that occurred in production mode - [#285](https://github.com/cfwheels/cfwheels/issues/285) [James Gibson, Per Djurner]
- Support passing in a single column query to select() and selectTag() - [#300](https://github.com/cfwheels/cfwheels/issues/300) [Tony Petruzzi]
- Fixed radio button ids to work properly with negative number values - [#274](https://github.com/cfwheels/cfwheels/issues/274) [Elezotte, Per Djurner]
- Removed display of "rewrite.cfm" in error emails - [#280](https://github.com/cfwheels/cfwheels/issues/280) [Raul Riera, Per Djurner]
- Fix for layout handling in sendEmail() on multipart emails - [#269](https://github.com/cfwheels/cfwheels/issues/269) [Chris Peters, Per Djurner]
- Throw CFWheels errors based on the "showErrorInformation" setting instead of production mode - [#276](https://github.com/cfwheels/cfwheels/issues/276) [Tony Petruzzi, Per Djurner]
- Fixed so includePartial() / renderPartial() returns a blank string when passed an empty array instead of an error - [#287](https://github.com/cfwheels/cfwheels/issues/287) [James Gibson, Per Djurner]
- Fixed a problem with file naming and case on Linux / Unix when using helpers and plugins - [Chris Peters, Per Djurner]
- Fixed so pagination aborts early when no records exist in the table instead of causing an error - Groups [Per Djurner, James Gibson]
- Fixed so return type is correct when no records are found on using findOne() with returnAs="object" - [Raul Riera, Per Djurner]
- Fixed Railo bug caused by argument defaults on a number of functions - [#201](https://github.com/cfwheels/cfwheels/issues/201), #264 [William Fisk, Tony Petruzzi, Per Djurner]
- Fixed so you can order on included tables in finders without specifying table name - [Per Djurner]
- Fixed so pagination returns an empty query instead of the full record set when specifying a page out of range - [Per Djurner]

### Miscellaneous

- Support for setting Application.cfc this scoped variables through config/app.cfm - [#315](https://github.com/cfwheels/cfwheels/issues/315) [Jay McEntire, Per Djurner]
- Allow plugin developer to specify a list of supported CFWheels versions instead of just one - [Chris Peters, Per Djurner]
- Methods from plugins can now be injected to "Application.cfc" - [#288](https://github.com/cfwheels/cfwheels/issues/288) [James Gibson, Per Djurner]
- Refactored validations code - [#266](https://github.com/cfwheels/cfwheels/issues/266) [Per Djurner]
- Copied cgi scope to request scope - [#277](https://github.com/cfwheels/cfwheels/issues/277) [Tony Petruzzi, James Gibson, Per Djurner]
- Removed an unnecessary variable assignment - [#265](https://github.com/cfwheels/cfwheels/issues/265) [William Fisk, Per Djurner]
- Added informative error messages for common CFWheels mistakes - [James Gibson, Per Djurner]
