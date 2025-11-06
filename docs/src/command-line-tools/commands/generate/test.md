# wheels generate test

Generate test files for models, controllers, views, and other components using TestBox BDD syntax.

## Synopsis

```bash
wheels generate test [type] [target] [options]
wheels g test [type] [target] [options]
```

## CommandBox Parameter Syntax

This command supports multiple parameter formats:

- **Positional parameters**: `wheels generate test model User` (most common)
- **Named parameters**: `type=value target=value` (e.g., `type=model target=User`)
- **Flag parameters**: `--flag` equals `flag=true` (e.g., `--crud` equals `crud=true`)

**Parameter Mixing Rules:**

**ALLOWED:**
- All positional: `wheels generate test model User`
- All positional + flags: `wheels generate test model User --crud --factory`
- All named: `type=model target=User crud=true`

**NOT ALLOWED:**
- Positional + named: `wheels generate test model target=User` (causes error)

**Recommendation:** Use positional for type/target, flags for options: `wheels generate test model User --crud --factory`

## Description

The `wheels generate test` command creates test files for various components of your Wheels application using TestBox 6 BDD syntax. All generated tests use standard CFML `cfhttp()` for HTTP testing and proper Wheels `model()` syntax, ensuring compatibility and reliability.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `type` | Type of test: `model`, `controller`, `view`, `unit`, `integration`, `api` | Required |
| `target` | Name of the component/object to test | Required |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--name` | Name of the view (required for view tests) | `""` |
| `--crud` | Generate CRUD test methods (create, read, update, delete) | `false` |
| `--mock` | Generate mock/stub examples (for unit tests) | `false` |
| `--factory` | Generate factory examples using `model().create()` pattern | `false` |
| `--force` | Overwrite existing files without prompting | `false` |
| `--open` | Open the created file in default editor | `false` |

## Test Types

The command generates different test structures based on the type:

| Type | Location | Purpose | Testing Method |
|------|----------|---------|----------------|
| `model` | `/tests/specs/models/` | Model validations, associations, callbacks, custom methods | Direct model instantiation |
| `controller` | `/tests/specs/controllers/` | Controller actions via HTTP requests | `cfhttp()` requests |
| `view` | `/tests/specs/views/` | View rendering via HTTP requests | `cfhttp()` requests |
| `unit` | `/tests/specs/unit/` | Service/library components with custom logic | Direct component instantiation |
| `integration` | `/tests/specs/integration/` | End-to-end workflow tests | `cfhttp()` requests |
| `api` | `/tests/specs/integration/api/` | API endpoints with JSON request/response | `cfhttp()` with JSON |

## Examples

### Model Tests

```bash
# Basic model test
wheels generate test model User
```

**Output:** `tests/specs/models/UserSpec.cfc`

**Generated Code:**
```cfc
component extends="wheels.Testbox" {

    function run() {

        describe("User Model", function() {

            beforeEach(function() {
                variables.user = model("User").new();
            });

            it("should validate required fields", function() {
                expect(user.valid()).toBe(false);
                // Add specific field validations here
            });

            it("should have expected associations", function() {
                // Test your model associations here
                // Example: expect(isObject(user)).toBe(true);
            });

            it("should test custom model methods", function() {
                // Test custom model methods here
            });
        });
    }
}
```

### Model Test with CRUD Operations

Generate a model test with create, read, update, delete operations:

```bash
# With CRUD operations
wheels generate test model Product --crud
```

**Output:** `tests/specs/models/ProductSpec.cfc`

**Contains:**
- Basic validation tests
- `it("should create a new product")` - Tests `model().new()` and `save()`
- `it("should find an existing product")` - Tests `findByKey()`
- `it("should update an existing product")` - Tests property updates and `save()`
- `it("should delete a product")` - Tests `delete()` method

**Sample CRUD Test:**
```cfc
it("should create a new product", function() {
    product.name = "Test Product";
    expect(product.save()).toBe(true);
    var newProduct = product;
    expect(newProduct.id).toBeGT(0);
});
```

# With factory pattern for test data
```bash
wheels generate test model Order --crud --factory
```

**Output:** `tests/specs/models/UserSpec.cfc`

**Generated Code:**
```cfc
beforeEach(function() {
    // Factory pattern: create reusable test data with sensible defaults
    variables.order = model("Order").new({
        // Add default test attributes here
    });
});

