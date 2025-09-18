# Routing Basics

## Description
Wheels routing system matches HTTP requests to controller actions based on URL patterns and HTTP verbs.

## Key Points
- Routes defined in `/config/routes.cfm`
- Matches HTTP verb + URL pattern to controller/action
- Uses `mapper()...end()` chain syntax
- First matching route wins
- Route names used for link generation

## Code Sample
```cfm
// /config/routes.cfm
mapper()
    .get(name="product", pattern="products/[key]", to="products##show")
    .post(name="products", pattern="products", to="products##create")
    .patch(name="product", pattern="products/[key]", to="products##update")
    .delete(name="product", pattern="products/[key]", to="products##delete")
.end();

// Usage in views/controllers
#linkTo(route="product", key=5, text="View Product")# // /products/5
#startFormTag(route="products", method="post")#       // /products
```

## Usage
1. Configure routes in `/config/routes.cfm`
2. Use HTTP verb methods: `get()`, `post()`, `patch()`, `delete()`
3. Define patterns with `[parameters]` for dynamic segments
4. Map to controller using `to="controller##action"`
5. Reference by name in links and forms

## Related
- [Resources](./resources.md)
- [Patterns](./patterns.md)
- [HTTP Methods](./http-methods.md)
- [MVC Controllers](../mvc-architecture/controllers.md)

## Important Notes
- Routes processed in order - specific routes first
- Use debugging footer "Routes" link to view all routes
- Parameter values available as `params.key` in controllers
- Avoid `.` in route patterns (use query strings instead)