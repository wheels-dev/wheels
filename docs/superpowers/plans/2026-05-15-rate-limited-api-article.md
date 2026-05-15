# Blog Article: Skip the Plugin — Building a Rate-Limited API in Wheels 4.0

**Status:** Concept + validation plan
**Author:** Peter Amiri (drafting via assistant)
**Target publish:** 2026-05-15 (post-GA)

## Audience

Wheels developers who would previously have reached for a plugin, a hand-rolled
`cflock`-based throttle, or a Cloudflare/Cloud-WAF rule to bolt rate limiting
onto a JSON API. They know what 4.0 announced last week but haven't yet
written code against the new middleware stack.

## Thesis

In Wheels 4.0 the dispatcher runs a real middleware pipeline. You don't write
filters or plugins to enforce rate limits, add CORS, or emit security headers
— you compose middleware objects in `config/settings.cfm` (global) or
`config/routes.cfm` (route-scoped). The article walks through the design with
one concrete example: a small JSON API that needs different limits for
anonymous traffic vs authenticated API keys, with CORS for browser clients
and security headers on every response.

## Structure

1. **The problem — what plugins used to do.** A brief vignette of the old
   workflow (install plugin / write your own `before` filter / accidentally
   trust `X-Forwarded-For`).
2. **The dispatcher meets middleware.** Tour of the pipeline:
   - global stack via `set(middleware = [...])` in `config/settings.cfm`
   - route-scoped via `.scope(middleware=[...])` in `config/routes.cfm`
   - how a request actually flows through.
3. **Three rate-limit strategies, picked by behavior.**
   - `fixedWindow` — cheap, bursty at boundaries
   - `slidingWindow` — accurate, more memory
   - `tokenBucket` — allow short bursts, refill steadily
   - When each is the right answer, with the `new wheels.middleware.RateLimiter(...)` config for each.
4. **Don't trust `X-Forwarded-For` by accident.** The `trustProxy` flag, why
   it's off by default (spoof prevention), and what `proxyStrategy="last"`
   means in front of nginx vs an AWS ALB vs Cloudflare.
5. **Custom keys: rate-limit per API key, not per IP.** A `keyFunction`
   closure example that pulls `X-Api-Key`, plus the `maxKeyLength` safety net
   (long keys get hashed so attackers can't bloat the store).
6. **Scoping middleware to routes.** Apply a strict limit to `/api`, a
   relaxed one to `/login`, none to the rest. Use the mapper DSL.
7. **Stacking with CORS and SecurityHeaders.** The canonical ordering
   (RequestId → SecurityHeaders → Cors → RateLimiter → app) and why it
   matters — rate-limited responses still need CORS so browsers can read
   them.
8. **Database storage for multi-instance deploys.** When to switch from
   `storage="memory"` to `storage="database"`, the auto-created
   `wheels_rate_limits` table, and the fail-closed default.
9. **What to assert about it.** A short BDD test from `RateLimiterSpec` that
   any reader can copy as the seed for their own coverage.

## Why this article works post-GA

The launch posts named the features. This one shows a user shipping a real
API with them — the "how do I actually use 4.0?" piece that the cohort of
post-GA readers is hungry for.

## Validation plan (must pass before publishing)

Every code sample in the article will be one of:

- Lifted verbatim from a passing spec in `vendor/wheels/tests/specs/middleware/`, OR
- A new spec authored alongside this article and added to the same directory.

Test commands:

```
tools/test-matrix.sh lucee7 sqlite          # baseline middleware suite
```

New specs required:

- `apiKeyRateLimitSpec.cfc` — covers the custom `keyFunction` pattern
  (anonymous → IP bucket; authenticated → API-key bucket) end-to-end.

Existing specs the article relies on (already in repo, must remain green):

- `RateLimiterSpec.cfc` (trustProxy, proxyStrategy, maxStoreSize)
- `SecurityHeadersSpec.cfc`
- `CorsSpec.cfc`
- `MiddlewarePipelineSpec.cfc` (ordering)

## Open questions / risks

- The article will reference the canonical stack ordering. Need to confirm
  there isn't an undocumented convention that contradicts what I'm planning
  to write (e.g., whether `RequestId` must run before `RateLimiter` for
  diagnostic correlation in 429 responses).
- The `keyFunction` snippet needs to work cleanly under Adobe CF in addition
  to Lucee — closure semantics differ. Will verify with at least one Adobe
  pass in the matrix before publishing.

## Issues to file (if discovered)

Any framework or CLI defects found while building the test app or running
the spec suite get a GitHub issue on `wheels-dev/wheels` and a follow-up PR
on the same branch. Article does not publish until those land.
