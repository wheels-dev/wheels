---
title: From WireBox to wheelsdi — The Framework Gets Leaner
slug: from-wirebox-to-wheelsdi
publishedAt: '2026-05-14T14:00:00.000Z'
updatedAt: '2026-05-13T02:19:38.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - dependency-injection
  - internals
categories: []
excerpt: >-
  Wheels 4.0 decomposes the framework's rim against the CFML engine, pulls
  dependency injection and the test runner in-house as wheelsdi and
  WheelsTest, and breaks the monolithic boot sequence into discrete phases.
  Nothing a user of the framework notices at the surface. Everything a
  contributor notices when they try to add the next feature.
coverImage: null
---

If you have tried to debug the Wheels boot sequence in the last few major releases, you have probably run into the same wall the rest of us did. Application startup was one long function that did engine detection, dependency injection wiring, model and controller loading, route compilation, plugin loading, and environment setup in a single pass. Something broke halfway through and the stack trace pointed at a line that had nothing to do with the thing that was actually wrong. Every new feature landed on top of that pile.

This post is about what 4.0 did to the pile. It is a contributor-facing post — a tour of framework internals that most users of Wheels will never look at. If you maintain a Wheels app and ship it without extending the framework, nothing here changes how you write code. If you have ever wanted to contribute to Wheels, extend it with a package, or debug why some cross-engine gotcha blew up on Lucee but not Adobe, this is the shape of the ground you are walking on now.

## The accidental coupling problem

Over more than a decade, CFWheels (and later Wheels) accreted hard dependencies on Ortus Solutions infrastructure. WireBox for the DI container. TestBox for the test runner. CommandBox for the CLI. Every one of those was a reasonable choice the day it was made. Ortus has shipped excellent CFML tooling for years, and framework authors do not build their own DI container unless they have a reason to.

The reason accumulates slowly. Each dependency is a version matrix you have to keep in your head. Upgrading Lucee or Adobe CF meant first confirming that WireBox, TestBox, and CommandBox all worked in the new environment — so the minimum viable test before accepting an engine bump was not "does Wheels run," it was "does Wheels plus three external dependencies run." A fix in any one of those projects shipped on its own cadence. A bug that looked like a Wheels bug was sometimes a WireBox bug, and vice versa.

The 4.0 release pace — more than 260 PRs in roughly 15 weeks, from @bpamiri, @zainforbjs, @chapmandu, @mlibbe, @MukundaKatta, and a very patient Dependabot — was not compatible with that coupling. We either loosened it, or we slowed down.

This is not a rejection of Ortus tooling. CommandBox, WireBox, and TestBox are excellent products and many Wheels users will keep reaching for them in their own apps. The change here is about what the framework's own internals depend on, not about what you are allowed to use alongside the framework.

## What "rim modernization" means

The rim is where Wheels meets the CFML engine. It is the layer that has to know that Lucee 7 resolves `obj.map()` as a struct member function when you wanted the CFC method, that Adobe CF copies arrays by value inside struct literals, that BoxLang integrates private mixin functions differently than the other two. For years that knowledge lived scattered across the codebase as conditionals and workarounds.

