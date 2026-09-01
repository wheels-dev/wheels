---
title: 'The Wheels 4.1 security hardening pass'
slug: the-wheels-4-1-security-hardening-pass
publishedAt: '2026-09-08T14:00:00.000Z'
updatedAt: null
author: Peter Amiri
tags:
  - wheels-4
  - security
categories:
  - Releases
excerpt: >-
  4.1 shipped a release-cycle hardening pass across the framework: fail-closed
  auth and policies, controller retargeting protection, mass-assignment
  opt-in, zip-slip and path-escape fixes, view-helper encoding, and storage
  key validation. Here's what changed, area by area, and what (if anything)
  you need to do about it.
coverImage: null
---

Alongside the feature work, 4.1 ran a systematic hardening pass over the framework's trust boundaries. The theme across all of it: **fail closed**. Where 4.0 sometimes guessed, 4.1 refuses — loudly, and with a typed error you can catch.

Here's the tour, area by area.

## Authentication and authorization

- **Session rotation.** `SessionStrategy.login()` and `logout()` rotate or invalidate the session ID, and rotation failures are no longer swallowed by a catch-all.
- **JWTs require expiry by default.** `JwtService.decode()` now demands an `exp` claim unless you explicitly pass `requireExpiry=false`. A signed token with no expiry was a token with no revocation story.
- **Policies require true.** `authorize()`/`can()` grant only when a policy method returns boolean `true` — the CFML strings `"yes"` and `"true"` no longer authorize. Unknown actions throw `Wheels.Policy.UnknownAction` instead of treating a typo as a deny (a typo that denies is a bug that hides).
- **`authenticateWith()` fails closed** when the restriction list names a strategy that doesn't exist, instead of silently skipping the typo.
- **Empty policy scopes return a no-rows chain** rather than calling `whereIn("id", [])` — which, per the anti-pattern we've burned on before, was a SQL syntax error waiting for an empty collection.

## Controllers and requests

- **Controller/action retargeting is gone.** Query strings, form fields, or JSON bodies can no longer retarget the routed `controller`/`action` — `$ensureControllerAndAction` pins them. Wildcard path names are unchanged.
- **`form._method` is honored only on POST**, and only for `PUT`/`PATCH`/`DELETE` — GET can't become a state-changing verb.
- **Before filters that return `false` now halt** the action and remaining filters (redirects and renders still halt as before). The authz fail-closed signal actually fails closed.
- **Client-supplied rewrite headers** (`X-Rewrite-URL`, `X-Original-URL`) are ignored unless you opt in with `set(trustProxyHeaders=true)`.
- **`$wildcardDomainMatch` compares every host label**, so `https://*.example.com` no longer matches `https://evil.com`.

## Models and mass assignment

- **Strict mode.** `set(massAssignmentStrict=true)` fail-closes `create`/`update`/`save` for models with neither `accessibleProperties()` nor `protectedProperties()`. The default remains open for compatibility — flip it on new apps and never look back.
- **`create()` no longer leaks properties onto the shared class model** before instantiating the record, and nested `hasMany` keys no longer use a `GetTickCount` window to decide "new" vs existing (form identities use a `new-` prefix).
- **Uniqueness scopes now exclude soft-deleted rows by default** (`includeSoftDeletes=false`), so a soft-deleted value can be reused.

## Plugins and packages

- **Zip-slip is fixed.** Plugin zip extraction rejects absolute paths, `..` segments, and canonical escapes before writing a single file.
- **Package manifests with empty `wheelsVersion` are rejected**; invalid `plugin.json` skips the plugin instead of half-loading it.
- **Admin pages no longer `cfinclude` on-disk `index.cfm` files** from packages, and homepage links are `EncodeForHTML`-encoded http(s)-only.
- **PackageLoader refuses dotted/traversed directory names** and mappings whose realpath lands outside the package — including symlink escapes.

## Views and output

- **Breakout attribute names are rejected** in view helpers, `errorElement`/`wrapperElement` are restricted to safe tags, and `encode` is honored on date option bodies and `csrfMetaTags`.
- **`linkTo(sanitizeHref=true)` blanks `javascript:`/`data:` hrefs** (opt-in; the default stays `false`).
- **Pagination and asset helpers encode interpolated paths**, collapse `..` on local sources, and stop double-encoding pagination params.

## Middleware and storage

- **`Pipeline.getMiddleware()` returns a copy** — callers can't mutate the live stack.
- **RateLimiter honors `trustProxy`** before a client-supplied `remoteAddr`.
- **Circular middleware dependencies throw** `Wheels.Middleware.CircularDependency` instead of silently falling back to priority ordering.
- **LocalDisk refuses empty and slash-only keys** so `put()` can't write the disk root, and S3 `put()` sends a signed `x-amz-acl` so visibility settings are actually enforced.

## What you need to do

For most apps: **nothing**. The changes are either opt-in (strict mass assignment, `sanitizeHref`, `genericErrors`) or bug fixes that make existing defaults behave the way they were always documented to. The two things worth a look on an upgrade:

1. Grep for `whereIn`/`whereNotIn` with possibly-empty arrays and for `form._method` usage — both now behave more strictly.
2. If you wrote policy methods returning `"yes"` strings, they deny now. That's the point.

The full list is in the 4.1.0 changelog. Security releases shouldn't be exciting; this one's excitement is that the checks you always assumed existed now actually exist.
