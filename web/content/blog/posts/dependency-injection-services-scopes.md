---
title: 'Dependency Injection in Wheels 4.0: services.cfm, Scopes, and Auto-Wiring'
slug: dependency-injection-services-scopes
publishedAt: '2026-06-26T14:00:00.000Z'
updatedAt: '2026-06-19T15:10:00.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - di
  - wheelsdi
  - services
  - architecture
categories: []
excerpt: >-
  A user-facing how-to for the Wheels 4.0 DI container: register services in
  config/services.cfm with singleton/request/transient scopes, resolve them
  anywhere with service(), declare them in controllers with inject(), and let
  constructor auto-wiring fill in the rest.
coverImage: null
---

You've written this object three times this week. It's an `EmailService` — wraps your SMTP config, has a `send()` method, maybe holds a connection. The first time, you `new`'d it inside the controller action. The second time, you `new`'d it inside a model callback. The third time you found yourself passing it down through two function arguments because the place that needed it was three layers deep from the place that built it.

That's the problem dependency injection solves, and Wheels 4.0 ships a container — `wheelsdi` — that does it without ceremony. You register a service once, give it a lifetime, and pull it out anywhere with one helper call. No `new`, no plumbing it through arguments, no remembering which controller already built one this request.

This is a how-to. If you want the story of *why* Wheels grew its own container instead of bolting on WireBox, that's [a separate post](/posts/from-wirebox-to-wheelsdi) about the internals and the boot sequence. Here we're staying on the surface a developer actually touches: `config/services.cfm`, three scope verbs, and the helpers that read from the container. Everything below is grounded in the live code under `vendor/wheels/Injector.cfc` and its spec suite.

## There is no services.cfm — you create it

First, the thing the docs don't say loudly enough: **a fresh Wheels app has no `config/services.cfm`**. The scaffold doesn't write one, and the demo app doesn't ship one. The framework's own bindings file (`wheels.Bindings`) registers internal subsystem interfaces — the model finder, the controller renderer, the view object — and nothing of yours. Your app-level registrations are a file you author.

So make it:

```cfm
// config/services.cfm
// Loaded automatically at app start, right after config/settings.cfm.
// Override per-environment in config/<environment>/services.cfm.
local.di = injector();

local.di.map("emailService").to("app.lib.EmailService").asSingleton();
```

`injector()` is a global helper — mixed onto controllers, models, and views, so you can call it from any of those. It returns the live container instance (the framework keeps it at `application.wheelsdi`). Inside `services.cfm` it's your entry point: grab the container, then map things into it.

The fluent chain reads like a sentence. `map("emailService")` opens a definition for the alias `emailService`. `.to("app.lib.EmailService")` binds that alias to a dotted component path. `.asSingleton()` declares the lifetime. Done — one instance of `EmailService`, built lazily on first resolve, shared for the life of the application.

One catch worth internalizing before you write a line of this: if you call `injector()` or `service()` *before* the app has finished starting, you get a thrown `Wheels.DI.NotInitialized`, not a null. The container is bootstrapped in your app's `Application.cfc` (`application.wheelsdi = new wheels.Injector("wheels.Bindings")`), and `config/services.cfm` runs as part of that start. By the time a request reaches a controller, the container is live.

## Three lifetimes, and one of them is the trap

A service's *scope* is how long its instance lives and who shares it. Wheels gives you exactly three, and here is the surface in full:

| Scope | Verb | Lifetime | Cached where |
|---|---|---|---|
| Transient | *(none — the default)* | A brand-new instance on every resolve | not cached |
| Singleton | `.asSingleton()` | One instance for the whole app lifetime | `variables.singletons`, keyed by mapping name |
| Request-scoped | `.asRequestScoped()` | One instance per HTTP request | `request.$wheelsDICache`, keyed by name |

Read the first row twice, because it's the one that bites. **Transient is the default.** If you write `local.di.map("pdfBuilder").to("app.lib.PdfBuilder")` and stop there — no scope verb — then every `service("pdfBuilder")` call hands you a *fresh* `PdfBuilder`. You only get sharing when you ask for it:

