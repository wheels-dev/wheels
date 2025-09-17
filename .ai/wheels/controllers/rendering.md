# Controller Rendering and Response Methods

## Description
Comprehensive guide to rendering views, handling different response formats, redirects, and managing HTTP responses in CFWheels controllers.

## Rendering Views

### Automatic View Rendering
```cfm
function show() {
    product = model("Product").findByKey(params.key);

    // Automatic rendering - renders /app/views/products/show.cfm
    // No explicit renderView() call needed
}
```

### Explicit View Rendering
```cfm
function show() {
    product = model("Product").findByKey(params.key);

    // Explicit rendering with different template
    renderView(action="display", layout="custom");

    // Render with caching
    renderView(cache=60); // Cache for 60 minutes

    // Return as string instead of rendering
    content = renderView(returnAs="string");
}
```

### Rendering Different Templates
```cfm
function dashboard() {
    // Render different action template
    renderView(action="admin_dashboard");

    // Render from different controller
    renderView(controller="admin", action="dashboard");

    // Render with custom layout
    renderView(layout="admin");

    // Render without layout
    renderView(layout=false);
}
```

## Multiple Format Support

### Format Configuration
```cfm
function config() {
    super.config();
    provides("html,json,xml");
}
```

### Automatic Format Handling with renderWith
```cfm
function index() {
    products = model("Product").findAll();

    // Automatic format handling
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

### Custom Format Handling
```cfm
function download() {
    product = model("Product").findByKey(params.key);

    switch (params.format ?: "html") {
        case "json":
            renderWith(data={product: product});
            break;
        case "xml":
            renderWith(data={product: product}, format="xml");
            break;
        case "csv":
            renderCsv(product);
            break;
        default:
            renderView();
    }
}

private function renderCsv(required product) {
    csvContent = "Name,Price,Category" & chr(13) & chr(10);
    csvContent &= "#arguments.product.name#,#arguments.product.price#,#arguments.product.category.name#";

    renderText(
        text=csvContent,
        contentType="text/csv",
        fileName="product_#arguments.product.id#.csv"
    );
}
```

## Other Rendering Methods

### Plain Text Response
```cfm
function apiStatus() {
    // Render plain text
    renderText("OK");

    // With custom content type
    renderText(
        text="Custom response",
        contentType="text/plain",
        status=200
    );
}
```

### Partial Template Rendering
```cfm
function ajaxUpdate() {
    product = model("Product").findByKey(params.key);

    // Render partial template
    renderPartial(partial="productRow", data=product);

    // Render partial with layout
    renderPartial(partial="productCard", layout="ajax");
}
```

### No Content Response
```cfm
function hidden() {
    // Render nothing (useful for AJAX endpoints)
    renderNothing();
}

function apiDelete() {
    product = model("Product").findByKey(params.key);
    product.delete();

    // Return 204 No Content
    renderNothing(status=204);
}
```

### Custom Content Type
```cfm
function customApi() {
    data = {message: "Hello", timestamp: now()};

    // Render with custom content type
    renderText(
        text=SerializeJSON(data),
        contentType="application/vnd.api+json"
    );
}
```

## Redirecting Users

### Standard Redirects
```cfm
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
```

### Redirects with Flash Messages
```cfm
function update() {
    product = model("Product").findByKey(params.key);

    if (product.update(params.product)) {
        // Redirect with flash messages
        redirectTo(
            action="show",
            key=params.key,
            success="Product updated successfully"
        );
    } else {
        flashInsert(error="Please correct the errors below");
        renderView(action="edit");
    }
}

function delete() {
    product = model("Product").findByKey(params.key);
    product.delete();

    redirectTo(
        action="index",
        success="Product deleted successfully"
    );
}
```

### Back Navigation
```cfm
function cancel() {
    // Redirect back to referring page
    redirectTo(back=true);

    // Redirect back with fallback
    redirectTo(back=true, action="index");
}

