# CLAUDE.md - Controllers

This file provides guidance to Claude Code (claude.ai/code) when working with Wheels controllers.

## 🚨 CRITICAL: PRE-CONTROLLER IMPLEMENTATION CHECKLIST 🚨

### 🛑 MANDATORY DOCUMENTATION READING (COMPLETE BEFORE ANY CODE)

**YOU MUST READ THESE FILES IN ORDER:**

✅ **Step 1: Error Prevention (ALWAYS FIRST)**
- [ ] `.ai/wheels/troubleshooting/common-errors.md` - PREVENT FATAL ERRORS
- [ ] `.ai/wheels/patterns/validation-templates.md` - CONTROLLER CHECKLIST

✅ **Step 2: Controller-Specific Documentation**
- [ ] `.ai/wheels/controllers/rendering/views.md` - View rendering patterns
- [ ] `.ai/wheels/controllers/filters/authentication.md` - Authentication patterns
- [ ] `.ai/wheels/controllers/params/verification.md` - Parameter handling
- [ ] `.ai/cfml/syntax/cfscript-vs-tags.md` - CFScript syntax rules
- [ ] `.ai/wheels/snippets/controller-snippets.md` - Code examples

### 🔴 CRITICAL ANTI-PATTERN CHECK (MUST VERIFY BEFORE WRITING)

**Before writing ANY controller code, verify you will NOT:**
- [ ] ❌ Mix argument styles: `renderText("error", status=404)`
- [ ] ❌ Use ArrayLen() on model results: `ArrayLen(posts)`
- [ ] ❌ Loop queries as arrays in views
- [ ] ❌ Use singular controller names: `PostController.cfc`

**And you WILL:**
- [ ] ✅ Use consistent argument style throughout
- [ ] ✅ Use plural naming: `PostsController.cfc`
- [ ] ✅ Use .recordCount for query counts
- [ ] ✅ Handle 404s properly for missing records

### 📋 CONTROLLER IMPLEMENTATION TEMPLATE (MANDATORY STARTING POINT)

```cfm
component extends="Controller" {
    function config() {
        // Choose ONE argument style and stick with it

        // Option 1: ALL NAMED arguments (RECOMMENDED)
        filters(through="authenticate");
        verifies(params="key", paramsTypes="integer");

        // Option 2: ALL POSITIONAL arguments
        filters("authenticate");
        verifies("key");

        // NEVER mix styles within same component
    }

    function show() {
        // ALL NAMED arguments pattern
        post = model("Post").findByKey(key=params.key, include="comments");

        if (!isObject(post)) {
            renderText(text="Not found", status=404);
            return;
        }

        // Association returns QUERY, not array
        commentCount = post.comments().recordCount;
    }
}
```

### ⚠️ MANDATORY: Controller Implementation Validation

**After reading documentation and completing checklist above, you must also:**

1. **📖 Load Controller Documentation**
   - Read `.ai/wheels/controllers/basics.md` for controller fundamentals
   - Review `.ai/wheels/controllers/filters.md` for authentication patterns
   - Check `.ai/wheels/controllers/parameters.md` for parameter handling
   - Reference `.ai/wheels/controllers/rendering.md` for response patterns

2. **✅ Validate Implementation Standards**
   - Confirm controller uses **plural naming** (Users.cfc handles users resource)
   - Verify extends "Controller" class (not "wheels.Controller")
   - Ensure proper filter syntax: `filters(through="authenticate")`
   - Check parameter verification: `verifies(params="key", paramsTypes="integer")`

3. **🔒 Security Requirements**
   - Implement CSRF protection: `protectsFromForgery()`
   - Add parameter validation for all actions
   - Use authentication filters where needed
   - Sanitize user input properly

4. **🔍 Code Example Reference**
   - Use templates from `.ai/wheels/snippets/controllers/`
   - Follow RESTful patterns from `.ai/wheels/patterns/`
   - Apply security practices from `.ai/wheels/security/`

5. **📝 RESTful Action Standards**
   - `index()` - List resources (GET /users)
   - `show()` - Display single resource (GET /users/12)
   - `new()` - Show creation form (GET /users/new)
   - `create()` - Process creation (POST /users)
   - `edit()` - Show edit form (GET /users/12/edit)
   - `update()` - Process updates (PUT /users/12)
   - `delete()` - Remove resource (DELETE /users/12)

## 🚨 CRITICAL: CFWheels Argument Mixing Rules

**NEVER mix positional and named arguments in ANY CFWheels function call. This is the #1 cause of controller errors.**