PR [#2016](https://github.com/wheels-dev/wheels/pull/2016) decomposed the rim into engine-specific adapter modules. Each adapter isolates its engine's idiosyncrasies — member function idioms, scope handling, closure semantics, version quirks — behind a narrow interface. The core is written against that interface, not against the engine directly. Tests exercise the engine-neutral core against each adapter, which means a regression in one engine no longer threatens the other two.

The practical result is that adding support for a new CFML engine, or catching up to a point release in an existing one, is now a scoped change to a single adapter file. It used to be a hunt through the codebase.

## WireBox to wheelsdi

PRs [#1883](https://github.com/wheels-dev/wheels/pull/1883) and [#1888](https://github.com/wheels-dev/wheels/pull/1888) renamed `application.wirebox` to `application.wheelsdi` and replaced the underlying implementation with an in-house container. The surface is deliberately familiar — `map()`, `bind()`, `to()`, `asSingleton()`, `asRequestScoped()` — so if you have used any small DI container in the last decade you already know how to drive it. But the code behind it is shorter, scoped to what Wheels actually uses, and lives in the same tree as the rest of the framework.

```cfm
// config/services.cfm — in-house DI, familiar surface
var di = injector();
di.map("emailService").to("app.lib.EmailService").asSingleton();
di.map("currentUser").to("app.lib.CurrentUserResolver").asRequestScoped();
di.bind("INotifier").to("app.lib.SlackNotifier").asSingleton();
```

Scopes are explicit. Transient is the default — a fresh instance per call. Singleton lives for the application lifetime. Request-scoped lives for the duration of one HTTP request, cached on `request.$wheelsDICache`. Auto-wiring of `init()` arguments matches registered names when no explicit `initArguments` are passed, which is the common case and the reason most service definitions fit on one line.

On top of that base, PR [#1933](https://github.com/wheels-dev/wheels/pull/1933) landed the pieces that make DI feel idiomatic rather than ceremonial: the `service()` global helper, declarative `inject()` in controller `config()`, and interface binding.

```cfm
// Declarative injection in a controller
component extends="Controller" {
    function config() {
        inject("emailService, currentUser");
    }

    function create() {
        this.emailService.send(
            to=this.currentUser.email(),
            subject="Welcome"
        );
    }
}
```

Why in-house, given that WireBox is mature and well-documented? Because the DI container is central to how Wheels extends. Packages register services. Controllers resolve services. Middleware resolves services. Every non-trivial feature we ship from here on either depends on or touches the container. Keeping it in-tree means we can fix behavior, change scopes, or add features without negotiating with a third-party release cadence — and you do not have to read Ortus docs to wire a service.

## TestBox to WheelsTest

PR [#1889](https://github.com/wheels-dev/wheels/pull/1889) introduced WheelsTest, a BDD runner that lives inside the framework. The syntax is the one you expect — `describe()`, `it()`, `expect()` — and the lifecycle matches what specs were already using under TestBox, so the migration was mostly a base-class rename.

The interesting part is what WheelsTest does not do. It does not try to be a general-purpose CFML testing framework. It does what Wheels needs — BDD specs, shared test helpers, populate fixtures, a core-tests and app-tests split — and stops there. Smaller surface, faster evolution, tests that read like documentation.

Legacy specs written against RocketUnit (the `test_` prefix, bare `assert()`) continue to run, and PR [#1925](https://github.com/wheels-dev/wheels/pull/1925) kept that bridge working so in-tree specs could migrate incrementally rather than in a single breaking commit. New tests should be WheelsTest; old tests do not have to be rewritten before they are touched.

## Decomposed init

`onApplicationStart` used to be a monolith. Engine detection, DI wiring, model and controller loading, route compilation, plugin loading, environment setup — all in one sequence, with failures cascading in confusing ways.

4.0 broke the sequence into discrete phases. Each phase is a function, each function is testable in isolation, and each phase produces an observable state that the next phase depends on. An error in plugin loading no longer corrupts the state of route compilation. An error in the engine detector no longer reports itself as a DI failure.

Package loading became a phase of its own with per-package error isolation (PR [#1995](https://github.com/wheels-dev/wheels/pull/1995)). A broken package logs its failure and the loader moves on. The app starts. Other packages continue. The old behavior — one bad plugin taking down the entire application — is gone.

## The package system — a philosophical shift from plugins

The legacy `plugins/` folder merged mixin methods into global scope by default. Drop a plugin in, and every controller, view, model, and global helper inherited whatever the plugin provided, whether you wanted it or not. That default served the 1.x era well. It is the wrong default for a framework that wants to scale to third-party extensions.

The new `packages/` to `vendor/` model requires explicit opt-in. Every package declares in its `package.json` exactly which surfaces it mixes into: `controller`, `view`, `model`, `global`, or `none`. The default is `none`. If a package wants to add methods to your controllers, it has to say so, and you have to choose to activate the package.

PR [#2017](https://github.com/wheels-dev/wheels/pull/2017) added a dependency graph with topological sort and `requires` / `replaces` / `suggests` relationships, which is what turns packages from a folder convention into a proper plugin system. Per-package error isolation from the init decomposition means that a broken package never blocks the rest of the boot.

## CommandBox to LuCLI

The CLI story parallels the DI and testing stories — a dependency on external Ortus infrastructure became a dependency we could evolve on our own cadence. LuCLI is that cadence. It is the fast path for the inner development loop and for CI, and article 05 in this series covers it in depth. CommandBox continues to work; LuCLI exists because the feedback loop is faster when the framework controls the CLI.

## What this means for contributors

Boot time in dev is shorter. The surface to learn is smaller — wheelsdi's API is narrower than WireBox's, and WheelsTest's is narrower than TestBox's. Specs that read like BDD read like documentation when you open them six months after they were written. The phases of `onApplicationStart` are discoverable; you can set a breakpoint on one of them without guessing where in the monolith to put it.

## What this doesn't mean

It does not mean we did the modernization cleanly on the first try. The decomposition shipped with its own set of cross-engine gotchas (PRs [#2028](https://github.com/wheels-dev/wheels/pull/2028), [#2030](https://github.com/wheels-dev/wheels/pull/2030), [#2031](https://github.com/wheels-dev/wheels/pull/2031)), most of them in the Lucee-vs-Adobe boundary that the new adapter modules were supposed to make easier. They did make it easier — the fixes were scoped and obvious — but "easier" and "automatic" are not the same thing.

It does not mean CommandBox, WireBox, and TestBox are deprecated for users. Reach for them in your own apps whenever they fit. The change is about what Wheels depends on at its core, not about what you are allowed to depend on alongside it.

And it does not mean the internals are done. The package system has a staging-to-activation dance that could be more ergonomic. The adapter modules cover today's engines but will need revisiting when the next Lucee or Adobe release arrives. The decomposed init has phases that could be split further. This is a foundation to build on, not a finished room.

## Where to go next

- [Package system reference](https://guides.wheels.dev/v4-0-0/digging-deeper/packages/) covers the `packages/` to `vendor/` activation model and the `package.json` manifest.
- [DI container reference](https://guides.wheels.dev/v4-0-0/core-concepts/dependency-injection/) covers scopes, interface binding, and declarative `inject()`.
- [Testing guide](https://guides.wheels.dev/v4-0-0/testing/) covers WheelsTest BDD syntax and the app-tests vs core-tests split.
- [Contributing guide](https://guides.wheels.dev/v3-0-0/working-with-wheels/contributing-to-wheels/) is the place to start if you want to work on a DI feature, a new adapter module, or a package.

The most important 4.0 feature is the one nobody feels directly — the one that lets future features ship faster. If you want to help shape what those future features look like, the door is open. Adapter modules, DI container features, and the package loader are all good first places to land a PR.

