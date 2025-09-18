# Controller Architecture

## Description
CFWheels controller fundamentals, including structure, conventions, basic patterns, and the MVC request lifecycle.

## Controller Overview

Controllers in Wheels handle incoming HTTP requests and coordinate between models (data) and views (presentation). They are the "C" in the MVC (Model-View-Controller) pattern and are responsible for:

- Processing incoming requests and routing them to appropriate actions
- Interacting with models to retrieve or modify data
- Preparing data for views and rendering responses
- Handling user input validation and error handling
- Managing redirects and HTTP responses
- Implementing business logic flow control

## Controller File Structure

Controllers are stored in `/app/controllers/` and follow these conventions:
- **File naming**: PascalCase, typically plural (e.g., `Products.cfc`, `Users.cfc`)
- **Base class**: All controllers extend `Controller.cfc` (which extends `wheels.Controller`)
- **Actions**: Public methods that handle specific requests
- **Configuration**: Use `config()` method for initialization (NOT `init()`)

## Basic Controller Template

Every controller extends `Controller` and uses `config()` for initialization:

```cfm
component extends="Controller" {

    /**
     * Controller configuration - runs once when controller is loaded
     */
    function config() {
        // Call parent config to inherit base functionality
        super.config();

        // Controller-specific configuration goes here
        // Examples: filters, format support, verification rules
    }

    /**
     * Default action - typically lists all records
     */
    function index() {
        // Load data and prepare for view
        products = model("Product").findAll();
        // View automatically rendered: /app/views/products/index.cfm
    }

    /**
     * Show specific record
     */
    function show() {
        product = model("Product").findByKey(params.key);
        if (!IsObject(product)) {
            redirectTo(action="index", error="Product not found");
        }
    }

}
```

## CLI Commands for Controllers

### Creating Controllers
```bash
# Basic controller
wheels generate controller products
wheels g controller products

# Controller with specific actions
wheels g controller products actions="index,show,new,create,edit,update,delete"

# RESTful controller (full CRUD)
wheels g controller products --rest

# API controller (JSON responses, no views)
wheels g controller api/products --api

# Custom actions
wheels g controller reports actions="dashboard,monthly,yearly,export"
```

### Testing Controllers
```bash
wheels generate test controller products
wheels test run --directory=tests/specs/controllers
```

## Controller Configuration (`config()` method)

The `config()` method is where you configure controller behavior. **CRITICAL**: Use `config()`, NOT `init()`.

```cfm
function config() {
    // Always call parent config first
    super.config();

    // Authentication filters
    filters(through="authenticate", except="index,show");
    filters(through="loadUser", only="show,edit,update,delete");

    // Format support
    provides("html,json,xml");

    // Verification rules
    verifies(except="index,new,create", params="key", paramsTypes="integer", handler="objectNotFound");

    // CSRF protection (automatic in base Controller.cfc)
    protectsFromForgery();

    // Pagination defaults
    set(defaultPerPage=25);
}
```

## Standard CRUD Actions Pattern

### Basic CRUD Implementation
```cfm
component extends="Controller" {

    function config() {
        super.config();
        verifies(except="index,new,create", params="key", paramsTypes="integer", handler="objectNotFound");
    }

    /**
     * GET /products - List all products
     */
    function index() {
        products = model("Product").findAll(
            page=params.page ?: 1,
            perPage=25,
            order="createdAt DESC"
        );
    }

    /**
     * GET /products/[key] - Show specific product
     */
    function show() {
        product = model("Product").findByKey(params.key);
    }

    /**
     * GET /products/new - New product form
     */
    function new() {
        product = model("Product").new();
    }

    /**
     * POST /products - Create product
     */
    function create() {
        product = model("Product").create(params.product);
        if (product.hasErrors()) {
            renderView(action="new");
        } else {
            redirectTo(action="index", success="Product created successfully");
        }
    }

    /**
     * GET /products/[key]/edit - Edit product form
     */
    function edit() {
        product = model("Product").findByKey(params.key);
    }

    /**
     * PATCH/PUT /products/[key] - Update product
     */
    function update() {
        product = model("Product").findByKey(params.key);
        if (product.update(params.product)) {
            redirectTo(action="show", key=product.id, success="Product updated successfully");
        } else {
            renderView(action="edit");
        }
    }

    /**
     * DELETE /products/[key] - Delete product
     */
    function delete() {
        product = model("Product").deleteByKey(params.key);
        redirectTo(action="index", success="Product deleted successfully");
    }

    /**
     * Handle verification failures
     */
    function objectNotFound() {
        redirectTo(action="index", error="Product not found");
    }

}
```