### ❌ WRONG - Mixed Arguments (WILL CAUSE ERRORS)
```cfm
// Model methods - MIXING CAUSES ERRORS
post = model("Post").findByKey(params.key, include="comments"); // ERROR!
users = model("User").findAll("active = 1", order="name"); // ERROR!
user = model("User").findOne(params.email, include="profile"); // ERROR!

// Rendering methods
renderText("Not found", status=404); // ERROR!
redirectTo("index", error="Failed"); // ERROR!

// Helper methods
linkTo("Home", controller="users"); // ERROR!
```

### ✅ CORRECT - All Named Arguments (RECOMMENDED)
```cfm
// Model methods - ALWAYS use named arguments for clarity
post = model("Post").findByKey(key=params.key, include="comments");
users = model("User").findAll(where="active = 1", order="name");
user = model("User").findOne(where="email = '#params.email#'", include="profile");

// Rendering methods
renderText(text="Not found", status=404);
redirectTo(action="index", error="Failed");

// Helper methods
linkTo(text="Home", controller="users");
```

### ✅ ALSO CORRECT - All Positional Arguments
```cfm
// Model methods - positional only when simple
post = model("Post").findByKey(params.key);
users = model("User").findAll();
user = model("User").findOne();

// But named arguments are clearer for multiple parameters
```

### Common Controller Patterns - CORRECT Examples
```cfm
function show() {
    // ✅ CORRECT - All named
    post = model("Post").findByKey(key=params.key, include="comments");

    if (!isObject(post)) {
        // ✅ CORRECT - All named
        renderText(text="Post not found", status=404);
        return;
    }
}

function index() {
    // ✅ CORRECT - All named
    posts = model("Post").findAll(
        where="published = 1",
        order="createdAt DESC",
        include="comments"
    );
}

function create() {
    post = model("Post").new(params.post);

    if (post.save()) {
        // ✅ CORRECT - All named
        redirectTo(route="post", key=post.id, success="Created!");
    } else {
        // ✅ CORRECT - All named
        renderView(action="new");
    }
}
```

**⚡ MEMORY RULE**: In CFWheels, consistency is king. Pick named OR positional arguments and stick with it throughout the entire function call.

### 🔍 POST-IMPLEMENTATION VALIDATION (REQUIRED BEFORE COMPLETION)

**After writing controller code, you MUST run these checks:**

```bash
# 1. Syntax validation
wheels server start --validate

# 2. Test validation
wheels test run

# 3. Anti-pattern detection
grep -r "renderText(\"[^\"]*\",[[:space:]]*[a-zA-Z]" app/controllers/  # Check mixed args
grep -r "ArrayLen(" app/controllers/  # Check query/array confusion
```

**Manual checklist verification:**
- [ ] No mixed argument styles in any function calls
- [ ] No ArrayLen() calls on model results or associations
- [ ] Proper error handling for missing records (404s)
- [ ] Consistent naming (plural controller names)
- [ ] All model interactions use consistent argument syntax

## Overview

Controllers in Wheels handle incoming HTTP requests and coordinate between models (data) and views (presentation). They are the "C" in the MVC (Model-View-Controller) pattern and are responsible for:

- Processing incoming requests and routing them to appropriate actions
- Interacting with models to retrieve or modify data
- Preparing data for views and rendering responses
- Handling user input validation and error handling
- Managing redirects and HTTP responses
- Implementing business logic flow control

## Controller File Structure

Controllers are stored in this directory (`/app/controllers/`) and follow these conventions:
- **File naming**: PascalCase, typically plural (e.g., `Products.cfc`, `Users.cfc`)
- **Base class**: All controllers extend `Controller.cfc` (which extends `wheels.Controller`)
- **Actions**: Public methods that handle specific requests
- **Configuration**: Use `config()` method for initialization (NOT `init()`)

## Basic Controller Template

Every controller extends `Controller` and uses `config()` for initialization:

```cfc
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

```cfc
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

## Request Handling and Actions

### Standard CRUD Actions Pattern
```cfc
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

## Rendering and Response Methods

### Rendering Views
```cfc
function show() {
    product = model("Product").findByKey(params.key);
    
    // Automatic rendering - renders /app/views/products/show.cfm
    // No explicit renderView() call needed
    
    // Explicit rendering with different template
    renderView(action="display", layout="custom");
    
    // Render with caching
    renderView(cache=60); // Cache for 60 minutes
    
    // Return as string instead of rendering
    content = renderView(returnAs="string");
}
```

### Multiple Format Support
```cfc
function config() {
    super.config();
    provides("html,json,xml");
}

