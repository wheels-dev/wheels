---
title: Security Hardening in Wheels 4.0
slug: security-hardening-in-wheels-4
publishedAt: '2026-05-07T14:00:00.000Z'
updatedAt: '2026-05-07T02:00:09.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - security
  - hardening
categories: []
excerpt: >-
  Wheels 4.0 shipped more than forty security-hardening pull requests across
  eight categories — SQL, path handling, session integrity, CORS, rate
  limiting, auth and dev surfaces, CLI and MCP, and view helpers. The common
  thread is a shift in posture: the framework's defaults are now safe first,
  convenient second.
coverImage: null
---

If you audit your own stack, you already know the shape of a "security release." It is usually a CVE round-up — a list of issues found, patches shipped, advisories published. Wheels 4.0 is not that release. It is the one where the defaults themselves changed.

Across roughly forty pull requests, 4.0 moved the framework from a per-issue patch model to a secure-by-default posture. The work grouped itself into eight categories: SQL injection, path traversal, session and CSRF integrity, CORS and security headers, rate limiting, auth and developer surfaces (JWT, console, reload, env-switch), the new AI-era surfaces (CLI and MCP), and view helpers. Each category got the same treatment — audit every surface, tighten the default, name the remaining sharp edges.

This post walks each category, shows the defaults that changed, and is honest about what the framework still does not claim to solve.

## From patches to posture

Wheels 3.0 handled security the way most frameworks handle it: when a report came in, a patch went out. The model worked, but it put the burden on the operator. You had to know which opt-in settings to flip to get HSTS, which defaults to override to stop wildcard CORS, whether your CSRF setup would survive a restart. The happy path was "insecure unless you configured otherwise."

4.0 inverts that. The happy path is now "secure unless you explicitly opted out." That is a posture change, not a single feature — which is why the work is spread across so many small PRs instead of one big one.

## SQL injection — the scope and QueryBuilder pipeline

