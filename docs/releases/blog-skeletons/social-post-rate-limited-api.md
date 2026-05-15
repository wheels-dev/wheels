# Social Posts — "Skip the Plugin: Building a Rate-Limited API in Wheels 4.0"

**Status:** Copy-paste ready. Post-GA follow-up to the GA campaign in `social-announcements.md`.
**Pairs with:** [web/content/blog/posts/skip-the-plugin-rate-limited-api.md](../../../web/content/blog/posts/skip-the-plugin-rate-limited-api.md)
**Post date:** 2026-05-15 (same day as the article)
**Tone:** Post-GA, present tense, how-to angle. The launch story is done — this is the "now go build with it" beat.

**Canonical URL** (use everywhere):
- `https://blog.wheels.dev/posts/skip-the-plugin-rate-limited-api`

---

## Slack (#wheels-dev)

```
New on the blog: Skip the Plugin — Building a Rate-Limited API in Wheels 4.0.

<https://blog.wheels.dev/posts/skip-the-plugin-rate-limited-api|Full post>

What it covers:
• Three rate-limit strategies in the box — fixed window, sliding window, token bucket — and which one to pick
• Per-API-key limiting via the `keyFunction` closure (Alice and Bob behind the same office NAT, different buckets)
• The `trustProxy` / `proxyStrategy` footgun — why it's off by default and how to read `X-Forwarded-For` safely behind nginx vs ALB vs Cloudflare
• Canonical pipeline order: RequestId → SecurityHeaders → Cors → RateLimiter → app, and why 429s still need CORS
• In-memory vs database storage, fail-closed default, `wheels_rate_limits` auto-table

Side effect of writing the post: a small framework fix (#2693) — `RateLimiter` now throws a typed error at init time when `windowSeconds=0` instead of leaking a div-by-zero out of the strategy math.
```

---

## LinkedIn

```
New on the Wheels blog: Skip the Plugin — Building a Rate-Limited API in Wheels 4.0.

For most of Wheels' history, "I need to rate-limit my API" meant one of three things — write a cflock-guarded counter in a before-filter, push it out to the CDN edge, or go find a plugin and read its source code to understand what it actually does. Wheels 4.0 makes that conversation shorter. The dispatcher now runs a real middleware pipeline, and three things people used to plug in — rate limiting, CORS, and security headers — ship in the box.

The post walks through a small, opinionated JSON API: anonymous browsers get one limit, authenticated API keys get another, every response carries security headers, and the whole stack composes in fifteen lines of config/settings.cfm and config/routes.cfm. Topics covered:

— Three strategies (fixed window, sliding window, token bucket) and the behavior that picks one over the others.
— The X-Forwarded-For footgun: trustProxy is off by default for a reason, proxyStrategy="last" vs "first" maps to your nginx vs Cloudflare vs ALB setup.
— A keyFunction closure that buckets per-API-key for authenticated traffic and falls back to IP for anonymous. Alice and Bob from the same office NAT each get their own bucket.
— Canonical stack order: RequestId → SecurityHeaders → Cors → RateLimiter → app. Why 429s still need CORS headers, why HSTS lives in SecurityHeaders, and why ordering breaks subtly if you reverse it.
— When to flip from in-memory to database storage for multi-instance deployments, and why the limiter fails closed by default.

A side note in the post: writing it surfaced a small framework fix. The RateLimiter constructor previously let windowSeconds=0 through, which produced an opaque "you cannot divide by zero" exception out of the strategy math instead of a framework-shaped configuration error. That's #2693, fixed in the same week the article landed, with a typed Wheels.RateLimiter.InvalidConfiguration error that names the bad parameter. The kind of thing the 4.0 middleware refactor makes easy: one place to validate, one error type, one line back to the misconfigured set(middleware=[...]).

Read: https://blog.wheels.dev/posts/skip-the-plugin-rate-limited-api

#CFML #Wheels #API #RateLimiting #Middleware #WebDevelopment
```

---

## X / Twitter

**Hero tweet (unnumbered):**
```
New on the Wheels blog — Skip the Plugin: Building a Rate-Limited API in Wheels 4.0.

Three strategies, per-API-key keying, the X-Forwarded-For footgun, and the right pipeline order so your 429s still carry CORS headers.

https://blog.wheels.dev/posts/skip-the-plugin-rate-limited-api
```

**Reply 1:**
```
1/ Three rate-limit strategies in the box — pick by behavior, not by name:

• Fixed window — cheapest, bursts at boundaries
• Sliding window — accurate, more memory
• Token bucket — allows short bursts, refills steadily

If your API needs "no more than N per minute, period," reach for sliding.
```

