---
title: 'Dependency-injection factories with Injector.toFactory()'
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
  Wheels 4.1's toFactory() binds a name to a closure that builds the
  instance — and the closure receives the container itself, so factories can
  resolve collaborators. Singletons and request-scoped bindings cache the
  result; transient bindings re-run the factory on every resolve. Here's
  when a factory beats a to() binding.
coverImage: null
---

Most DI bindings in Wheels are static: `map("mailer").to("app.services.Mailer")` means "construct this component." 4.1 adds the second shape:

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

The factory is a closure — it receives **the container** as its argument, and its return value is what `getInstance("storageClient")` resolves to.

## What `to()` can't express

`to("component.path")` answers one question: *which component?* Factories answer *how?* Three situations where the difference matters:

**Conditional construction.** The example above — pick an implementation based on config at resolve time. With `to()` you'd construct both clients and pick at the call site, leaking that decision into every consumer. With a factory, consumers ask for `storageClient` and stay ignorant of the branch.

**Non-component return values.** `to()` always constructs a CFC. A factory can return anything — a Java object, a plain struct of config, a test double. If your binding isn't a component, it's a factory.

**Expensive or racy setup.** Construction that should happen once, under the container's singleton lock, rather than lazily inside whoever happens to resolve it first.

## Lifecycle flags still apply

The factory is a *source of instances*, not a lifecycle. The usual flags do what you'd expect:

```cfm
// built once, under a double-checked lock, cached forever
.map("appConfig").toFactory(function(ctx) { return ctx.getInstance("settings").appConfig; }).asSingleton()

// built once per request, cached in request scope
.map("requestScopedClient").toFactory(function(ctx) { return new api.Client(token = request.headers.apiToken); }).asRequestScoped()

// default: the factory runs on every resolve
.map("freshQuery").toFactory(function(ctx) { return new query.Builder(); })
```

And because the factory receives the container, nested resolution is natural: `ctx.getInstance("settings")` inside a factory is the same call your controllers make.

## Gotchas worth internalizing

- **`toFactory()` requires a preceding `map()`.** Just like `to()`, it throws `Wheels.Injector` without one.
- **The argument must be a closure or function reference.** Passing a string or a component is rejected loudly.
- **`toFactory()` after `to()` replaces the path binding.** You can rebind a name from component to factory and back; rebinding also resets singleton/request-scoped flags and drops the request-scope cache entry, so stale cached instances don't survive a rebind.
- **Circulars are guarded.** The container tracks the in-flight resolving stack per request, so a factory that (directly or indirectly) resolves the name it's building gets a clear circular-dependency error rather than a stack overflow.

## What changed under the hood

Factories live in their own registry, checked before path resolution in `getInstance()`. That ordering is what makes the lifecycle flags work: singleton factories are cached by mapping name under a named lock, request-scoped factories land in the request DI cache, and transient factories run every time. The new `hasExplicitMapping()` on the injector rounds out the surface — it's how other framework code (notably the model-construction fast path from the [performance work](https://blog.wheels.dev/posts/how-we-made-model-instantiation-2-5x-faster/)) knows to fall back to the full container path when a name is explicitly mapped.

The complete container surface — `map`, `to`, scopes, rebinding semantics — is documented in the guides under dependency injection, and the 4.0 series' [authentication post](https://blog.wheels.dev/posts/authentication-strategies-wheels-4/) shows `bind()`-style service wiring in a real app context.