The biggest category by PR count was SQL. The QueryBuilder chain — `where`, `orWhere`, `whereIn`, `whereNotIn`, `whereBetween`, `whereNull` — was hardened end to end so that user-provided values cannot break out of their parameter slot regardless of operator ([#2025](https://github.com/wheels-dev/wheels/pull/2025), [#2026](https://github.com/wheels-dev/wheels/pull/2026), [#2033](https://github.com/wheels-dev/wheels/pull/2033), [#2043](https://github.com/wheels-dev/wheels/pull/2043), [#2045](https://github.com/wheels-dev/wheels/pull/2045), [#2056](https://github.com/wheels-dev/wheels/pull/2056), [#2061](https://github.com/wheels-dev/wheels/pull/2061), [#2070](https://github.com/wheels-dev/wheels/pull/2070), [#2090](https://github.com/wheels-dev/wheels/pull/2090)).

Scopes got the same pass. Static scopes and dynamic scope handlers both validate identifiers and parameterize values, which means `model("User").active().byRole(params.role).findAll()` is safe even when `params.role` is a raw query-string value ([#2044](https://github.com/wheels-dev/wheels/pull/2044), [#2055](https://github.com/wheels-dev/wheels/pull/2055), [#2058](https://github.com/wheels-dev/wheels/pull/2058)). Beyond scopes, identifier-accepting surfaces — table names, column names, ordering clauses — were audited for the "what if this is a string from the user" case ([#2023](https://github.com/wheels-dev/wheels/pull/2023), [#2047](https://github.com/wheels-dev/wheels/pull/2047)).

The takeaway is not "Wheels guarantees no SQL injection." It is narrower and more useful: every place user input reaches SQL through the model API is parameterized, and scopes and QueryBuilder chains are safe to use with untrusted values. Raw `where=` strings built by string-concatenating user input are still your problem. That has not changed.

## Path traversal — every surface that takes a path

Path-accepting surfaces are easy to miss because they look innocuous. A `renderPartial()` call that takes a partial name, a guide-image helper that serves framework doc assets, an MCP tool that reads documentation files — each one is a path interpreter, and each one needs to refuse traversal sequences.

4.0 audited all of them. Partial rendering rejects paths that escape the views directory ([#2071](https://github.com/wheels-dev/wheels/pull/2071)). The guide image helper canonicalizes and validates the image path ([#2037](https://github.com/wheels-dev/wheels/pull/2037)). The MCP documentation reader, which became a new path-accepting surface when we added AI tooling, got the same canonicalization treatment ([#2049](https://github.com/wheels-dev/wheels/pull/2049)). And because naive `..` checks miss URL-encoded variants, a second pass closed the encoded-bypass hole ([#2089](https://github.com/wheels-dev/wheels/pull/2089)).

The takeaway: if you accept a path from a request, you now have a pattern to follow — resolve, canonicalize, then compare against the allowed root. The framework's own surfaces all do this.

## Session integrity, CSRF, and open redirects

Three different vulnerabilities, one theme: state that moves between client and server must be harder to tamper with than a single misconfiguration.

The CSRF token cookie now sets `SameSite=Lax` by default ([#2035](https://github.com/wheels-dev/wheels/pull/2035)). The encryption key used for signed cookies is auto-generated and persisted if not supplied during development ([#2054](https://github.com/wheels-dev/wheels/pull/2054)) — but in production a missing CSRF encryption key is a startup error, not a silent downgrade ([#2079](https://github.com/wheels-dev/wheels/pull/2079)). The session ID is rotated on login to close the classic session-fixation path ([#2034](https://github.com/wheels-dev/wheels/pull/2034)). And `redirectTo` refuses to send users to off-site URLs unless they are explicitly allowed, closing the open-redirect pattern that shows up in a lot of auth flows ([#2038](https://github.com/wheels-dev/wheels/pull/2038)).

None of these are new attacks. All of them are the kind of thing that slips through when defaults are permissive.

## CORS and security headers — deny by default

The wildcard CORS origin is a canonical footgun. 4.0 removed it from the defaults. An unconfigured `Cors` middleware denies all cross-origin requests instead of mirroring `Origin` ([#2039](https://github.com/wheels-dev/wheels/pull/2039)). The combination most CSRF guidance calls out specifically — `Access-Control-Allow-Origin: *` with `Access-Control-Allow-Credentials: true` — is now a configuration error, not a running default ([#2053](https://github.com/wheels-dev/wheels/pull/2053)).

```cfm
// Deny-by-default CORS — explicit origins, explicit methods
set(middleware = [
    new wheels.middleware.Cors(
        allowOrigins="https://app.example.com",
        allowMethods="GET,POST",
        allowCredentials=true
    )
]);
```

The companion change was a new `SecurityHeaders` middleware that ships Content-Security-Policy, HTTP Strict Transport Security, and Permissions-Policy defaults that are actually strict ([#2036](https://github.com/wheels-dev/wheels/pull/2036)). HSTS is on by default in production ([#2081](https://github.com/wheels-dev/wheels/pull/2081)), which is a small but important break from the previous "opt in and hope you remembered" model.

## Rate limiter — hardening a hardening feature

The rate limiter is itself a security feature, so the bar for it was higher. The initial implementation landed in [#1931](https://github.com/wheels-dev/wheels/pull/1931), and a run of follow-up PRs closed every class of weakness we could find in it.

The `trustProxy` default flipped to false, so an operator has to opt into trusting `X-Forwarded-For` instead of being spoofed by it ([#2024](https://github.com/wheels-dev/wheels/pull/2024)). The in-memory store got bounded to prevent an attacker from exhausting memory with a firehose of unique keys, and the IP extraction logic was tightened against the same spoofing vector ([#2041](https://github.com/wheels-dev/wheels/pull/2041), [#2048](https://github.com/wheels-dev/wheels/pull/2048)). On lock timeout — the case where the underlying atomic operation cannot acquire its lock — the limiter now fails closed rather than letting the request through ([#2069](https://github.com/wheels-dev/wheels/pull/2069)). Background cleanup got throttled so a busy limiter cannot DoS itself, and key length is capped to close a different memory vector ([#2080](https://github.com/wheels-dev/wheels/pull/2080)). The proxy strategy default is `last` — read only the last hop in the `X-Forwarded-For` chain, which is the only value your own reverse proxy controls ([#2088](https://github.com/wheels-dev/wheels/pull/2088)).

```cfm
// Rate limiter — production-ready defaults
new wheels.middleware.RateLimiter(
    maxRequests=100,
    windowSeconds=60,
    strategy="slidingWindow",
    storage="database",
    trustProxy=true,
    proxyStrategy="last"
)
```

Every one of those changes is the kind of thing you discover by writing the exploit, not by reading the docs. Which is why we wrote the exploits.

## JWT, console, reload — developer surfaces with production consequences

Developer conveniences leak into production. 4.0 treated that assumption as given and tightened the surfaces that matter most.

JWT signatures validate the algorithm header before anything else, closing the `alg: none` family of bugs, and signature comparison is constant-time ([#2079](https://github.com/wheels-dev/wheels/pull/2079), [#2086](https://github.com/wheels-dev/wheels/pull/2086)). The `consoleeval` endpoint is POST-only, handles IPv6 allowlists correctly, and validates its `Content-Type` ([#2059](https://github.com/wheels-dev/wheels/pull/2059)). The `?reload=true` endpoint uses constant-time password comparison, is rate-limited, and requires a hashed password rather than a plain string ([#2077](https://github.com/wheels-dev/wheels/pull/2077), [#2022](https://github.com/wheels-dev/wheels/pull/2022)). The `allowEnvironmentSwitchViaUrl` setting defaults to false in production, and an empty reload password is now a startup error when env switching is possible ([#2076](https://github.com/wheels-dev/wheels/pull/2076), [#2082](https://github.com/wheels-dev/wheels/pull/2082)).

These are the settings that get left on "whatever is easiest" in development and forgotten in production. The defaults now match what you would want the forgotten value to be.

## CLI and MCP — the AI-era attack surface

The new category in 4.0 is "things an AI agent can reach." A Model Context Protocol endpoint accepts tool calls from a model that was, five minutes ago, reading untrusted input. That makes the MCP boundary the same kind of trust boundary as the HTTP boundary — and we treated it that way.

`wheels deploy` sanitizes shell arguments end to end, across every verb that shells out ([#2068](https://github.com/wheels-dev/wheels/pull/2068), [#2073](https://github.com/wheels-dev/wheels/pull/2073)). The database shell helper refuses injection patterns in its arguments ([#2040](https://github.com/wheels-dev/wheels/pull/2040)). The MCP server validates every tool input, blocks path traversal in the docs reader, gates privileged tools behind an auth check, caps error output so it cannot be used as an oracle, validates port values before binding, enforces a structural allowlist for tool names, and uses a CSRNG for session tokens ([#2049](https://github.com/wheels-dev/wheels/pull/2049), [#2062](https://github.com/wheels-dev/wheels/pull/2062), [#2050](https://github.com/wheels-dev/wheels/pull/2050), [#2072](https://github.com/wheels-dev/wheels/pull/2072), [#2075](https://github.com/wheels-dev/wheels/pull/2075), [#2083](https://github.com/wheels-dev/wheels/pull/2083), [#2087](https://github.com/wheels-dev/wheels/pull/2087)).

The frame that guided this work: assume the MCP caller is adversarial, because at some point it will be.

## XSS and view helpers

Output encoding got its own pass. The four helpers that matter — `h()`, `hAttr()`, `stripTags()`, `stripLinks()` — were formalized so that view code has one obvious way to encode for each context ([#2097](https://github.com/wheels-dev/wheels/pull/2097)). The pagination helpers in particular had a history of user-controlled strings reaching the page unencoded: `prependToPage`, `anchorDivider`, and `appendToPage` are all sanitized now, and the HTML-entity bypass that let an attacker smuggle markup through the encoder is closed ([#2042](https://github.com/wheels-dev/wheels/pull/2042), [#2057](https://github.com/wheels-dev/wheels/pull/2057), [#2060](https://github.com/wheels-dev/wheels/pull/2060)). Server-Sent Events responses reject embedded newlines so an attacker-controlled event payload cannot inject additional event frames ([#2051](https://github.com/wheels-dev/wheels/pull/2051)).

```cfm
// SecurityHeaders — strict CSP, HSTS on, locked-down permissions
new wheels.middleware.SecurityHeaders(
    contentSecurityPolicy="default-src 'self'",
    hstsMaxAge=31536000,
    hstsIncludeSubDomains=true,
    permissionsPolicy="geolocation=(), microphone=()"
)
```

## Before and after — the defaults that changed

| Setting | 3.0 default | 4.0 default |
|---|---|---|
| CORS | wildcard `*` | deny-all |
| HSTS in production | off | on |
| CSRF encryption key | optional | required in prod |
| `allowEnvironmentSwitchViaUrl` | true | false in prod |
| Reload password | may be empty | non-empty required in prod for env-switching |
| RateLimiter `trustProxy` | true (dev convenience) | false |
| RateLimiter proxy strategy | n/a | `last` (authoritative) |

Each row is a place where an operator used to have to know to change the default. None of them require action now — the safe value is what you get.

## What Wheels still does not solve

It is worth being direct about the limits. The framework hardened its own primitives. It did not solve the classes of problem that are inherently application-specific ([#2078](https://github.com/wheels-dev/wheels/pull/2078) documents this).

Wheels does not provide authorization. Authentication patterns exist, but "can this user perform this action on this record" is your application's decision. The framework cannot know what your roles mean.

Wheels does not make tenant-isolation decisions for you. Multi-tenancy is documented, and the middleware primitives are there, but deciding which tenant a request belongs to — and enforcing that every query is tenant-scoped — is an application concern. A bug in that logic is an application bug, not a framework bug.

Wheels does not prevent insecure direct object references. `findByKey(params.key)` will happily return any record by primary key. Preventing an authenticated user from fetching another user's record is your authorization layer's job. The framework cannot infer intent from a model call.

These are not oversights. They are the kinds of decisions that only the application understands, and a framework that pretended to solve them would do so by making assumptions that do not hold in most real apps.

## Secure by default is a posture

Across these forty-plus PRs, no single change stands out as dramatic. That is the point. Secure-by-default is a posture, not a feature — it is the accumulation of a lot of small default changes, each one moving the ground state from "works, probably unsafe" to "works, safe unless you explicitly say otherwise."

## Where to go next

- [Full audit § Security hardening](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md) — per-PR receipts for every hardening change in this post, plus the ones that did not fit.
- [Upgrading from Wheels 3.x](https://guides.wheels.dev/v4-0-0-snapshot/upgrading/3x-to-4x/) — detect / fix / opt-out guidance for each of the seven breaking defaults.
- [Security documentation](https://guides.wheels.dev/v4-0-0-snapshot/deployment/security-hardening/) — the user-facing reference for middleware, headers, and session hardening.
- [SECURITY.md](https://github.com/wheels-dev/wheels/blob/develop/SECURITY.md) — responsible-disclosure process. That channel is read.

The framework cannot make your application secure. It can refuse to make it easy to be insecure. That is what 4.0 does.

