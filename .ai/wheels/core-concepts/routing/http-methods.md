# HTTP Methods

## Description
Wheels routes map specific HTTP verbs to actions following REST conventions for safe and unsafe operations.

## Key Points
- GET: Safe operations (display data)
- POST: Create new resources
- PATCH/PUT: Update existing resources
- DELETE: Remove resources
- Method determines action type, not just URL

## Code Sample
```cfm
mapper()
    // Safe operations (GET)
    .get(name="products", to="products##index")        // List
    .get(name="product", pattern="products/[key]", to="products##show")  // Show

    // Unsafe operations (require CSRF protection)
    .post(name="products", to="products##create")      // Create
    .patch(name="product", pattern="products/[key]", to="products##update") // Update
    .delete(name="product", pattern="products/[key]", to="products##delete") // Delete

    // Form helpers automatically use correct method
    .get(name="newProduct", pattern="products/new", to="products##new")
    .get(name="editProduct", pattern="products/[key]/edit", to="products##edit")
.end();
```

## Usage
1. Use GET for displaying data (lists, forms, individual records)
2. Use POST for creating new resources
3. Use PATCH for updating resources (preferred over PUT)
4. Use DELETE for removing resources
5. Form helpers automatically set correct HTTP method

## Related
- [Routing Basics](./basics.md)
- [Resources](./resources.md)
- [CSRF Protection](../../configuration/security.md)

## Important Notes
- Never use GET for data modification (security risk)
- PATCH preferred over PUT for updates
- Form helpers handle method overrides automatically
- CSRF protection required for POST/PATCH/DELETE
- Resources generate all HTTP methods automatically