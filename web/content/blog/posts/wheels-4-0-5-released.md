---
title: 'Wheels 4.0.5: a hardening release — 100+ fixes across security, performance, and deploy, now installable anywhere'
slug: wheels-4-0-5-released
publishedAt: '2026-06-19T13:30:00.000Z'
updatedAt: '2026-06-19T13:30:00.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - release-notes
  - frameworks
categories:
  - Releases
excerpt: >-
  Wheels 4.0.5 is out, and together with 4.0.4 it's one of the most substantial
  hardening passes on the 4.0 line — 100+ changes spanning security (open-redirect
  and info-disclosure fixes, fail-closed gates, SQL-surface tightening), warm-path
  performance, a much tougher `wheels deploy`, and Adobe CF / BoxLang cross-engine
  fixes. 4.0.5 then makes the whole thing installable the same way on every major
  platform — Homebrew, Scoop, apt, dnf — including arm64 Linux, verified daily.
---

Wheels 4.0.5 is out — and the story is really two releases. **4.0.4 was a large hardening pass (100+ commits across security, performance, and deploy), and 4.0.5 makes that work installable the same way on every major platform, including arm64 Linux.** 4.0.4 went out and was superseded by 4.0.5 the same day, before any announcement, so this post covers both.

## Security hardening

4.0.4 closed a batch of real security gaps in the framework's request surface:

- **Open-redirect hardening.** `$isSafeRedirectUrl()` now normalizes input per WHATWG URL parsing (stripping embedded tab/CR/LF) before it classifies a redirect, and rejects backslash and schemeless-authority tricks (`/\evil.com`, `\/evil.com`, `https:/evil.com`).
- **Information disclosure.** The HTML and JSON branches of `/wheels/info` no longer render secrets — `csrfCookieEncryptionSecretKey` is no longer printed in plaintext, and the JSON branch no longer dumps the full application metadata (datasource credentials, ORM settings).
- **Fail-closed by default.** The production block on `/wheels/*` dev-UI handlers is now a fail-closed allowlist, and the URL reload gate refuses to act unless a non-empty `reloadPassword` is configured — `?reload=true` with no password set is denied, not allowed.
- **Path traversal.** `$getRequestFormat` rejects non-alphanumeric `url.format` values, closing a local-file-inclusion vector through the error-template include.
- **SQL surface.** Scope-handler arguments and `findAll(select=)` items are tightened (values like `Union Pacific` round-trip unchanged while genuinely suspicious `select` items get flagged), and `updateAll(include=)` join parsing no longer splits on a bare `ON` token inside an identifier.
- **Proxy trust.** A new `trustProxyHeaders` setting (default `false`) governs whether `X-Forwarded-*` is believed — `isSecure()`, maintenance-mode IP exceptions, and the reload rate-limit key all stop trusting client-supplied forwarded headers unless you opt in.
- **Deploy secrets** are redacted from remote-execution failure messages and sent over SSH stdin (`docker login --password-stdin`) so they never surface in output.

## Performance

Ten warm-path optimizations, focused on the work every request repeats:

- `model()` and `controller()` take a **lock-free fast path** on cache hits instead of a reflective double-checked lock.
- `URLFor()` route lookups are memoized in application scope (with negative caching), and database column metadata is cached per datasource+table.
- The per-request action-dispatch gate is now an **O(1)** lookup instead of an O(n) list scan, the HTTP status-code map and partial column lists are memoized instead of rebuilt per render, and mixin-free apps no longer pay for a throwaway `wheels.Plugins` instance on every request.

## `wheels deploy` grew up

The Kamal-port deploy command got roughly twenty fixes hardening it for real fleets:

- Works on **fresh hosts** now (the proxy boot guard never reached `boot()`), acquires its fleet lock **all-or-nothing**, bounds secret resolution with a timeout, and writes an on-server audit trail.
- Correct `rollback --destination` overlay handling, proxy traffic built from `proxy.app_port`, env-file secret delivery to app and accessory containers, stricter IPv6 host validation, and same-version redeploys that no longer collide on the container name.

## Cross-engine fixes

