---
title: 'Wheels 4.0.1: Adobe CF hardening, Windows Scoop fixes, and the post-GA shakeout'
slug: wheels-4-0-1-released
publishedAt: '2026-05-20T23:00:00.000Z'
updatedAt: '2026-05-21T03:51:31.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - release-notes
  - frameworks
categories:
  - Releases
excerpt: >-
  Wheels 4.0.1 is out — the first patch on the 4.0 line. It hardens Adobe
  ColdFusion 2023/2025 compatibility, fixes the Windows Scoop install
  regressions reported after GA, adds CSS-framework presets to
  paginationNav(), short-circuits whereIn([]) so empty filters stop emitting
  invalid SQL, and threads about a hundred smaller fixes through the rest of
  the framework.
coverImage: null
---


Wheels 4.0.1 ships today, eight days after the 4.0.0 GA. It is a patch release in the SemVer sense — no breaking changes, no new public APIs you have to learn — but it is the first patch on a brand-new major, and the post-GA week surfaced a longer list of "this only matters at scale" issues than a normal point release would carry. Roughly a hundred PRs landed between [4.0.0](https://github.com/wheels-dev/wheels/releases/tag/v4.0.0) and [4.0.1](https://github.com/wheels-dev/wheels/releases/tag/v4.0.1).

This post walks through what changed, organized by who hit it.

## Adobe ColdFusion 2023 and 2025: the compat-matrix gauntlet

The headline story is Adobe CF. The 4.0 release verified clean on Lucee 5/6/7 and BoxLang, but the Adobe 2023 and 2025 legs of the compatibility matrix were reporting `0 pass / 0 fail / 0 err` — every request was failing before any test could complete. The root cause was a cascade of three Adobe-specific behaviors stacked on top of each other, each one masking the next.

**`attributeCollection = arguments` is rejected on Adobe CF 2023/2025** ([#2741](https://github.com/wheels-dev/wheels/pull/2741), [#2750](https://github.com/wheels-dev/wheels/pull/2750)). Lucee, BoxLang, and Adobe 2018/2021 all accept the `arguments` scope passed directly to a built-in CFML tag's `attributeCollection`. Adobe 2023 tightened that — it now demands a plain struct, and throws `InvalidHeaderException: Failed to add HTML header` on `cfheader` (and equivalents on `cfcache`, `cfcontent`, `cfmail`, `cfdirectory`, `cffile`, `cflocation`, `cfhtmlhead`, `cfimage`, `cfdbinfo`, `cfinvoke`, `cfwddx`, `cfzip`). The fix is a uniform copy-arguments-to-struct shim across thirteen sites in `vendor/wheels/Global.cfc`. `$header()` is the dispatch-path blocker, but every other helper that wraps a built-in tag needed the same treatment.

**`$header()` masks the original exception when called from `onError`** ([#2756](https://github.com/wheels-dev/wheels/pull/2756)). Even after the `attributeCollection` fix, Adobe CF still rejects `cfheader` calls when the response buffer has already been committed — and CF commits the buffer aggressively when any view content flushes mid-render. The error handler at `EventMethods.cfc:113` calls `$header("Content-Type", "application/json")`, which then threw `InvalidHeaderException` and replaced the upstream exception in the stack. `$header()` now probes `response.isCommitted()` and short-circuits with a best-effort write when the buffer has flushed. A new companion helper, `$responseCommitted()`, lets other tag wrappers adopt the same short-circuit incrementally.

**`env("KEY", "fallback")` silently returned `""` on Adobe CF** (also in [#2756](https://github.com/wheels-dev/wheels/pull/2756)). The second parameter was named `default` — a CFML reserved word (`switch`/`case`/`default`) — and Adobe refuses to bind a parameter with that name at all. Neither the signature default nor a caller-supplied value populated `arguments.default`. Lucee and BoxLang bind it correctly. The fix renames the parameter to `defaultValue` and adds a back-compat shim for the legacy named-arg form `env(name="X", default="Y")` by checking the `arguments` scope for the literal `default` key first. Positional callers — the framework's own pattern — are unaffected.

**Vite asset-walk lost transitive imports on Adobe CF** ([#2756](https://github.com/wheels-dev/wheels/pull/2756)). `viteScriptTag`, `viteStyleTag`, `vitePreloadTag`, and `$viteHtmlHead` were passing arrays from a struct literal to a recursive walker — and Adobe CF copies arrays by value in struct literals, while Lucee and BoxLang share the reference. Every `ArrayAppend()` inside the recursion was writing to a garbage copy. The fix is to pass the parent struct by reference and mutate `arguments.rv.preloads` / `arguments.rv.styles` instead. This is Cross-Engine Invariant #6 in [CLAUDE.md](https://github.com/wheels-dev/wheels/blob/develop/CLAUDE.md) — the kind of thing that bites once per release cycle.

Two more in the same chain: the vendored TestBox `BaseReporter.resetHTMLResponse()` was throwing `IllegalStateException` on already-committed responses, and the test runner's bare `cfheader`/`cfcontent` calls in `runner.cfm` needed to route through the defensive `$header()`/`$content()` helpers so the runner could finish its own end-of-suite reporting. Both shipped in [#2756](https://github.com/wheels-dev/wheels/pull/2756) and [#2745](https://github.com/wheels-dev/wheels/pull/2745).

The Adobe CF 2023/2025 legs are now green.

## Windows: Scoop install actually works

The second user-visible cliff was Windows install. Scoop is the canonical Windows install path for 4.0 (Chocolatey is no longer maintained), and the GA Scoop wrapper was failing on a clean Windows 11 install before LuCLI could even run.

**The `wheels.cmd` wrapper tripped cmd.exe's pre-parser** ([#2766](https://github.com/wheels-dev/wheels/pull/2766), [#2767](https://github.com/wheels-dev/wheels/pull/2767)). The wrapper had been doing `call "%~dp0lucli-<ver>.bat" %*`, which makes cmd.exe pre-parse the entire bat-jar concatenation looking for labels. The bat preamble is ~915 KB, then a `:JAR_BOUNDARY` marker, then raw JAR ZIP bytes. The pre-parser tripped on byte sequences in the ZIP tail and printed `The filename, directory name, or volume label syntax is incorrect.` before exiting. The fix dispatches LuCLI via `"%JAVA_HOME%\bin\java.exe" -client -jar "%~dp0lucli-<ver>.bat" %*` directly — `java` reads the JAR via stream and skips the bat preamble, bypassing cmd's pre-parser entirely. A one-line fallback handles the case where Scoop's extraction lands the inlined JDK at a different path than expected.

**Release artifacts now ship `.zip.sha512` sidecars instead of `.sha512`** ([#2761](https://github.com/wheels-dev/wheels/pull/2761)). The scoop-wheels `autoupdate` config uses `$url.sha512` substitution and expects the `.zip.sha512` shape; the GA artifacts shipped `*.sha512` and `*.md5`, so every non-module artifact 404'd the autoupdater. Four release artifacts and three workflows now produce the correct shape.

**The Scoop install docs now mention the `java` bucket prerequisite**. Scoop's `depends:` declaration doesn't add the dependency bucket on the user's behalf, so users hit `Couldn't find manifest for 'openjdk21' from 'java' bucket` before they could even attempt install. `start-here/installing.mdx` and `command-line-tools/installation.mdx` now lead with `scoop bucket add java`.

If you tried to install on Windows after 4.0.0 dropped and hit any of the above, this is the release that fixes it.

## Pagination view helpers: CSS-framework presets

This is the only meaningfully new user-facing surface in 4.0.1, and it lands because the like-for-like 3.x → 4.0 swap from `paginationLinks()` to `paginationNav()` was forcing Bootstrap apps to do a `Replace()` regex hack to move the `active` class from the anchor to the wrapping `<li>`. `paginationNav()` and `pageNumberLinks()` now accept a `viewStyle` argument with named presets ([#2718](https://github.com/wheels-dev/wheels/pull/2718)):

```cfm
#paginationNav(viewStyle="bootstrap5")#
#paginationNav(viewStyle="bootstrap4")#
#paginationNav(viewStyle="tailwind")#
#paginationNav(viewStyle="plain")#
```

The Bootstrap presets emit the canonical `<nav><ul class="pagination"><li class="page-item active" aria-current="page"><span class="page-link">N</span></li>` structure — active class on the `<li>`, `<span>` (not anchor) for the current page. `viewStyle="plain"` is the default and preserves today's output byte-for-byte, so existing apps are unaffected. The manual-composition arguments (`prepend`, `appendToPage`, `addActiveClassToPrependedParent`, etc.) still exist and were filled out in [#2715](https://github.com/wheels-dev/wheels/pull/2715) and [#2730](https://github.com/wheels-dev/wheels/pull/2730) for callers who want to keep building the markup by hand.

While we were in there, `paginationNav()` also picked up `showFirst` / `showLast` / `showPrevious` / `showNext` tri-state strings (`"auto"`, `"always"`, `"never"`) so the "first/last anchors only render when the window doesn't already reach the boundary" semantics from legacy `paginationLinks(alwaysShowAnchors=false)` come back. And in development, passing an argument that no sub-helper accepts now throws `Wheels.PaginationNav.InvalidArgument` ([#2717](https://github.com/wheels-dev/wheels/pull/2717)) instead of silently dropping it — production behavior is unchanged.

## ORM safety: `whereIn([])` no longer emits invalid SQL

```cfm
// 4.0.0: this emitted "WHERE id IN ()" — JDBC syntax error on every engine
model("Post").whereIn("id", []).count()

// 4.0.1: short-circuits to a zero-row sentinel
model("Post").whereIn("id", []).count()      // 0
model("Post").whereNotIn("id", []).count()   // total count (exclude-none = match-all)
```

The empty-array case isn't exotic — it's what you get back from a form filter with no selections, a sub-query that returned nothing, or any runtime-built collection. [#2736](https://github.com/wheels-dev/wheels/pull/2736) sets an `$alwaysEmpty` flag on the builder so every terminal method (`count`, `findAll`, `findOne`, `first`, `exists`, `updateAll`, `deleteAll`, `findEach`, `findInBatches`) short-circuits before going through the finder. This matches the behavior every mature ORM converged on — Rails, Sequel, Django, Laravel Eloquent — and the new behavior is documented in both copies of the query-builder guide.

## CORS middleware: three fixes you only notice once you ship to production

The `wheels.middleware.Cors` rewrite for 4.0 had a small cluster of issues that only surfaced under real traffic.

- **Preflight requests against verb-restricted routes** ([#2703](https://github.com/wheels-dev/wheels/pull/2703)). `OPTIONS` requests were 404'ing against routes that only declared `POST`/`PUT`/`PATCH`/`DELETE` because route matching ran before middleware. Dispatch now short-circuits unmatched `OPTIONS` requests to the CORS middleware before route resolution, preserving the legacy `set(allowCorsRequests=true)` contract.
- **`Vary: Origin` is now emitted** ([#2707](https://github.com/wheels-dev/wheels/pull/2707)) alongside the reflected `Access-Control-Allow-Origin`, so CDN and reverse-proxy caches don't serve a cached response with the wrong ACAO to a different origin.
- **Multi-origin lists no longer leak into the response header** ([#2704](https://github.com/wheels-dev/wheels/pull/2704)). Configurations like `allowOrigins="https://a.com,https://b.com"` were emitting the raw comma-delimited list as the `Access-Control-Allow-Origin` value when no `Origin` header was present — violating the spec, which requires a single origin or `*`. Origin resolution is now a separate helper that returns a value only when the incoming `Origin` is in the allowlist.

Migration callouts and a 3.x-defaults comparison table were added to the 3.x → 4.x upgrade guide in [#2708](https://github.com/wheels-dev/wheels/pull/2708).

## Plural `mappings` for legacy callsite preservation

Packages now register additional dotted CFML mapping aliases beyond the singular `mapping` identifier ([#2739](https://github.com/wheels-dev/wheels/pull/2739)):

```json
{
  "name": "wheels-sentry",
  "mapping": "wheelsSentry",
  "mappings": {
    "plugins.sentry": "."
  }
}
```

This is the bridge that lets a package keep `new plugins.sentry.SentryClient()` resolving when it's installed at `vendor/wheels-sentry/` instead of `plugins/sentry/`. Each segment must match `[A-Za-z_][A-Za-z0-9_]*`, absolute paths and `..` traversal are rejected, and collisions across packages fail the offending package and unwind its registration so the mapping registries stay internally consistent. The per-package mapping derivation that landed in [#2712](https://github.com/wheels-dev/wheels/pull/2712) — defaulting to lower-camel-case of the manifest name — is the underlying machinery.

## Oracle and CockroachDB compat-matrix legs

Two long-standing red rows in the compatibility matrix turned green.

**Oracle bulk insert** ([#2745](https://github.com/wheels-dev/wheels/pull/2745)). `model.insertAll()` was emitting the SQL-standard multi-row table value constructor — `INSERT INTO t (cols) VALUES (?,?), (?,?), ...` — which Oracle 23 rejects when the JDBC driver's implicit `RETURN_GENERATED_KEYS` handling expands into a `RETURNING ROWID` clause. Bulk-insert SQL moved off the model mixin onto the database adapter (mirroring the existing `$upsertSQL` pattern), and the Oracle adapter overrides it to emit `INSERT ALL ... SELECT 1 FROM dual` — neither uses the table value constructor nor triggers the RETURNING expansion. Non-Oracle adapters keep the standard form. The companion `Migrator.renameSystemTables()` fix sidesteps Oracle's implicit-DDL-commit by skipping the transaction wrapper on Oracle.

**CockroachDB advisory locks** ([#2743](https://github.com/wheels-dev/wheels/pull/2743)). `CockroachDBModel` inherits from `PostgreSQLModel`, which reports `$supportsAdvisoryLocks() == true`, so the four `lockingSpec :: withAdvisoryLock` tests were proceeding through to `$acquireAdvisoryLock` and erroring. The CockroachDB adapter now correctly reports `false` and the specs skip cleanly via the capability flag's `beforeEach` skip-guard. The capability flag itself was introduced in [#2670](https://github.com/wheels-dev/wheels/pull/2670) — this PR finishes wiring it.

## BoxLang fixes

Two BoxLang-specific bugs that were generating most of the BoxLang error volume in the compat matrix.

**`engineAdapter.getStatusCode()` was throwing on BoxLang** ([#2646](https://github.com/wheels-dev/wheels/pull/2646)). The BoxLang adapter overrides `getResponse()` to return the `PageContext`, but the inherited `Base.cfc::getStatusCode()` then resolved to `PageContext.getStatus()` — which `BoxPageContext` doesn't expose. The adapter now provides its own `getStatusCode()` that reaches the underlying `HttpServletResponse` via `GetPageContext().getResponse().getStatus()`. This was the single largest source of BoxLang errors (~600 errors across nine test bundles × five databases).

**Internal Wheels routes were 500'ing on BoxLang** (same PR). The BoxLang engine adapter's `invokeMethod` was splitting dispatch into `local.method = obj[name]; local.method()`, which stripped the component receiver under BoxLang's JS-style dispatch — so every `Public.cfc` handler's first call to `$blockInProduction()` failed to resolve. The dispatch is now a single-expression bracket-call that preserves the receiver.

A BoxLang catch-scope quirk also surfaced via `lockingSpec` ([#2744](https://github.com/wheels-dev/wheels/pull/2744)): `local.X = ...` inside a `catch` block doesn't persist past block exit on BoxLang. The locking spec switched to a struct-field pattern (`var state = {flag: false}; ... state.flag = true;`), and the gotcha is now documented as Cross-Engine Invariant #11 in [CLAUDE.md](https://github.com/wheels-dev/wheels/blob/develop/CLAUDE.md).

## CLI hardening

Six fixes in `wheels deploy`, mostly small things that surfaced when real users tried the documented commands.

- `wheels deploy --version=v1.2.3` (the documented Kamal form) was being absorbed by picocli's root `versionHelp` flag before module dispatch could see it. `--release` is the new picocli-safe alias, and the brew/scoop wrappers rewrite `--version[=val]` → `--release[=val]` when `deploy` is the first positional ([#2674](https://github.com/wheels-dev/wheels/pull/2674)).
- `wheels deploy server <verb>` and `wheels deploy secrets <verb>` had the same problem — picocli registers `server` and `secrets` as its own top-level subcommands and shortcut the nested form. Flat aliases (`wheels deploy bootstrap`, `wheels deploy exec`, `wheels deploy fetch-secrets`, `wheels deploy extract-secrets`, `wheels deploy print-secrets`) sidestep the collision; the nested forms are retained for MCP and programmatic callers ([#2677](https://github.com/wheels-dev/wheels/pull/2677), [#2697](https://github.com/wheels-dev/wheels/pull/2697)).
- `wheels deploy` now honors the `ssh:` block in `config/deploy.yml` for every subcommand ([#2672](https://github.com/wheels-dev/wheels/pull/2672)) — previously every `SshPool` defaulted to `root@host:22` regardless of config.
- `wheels deploy init` no longer fails in a freshly generated user app with a template-path resolution error; `DeployMainCli` anchors template resolution to its own CFC location ([#2658](https://github.com/wheels-dev/wheels/pull/2658)).
- `wheels deploy init` also scaffolds a starter `Dockerfile` and `.dockerignore` alongside `config/deploy.yml` and `.kamal/secrets` ([#2673](https://github.com/wheels-dev/wheels/pull/2673)) — the Lucee 7 + Java 21 multi-stage with `/up` HEALTHCHECK aligned with the generated `kamal-proxy` healthcheck.
- `$gitShortSha()` no longer leaks git's `fatal: not a git repository` stderr as the version label when `wheels deploy` runs outside a git repo ([#2671](https://github.com/wheels-dev/wheels/pull/2671)).

## Linux packages and titan production cutover

The 4.0.0 RPM regressions that broke `wheels start` on Rocky Linux during the [titan](https://github.com/paiindustries/titan) production cutover are all fixed ([#2700](https://github.com/wheels-dev/wheels/pull/2700)). The `.deb` and `.rpm` packages now ship the lucli-native `wheels-module` artifact, the LuCLI binary is staged so `basename(argv[0])` is `wheels` (which is what LuCLI's module dispatcher keys on), `.version` and `.channel` files land at `/opt/wheels/`, and `tar` is declared as a runtime dependency since Rocky Linux 10's minimal cloud image doesn't ship it.

## Everything else

A non-exhaustive list of the smaller stuff:

- `wheels packages --help` documents `add` as the canonical install verb and explains why `install` doesn't work (LuCLI's built-in extension installer intercepts the verb before module dispatch) ([#2706](https://github.com/wheels-dev/wheels/pull/2706), [#2713](https://github.com/wheels-dev/wheels/pull/2713)).
- `wheels mcp setup` now writes a stdio-based `.opencode.json` instead of one pointing at the deprecated HTTP MCP endpoint ([#2735](https://github.com/wheels-dev/wheels/pull/2735)).
- `wheels upgrade check --to=4.0.0` scans seven additional documented breakers including the legacy `paginationLinks()` calls in views, with a one-time per-request deprecation `WriteLog` warning emitted at runtime ([#2628](https://github.com/wheels-dev/wheels/pull/2628), [#2714](https://github.com/wheels-dev/wheels/pull/2714)).
- Binary-column property assignment via `setProperties()` / `new()` / `update()` no longer trips the scalar-column type guard on BoxLang or Lucee 6 file uploads, with the carve-out narrowed to array-shape only so struct-on-binary still throws the friendly `Wheels.PropertyIsIncorrectType` from #2412.
- A bunch of docs work on the 3.x → 4.x upgrade guide: the load-order gap for `config/environment.cfm`, the `application.wirebox` → `application.wheelsdi` rename being out-of-scope for `wheels-legacy-adapter`, the `reloadPassword` wiring through `set()` rather than `.env`, the 3.x global `set(allowCorsRequests=true)` path still being honored ([#2627](https://github.com/wheels-dev/wheels/pull/2627), [#2631](https://github.com/wheels-dev/wheels/pull/2631), [#2633](https://github.com/wheels-dev/wheels/pull/2633), [#2709](https://github.com/wheels-dev/wheels/pull/2709)).
- A new "Reading the Changelog" docs page under the Upgrading section explains where `CHANGELOG.md` lives, how to look up PR references, and how to access it offline ([#2719](https://github.com/wheels-dev/wheels/pull/2719)).

## Upgrading

If you're already on 4.0.0, the upgrade is `brew upgrade wheels` (macOS), `scoop update wheels` (Windows), or `apt upgrade wheels` / `dnf upgrade wheels` (Linux). No code changes are required. If you've been running on 3.x and waiting for the post-GA shakeout to settle before jumping, this is a reasonable moment to start — the Adobe CF and Windows cliffs are now smooth.

The [4.0.1 release notes](https://github.com/wheels-dev/wheels/releases/tag/v4.0.1) on GitHub have the full PR list. The [CHANGELOG](https://github.com/wheels-dev/wheels/blob/develop/CHANGELOG.md) carries the longer-form rationale for each entry.

Thank you to everyone who filed issues, attached repros, and ran the bleeding-edge channel after GA — the post-GA bug surface that this release covers exists because real users hit it on real systems and told us about it. As always, the bleeding-edge channel (`brew install wheels-dev/wheels/wheels-be` or the Scoop `wheels-be` manifest) tracks `develop` if you want to ride ahead of the next patch.

Onward to 4.0.2.
