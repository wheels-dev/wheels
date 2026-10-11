---
title: 'Pass 1: 2.x to 3.0, the layout move'
slug: from-2x-to-41-pass-1-wheels-3
publishedAt: '2026-10-06T21:00:00.000Z'
updatedAt: '2026-10-03T02:31:40.000Z'
author: Peter Amiri
tags:
  - wheels-3-0
  - wheels-4
  - upgrade
  - migration
categories:
  - Tutorials
excerpt: >-
  Part 2 of "From 2.x to 4.1: the field guide" walks the nine commits that
  take the example app from CFWheels 2.2 to Wheels 3.0.0+33: moving code into
  app/ and assets into public/, the new public/Application.cfc, vendor/wheels
  pinned to 3.0.0+33, path and test fixes, and the problems the 3.0 guide
  doesn't mention: events/ has to move, plugins/ stays at the root, a caret
  range can install a 4.0 development build, joinType="left" silently drops a
  nested join, and a 2.3 validatesConfirmationOf change breaks login.
coverImage: null
announcement:
  discussionUrl: 'https://github.com/wheels-dev/wheels/discussions/4467'
  title: 'From 2.x to 4.x, part 2: the layout move to Wheels 3.0'
  body: |
    New post: **[Pass 1: 2.x to 3.0, the layout move](https://blog.wheels.dev/posts/from-2x-to-41-pass-1-wheels-3/)** — the nine commits that take a real CFWheels 2.2 app to Wheels 3.0.0+33: code into app/, assets into public/, the new public/Application.cfc, and vendor/wheels pinned for the next pass.
---

Pass 1 takes the example app from CFWheels 2.2 to Wheels 3.0.0+33. It's mostly moving files, and the frozen [Upgrading to Wheels 3.0.0](https://guides.wheels.dev/v3-0-0/introduction/upgrading/) guide covers most of it. This post walks the 9 commits on [`upgrade/pass-1-wheels-3.0`](https://github.com/wheels-dev/cfwheels-example-app/tree/upgrade/pass-1-wheels-3.0), and the places where following the guide alone wasn't enough.

If you missed it, [the first post](https://blog.wheels.dev/blog/from-2x-to-41-the-map) explains why the upgrade takes two passes.

## 1. Move the application code into app/

[5973ba9](https://github.com/wheels-dev/cfwheels-example-app/commit/5973ba9d990e91d13d7ef81761981f77c3b42dd2) is a pure `git mv`, so history follows every file:

```bash
mkdir app
git mv controllers models views global events migrator app/
```

Two things in it aren't in the guide.

**`events/` moves too.** Section 2.1 lists `app/controllers/`, `app/global/`, `app/migrator/`, `app/models/` and `app/views/`, but not events. The 3.0 core reads application events from `/app/events` (`eventPath` in `onapplicationstart.cfc`), so they have to move.

**`plugins/` stays at the project root.** Section 2.1 lists `plugins/` at the root. The guide's "After (Wheels 3.x)" diagram shows `/app/plugins`. The 3.0 core and template agree with section 2.1: the core sets `pluginPath = "/plugins"`, and the template's `public/Application.cfc` maps `/plugins` to `../plugins`. Leave it where it is.

## 2. Move static assets under public/

In 3.0 the web server's document root is `public/`, so only what's inside it is reachable over HTTP. [06e7910](https://github.com/wheels-dev/cfwheels-example-app/commit/06e7910ae26c3bd318b0222c6a9d2574e3aa0922):

```bash
git mv files images javascripts stylesheets miscellaneous public/
```

`imagePath`, `javascriptPath`, `stylesheetPath` and `filePath` keep their relative values, now resolved against `public/`, so the asset helpers need no changes.

## 3. Replace the front controller

In 2.x the project root was the web root, and three small shims handed each request to the bundled framework. The 2.2 `Application.cfc` was the whole bootstrap:

```cfm
component output="false" {
	include "wheels/functions.cfm";
}
```

In 3.0, `public/Application.cfc` *is* the bootstrap. [463d6c7](https://github.com/wheels-dev/cfwheels-example-app/commit/463d6c7b47936c2d9d1edadad35f4ebe66ec5548) copies `public/Application.cfc`, `public/index.cfm` and `public/urlrewrite.xml` verbatim from the 3.0.0+33 template. The new `Application.cfc` is 450 lines: it defines the `/app`, `/config`, `/vendor`, `/wheels`, `/wirebox`, `/testbox`, `/tests` and `/plugins` mappings, loads `.env`, starts WireBox, and then includes `../config/app.cfm`. This app already kept `this.name`, sessions and mail settings in `config/app.cfm`, so nothing had to move out of the old file.

The CommandBox server configs need the new web root, and the Adobe one needs an engine 3.0 supports:

```diff
     "web":{
+        "webroot":"public",
         "rewrites":{
             "enable":true,
-            "config":"urlrewrite.xml"
+            "config":"public/urlrewrite.xml"
         }
     },
     "app":{
-        "cfengine":"adobe@2016"
+        "cfengine":"adobe@2018"
     }
```

The commit keeps the app's own Apache rules in `public/.htaccess`, retargeted from `rewrite.cfm` to `index.cfm`. The template's `.htaccess` only redirects `/wheels/*`, which would drop pretty URLs on Apache.

## 4. Put the framework in vendor/, and pin it

[0891b68](https://github.com/wheels-dev/cfwheels-example-app/commit/0891b68c5a4c6df7249f8eb77548d27c7411dc42) deletes `wheels/` (2.2.0), adds `vendor/wheels/` from the `v3.0.0+33` tag, and declares the dependencies:

```diff
     "dependencies":{
+        "wheels-core":"3.0.0+33",
+        "wirebox":"^7.0.0",
+        "testbox":"^6.0.0",
         "cfwheels-flashmessages-bootstrap":"^1.0.2",
```

**Pin `wheels-core` to exactly `3.0.0+33`.** The guide's `box.json` example says `"^3.0.0-SNAPSHOT"`, and the 3.0 template says `"^3.0.0"`. Neither is safe. Builds after the GA kept the `3.0.0+N` version while 4.0 was being developed: the `v3.0.0+48` and `v3.0.0+50` tags already contain 4.0's `Injector.cfc` and `WheelsTest.cfc`. On ForgeBox, wheels-core 3.0.0+48 and +50 are those 4.0 development builds, so a caret range can install something that isn't 3.0 GA.

## 5. Point the app code at the new paths

Moving files is half the job. [c3da071](https://github.com/wheels-dev/cfwheels-example-app/commit/c3da071044acc31d3d3dfd0b7f5525853a0f1850) fixes the places that assumed the 2.x layout. On Adobe CF, the global functions used root-relative includes, and 3.0 has no `/global` mapping:

```diff
-	include "/global/install.cfm";
-	include "/global/auth.cfm";
+	// Root-relative includes resolve through the /app mapping in public/Application.cfc
+	include "/app/global/install.cfm";
+	include "/app/global/auth.cfm";
```

The base model worked out the calling model's name by stripping a 2.x-specific prefix. In 3.0 models load through the `/app` mapping, so the audit log would have recorded `app.models.User`:

```diff
-		return replace(getMetaData(this)['fullname'], "wheels....models.", "", "all");
+		return reReplaceNoCase(getMetaData(this)["fullname"], "^.*models\.", "");
```

Controllers and models that extend `app.controllers.Controller` and `app.models.Model` needed no change.

## 6. Move the RocketUnit tests

The guide doesn't mention `tests/`, but 3.0 changes where the legacy runner looks: for app tests it uses `tests.RocketUnit`, and `tests/` itself is for TestBox specs. [b170a17](https://github.com/wheels-dev/cfwheels-example-app/commit/b170a172f569e4ce6bda15b5023ecced33e2267a) moves the files with `git mv`, and [e30fa85](https://github.com/wheels-dev/cfwheels-example-app/commit/e30fa854bbe78e96821ad6c6f09df5b3ff7020d8) repoints all ten test cases:

```diff
-component extends="tests.Test" {
+component extends="tests.RocketUnit.Test" {
```

The base class itself still extends `wheels.Test`, the RocketUnit-compatible runner 3.0 keeps next to TestBox.

## 7. joinType="left" silently dropped a join

The app's first boot on 3.0 failed at application start with:

```
Unknown column 'roles.name' in 'field list'
```

The query was `model("permission").findAll(include="rolepermissions(role)")`. 3.0 generated `FROM permissions LEFT JOIN rolepermissions ON ...`, and the `INNER JOIN` to `roles` was missing.

The cause was `hasMany(name="rolepermissions", jointype="left")`. The documented values are `inner` and `outer`, and 2.x pasted any value into `<TYPE> JOIN`, so `left` happened to work. 3.0.0 groups an include that mixes an outer and an inner join, as in `a(b)`, but it finds the outer join by matching the literal text `LEFT OUTER JOIN`. `LEFT JOIN` doesn't match, so the inner join was dropped without an error. [c1a87a8](https://github.com/wheels-dev/cfwheels-example-app/commit/c1a87a8892fe719bc1d2a9074a67840ddd62984d) is a one-line fix with the same results:

```diff
-		hasMany(name="rolepermissions", jointype="left");
+		hasMany(name="rolepermissions", joinType="outer");
```

We reported this as [#3936](https://github.com/wheels-dev/wheels/issues/3936), and [#3937](https://github.com/wheels-dev/wheels/pull/3937) fixes it for Wheels 4.2: `left` and `left outer` become aliases of `outer`, any other value throws `Wheels.InvalidJoinType`, and Wheels throws instead of dropping a nested join it can't place.

## 8. A 2.3 change broke login

With the app booting, logging in with valid credentials failed with "Password should match confirmation". The login model calls the authenticateThis plugin, which always registers `validatesConfirmationOf("password")`. In 2.2 that validation was skipped when no `passwordConfirmation` property existed. Wheels 2.3.0 changed it to require the property ([cfwheels#1070](https://github.com/cfwheels/cfwheels/issues/1070), in the 2.3.0 changelog), and 3.0 kept that. Jump from 2.2 straight to 3.0 and you hit a change the 3.0 guide never mentions.

The login form has no confirm field, so [4da261b](https://github.com/wheels-dev/cfwheels-example-app/commit/4da261b12cfa16959bbfc08471d53374f3656aa9) adds a stopgap callback to the login model:

```cfm
beforeValidation("mirrorPasswordConfirmation");

private function mirrorPasswordConfirmation(){
	if(structKeyExists(this, "password")){
		this.passwordConfirmation = this.password;
	}
}
```

Pass 2 removes it when the plugin itself goes.

## What the guide doesn't tell you

- `events/` moves into `app/`.
- `plugins/` stays at the root, whatever the "After" diagram shows.
- Pin `wheels-core` to `3.0.0+33`.
- RocketUnit tests move to `tests/RocketUnit/`.
- If you skip versions, the 2.3 to 2.5 changelogs still apply. `validatesConfirmationOf` is one example.
- On 3.0, `joinType` has to be `inner` or `outer`.

## If you're upgrading

Before you boot on 3.0, search for the patterns that bit us:

```bash
grep -rni 'jointype *= *"left"' app/models
grep -rn 'include "/global' app
grep -rln 'extends="tests.Test"\|extends="app.tests.Test"' tests
grep -rn 'validatesConfirmationOf\|authenticateThis' app/models
```

Then boot the app, log in, and run the RocketUnit suite before you start pass 2. The 3.0 landing is your checkpoint.

**Previous:** [2.x to 4.x: why it's two passes, and the map](https://blog.wheels.dev/blog/from-2x-to-41-the-map) · **Next:** [Pass 2: 3.x to 4.1 with `wheels upgrade check`](https://blog.wheels.dev/blog/from-2x-to-41-pass-2-upgrade-check)

