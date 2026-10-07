---
title: 'Pass 2: 3.x to 4.1 with `wheels upgrade check`'
slug: from-2x-to-41-pass-2-upgrade-check
publishedAt: '2026-10-07T21:00:00.000Z'
updatedAt: '2026-10-03T02:31:40.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - upgrade
  - migration
  - cli
categories:
  - Tutorials
excerpt: >-
  Part 3 of "From 2.x to 4.1: the field guide" takes the example app from
  Wheels 3.0.0+33 to 4.1.2. It reads the real `wheels upgrade check` output
  before and after, explains why to run the check before swapping
  vendor/wheels, and walks the 14 commits: the framework swap, the 4.1
  public/Application.cfc, plugin replacements, paginationNav(), the CSRF
  settings, a RocketUnit-to-WheelsTest conversion and validation conditions.
  It also covers the breakers only a real boot found: default='' in
  migrations, structs assigned to scalar columns, dates interpolated into
  where strings on 4.1.2, and a reload password the CLI and the app disagreed
  on.
coverImage: null
---

Pass 2 takes the example app from Wheels 3.0.0+33 to 4.1.2 in 14 commits on [`upgrade/pass-2-wheels-4.1`](https://github.com/wheels-dev/cfwheels-example-app/tree/upgrade/pass-2-wheels-4.1). [Pass 1](https://blog.wheels.dev/blog/from-2x-to-41-pass-1-wheels-3) did the layout move. This pass is the framework swap and the 4.x breaking changes, and it starts with `wheels upgrade check`.

## Run the check before you swap vendor/wheels

`wheels upgrade check` is a read-only scan of your app for the patterns that break between your version and the target. Run it from the project root with the 4.1 CLI, while `vendor/wheels/` is still 3.0:

```bash
wheels upgrade check --to=4.1.2
```

On the 3.0 example app it reported five breaking changes and two advisories (output trimmed):

```
Current version: unknown
Target version:  4.1.2

Breaking Changes (5 found):
  ! Old test base class (wheels.Test / wheels.Testbox)
    tests/RocketUnit/Test.cfc:2
  ! Legacy plugin directory (deprecated as of 4.0, removed in 5.0)
    plugins/
  ! Old test base class (wheels.Test / wheels.Testbox)
    tests/RocketUnit/Test.cfc:2
  ! Missing csrfCookieEncryptionSecretKey (CSRF cookies rotate on every deploy when csrfStore="cookie")
    config/ (no occurrences found)
  ! Deprecated paginationLinks() helper (renamed to paginationNav() in 4.0)
    app/views/admin/auditlogs/index.cfm:38
    app/views/admin/users/index.cfm:74

Recommended Improvements (2 found):
  ~ CSRF cookie sets SameSite in 4.0 (advisory: review cross-site POST flows)
  ~ App template drift — public/Application.cfc or public/index.cfm differs from the bundled template
```

Breaking findings make the command exit non-zero, so it can gate CI. Some of this output needs reading with care:

- **`Current version: unknown`.** The check reads the version from `vendor/wheels/wheels.json` or `vendor/wheels/box.json`. The 3.0.0+33 `box.json` has no version, so the check falls back to "unknown", runs the 2.x rules as well, and reports the test base class twice.
- **The CSRF key is a false positive here.** The key only matters for `csrfStore="cookie"`. This app uses the default session store, and the check only looks for the setting name in `config/`.
- **Don't take its RocketUnit advice.** It suggests `extends="wheels.WheelsTest"` for `tests/RocketUnit/Test.cfc`. That breaks every RocketUnit test that inherits from it.

After all 14 commits, the check says:

```
Current version: 4.1.2
Target version:  4.1.2

Same major version — no known breaking changes.
Scanning for opt-in recommendations...

All Clear (3 checks):
```

That's correct, but note why. Once `vendor/wheels/` reports 4.1.2, the check compares 4.1.2 with 4.1.2 and skips every 3→4 rule. Swap first and check second, and you'll see "all clear" with the work still to do. **Run the check before the swap, and keep the output as your to-do list.** These four problems are filed as [#3939](https://github.com/wheels-dev/wheels/issues/3939).

## Swap the framework

[10d921e](https://github.com/wheels-dev/cfwheels-example-app/commit/10d921e06d90c82112c61aac3064933bc6eb9a68) replaces `vendor/wheels/` with the contents of `wheels-core-4.1.2.zip` from the GitHub release, extracted fresh so files deleted in 4.x don't linger. Wheels 4 has dependency injection and testing built in, so WireBox and TestBox leave `box.json`:

```diff
-        "wheels-core":"3.0.0+33",
-        "wirebox":"^7.0.0",
-        "testbox":"^6.0.0",
+        "wheels-core":"4.1.2",
```

`wheels upgrade apply` does the same swap with the framework bundled in your CLI, and backs up the old folder to `vendor/wheels.bak-<timestamp>/` first. Either way, the app won't boot until the next step.

## Adopt the 4.1 public/Application.cfc

The swap doesn't touch this app-owned file, so [02da512](https://github.com/wheels-dev/cfwheels-example-app/commit/02da512bef00da4fc54afa2855f83273db99233d) copies the 4.1.2 template over it verbatim. The core change is dependency injection:

```diff
-		wirebox = new wirebox.system.ioc.Injector("wheels.Wirebox");
+		application.wheelsdi = new wheels.Injector("wheels.Bindings");
```

It also brings the Adobe CF teardown guards in `onApplicationEnd`/`onSessionEnd` (4.0.6 and 4.1.0, [#3379](https://github.com/wheels-dev/wheels/issues/3379), reported by [@mikegrogan](https://github.com/mikegrogan)), fail-closed reloads, and a session cookie that's `secure` over HTTPS. `config/app.cfm` forced `this.sessioncookie.secure = false`, which would undo that, so the line went.

## Three things only a real boot found

**Migrations with `default=''`.** `wheels migrate latest` on an empty MySQL database stopped at the first migration:

```
An empty string default is not allowed for string columns.
```

Since 4.1.0 the migrator throws `Wheels.InvalidDefault` for `default=''` on string, text and char columns. Applied migrations never re-run, so you only find out on a fresh database: a new developer, CI, a test database. [77b4729](https://github.com/wheels-dev/cfwheels-example-app/commit/77b47296e43577ae4ca121b69e55e1d8de5df26c) drops the argument from nine columns, which gives MySQL the same DDL as before:

```diff
-				t.string(columnNames="name,description", default='', null=false );
+				t.string(columnNames="name,description", null=false );
```

**A struct passed to a scalar column.** A failed login returned a 500:

```
Cannot assign a array value to scalar column `data` on the `auditlog` model
```

Since 4.0.0, setting a struct or array on a property that isn't a nested association throws `Wheels.PropertyIsIncorrectType`. The app passed the login errors to `create()` and serialized them in an `afterNew` callback, which now runs too late. [369de1b](https://github.com/wheels-dev/cfwheels-example-app/commit/369de1b9227100b3f0ea558556baafc58a681250) adds a `newEntry()` method that calls `SerializeJSON()` before `new()`.

**A date interpolated into a where string.** On 4.1.2, `/admin/logs` returned a 500:

```
invalid hexadecimal String for, [ ' ]
```

The controller built `createdAt >= '#local.from#'` from a `CreateDateTime()` value. CFML renders that date as `{ts '2026-09-01 00:00:00'}`, and on 4.1.2 the quotes inside it end the surrounding string in the where clause early. We reported it as [#3941](https://github.com/wheels-dev/wheels/issues/3941), and the fix, [#3942](https://github.com/wheels-dev/wheels/pull/3942), ships in Wheels 4.2. Until then, format the date yourself, as [09541df](https://github.com/wheels-dev/cfwheels-example-app/commit/09541dfc2de9652aa25f33ebde06e11943f41a1a) does:

```cfm
arrayAppend(local.where, "createdAt >= '#DateTimeFormat(local.from, "yyyy-mm-dd HH:nn:ss")#'");
```

## The reload password, and the CLI

Wheels 4 makes URL reloads fail closed: `?reload=true` needs a non-empty `reloadPassword` and a matching password. The app hard-coded `"changeme"`, the pattern [@teleotic](https://github.com/teleotic) raised in [D#2854](https://github.com/wheels-dev/wheels/discussions/2854). That still worked, but `wheels migrate latest` failed with "Invalid reload password". The 4.1 CLI looks for `WHEELS_RELOAD_PASSWORD` in `.env` first and only falls back to a literal `reloadPassword="..."` in `config/settings.cfm`. With a value in `.env` and a different one in settings, the CLI sends one password and the app expects another. [c45e48f](https://github.com/wheels-dev/cfwheels-example-app/commit/c45e48f621cb0952cb1bcfec10f764ebade915d6) gives both the same source:

```cfm
set(reloadPassword=env("WHEELS_RELOAD_PASSWORD", ""));
```

## The check's own list

- **Plugins.** [6e21dfd](https://github.com/wheels-dev/cfwheels-example-app/commit/6e21dfd2e94e2be515dc97ead5e439f26ea0fd54) replaces jsconfirm with `dataConfirm=` (helpers pass unknown arguments through as `data-*` attributes) and one click listener, with no `buttonTo()` override at all. That avoids the `super<name>` trouble [@mikegrogan](https://github.com/mikegrogan) hit in [D#3323](https://github.com/wheels-dev/wheels/discussions/3323). [cb28e9c](https://github.com/wheels-dev/cfwheels-example-app/commit/cb28e9c73f9057054067f35cda038768677233b2) moves FlashMessagesBootstrap into a `flashMessages()` override in `app/views/helpers.cfm` that calls `superFlashMessages()`. [f09c6a9](https://github.com/wheels-dev/cfwheels-example-app/commit/f09c6a902676046f31fb467c027e76c3bf471665) replaces authenticateThis with app code on 4.1's `bcryptHash()` and `bcryptVerify()`; existing `$2a$` hashes still verify, and pass 1's login stopgap goes. A later post covers plugins in depth.
- **Pagination.** [3587d82](https://github.com/wheels-dev/cfwheels-example-app/commit/3587d824adb5d5f695813a032ba806ec3371b5ac) swaps both calls to `paginationNav()` and replaces a long Bootstrap settings line with `set(functionName="paginationNav", viewStyle="bootstrap4")`.
- **CSRF.** [5f9ae56](https://github.com/wheels-dev/cfwheels-example-app/commit/5f9ae5603c33a8fe4e68c42577bfade8d3aaa6a0) makes the store explicit and reads the key from the environment, which silences the false positive and is right if the store ever changes:

  ```cfm
  set(csrfStore="session");
  set(csrfCookieEncryptionSecretKey=env("WHEELS_CSRF_KEY", ""));
  ```

- **Tests.** [6afe3b4](https://github.com/wheels-dev/cfwheels-example-app/commit/6afe3b482226b5942bd8f04e9c9f13a5a4ae24c8) converts one file to a WheelsTest spec and leaves the rest of the RocketUnit suite running unchanged. `assert("log.valid()")` becomes `expect(log.valid()).toBeTrue()`, and `setup()` becomes `beforeEach()`.

## Validation conditions

4.1.0 throws `Wheels.InvalidValidationCondition` for a `condition` or `unless` string it can't parse, where 4.0.x skipped the validation. [23056c8](https://github.com/wheels-dev/cfwheels-example-app/commit/23056c895caf6684932dcae3c3eb5b77d6bf39cf) finds the app's two conditions with `git grep -nE 'condition\s*=|unless\s*=' -- app config`. Both parse, and a new spec runs each one both ways so a future change can't break them silently.

## If you're upgrading

1. Run `wheels upgrade check --to=<your target version>` **before** swapping `vendor/wheels/`, and save the output (we used `--to=4.1.2`).
2. Swap the framework, then diff `public/Application.cfc` against the template for the version you moved to.
3. Run your migrations against an empty database to catch `default=''`.
4. Look for structs or arrays assigned to plain columns, and for dates interpolated into `where` strings.
5. Set `reloadPassword` from `env("WHEELS_RELOAD_PASSWORD", "")` so the app and the CLI agree.
6. Keep `wheels.Test` on your RocketUnit base class until those tests are converted.

The finished branch boots on Lucee 7 with MySQL 8. `wheels test` passes 10 specs, and the RocketUnit suite runs 46 tests with 0 failures.

**Previous:** [Pass 1: 2.x to 3.0, the layout move](https://blog.wheels.dev/blog/from-2x-to-41-pass-1-wheels-3). **Next in the series:** the `public/Application.cfc` edits between 4.0 and 4.1.

