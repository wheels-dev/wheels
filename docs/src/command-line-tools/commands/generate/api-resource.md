# wheels generate api-resource (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Generate a complete API resource with model, API controller, and routes.

> ⚠️ **Note**: This command is currently marked as broken/disabled in the codebase. The documentation below represents the intended functionality when the command is restored.

## Synopsis

```bash
wheels generate api-resource [name] [properties] [options]
wheels g api-resource [name] [properties] [options]
```

## Description

The `wheels generate api-resource` command creates a complete RESTful API resource including model, API-specific controller (no views), routes, and optionally database migrations and tests. It's optimized for building JSON APIs following REST conventions.

## Current Status

**This command is temporarily disabled.** Use alternative approaches:

```bash
# Option 1: Use regular resource with --api flag
wheels generate resource product name:string price:float --api

# Option 2: Generate components separately
wheels generate model product name:string price:float
wheels generate controller api/products --api
wheels generate route products --api --namespace=api
```

## Arguments (When Enabled)

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Resource name (typically singular) | Required |
| `properties` | Property definitions (name:type) | |

## Options (When Enabled)

| Option | Description | Default |
|--------|-------------|---------|
| `--version` | API version (v1, v2, etc.) | `v1` |
| `--format` | Response format (json, xml) | `json` |
| `--auth` | Include authentication | `false` |
| `--pagination` | Include pagination | `true` |
| `--filtering` | Include filtering | `true` |
| `--sorting` | Include sorting | `true` |
| `--skip-model` | Skip model generation | `false` |
| `--skip-migration` | Skip migration generation | `false` |
| `--skip-tests` | Skip test generation | `false` |
| `--namespace` | API namespace | `api` |
| `--force` | Overwrite existing files | `false` |
| `--help` | Show help information | |

## Intended Functionality

### Basic API Resource
```bash
wheels generate api-resource product name:string price:float description:text
```

Would generate:
- Model: `/models/Product.cfc`
- Controller: `/controllers/api/v1/Products.cfc`
- Route: API namespace with versioning
- Migration: Database migration file
- Tests: API integration tests