function index() {
    products = model("Product").findAll();
    
    // Automatic format handling with renderWith
    renderWith(products);
    // - HTML: renders /app/views/products/index.cfm
    // - JSON: automatically converts to JSON
    // - XML: automatically converts to XML
}

function show() {
    product = model("Product").findByKey(params.key);
    
    if (IsObject(product)) {
        renderWith(product);
    } else {
        renderWith(data={error: "Not found"}, status=404);
    }
}
```

### Other Rendering Methods
```cfc
function ajaxUpdate() {
    // Render partial template
    renderPartial(partial="productRow", data=product);
}

function apiStatus() {
    // Render plain text
    renderText("OK");
}

function hidden() {
    // Render nothing (useful for AJAX endpoints)
    renderNothing();
}

function customApi() {
    // Render with custom content type
    renderText(
        text=SerializeJSON(data), 
        contentType="application/vnd.api+json"
    );
}
```

## Redirecting Users

### Standard Redirects
```cfc
function create() {
    product = model("Product").create(params.product);
    
    if (product.hasErrors()) {
        renderView(action="new");
    } else {
        // Redirect to action
        redirectTo(action="index", success="Product created");
        
        // Redirect to specific record
        redirectTo(action="show", key=product.id);
        
        // Redirect to different controller
        redirectTo(controller="dashboard", action="index");
    }
}

function update() {
    // Redirect with flash messages
    redirectTo(
        action="show", 
        key=params.key,
        success="Product updated successfully"
    );
}

function cancel() {
    // Redirect back to referring page
    redirectTo(back=true);
    
    // Redirect back with fallback
    redirectTo(back=true, action="index");
}
```

### Route-based Redirects
```cfc
function login() {
    // Redirect using named routes (defined in /config/routes.cfm)
    redirectTo(route="dashboard");
    redirectTo(route="userProfile", key=session.userId);
}
```

## Using Filters

Filters allow you to run code before or after actions without explicit calls:

### Basic Filter Setup
```cfc
function config() {
    super.config();
    
    // Before filters (default)
    filters(through="authenticate");
    filters(through="loadUser", only="show,edit,update,delete");
    filters(through="adminRequired", except="index,show");
    
    // After filters
    filters(through="logAccess", type="after");
    filters(through="cleanup", type="after", only="create,update,delete");
}

/**
 * Authentication filter
 */
private function authenticate() {
    if (!StructKeyExists(session, "userId")) {
        redirectTo(controller="sessions", action="new", error="Please log in");
    }
}

/**
 * Load user for actions that need it
 */
private function loadUser() {
    user = model("User").findByKey(session.userId);
    if (!IsObject(user)) {
        redirectTo(controller="sessions", action="new", error="Invalid session");
    }
}

/**
 * Admin access required
 */
private function adminRequired() {
    if (!user.isAdmin()) {
        redirectTo(back=true, error="Access denied");
    }
}
```

### Filter Arguments and Dynamic Values
```cfc
function config() {
    super.config();
    
    // Static arguments
    filters(through="checkPermission", permission="read");
    
    // Dynamic arguments (evaluated at runtime)
    filters(through="checkOwnership", userId="##session.userId##");
    
    // Arguments as struct
    filterArgs = {permission: "admin", strict: true};
    filters(through="authorize", authorizeArguments=filterArgs);
}

private function checkPermission(permission = "read") {
    if (!user.hasPermission(arguments.permission)) {
        redirectTo(back=true, error="Insufficient permissions");
    }
}
```

## Working with Models in Controllers

Controllers primarily interact with models to retrieve, create, update, and delete data. This section covers common controller-model interaction patterns.

> **🚨 REMINDER**: ALL model method calls in controllers MUST use consistent argument syntax - either all named OR all positional arguments. Mixed arguments will cause "Missing argument name" errors.

> **🚨 REMINDER**: Model associations return QUERY objects, not arrays. Use `.recordCount` for counts and `<cfloop query="...">` for iteration in views.

> **📚 For comprehensive model documentation**, see `/app/models/CLAUDE.md` which covers all model methods, associations, validations, callbacks, and advanced features like dirty tracking, dynamic finders, statistical functions, and more.

### Basic Model Operations in Controllers
```cfc
function index() {
    // Find all records with common controller patterns
    products = model("Product").findAll(
        page=params.page ?: 1,
        perPage=25,
        order="createdAt DESC"
    );
    
    // With search filtering
    if (StructKeyExists(params, "q") && len(params.q)) {
        products = model("Product").findAll(
            where="name LIKE '%#params.q#%' OR description LIKE '%#params.q#%'",
            page=params.page ?: 1,
            perPage=25
        );
    }
}

