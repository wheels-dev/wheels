---
title: 'CORS in Wheels 4: Deny by Default, Open It Correctly'
slug: cors-in-wheels-4
publishedAt: '2026-07-13T14:00:00.000Z'
updatedAt: '2026-07-06T05:06:04.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - cors
  - security
  - middleware
  - api
categories: []
excerpt: >-
  Wheels 4 denies cross-origin requests until you say otherwise — and the Cors
  middleware refuses the popular ways of saying it wrong. The deny-all
  breaking change, single-origin resolution, Vary: Origin, preflight handling,
  and the legacy-settings trap the framework defuses for you.
coverImage: null
---

Somewhere right now, a developer is adding `Access-Control-Allow-Origin: *` to a production API because the browser console told them to. The error goes away. The demo works. And an API that was supposed to serve one React frontend is now scriptable from every web page on the internet.

CORS is the security feature everyone meets backwards — as an obstacle to route around rather than a boundary to configure. Wheels 4 took a position on this: **cross-origin requests are denied until you say otherwise**, and the thing you use to say otherwise refuses several popular ways of saying it wrong. This post is how the `Cors` middleware actually behaves, why 4.0 changed the default, and the config mistakes it's specifically designed to catch.

## The breaking change first

If you're coming from 3.x: this is breaking change #1 in the [upgrade guide](https://guides.wheels.dev/v4-0-0/upgrading/3x-to-4x/). Wheels 3's global CORS setting was wildcard-flavored; Wheels 4 denies all cross-origin requests out of the box. Nothing emits CORS headers until you configure an origin list. If your SPA broke the day you upgraded, this is why — and the fix is one middleware registration, not a return to `*`.

```cfm
// config/settings.cfm
set(middleware = [
    new wheels.middleware.Cors(allowOrigins="https://app.example.com")
]);
```

That's a working, correctly-scoped CORS setup. Everything else in this post is what happens around that line.

## The constructor, and what it refuses

```cfm
new wheels.middleware.Cors(
    allowOrigins     = "",                                            // REQUIRED in practice — "" means deny all
    allowMethods     = "GET,POST,PUT,PATCH,DELETE,OPTIONS",
    allowHeaders     = "Content-Type,Authorization,X-Requested-With",
    allowCredentials = false,
    maxAge           = 86400                                          // preflight cache, seconds
)
```

`allowOrigins` takes a comma-delimited list (whitespace around entries is ignored) or `"*"`. The default is the empty string — deny everything — which is the whole philosophy in one default: you can't accidentally have CORS; you can only decide to.

And one combination throws at construction time, on purpose:

```cfm
// Throws Wheels.Cors.InvalidConfiguration — at startup, not at request time
new wheels.middleware.Cors(allowOrigins="*", allowCredentials=true)
```

Wildcard-plus-credentials is the classic CORS footgun: browsers refuse it anyway per the Fetch spec, but only after you've shipped it and spent an afternoon debugging why cookies don't arrive. Wheels moves that discovery to boot time with a message that tells you the two valid ways out: list specific origins, or drop credentials.

## One origin goes out, never the list

Here's the subtle spec detail the middleware handles that hand-rolled CORS code almost always gets wrong. Your *config* is a list:

```cfm
new wheels.middleware.Cors(allowOrigins="https://app.example.com, https://admin.example.com")
```

But `Access-Control-Allow-Origin` is a **single-value header** — the spec allows exactly one origin or `*`, never a comma-separated list. A response that echoes the whole list is malformed, browsers reject it, and (worse) if a CDN caches it, one origin's response can poison the cache for another.

So the middleware resolves per request: it matches the request's `Origin` header against your list and emits *that one origin* on a hit, or no CORS headers at all on a miss. And whenever the response depends on which origin asked, it emits **`Vary: Origin`** alongside — the header that tells every cache in the chain "don't serve origin A's response to origin B." You get the spec-correct behavior without knowing the spec trivia; the trivia is encoded in the component.

## Preflight, handled

