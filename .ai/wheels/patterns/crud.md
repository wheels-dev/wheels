# CRUD Patterns

## Description
Standard Create, Read, Update, Delete patterns for managing resources in Wheels applications.

## Key Points
- Follow RESTful conventions for CRUD operations
- Use standard HTTP verbs for different actions
- Implement proper error handling and validation
- Provide user feedback with flash messages
- Handle both successful and failed operations

## Code Sample
```cfm
component extends="Controller" {
    function config() {
        // Parameter verification for actions requiring ID
        verifies(params="key", paramsTypes="integer", only="show,edit,update,delete");

        // Authentication for protected actions
        filters(through="authenticate", except="index,show");
    }

    // READ - List all resources
    function index() {
        products = model("Product").findAll(
            order="name ASC",
            page=params.page,
            perPage=20
        );
    }

    // READ - Show single resource
    function show() {
        product = model("Product").findByKey(params.key);
        if (!IsObject(product)) {
            flashInsert(error="Product not found");
            redirectTo(action="index");
        }
    }

    // CREATE - Show form for new resource
    function new() {
        product = model("Product").new();
        categories = model("Category").findAll();
    }

    // CREATE - Process form submission
    function create() {
        product = model("Product").new(params.product);

        if (product.save()) {
            flashInsert(success="Product created successfully!");
            redirectTo(route="product", key=product.id);
        } else {
            categories = model("Category").findAll();
            flashInsert(error="Please fix the errors below");
            renderView(action="new");
        }
    }

    // UPDATE - Show form for editing resource
    function edit() {
        product = model("Product").findByKey(params.key);
        categories = model("Category").findAll();

        if (!IsObject(product)) {
            flashInsert(error="Product not found");
            redirectTo(action="index");
        }
    }

    // UPDATE - Process form submission
    function update() {
        product = model("Product").findByKey(params.key);

        if (!IsObject(product)) {
            flashInsert(error="Product not found");
            redirectTo(action="index");
            return;
        }

        if (product.update(params.product)) {
            flashInsert(success="Product updated successfully!");
            redirectTo(route="product", key=product.id);
        } else {
            categories = model("Category").findAll();
            flashInsert(error="Please fix the errors below");
            renderView(action="edit");
        }
    }

    // DELETE - Remove resource
    function delete() {
        product = model("Product").findByKey(params.key);

        if (!IsObject(product)) {
            flashInsert(error="Product not found");
            redirectTo(action="index");
            return;
        }

        if (product.delete()) {
            flashInsert(success="Product deleted successfully!");
        } else {
            flashInsert(error="Unable to delete product");
        }

        redirectTo(action="index");
    }
}
```

## Usage
1. Use RESTful route conventions (resources)
2. Verify parameters for actions requiring IDs
3. Handle not found conditions gracefully
4. Provide clear success/error messages
5. Redirect after successful POST operations (PRG pattern)

## Related
- [Resource Routing](../core-concepts/routing/resources.md)
- [Object Validation](../database/validations/presence.md)
- [Authentication](./authentication.md)

## Important Notes
- Always verify object existence before operations
- Use POST-redirect-GET pattern for form submissions
- Provide meaningful flash messages for user feedback
- Handle validation errors by re-rendering forms
- Consider soft delete for important data