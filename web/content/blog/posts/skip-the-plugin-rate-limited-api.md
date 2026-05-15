---
title: 'Skip the Plugin: Building a Rate-Limited API in Wheels 4.0'
slug: skip-the-plugin-rate-limited-api
publishedAt: '2026-05-15T14:00:00.000Z'
updatedAt: '2026-05-15T14:00:00.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - middleware
  - rate-limiting
  - security
categories: []
excerpt: >-
  Wheels 4.0 ships a real middleware pipeline, and three of the things you used
  to reach for a plugin to add — rate limiting, CORS, and security headers —
  are built in. This post walks through wiring a JSON API with per-API-key
  rate limits, sane proxy handling, and the right ordering so you do not
  accidentally weaken the very headers you were trying to add.
coverImage: null
---

For most of Wheels' history, "I need to rate-limit my API" meant one of three things. You wrote a `before` filter that ran a `cflock`-guarded counter against the session scope (works fine until you put a load balancer in front of it). You leaned on Cloudflare or your CDN to do it at the edge (works fine until you have an internal API behind a VPN). Or you went looking for a plugin, found two that hadn't been updated in five years and one that almost did what you wanted, and started reading source code.

Wheels 4.0 makes that conversation shorter. The dispatcher now runs a real middleware pipeline, and three of the things people used to plug in — rate limiting, CORS, and security headers — ship in the box. This post walks through a small, opinionated JSON API: anonymous browsers get one limit, authenticated API keys get another, every response carries security headers, and the whole stack is composed in fifteen or so lines of `config/settings.cfm` and `config/routes.cfm`.

## The shape of a Wheels 4.0 middleware

A middleware in 4.0 is a component that implements `wheels.middleware.MiddlewareInterface`. It has one public method:

```cfm
public string function handle(required struct request, required any next) {
    // do work before the controller runs ...
    var response = arguments.next(arguments.request);
    // ... do work after the controller runs
    return response;
}
```

`next` is a closure. Call it and the rest of the pipeline runs, ending in the controller dispatch. Don't call it and the request short-circuits — useful when you want to reject a request before it ever reaches the controller, which is exactly what rate limiting does on the unhappy path.

You compose middleware in two places. Global middleware runs on every request and lives in `config/settings.cfm`:

```cfm
set(middleware = [
    new wheels.middleware.RequestId(),
    new wheels.middleware.SecurityHeaders()
]);
```

Route-scoped middleware runs only on routes inside a `.scope(...)` block in `config/routes.cfm`:

```cfm
mapper()
    .scope(path="/api", middleware=[
        new wheels.middleware.Cors(allowOrigins="https://myapp.com"),
        new wheels.middleware.RateLimiter(maxRequests=60, windowSeconds=60)
    ])
        .resources("users")
        .resources("orders")
    .end()
.end();
```

That's the whole composition model. The rest of this post is about picking the right arguments.

## Three strategies, one decision

The built-in `RateLimiter` supports three algorithms, and the choice matters more than you'd think.

**Fixed window** is the default and the cheapest. It puts every client into a counter keyed by `(client, windowId)` where `windowId` is the time bucket. Fast to compute, almost no memory per client, and it has one known weakness: if a client makes 60 requests in the last second of one window and 60 more in the first second of the next, you let through 120 in two seconds when you thought your limit was 60 in 60.

```cfm
new wheels.middleware.RateLimiter(maxRequests = 60, windowSeconds = 60)
```

**Sliding window** keeps a timestamp log per client and counts how many fall inside the rolling window from now. More accurate, more memory — each client costs `O(maxRequests)` timestamps. Use it when the fixed-window burst-at-the-boundary is unacceptable.

```cfm
new wheels.middleware.RateLimiter(maxRequests = 60, windowSeconds = 60, strategy = "slidingWindow")
```

**Token bucket** is the right answer when you want to *allow* short bursts but enforce an average rate. The bucket holds up to `maxRequests` tokens and refills at `maxRequests / windowSeconds` per second. A burst of traffic drains it; sustained traffic is bounded by the refill rate.

```cfm
new wheels.middleware.RateLimiter(maxRequests = 60, windowSeconds = 60, strategy = "tokenBucket")
```

Pick by behavior, not by name. APIs that are mostly chatty with occasional spikes want token bucket. APIs that need a hard guarantee of "no more than N per minute, period" want sliding window. Everything else gets fixed window and a good night's sleep.