function show() {
    // Find by primary key with error handling
    product = model("Product").findByKey(params.key);
    
    if (!IsObject(product)) {
        redirectTo(action="index", error="Product not found");
        return;
    }
    
    // Load related data for display
    product = model("Product").findByKey(
        key=params.key,
        include="category,reviews.user"
    );
}

function new() {
    // Create new model instance for form
    product = model("Product").new();
    
    // Load related data for form dropdowns
    categories = model("Category").findAll(order="name");
}

function create() {
    // Create with form data and handle validation
    product = model("Product").create(params.product);
    
    if (product.hasErrors()) {
        // Re-display form with errors
        categories = model("Category").findAll(order="name");
        renderView(action="new");
    } else {
        redirectTo(action="show", key=product.id, success="Product created successfully");
    }
}

function edit() {
    // Load record for editing
    product = model("Product").findByKey(params.key);
    categories = model("Category").findAll(order="name");
}

function update() {
    // Update existing record
    product = model("Product").findByKey(params.key);
    
    if (product.update(params.product)) {
        redirectTo(action="show", key=product.id, success="Product updated successfully");
    } else {
        categories = model("Category").findAll(order="name");
        renderView(action="edit");
    }
}

function delete() {
    // Delete record with confirmation
    product = model("Product").findByKey(params.key);
    product.delete();
    redirectTo(action="index", success="Product deleted successfully");
}
```

### Controller-Specific Model Patterns

#### Pagination in Controllers
```cfc
function index() {
    // Standard pagination pattern
    products = model("Product").findAll(
        page=params.page ?: 1,
        perPage=params.perPage ?: 25,
        order="name"
    );
    
    // Make pagination info available to view
    pagination = {
        currentPage: products.currentPage,
        totalPages: products.pageCount,
        totalRecords: products.totalRecords
    };
}
```

#### Search and Filtering
```cfc
function search() {
    local.where = "";

    // Build where clause
    if (Len(params.q ?: "")) {
        local.where = "name LIKE '%#params.q#%' OR description LIKE '%#params.q#%'";
    }

    if (IsNumeric(params.categoryId ?: "")) {
        if (Len(local.where)) {
            local.where &= " AND ";
        }
        local.where &= "categoryId = #params.categoryId#";
    }

    products = model("Product").findAll(where = local.where);
}
```

#### Association Loading
```cfc
function dashboard() {
    // Load multiple models efficiently
    recentProducts = model("Product").findAll(
        limit=5,
        order="createdAt DESC",
        include="category"  // Avoid N+1 queries
    );
    
    topCategories = model("Category").findAll(
        joins="INNER JOIN products p ON categories.id = p.categoryId",
        group="categories.id",
        order="COUNT(p.id) DESC",
        limit=10
    );
    
    // Use statistical functions (see models/CLAUDE.md for full reference)
    totalProducts = model("Product").count();
    averagePrice = model("Product").average("price");
}
```

#### Validation Handling
```cfc
function create() {
    product = model("Product").new(params.product);
    
    if (product.save()) {
        redirectTo(action="show", key=product.id, success="Created successfully");
    } else {
        // Make errors available to view
        errors = product.allErrors();
        
        // Reload supporting data
        categories = model("Category").findAll(order="name");
        
        renderView(action="new");
    }
}

function bulkUpdate() {
    errors = [];
    successes = 0;
    
    for (productId in params.selectedIds) {
        product = model("Product").findByKey(productId);
        
        if (IsObject(product)) {
            if (product.update(params.bulkData)) {
                successes++;
            } else {
                arrayAppend(errors, "Product ##productId##: #arrayToList(product.errorMessages())#");
            }
        }
    }
    
    if (successes > 0) {
        flashInsert(success="#successes# products updated");
    }
    if (arrayLen(errors) > 0) {
        flashInsert(error="Errors: #arrayToList(errors, '; ')#");
    }
    
    redirectTo(action="index");
}
```

### Advanced Controller-Model Patterns

#### Dynamic Finders in Controllers
```cfc
function findByEmail() {
    // Use dynamic finders (see models/CLAUDE.md for complete reference)
    user = model("User").findOneByEmail(params.email);
    
    if (IsObject(user)) {
        renderWith(user);
    } else {
        renderWith(data={error: "User not found"}, status=404);
    }
}

