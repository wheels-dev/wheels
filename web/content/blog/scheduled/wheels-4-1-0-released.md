---
title: 'Wheels 4.1.0 is out — the release a bug report built'
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
  Wheels 4.1.0 is out: bcrypt, one-line session auth, pretty routes, DI
  factories, CLI diff/dry-run/offline, a security hardening pass, and model
  instantiation ~2.5x faster. Every one of those threads traces back to a
  single issue filed by @chapmandu — and the release is better because it
  didn't start with a features list.
coverImage: '/blog-images/4-1/wheels-4-1-0-released.png'
announcement:
  title: 'Wheels 4.1.0 is out'
  body: |
    **[Wheels 4.1.0 is released](https://blog.wheels.dev/blog/wheels-4-1-0-released)** — the full changelog and where to get it.
---

Wheels 4.1.0 is out. If you've followed [the series](https://blog.wheels.dev/posts/wheels-4-1-coming/), you know this release has a plot, and it starts with [@chapmandu](https://github.com/chapmandu) asking, politely, whether we'd ever benchmarked Wheels 4 against 2.5.

He'd ported a real app. His test suite went from five minutes to half an hour. And as it turned out, **he was right.** That single report is the reason this isn't just another features-and-fixes release — it's the reason the framework got meaningfully faster, and the reason a couple of hard-to-find bugs are gone.

Full notes: [GitHub Release v4.1.0](https://github.com/wheels-dev/wheels/releases/tag/v4.1.0) · [CHANGELOG](https://github.com/wheels-dev/wheels/blob/main/CHANGELOG.md)

## The features, and what they're really about

**bcrypt password hashing.** `bcryptHash()`, `bcryptVerify()`, `bcryptNeedsRehash()` — pure CFML, no Java objects, OpenBSD/htpasswd/jBCrypt-compatible, correct on every engine. The [deep dive](https://blog.wheels.dev/posts/bcrypt-password-hashing-in-wheels-4-1/) starts with a pentest report, but it's really about the migration dance you'll do to use them.

**One-line session auth.** `injector().enableSession()` in `config/services.cfm`. The [story](https://blog.wheels.dev/posts/one-line-session-auth-with-enablesession/) is the three subtle bugs it exists to prevent — the strategy that isn't there, the duplicate, the logged-in-user-who-isn't.

**Pretty routes.** `bindBy="slug"` turns `/posts/4821` into `/posts/wheels-4-1-released`. The [deep dive](https://blog.wheels.dev/posts/pretty-urls-with-route-bindby/) is the unshareable link and the two ways to get it wrong.

**DI factories.** `toFactory()` for when `to()` can't express *how* something gets built. [The story](https://blog.wheels.dev/posts/dependency-injection-factories-with-tofactory/) is the service that couldn't decide where its files lived.

**CLI workflow tools.** `migrate diff`, `generate --dry-run`, offline mode, fail-closed exit codes. [The story](https://blog.wheels.dev/posts/cli-workflow-upgrades-migrate-diff-dry-run-offline/) is two deploy incidents and the CLI learning to show its work.

## The centerpiece: performance

Model instantiation is **~2.5× faster than 4.0.3** on our benchmark rig — the result of the investigation [@chapmandu](https://github.com/chapmandu)'s report started. Request-scoped plan caching, compile-time inheritance of the model API, and direct construction instead of a DI round-trip and a reflective invoke. The full story — including the two unrelated bugs the benchmarking surfaced — is in the [write-up](https://blog.wheels.dev/posts/how-we-made-model-instantiation-2-5x-faster/).

## The hardening pass

4.1 also ships a release-cycle security hardening: fail-closed policies and auth, controller retargeting protection, strict mass-assignment mode, zip-slip and path-escape fixes, view-helper encoding, middleware copy semantics, storage key validation. The theme is one word: **fail closed.** [Area by area](https://blog.wheels.dev/posts/the-wheels-4-1-security-hardening-pass/).

## And the rest

- **Developer tooling:** a Code Complexity panel and the `wheels coverage` CRAP-ranking command — [the tool that would have caught the September bug](https://blog.wheels.dev/posts/wheels-coverage-and-the-complexity-panel/).
- **Engine compatibility:** the Adobe CF 2023/2025 matrix failures are fixed, the core suite runs clean on the JVM-free RustCFML engine, and the Adobe `applicationStop()` teardown crash ("Element wo is undefined", which could error a whole site until a CF restart) is gone — `onApplicationEnd`, `onSessionEnd`, and `onError` now survive a torn-down application scope.
- **Deploy:** Kamal-compatible `boot` config (`limit`/`wait`).
- **Deprecations:** `wheels.Test` (RocketUnit) now warns once; removal is planned for Wheels 5.0. If you still run RocketUnit suites, that's your heads-up.

## Upgrading

```sh
wheels upgrade check
wheels upgrade apply
```

The upgrade is additive — the behavior-changing items are opt-in (strict mass assignment, `sanitizeHref`, JWT `requireExpiry`) or bug fixes to documented defaults. The changelog's "changed" section is the complete list of the latter; it's a ten-minute read and worth doing before you deploy.

One manual step if you run **Adobe CF 2023/2025**: the teardown hardening ships in `public/Application.cfc`, which the `vendor/wheels/` swap doesn't touch. `wheels upgrade check` now flags that drift automatically — diff your `public/Application.cfc` against the bundled template and adopt the guarded `onError`/`onSessionEnd` handlers before you deploy. (Lucee and BoxLang apps are unaffected.)

## The thanks

Releases usually end with thanks to the people who filed the issues. This one means it more than most. [@chapmandu](https://github.com/chapmandu) asked a question we should have been asking ourselves, and the answer reshaped the framework — not just its speed, but how we'll measure it next time.

If you're on an older 4.0.x and your suite got slower somewhere along the way, this is the release to try. And if it's still slow, file it. The rig is built, and it's listening before it argues.
