# wheels generate api-resource

Generate a complete RESTful API controller with advanced features like pagination, filtering, sorting, and authentication.

## Synopsis

```bash
wheels generate api-resource [name] [options]
wheels g api-resource [name] [options]
```

## Description

The `wheels generate api-resource` command creates a production-ready RESTful API controller optimized for JSON APIs. It generates API-specific controllers with no view rendering logic, including optional features like pagination, filtering, sorting, authentication, and API versioning.

The generated controllers use `provides("json")` and `renderWith()` to return JSON responses with proper HTTP status codes for REST operations.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Resource name (singular or plural) | Required |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--version` | API version (v1, v2, etc.) | `v1` |
| `--format` | Response format (json, xml) | `json` |
| `--auth` | Include authentication | `false` |
| `--pagination` | Include pagination | `true` |
| `--filtering` | Include filtering | `true` |
| `--sorting` | Include sorting | `true` |
| `--skipModel` | Skip model generation | `false` |
| `--skipMigration` | Skip migration generation | `false` |
| `--skipTests` | Skip test generation | `false` |
| `--namespace` | API namespace | `api` |
| `--docs` | Generate API documentation template | `false` |
| `--force` | Overwrite existing files | `false` |

## Examples

### Basic API Controller

Generate a simple API controller:

```bash
wheels generate api-resource products
```

Creates:
- `/models/Product.cfc` - Model file
- `/controllers/api/v1/Products.cfc` - Versioned API controller with pagination, filtering, sorting

### Without Advanced Features

Generate a minimal API controller:

```bash
wheels generate api-resource products --pagination=false --filtering=false --sorting=false
```

Creates a simple controller with only basic CRUD operations.

### With Authentication

Generate API controller with authentication:

```bash
wheels generate api-resource products --auth
```

Includes Bearer token authentication that requires Authorization header for create, update, delete actions.

### Custom Version and Namespace

Generate API controller with custom versioning:

```bash
wheels generate api-resource products --version=v2 --namespace=api
```

Creates `/controllers/api/v2/Products.cfc`

### Skip Model Generation

Generate only the controller (model already exists):

```bash
wheels generate api-resource products --skipModel
```

### Complete Setup with Documentation

Generate everything with API documentation:

```bash
wheels generate api-resource products --auth --docs
```

Creates:
- `/models/Product.cfc`
- `/controllers/api/v1/Products.cfc` with authentication
- `/app/docs/api/products.md` - API documentation

## Generated Controller Features

### With All Features Enabled

```bash
wheels generate api-resource products --auth --pagination --filtering --sorting
```

Generates:

```cfc
component extends="wheels.Controller" {

    function config() {
        provides("json");
        filters(through="setJsonResponse");
        filters(through="authenticate", except="index,show");
    }

    /**
     * GET /products
     * Supports: ?page=1&perPage=25&sort=name,-price&filter[name]=widget
     */
    function index() {
        local.page = params.page ?: 1;
        local.perPage = params.perPage ?: 25;
        local.options = {};
        local.options.page = local.page;
        local.options.perPage = local.perPage;

        if (structKeyExists(params, "sort")) {
            local.options.order = parseSort(params.sort);
        }

        if (structKeyExists(params, "filter")) {
            local.options.where = parseFilter(params.filter);
        }

        local.products = model("Product").findAll(argumentCollection=local.options);

        local.response = {
            data = local.products,
            meta = {
                pagination = {
                    page = local.products.currentPage ?: local.page,
                    perPage = local.perPage,
                    total = local.products.totalRecords ?: 0,
                    pages = local.products.totalPages ?: 1
                }
            }
        };

        renderWith(data=local.response);
    }

    function show() { /* ... */ }
    function create() { /* ... */ }
    function update() { /* ... */ }
    function delete() { /* ... */ }

    // Helper methods for pagination, filtering, sorting, auth
    private function authenticate() { /* ... */ }
    private function parseSort(required string sort) { /* ... */ }
    private function parseFilter(required struct filter) { /* ... */ }
}
```

## Adding Routes

After generating your API resource, add routes to `/config/routes.cfm`:

### Default Namespaced Routes

```cfm
// Add inside mapper() block
namespace(name="api", function() {
    namespace(name="v1", function() {
        resources(name="products", except="new,edit");
    });
});
```

Creates routes:
- `GET /api/v1/products`
- `GET /api/v1/products/:key`
- `POST /api/v1/products`
- `PUT /api/v1/products/:key`
- `DELETE /api/v1/products/:key`

### Custom Version

```cfm
namespace(name="api", function() {
    namespace(name="v2", function() {
        resources(name="products", except="new,edit");
    });
});
```

### No Namespace

If you used `--namespace=""`:

```cfm
resources(name="products", except="new,edit");
```

## Feature Details

### Pagination

When `--pagination` is enabled (default):

**Request:**
```bash
curl "http://localhost:8080/api/v1/products?page=2&perPage=10"
```

**Response:**
```json
{
  "data": [ /* products */ ],
  "meta": {
    "pagination": {
      "page": 2,
      "perPage": 10,
      "total": 100,
      "pages": 10
    }
  }
}
```

### Filtering

When `--filtering` is enabled (default):

**Request:**
```bash
curl "http://localhost:8080/api/v1/products?filter[name]=widget&filter[minPrice]=10"
```

The generated controller includes a `parseFilter()` method with TODO comments for you to implement your filtering logic.

### Sorting

When `--sorting` is enabled (default):

**Request:**
```bash
# Sort by name ascending, then price descending
curl "http://localhost:8080/api/v1/products?sort=name,-price"
```

The `-` prefix indicates descending order.

### Authentication

When `--auth` is enabled:

**Request:**
```bash
curl -X POST http://localhost:8080/api/v1/products \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"product":{"name":"Widget"}}'
```

The generated controller includes authentication methods that you need to implement with your actual token validation logic.

## HTTP Status Codes

The generated controller uses proper REST HTTP status codes:

| Action | Success Status | Error Status |
|--------|---------------|--------------|
| `index` | 200 OK | - |
| `show` | 200 OK | 404 Not Found |
| `create` | 201 Created | 422 Unprocessable Entity |
| `update` | 200 OK | 404 Not Found, 422 Unprocessable Entity |
| `delete` | 204 No Content | 404 Not Found |
| `auth failure` | - | 401 Unauthorized |

## Testing Your API

### Basic Requests

```bash
# List products with pagination
curl "http://localhost:8080/api/v1/products?page=1&perPage=25"