```cfm
local.di = injector();

// One instance per app lifetime — must be thread-safe.
local.di.map("emailService").to("app.lib.EmailService").asSingleton();

// Interface-style binding reads better with bind() (it's map() under the hood).
local.di.bind("INotifier").to("app.lib.SlackNotifier").asSingleton();

// One instance per HTTP request — safe to hold per-request state.
local.di.map("currentUser").to("app.lib.CurrentUserResolver").asRequestScoped();

// Transient (DEFAULT — no scope verb): a fresh instance on every resolve.
local.di.map("pdfBuilder").to("app.lib.PdfBuilder");
```

The verbs are spelled `asSingleton()` and `asRequestScoped()`, camelCase, on the fluent chain. That's the complete vocabulary. There is no `.transient()`, no `.asTransient()`, no `.scope("singleton")` — transient is what you get by *omission*, and the other two are explicit. If you came from a container that takes a scope string, unlearn it here.

When do you reach for each?

- **Singleton** for stateless collaborators and expensive-to-build objects: a mailer, a notifier, an API client, a formatter. One instance, app-wide. Because it's shared across every concurrent request for the application's whole life, a singleton **must be safe to share across threads** — if it holds mutable state, you own the locking. This is the same lifecycle contract Wheels singleton middleware lives under.
- **Request-scoped** when you want to hold per-request state safely: a `CurrentUserResolver` that resolves the logged-in user once and caches it for the rest of *this* request, a per-request correlation ID, a unit-of-work. Each request gets its own instance, so there's no cross-request bleed and no lock to write.
- **Transient** when each caller genuinely wants a fresh, independent object: a builder you mutate, a query accumulator, anything you'd be surprised to find pre-dirtied by the last caller.

## Resolving a service: service() anywhere

Registration is half the deal; pulling the thing out is the other half. The `service()` global helper resolves a registered name from anywhere with framework-helper access — controllers, models, and views:

```cfm
// Works in controllers, models, and views.
var mailer = service("emailService");
mailer.send(to="user@example.com", subject="Welcome");
```

`service("emailService")` honors the registered scope. Ask for a singleton and you get the shared instance; ask for a request-scoped name and you get *this* request's instance; ask for a transient and you get a fresh one. The helper itself does the scope-aware lookup — internally it checks `containsInstance(name)` and then `getInstance(name)`, which is the same path `injector().getInstance()` walks.

Note what `service()` does when the name isn't registered: it **throws**, it doesn't return null. Two typed errors are in play, and both are deliberately loud:

- `Wheels.DI.NotInitialized` — the container is missing entirely (you called too early in the lifecycle).
- `Wheels.DI.ServiceNotFound` — the container is up but nothing's mapped to that name. The message literally tells you to check `config/services.cfm`, which is usually exactly where the missing `map()` call should go.

If a service is *optionally* present — maybe it's only registered in one environment — guard with introspection instead of catching the throw:

```cfm
local.di = injector();
if (di.containsInstance("emailService")) {
    local.di.getInstance("emailService").send(to="u@example.com", subject="Hi");
}
```

`containsInstance(name)` tells you whether an alias→path mapping exists. There's a small introspection family alongside it — `isSingleton(name)`, `isRequestScoped(name)`, and `getMappings()` (the full name→path struct) — handy in diagnostics and tests when you want to assert what's wired up.

## Controllers: declare with inject(), use this.<name>

Calling `service("emailService")` at the top of every action that needs it works, but Wheels gives controllers something cleaner: declare your dependencies once in `config()`, and let the framework attach them to each instance.

```cfm
// app/controllers/Users.cfc
component extends="Controller" {
    function config() {
        // Class-level declaration (config runs once). Comma-delimited list ok.
        inject("emailService, currentUser");
    }

    function create() {
        user = model("User").create(params.user);
        if (user.hasErrors()) { renderView(action="new"); return; }

        // Resolved per-instance (per-request) and attached as this.<serviceName>.
        // this.currentUser is the request-scoped instance for THIS request.
        this.emailService.send(to=user.email, subject="Welcome");
        redirectTo(route="user", key=user.id);
    }
}
```

Two things about `inject()` are easy to get wrong, and both come straight from how the controller mixin works.

First, `inject()` **declares**; it doesn't resolve on the spot. `config()` runs once per controller class, at app start, and `inject("emailService, currentUser")` just records those names (deduplicated) at the class level. The actual resolution happens later, *per controller instance*, during the controller's init — after params are set, the framework runs `$resolveInjectedServices()`, walks your declared names, and for each one the container `containsInstance()`, resolves it and pins it onto the instance as `this.<serviceName>`.

