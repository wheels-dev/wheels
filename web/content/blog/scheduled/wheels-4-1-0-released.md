---
title: 'Wheels 4.1.0 released: bcrypt, session auth, pretty routes, and a faster core'
slug: wheels-4-1-0-released
publishedAt: '2026-09-10T14:00:00.000Z'
updatedAt: null
author: Peter Amiri
tags:
  - wheels-4
  - release-notes
  - frameworks
categories:
  - Releases
excerpt: >-
  Wheels 4.1.0 is out — the release where the 4.x backlog shipped and the
  framework got faster. bcrypt password hashing, one-line session auth, route
  bindBy, DI factories, CLI diff/dry-run/offline workflows, a security
  hardening pass, and model instantiation ~2.5x faster than 4.0.3.
coverImage: null
---

Wheels 4.1.0 is out. This release closes the 4.x backlog and lands the performance work that started with a single bug report — plus a hardening pass that makes a lot of things you already assumed were safe actually safe.

Full notes: [GitHub Release v4.1.0](https://github.com/wheels-dev/wheels/releases/tag/v4.1.0) · [CHANGELOG](https://github.com/wheels-dev/wheels/blob/main/CHANGELOG.md)

## The headline features

**bcrypt password hashing.** `bcryptHash()`, `bcryptVerify()`, and `bcryptNeedsRehash()` are now global helpers — pure CFML, no Java objects, OpenBSD/htpasswd/jBCrypt-compatible, and correct on every supported engine including the ones that made it hard. [Deep dive](https://blog.wheels.dev/posts/bcrypt-password-hashing-in-wheels-4-1/).

**One-line session auth.** `injector().enableSession()` in `config/services.cfm` wires the authenticator, the session strategy singleton, and idempotent strategy registration — and composes with a pre-mapped authenticator. [Deep dive](https://blog.wheels.dev/posts/one-line-session-auth-with-enablesession/).

**Pretty routes.** `bindBy="slug"` on a resource binds its `:key` segment to a non-primary-key column via the parameterized finder — `/posts/wheels-4-1-0-released` instead of `/posts/42`. [Deep dive](https://blog.wheels.dev/posts/pretty-urls-with-route-bindby/).

**DI factories.** `map("x").toFactory(function(ctx){...})` binds a name to a closure that receives the container and builds the instance — with full singleton/request-scoped/transient lifecycle support. [Deep dive](https://blog.wheels.dev/posts/dependency-injection-factories-with-tofactory/).

**CLI workflow tools.** `wheels migrate diff` (preview or `--write` schema changes with rename hints), `generate --dry-run`, offline mode, plus fail-closed `wheels test` exit codes and new `wheels doctor` checks. [Deep dive](https://blog.wheels.dev/posts/cli-workflow-upgrades-migrate-diff-dry-run-offline/).

## The performance work

Model instantiation is **~2.5× faster than 4.0.3** on our benchmark rig — the result of a head-to-head 2.5-vs-4.x benchmark that confirmed a user's "4.x is much slower" report, followed by three hot-path changes: request-scoped caching of the mixin plan, compile-time inheritance of the model API, and direct construction. The full story, including the two unrelated bugs the benchmarking surfaced, is in the [write-up](https://blog.wheels.dev/posts/how-we-made-model-instantiation-2-5x-faster/).

## The hardening pass

4.1 ships a release-cycle security hardening pass: fail-closed policies and auth, controller/action retargeting protection, strict mass-assignment mode, zip-slip and path-escape fixes in the plugin system, view-helper encoding fixes, middleware copy semantics, and storage key validation. [What changed, area by area](https://blog.wheels.dev/posts/the-wheels-4-1-security-hardening-pass/).

## And the rest

- **Developer tooling:** a Code Complexity panel in the debug bar and the `wheels coverage` CRAP-ranking command — [write-up](https://blog.wheels.dev/posts/wheels-coverage-and-the-complexity-panel/).
- **Engine compatibility:** the Adobe CF 2023/2025 matrix failures are fixed (debug bar, `"Null"` string binding, nested hasMany keys, pagination params) and the core suite runs clean on the JVM-free RustCFML engine.
- **Deploy:** Kamal-compatible `boot` config (`limit`/`wait`) for `wheels deploy`.
- **Deprecations:** `wheels.Test` (RocketUnit) now emits a one-time deprecation warning; removal is planned for Wheels 5.0. If you still run RocketUnit suites, this is your heads-up.

## Upgrading

```sh
wheels upgrade check
wheels upgrade apply
```

The upgrade is additive — the changes that alter behavior are opt-in (strict mass assignment, `sanitizeHref`, JWT `requireExpiry`) or bug fixes to documented defaults. The changelog's "changed" section is the complete list of the latter; it's a ten-minute read and worth it before you deploy.

Thanks as always to everyone who filed the issues that shaped this release — especially the performance report that started the whole investigation.