## The proxy footgun

Here is the one place rate limiters bite back, and Wheels 4.0 defaults to safe.

By default, the limiter keys on `cgi.remote_addr`. If your app sits behind nginx, AWS ALB, or Cloudflare, that's the proxy's IP, not the client's. Every request from every user buckets together and you've built a global denial-of-service against your own users.

The obvious fix is `X-Forwarded-For`. The problem with that header is that it's set by the client. Anyone can put whatever they like in there. Trust it without thinking and you get the inverse problem: an attacker can rotate `X-Forwarded-For` values to land in a fresh bucket on every request, and your limiter does nothing.

So the limiter requires an explicit opt-in. To use `X-Forwarded-For`, you say so:

```cfm
new wheels.middleware.RateLimiter(
    maxRequests = 60,
    windowSeconds = 60,
    trustProxy = true,
    proxyStrategy = "last"   // default
)
```

`proxyStrategy = "last"` reads the rightmost entry in `X-Forwarded-For`. That's the one most recently added by the proxy nearest to your app, which is the only entry you can trust. `"first"` reads the leftmost entry, which is the original client-supplied value — useful only when you know exactly which proxy chain is in front of you and you've configured it to write a fresh `X-Forwarded-For`. For nginx, the standard `proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;` appends the upstream IP, so `"last"` is right. For Cloudflare, use `CF-Connecting-IP` directly via a custom key function instead — described next.

If you're not behind a proxy at all, leave `trustProxy = false` and the limiter uses `cgi.remote_addr` like it should.

## The hero example: per-API-key, not per-IP

Most internal APIs and B2B integrations need different limits for anonymous traffic and authenticated callers. The same office IP might host dozens of legitimate API keys; the same API key might roam across IPs. Keying on `remote_addr` is the wrong layer.

The `keyFunction` parameter lets you decide what to bucket on. It receives the request struct and returns a string — Wheels uses that string as the bucket key, falling back to IP if you don't provide one.

```cfm
var keyFunction = function(req) {
    if (StructKeyExists(req, "cgi") && StructKeyExists(req.cgi, "http_x_api_key") && Len(req.cgi.http_x_api_key)) {
        return "apikey:" & req.cgi.http_x_api_key;
    }
    return "ip:" & req.cgi.remote_addr;
};

var limiter = new wheels.middleware.RateLimiter(
    maxRequests   = 2,
    windowSeconds = 60,
    strategy      = "slidingWindow",
    keyFunction   = keyFunction
);
```

Now Alice with `X-Api-Key: alice-key` gets her own bucket. Bob with `X-Api-Key: bob-key` gets a separate one even though they're behind the same office NAT. Anonymous traffic falls through to the IP bucket, which is the right behavior — you still want to slow down a scraper that isn't bothering with a key.

There's one subtle safety net to know about. By default, any key longer than 128 characters gets replaced with its SHA-256 hash before being stored. That prevents an attacker who controls the value of `X-Api-Key` from inflating the in-memory store with arbitrarily long strings. If you want to tune it, the parameter is `maxKeyLength`.

## Stacking middleware: order matters

Here is the canonical order for a JSON API. The reasoning is in the comments.

```cfm
// config/settings.cfm — runs on every request
set(middleware = [
    new wheels.middleware.RequestId(),       // generate request.wheels.requestId for logs
    new wheels.middleware.SecurityHeaders()  // OWASP-recommended response headers
]);
```

```cfm
// config/routes.cfm — runs only on /api/*
mapper()
    .scope(path="/api", middleware=[
        new wheels.middleware.Cors(allowOrigins="https://myapp.com"),
        new wheels.middleware.RateLimiter(
            maxRequests   = 100,
            windowSeconds = 60,
            strategy      = "tokenBucket",
            keyFunction   = keyFunction,
            trustProxy    = true
        )
    ])
        .resources("users")
        .resources("orders")
    .end()
.end();
```

`SecurityHeaders` runs in the outermost wrap because it adds response headers on the way *out*. Whatever the inner stack produces — a `200 OK`, a `404`, a `429 Too Many Requests` — `SecurityHeaders` decorates it on the way back. If you reordered it inside `RateLimiter` and a request got rate-limited, the `429` would go out without your security headers.