## RESTful Action Standards

### Standard Action Mappings
- `index()` - List resources (GET /users)
- `show()` - Display single resource (GET /users/12)
- `new()` - Show creation form (GET /users/new)
- `create()` - Process creation (POST /users)
- `edit()` - Show edit form (GET /users/12/edit)
- `update()` - Process updates (PUT /users/12)
- `delete()` - Remove resource (DELETE /users/12)

### URL-to-Action Mapping
| HTTP Method | URL Pattern | Action | Purpose |
|-------------|-------------|--------|---------|
| GET | `/products` | index | List all products |
| GET | `/products/new` | new | Show creation form |
| POST | `/products` | create | Create new product |
| GET | `/products/123` | show | Display product 123 |
| GET | `/products/123/edit` | edit | Show edit form for product 123 |
| PUT/PATCH | `/products/123` | update | Update product 123 |
| DELETE | `/products/123` | delete | Delete product 123 |

## Argument Consistency Rules

**🚨 CRITICAL**: NEVER mix positional and named arguments in ANY CFWheels function call.

### ❌ WRONG - Mixed Arguments (WILL CAUSE ERRORS)
```cfm
// Model methods - MIXING CAUSES ERRORS
post = model("Post").findByKey(params.key, include="comments"); // ERROR!
users = model("User").findAll("active = 1", order="name"); // ERROR!

// Rendering methods
renderText("Not found", status=404); // ERROR!
redirectTo("index", error="Failed"); // ERROR!
```

### ✅ CORRECT - All Named Arguments (RECOMMENDED)
```cfm
// Model methods - ALWAYS use named arguments for clarity
post = model("Post").findByKey(key=params.key, include="comments");
users = model("User").findAll(where="active = 1", order="name");

// Rendering methods
renderText(text="Not found", status=404);
redirectTo(action="index", error="Failed");
```

### ✅ ALSO CORRECT - All Positional Arguments
```cfm
// Model methods - positional only when simple
post = model("Post").findByKey(params.key);
users = model("User").findAll();
```

## The `params` Struct

The `params` struct combines URL, form, and route parameters:

### Accessing Parameters
```cfm
function show() {
    // Route parameter: /products/123
    productId = params.key; // "123"

    // URL parameter: /products/123?format=json
    format = params.format; // "json"

    // Always available
    controller = params.controller; // "products"
    action = params.action; // "show"
}

function search() {
    // URL parameters: /products?q=laptop&category=electronics&page=2
    searchTerm = params.q ?: "";
    categoryId = params.category ?: "";
    page = params.page ?: 1;

    // Form parameters (from POST request)
    if (StructKeyExists(params, "product")) {
        productData = params.product;
        name = params.product.name;
        price = params.product.price;
    }
}

function create() {
    // Nested parameters from form
    // <input name="product[name]" value="Laptop">
    // <input name="product[price]" value="999.99">

    product = model("Product").create(params.product);
    // params.product = {name: "Laptop", price: "999.99"}
}
```

## Request Lifecycle

### 1. Route Resolution
Wheels matches the incoming URL to a route pattern:
```
http://localhost:8080/products/show/123
                     ↓
{controller: "products", action: "show", key: "123"}
```

### 2. Controller Instantiation
Creates an instance of the appropriate controller (Products.cfc)