function filterByStatus() {
    // Dynamic finder with additional parameters
    products = model("Product").findAllByStatus(
        value=params.status,
        order="createdAt DESC",
        page=params.page ?: 1
    );
}
```

#### Statistical Queries in Controllers
```cfc
function reports() {
    // Use model statistical functions
    totalRevenue = model("Order").sum("total", where="status = 'completed'");
    averageOrderValue = model("Order").average("total", where="status = 'completed'");
    orderCount = model("Order").count(where="status = 'completed'");
    
    sql = "SELECT p.*, COUNT(oi.id) as orderCount
        FROM products p
        INNER JOIN orderItems oi ON p.id = oi.productId
        GROUP BY p.id
        ORDER BY orderCount DESC
        LIMIT 10";
                
    topProducts = queryExecute(sql, {}, { datasource = "yourDatasourceName" });
}
```

#### Change Tracking in Controllers
```cfc
function update() {
    product = model("Product").findByKey(params.key);
    originalPrice = product.price;
    
    if (product.update(params.product)) {
        // Use dirty tracking to detect changes (see models/CLAUDE.md)
        if (product.hasChanged("price")) {
            // Log price change
            writeLog("Price changed for product #product.id#: #originalPrice# to #product.price#");
        }
        
        redirectTo(action="show", key=product.id, success="Updated successfully");
    } else {
        renderView(action="edit");
    }
}
```

### API Controller Model Patterns
```cfc
function apiIndex() {
    products = model("Product").findAll(
        page=params.page ?: 1,
        perPage=params.perPage ?: 25
    );
    
    renderWith(data={
        products: products,
        meta: {
            page: products.currentPage,
            totalPages: products.pageCount,
            total: products.totalRecords
        }
    });
}

function apiCreate() {
    product = model("Product").new(params.product);
    
    if (product.save()) {
        renderWith(data={product: product}, status=201);
    } else {
        renderWith(data={
            error: "Validation failed",
            errors: product.allErrors()
        }, status=422);
    }
}
```

> **🔗 Model Method Reference**: For complete documentation of all available model methods including:
> - **Finders**: `findAll()`, `findByKey()`, `findOne()`, dynamic finders
> - **CRUD**: `create()`, `new()`, `save()`, `update()`, `delete()`
> - **Associations**: `hasMany()`, `belongsTo()`, `hasOne()`, nested properties
> - **Validations**: All validation methods and custom validations
> - **Advanced Features**: Dirty tracking, callbacks, soft delete, statistics, etc.
> 
> See `/app/models/CLAUDE.md`

## Flash Messages

The Flash is used to store messages between requests (especially after redirects):

### Setting Flash Messages
```cfc
function update() {
    product = model("Product").findByKey(params.key);
    
    if (product.update(params.product)) {
        // Flash message with redirect (shortcut)
        redirectTo(action="show", key=product.id, success="Product updated successfully");
    } else {
        // Flash message without redirect
        flashInsert(error="Please correct the errors below");
        renderView(action="edit");
    }
}

function delete() {
    product = model("Product").findByKey(params.key);
    
    if (product.delete()) {
        flashInsert(success="Product deleted successfully");
    } else {
        flashInsert(error="Could not delete product");
    }
    
    redirectTo(action="index");
}
```

### Advanced Flash Usage
```cfc
function complexOperation() {
    // Multiple flash messages
    flashInsert(info="Processing your request...");
    
    try {
        // Complex operation
        result = performComplexOperation();
        
        if (result.success) {
            flashInsert(success="Operation completed successfully");
        } else {
            flashInsert(warning="Operation completed with warnings: #result.warnings#");
        }
    } catch (any e) {
        flashInsert(error="Operation failed: #e.message#");
    }
    
    redirectTo(action="dashboard");
}

function multiStep() {
    // Flash with custom keys
    flashInsert(step="Validating data...");
    flashInsert(progress="25%");
    
    redirectTo(action="stepTwo");
}
```

## The `params` Struct

The `params` struct combines URL, form, and route parameters:

### Accessing Parameters
```cfc
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

### JSON Request Handling
```cfc
function apiCreate() {
    // JSON body automatically parsed to params
    // Content-Type: application/json
    // {"product": {"name": "Laptop", "price": 999.99}}
    
    product = model("Product").create(params.product);
    
    if (product.hasErrors()) {
        renderWith(data={errors: product.allErrors()}, status=422);
    } else {
        renderWith(data={product: product}, status=201);
    }
}
```

## API Controllers