That class-declare / instance-resolve split is the whole reason request-scoped services work correctly inside controllers. The *declaration* is shared (config ran once), but each request gets a fresh controller instance, so `this.currentUser` is resolved fresh per request — which means it's *this* request's request-scoped `CurrentUserResolver`, not a stale one from someone else's request.

Second — and this follows from the above — you reach an injected service as **`this.emailService`**, not as a bare local and not as `variables.emailService`. It's attached as a property on `this`. Reach for it the wrong way in an action and you'll get an undefined-variable error wondering where your service went; it's sitting on `this`.

When you declared nothing (no `inject()` call), the controller's declared-services list is simply empty, so `$resolveInjectedServices()` iterates zero names and attaches nothing — and if the class data or the container is somehow absent, it returns early. Either way: no spurious error from a controller that has no declared dependencies.

## Auto-wiring: constructors that fill themselves in

Here's where the container earns its keep on bigger objects. When you resolve a component, Wheels calls its `init()`, and if you didn't pass explicit constructor arguments, it **auto-wires**: it reads the `init()` parameter *names* and, for each name that matches a registered mapping, resolves that mapping and passes it in.

```cfm
// app/lib/ReportService.cfc
component {
    // Param name 'emailService' matches the registered mapping name, so the
    // container injects service("emailService") automatically when ReportService
    // is resolved with NO explicit initArguments.
    public ReportService function init(required any emailService) {
        variables.emailService = arguments.emailService;
        return this;
    }
    public void function mailReport(required string to) {
        variables.emailService.send(to=arguments.to, subject="Your report");
    }
}
```

```cfm
// config/services.cfm
local.di = injector();
local.di.map("emailService").to("app.lib.EmailService").asSingleton();
local.di.map("reportService").to("app.lib.ReportService");   // transient; auto-wires emailService
```

```cfm
// Resolve — emailService is wired in for you:
service("reportService").mailReport(to="boss@example.com");
```

The match is on the *parameter name*, not its type. `init(required any emailService)` gets injected only because you also mapped something to the name `emailService`. Name a parameter after a registered mapping and the container fills it; name it something unmapped and the container leaves it to the constructor's own default (or to whatever you pass explicitly).

A few properties of auto-wiring that matter in practice:

- **It walks the `extends` chain.** If a component inherits its `init()` from a parent, that inherited constructor's parameters participate in auto-wiring just the same.
- **Parameter names are matched against *live* mappings on each resolve.** The container memoizes which param names a given component path has, but the match against registered mappings runs every time. So if you register a mapping *after* a component first resolved, the next resolution still picks it up.
- **Explicit arguments win, completely.** Auto-wiring only fires when the `initArguments` struct is empty. The moment you pass one, auto-wiring is skipped entirely and your struct is used verbatim. That's your override hook — and it's exactly how you'd swap in a fake for a test:

```cfm
// Bypass auto-wiring: pass your own collaborator (a fake, a preconfigured client, …).
injector().getInstance(name="reportService", initArguments={emailService: myFake});
```

After construction, if the component defines an `onDIcomplete()` method, the container calls it — a post-wiring hook for any setup that needs all dependencies already in place.

## Swapping a framework subsystem

`bind()` is `map()` with a name that reads better for interface→implementation pairs, and that's not just cosmetic — the framework's own internals are registered as interface bindings you can override. The default `wheels.Bindings` binds things like `ModelFinderInterface` to their stock implementations; re-bind them in your `services.cfm` to drop in your own:

```cfm
// config/services.cfm — replace a built-in interface implementation.
local.di = injector();
local.di.bind("ModelFinderInterface").to("app.lib.CustomFinder");

// Per-project DB adapter (no framework default is registered for this one):
local.di.bind("DatabaseModelAdapterInterface").to("wheels.databaseAdapters.H2.H2Model");
```

This is the supported drop-in extension point for the subsystems the framework itself resolves through the container. You don't fork the framework to change how finders work — you bind a different implementation to the interface name and the framework resolves yours.

## Sharp edges

