---
title: Writing Your Own Middleware in Wheels 4.0
slug: writing-custom-middleware-wheels-4
publishedAt: '2026-06-25T14:00:00.000Z'
updatedAt: '2026-06-19T15:10:00.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - middleware
  - dispatch
  - advanced
categories: []
excerpt: >-
  A from-scratch guide to authoring custom middleware in Wheels 4.0 — the
  one-method interface, the singleton-per-app lifecycle and the thread-safety
  it demands, how to short-circuit, and how to register globally or per route.
coverImage: null
---

There's a moment in every Wheels app where you realise the thing you need doesn't belong in a controller. You want to time every request and stick the duration in a response header. You want to deny traffic during a deploy window before any controller runs. You want to write an audit line for every admin action without copy-pasting a `beforeFilter` into a dozen controllers. None of these is *about* a specific resource — they're about the request itself, the layer below your actions.

That layer is middleware, and in Wheels 4.0 you can write your own. The [rate-limiting walkthrough](/posts/skip-the-plugin-rate-limited-api) covered consuming the built-in `RateLimiter`; this post is the other half — authoring middleware from scratch. It's a small surface: one method, one interface, two ways to register. The catch is that the small surface hides a lifecycle decision that will bite you if you don't know it's there. We'll build three middleware components — a timer, an audit logger, a maintenance gate — and the third of those exists mostly to teach you the rule that makes the second one correct.

## The contract is one method

Every middleware in Wheels implements exactly one interface, and that interface declares exactly one method. Here's the whole thing, verbatim from `vendor/wheels/middleware/MiddlewareInterface.cfc`:

```cfm
interface {
    public string function handle(required struct request, required any next);
}
```

That's the entire contract. `handle` takes a request struct and a `next` reference, and it returns a string — the response body. There is no base component to extend, no lifecycle hooks to override, no `init` you're forced to write. You declare `component implements="wheels.middleware.MiddlewareInterface"` and you write `handle`. The built-ins do exactly this; so will you.

The two arguments are where the design lives.

**`request` is not the CFML `request` scope.** This trips up everyone the first time. The `request` you receive is a plain struct that Dispatch builds for you, carrying `{params, route, pathInfo, method, cgi}` — the request *context*, not the engine's `request` scope. So `arguments.request.method` is the HTTP verb, `arguments.request.params.controller` is the routed controller name, and so on. (More on the scope-shadowing hazard this creates in a moment — it's the single sharpest edge in the whole API.)

**`next` is a closure.** Call it as `next(request)` and it runs the rest of the pipeline — every middleware after yours, and ultimately the controller. It returns the downstream response as a string. That return value is the thing you hand back, optionally after doing something to it or to the response headers.

So the canonical shape of a `handle` method is: do some work, call `next`, do some more work, return what `next` gave you.

```cfm
public string function handle(required struct request, required any next) {
    // ... before the controller runs ...
    local.response = arguments.next(arguments.request);
    // ... after the controller has run ...
    return local.response;
}
```

Everything you'll write fits in that frame. Code before `next` runs on the way *in*. Code after `next` runs on the way *out*. And — the move we'll get to last — if you `return` a string *without* calling `next`, you've short-circuited: the controller never runs.

## A first middleware: timing every request

Let's build the simplest useful thing — a middleware that measures how long each request took and writes it into an `X-Response-Time` header. It goes in `app/middleware/RequestTiming.cfc`, because custom middleware lives in `app/middleware/` and is referenced by its dotted component path.

```cfm
// app/middleware/RequestTiming.cfc
component implements="wheels.middleware.MiddlewareInterface" output="false" {

    public string function handle(required struct request, required any next) {
        local.start = GetTickCount();

        // Run the rest of the pipeline (downstream middleware + controller).
        local.response = arguments.next(arguments.request);

        local.elapsedMs = GetTickCount() - local.start;

        // Headers may already be flushed — never let this throw.
        try {
            cfheader(name = "X-Response-Time", value = "#local.elapsedMs#ms");
        } catch (any e) {}

        return local.response;
    }

}
```

Read it top to bottom and the on-the-way-in / on-the-way-out structure is right there. We stamp the start time, hand control down the chain, and the line after `next` doesn't execute until the controller has finished and the response is built. Then we measure, set a header, and return the response we were handed.

Two details that aren't decoration. The `cfheader` call is wrapped in a bare `try/catch` that swallows everything. That's deliberate and it's what every built-in does — `RequestId`, `SecurityHeaders`, `Cors`, and `RateLimiter` all wrap their header writes the same way. By the time your "on the way out" code runs, the response may already be flushed to the client, and writing a header to a flushed response throws. You do not want a header you're adding for *observability* to take down requests. Swallow the error.