Any cross-origin request that isn't "simple" — a `PUT`, a `DELETE`, anything with a `Content-Type: application/json` body or an `Authorization` header — triggers a browser preflight: an `OPTIONS` request asking permission before the real request is sent. The middleware short-circuits these itself: an `OPTIONS` request from an allowed origin gets the allow-headers and an immediate empty response. Your controllers never see preflights, you don't need an `OPTIONS` route, and `maxAge` tells the browser how long to cache the permission (the default is a day — turn it down while you're actively changing CORS config, because a cached preflight verdict survives your redeploys).

This works because Wheels 4's middleware pipeline runs after route matching but *before* controller instantiation, with a request context that carries the real HTTP method — so the middleware can answer the preflight without dragging your application code into it.

## Where to put it: global vs route-scoped

The registration above is global — every route gets CORS handling. If only your API is cross-origin (the usual case: HTML pages are same-origin by definition), scope it:

```cfm
// config/routes.cfm
mapper()
    .scope(path="/api", middleware=[
        new wheels.middleware.Cors(allowOrigins="https://app.example.com")
    ], callback=function(map) {
        map.resources("users");
        map.resources("orders");
    })
.end();
```

Now `/api/*` speaks CORS and the rest of the app keeps the deny-all posture. One lifecycle note that applies to all Wheels middleware: instances are resolved once and cached for the application lifetime — the same object serves every matching request. `Cors` holds only its immutable config, so that's free; just know the contract if you subclass it.

## The migration trap: old settings alongside new middleware

Wheels 3 configured CORS through half a dozen global settings (`allowCorsRequests` and the `accessControlAllow*` family). Those still exist for compatibility — which sets up a nasty possibility: both the legacy path *and* your new middleware handling the same request, emitting duplicate headers. Duplicate CORS headers aren't harmless; browsers treat a doubled `Access-Control-Allow-Origin` as a hard error.

As of [#3114](https://github.com/wheels-dev/wheels/issues/3114), the framework defuses this itself: when a `wheels.middleware.Cors` instance is registered, the global `allowCorsRequests` path detects it and **defers automatically**, writing a one-time warning to `wheels.log` instead of a second set of headers. So the upgrade can't break you silently — but the warning is your prompt to finish the job: delete the six legacy CORS settings from `config/settings.cfm` and let the middleware be the single owner.

## Debugging CORS without guessing

Three habits that turn CORS debugging from vibes into observation:

1. **curl the preflight yourself.** `curl -is -X OPTIONS -H "Origin: https://app.example.com" -H "Access-Control-Request-Method: PUT" https://api.example.com/api/users/1` — you should see your origin echoed back and your methods list. If you see nothing, the origin didn't match the list; check for scheme and port exactness — origins are matched as whole strings (case-insensitively), so `https://app.example.com` and `https://app.example.com:443` are different entries, and `http://` is not `https://`.
2. **Look for `Vary: Origin` on responses that carry CORS headers.** If it's missing, something other than the middleware is emitting your headers — usually a leftover legacy setting or a proxy layer doing its own CORS.
3. **Remember the browser cache.** A preflight cached under yesterday's config outlives today's deploy for up to `maxAge` seconds. When testing config changes, use a private window or drop `maxAge` temporarily.

## The posture, in one paragraph

Deny by default. Configure a list, emit a single origin. Refuse wildcard-with-credentials before the app even boots. Emit `Vary: Origin` so caches can't cross the streams. Answer preflights before application code runs. Defer the legacy path so upgrades fail loud instead of double-headed. None of these decisions is exotic — they're just the accumulated cost of every CORS misconfiguration the CFML community has shipped over the years, paid once, in the framework, so you don't pay it per app.

The reference lives in the [Middleware Pipeline guide](https://guides.wheels.dev/v4-0-0/core-concepts/middleware-pipeline/) and the [CORS page](https://guides.wheels.dev/v4-0-0/digging-deeper/cors/); the deny-all migration details are in the [3.x → 4.0 upgrade guide](https://guides.wheels.dev/v4-0-0/upgrading/3x-to-4x/).