it("should create a new order", function() {
    var newOrder = model("Order").create({
        // Add test attributes
    });
    expect(newOrder.id).toBeGT(0);
});
```

**Key Features:**
- Validation testing with `model().new()` and `valid()`
- Association testing
- CRUD operations: `model().create()`, `findByKey()`, `save()`, `delete()` (with `--crud`)
- Factory pattern for reusable test data (with `--factory`)

### Controller Tests

```bash
# Basic controller test
wheels generate test controller Users
```

**Output:** `tests/specs/controllers/UsersControllerSpec.cfc`

**Generated Code:**
```cfc
component extends="wheels.Testbox" {

    function beforeAll() {
        variables.baseUrl = "http://localhost:8080";
    }

    function run() {

        describe("Users Controller", function() {

            it("should respond to index request", function() {
                cfhttp(url = "#variables.baseUrl#/users", method = "GET", result = "response");
                expect(response.status_code).toBe(200);
                // Add more specific assertions for your controller actions
            });
        });
    }
}
```

# With CRUD actions
```bash
wheels generate test controller Products --crud
```

**Output:** `tests/specs/controllers/UsersControllerSpec.cfc`

**Contains:**
- `it("should list all products (index action)")` - Tests GET `/products`
- `it("should display a specific product (show action)")` - Tests GET `/products/:id`
- `it("should create a new product (create action)")` - Tests POST `/products`
- `it("should update an existing product (update action)")` - Tests PUT `/products/:id`
- `it("should delete a product")` - Tests DELETE `/products/:id`

**Sample Controller Test:**
```cfc
it("should list all products (index action)", function() {
    cfhttp(url = "#variables.baseUrl#/products", method = "GET", result = "response");
    expect(response.status_code).toBe(200);
    expect(response.filecontent).toInclude("Products");
});

it("should create a new product (create action)", function() {
    cfhttp(url = "#variables.baseUrl#/products", method = "POST", result = "response") {
        cfhttpparam(type = "formfield", name = "product[name]", value = "Test Product");
        // Add more form fields as needed
    }
    expect(response.status_code).toBe(302); // Redirect on success
});
```

**Key Features:**
- HTTP-based testing using `cfhttp()`
- Tests for index, show, create, update, delete actions (with `--crud`)
- Response status code assertions
- Content verification

### View Tests

```bash
# View rendering test
wheels generate test view users edit
```

**Output:** `tests/specs/views/users/editViewSpec.cfc`

**Generated Code:**
```cfc
component extends="wheels.Testbox" {

    function beforeAll() {
        variables.baseUrl = "http://localhost:8080";
    }

    function run() {

        describe("Users edit View", function() {

            it("should render edit view without errors", function() {
                // Test view rendering via HTTP request
                cfhttp(url = "#variables.baseUrl#/users/edit", method = "GET", result = "response");
                expect(response.status_code).toBe(200);
                expect(response.filecontent).toInclude("Users");
            });

            it("should display required HTML elements", function() {
                cfhttp(url = "#variables.baseUrl#/users/edit", method = "GET", result = "response");
                // Add specific HTML element assertions
                // expect(response.filecontent).toInclude("<form");
                // expect(response.filecontent).toInclude("<input");
            });
        });
    }
}
```

**Key Features:**
- HTTP-based rendering tests
- Status code verification
- HTML content assertions

### Unit Tests

```bash
# Basic unit test
wheels generate test unit OrderProcessor
```

**Output:** `tests/specs/unit/OrderProcessorSpec.cfc`

**Generated Code:**
```cfc
component extends="wheels.Testbox" {

    function run() {

        describe("OrderProcessor Unit Tests", function() {

            it("should test orderprocessor functionality", function() {
                // Create your service/component to test
                // var service = new app.lib.OrderProcessorService();
                // Test your service methods here
                // expect(service.someMethod()).toBe(expectedValue);
            });

            it("should handle edge cases", function() {
                // Test edge cases like empty strings, null values, etc.
                // expect(someFunction("")).toBe(expectedValue);
            });

            it("should handle errors gracefully", function() {
                // Test error handling
                // expect(function() {
                //     someFunction(invalidInput);
                // }).toThrow();
            });
        });
    }
}
```

# With mocking examples
```bash
wheels generate test unit PaymentService --mock
```

**Output:** `tests/specs/unit/OrderProcessorSpec.cfc`

**Additional Mock Test:**
```cfc
it("should work with mocked dependencies", function() {
    // Example of using MockBox for mocking
    // var mockDependency = createMock("app.lib.DependencyService");
    // mockDependency.$("someMethod").$results("mocked value");
    // Test with mocked dependency
});
```

**Key Features:**
- Direct component instantiation
- Edge case testing
- Error handling tests
- MockBox examples (with `--mock`)

### Integration Tests

```bash
# End-to-end workflow test
wheels generate test integration CheckoutFlow --crud
```

**Output:** `tests/specs/integration/CheckoutFlowIntegrationSpec.cfc`

**Generated Code:**
```cfc
component extends="wheels.Testbox" {
    function beforeAll() {
        variables.baseUrl = "http://localhost:8080";
    }

    function run() {

        describe("CheckoutFlow Integration Test", function() {

            it("should complete the full checkoutflow workflow", function() {
                // Test complete user journey using HTTP requests

                // 1. Visit listing page
                cfhttp(url = "#variables.baseUrl#/checkoutflows", method = "GET", result = "listResponse");
                expect(listResponse.status_code).toBe(200);

                // 2. Create new record
                cfhttp(url = "#variables.baseUrl#/checkoutflows", method = "POST", result = "createResponse") {
                    cfhttpparam(type = "formfield", name = "checkoutflow[name]", value = "Integration Test");
                }
                expect(createResponse.status_code).toBe(302); // Redirect on success

                // 3. Verify listing shows new record
                cfhttp(url = "#variables.baseUrl#/checkoutflows", method = "GET", result = "verifyResponse");
                expect(verifyResponse.filecontent).toInclude("Integration Test");

                // 4. Add more workflow steps (update, delete, etc.)
            });

            it("should complete operations within acceptable time", function() {
                var startTime = getTickCount();
                cfhttp(url = "#variables.baseUrl#/checkoutflows", method = "GET", result = "response");
                var endTime = getTickCount();
                var executionTime = endTime - startTime;
                expect(executionTime).toBeLT(5000, "Request should complete in under 5 seconds");
            });
        });
    }
}
```

**Key Features:**
- Multi-step workflow testing
- Complete user journey via HTTP
- Performance timing assertions

### API Tests

```bash
# API endpoint tests with JSON
wheels generate test api Users --crud
```

**Output:** `tests/specs/integration/api/UsersAPISpec.cfc`

**Generated Code:**
```cfc
component extends="wheels.Testbox" {

    function beforeAll() {
        variables.apiUrl = "http://localhost:8080/api";
    }

    function run() {

        describe("Users API", function() {

            it("should return paginated users via GET", function() {
                cfhttp(url = "#variables.apiUrl#/users", method = "GET", result = "response") {
                    cfhttpparam(type = "header", name = "Accept", value = "application/json");
                    // Add authentication header if needed
                    // cfhttpparam(type = "header", name = "Authorization", value = "Bearer TOKEN");
                }
                expect(response.status_code).toBe(200);
                var jsonData = deserializeJSON(response.filecontent);
                expect(jsonData).toHaveKey("data");
                expect(isArray(jsonData.data)).toBe(true);
            });

            it("should create a new user via POST", function() {
                var postData = {
                    name = "API Test User"
                };
                cfhttp(url = "#variables.apiUrl#/users", method = "POST", result = "response") {
                    cfhttpparam(type = "header", name = "Content-Type", value = "application/json");
                    cfhttpparam(type = "body", value = serializeJSON(postData));
                }
                expect(response.status_code).toBe(201);
                var jsonData = deserializeJSON(response.filecontent);
                expect(jsonData.data).toHaveKey("id");
            });

            it("should return 401 for unauthorized requests", function() {
                // Test without authentication header
                cfhttp(url = "#variables.apiUrl#/users", method = "GET", result = "response");
                // expect(response.status_code).toBe(401);
                // Add your authentication tests here
            });
        });
    }
}
```

**Key Features:**
- JSON request/response handling with `serializeJSON()` and `deserializeJSON()`
- Content-Type and Accept headers
- Authentication testing placeholders
- RESTful status code assertions (200, 201, 401, etc.)

### Additional Options

```bash
# Force overwrite existing files
wheels generate test model User --force