### Generated API Controller
`/controllers/api/v1/Products.cfc`:
```cfc
component extends="Controller" {
    
    function init() {
        provides("json");
        
        // Filters
        filters(through="authenticate", except="index,show");
        filters(through="findProduct", only="show,update,delete");
        filters(through="parseApiParams", only="index");
    }
    
    function index() {
        // Pagination
        page = params.page ?: 1;
        perPage = Min(params.perPage ?: 25, 100);
        
        // Filtering
        where = [];
        if (StructKeyExists(params, "filter")) {
            if (StructKeyExists(params.filter, "name")) {
                ArrayAppend(where, "name LIKE :name");
                params.name = "%#params.filter.name#%";
            }
            if (StructKeyExists(params.filter, "minPrice")) {
                ArrayAppend(where, "price >= :minPrice");
                params.minPrice = params.filter.minPrice;
            }
        }
        
        // Sorting
        order = "createdAt DESC";
        if (StructKeyExists(params, "sort")) {
            order = parseSort(params.sort);
        }
        
        // Query
        products = model("Product").findAll(
            where=ArrayToList(where, " AND "),
            order=order,
            page=page,
            perPage=perPage,
            returnAs="objects"
        );
        
        // Response
        renderWith({
            data: serializeProducts(products),
            meta: {
                pagination: {
                    page: products.currentPage,
                    perPage: products.perPage,
                    total: products.totalRecords,
                    pages: products.totalPages
                }
            },
            links: {
                self: urlFor(route="apiV1Products", params=params),
                first: urlFor(route="apiV1Products", params=params, page=1),
                last: urlFor(route="apiV1Products", params=params, page=products.totalPages),
                prev: products.currentPage > 1 ? urlFor(route="apiV1Products", params=params, page=products.currentPage-1) : "",
                next: products.currentPage < products.totalPages ? urlFor(route="apiV1Products", params=params, page=products.currentPage+1) : ""
            }
        });
    }
    
    function show() {
        renderWith({
            data: serializeProduct(product),
            links: {
                self: urlFor(route="apiV1Product", key=product.id)
            }
        });
    }
    
    function create() {
        product = model("Product").new(deserializeProduct(params));
        
        if (product.save()) {
            renderWith(
                data={
                    data: serializeProduct(product),
                    links: {
                        self: urlFor(route="apiV1Product", key=product.id)
                    }
                },
                status=201,
                headers={"Location": urlFor(route="apiV1Product", key=product.id)}
            );
        } else {
            renderWith(
                data={
                    errors: formatErrors(product.allErrors())
                },
                status=422
            );
        }
    }
    
    function update() {
        if (product.update(deserializeProduct(params))) {
            renderWith({
                data: serializeProduct(product),
                links: {
                    self: urlFor(route="apiV1Product", key=product.id)
                }
            });
        } else {
            renderWith(
                data={
                    errors: formatErrors(product.allErrors())
                },
                status=422
            );
        }
    }
    
    function delete() {
        if (product.delete()) {
            renderWith(data={}, status=204);
        } else {
            renderWith(
                data={
                    errors: [{
                        status: "400",
                        title: "Bad Request",
                        detail: "Could not delete product"
                    }]
                },
                status=400
            );
        }
    }
    
    // Private methods
    
    private function findProduct() {
        product = model("Product").findByKey(params.key);
        if (!IsObject(product)) {
            renderWith(
                data={
                    errors: [{
                        status: "404",
                        title: "Not Found",
                        detail: "Product not found"
                    }]
                },
                status=404
            );
        }
    }
    
    private function authenticate() {
        if (!StructKeyExists(headers, "Authorization")) {
            renderWith(
                data={
                    errors: [{
                        status: "401",
                        title: "Unauthorized",
                        detail: "Missing authentication"
                    }]
                },
                status=401
            );
        }
        // Implement authentication logic
    }
    
    private function parseApiParams() {
        // Parse JSON API params
        if (StructKeyExists(params, "_json")) {
            StructAppend(params, params._json, true);
        }
    }
    
    private function parseSort(required string sort) {
        local.allowedFields = ["name", "price", "createdAt"];
        local.parts = ListToArray(arguments.sort);
        local.order = [];
        
        for (local.part in local.parts) {
            local.desc = Left(local.part, 1) == "-";
            local.field = local.desc ? Right(local.part, Len(local.part)-1) : local.part;
            
            if (ArrayFindNoCase(local.allowedFields, local.field)) {
                ArrayAppend(local.order, local.field & (local.desc ? " DESC" : " ASC"));
            }
        }
        
        return ArrayToList(local.order);
    }
    
    private function serializeProducts(required array products) {
        local.result = [];
        for (local.product in arguments.products) {
            ArrayAppend(local.result, serializeProduct(local.product));
        }
        return local.result;
    }
    
    private function serializeProduct(required any product) {
        return {
            type: "products",
            id: arguments.product.id,
            attributes: {
                name: arguments.product.name,
                price: arguments.product.price,
                description: arguments.product.description,
                createdAt: DateTimeFormat(arguments.product.createdAt, "iso"),
                updatedAt: DateTimeFormat(arguments.product.updatedAt, "iso")
            },
            links: {
                self: urlFor(route="apiV1Product", key=arguments.product.id)
            }
        };
    }
    
    private function deserializeProduct(required struct data) {
        if (StructKeyExists(arguments.data, "data")) {
            return arguments.data.data.attributes;
        }
        return arguments.data;
    }
    
    private function formatErrors(required array errors) {
        local.result = [];
        for (local.error in arguments.errors) {
            ArrayAppend(local.result, {
                status: "422",
                source: {pointer: "/data/attributes/#local.error.property#"},
                title: "Validation Error",
                detail: local.error.message
            });
        }
        return local.result;
    }
    
}
```

### API Routes
Generated in `/config/routes.cfm`:
```cfm
<cfset namespace("api")>
    <cfset namespace("v1")>
        <cfset resources(name="products", except="new,edit")>
        
        <!--- Additional API routes --->
        <cfset post(pattern="products/[key]/activate", to="products##activate", on="member")>
        <cfset get(pattern="products/search", to="products##search", on="collection")>
    </cfset>
</cfset>
```

### API Documentation
Would generate OpenAPI/Swagger documentation:

```yaml
openapi: 3.0.0
info:
  title: Products API
  version: 1.0.0
  
paths:
  /api/v1/products:
    get:
      summary: List products
      parameters:
        - name: page
          in: query
          schema:
            type: integer
        - name: perPage
          in: query
          schema:
            type: integer
        - name: filter[name]
          in: query
          schema:
            type: string
        - name: sort
          in: query
          schema:
            type: string
      responses:
        200:
          description: Success
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ProductList'
    
    post:
      summary: Create product
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ProductInput'
      responses:
        201:
          description: Created
        422:
          description: Validation error
```

