# Routing Quick Reference

Part of the Wheels application guide; start with `../CLAUDE.md`.

```cfm
mapper()
    .resources("users")
    .resources(name="products", except="delete")
    .resources(name="posts", callback=function(map) {
        map.resources("comments");
    })
    .get(name="login", to="sessions##new")
    .post(name="authenticate", to="sessions##create")
    .root(to="home##index", method="get")
    .wildcard()                                       // keep last!
.end();
```

Helpers: `linkTo(route="user", key=user.id)`, `urlFor(route="users")`, `redirectTo(route="user", key=user.id)`, `startFormTag(route="user", method="put", key=user.id)`.

`params.controller` / `params.action` come from the matched route. Query string, form, and JSON body cannot retarget them. Wildcard `[controller]` / `[action]` still take those names from the path. `form._method` is honored only on POST and only for `PUT` / `PATCH` / `DELETE`. A before filter that returns `false` skips the action (same as `redirectTo()` / `renderText()`). Filter `type` is case-insensitive. `caches(appendToKey=)` throws `Wheels.KeyNotFound` if a listed path is missing. `X-Rewrite-URL` / `X-Original-URL` follow `set(trustProxyHeaders=true)` like `X-Forwarded-*`.

## Route Model Binding

Resolves `params.key` into a model instance before the action runs. Lands in `params.<singularModelName>`. Throws `Wheels.RecordNotFound` (404) if missing; silently skips if the model class doesn't exist.

```cfm
.resources(name="users", binding=true)                // params.user
.resources(name="posts", binding="BlogPost")          // params.blogPost
.resources(name="posts", binding=true, bindBy="slug") // params.post via findOneBySlug(value=key)
.scope(path="/api", binding=true, callback=function(map) {  // all nested resources bound
    map.resources("users");
})
set(routeModelBinding=true);                          // global, in config/settings.cfm
```

`bindBy="slug"` resolves the `:key` segment through the parameterized dynamic finder (`findOneBySlug(value=key)`) instead of `findByKey()`, so URLs can carry slugs or usernames rather than primary keys. It's ignored unless binding is enabled.
