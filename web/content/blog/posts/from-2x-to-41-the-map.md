---
title: '2.x to 4.x: why it''s two passes, and the map'
slug: from-2x-to-41-the-map
publishedAt: '2026-10-05T21:00:00.000Z'
updatedAt: '2026-10-03T02:31:40.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - wheels-3-0
  - upgrade
  - migration
categories:
  - Tutorials
excerpt: >-
  The first post in "From 2.x to 4.1: the field guide". Going from Wheels 2.x
  to 4.1 takes two passes: 2.x to 3.0.0+33 (the layout move), then 3.0 to 4.1
  (the framework swap and the 4.x breaking changes). This post shows what each
  pass touches, which files no upgrade command ever touches, and the real
  CFWheels 2.2 app we upgrade on camera, wheels-dev/cfwheels-example-app, with
  one branch and one commit per step.
coverImage: null
---

The question we hear most from teams on Wheels 2.x is some version of "can I jump straight to 4.x, and what am I in for?" This series answers it by doing it. We take one real CFWheels 2.2 app all the way to Wheels 4.1.2, fix what breaks in the order it breaks, and publish every commit.

This first post is the map: why the upgrade takes two passes, what each pass touches, which files the upgrade never touches, and the app we're upgrading.

## Two passes, not one

The upgrade guides are direct about this. Rule 2 of the [upgrade philosophy](https://guides.wheels.dev/v4-1-0/upgrading/) is "One major at a time": do the 2.x→3.x upgrade, verify your app boots and its tests pass, then do 3.x→4.x. The [2.x to 3.x page](https://guides.wheels.dev/v4-1-0/upgrading/2x-to-3x/) repeats it for anyone hopping 2.x to 4.x in one sitting:

> Skipping the 3.x landing creates a combinatorial upgrade. Many 2→3 breaking changes assume 3.x semantics once applied, and many 3→4 breaking changes assume the same.

So the plan is:

1. **Pass 1: 2.x to 3.0.0+33.** The layout move. Your code goes under `app/`, static files under `public/`, the framework moves from `wheels/` to `vendor/wheels/`, and `public/Application.cfc` becomes the bootstrap. The authority is the frozen [Upgrading to Wheels 3.0.0](https://guides.wheels.dev/v3-0-0/introduction/upgrading/) guide.
2. **Pass 2: 3.0 to 4.1.** The framework swap and the 4.x breaking changes, found with `wheels upgrade check`. The authority is [Upgrading from 3.x to 4.x](https://guides.wheels.dev/v4-1-0/upgrading/3x-to-4x/).

Land pass 1 on exactly `3.0.0+33`, the 3.0 GA build. The next post explains why a caret range isn't safe there.

## What each pass touches

| Area | Pass 1: 2.x → 3.0 | Pass 2: 3.0 → 4.1 |
|---|---|---|
| Layout | `controllers/`, `models/`, `views/`, `global/`, `events/` and `migrator/` move into `app/`; `files/`, `images/`, `javascripts/`, `stylesheets/` and `miscellaneous/` move into `public/` | No change |
| Bootstrap | The root `Application.cfc`, `index.cfm` and `rewrite.cfm` shims give way to `public/Application.cfc`, `public/index.cfm` and `public/urlrewrite.xml` | `public/Application.cfc` is replaced by the 4.1 template (`wheels.Injector`, `application.wheelsdi`) |
| Framework | `wheels/` is deleted; `vendor/wheels/`, WireBox and TestBox are declared in `box.json` | `vendor/wheels/` is swapped for 4.1.2; WireBox and TestBox go away |
| Tests | RocketUnit tests move to `tests/RocketUnit/` | New tests extend `wheels.WheelsTest`; `wheels.Test` still runs but is deprecated, with removal in 5.0 |
| Plugins | Stay in `plugins/` at the project root | Deprecated in 4.0, removed in 5.0: replace them with packages or app code |
| Config and code | Root-relative paths such as `/global/...` need fixing | `reloadPassword`, CSRF settings, `paginationNav()`, migrations with `default=''`, validation conditions |
| Engines | Adobe ColdFusion 2016 and earlier are no longer supported | Lucee 5/6/7, Adobe ColdFusion 2018/2021/2023/2025 and BoxLang |

The engine floor is the one item to check before you start. If you're still on ACF 2016, upgrading the engine is its own project. The guides' rule 3 says to change the framework and the engine one at a time, so you know which change broke what.

## The files upgrades never touch

Swapping `vendor/wheels/`, by hand or with `wheels upgrade apply`, replaces one folder. Everything else in the project is yours to maintain:

- `app/`: controllers, models, views, global functions, events and migrations
- `config/`
- `public/Application.cfc`, `public/index.cfm` and the rewrite files
- `tests/`
- `box.json` and `.env`

`public/Application.cfc` needs the most care. Since 3.0 it's the bootstrap: it sets the mappings, loads `.env`, starts dependency injection, and handles errors and reloads. Several 4.x fixes live in that file, and the [manual upgrade guide](https://guides.wheels.dev/v4-1-0/upgrading/manual-upgrades/) says plainly that the `vendor/wheels/` swap does **not** update it. `wheels upgrade check` reports drift from the bundled template as an advisory. A later post in this series goes through those edits one by one.

## The app: cfwheels-example-app

[`wheels-dev/cfwheels-example-app`](https://github.com/wheels-dev/cfwheels-example-app) is a real CFWheels 2.2 app, Apache-2.0, with its last original commit in June 2022. It has user management, role-based permissions, password resets and an audit log. It's a better test than a toy app because it uses most of what 2.x apps use:

- three plugins, as zips in `plugins/`: FlashMessagesBootstrap, authenticateThis and jsconfirm;
- RocketUnit tests in `tests/Test.cfc`, `tests/functions/` and `tests/requests/`;
- 13 migrations from 2018 in `migrator/migrations/`;
- MySQL, with CommandBox server configs for Lucee 5 and Adobe ColdFusion 2016.

The upgrade lives in two branches next to the untouched `master`:

- [`upgrade/pass-1-wheels-3.0`](https://github.com/wheels-dev/cfwheels-example-app/tree/upgrade/pass-1-wheels-3.0): 2.2 to 3.0.0+33, in 9 commits.
- [`upgrade/pass-2-wheels-4.1`](https://github.com/wheels-dev/cfwheels-example-app/tree/upgrade/pass-2-wheels-4.1): 3.0 to 4.1.2, in 14 commits.

Each commit does one thing, and its message says why: which guide section it follows, or what broke and how we found it. To step through them:

```bash
git clone https://github.com/wheels-dev/cfwheels-example-app.git
cd cfwheels-example-app
git log --reverse --oneline master..upgrade/pass-1-wheels-3.0
git log --reverse --oneline upgrade/pass-1-wheels-3.0..upgrade/pass-2-wheels-4.1
```

The finished branch boots on Lucee 7 with MySQL 8. The old RocketUnit suite still runs (46 tests, 0 failures), and 10 new WheelsTest specs pass.

## The to-do list

Here's the example app checked against the table. This is the running list for the series:

- **Layout:** all six app folders and all five asset folders move.
- **Bootstrap:** `Application.cfc`, `index.cfm`, `rewrite.cfm` and `root.cfm` sit in the project root.
- **Framework:** `wheels/` (2.2.0) is committed to the repo.
- **Engine:** `server-exampleappACF.json` targets `adobe@2016`.
- **Tests:** ten RocketUnit test cases extend `tests.Test` or `app.tests.Test`.
- **Plugins:** three, all replaced in pass 2.
- **Migrations:** nine string and text columns declare `default=''`.
- **Pagination:** two views call `paginationLinks()`.
- **Reload:** `config/settings.cfm` hard-codes `reloadPassword="changeme"`.

Some of these only showed up once the app booted on the new version. That's normal, and it's why the guides insist on a working checkpoint between the passes.

## If you're upgrading

- Back up the database, commit everything, and work in a branch.
- Finish pass 1 before you start pass 2. The app should boot and its tests should run on 3.0.
- Keep the CFML engine fixed while you change the framework.
- Treat `public/Application.cfc` as your file. No upgrade command replaces it for you.

## Thanks

This series exists because people told us where upgrading hurt. Thanks to [@mikegrogan](https://github.com/mikegrogan) ([#3379](https://github.com/wheels-dev/wheels/issues/3379), [D#2887](https://github.com/wheels-dev/wheels/discussions/2887), [D#3323](https://github.com/wheels-dev/wheels/discussions/3323)), [@chapmandu](https://github.com/chapmandu) ([#3213](https://github.com/wheels-dev/wheels/issues/3213)) and [@andoradmiraal](https://github.com/andoradmiraal) ([D#1838](https://github.com/wheels-dev/wheels/discussions/1838)), who reported the problems this series works through.

**Next:** [Pass 1: 2.x to 3.0, the layout move](https://blog.wheels.dev/blog/from-2x-to-41-pass-1-wheels-3).