## Workaround Implementation

Until the command is fixed, implement API resources manually:

### 1. Generate Model
```bash
wheels generate model product name:string price:float description:text
```

### 2. Create API Controller
Create `/controllers/api/v1/Products.cfc` manually with the code above.

### 3. Add Routes
```cfm
<!--- In /config/routes.cfm --->
<cfset namespace("api")>
    <cfset namespace("v1")>
        <cfset resources(name="products", except="new,edit")>
    </cfset>
</cfset>
```

### 4. Create Tests
```bash
wheels generate test controller api/v1/products
```

## API Features

### Authentication
```cfc
// Bearer token authentication
private function authenticate() {
    local.token = GetHttpRequestData().headers["Authorization"] ?: "";
    local.token = ReReplace(local.token, "^Bearer\s+", "");
    
    if (!Len(local.token) || !isValidToken(local.token)) {
        renderWith(
            data={error: "Unauthorized"},
            status=401
        );
    }
}
```

### Rate Limiting
```cfc
// In controller init()
filters(through="rateLimit");

private function rateLimit() {
    local.key = "api_rate_limit_" & request.remoteAddress;
    local.limit = 100; // requests per hour
    
    if (!StructKeyExists(application, local.key)) {
        application[local.key] = {
            count: 0,
            reset: DateAdd("h", 1, Now())
        };
    }
    
    if (application[local.key].reset < Now()) {
        application[local.key] = {
            count: 0,
            reset: DateAdd("h", 1, Now())
        };
    }
    
    application[local.key].count++;
    
    if (application[local.key].count > local.limit) {
        renderWith(
            data={error: "Rate limit exceeded"},
            status=429,
            headers={
                "X-RateLimit-Limit": local.limit,
                "X-RateLimit-Remaining": 0,
                "X-RateLimit-Reset": DateTimeFormat(application[local.key].reset, "iso")
            }
        );
    }
}
```

### CORS Headers
```cfc
// In controller init()
filters(through="setCorsHeaders");

private function setCorsHeaders() {
    header name="Access-Control-Allow-Origin" value="*";
    header name="Access-Control-Allow-Methods" value="GET, POST, PUT, DELETE, OPTIONS";
    header name="Access-Control-Allow-Headers" value="Content-Type, Authorization";
    
    if (request.method == "OPTIONS") {
        renderWith(data={}, status=200);
    }
}
```

## Testing API Resources

### Integration Tests
```cfc
component extends="wheels.Test" {
    
    function setup() {
        super.setup();
        model("Product").deleteAll();
    }
    
    function test_get_products_returns_json() {
        products = createProducts(3);
        
        result = $request(
            route="apiV1Products",
            method="GET",
            headers={"Accept": "application/json"}
        );
        
        assert(result.status == 200);
        data = DeserializeJSON(result.body);
        assert(ArrayLen(data.data) == 3);
        assert(data.meta.pagination.total == 3);
    }
    
    function test_create_product_with_valid_data() {
        params = {
            data: {
                type: "products",
                attributes: {
                    name: "Test Product",
                    price: 29.99,
                    description: "Test description"
                }
            }
        };
        
        result = $request(
            route="apiV1Products",
            method="POST",
            params=params,
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json"
            }
        );
        
        assert(result.status == 201);
        assert(StructKeyExists(result.headers, "Location"));
        data = DeserializeJSON(result.body);
        assert(data.data.attributes.name == "Test Product");
    }
    
    function test_authentication_required() {
        result = $request(
            route="apiV1Products",
            method="POST",
            params={},
            headers={"Accept": "application/json"}
        );
        
        assert(result.status == 401);
    }
    
}
```

## Best Practices

1. **Version your API**: Use URL versioning (/api/v1/)
2. **Use consistent formats**: JSON API or custom format
3. **Include pagination**: Limit response sizes
4. **Add filtering**: Allow query parameters
5. **Implement sorting**: Support field sorting
6. **Handle errors consistently**: Standard error format
7. **Document thoroughly**: OpenAPI/Swagger specs
8. **Add authentication**: Secure endpoints
9. **Rate limit**: Prevent abuse
10. **Test extensively**: Integration tests

## See Also

- [wheels generate resource](resource.md) - Generate full resources
- [wheels generate controller](controller.md) - Generate controllers
- [wheels generate model](model.md) - Generate models
- [wheels generate route](route.md) - Generate routes