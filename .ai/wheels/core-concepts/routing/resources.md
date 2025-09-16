# Resource Routing

## Description
RESTful resource routing automatically creates conventional routes for CRUD operations on models.

## Key Points
- Use `resources("name")` for full CRUD routes
- Use `resource("name")` for singular resources (no key)
- Creates 7 routes automatically for plural resources
- Creates 6 routes for singular resources
- Follows REST conventions for HTTP verbs

## Code Sample
```cfm
// Plural resource - creates 7 routes
mapper()
    .resources("products")
.end();

// Generates these routes:
// GET    /products          → products.index
// GET    /products/[key]    → products.show
// GET    /products/new      → products.new
// POST   /products          → products.create
// GET    /products/[key]/edit → products.edit
// PATCH  /products/[key]    → products.update
// DELETE /products/[key]    → products.delete

// Singular resource - creates 6 routes (no index/show)
mapper()
    .resource("cart")
.end();
```

## Usage
1. Add `resources("modelName")` in routes.cfm
2. Create corresponding controller with standard actions
3. Use generated route names in links: `linkTo(route="product", key=1)`
4. Restrict actions with `except` or `only` options

## Related
- [Routing Basics](./basics.md)
- [HTTP Methods](./http-methods.md)
- [MVC Controllers](../mvc-architecture/controllers.md)
- [CRUD Patterns](../../patterns/crud.md)

## Important Notes
- Resources are the primary convention in Wheels
- Controller names are always plural even for singular resources
- Both PUT and PATCH map to update action
- Use `except="destroy"` to exclude specific actions
- Nested resources supported for associations