CORS goes outside the rate limiter for the same reason. If you rate-limit an API request from a browser and the browser can't read the `429` response because there's no `Access-Control-Allow-Origin` header on it, your front-end developer files a bug about a "phantom CORS error" that's actually a 429.

## Storage, multi-instance, and the failure mode

The limiter stores state in memory by default. That's fine for a single instance. Two app servers behind a load balancer, each with their own memory, will each enforce the limit independently — meaning the actual ceiling is twice what you configured.

For multi-instance deployments, switch storage to database:

```cfm
new wheels.middleware.RateLimiter(
    maxRequests   = 100,
    windowSeconds = 60,
    storage       = "database"
)
```

A `wheels_rate_limits` table gets auto-created on first use; no migration to write. Trade-off is the obvious one: every request now does a couple of indexed selects and an upsert. Whether that's a problem depends on your traffic. For 4.0 we settled on "in-memory for the default, database for the opt-in," which mirrors the choice every other framework makes.

One more knob worth knowing about: `failOpen`. If the limiter's lock times out — which under normal load shouldn't happen, but can under pathological contention — what should it do? By default, it fails *closed*: the request is rejected with a `429`. That's the secure default, and it's the right one for APIs where you'd rather drop a request than over-serve. If you'd rather prioritize availability over strict enforcement, set `failOpen = true` and the limiter lets the request through when it can't be sure.

## What changed since I started writing this post

If you read this post a week from now, one detail will be subtly different. While probing edge cases for the article, I tried `windowSeconds = 0` to see what happened. The fixed-window and token-bucket strategies threw a generic "You cannot divide by zero" exception — accurate but useless for debugging. That's the kind of error message that costs an hour the first time you hit it.

[Issue #2693](https://github.com/wheels-dev/wheels/issues/2693) tracks the fix. The constructor now refuses `windowSeconds <= 0` and negative `maxRequests` at init time with a `Wheels.RateLimiter.InvalidConfiguration` and a message that names the bad parameter and explains what would have gone wrong. Regression coverage is in `RateLimiterSpec`. `maxRequests = 0` is still legal — it's the kill-switch idiom for "block everything," which has real uses (incident response, rolling a key out of production, etc.).

This is the kind of thing the middleware refactor in 4.0 makes easy. The validation lives in one place, the error type is framework-shaped, and a developer who fat-fingers the configuration gets a one-line pointer back to their own code rather than a CFML engine traceback.

## What this looks like in practice

A few months from now, your `config/routes.cfm` will probably look something like this:

```cfm
var keyFunction = function(req) {
    if (StructKeyExists(req, "cgi") && StructKeyExists(req.cgi, "http_x_api_key") && Len(req.cgi.http_x_api_key)) {
        return "apikey:" & req.cgi.http_x_api_key;
    }
    return "ip:" & req.cgi.remote_addr;
};

mapper()
    // Browser app — relaxed limits, narrower CORS
    .scope(path="/api/v1", middleware=[
        new wheels.middleware.Cors(allowOrigins="https://myapp.com"),
        new wheels.middleware.RateLimiter(
            maxRequests   = 600,
            windowSeconds = 60,
            strategy      = "tokenBucket",
            keyFunction   = keyFunction,
            trustProxy    = true
        )
    ])
        .resources("posts")
        .resources("comments")
    .end()

    // Webhook receivers — strict, IP-keyed, short fuse
    .scope(path="/webhooks", middleware=[
        new wheels.middleware.RateLimiter(
            maxRequests   = 30,
            windowSeconds = 60,
            strategy      = "fixedWindow",
            trustProxy    = true
        )
    ])
        .post(name="stripeWebhook", to="webhooks##stripe")
    .end()

    // Authentication endpoint — different limit again
    .scope(path="/auth", middleware=[
        new wheels.middleware.RateLimiter(
            maxRequests   = 5,
            windowSeconds = 60,
            strategy      = "slidingWindow",
            trustProxy    = true
        )
    ])
        .post(name="login", to="sessions##create")
    .end()
.end();
```

Three different policies, three different keying strategies, one framework. No plugin. No custom filter to maintain. No accidentally trusting `X-Forwarded-For`.

That's the bet 4.0 makes: that a thoughtful middleware stack you can read in fifteen lines beats a "one ring to rule them all" rate-limiting plugin every time. So far the bet seems to be paying off.
