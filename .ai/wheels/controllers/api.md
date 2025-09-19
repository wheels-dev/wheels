# API Controllers

## Description
Comprehensive guide to building JSON and XML APIs with CFWheels controllers, including REST patterns, error handling, authentication, and response formatting.

## Basic API Controller Pattern

### JSON API Controller
```cfm
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

## REST API with Error Handling

### Comprehensive API Controller
```cfm
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

    function show() {
        try {
            product = model("Product").findByKey(params.key);

            if (IsObject(product)) {
                renderWith(data={
                    product: product,
                    links: {
                        self: "#application.baseUrl#/api/products/#product.id#",
                        category: "#application.baseUrl#/api/categories/#product.categoryId#"
                    }
                });
            } else {
                renderWith(
                    data={
                        error: "Product not found",
                        code: "PRODUCT_NOT_FOUND"
                    },
                    status=404
                );
            }
        } catch (any e) {
            logApiError(e);
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

    private function logApiError(required any exception) {
        writeLog(
            file="api_errors",
            text="API Error: #arguments.exception.message# - Action: #params.controller#.#params.action#"
        );
    }

}
```

## API Authentication

### Token-Based Authentication
```cfm
component extends="Controller" {

    function config() {
        super.config();
        provides("json");
        filters(through="authenticateToken");
    }

    private function authenticateToken() {
        local.authHeader = getHttpRequestData().headers["Authorization"] ?: "";

        if (!len(local.authHeader) || !reFindNoCase("^Bearer\s+", local.authHeader)) {
            renderWith(
                data={error: "Missing or invalid Authorization header"},
                status=401
            );
            return;
        }

        local.token = reReplace(local.authHeader, "^Bearer\s+", "", "one");

        // Validate token
        local.user = validateApiToken(local.token);
        if (!IsObject(local.user)) {
            renderWith(
                data={error: "Invalid or expired token"},
                status=401
            );
            return;
        }

        // Set current user for this request
        variables.currentUser = local.user;
    }

    private function validateApiToken(required string token) {
        return model("User").findOne(
            where="apiToken = :token AND tokenExpiresAt > :now",
            params={
                token: arguments.token,
                now: now()
            }
        );
    }

}
```

### API Key Authentication
```cfm
component extends="Controller" {

    function config() {
        super.config();
        provides("json");
        filters(through="authenticateApiKey");
    }

    private function authenticateApiKey() {
        local.apiKey = params.apiKey ?: getHttpRequestData().headers["X-API-Key"] ?: "";

        if (!len(local.apiKey)) {
            renderWith(
                data={error: "API key required"},
                status=401
            );
            return;
        }

        local.client = model("ApiClient").findOne(where="apiKey = :key", params={key: local.apiKey});
        if (!IsObject(local.client) || !local.client.isActive) {
            renderWith(
                data={error: "Invalid API key"},
                status=401
            );
            return;
        }

        // Rate limiting check
        if (exceedsRateLimit(local.client)) {
            renderWith(
                data={error: "Rate limit exceeded"},
                status=429
            );
            return;
        }

        variables.apiClient = local.client;
    }

    private function exceedsRateLimit(required apiClient) {
        // Implement rate limiting logic
        return false;
    }

}
```

## JSON Request Handling

### Processing JSON Payloads
```cfm
function apiCreate() {
    // JSON body automatically parsed to params
    // Content-Type: application/json
    // {"product": {"name": "Laptop", "price": 999.99}}

    if (!StructKeyExists(params, "product")) {
        renderWith(
            data={error: "Missing product data"},
            status=400
        );
        return;
    }

    product = model("Product").create(params.product);

    if (product.hasErrors()) {
        renderWith(
            data={
                error: "Validation failed",
                errors: formatValidationErrors(product.allErrors())
            },
            status=422
        );
    } else {
        renderWith(
            data={
                product: product,
                message: "Product created successfully"
            },
            status=201
        );
    }
}

private function formatValidationErrors(required array errors) {
    local.formatted = {};

    for (local.error in arguments.errors) {
        if (!StructKeyExists(local.formatted, local.error.property)) {
            local.formatted[local.error.property] = [];
        }
        arrayAppend(local.formatted[local.error.property], local.error.message);
    }

    return local.formatted;
}
```

### Handling Different Content Types
```cfm
function flexibleCreate() {
    // Handle both JSON and form data
    local.contentType = getHttpRequestData().headers["Content-Type"] ?: "";

    if (findNoCase("application/json", local.contentType)) {
        // JSON payload
        if (!StructKeyExists(params, "product")) {
            renderWith(data={error: "Invalid JSON structure"}, status=400);
            return;
        }
    } else {
        // Form data or other content types
        if (!StructKeyExists(params, "product")) {
            renderWith(data={error: "Missing product data"}, status=400);
            return;
        }
    }

    product = model("Product").create(params.product);

    if (product.hasErrors()) {
        renderWith(data={errors: product.allErrors()}, status=422);
    } else {
        renderWith(data={product: product}, status=201);
    }
}
```

## API Response Formatting

### Consistent Response Structure
```cfm
function standardizedResponse() {
    products = model("Product").findAll(page=params.page ?: 1, perPage=10);

    response = {
        success = true,
        data = {
            products = products,
            meta = {
                total = products.totalRecords,
                page = products.currentPage,
                pages = products.pageCount,
                perPage = 10
            }
        },
        timestamp = now()
    };

    renderWith(data=response);
}

function standardizedError() {
    response = {
        success = false,
        error = {
            code = "VALIDATION_ERROR",
            message = "The provided data is invalid",
            details = product.allErrors()
        },
        timestamp = now()
    };

    renderWith(data=response, status=422);
}
```

### HATEOAS (Hypermedia as the Engine of Application State)
```cfm
function resourceWithLinks() {
    product = model("Product").findByKey(params.key);

    if (IsObject(product)) {
        response = {
            product = product,
            links = {
                self = "#application.baseUrl#/api/products/#product.id#",
                category = "#application.baseUrl#/api/categories/#product.categoryId#",
                reviews = "#application.baseUrl#/api/products/#product.id#/reviews",
                edit = "#application.baseUrl#/api/products/#product.id#",
                delete = "#application.baseUrl#/api/products/#product.id#"
            }
        };

        renderWith(data=response);
    } else {
        renderWith(data={error: "Not found"}, status=404);
    }
}
```

## API Versioning

### URL-Based Versioning
```cfm
// /app/controllers/api/v1/Products.cfc
component extends="wheels.Controller" {

    function config() {
        super.config();
        provides("json");
        filters(through="setApiVersion");
    }

    private function setApiVersion() {
        variables.apiVersion = "1.0";
        header name="API-Version" value=variables.apiVersion;
    }

    function index() {
        products = model("Product").findAll();

        // Version 1 response format
        renderWith(data={
            products: products,
            version: variables.apiVersion
        });
    }

}

// /app/controllers/api/v2/Products.cfc
component extends="wheels.Controller" {

    function config() {
        super.config();
        provides("json");
        filters(through="setApiVersion");
    }

    private function setApiVersion() {
        variables.apiVersion = "2.0";
        header name="API-Version" value=variables.apiVersion;
    }

    function index() {
        products = model("Product").findAll();

        // Version 2 response format (enhanced)
        renderWith(data={
            data: products,
            meta: {
                version: variables.apiVersion,
                total: products.totalRecords,
                links: {
                    self: "#application.baseUrl#/api/v2/products"
                }
            }
        });
    }

}
```

### Header-Based Versioning
```cfm
function config() {
    super.config();
    provides("json");
    filters(through="detectApiVersion");
}

private function detectApiVersion() {
    variables.apiVersion = getHttpRequestData().headers["Accept-Version"] ?: "1.0";
    header name="API-Version" value=variables.apiVersion;
}

function index() {
    products = model("Product").findAll();

    switch (variables.apiVersion) {
        case "1.0":
            renderWith(data={products: products});
            break;
        case "2.0":
            renderWith(data={
                data: products,
                meta: {version: "2.0", total: products.totalRecords}
            });
            break;
        default:
            renderWith(data={error: "Unsupported API version"}, status=400);
    }
}
```

## Error Handling and Status Codes

### HTTP Status Code Best Practices
```cfm
function restfulCreate() {
    product = model("Product").new(params.product);

    if (product.save()) {
        // 201 Created
        renderWith(data={product: product}, status=201);
    } else {
        // 422 Unprocessable Entity
        renderWith(data={errors: product.allErrors()}, status=422);
    }
}

function restfulShow() {
    product = model("Product").findByKey(params.key);

    if (IsObject(product)) {
        // 200 OK
        renderWith(data={product: product});
    } else {
        // 404 Not Found
        renderWith(data={error: "Product not found"}, status=404);
    }
}

function restfulDelete() {
    product = model("Product").findByKey(params.key);

    if (IsObject(product)) {
        product.delete();
        // 204 No Content
        renderNothing(status=204);
    } else {
        // 404 Not Found
        renderWith(data={error: "Product not found"}, status=404);
    }
}
```

### Comprehensive Error Responses
```cfm
function handleApiError(required any exception) {
    local.errorResponse = {
        error = {
            type = arguments.exception.type ?: "UnknownError",
            message = arguments.exception.message ?: "An unexpected error occurred",
            timestamp = now()
        }
    };

    // Add stack trace in development
    if (application.environment == "development") {
        local.errorResponse.error.detail = arguments.exception.detail ?: "";
        local.errorResponse.error.stackTrace = arguments.exception.stackTrace ?: "";
    }

    // Determine status code based on error type
    local.statusCode = 500;
    switch (arguments.exception.type) {
        case "ValidationError":
            local.statusCode = 422;
            break;
        case "NotFound":
            local.statusCode = 404;
            break;
        case "Unauthorized":
            local.statusCode = 401;
            break;
        case "Forbidden":
            local.statusCode = 403;
            break;
    }

    renderWith(data=local.errorResponse, status=local.statusCode);
}
```

## API Documentation and Testing

### Self-Documenting Endpoints
```cfm
function apiInfo() {
    endpoints = {
        products = {
            list = "GET /api/products",
            show = "GET /api/products/{id}",
            create = "POST /api/products",
            update = "PUT /api/products/{id}",
            delete = "DELETE /api/products/{id}"
        },
        categories = {
            list = "GET /api/categories",
            show = "GET /api/categories/{id}"
        }
    };

    renderWith(data={
        api = "Products API",
        version = "1.0",
        endpoints = endpoints,
        documentation = "#application.baseUrl#/api/docs"
    });
}
```

### Health Check Endpoint
```cfm
function health() {
    local.health = {
        status = "ok",
        timestamp = now(),
        version = application.version ?: "1.0",
        environment = application.environment
    };

    // Check database connectivity
    try {
        model("Product").count();
        local.health.database = "connected";
    } catch (any e) {
        local.health.database = "error";
        local.health.status = "error";
    }

    renderWith(data=local.health);
}
```

## Rate Limiting

### Basic Rate Limiting
```cfm
function config() {
    super.config();
    provides("json");
    filters(through="rateLimiting");
}

private function rateLimiting() {
    local.clientId = variables.apiClient.id ?: "anonymous";
    local.cacheKey = "rate_limit_#local.clientId#";
    local.requestCount = cacheGet(local.cacheKey) ?: 0;
    local.limit = 100; // 100 requests per hour

    if (local.requestCount >= local.limit) {
        header name="X-RateLimit-Limit" value=local.limit;
        header name="X-RateLimit-Remaining" value=0;
        renderWith(
            data={error: "Rate limit exceeded"},
            status=429
        );
        return;
    }

    // Increment counter
    cachePut(local.cacheKey, local.requestCount + 1, createTimeSpan(0, 1, 0, 0)); // 1 hour

    // Add rate limit headers
    header name="X-RateLimit-Limit" value=local.limit;
    header name="X-RateLimit-Remaining" value=(local.limit - local.requestCount - 1);
}
```

## CORS Support

### Comprehensive CORS Handling
```cfm
function config() {
    super.config();
    provides("json");
    filters(through="handleCors");
}

private function handleCors() {
    // Set CORS headers
    header name="Access-Control-Allow-Origin" value="*";
    header name="Access-Control-Allow-Methods" value="GET,POST,PUT,DELETE,OPTIONS";
    header name="Access-Control-Allow-Headers" value="Content-Type,Authorization,X-API-Key";
    header name="Access-Control-Max-Age" value="86400"; // 24 hours

    // Handle preflight requests
    if (cgi.request_method == "OPTIONS") {
        renderNothing(status=204);
    }
}
```

## API Testing

### Testing API Endpoints
```cfm
// In test file
function testApiIndex() {
    params = {
        controller: "api.products",
        action: "index",
        format: "json"
    };

    result = processAction(params);

    assert("result.statusCode == 200");
    assert("isJSON(result.content)");

    data = deserializeJSON(result.content);
    assert("StructKeyExists(data, 'products')");
}

function testApiCreateWithValidData() {
    params = {
        controller: "api.products",
        action: "create",
        format: "json",
        product: {
            name: "Test Product",
            price: 99.99
        }
    };

    result = processAction(params);

    assert("result.statusCode == 201");

    data = deserializeJSON(result.content);
    assert("StructKeyExists(data, 'product')");
    assert("data.product.name == 'Test Product'");
}

function testApiCreateWithInvalidData() {
    params = {
        controller: "api.products",
        action: "create",
        format: "json",
        product: {
            name: "" // Invalid - name required
        }
    };

    result = processAction(params);

    assert("result.statusCode == 422");

    data = deserializeJSON(result.content);
    assert("StructKeyExists(data, 'errors')");
}
```

## Best Practices

### 1. Use Appropriate HTTP Methods and Status Codes
```cfm
// GET for reading
function index() { /* 200 OK */ }
function show() { /* 200 OK or 404 Not Found */ }

// POST for creating
function create() { /* 201 Created or 422 Unprocessable Entity */ }

// PUT/PATCH for updating
function update() { /* 200 OK or 422 Unprocessable Entity */ }

// DELETE for removing
function delete() { /* 204 No Content or 404 Not Found */ }
```

### 2. Consistent Error Format
```cfm
// Always return errors in same format
{
    "error": {
        "code": "VALIDATION_ERROR",
        "message": "Validation failed",
        "details": {...}
    }
}
```

### 3. Include Pagination Metadata
```cfm
{
    "data": [...],
    "meta": {
        "page": 1,
        "pages": 10,
        "total": 250,
        "perPage": 25
    }
}
```

### 4. Version Your APIs
```cfm
// URL versioning
/api/v1/products
/api/v2/products

// Header versioning
Accept-Version: 1.0
```

### 5. Implement Rate Limiting
```cfm
// Return rate limit headers
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

## Related Documentation
- [Controller Architecture](./architecture.md)
- [Controller Security](./security.md)
- [Controller Rendering](./rendering.md)
- [Authentication Patterns](../security/authentication.md)