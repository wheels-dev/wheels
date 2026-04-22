# Issue #2138: Controllers/views inside /app

## Verdict
FIX NOW

## Summary
The repo-root `app/` contains three framework-internal browser-test fixture controllers plus their views, and a stray demo mailer. These are duplicates of canonical copies that already live in `vendor/wheels/tests/_assets/` and would confuse anyone running/inspecting the framework repo or copying it as a starting template. Route registration for `/_browser` is also leaking into the repo-root `config/routes.cfm`.

## Root cause
CLAUDE.md rule: user controllers/views live at `app/controllers/` and `app/views/`; framework-internal code belongs in `vendor/wheels/` or `cli/lucli/templates/`. The browser-testing PR3 plan (`docs/superpowers/plans/2026-04-15-browser-testing-pr3.md`) originally placed fixtures in `app/` to solve route/view-path resolution. A later change moved the canonical fixtures to `vendor/wheels/tests/_assets/controllers/` + `vendor/wheels/tests/_assets/views/browsertest*/` and switched `vendor/wheels/tests/runner.cfm` + `vendor/wheels/wheelstest/BrowserTest.cfc::beforeAll()` to use them via `set(controllerPath=...)`, `set(viewPath=...)`, and `application.wo.$include(template="/wheels/tests/routes.cfm")`. The old copies under `app/` were never removed. They are dead code.

### Misplaced files (9 files + 3 view dirs) in repo-root `app/`:

1. `app/controllers/BrowserTestHome.cfc` — browser-test fixture. Byte-identical to `vendor/wheels/tests/_assets/controllers/BrowserTestHome.cfc`.
2. `app/controllers/BrowserTestLogin.cfc` — test-only `loginAs` endpoint (env-gated). Canonical copy: `vendor/wheels/tests/_assets/controllers/BrowserTestLogin.cfc`.
3. `app/controllers/BrowserTestSessions.cfc` — login/logout fixture. Byte-identical to `vendor/wheels/tests/_assets/controllers/BrowserTestSessions.cfc`.
4. `app/views/browsertesthome/index.cfm`, `dashboard.cfm`, `layout.cfm` — fixture views. Canonical copies in `vendor/wheels/tests/_assets/views/browsertesthome/`.
5. `app/views/browsertestlogin/create.cfm`, `layout.cfm` — fixture views. Canonical copies in `vendor/wheels/tests/_assets/views/browsertestlogin/`.
6. `app/views/browsertestsessions/new.cfm`, `layout.cfm` — fixture views. Canonical copies in `vendor/wheels/tests/_assets/views/browsertestsessions/`.
7. `app/mailers/UserNotificationsMailer.cfc` + `app/views/usernotificationsmailer/sendEmail.cfm` — stray demo mailer. Not referenced by any test, spec, vendor code, or scaffold. Demo copies already live in `examples/tweet/app/mailers/` and `examples/starter-app/app/mailers/`.

`app/controllers/Controller.cfc`, `app/views/layout.cfm`, and `app/views/helpers.cfm` are the legitimate app-level starting stubs and must stay.

### Route leakage in `config/routes.cfm`
The repo-root `config/routes.cfm` registers the `/_browser` scope (lines 11–18). Not needed — core tests load `/wheels/tests/routes.cfm` via `runner.cfm` (line 25) and `BrowserTest.cfc::beforeAll()` (line 69). User app scaffolds (`cli/lucli/templates/app/config/routes.cfm`) correctly omit this scope.

## Files to change

### Deletions (use `git rm -r` — these are dead duplicates)
```
app/controllers/BrowserTestHome.cfc
app/controllers/BrowserTestLogin.cfc
app/controllers/BrowserTestSessions.cfc
app/views/browsertesthome/          (dir: index.cfm, dashboard.cfm, layout.cfm)
app/views/browsertestlogin/         (dir: create.cfm, layout.cfm)
app/views/browsertestsessions/      (dir: new.cfm, layout.cfm)
app/mailers/UserNotificationsMailer.cfc
app/views/usernotificationsmailer/  (dir: sendEmail.cfm)
```
No `git mv` needed — canonical copies already exist at `vendor/wheels/tests/_assets/` (for browser fixtures). The `UserNotificationsMailer` is a pure demo already present in the example apps; no move required.

