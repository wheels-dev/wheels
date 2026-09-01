---
title: 'One-line session authentication with enableSession()'
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
  Wheels 4.1's enableSession() facade condenses session authentication setup
  into one line of config: the authenticator and session strategy singletons
  get registered, the session strategy is wired into the authenticator, and
  it all composes cleanly with a pre-existing container. Here's what it does
  and how it fits with wheels generate auth.
coverImage: null
---

Wheels 4.0 introduced the `wheels.auth` primitives — an `Authenticator` that composes named strategies, a `SessionStrategy` that stores a user key in the session, and `authenticateWith()` to route logins through them. What it didn't have was a short path from "new app" to "sessions work."

4.1 adds it. In `config/services.cfm`:

```cfm
injector().enableSession(sessionKey = "wheels.auth");
```

That's the entire setup. One line.

## What the line does

`enableSession()` is a facade over three pieces of container wiring that you'd otherwise write by hand (and get subtly wrong):

1. **Maps the singletons** — `authenticator` and `sessionStrategy` are registered as container singletons, so every `injector().getInstance("authenticator")` in your app is the same object.
2. **Registers the session strategy** — the `session` strategy is added to the authenticator's strategy list, so `authenticateWith("session", ...)` works without any further configuration.
3. **Returns the strategy** — the call returns the `SessionStrategy` instance, in case you want to hold a reference for further configuration.

It's also **idempotent**. Call it twice — or call it in code that runs during a reload cycle — and you still end up with one `session` strategy, not two. That matters more than it sounds: config files re-execute on reloads, and duplicate strategy registration is exactly the kind of bug that only shows up after the second deploy.

## What it composes with

The facade deliberately doesn't assume it's the only thing in your container:

- **A pre-mapped authenticator is respected.** If your `config/services.cfm` (or a package) already mapped `authenticator` to a subclass, `enableSession()` adds the session strategy to *that* instance instead of replacing it.
- **A custom `currentUser` resolver still works.** The strategy asks the DI container for `currentUser`; `enableSession()` doesn't take that over. Bind `currentUser` to a closure that looks up your `User` model and both the strategy and your policies use it.
- **Missing container? You get told.** Calling `enableSession()` with no DI container registered throws a `Wheels.Injector` error rather than half-wiring a session that would fail on the first request.

The signature is small and all-optional:

```cfm
enableSession(
    sessionKey = "wheels.auth",  // default
    onLogin = "",                // optional event/callback
    onLogout = ""                // optional event/callback
);
```

## How it fits with `wheels generate auth`

If you ran `wheels generate auth` in 4.0.6, you already have controllers, views, a `User` model, and a services block — the generator wires session auth up through the same primitives this facade now collapses. For 4.1 apps, the story is simpler:

- **Scaffolded auth:** keep the generated wiring. It is explicit, owned code, and the generator already added the strategy registration for you.
- **Hand-rolled auth:** start from `enableSession()` and add only what you need — a login controller action calling `authenticateWith("session", user)`, a logout calling `deauthenticate()`, and a `currentUser` binding.

And if you'd rather not write the one line at all, `wheels generate auth` remains the full-featured path. The facade is the middle ground that didn't exist before 4.1: the full power of the auth layer, one line of config.

The complete auth surface — strategies, tokens, JWTs, policies — is covered in the [authentication strategies](https://blog.wheels.dev/posts/authentication-strategies-wheels-4/) post from the 4.0 series, which is still the best tour of the architecture this facade sits on top of.