### JSON API Pattern
```cfc
component extends="Controller" {

    function config() {
        super.config();
        provides("json");
        filters(through="setJsonResponse");
    }

    function index() {
        products = model("Product").findAll();
        renderWith(data={products: products});
    }

    function show() {
        product = model("Product").findByKey(params.key);
        
        if (IsObject(product)) {
            renderWith(data={product: product});
        } else {
            renderWith(data={error: "Product not found"}, status=404);
        }
    }

    function create() {
        product = model("Product").new(params.product);
        
        if (product.save()) {
            renderWith(data={product: product}, status=201);
        } else {
            renderWith(
                data={
                    error: "Validation failed",
                    errors: product.allErrors()
                }, 
                status=422
            );
        }
    }

    function update() {
        product = model("Product").findByKey(params.key);
        
        if (IsObject(product)) {
            product.update(params.product);
            
            if (product.hasErrors()) {
                renderWith(
                    data={
                        error: "Validation failed",
                        errors: product.allErrors()
                    }, 
                    status=422
                );
            } else {
                renderWith(data={product: product});
            }
        } else {
            renderWith(data={error: "Product not found"}, status=404);
        }
    }

    function delete() {
        product = model("Product").findByKey(params.key);
        
        if (IsObject(product)) {
            product.delete();
            renderWith(data={}, status=204);
        } else {
            renderWith(data={error: "Product not found"}, status=404);
        }
    }

    /**
     * Force JSON format for all requests
     */
    private function setJsonResponse() {
        params.format = "json";
    }

}
```

### REST API with Error Handling
```cfc
component extends="Controller" {

    function config() {
        super.config();
        provides("json");
        filters(through="setJsonFormat,corsHeaders");
    }

    function index() {
        try {
            products = model("Product").findAll(
                page=params.page ?: 1,
                perPage=params.perPage ?: 25,
                order="createdAt DESC"
            );
            
            renderWith(data={
                products: products,
                pagination: {
                    page: products.currentPage,
                    pages: products.pageCount,
                    total: products.totalRecords
                }
            });
        } catch (any e) {
            renderWith(
                data={error: "Internal server error"}, 
                status=500
            );
        }
    }

    private function corsHeaders() {
        header name="Access-Control-Allow-Origin" value="*";
        header name="Access-Control-Allow-Methods" value="GET,POST,PUT,DELETE,OPTIONS";
        header name="Access-Control-Allow-Headers" value="Content-Type,Authorization";
    }

    private function setJsonFormat() {
        params.format = "json";
    }

}
```

## Verification and Security

### Parameter Verification
```cfc
function config() {
    super.config();
    
    // Verify required parameters
    verifies(
        except="index,new,create", 
        params="key", 
        paramsTypes="integer", 
        handler="objectNotFound"
    );
    
    // Multiple parameter verification
    verifies(
        only="create,update",
        params="product.name,product.price",
        handler="invalidProduct"
    );
}

function objectNotFound() {
    redirectTo(action="index", error="Record not found");
}

function invalidProduct() {
    flashInsert(error="Invalid product data");
    redirectTo(action="new");
}
```

### CSRF Protection
```cfc
function config() {
    super.config();
    
    // CSRF protection (enabled by default in base Controller.cfc)
    protectsFromForgery();
    
    // Exclude specific actions from CSRF
    protectsFromForgery(except="webhook,api");
}
```

### Authentication Patterns
```cfc
function config() {
    super.config();
    
    // Require authentication for all actions except public ones
    filters(through="requireAuth", except="index,show");
}

private function requireAuth() {
    if (!StructKeyExists(session, "userId") || !IsNumeric(session.userId)) {
        session.returnTo = cgi.request_url;
        redirectTo(controller="sessions", action="new", error="Please log in to continue");
    }
}

private function loadCurrentUser() {
    if (StructKeyExists(session, "userId")) {
        currentUser = model("User").findByKey(session.userId);
        if (!IsObject(currentUser)) {
            StructDelete(session, "userId");
            redirectTo(controller="sessions", action="new", error="Invalid session");
        }
    }
}
```

## Nested Controllers and Namespaces

### Namespace Controllers (Admin Example)
```cfc
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
```cfc
// In /config/routes.cfm
mapper()
    .namespace("admin")
        .resources("products")
        .resources("users")
    .end()
