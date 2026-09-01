---
title: 'DI factories with toFactory: the service that couldn''t decide'
slug: dependency-injection-factories-with-tofactory
publishedAt: '2026-09-05T14:00:00.000Z'
updatedAt: null
author: Peter Amiri
tags:
  - wheels-4
  - dependency-injection
categories:
  - Releases
excerpt: >-
  A storage service had to pick S3 in production and the local disk in dev.
  The to() binding couldn't express that, so the decision leaked into every
  caller. toFactory() gives a DI container a *how* — and it's the difference
  between one closed arrow and ten open switch statements.
coverImage: '/blog-images/4-1/dependency-injection-factories-with-tofactory.png'
announcement:
  title: 'DI factories with toFactory()'
  body: |
    New post: **[Factories for your container](https://blog.wheels.dev/blog/dependency-injection-factories-with-tofactory)** — `Injector.toFactory()` binds a name to a closure that builds the instance.
---

The routing was fine. The uploads were fine. Then the app went to production and every picture was gone, because locally they landed on a disk and in production they were supposed to land in S3 — and the storage service had a `useS3` flag that each of the ten call sites checked in its own way.

Ten call sites. Ten slightly different spellings of `if (settings.useS3)`. One of them was inverted. The bug report said "in some places uploads work, in others they 500," which is the most fun kind of bug to get at nine on a Friday.

The root cause wasn't the service. It was the **container**. `bind("storageClient").to("app.services.StorageClient")` can only answer *which component* — it can't express *how that component gets built*. And when "how" depends on configuration, the decision stops being the container's and becomes every caller's.

## The factory shape

Wheels 4.1 adds the second way to bind:

```cfm
injector()
    .map("storageClient")
    .toFactory(function(ctx) {
        var settings = ctx.getInstance("settings");
        return settings.useS3
            ? new storage.S3Client(bucket = settings.s3Bucket)
            : new storage.LocalClient(root = settings.uploadsPath);
    });
```

The factory is a closure. It receives **the container** as its argument — so it can resolve collaborators — and its return value is what `getInstance("storageClient")` resolves to.

Now the decision lives in exactly one place, next to the configuration it depends on. Callers ask for `storageClient` and stay ignorant of the branch. The inverted check can still exist, but it can only exist *once*, and it's reviewable in a ten-line closure instead of buried in a controller.

## When a factory beats to()

`to("component.path")` answers "which component?" Factories answer "how?" Three situations where that distinction is the whole story:

**Conditional construction** — the example above. Pick an implementation at resolve time based on config.

**Non-component return values.** `to()` always constructs a CFC. A factory can return anything — a Java object, a plain struct of config, a test double. If your binding isn't a component, it's a factory.

**Expensive or racy setup.** Construction that should happen once, under the container's singleton lock, rather than lazily inside whoever happens to resolve it first.

## Lifecycle flags still apply

A factory is a *source of instances*, not a lifecycle. The usual flags do the obvious thing:

```cfm
// built once, under a double-checked lock, cached forever
.map("appConfig").toFactory(function(ctx) { return ctx.getInstance("settings").appConfig; }).asSingleton()

// built once per request, cached in request scope
.map("requestScopedClient").toFactory(function(ctx) { return new api.Client(token = request.headers.apiToken); }).asRequestScoped()

// default: the factory runs on every resolve
.map("freshQuery").toFactory(function(ctx) { return new query.Builder(); })
```

And because the factory gets the container, nested resolution is natural: `ctx.getInstance("settings")` inside a factory is the same call your controllers make. No special-casing, no globals.

## The sharp edges worth knowing

Factories are powerful, which means they have corners:

- **`toFactory()` needs a preceding `map()`.** Just like `to()`, it throws `Wheels.Injector` without one.
- **The argument must be a closure or function reference.** A string or a component is rejected loudly.
- **`toFactory()` after `to()` replaces the path binding**, and rebinding resets singleton/request-scoped flags and drops the request-scope cache — so a stale cached instance from the old binding doesn't survive a rebind.
- **Circulars are guarded.** The container tracks the in-flight resolving stack per request, so a factory that (directly or indirectly) resolves the name it's building gets a clear circular-dependency error instead of a stack overflow.

## The payoff

The storage service shipped with one factory, and the ten `if (settings.useS3)` sprinkled through the codebase became one closure. When the team later added a third backend, the change was a single lambda.

The broader point: a DI container is only doing its job if the *caller* doesn't know how the thing gets built. `to()` handles the static case; `toFactory()` handles the dynamic one. Between them, there's no longer a reason for construction logic to leak into your controllers — which is where it goes to die, and where it takes its bugs with it.

There's a connection to the work in the next post: the same container this factory lives in is what the model layer now bypasses on its hot path, and `hasExplicitMapping()` is how it knows when to back off. The [whole performance story](https://blog.wheels.dev/posts/wheels-4-1-coming/) is next in the series — it starts with a bug report we initially didn't believe.
