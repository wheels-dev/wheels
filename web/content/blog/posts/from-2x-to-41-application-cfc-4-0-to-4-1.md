---
title: 'The file the upgrade doesn''t touch: `public/Application.cfc` from 4.0 to 4.1'
slug: from-2x-to-41-application-cfc-4-0-to-4-1
publishedAt: '2026-10-08T21:00:00.000Z'
updatedAt: '2026-10-03T04:31:29.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - upgrade
  - migration
  - adobe-coldfusion
  - security
categories:
  - Tutorials
excerpt: >-
  Part 4 of "From 2.x to 4.x: the field guide" covers public/Application.cfc,
  the app-owned file that a vendor/wheels/ swap never updates. It replays
  every template change from 4.0.0 to 4.1.2 one commit at a time: the DI
  container, the onError fallbacks, the fail-closed reload gate, the
  X-Wheels-Reload-Password header, IP-based debug access, the session cookie,
  the Adobe teardown handlers, the jBCrypt load path and the .env parser. A
  table says what each edit fixes, which release added it and whether skipping
  it fails safe, and the post shows what changed on Lucee 7 and Adobe
  ColdFusion 2025 after each edit.
coverImage: null
announcement:
  discussionUrl: 'https://github.com/wheels-dev/wheels/discussions/4513'
  title: "From 2.x to 4.x, part 4: the file the upgrade doesn't touch"
  body: |
    New post: **[The file the upgrade doesn't touch: `public/Application.cfc` from 4.0 to 4.1](https://blog.wheels.dev/posts/from-2x-to-41-application-cfc-4-0-to-4-1/)** — `public/Application.cfc` is app-owned, so a vendor/wheels swap never updates it. This post replays every template change from 4.0.0 to 4.1.2, one commit at a time.
---

Swapping `vendor/wheels/` upgrades the framework. It doesn't upgrade `public/Application.cfc`, because that file belongs to your app: `wheels new` writes it once and never touches it again. Between 4.0.0 and 4.1.2 the template copy changed in seven releases (676 lines added, 98 removed), and several of those changes only work once they're in your copy.

That gap is how [#3379](https://github.com/wheels-dev/wheels/issues/3379), reported by [@mikegrogan](https://github.com/mikegrogan), ended. The framework side of the Adobe teardown fix shipped, and the last comment on the issue had to point out that the `onError` and `onSessionEnd` guards "live in `public/Application.cfc`, which a `vendor/wheels/`-only swap does **not** touch".

This post is for an app generated on 4.0.x and upgraded by swapping `vendor/wheels/` only. In [part 3](https://blog.wheels.dev/blog/from-2x-to-41-pass-2-upgrade-check) the example app copied the 4.1.2 template over this file in one step. Here we put the 4.0.0 file back and replay the changes one at a time on a local branch, `series/post4`: 13 commits, after which the file matches the 4.1.2 template byte for byte. We checked the behaviour on Lucee 7 after each step, and the teardown handlers on Adobe ColdFusion 2025 in Docker.

## The short version

If you never edited `public/Application.cfc`, replace it with the copy from the release you're upgrading to: take it from that release's `wheels-base-template-<version>.zip` asset, or from `cli/lucli/templates/app/public/Application.cfc` at its tag (we used `v4.1.2`). Put any settings you added in `config/app.cfm`, which the template includes. If you did edit it, the table below lists every change in the order we applied them.

`wheels upgrade check` reports the file as "App template drift" (an advisory since 4.1.0), but it doesn't list the individual changes, and its suggested fix mentions only the Adobe teardown guards. The guides now have a checklist for this: [Upgrading from 4.0 to 4.1](https://guides.wheels.dev/v4-1-0/upgrading/4x-0-to-4x-1/). This post walks through the same file on a real app and shows what each edit changes.

## Every edit

"Fails safe" means that skipping the edit leaves you no worse off than on 4.0.0, apart from the missing improvement.

| # | Edit | What it fixes | Since | Skip it and... | What to paste |
|---|---|---|---|---|---|
| 1 | DI container | `application.wheelsdi` holds the injector (#2622). `onError()` stops building a new injector on every error page, which wiped `config/services.cfm` registrations (#3061) | 4.0.1, 4.0.4 | **Not safe.** Each error page resets your services | The `application.wheelsdi` lines in `onApplicationStart()`, and the guarded block at the top of `onError()` |
| 2 | `onError()` fallbacks | A minimal 500 page when the Wheels global never came up (#2774). A `try`/`catch` for Adobe tearing the scope down mid-`onError` (#3379). The real failure written to `wheels.log` (#3671) | 4.0.2, 4.1.0, 4.1.1, 4.1.2 | Fails safe for ordinary errors. On those failure paths the original error is lost | `onError()` from the first `if` onward, `$renderMinimalError()`, `$logStartupFailure()` and the `$startupFailure*()` helpers |
| 3 | graphqlclient notice | On Adobe 2025 without the graphqlclient package, the first request after a start returned HTTP 500 (#3726) | 4.1.1 | **Not safe** on Adobe 2025 without that package. Or run `cfpm install graphqlclient` | The `EngineStartupNotice` block at the top of `onError()` |
| 4 | Reload gate | Fails closed: `?reload=` needs a non-empty `reloadPassword` and a matching password, and failed attempts are logged and rate-limited (#3062). Also a constant-time compare (#2927), Adobe reloads that returned HTTP 500 (#3053), and URL environment switching (#3030) | 4.0.4–4.0.6 | **Not safe.** With an empty password, anyone can restart the app | `onRequestStart()`, `$authorizeReload()` and the helpers after it, `$handleRestartAppRequest()`, `$buildRedirectUrl()`, and the handoff block in `onApplicationStart()` |
| 5 | Reload password header | The CLI sends the password in an `X-Wheels-Reload-Password` header "instead of the URL query string, keeping it out of access and proxy logs" (GHSA-x3cm-2j3q-jgg4) | 4.1.1 | Fails safe. The CLI falls back to the query string and prints a notice | The block near the top of `onRequestStart()`, before the reload lock |
| 6 | IP-based debug access | The grant now covers "the allowed client's own request only" (GHSA-8r22-vwcc-v55m) | 4.1.2 | Fails safe: "upgrading alone still protects you" and Wheels logs a one-time warning. Only matters with `allowIPBasedDebugAccess` on | `application.wo.$applyIPDebugAccess();` in place of the old block, and `application.wo.$get("showDebugInformation")` in `onRequestEnd()` |
| 7 | Session cookie | `httpOnly` and `sameSite: "lax"` (#2927), and `Secure` over HTTPS or behind a proxy that sends `X-Forwarded-Proto: https` (#3830) | 4.0.4, 4.1.2 | **Not safe**, and silent | The `this.sessionCookie` block |
| 8 | Teardown handlers | `onApplicationEnd` and `onSessionEnd` go through `arguments.applicationScope.wo`, because on Adobe the live scope may already be gone (#3379) | 4.0.6, 4.1.0 | **Not safe** on Adobe. No effect on Lucee | Both handler bodies |
| 9 | `rootPath` | The path is anchored to `GetCurrentTemplatePath()`, so the test runner can't split the app across two application scopes (#3025) | 4.0.6 | Fails safe. Same value for normal requests | One line |
| 10 | Test context | Test requests get their own application name, so a test run no longer swaps the live `application.wheels` (#3374) | 4.0.6 | Fails safe. The older swap under a lock stays | The `testcontext.cfm` include after `config/app.cfm` |
| 11 | `plugins/` scan | Scans `plugins/` only if it exists. Lucee and Adobe don't need it | 4.0.4 | Fails safe | The `DirectoryExists()` ternary |
| 12 | jBCrypt load path | Loads the jBCrypt jar that ships with Wheels, so `bcryptHash()` and `bcryptVerify()` run in Java | 4.1.0 | **Not safe** if you call bcrypt (see below) | The `resources/java` block |
| 13 | `.env` parser | `1` and `1.0` arrived as boolean `true` (#3641) | 4.1.1 | **Not safe**, and silent | Two lines in `loadEnvFile()` (below) |

## What the replay showed

**The reload gate (4).** With `WHEELS_RELOAD_PASSWORD` blank, the 4.0.0 gate answered an anonymous `?reload=true` with a `302`: the app restarted. After edit 4, the same request got a `200` and no restart. The 4.1 gate needs a non-empty password.

**The header (5).** Before edit 5, a reload that sent the password only in `X-Wheels-Reload-Password` was ignored, and `wheels reload` printed:

```
Note: this app's public/Application.cfc does not accept the reload password in a header, so it was sent in the URL. Update public/Application.cfc from the current Wheels template to keep the password out of server logs.
```

After it, the header reload returned `302`, and the access log line for `wheels reload` was `GET /index.cfm/?reload=true`, with no password in it.

**The session cookie (7).** Before:

```
Set-Cookie: cfid=...;Path=/;Expires=...;HttpOnly
```

After, for a request sent with `X-Forwarded-Proto: https`:

```
Set-Cookie: cfid=...;Path=/;Expires=...;Secure;HttpOnly;SameSite=Lax
```

Without that header there was no `Secure`, as intended.

**jBCrypt (12).** The example app has logged users in with `bcryptVerify()` since part 3. Without the load-path block, the jar isn't on the classpath and bcrypt falls back to pure CFML. On Lucee 7, a single `bcryptHash()` at the default cost didn't finish before the request timeout. With the block, it took 71 ms.

**The `.env` parser (13).** With `P4_ONE=1` and `P4_RATE=1.0` in `.env`, the 4.0.0 parser stored both as `java.lang.Boolean` `true`, on Lucee and on Adobe. After the edit they came through as the number `1` and the string `"1.0"`. The two lines:

```cfm
if (Compare(lCase(local.value), "true") == 0 || Compare(lCase(local.value), "false") == 0) {
	local.value = (Compare(lCase(local.value), "true") == 0);
```

**Adobe teardown (8).** We ran the app in Adobe ColdFusion 2025 with a 20-second session timeout, opened sessions, did one authorized reload and waited for the session reaper. With the 4.0.0 handlers, the reload's `onApplicationEnd` (line 103) and the reaper's `onSessionEnd` (line 127) both logged the error from #3379:

```
Element WO is undefined in a Java object of type class [Ljava.lang.String;.
```

The reaper logged it again every 20 seconds. With the 4.1.2 file, there were no errors, and the app's own `onApplicationEnd` and `onSessionEnd` event files ran (we added a log line to each for the test).

## If you're upgrading

1. Diff your `public/Application.cfc` against the template for the release you're on (4.1.2 in this post). Unless you changed it on purpose, replace it.
2. If you keep your own copy, apply at least edits 1, 4, 7, 12 and 13, plus 3 and 8 on Adobe.
3. Check that `wheels reload` no longer prints the URL notice, and that your session cookie has `Secure` over HTTPS.

The `develop` branch has no further changes to this file yet.

**Previous:** [Pass 2: 3.x to 4.1 with `wheels upgrade check`](https://blog.wheels.dev/blog/from-2x-to-41-pass-2-upgrade-check). **Next in the series:** migrating your 2.x validation conditions.

