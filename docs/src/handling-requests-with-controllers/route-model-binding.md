# Route Model Binding

Route model binding automatically resolves model instances from route `key` parameters during dispatch, before your controller action runs. Instead of manually looking up records in every action, Wheels does it for you.

## The Problem

Without route model binding, every controller action that works with a specific record starts with the same boilerplate:

```cfm
// app/controllers/Users.cfc
function show() {
    user = model("User").findByKey(params.key);
    if (IsBoolean(user) && !user) {
        redirectTo(route="users");
    }
}

function edit() {
    user = model("User").findByKey(params.key);
    if (IsBoolean(user) && !user) {
        redirectTo(route="users");
    }
}
```

## The Solution

With route model binding enabled, the resolved model instance is automatically available in `params`:

```cfm
// config/routes.cfm
mapper()
    .resources(name="users", binding=true)
.end();

// app/controllers/Users.cfc
function show() {
    // params.user is already a User model instance!
    // If the record doesn't exist, a 404 is automatically returned.
    user = params.user;
}
```

## Enabling Route Model Binding

### Per-Route (Recommended)

Add `binding=true` to individual resource declarations:

```cfm
// config/routes.cfm
mapper()
    .resources(name="users", binding=true)
    .resources(name="posts", binding=true)
    .resources("comments")  // no binding on this resource
.end();
```

### Globally

Enable for all resource routes at once:

```cfm
// config/settings.cfm
set(routeModelBinding=true);
```

Per-route `binding=false` can override the global setting:

```cfm
set(routeModelBinding=true);

// In routes.cfm — comments won't have binding even though global is on
mapper()
    .resources("users")                         // binding enabled (global)
    .resources(name="comments", binding=false)   // binding disabled (per-route)
.end();
```

## How It Works

1. **Convention:** The controller name is singularized and capitalized to derive the model name. `posts` controller → `Post` model.
2. **Lookup:** `model("Post").findByKey(params.key)` is called automatically.
3. **Storage:** The resolved instance is stored in `params` under the singular name: `params.post`.
4. **404 Handling:** If no record is found, Wheels throws `Wheels.RecordNotFound` which renders a 404 page.
5. **No key, no binding:** Actions without a `key` parameter (like `index` and `create`) are unaffected.

## Explicit Model Name

If your controller name doesn't match your model name, specify the model explicitly:

```cfm
// "writers" controller, but the model is "Author"
mapper()
    .resources(name="writers", binding="Author")
.end();

// In the controller, the resolved model uses the model name:
// params.author (not params.writer)
```

## Scoped Binding

Binding inherits through route scopes, so you can enable it for an entire API namespace:

```cfm
mapper()
    .scope(path="/api", binding=true)
        .resources("users")    // binding enabled
        .resources("posts")    // binding enabled
    .end()
.end();
```

## Error Handling

When a record is not found, Wheels throws a `Wheels.RecordNotFound` error. In development mode, you'll see a detailed error page. In production, this renders your 404 page.

If binding is enabled on a route whose controller doesn't correspond to a model (e.g., a `settings` controller with no `Setting` model), binding is silently skipped — no error is thrown.

## What's in params?

| Scenario | `params.key` | `params.<model>` |
|----------|-------------|------------------|
| Binding enabled, record found | `"42"` (preserved) | Model instance |
| Binding enabled, no key param | N/A | Not set |
| Binding disabled | `"42"` (preserved) | Not set |
| No matching model class | `"42"` (preserved) | Not set |

## Limitations

- **Single resource only:** Nested parent resources are not automatically resolved. `/users/5/posts/3` resolves `Post` from `params.key` but does not resolve `User` from `params.userKey`.
- **Primary key only:** Binding uses `findByKey()`. Slug-based or custom lookups should use a before filter.
- **Soft deletes:** Uses default `findByKey()` behavior, which excludes soft-deleted records.