And we return `local.response` — the exact string `next` gave us. We added a header as a side effect; we did not invent a new body. If you forget to return the downstream response, you'll send an empty body to the client. The return type is `string` for a reason: the framework concatenates your return value into the response, and `handle` returning nothing means the response *is* nothing.

That's a complete, shippable middleware. Register it (we'll cover how shortly), reload, and every response grows an `X-Response-Time` header. Now for the part that separates middleware that works in dev from middleware that survives production.

## The lifecycle that changes everything: singletons

Here is the rule that you must internalise before you write any middleware with state:

**Every middleware instance is a singleton shared across every concurrent request for the entire application lifetime.**

Not per-request. Not per-thread. One instance, reused for every request that hits your app until the app reloads. Global middleware is resolved exactly once when Dispatch initialises; route-scoped middleware specified as a string path is instantiated on first encounter and then cached. Either way, the same object handles request #1 and request #50,000, and it handles them concurrently — request #50,000 might be executing `handle` on the same instance while request #49,999 is still mid-flight.

This is by design, and the framework goes out of its way to preserve it: the matched route's `middleware` entries are deliberately exempted from the per-request `Duplicate()` pass Dispatch runs over the route struct (`$copyRouteForRequest`), precisely so your singletons aren't reset on every request. It's the same lifecycle contract the built-in `RateLimiter` depends on — an in-memory rate limiter would be useless if its counters reset every request.

The consequence is blunt: **your middleware must be thread-safe.** If `handle` only ever reads its arguments and local variables, you're fine — locals are per-invocation. But the moment you store mutable state in `variables.`, you have shared mutable state across concurrent threads, and you must guard it.

Watch what goes wrong if you don't. Say you want to number each request and log it:

```cfm
// WRONG — variables.requestCount is shared; ++ is not atomic.
variables.requestCount++;
local.seq = variables.requestCount;
```

Under concurrent load, two threads read the same value, both increment, both write — and you've handed out a duplicate sequence number and lost a count. The fix is a `cflock` around the read-modify-write, which is exactly what the built-in `RateLimiter` does: it backs its store with a `java.util.concurrent.ConcurrentHashMap` and wraps every read-modify-write in a `cflock`. Mutable state, locked. Always.

## A stateful middleware, done right

Here's an audit logger that numbers every request it sees and writes a log line. Because the instance is shared, the counter mutation lives inside a `cflock`.

```cfm
// app/middleware/AuditLog.cfc
component implements="wheels.middleware.MiddlewareInterface" output="false" {

    // Called by Dispatch when registered as a STRING path ("app.middleware.AuditLog").
    // Returns `this` so $resolveMiddlewareInstance's CreateObject(...).init() works.
    public AuditLog function init(string logFile = "audit") {
        variables.logFile = arguments.logFile;
        variables.requestCount = 0;   // shared across ALL requests — guard every write
        return this;
    }

    public string function handle(required struct request, required any next) {
        // Mutable shared state MUST be locked — this instance is a singleton.
        cflock(name = "app-auditlog-counter", type = "exclusive", timeout = 5) {
            variables.requestCount++;
            local.seq = variables.requestCount;
        }

        writeLog(
            file = variables.logFile,
            text = "#local.seq# #arguments.request.method# "
                 & "#arguments.request.params.controller#.#arguments.request.params.action#"
        );

        return arguments.next(arguments.request);
    }

}
```

Two things to note beyond the lock.

First, this one has an `init`. The comment explains why, and it's worth understanding the mechanism, because it's the difference between two ways of registering middleware. When you register middleware as a **string path** — `"app.middleware.AuditLog"` — Dispatch's resolver instantiates it with `CreateObject("component", path).init()`. It calls `.init()` unconditionally. So a string-registered middleware **must** have an `init` that returns `this`. When you instead register an already-constructed **object instance** — `new wheels.middleware.Cors(allowOrigins="...")` — the resolver sees a non-simple value and returns it as-is; it never re-inits it. The object instance is responsible for its own construction. Same resolver, two paths, and the `init`-returns-`this` requirement only applies to the string-path form.