- **Adobe ColdFusion**: authorized reloads returned HTTP 500 on case-sensitive filesystems — i.e. every stock Linux Adobe deployment — and URL environment switches into production/maintenance silently reverted. Both fixed, along with a Lucee-only `cfabort;` that 500'd `GET /` on Adobe.
- **BoxLang**: hardened null handling across the router, dispatcher, and error handler for BoxLang's stricter semantics.
- **Oracle / SQL Server**: identity retrieval after INSERT now uses the JDBC driver's generated keys (or session-scoped sequence values) instead of the race-prone `@@IDENTITY` / `MAX(ROWID)` fallbacks.

## New capabilities

- **`wheels jobs work`** — a long-lived background-job worker loop (`--queue`, `--interval`, `--max-jobs`), plus `wheels jobs status`.
- **`wheels upgrade apply`** swaps an app's `vendor/wheels/` for the framework bundled in the installed CLI, and **`wheels upgrade check --strict`** escalates advisory findings to a hard CI-gating failure.
- A `subpath` setting for subfolder-mounted apps, a `/up` liveness/warm-up endpoint in scaffolded apps (used by the deploy healthcheck), and per-tool MCP input schemas.

…and roughly **eighty fixes** in total — routing `scope()`/`namespace()` callbacks, named capture groups, CORS duplicate-header arbitration, multi-node `RateLimiter` storage, honest `migrate`/`seed`/`test` exit codes and output, `hasMany` shortcut associations, and more. The complete list is in the [changelog](https://github.com/wheels-dev/wheels/blob/main/CHANGELOG.md).

## Now install it anywhere — including arm64

4.0.5's own headline is distribution. The `wheels` CLI installs the same way on every major platform:

```bash
# macOS / Linux — Homebrew
brew install wheels-dev/wheels/wheels

# Windows — Scoop
scoop bucket add wheels https://github.com/wheels-dev/scoop-wheels
scoop install wheels

# Debian / Ubuntu — apt
curl -fsSL https://apt.wheels.dev/wheels.gpg | sudo gpg --dearmor -o /usr/share/keyrings/wheels.gpg
echo "deb [signed-by=/usr/share/keyrings/wheels.gpg] https://apt.wheels.dev stable main" | sudo tee /etc/apt/sources.list.d/wheels.list
sudo apt update && sudo apt install wheels

# RHEL / Fedora / Rocky / Alma — dnf
sudo dnf config-manager --add-repo https://yum.wheels.dev/wheels.repo
sudo dnf install wheels
```

The Linux `.deb`/`.rpm` are now **architecture-independent** — the CLI launches through a portable `java -jar` runner — so `apt install` / `dnf install` work on **arm64 (aarch64)** as well as x86_64: Raspberry Pi, AWS Graviton, Ampere, arm64 Linux VMs on Apple silicon. 4.0.5 also fixes a bug where the RHEL/Fedora package couldn't locate its Java runtime, so `dnf install wheels` now works out of the box on Rocky, Alma, and Fedora. Java 21 is pulled in automatically on every channel.

And we now **verify all four channels every day**: a CI job installs the published CLI through Homebrew, Scoop, apt, and yum on real macOS / Windows / Ubuntu / Rocky runners (amd64 *and* arm64) and asserts `wheels --version` matches the release — so a broken `brew install wheels` becomes our problem before it becomes yours.

## A note on versions

If you see a **4.0.4** tag, that's expected: 4.0.4 shipped the hardening work above but its Linux packages weren't yet architecture-independent, so 4.0.5 superseded it the same day. Everything in 4.0.4 is in 4.0.5 — just install or upgrade to **4.0.5**.

## Upgrading

```bash
brew upgrade wheels                                          # Homebrew
scoop update wheels                                          # Scoop
sudo apt update && sudo apt install --only-upgrade wheels    # apt
sudo dnf upgrade wheels                                      # dnf
```

Then confirm:

```bash
wheels --version   # Wheels Version: 4.0.5
```

The framework itself lives in `vendor/wheels/` in your app — run `wheels upgrade check` to see anything worth adjusting before you bump a project, or `wheels upgrade apply` to swap it. Happy shipping.