function unauthorized() {
    // Redirect back with error message
    redirectTo(back=true, error="Access denied");
}
```

### Route-based Redirects
```cfm
function login() {
    // Redirect using named routes (defined in /config/routes.cfm)
    redirectTo(route="dashboard");
    redirectTo(route="userProfile", key=session.userId);
}
```

## HTTP Status Codes

### Standard Status Codes
```cfm
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

function apiUpdate() {
    product = model("Product").findByKey(params.key);

    if (!IsObject(product)) {
        renderWith(data={error: "Not found"}, status=404);
        return;
    }

    if (product.update(params.product)) {
        renderWith(data={product: product}, status=200);
    } else {
        renderWith(data={errors: product.allErrors()}, status=422);
    }
}

function apiDelete() {
    product = model("Product").findByKey(params.key);

    if (IsObject(product)) {
        product.delete();
        renderNothing(status=204);
    } else {
        renderWith(data={error: "Not found"}, status=404);
    }
}
```

### Custom Status Codes
```cfm
function maintenance() {
    renderText(
        text="Service temporarily unavailable",
        status=503
    );
}

function rateLimit() {
    renderWith(
        data={error: "Rate limit exceeded", retryAfter: 3600},
        status=429
    );
}
```

## Response Headers

### Setting Custom Headers
```cfm
function downloadFile() {
    product = model("Product").findByKey(params.key);

    // Set download headers
    header name="Content-Disposition" value="attachment; filename=product-#product.id#.pdf";
    header name="Content-Type" value="application/pdf";

    // Render file content
    renderBinary(fileContent);
}

function corsHeaders() {
    // CORS headers for API
    header name="Access-Control-Allow-Origin" value="*";
    header name="Access-Control-Allow-Methods" value="GET,POST,PUT,DELETE,OPTIONS";
    header name="Access-Control-Allow-Headers" value="Content-Type,Authorization";

    renderWith(data={message: "CORS enabled"});
}
```

### Cache Headers
```cfm
function publicData() {
    // Set cache headers
    header name="Cache-Control" value="public, max-age=3600";
    header name="Expires" value=dateFormat(dateAdd("h", 1, now()), "ddd, dd mmm yyyy HH:nn:ss") & " GMT";

    data = model("Product").findAll();
    renderWith(data);
}

function privateData() {
    // Prevent caching
    header name="Cache-Control" value="no-cache, no-store, must-revalidate";
    header name="Pragma" value="no-cache";
    header name="Expires" value="0";

    userData = getCurrentUserData();
    renderWith(userData);
}
```

## Caching Responses

### View Caching
```cfm
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

### Conditional Caching
```cfm
function cachedData() {
    // Only cache for authenticated users
    if (isLoggedIn()) {
        renderView(cache=15);
    } else {
        renderView();
    }
}

function dynamicCache() {
    cacheTime = application.environment == "production" ? 60 : 0;
    renderView(cache=cacheTime);
}
```

## Flash Messages

### Setting Flash Messages
```cfm
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
```cfm
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

## Error Handling in Rendering

### Graceful Error Responses
```cfm
function apiShow() {
    try {
        product = model("Product").findByKey(params.key);

        if (IsObject(product)) {
            renderWith(data={product: product});
        } else {
            renderWith(
                data={error: "Product not found", code: "PRODUCT_NOT_FOUND"},
                status=404
            );
        }
    } catch (any e) {
        renderWith(
            data={error: "Internal server error", code: "INTERNAL_ERROR"},
            status=500
        );
    }
}
```

### Format-Specific Error Handling
```cfm
function handleError(required any exception) {
    switch (params.format ?: "html") {
        case "json":
            renderWith(
                data={
                    error: arguments.exception.message,
                    type: arguments.exception.type
                },
                status=500
            );
            break;
        case "xml":
            renderWith(
                data={error: arguments.exception.message},
                format="xml",
                status=500
            );
            break;
        default:
            flashInsert(error="An error occurred: #arguments.exception.message#");
            redirectTo(action="index");
    }
}
```

## File Downloads and Uploads