### Edits
- `config/routes.cfm` — remove the `/_browser` scope block (lines 10–18). Leave `mapper() … .wildcard() … .root(method="get") … .end();` intact.

### Keep
- `app/controllers/Controller.cfc` (base class stub — required)
- `app/views/layout.cfm`, `app/views/helpers.cfm` (app-level starters)

## Implementation steps
1. `git rm app/controllers/BrowserTestHome.cfc app/controllers/BrowserTestLogin.cfc app/controllers/BrowserTestSessions.cfc`
2. `git rm -r app/views/browsertesthome app/views/browsertestlogin app/views/browsertestsessions`
3. `git rm app/mailers/UserNotificationsMailer.cfc`
4. `git rm -r app/views/usernotificationsmailer`
5. Edit `config/routes.cfm`: delete the `/_browser` `.scope(…)…end()` block including its inner `.get`/`.post` lines and the "Browser test fixture routes" comment. The remaining file should match the lucli scaffold (`cli/lucli/templates/app/config/routes.cfm`) structure: `CLI-Appends-Here` marker → `.wildcard()` → `.root(method="get")` → `.end();`.
6. Grep verify no residual refs: `rg "app/controllers/BrowserTest" .ai/ docs/superpowers/plans/ docs/superpowers/specs/` — if matches exist, those are historical plan docs (`docs/superpowers/plans/2026-04-15-browser-testing-pr3.md`, `-pr3-design.md`); leave them untouched (historical record of decision).
7. Run `bash tools/test-local.sh` — confirm 0 regressions. Browser specs will either skip (no Playwright JARs locally) or still pass because they load the vendor-level routes and controllers.
8. Run `bash tools/test-local.sh browser` (if Playwright installed locally) to explicitly exercise the browser fixture path after removal.
9. Boot the dev app: `lucli server run --port=8080` and `curl -s "http://localhost:8080/?reload=true&password=wheels"` — confirm app reloads clean with no routing errors and no missing-controller errors.
10. Smoke `/`, `/home`, `/login` on the running server — the first should hit the default wildcard/root behavior; the two browser-scoped URLs should now 404 in the repo-root app (they should only exist when core tests bootstrap `runner.cfm`), which is the intended end state.

## Testing
- `bash tools/test-local.sh` — full core suite must remain green (currently ~2667 passing; no change expected).
- `bash tools/test-local.sh browser` — must stay green; this is the regression risk since these files were originally created for browser testing. They've been superseded by `vendor/wheels/tests/_assets/`, so removal is safe, but verify explicitly.
- Repeat against Lucee + Adobe containers for the browser suite if local Playwright is unavailable (per CLAUDE.md cross-engine rule).
- Manual: `wheels start` / `lucli server run`, hit `/` — no errors, layout renders. Hit `/_browser/home` — expect 404 (confirms leaked routes are gone).

## Risk & dependencies
- Very low risk. Files removed are byte-identical duplicates (browser fixtures) or unreferenced demo stubs (mailer). No production code, no scaffold template, no vendor code, no spec references them.
- Not a breaking change for external apps upgrading from 3.x — these files were only ever in the framework repo root, never shipped to user apps. The lucli `init` template (`cli/lucli/templates/app/`) has always scaffolded a clean `app/` and a clean `config/routes.cfm`.
- **No upgrade-guide entry needed.** Confirmed user-facing scaffold is unaffected; this is framework-repo hygiene only. If the triage team disagrees, add a one-line note under `web/sites/guides/src/content/docs/v4-0-0-snapshot/upgrading/3x-to-4x.mdx` → "Housekeeping" section: "Removed stale browser-test fixtures from the framework's own `app/` directory; no action required for application developers."
- Related: #2135 (internal routes in app-level files — same cleanup theme). The `/_browser` scope removal from `config/routes.cfm` directly overlaps; coordinate so both land together or in sequence without merge conflict.
- Historical plan docs under `docs/superpowers/plans/2026-04-15-browser-testing-pr3.md` reference the old `app/` paths. Do NOT edit — they are historical design records.

## Effort estimate
S (≈30 min: delete 9 files + 3 dirs, edit routes.cfm, run full test matrix locally)