### 3. Filter Execution
Runs any before filters defined for the action

### 4. Action Execution
Calls the specified action method (show())

### 5. View Rendering
Renders the corresponding view (unless redirected or explicitly rendered)

### 6. Response
Sends the final output to the browser

## Naming Conventions

### Controllers
- **File names**: PascalCase (e.g., `Users.cfc`, `SiteMap.cfc`)
- **URL mapping**: Hyphenated lowercase (e.g., `/users`, `/site-map`)

### Actions
- **Method names**: camelCase (e.g., `index()`, `searchEngines()`)
- **URL mapping**: Hyphenated lowercase (e.g., `/index`, `/search-engines`)

### Views
- **Directory names**: Lowercase controller name (e.g., `/users`, `/sitemap`)
- **File names**: Lowercase action name (e.g., `index.cfm`, `searchengines.cfm`)

## Nested Controllers and Namespaces

### Namespace Controllers (Admin Example)
```cfm
// File: /app/controllers/admin/Products.cfc
component extends="wheels.Controller" {

    function config() {
        super.config();
        filters(through="requireAdmin");
    }

    function index() {
        products = model("Product").findAll(include="category");
    }

    private function requireAdmin() {
        if (!session.user.isAdmin()) {
            redirectTo(controller="home", action="index", error="Access denied");
        }
    }

}
```

### Routes for Nested Controllers
```cfm
// In /config/routes.cfm
mapper()
    .namespace("admin")
        .resources("products")
        .resources("users")
    .end()
.end();
```

## Common Controller Patterns

### Authentication Controller
```cfm
// /app/controllers/Sessions.cfc
component extends="Controller" {

    function new() {
        // Show login form
    }

    function create() {
        user = model("User").findOne(where="email = :email", params={email: params.email});

        if (IsObject(user) && user.authenticate(params.password)) {
            session.userId = user.id;

            // Redirect to intended destination or default
            redirectUrl = session.returnTo ?: "/dashboard";
            StructDelete(session, "returnTo");

            location(url=redirectUrl, addToken=false);
        } else {
            flashInsert(error="Invalid email or password");
            renderView(action="new");
        }
    }

    function delete() {
        StructClear(session);
        redirectTo(action="new", success="You have been logged out");
    }

}
```

## Best Practices

### 1. Use Descriptive Action Names
```cfm
// Good - clear intent
function activate() { }
function deactivate() { }
function search() { }
function export() { }

// Avoid - unclear purpose
function doStuff() { }
function handle() { }
function process() { }
```

### 2. Keep Actions Focused
```cfm
// Good - single responsibility
function create() {
    product = model("Product").create(params.product);
    handleCreateResponse(product);
}

// Avoid - doing too much
function createOrUpdate() {
    // Complex logic mixing create and update
}
```

### 3. Handle Errors Gracefully
```cfm
function show() {
    product = model("Product").findByKey(params.key);

    if (!IsObject(product)) {
        // Redirect with helpful message instead of throwing error
        redirectTo(action="index", error="The requested product could not be found");
        return;
    }

    // Continue with normal flow
}
```

## Important Notes

- **Use `config()`, not `init()`**: Controllers use the `config()` method for initialization, never `init()`
- **Always call `super.config()`**: When implementing `config()`, call the parent method first
- **Actions are public methods**: Any public method can be called as an action via URL
- **Private methods for helpers**: Use `private` access for filter methods and internal helpers
- **Automatic view rendering**: Views are automatically rendered unless you explicitly render or redirect
- **The `params` struct**: Contains all request parameters (URL, form, route) and is available throughout the controller
- **CSRF protection**: Automatically enabled in base `Controller.cfc` via `protectsFromForgery()`

## Related Documentation
- [Controller Rendering](./rendering.md)
- [Controller Filters](./filters.md)
- [Controller Security](./security.md)
- [API Controllers](./api.md)
- [Controller Testing](./testing.md)