**Reply 2:** (outer fence is `~~~~` so the inner ```` ```cfm ```` block renders correctly in the Markdown preview — the tweet itself is plain text)

~~~~
2/ The hero example — per-API-key, not per-IP:

```cfm
keyFunction = function(req) {
    if (StructKeyExists(req, "cgi") && StructKeyExists(req.cgi, "http_x_api_key") && Len(req.cgi.http_x_api_key)) {
        return "apikey:" & req.cgi.http_x_api_key;
    }
    return "ip:" & req.cgi.remote_addr;
};
```

Alice and Bob behind the same office NAT, each with their own bucket.
~~~~

**Reply 3:**
```
3/ X-Forwarded-For is the place rate limiters bite back.

trustProxy is off by default. When you flip it on, proxyStrategy="last" reads the rightmost entry (the one your nearest trusted proxy added — the one you can trust).

Don't trust client-supplied XFF without knowing your proxy chain.
```

**Reply 4:**
```
4/ Side effect of writing the post: a small framework fix (#2693).

windowSeconds=0 used to leak a generic CFML div-by-zero out of fixedWindow/tokenBucket. Now it throws Wheels.RateLimiter.InvalidConfiguration at init with a message naming the bad parameter.

The middleware refactor in 4.0 made the fix one line.
```

---

## GitHub Discussions

**Title:** `Post-GA blog: Skip the Plugin — Building a Rate-Limited API in Wheels 4.0`

```markdown
Now that 4.0 is out, the post-GA blog series shifts from "what shipped" to "how do you actually use it?" First in the series is the middleware stack — specifically rate limiting, which used to be the most common "I need a plugin for this" request.

**Read:** https://blog.wheels.dev/posts/skip-the-plugin-rate-limited-api

The post is a guided tour of `wheels.middleware.RateLimiter`, `Cors`, and `SecurityHeaders` composed via the new pipeline. It walks through:

- **Three strategies** — `fixedWindow` (default, cheap), `slidingWindow` (accurate), `tokenBucket` (allows bursts). Picked by behavior, not by name.
- **The `keyFunction` hero example** — a small closure that buckets authenticated traffic per `X-Api-Key` and falls back to IP for anonymous. Same office NAT, different buckets for different keys.
- **`trustProxy` and `proxyStrategy`** — why it's off by default (X-Forwarded-For spoofing), why `"last"` is right behind nginx with `proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;`, and where Cloudflare's `CF-Connecting-IP` fits.
- **Canonical stack order** — RequestId → SecurityHeaders → Cors → RateLimiter → app. Why 429s still need CORS so browsers can read them, why SecurityHeaders wraps everything on the way out.
- **In-memory vs database storage** — when to flip to `storage="database"` for multi-instance, and the auto-created `wheels_rate_limits` table.
- **`failOpen` vs fail-closed** — secure default, when to override.

## Side note: a small framework fix surfaced while writing this

While probing edge cases for the post, `windowSeconds = 0` turned out to leak a generic CFML `You cannot divide by zero` out of the `fixedWindow` and `tokenBucket` strategy math — accurate but useless for debugging. That's [#2693](https://github.com/wheels-dev/wheels/issues/2693), fixed in the same week the article landed. The constructor now refuses `windowSeconds <= 0` and negative `maxRequests` at init time and throws `Wheels.RateLimiter.InvalidConfiguration` with a message naming the bad parameter, matching the pattern already used for `strategy`, `storage`, and `proxyStrategy`. `maxRequests = 0` is still legal — it's the kill-switch idiom for "block everything," useful in incident response.

## What's next in the post-GA series

The remaining four titles from the second batch:

1. *Anatomy of a Wheels Package* — authoring, mixins, the registry
2. *Wheels + Claude* — building a feature via the stdio MCP
3. *Beyond findAll* — scopes, enums, the chainable query builder
4. *From Empty Directory to Deployed SaaS* — end-to-end with generators, multi-tenancy, jobs, browser tests, `wheels deploy`

Feedback on the rate-limiting post — what worked, what didn't, what you'd want covered next — welcome in this thread.
```

---

## Posting checklist

- [ ] Article live at `https://blog.wheels.dev/posts/skip-the-plugin-rate-limited-api`
- [ ] PR #2694 merged (article + framework fix + visual baseline)
- [ ] Slack post in `#wheels-dev`
- [ ] LinkedIn post from the Wheels org account
- [ ] X / Twitter hero + 4-reply thread from `@wheels_dev`
- [ ] GitHub Discussions thread under "Show and tell" or equivalent category
- [ ] Verify all four channels link to the same canonical URL
