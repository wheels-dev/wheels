---
title: 'Fail closed, everywhere: the hardening pass and the assumptions that weren''t true'
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
  A security review of Wheels 4.0 found a pile of "surely that's safe" that
  weren't: a policy that treated the string "yes" as true, a form method
  override that worked on a GET, a zip that could escape its directory. 4.1
  closes them by failing closed. Here's the story area by area, and what you
  have to check on the way up.
coverImage: '/blog-images/4-1/the-wheels-4-1-security-hardening-pass.png'
announcement:
  title: 'The 4.1 security hardening pass'
  body: |
    New post: **[Fail closed, everywhere](https://blog.wheels.dev/blog/the-wheels-4-1-security-hardening-pass)** — the hardening pass that makes Wheels fail closed by default.
---

Every framework has a layer of things you assume are safe because *surely* nobody would write it that way. A policy that returns `"yes"` authorizes. A `_method` field that works on a GET. A plugin zip that unzips wherever it wants. A route that trusts a header the client set.

You assume those are safe. Then you review the code.

The 4.1 hardening pass was the release where we stopped assuming and started reading. The theme across every fix: **fail closed.** Where 4.0 sometimes guessed at what you meant, 4.1 refuses — loudly, with a typed error you can catch.

## The ones that will bite you first

**A policy that authorized on `"yes"`.** Policies return a boolean; authorize only when `true`. Except CFML is loose, and a policy method that returned the string `"yes"` — which CFML cheerfully coerces — happily authorized. Now `authorize()`/`can()` grant only on a literal boolean `true`. The strings `"yes"` and `"true"` deny. If you have a policy returning strings, it denies now. That's the point.

**A method override that worked on a GET.** `form._method` is a nice Rails-ism. It's also a footgun: if it's honored on a GET, then a prefetched link can become a DELETE. 4.1 honors `form._method` only on POST, and only for `PUT`/`PATCH`/`DELETE`. GET can't become state-changing, POST can't become CSRF-safe.

**A route you could retarget with a query string.** The routed `controller`/`action` used to be overridable by query parameters, form fields, or a JSON body. An attacker could make one URL dispatch somewhere unexpected. 4.1 pins them — `$ensureControllerAndAction` — so only the path defines what runs. Wildcard path names are unchanged.

**A wildcard that matched too much.** `https://*.example.com` didn't just match subdomains; it matched `https://evil.com`. Host-label comparison now checks every label.

## The ones that were quietly dangerous

**Mass assignment.** `create()`/`update()`/`save()` would happily assign whatever came in `params`, and if a model had neither `accessibleProperties()` nor `protectedProperties()`, there was nothing to stop a crafted `params.isAdmin=true`. New apps can opt into `set(massAssignmentStrict=true)`, which fail-closes those models. Default stays open for compatibility — but flip it.

**`create()` leaking onto the class.** Creating a record used to assign properties onto the *shared class model* before instantiating the record. Fixing that uncovered a cousin: `hasChanged()` now treats a deleted persisted property as a change, and nested `hasMany` keys no longer use a `GetTickCount` window to guess "new" vs existing.

**Plugin zips that escaped.** Zip extraction didn't reject `..` segments or absolute paths. `wheels destroy view` didn't reject `../x`. Both are closed — extraction refuses zip-slip before writing, and `destroy view` stays under `app/views/`.

**View helpers that let attributes break out.** Breakout attribute names are rejected, `errorElement`/`wrapperElement` are restricted to safe tags, and `linkTo(sanitizeHref=true)` blanks `javascript:`/`data:` hrefs (opt-in, default unchanged).

## The ones a red-team would find

- **Policy scopes** that returned `whereIn("id", [])` on empty — SQL syntax error waiting for a collection. Now fail-closed with a no-rows chain.
- **`authenticateWith()`** that silently skipped a typo'd strategy name. Now fails closed. `JwtService.decode()` requires an `exp` claim by default; `SessionStrategy.login()`/`logout()` rotate the session ID.
- **Middleware that mutated the live stack.** `Pipeline.getMiddleware()` and the package/plugin getters return copies now. `RateLimiter` honors `trustProxy` before a client-supplied `remoteAddr`. Circular middleware dependencies throw instead of silently reordering.
- **Storage keys.** LocalDisk refuses empty and slash-only keys — `put()` can't write the disk root — and S3 `put()` sends a signed `x-amz-acl` so visibility is honored.

## What you actually have to do

For most apps: **nothing.** The changes are opt-in (strict mass assignment, `sanitizeHref`, `genericErrors`) or bug fixes that make existing defaults behave as documented. The two worth a look on upgrade:

1. **Grep for policy methods returning strings.** They deny now.
2. **Grep for `form._method` usage and possibly-empty `whereIn` arrays.** Both behave more strictly.

The full list is in the [4.1.0 changelog](https://github.com/wheels-dev/wheels/blob/main/CHANGELOG.md). Security releases aren't supposed to be exciting. This one's excitement is that the checks you always assumed existed now actually exist — and that "fail closed" stopped being a slogan and became the default.

Next up: read the next post — finding your riskiest code, and the 900-line controller. (See the [series index](https://blog.wheels.dev/posts/wheels-4-1-coming/).)
