---
title: 'Replacing your 2.x plugins: packages, `super<name>`, and app helpers'
slug: from-2x-to-41-replacing-plugins
publishedAt: '2026-10-12T21:00:00.000Z'
updatedAt: '2026-10-06T00:55:34.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - upgrade
  - plugins
  - packages
categories:
  - Tutorials
excerpt: >-
  Part 6 of "From 2.x to 4.x: the field guide" ports the example app's three
  legacy plugins off the deprecated plugins/ directory. It explains why 2.x
  plugins "just worked" (global mixins and the core. reference), shows what
  4.1.2 logs when plugins are still present, and how packages differ:
  provides.mixins defaults to none. jsconfirm becomes a linkTo()/buttonTo()
  override that delegates with superLinkTo(), the D#3323 case fixed in 4.0.6,
  plus a Lucee bracket-notation gotcha. FlashMessagesBootstrap becomes an app
  helper, and authenticateThis becomes app code on
  bcryptHash()/bcryptVerify(), tested against a hash from the plugin's own
  BCrypt.class. A sidebar covers the five regressions #3520 fixed when we
  upgraded our own apps.
coverImage: null
announcement:
  discussionUrl: 'https://github.com/wheels-dev/wheels/discussions/4582'
  title: "From 2.x to 4.x, part 6: replacing your 2.x plugins"
  body: |
    New post: **[Replacing your 2.x plugins: packages, `super<name>`, and app helpers](https://blog.wheels.dev/posts/from-2x-to-41-replacing-plugins/)** — porting three legacy plugins off the deprecated plugins/ directory to packages, `super<name>` and app helpers, and what 4.1.2 logs while plugins are still present.
---

The example app shipped three plugin zips in `plugins/`: jsconfirm, FlashMessagesBootstrap and authenticateThis. [Pass 2](https://blog.wheels.dev/blog/from-2x-to-41-pass-2-upgrade-check) removed all three in three commits so the upgrade could move on. This post goes back over them properly. It explains why 2.x plugins "just worked", what Wheels 4.x does with them, and how each one ports. For jsconfirm it takes the route [@mikegrogan](https://github.com/mikegrogan) tried in [D#3323](https://github.com/wheels-dev/wheels/discussions/3323): an override of `linkTo()` that calls the framework original through `superLinkTo()`. The work is on branch `series/post6`, three commits on top of pass 2.

## Why 2.x plugins just worked

In 2.5.1 you dropped a zip into `plugins/` and reloaded. `wheels/plugins/initialization.cfm` unzipped it at startup, created the plugin's CFC, and collected its public methods. Unless a plugin said otherwise, each method went into every mixable component: application, dispatch, controller, mapper, model, the database adapters and tests. The code says so: "by default and for backwards compatibility, we inject all methods into all objects".

Before mixing in, `wheels/plugins/standalone/injection.cfm` copied the object's `variables` scope into `variables.core`. That's why jsconfirm could override `linkTo()` and still call `core.linkTo()`. The original was saved before the override replaced it.

## What 4.x does with them

4.1.2 still loads them. We put the three zips back into the finished app and reloaded. It unzipped them and booted, and `wheels.log` showed a deprecation warning for each plugin, plus this one (trimmed):

```
[Wheels] Deprecation: The plugins/ directory is deprecated as of Wheels 4.0 and will be removed in Wheels 5.0. Plugins found: flashmessagesbootstrap,authenticatethis,jsconfirm. Migrate each one to a package installed under vendor/ ...
```

authenticateThis and FlashMessagesBootstrap also got "uses the implicit mixin target 'global' (every mixable component)", because neither declares a target.

The replacement for plugins is packages: a directory under `vendor/` with a `package.json`. One default is reversed. A plugin with no `mixin` attribute went everywhere, but a package with no `provides.mixins` mixes in nothing. The [Packages guide](https://guides.wheels.dev/v4-1-0/digging-deeper/packages/) calls this "a deliberate break from legacy plugins". We tested it with a throwaway package. With `"provides": { "mixins": "model" }`, its method showed up on a `User` instance and not on a controller. With the field removed, it showed up nowhere.

None of our three plugins needed to become a package.

## jsconfirm: an override that calls super<name>

jsconfirm overrode `linkTo()` and `buttonTo()` to turn `confirm="..."` into an inline `onclick`. When mikegrogan replaced it in app code on 4.0.x, `superLinkTo()` returned 500s. At the time, only models registered the `super<name>` aliases. Controllers and view helpers got nothing. The fix ([#3325](https://github.com/wheels-dev/wheels/issues/3325), from D#3323) shipped in 4.0.6. When your code defines a method that a framework mixin also provides, Wheels keeps yours and registers the original as `super<name>`.

`app/views/helpers.cfm` is the place for app-wide view helper overrides. Wheels includes it into every controller before it mixes in the framework helpers, so your `linkTo()` is already there when the framework's arrives. Commit `4d45f76` adds:

```cfm
public string function linkTo() {
  return superLinkTo(argumentCollection=jsConfirmArgs(arguments));
}

public string function buttonTo() {
  return superButtonTo(argumentCollection=jsConfirmArgs(arguments));
}

private struct function jsConfirmArgs(required struct args) {
  local.rv = StructCopy(arguments.args);
  if (StructKeyExists(local.rv, "confirm")) {
    if (Len(local.rv.confirm)) {
      local.rv["dataConfirm"] = local.rv.confirm;
    }
    StructDelete(local.rv, "confirm");
  }
  return local.rv;
}
```

The four `buttonTo()` calls in `admin/users` go back to `confirm=`, as they were before pass 2. `/admin/users/1` now renders `<form ... data-confirm="...">`, and the delegated click listener pass 2 added to `custom.js` shows the dialog. No inline JavaScript comes back.

**Use bracket notation for that key.** Our first version used `local.rv.dataConfirm = ...`, and the page rendered `dataconfirm="..."`. On Lucee a dot-set key loses its camelCase. The helpers only hyphenate a camelCase `data...` name, so the attribute never became `data-confirm`. Wheels' own source warns about the same trap in a comment.

**Or skip the override.** Pass 2 changed the call sites to `dataConfirm=` instead ([6e21dfd](https://github.com/wheels-dev/cfwheels-example-app/commit/6e21dfd2e94e2be515dc97ead5e439f26ea0fd54)). Every helper passes unknown arguments through as attributes. With a few call sites, that's simpler. With hundreds, the override keeps your views as they are.

**In controllers and view helpers, use `superLinkTo()`.** That's the form the [Overriding Core Methods](https://guides.wheels.dev/v4-1-0/digging-deeper/overriding-core-methods/) guide documents. Whether `super.linkTo()` works there is untested on every engine, and is tracked in [#3933](https://github.com/wheels-dev/wheels/issues/3933). In models, 4.1 and later accept three forms: `superDelete()`, `variables.superdelete()` and `super.delete()`. The [manual upgrade notes](https://guides.wheels.dev/v4-1-0/upgrading/manual-upgrades/) say all three were checked on Lucee 7, Adobe CF 2025 and BoxLang.

## FlashMessagesBootstrap: an app helper

This plugin wrapped `core.flashMessages()` and rewrote the markup into dismissible Bootstrap 4 alerts. That's about twenty lines of view logic. Pass 2 moved it into a `flashMessages()` override in `helpers.cfm` that starts with:

```cfm
local.rv = superFlashMessages(argumentCollection=arguments);
```

The layout still calls `#flashMessages()#`. Commit `306c428` adds specs for it: the alias exists, an empty Flash renders nothing, `success` becomes `alert alert-success alert-dismissible`, `error` maps to `alert-danger` and any other key to `alert-info`. In the browser, an anonymous request to `/admin/users` redirects to `/login`, which shows the "Login Required" message as a dismissible `alert-danger`.

## authenticateThis: what the app actually used

The plugin bundled its own `BCrypt.class` and mixed five methods into models. The app called it in `User` and in the login model, which only borrowed its validations. Since 4.1, Wheels ships `bcryptHash()` and `bcryptVerify()`, so pass 2 ([f09c6a9](https://github.com/wheels-dev/cfwheels-example-app/commit/f09c6a902676046f31fb467c027e76c3bf471665)) wrote the plugin's validations and its four helper methods into `User.cfc` under the same names. Controllers and tests didn't change.

The question that matters in an upgrade is whether existing passwords still work. The seeded accounts couldn't answer that: their hashes date from 2018, and the repo doesn't document the password. So we generated a hash with the plugin's own `BCrypt.class`, taken from the zip on `master`. Commit `8eab0a0` pins it: `checkPassword()` accepts the right password and rejects a case-changed one. With the same hash on `admin@domain.com`, logging in redirects to `/` and a wrong password re-renders the form with "Sorry, we couldn't log you in".

A package would make sense if several apps shared this code. For one app, a package adds a manifest and a `vendor/` directory and gives nothing back.

## What broke when we upgraded our own apps

[#3520](https://github.com/wheels-dev/wheels/pull/3520) fixed five regressions we found while upgrading two of our own apps to 4.1. All five fixes shipped in 4.1.0:

- **Model `super<name>` on `new()`.** The faster 4.1 model path built instances without calling `init()`, so `new()`, `create()` and finder rows had no aliases. An override of `save()` that called `supersave()` failed ([#3515](https://github.com/wheels-dev/wheels/issues/3515)).
- **DI lifecycle flags.** Re-mapping a singleton with `map("name").to("other.Path")` dropped its singleton flag.
- **`startFormTag()` on member routes.** PUT, PATCH and DELETE member routes threw `RouteNotFound`.
- **View variables shadowed.** Locals inside the view-include function were visible to templates and hid controller variables with the same name.
- **`super.delete()`.** The PR pinned `super.delete()` with a spec. A later docs fix, [#3938](https://github.com/wheels-dev/wheels/pull/3938), confirmed that all three model forms work.

## Check your work

`wheels upgrade check` lists `plugins/` as a breaking change, but only while `vendor/wheels/` still reports 3.x. After the swap it skips the 3→4 rules (see part 3). To see the finding change on the finished app, we ran the check in two throwaway copies with `vendor/wheels/wheels.json` set to 3.0.0. With the zips:

```
Breaking Changes (2 found):
  ! Legacy plugin directory (deprecated as of 4.0, removed in 5.0)
    plugins/
```

Without them:

```
All Clear (15 checks):
  + Legacy plugin directory (deprecated as of 4.0, removed in 5.0)
```

The real app has no `plugins/` directory and boots on Lucee 7. `wheels test` passes 22 specs, and the RocketUnit suite runs 46 tests with 0 failures.

## If you're replacing plugins

1. Read each plugin's source and list what your app actually calls.
2. If the plugin overrides a core helper, override it in `app/views/helpers.cfm` and delegate with `super<name>()`. You need 4.0.6 or later.
3. Check whether a `data*` pass-through argument would do the same job without an override.
4. Set camelCase struct keys with bracket notation before passing them on.
5. Keep the plugin's data working. Test against values the old code wrote, like password hashes.
6. Make it a package only when several apps share it, and declare `provides.mixins`.

**Previous:** [migrating your 2.x validation conditions](https://blog.wheels.dev/blog/from-2x-to-41-validation-conditions). **Next in the series:** from RocketUnit to WheelsTest.