# Get specific product
curl http://localhost:8080/api/v1/products/1

# Create product
curl -X POST http://localhost:8080/api/v1/products \
  -H "Content-Type: application/json" \
  -d '{"product":{"name":"Widget","price":29.99}}'

# Update product
curl -X PUT http://localhost:8080/api/v1/products/1 \
  -H "Content-Type: application/json" \
  -d '{"product":{"price":39.99}}'

# Delete product
curl -X DELETE http://localhost:8080/api/v1/products/1
```

### With Filtering and Sorting

```bash
# Filter and sort
curl "http://localhost:8080/api/v1/products?filter[name]=widget&sort=-createdAt"

# Pagination with filters
curl "http://localhost:8080/api/v1/products?page=1&perPage=10&filter[minPrice]=20&sort=name"
```

### With Authentication

```bash
# With Bearer token
curl -X POST http://localhost:8080/api/v1/products \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"product":{"name":"Widget"}}'
```

## Example Responses

**Success with Pagination (200 OK):**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Widget",
      "price": 29.99,
      "createdAt": "2023-01-01T12:00:00Z",
      "updatedAt": "2023-01-01T12:00:00Z"
    }
  ],
  "meta": {
    "pagination": {
      "page": 1,
      "perPage": 25,
      "total": 1,
      "pages": 1
    }
  }
}
```

**Validation Error (422):**
```json
{
  "error": "Validation failed",
  "errors": [
    {
      "property": "name",
      "message": "This field is required"
    }
  ]
}
```

**Not Found (404):**
```json
{
  "error": "Record not found"
}
```

**Unauthorized (401):**
```json
{
  "error": "Unauthorized"
}
```

## Customization

### Implementing Filter Logic

Edit the generated `parseFilter()` method:

```cfm
private function parseFilter(required struct filter) {
    local.where = [];
    local.params = {};

    if (structKeyExists(arguments.filter, "name")) {
        arrayAppend(local.where, "name LIKE :name");
        local.params.name = "%#arguments.filter.name#%";
    }

    if (structKeyExists(arguments.filter, "minPrice")) {
        arrayAppend(local.where, "price >= :minPrice");
        local.params.minPrice = arguments.filter.minPrice;
    }

    if (structKeyExists(arguments.filter, "category")) {
        arrayAppend(local.where, "category = :category");
        local.params.category = arguments.filter.category;
    }

    return arrayLen(local.where) ? arrayToList(local.where, " AND ") : "";
}
```

### Implementing Authentication

Edit the generated `isValidToken()` method:

```cfm
private function isValidToken(required string token) {
    // Example: Check against database
    local.apiKey = model("ApiKey").findOne(where="token = :token", token=arguments.token);

    if (isObject(local.apiKey) && local.apiKey.active) {
        // Store user context in session/request
        request.user = local.apiKey.user();
        return true;
    }

    return false;
}
```

### Adding More Sortable Fields

Edit the `parseSort()` method:

```cfm
private function parseSort(required string sort) {
    local.allowedFields = ["id", "name", "price", "category", "createdAt", "updatedAt"];
    // ... rest of method
}
```

## Best Practices

1. **Use Versioning**: Always version your APIs (`--version=v1`)
2. **Enable Pagination**: Prevent performance issues with large datasets
3. **Add Authentication**: Secure your API endpoints with `--auth`
4. **Document Your API**: Use `--docs` flag and keep documentation updated
5. **Implement Filtering**: Customize `parseFilter()` for your model fields
6. **Whitelist Sort Fields**: Only allow sorting on indexed fields
7. **Use Proper Status Codes**: 201 for creation, 204 for deletion
8. **Return Error Details**: Always include error messages for 4xx/5xx
9. **Rate Limiting**: Consider adding rate limiting for public APIs
10. **CORS Headers**: Add CORS support for browser-based clients

## Comparison with Other Commands

| Feature | `api-resource` | `controller --api` | `scaffold` |
|---------|----------------|-------------------|------------|
| Generates model | Optional | No | Yes |
| Generates views | No | No | Yes |
| Actions | REST only | REST only | Full CRUD |
| Format | Configurable | JSON only | HTML + JSON |
| Versioning | Yes | No | No |
| Pagination | Optional | No | No |
| Filtering | Optional | No | No |
| Sorting | Optional | No | No |
| Authentication | Optional | No | No |
| Best for | Production APIs | Simple APIs | Full-stack apps |

## See Also

- [wheels generate controller](controller.md) - Generate standard controllers
- [wheels generate model](model.md) - Generate models
- [wheels generate scaffold](scaffold.md) - Generate full CRUD resources
- [Wheels REST Documentation](https://wheels.dev) - REST API best practices