Every one of these is real, lives in the code, and has a passing spec pinning it down. Read them before you ship a `services.cfm`.

**Transient is the default — silence means "fresh every time."** Map without a scope verb and you've made a transient. No sharing, no caching. If you expected one shared instance and forgot `.asSingleton()`, you'll get a new object per resolve and chase a "why is my cache empty" bug that's really a missing verb.

**Singletons are cached by mapping name, not by component path.** Two singleton aliases pointing at the same `.to()` path are **two distinct instances**:

```cfm
local.di.map("a").to("app.lib.X").asSingleton();
local.di.map("b").to("app.lib.X").asSingleton();
// service("a") and service("b") are DIFFERENT X objects.
```

The cache key is the alias. A transient alias to the same path likewise never receives the singleton's cached instance. If you want one shared X, register one name for it and resolve that name everywhere.

**The scope verb flags the mapping you *just completed*, not whichever key sorts last.** `to()` records the just-mapped name internally, and `asSingleton()` / `asRequestScoped()` flag exactly that one. This matters because by the time your `services.cfm` runs, the container already holds ~20 framework bindings, and the backing struct isn't insertion-ordered at that size — an earlier implementation that flagged "the last key" flagged the *wrong* binding. Fixed, with a regression spec. The practical takeaway: always finish a mapping (`.map().to()`) immediately before its scope verb; don't try to flag a scope on a mapping out of band.

**Auto-wiring matches parameter names, and only fires with empty initArguments.** If a constructor isn't getting its collaborator injected, check two things: is the parameter *named* exactly like a registered mapping, and are you (or some caller) passing an `initArguments` struct that's silently disabling auto-wiring? Pass an explicit struct and auto-wiring is off — your struct is the whole input.

**Injected controller services live on `this`.** Declared via `inject()` in `config()`, resolved per-instance, attached as `this.<serviceName>`. Reach them as `this.emailService` inside actions — not as a local var, not as `variables`-scoped.

**`service()` and `injector()` throw; they don't return null.** `Wheels.DI.NotInitialized` if the container is missing (you called too early), `Wheels.DI.ServiceNotFound` if the name isn't mapped (the message points you at `config/services.cfm`). For optional services, guard with `injector().containsInstance("name")` first.

**Circular constructor dependencies throw — with the chain.** If A's constructor needs B and B's needs A, you get `Wheels.DI.CircularDependency` carrying the full resolution chain in the message, so you can see exactly which constructors are biting each other. The resolving guard is request-scoped (it lives on `request.$wheelsDIResolving`), not application-scoped — so concurrent requests on a cold app don't trip a spurious self-loop the way they once did, and the resolution stack is cleaned up even when a resolve errors out.

**Inside a plugin ServiceProvider, use `mapInstance()`, not `map()`.** When a package or plugin configures the container, the injector usually arrives as a generic `any` argument. On Lucee and Adobe, `obj.map()` on an `any`-typed reference can resolve to CFML's built-in `struct.map()` member function and silently *not* call the Injector — your registrations vanish without an error. `mapInstance()` is a same-signature alias for `map()` that sidesteps the collision. In your own `config/services.cfm` you hold the injector as a concrete reference from `injector()`, so plain `map()` is fine there; the alias is for the `any`-argument case.

## The shape, end to end

Put it together and the loop is small. You author one file:

```cfm
// config/services.cfm
local.di = injector();
local.di.map("emailService").to("app.lib.EmailService").asSingleton();
local.di.bind("INotifier").to("app.lib.SlackNotifier").asSingleton();
local.di.map("currentUser").to("app.lib.CurrentUserResolver").asRequestScoped();
local.di.map("reportService").to("app.lib.ReportService");   // transient, auto-wires emailService
```

You declare what a controller needs, once:

```cfm
function config() {
    inject("emailService, currentUser");
}
```

And you use it, scope-aware and wired, without a single `new`:

```cfm
this.emailService.send(to=user.email, subject="Welcome");   // singleton
var who = this.currentUser.name();                          // request-scoped, this request's instance
service("reportService").mailReport(to="boss@example.com"); // transient, emailService auto-wired in
```

Register once, pick a lifetime, resolve anywhere. That's the whole container. The `EmailService` you wrote three times this week is now one mapping line and a `this.emailService` away from everywhere it was needed.