.end();
```

## Error Handling

### Custom Error Handling
```cfc
function show() {
    try {
        product = model("Product").findByKey(params.key);
        
        if (!IsObject(product)) {
            throw(type="ProductNotFound", message="Product not found");
        }
        
        // Check permissions
        if (!canViewProduct(product)) {
            throw(type="AccessDenied", message="Access denied");
        }
        
    } catch (ProductNotFound e) {
        redirectTo(action="index", error="The requested product could not be found");
    } catch (AccessDenied e) {
        redirectTo(back=true, error="You don't have permission to view this product");
    } catch (any e) {
        // Log error
        writeDump(var=e, output="console");
        
        redirectTo(action="index", error="An error occurred while processing your request");
    }
}
```

## Advanced Controller Patterns

### Pagination Helper
```cfc
function index() {
    paginationOptions = {
        page: params.page ?: 1,
        perPage: params.perPage ?: 25,
        order: "createdAt DESC"
    };
    
    // Add search if present
    if (StructKeyExists(params, "q") && Len(params.q)) {
        paginationOptions.where = "name LIKE :search OR description LIKE :search";
        paginationOptions.params = {search: "%#params.q#%"};
    }
    
    products = model("Product").findAll(argumentCollection=paginationOptions);
    
    // Pagination info for view
    pagination = {
        currentPage: products.currentPage,
        totalPages: products.pageCount,
        totalRecords: products.totalRecords,
        hasNext: products.currentPage < products.pageCount,
        hasPrevious: products.currentPage > 1
    };
}
```

### Bulk Operations
```cfc
function bulkUpdate() {
    if (StructKeyExists(params, "selectedIds") && IsArray(params.selectedIds)) {
        successCount = 0;
        errorCount = 0;
        
        for (productId in params.selectedIds) {
            try {
                product = model("Product").findByKey(productId);
                if (IsObject(product) && product.update(params.bulkData)) {
                    successCount++;
                } else {
                    errorCount++;
                }
            } catch (any e) {
                errorCount++;
            }
        }
        
        if (successCount > 0) {
            flashInsert(success="#successCount# products updated successfully");
        }
        if (errorCount > 0) {
            flashInsert(error="#errorCount# products could not be updated");
        }
    } else {
        flashInsert(error="No products selected");
    }
    
    redirectTo(action="index");
}
```

### File Upload Handling
```cfc
function update() {
    product = model("Product").findByKey(params.key);
    
    // Handle file upload
    if (StructKeyExists(form, "imageFile") && Len(form.imageFile)) {
        uploadResult = handleImageUpload();
        if (uploadResult.success) {
            params.product.imagePath = uploadResult.filePath;
        } else {
            flashInsert(error="Image upload failed: #uploadResult.error#");
            renderView(action="edit");
            return;
        }
    }
    
    if (product.update(params.product)) {
        redirectTo(action="show", key=product.id, success="Product updated successfully");
    } else {
        renderView(action="edit");
    }
}

private function handleImageUpload() {
    try {
        // Configure upload
        uploadPath = ExpandPath("/uploads/products/");
        
        if (!DirectoryExists(uploadPath)) {
            DirectoryCreate(uploadPath);
        }
        
        // Perform upload
        uploadResult = fileUpload(
            destination=uploadPath,
            fileField="imageFile",
            nameConflict="makeunique"
        );
        
        // Validate file type
        allowedTypes = "jpg,jpeg,png,gif";
        if (!ListFindNoCase(allowedTypes, uploadResult.clientFileExt)) {
            FileDelete(uploadResult.serverDirectory & uploadResult.serverFile);
            return {success: false, error: "Invalid file type"};
        }
        
        return {
            success: true, 
            filePath: "/uploads/products/" & uploadResult.serverFile
        };
        
    } catch (any e) {
        return {success: false, error: e.message};
    }
}
```

## Performance Considerations

### Caching Responses
```cfc
function index() {
    products = model("Product").findAll(order="name");
    
    // Cache the rendered view for 30 minutes
    renderView(cache=30);
}

function show() {
    product = model("Product").findByKey(params.key, include="category,reviews");
    
    // Cache based on product and last modified time
    cacheKey = "product_#params.key#_#product.updatedAt#";
    renderView(cache=60, cacheKey=cacheKey);
}
```

### Database Query Optimization
```cfc
function index() {
    // Eager load associations to avoid N+1 queries
    products = model("Product").findAll(
        include="category,reviews.user",
        order="createdAt DESC",
        page=params.page ?: 1,
        perPage=25
    );
}