### File Download Response
```cfm
function download() {
    product = model("Product").findByKey(params.key);

    if (!IsObject(product) || !len(product.filePath)) {
        redirectTo(action="index", error="File not found");
        return;
    }

    filePath = expandPath(product.filePath);

    if (!fileExists(filePath)) {
        redirectTo(action="index", error="File not available");
        return;
    }

    // Send file download
    sendFile(
        file=filePath,
        name="Product #product.id# Manual.pdf",
        type="application/pdf",
        disposition="attachment"
    );
}
```

### Image Response
```cfm
function thumbnail() {
    product = model("Product").findByKey(params.key);

    if (IsObject(product) && len(product.imagePath)) {
        imagePath = expandPath(product.imagePath);

        if (fileExists(imagePath)) {
            header name="Content-Type" value="image/jpeg";
            renderBinary(fileReadBinary(imagePath));
        } else {
            redirectTo(action="placeholder");
        }
    } else {
        redirectTo(action="placeholder");
    }
}
```

## Advanced Rendering Patterns

### Conditional Rendering
```cfm
function show() {
    product = model("Product").findByKey(params.key);

    if (!IsObject(product)) {
        // Handle missing product based on format
        if (params.format == "json") {
            renderWith(data={error: "Not found"}, status=404);
        } else {
            redirectTo(action="index", error="Product not found");
        }
        return;
    }

    // Normal rendering
    if (params.format == "json") {
        renderWith(data={product: product});
    } else {
        renderView();
    }
}
```

### Layout Selection
```cfm
function show() {
    product = model("Product").findByKey(params.key);

    // Choose layout based on user type or context
    if (isAdmin()) {
        renderView(layout="admin");
    } else if (isMobile()) {
        renderView(layout="mobile");
    } else {
        renderView(layout="application");
    }
}
```

### Partial Rendering for AJAX
```cfm
function updateCart() {
    cart = getCurrentCart();

    if (isAjaxRequest()) {
        // Return just the cart partial
        renderPartial(partial="cart", data=cart);
    } else {
        // Full page reload
        redirectTo(action="show");
    }
}

private function isAjaxRequest() {
    return StructKeyExists(cgi, "http_x_requested_with") &&
           cgi.http_x_requested_with == "XMLHttpRequest";
}
```

## Testing Rendering

### Testing View Rendering
```cfm
// In test
function testShowRendersCorrectView() {
    product = createTestProduct();

    params = {controller: "products", action: "show", key: product.id};
    result = processAction(params);

    // Check that view was rendered
    assert("IsStruct(result)");
    assert("result.view == 'products/show'");
}
```

### Testing JSON Responses
```cfm
function testApiShowReturnsJson() {
    product = createTestProduct();

    params = {
        controller: "products",
        action: "show",
        key: product.id,
        format: "json"
    };

    result = processAction(params);

    assert("result.contentType == 'application/json'");
    assert("isJSON(result.content)");
}
```

## Best Practices

### 1. Use Appropriate Response Formats
```cfm
// Good - format-specific responses
function show() {
    product = model("Product").findByKey(params.key);

    if (params.format == "json") {
        renderWith(data={product: product});
    } else {
        renderView();
    }
}
```

### 2. Handle Errors Gracefully
```cfm
// Good - graceful error handling
function show() {
    product = model("Product").findByKey(params.key);

    if (!IsObject(product)) {
        if (params.format == "json") {
            renderWith(data={error: "Not found"}, status=404);
        } else {
            redirectTo(action="index", error="Product not found");
        }
        return;
    }

    renderWith(product);
}
```

### 3. Use Flash Messages Appropriately
```cfm
// Good - informative flash messages
redirectTo(action="index", success="Product updated successfully");
redirectTo(action="index", error="Product could not be deleted");
redirectTo(action="index", info="Product archived");
```

### 4. Cache When Appropriate
```cfm
// Good - cache expensive operations
function expensiveReport() {
    report = generateExpensiveReport();

    // Cache for 1 hour in production, no cache in development
    cacheTime = application.environment == "production" ? 60 : 0;
    renderView(cache=cacheTime);
}
```

## Related Documentation
- [Controller Architecture](./architecture.md)
- [Controller Filters](./filters.md)
- [API Controllers](./api.md)
- [Controller Security](./security.md)
- [View Templates](../views/templates.md)