Second, notice the `#local.seq#` inside the `writeLog` text — single pounds, so `local.seq` interpolates as the sequence number. (If you doubled them to `##local.seq##`, CFML would read each `##` as one literal `#` and emit the literal text `#local.seq#` with no substitution; you'd need `###local.seq###` to wrap the value in literal hashes.) Standard CFML string-interpolation rules; nothing middleware-specific. The struct reads — `arguments.request.method`, `arguments.request.params.controller` — are the request *context* Dispatch handed us.

This middleware is correct under concurrency because the only shared state it touches is guarded. The `logFile` is set once at init and only ever read; the counter is the one mutable field and it's locked. That's the whole discipline: anything you write to from `handle` that lives in `variables.` gets a lock.

## Short-circuiting: deny before the controller runs

So far we've called `next` every time. But the contract says `handle` returns a string — and nothing forces that string to come from `next`. If you build a response and return it *without* calling `next`, the controller never runs, and neither does any middleware registered after yours. You've short-circuited the pipeline.

The built-ins do this. `RateLimiter` returns its 429 body when you're over the limit. `Cors` returns `""` for an OPTIONS preflight — there's no controller to run for a preflight, so it answers and stops. Here's a maintenance gate that does the same to put the whole app behind a 503 during a deploy:

```cfm
// app/middleware/MaintenanceMode.cfc
component implements="wheels.middleware.MiddlewareInterface" output="false" {

    public MaintenanceMode function init(boolean enabled = false) {
        variables.enabled = arguments.enabled;
        return this;
    }

    public string function handle(required struct request, required any next) {
        if (variables.enabled) {
            try { cfheader(statusCode = "503"); } catch (any e) {}
            // Returning here skips the controller AND any middleware after this one.
            return "Service temporarily unavailable.";
        }
        return arguments.next(arguments.request);
    }

}
```

When `enabled` is true, `handle` sets a 503 status and returns a body — `next` is never called, so nothing downstream of this middleware executes. When it's false, it calls `next` and behaves like a no-op pass-through.

One subtlety about *who* still runs when you short-circuit. Middleware registered **after** the short-circuiting one does not run — control never reaches it. But middleware registered **before** it is already on the stack, mid-`handle`, waiting for its own `next` call to return. When you short-circuit, that earlier middleware's `next(request)` simply returns your short-circuit string, and its "on the way out" code runs as normal. So an outer timing middleware would still record the duration of a 503 and still stamp its header. The chain unwinds; it doesn't get torn down. That's worth keeping in mind when you order middleware — the outermost ones see everything, including the short-circuits below them.

## Registering middleware

You've written the components. Now you wire them in. There are two places, and they compose: **global** middleware (every request) in `config/settings.cfm`, and **route-scoped** middleware (just some routes) in `config/routes.cfm`.

### Global — every request

```cfm
// config/settings.cfm
set(middleware = [
    new wheels.middleware.RequestId(),                       // object instance: used as-is
    new wheels.middleware.SecurityHeaders(),
    "app.middleware.RequestTiming",                          // string path: CreateObject(...).init() once, then cached singleton
    new wheels.middleware.Cors(allowOrigins = "https://myapp.com")
]);
// Array order = execution order: RequestId runs first (outermost), Cors last (innermost), then the controller.
```

The array order is the execution order, and it's outermost-to-innermost. The first entry wraps the second, which wraps the third, all the way down to the controller. So `RequestId` runs first on the way in and last on the way out; `Cors` is the innermost middleware, closest to the controller. Pick the order with the on-the-way-in / on-the-way-out frame in mind: a timer you want outermost so it measures everything; a thing that short-circuits cheaply you might want earlier so it bails before expensive middleware runs.

Notice the two registration *forms* in that one array. `new wheels.middleware.RequestId()` is an object instance — constructed right there, used as-is, never re-inited. `"app.middleware.RequestTiming"` is a string path — the resolver instantiates it with `CreateObject(...).init()` on first use and caches the singleton. Both are fine. The string form is handy when the middleware takes no constructor args (or sensible defaults) and you'd rather not `new` it in your config; the object form is what you reach for when you need to pass configuration, like `Cors`'s `allowOrigins`. They behave identically once resolved — both become lifetime singletons.

### Route-scoped — just some routes

```cfm
// config/routes.cfm
mapper()
    .scope(path = "/admin", middleware = ["app.middleware.AuditLog"])
        .resources("users")
        // Nested scope: AuditLog (parent) runs before MaintenanceMode (child).
        .scope(path = "/reports", middleware = "app.middleware.MaintenanceMode")
            .resources("exports")
        .end()
    .end()
    .resources("posts")
    .wildcard()
.end();
```

Route-scoped middleware attaches to a `.scope()` and only runs for requests that match that scope's routes. The `middleware` argument takes either an array (`["app.middleware.AuditLog"]`) or a single comma-delimited string — both resolve to the same list. And scopes nest: the inner `/reports` scope inherits `/admin`'s middleware, with the parent's running first. So a request to `/admin/reports/exports` runs `AuditLog` (from the parent scope) and then `MaintenanceMode` (from the child).

Route-scoped string middleware go through the *same* singleton resolver and cache as global ones, so they're lifetime singletons too — the thread-safety rule applies identically. The only timing wrinkle is that a route-scoped string middleware is instantiated lazily, on first encounter, which is well after the app has finished starting. If your `init` reads application state, it must tolerate being called late. (`SecurityHeaders` handles exactly this by checking both `application.$wheels` and `application.wheels` at init, because it can't assume which is populated by the time it runs.)

