---
title: 'The Debug Bar: A Complete Tour of Wheels 4''s Development Cockpit'
slug: debug-bar-tour-wheels-4
publishedAt: '2026-07-23T14:00:00.000Z'
updatedAt: '2026-07-06T05:23:50.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - debugging
  - development
  - tooling
categories: []
excerpt: >-
  Most developers use a fifth of the debug bar and writeDump() around the
  rest. The full tour: what each panel answers, the developer tools behind the
  last tab, the throughput cost worth knowing, and why the bar can't follow
  you to production — by design.
coverImage: null
---

Every framework has a place where it answers the question "what just happened?" In Wheels 4 it's pinned to the bottom of every development page: the debug bar. Most developers use maybe a fifth of it — the timing badge, occasionally Params — and route around the rest with `writeDump()`. Which is a shame, because the other four-fifths replace most of the dumps.

This is the tour: every panel, what question it answers, the developer tools hiding behind the last tab, and the two facts about the bar people learn late (it costs real throughput, and it cannot follow you to production — by design).

## The collapsed bar: the glance

Collapsed, the bar is a one-line request summary: the Wheels logo, **`controller.action`** for whatever just ran, a **timing badge**, and tabs for Params, the current environment, and Tools, with the framework version on the right.

That `controller.action` label alone retires a whole category of confusion. "Which action actually rendered this page?" — the question behind half of all routing mysteries — is permanently answered in the corner of your screen. If the label says `Main.index` and you swore you were editing `Posts.index`, you've just saved yourself the twenty minutes you were about to spend "fixing" a view the request never touched.

## Request: the dispatch anatomy

The Request panel expands into the full dispatch record: matched **route** name, **controller**, **action**, **HTTP method**, the URL, the application name, the **datasource**, the database **adapter** class, and whether **URL rewriting** is on.

Read it as the answer sheet for the [request lifecycle](https://guides.wheels.dev/v4-0-0/core-concepts/request-lifecycle/): what the router decided (route, controller, action) and what context it ran under (datasource, adapter, rewriting). The datasource row is quietly the most valuable during setup — "connected to the *wrong database*" looks identical to "connected to no database" from the browser, and this row disambiguates in one glance. Same for the adapter row when you're moving between SQLite in development and MySQL beyond it.

## Timing: where the milliseconds went

The Timing panel is a horizontal bar chart of the request's execution phases — action, view, and friends — color-coded and sorted by duration, with the total in the header.

The practiced read is the *ratio*, not the number. A slow total that's all **action** means query work — go look at what the models are doing, check for the N+1 shapes the [associations post](https://blog.wheels.dev/posts/associations-deep-dive-wheels-4) covers. A slow total that's all **view** means template work — usually a partial rendering per row of something big, which [`includePartial(cache=...)`](https://blog.wheels.dev/posts/caching-in-wheels-4) or a restructure fixes. Thirty seconds with this panel routinely redirects an afternoon of optimizing the wrong layer.

One calibration, though: don't benchmark with it. The debug machinery itself costs — our own profiling put development mode with the bar at roughly a third less throughput than production mode. Treat the numbers as *relative* (which phase dominates) rather than absolute (what production will do). Real numbers come from production mode and a load tool.

## Params: what the server actually received

The Params panel is the parsed request parameters as a table — name, value, type. It answers the form-debugging question at its root: not "why didn't my update work" but "did `params.user.firstName` even *arrive*, and did the bracket-notation form fields (`user[firstName]`) nest into the struct I expected?" With Wheels' [form helpers](https://blog.wheels.dev/posts/form-helpers-objects-and-html5) the nesting is automatic — this panel is where you verify it when something's off, before blaming the model.

## Environment: the app's self-portrait

The Environment panel shows the application's runtime identity: environment name (with a reassuring green dot in development), Wheels version, CFML engine and version, host — plus a **Packages** section listing what's installed from `vendor/` and the legacy-plugins list below it.

Two habits this panel serves. After an upgrade, the version row is the ground truth for "am I actually running what I think I deployed" — the same `application.$wheels.version` the [configuration post](https://blog.wheels.dev/posts/how-wheels-reads-configuration) talks about, no console needed. And after installing a [package](https://guides.wheels.dev/v4-0-0/digging-deeper/packages/), the Packages section confirms the loader actually discovered it — if your package isn't listed here after a reload, no amount of calling its helpers will work.

## Tools: the doorway tab

The last tab is a link grid to the framework's development surfaces, each opening in its own tab: **System Info**, **Routes**, **API Docs**, **Guides**, **Tests**, **Migrator**, and **Packages**.

Three of these deserve to be daily drivers. **Routes** renders the full route table — the "which pattern wins for this URL" question answered with the same data the dispatcher uses. **Tests** is the browser test runner (`/wheels/app/tests`) — the exact surface `wheels test` calls, one click away. **Migrator** is the GUI for applied-and-pending migrations, the no-CLI path our [manual-tooling post](https://blog.wheels.dev/posts/wheels-4-without-the-tooling) covered.

## The two late-learned facts

**It's development-only, and it stays that way.** The bar renders when `showDebugInformation` is true — the default in development, false everywhere else. But the Tools *links* have a harder gate: since 4.0.4 the `/wheels/*` surfaces sit behind a development-environment allowlist that no setting overrides — flip `enablePublicComponent=true` in production and you'll get the Tools tab rendering links that all 404. That's intentional. The migrator GUI and test runner expose schema and internals; the framework treats "show them outside development" as a request it should refuse. Production visibility is what [observability plumbing](https://blog.wheels.dev/posts/observability-in-wheels-4) is for.

**It participates in your dev workflow's honesty.** Because the bar reads live application state, it reflects reality after every reload — which makes it the fastest verification loop for config changes: edit `settings.cfm`, `?reload=true`, glance at Environment. If the bar still shows the old value, your reload didn't happen (wrong password fails silently — check `wheels_security.log`), and you've caught it in five seconds instead of after ten confusing requests.

The full panel-by-panel reference — including the settings that control each piece and the `debugAccessTrustProxy` knob for IP-allowlisted debug access behind proxies — is the [Debug Panel guide](https://guides.wheels.dev/v4-0-0/digging-deeper/debug-panel/), screenshots included.

