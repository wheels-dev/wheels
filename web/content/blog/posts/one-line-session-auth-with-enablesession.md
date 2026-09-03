---
title: 'One-line session auth, and the three bugs you won''t find the hard way'
slug: one-line-session-auth-with-enablesession
publishedAt: '2026-09-03T14:00:00.000Z'
updatedAt: null
author: Peter Amiri
tags:
  - wheels-4
  - authentication
  - dependency-injection
categories:
  - Releases
excerpt: >-
  The enableSession() facade is one line of config. But the real story is the
  three subtle bugs it exists to prevent — the ones that only surface after
  the second deploy, or only on a reload, or only for a user who was already
  logged in. Here's what happens when the wiring goes right.
coverImage: '/blog-images/4-1/one-line-session-auth-with-enablesession.png'
announcement:
  title: 'Session auth, one line'
  body: |
    New post: **[Session auth in one line](https://blog.wheels.dev/blog/one-line-session-auth-with-enablesession)** — `enableSession()` in `config/services.cfm` wires the whole session-auth subsystem.
---

The invitation email was two sentences. *We need login on the admin panel by Thursday. You can use the auth layer, right?* Sure. You can. The auth layer has everything: an `Authenticator`, named strategies, a `SessionStrategy`, `authenticateWith`. You've never wired it by hand, but how hard can fifteen lines be?

Three times harder than you think, it turns out — and each bug is a different kind of invisible.

## Bug one: the strategy that isn't there

You write the wiring the way the docs show it. An authenticator singleton, a session strategy singleton, then you add the `session` strategy to the authenticator's list so `authenticateWith("session", ...)` knows what to call.

```cfm
di.map("authenticator").to("app.services.Authenticator").asSingleton();
di.map("sessionStrategy").to("wheels.auth.SessionStrategy").asSingleton();
di.getInstance("authenticator").addStrategy("session", di.getInstance("sessionStrategy"));
```

It works on your machine. It works in review. Then Thursday arrives and the first login throws: `authenticateWith` can't find the `session` strategy. Because this code runs in `config/services.cfm`, and the order in which services and the authenticator initialize isn't guaranteed the way it looks. The strategy list was populated *before* the authenticator was ready, or the authenticator wasn't the same instance the controller got.

That's the bug. It's not a syntax error; it's an ordering problem dressed up as a runtime failure. The fix is trivially boring: register the strategy as part of the same operation that maps the authenticator, so they can't disagree.

## Bug two: the duplicate

You fix the ordering. It works. Then someone reloads the app — a `?reload=true` during a deploy, nothing unusual — and suddenly there are *two* `session` strategies in the list. `authenticateWith` still works, but now it's ambiguous, and a couple of weeks later you're tracing why a session gets two cookies and nobody's quite sure which one wins.

Config files re-execute on reload. Any wiring that appends to a list has to be idempotent, or your second deploy quietly breaks your first.

## Bug three: the authenticated user who isn't

Now the embarrassing one. Login works, the session strategy stores the user key, everything's green. Then a user who logged in *before* your change hits a page and gets bounced to login. Because the strategy checks — through the DI container — for a `currentUser` binding, and you'd mapped `authenticator` to a subclass, and in doing so the container re-resolved `currentUser` against the *new* authenticator instead of the one the session data belongs to.

The lesson all three bugs share: **session auth isn't fifteen lines, it's fifteen lines of stateful ordering.** Getting the wiring right by hand means knowing every one of those interactions and never touching them again.

## The one line

Wheels 4.1 turns it into what it should have been:

```cfm
injector().enableSession(sessionKey = "wheels.auth");
```

`enableSession()` does the three things those bugs were about, atomically:

1. Maps the `authenticator` and `sessionStrategy` **singletons**, so every `getInstance("authenticator")` is the same object.
2. Registers the `session` strategy **idempotently** — call it twice, on a reload, in a loop, you still end up with one.
3. Returns the `SessionStrategy` so you can hold a reference if you need it.

None of the three bugs can happen again, because none of them are "configuration" anymore — they're one call that can't be reordered, can't be duplicated, and can't be split across two objects that disagree.

## What it composes with

The facade doesn't assume it owns your container:

- **A pre-mapped authenticator is respected.** If you (or a package) already mapped `authenticator` to a subclass, `enableSession()` adds the session strategy to *that* instance instead of replacing it.
- **A custom `currentUser` resolver still works.** The strategy asks the container for `currentUser`; the facade doesn't take that over. Bind `currentUser` to a closure that looks up your `User` model, and both the strategy and your policies use it.
- **Missing container? You're told.** No DI container registered throws `Wheels.Injector` up front, instead of half-wiring a session that dies on the first request.

The signature is small and optional-all-the-way-down:

```cfm
enableSession(
    sessionKey = "wheels.auth",  // default
    onLogin = "",                // optional event
    onLogout = ""                // optional event
);
```

## When to skip the one line

If you ran `wheels generate auth` back in 4.0.6, you already have the wiring — generated, explicit, owned code, and it's correctly registered. Keep it.

But if you're hand-rolling auth, or you've been carrying the fifteen lines that "used to work," the facade is the middle ground that didn't exist before: the full auth layer, one line, with the ordering, idempotency, and identity bugs structurally impossible.

Next up in the series: read the next post — pretty URLs with bindBy, and the unshareable link. (See the [series index](https://blog.wheels.dev/posts/wheels-4-1-coming/).)