### The order across both

Put the two together and the full order is fixed: **global middleware always runs before route-scoped middleware.** Dispatch resolves your global list once, and for each request concatenates `[global..., route-scoped...]` into a fresh pipeline. So for a request to `/admin/users`, the order is: every global middleware (in array order), then `AuditLog`, then the controller — and unwinding back out the same way. Global is always the outer shell; route-scoped is always inside it.

## Sharp edges

These are the things that will actually bite you. Every one is real and every one comes from how the framework is built, not from style preference.

**The `request` parameter shadows the engine `request` scope.** This is the big one. Inside `handle`, your `required struct request` parameter has the same name as CFML's `request` scope. On Adobe CF in particular, a bare `request.wheels.x = ...` inside `handle` writes to your *passed struct*, not the engine scope — and you probably meant the scope. This is cross-engine anti-pattern #11 (reserved scope names shadowing parameters) hitting the most-used name in the whole interface. The framework's own `RequestId` works around it by writing the scope from a separate helper, `$writeRequestId`, that has no `request` parameter — so inside that helper, `request` is unambiguously the scope. If you need to write to the actual `request` scope from middleware, do the same: push it into a helper that doesn't take a `request` argument.

**Singletons mean shared mutable state.** Said once already, repeated because it's the bug you'll actually ship: one instance, every concurrent request, for the app's lifetime. Don't keep per-request state in `variables.` without a lock. If you find yourself wanting "the current user for this request" as a `variables.` field, stop — that's a per-request value living on a shared object, and it will leak across requests. Put per-request data in `local` (per invocation) or on the request struct, never on the instance.

**String-path middleware must have `init` returning `this`.** The resolver calls `CreateObject("component", path).init()` on string entries, unconditionally. No `init`, or an `init` that doesn't return `this`, and string registration breaks. Object-instance registration doesn't have this requirement — the instance is used as-is and never re-inited — so if you register with `new`, your constructor runs at `new` time and that's it.

**Header writes can fail if the response is flushed.** Wrap every `cfheader` in your "on the way out" code in a `try/catch` that ignores the error. All four built-ins do. A header you're adding should never be able to crash a request that was otherwise fine.

**Config that's a list isn't automatically a header value.** If your middleware takes a comma-list option (like `Cors`'s `allowOrigins`) but writes a single-value protocol header, you can't echo the list straight through — that's anti-pattern #13. `Cors` resolves the list to exactly one value per request (a specific matched origin, `*`, or nothing at all) and emits `Vary: Origin` only when it reflects a specific origin. It also refuses at construction to combine `allowOrigins="*"` with `allowCredentials=true`, throwing `Wheels.Cors.InvalidConfiguration`. If you accept list-shaped config that feeds a single-value output, resolve to one value yourself.

## What you actually have to remember

The interface is one method. `handle(request, next)` returns a string. Code before `next` runs in; code after runs out; return `next`'s value, or return your own string to short-circuit. That's the whole programming model and you can hold it in your head.

The lifecycle is the part to respect. One instance, shared, concurrent, for the app's life — so lock any mutable state and never stash per-request data on the instance. The built-ins aren't a special internal API; they're the same `implements="wheels.middleware.MiddlewareInterface"` you'll write, following the same rules. `RequestId` shows the scope-shadow workaround, `RateLimiter` shows the locking discipline, `Cors` shows single-value-from-a-list resolution and the short-circuit. When you're unsure how to handle an edge in your own middleware, open `vendor/wheels/middleware/` and read how the framework handles it — that's the reference implementation, and now you can read it fluently.

Beyond that: drop your `.cfc` in `app/middleware/`, register it global in `config/settings.cfm` or route-scoped in `config/routes.cfm`, mind the order, and reload. The layer below your controllers is yours to extend.