# Generate and open in editor
wheels generate test controller Products --crud --open
```

## Generated Test Structure

All generated tests include:

- **TestBox 6 BDD Syntax**: Modern `describe()` and `it()` syntax
- **Lifecycle Methods**: `beforeAll()`, `beforeEach()`, `afterEach()` hooks
- **Proper Testing Patterns**:
  - Models: `model().new()`, `model().create()`, `findByKey()`
  - Controllers/Views/Integration: `cfhttp()` with status code assertions
  - APIs: JSON serialization with proper headers
- **Helpful Placeholders**: Comments guiding implementation

## Running Tests

```bash
# Run all tests
wheels test run

# Run specific test bundle
wheels test run --testBundles=ProductSpec

# Run with coverage
wheels test run --coverage
```

## Best Practices

1. **Fill in Test Attributes**: Replace `// Add test attributes` comments with actual model attributes
2. **Customize Assertions**: Add specific assertions for your application's business logic
3. **Use Factory Pattern**: Use `--factory` flag for tests requiring multiple similar objects
4. **Test Edge Cases**: Add tests for empty values, null inputs, boundary conditions
5. **Clean Up Test Data**: Use `afterEach()` or transactions to clean up test data
6. **Use Descriptive Test Names**: Keep `it()` descriptions clear and specific

## Troubleshooting

### Tests Fail with "Model Not Found"
Ensure your model exists in `/app/models/` before generating tests.

### HTTP Tests Return 404
Verify your routes are configured correctly in `/config/routes.cfm`.

### Factory Tests Create Invalid Records
Add required attributes in the `model().create()` calls with valid test data.

## See Also

- [wheels test run](../test/test-run.md) - Run tests
- [Testing Guide](../../../working-with-wheels/testing-your-application.md) - Testing documentation
- [TestBox Documentation](https://testbox.ortusbooks.com/) - TestBox framework docs
