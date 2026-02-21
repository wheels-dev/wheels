# Resource Routing

## Description
RESTful resource routing automatically creates conventional routes for CRUD operations on models.

## Key Points
- Use `resources("name")` for full CRUD routes (7 routes: index, show, new, create, edit, update, delete)
- Use `resource("name")` for singular resources without a key (6 routes: show, new, create, edit, update, delete)
- Supports nested resources via `callback` parameter or `nested=true`
- Follows REST conventions for HTTP verbs
- Restrict actions with `only` or `except` options

## Code Sample
```cfm
// Plural resource - creates 7 routes
mapper()
    .resources("products")
.end();

// Generates these routes:
// GET    /products              → products.index
// GET    /products/[key]        → products.show
// GET    /products/new          → products.new
// POST   /products              → products.create
// GET    /products/[key]/edit   → products.edit
// PATCH  /products/[key]        → products.update
// DELETE /products/[key]        → products.delete

// Singular resource - creates 6 routes (no index, no key in URL)
mapper()
    .resource("cart")
.end();
```

## Nested Resources

Nest child resources within a parent to generate URL patterns like `/posts/[postKey]/comments/[key]`.

### Callback Syntax (Recommended)
```cfm
mapper()
    .resources(name="posts", callback=function(map) {
        map.resources("comments");
        map.resources("tags");
    })
.end();
```

This generates parent routes for `posts` AND nested routes for `comments` and `tags`:
- `GET /posts/[postKey]/comments` → comments.index
- `POST /posts/[postKey]/comments` → comments.create
- `GET /posts/[postKey]/comments/[key]` → comments.show
- `GET /posts/[postKey]/comments/[key]/edit` → comments.edit
- `PATCH /posts/[postKey]/comments/[key]` → comments.update
- `DELETE /posts/[postKey]/comments/[key]` → comments.delete

Named routes are prefixed with the parent name: `postComments`, `postComment`, `editPostComment`, etc.

### Manual Nested Syntax
```cfm
mapper()
    .resources(name="posts", nested=true)
        .resources("comments")
    .end()
.end();
```

### Multiple Levels of Nesting
```cfm
mapper()
    .resources(name="posts", callback=function(map) {
        map.resources(name="comments", callback=function(map2) {
            map2.resources("replies");
        });
    })
.end();
```

Keep nesting shallow (2 levels max recommended) for cleaner URLs.

### Nested with Options
```cfm
mapper()
    .resources(name="users", callback=function(map) {
        // Only index and create for nested orders
        map.resources(name="orders", only="index,create");
        // Singular nested resource
        map.resource("profile");
    })
.end();
```

### Nesting with Namespaces
```cfm
mapper()
    .namespace(name="api")
        .resources(name="posts", callback=function(map) {
            map.resources("comments");
        })
    .end()
.end();
// Generates: /api/posts/[postKey]/comments/[key]
```

## Restricting Routes
```cfm
// Only specific actions
.resources(name="products", only="index,show")

// Exclude specific actions
.resources(name="products", except="delete")
```

## Usage
1. Add `resources("modelName")` in routes.cfm
2. Create corresponding controller with standard actions
3. Use generated route names in links: `linkTo(route="product", key=1)`
4. For nested resources, include the parent key: `linkTo(route="postComment", postKey=post.id, key=comment.id)`

## Related
- [Routing Basics](./basics.md)
- [HTTP Methods](./http-methods.md)
- [MVC Controllers](../mvc-architecture/controllers.md)
- [CRUD Patterns](../../patterns/crud.md)

## Root Route Configuration
```cfm
mapper()
    .resources("posts")
    .root(to="posts##index", method="get")
.end();
```

The root route should come after resource definitions and before the wildcard route.

## Important Notes
- Resources are the primary convention in Wheels
- Controller names are always plural even for singular resources
- Both PUT and PATCH map to the update action
- The parent resource key uses the pattern `[singularNameKey]` (e.g., `postKey`, `userKey`)
- Callback syntax automatically calls `end()` — no need to close manually