function dashboard() {
    // Use findAll with specific columns to reduce memory usage
    recentProducts = model("Product").findAll(
        select="id,name,createdAt",
        order="createdAt DESC",
        maxRows=5
    );
}
```

## Testing Controllers

### Basic Controller Testing
```cfc
// tests/specs/controllers/ProductsTest.cfc
component extends="tests.BaseTest" {

    function setup() {
        super.setup();
        
        // Create test data
        testProduct = model("Product").create({
            name: "Test Product",
            price: 99.99,
            active: true
        });
    }

    function testIndex() {
        params = {};
        result = processAction(controller="products", action="index", params=params);
        
        assert("StructKeyExists(variables, 'products')");
        assert("IsQuery(products)");
    }

    function testShowWithValidKey() {
        params = {key: testProduct.id};
        result = processAction(controller="products", action="show", params=params);
        
        assert("StructKeyExists(variables, 'product')");
        assert("IsObject(product)");
        assert("product.id == #testProduct.id#");
    }

    function testShowWithInvalidKey() {
        params = {key: 99999};
        result = processAction(controller="products", action="show", params=params);
        
        // Should redirect to index with error
        assert("IsRedirect()");
    }

}
```

## Best Practices

### 1. Use Descriptive Action Names
```cfc
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
```cfc
// Good - single responsibility
function create() {
    product = model("Product").create(params.product);
    handleCreateResponse(product);
}

function update() {
    product = model("Product").findByKey(params.key);
    if (IsObject(product)) {
        product.update(params.product);
        handleUpdateResponse(product);
    } else {
        handleNotFound();
    }
}

// Avoid - doing too much
function createOrUpdate() {
    // Complex logic mixing create and update
}
```

### 3. Use Filters for Common Functionality
```cfc
function config() {
    super.config();
    
    // Authentication
    filters(through="requireAuth", except="index,show");
    
    // Load common data
    filters(through="loadCategories", only="new,edit");
    
    // Logging
    filters(through="logAccess", type="after");
}
```

### 4. Handle Errors Gracefully
```cfc
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

### 5. Use Appropriate HTTP Status Codes
```cfc
function apiShow() {
    product = model("Product").findByKey(params.key);
    
    if (IsObject(product)) {
        renderWith(data={product: product}, status=200);
    } else {
        renderWith(data={error: "Not found"}, status=404);
    }
}

function apiCreate() {
    product = model("Product").create(params.product);
    
    if (product.hasErrors()) {
        renderWith(data={errors: product.allErrors()}, status=422);
    } else {
        renderWith(data={product: product}, status=201);
    }
}
```

## Common Patterns

### Authentication Controller
```cfc
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

### Search Controller
```cfc
component extends="Controller" {

    function index() {
        searchParams = buildSearchParams();
        
        if (StructIsEmpty(searchParams.criteria)) {
            products = [];
        } else {
            products = model("Product").findAll(argumentCollection=searchParams);
        }
        
        // Store search terms for form
        searchTerms = {
            q: params.q ?: "",
            category: params.category ?: "",
            priceMin: params.priceMin ?: "",
            priceMax: params.priceMax ?: ""
        };
    }

    private function buildSearchParams() {
        local.criteria = {};
        local.params = {};
        local.conditions = [];
        
        // Text search
        if (StructKeyExists(params, "q") && Len(params.q)) {
            ArrayAppend(local.conditions, "(name LIKE :search OR description LIKE :search)");
            local.params.search = "%#params.q#%";
        }
        
        // Category filter
        if (StructKeyExists(params, "category") && IsNumeric(params.category)) {
            ArrayAppend(local.conditions, "categoryId = :categoryId");
            local.params.categoryId = params.category;
        }
        
        // Price range
        if (StructKeyExists(params, "priceMin") && IsNumeric(params.priceMin)) {
            ArrayAppend(local.conditions, "price >= :priceMin");
            local.params.priceMin = params.priceMin;
        }
        
        if (StructKeyExists(params, "priceMax") && IsNumeric(params.priceMax)) {
            ArrayAppend(local.conditions, "price <= :priceMax");
            local.params.priceMax = params.priceMax;
        }
        
        if (ArrayLen(local.conditions)) {
            local.criteria.where = ArrayToList(local.conditions, " AND ");
            local.criteria.params = local.params;
        }
        
        local.criteria.order = "name ASC";
        local.criteria.page = params.page ?: 1;
        local.criteria.perPage = 25;
        
        return {criteria: local.criteria};
    }

}
```

## Important Notes

- **Use `config()`, not `init()`**: Controllers use the `config()` method for initialization, never `init()`
- **Always call `super.config()`**: When implementing `config()`, call the parent method first
- **Actions are public methods**: Any public method can be called as an action via URL
- **Private methods for helpers**: Use `private` access for filter methods and internal helpers
- **Automatic view rendering**: Views are automatically rendered unless you explicitly render or redirect
- **The `params` struct**: Contains all request parameters (URL, form, route) and is available throughout the controller
- **Flash messages**: Use for temporary messages between requests, especially after redirects
- **CSRF protection**: Automatically enabled in base `Controller.cfc` via `protectsFromForgery()`
- **Multiple format support**: Use `provides()` and `renderWith()` for APIs and multiple response formats
- **Filters**: Perfect for cross-cutting concerns like authentication, logging, and data loading

The controller layer is where you orchestrate the flow of your application, coordinating between models and views while handling user interaction and business logic.