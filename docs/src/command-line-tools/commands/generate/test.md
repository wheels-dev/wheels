# wheels generate test

Generate test files for models, controllers, views, and other components using TestBox BDD syntax.

## Synopsis

```bash
wheels generate test [type] [target] [options]
wheels g test [type] [target] [options]
```

## Description

The `wheels generate test` command creates test files for various components of your Wheels application using TestBox 5 BDD syntax. All generated tests use standard CFML `cfhttp()` for HTTP testing and proper Wheels `model()` syntax, ensuring compatibility and reliability.

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

### Basic Model Test

Generate a basic model test with validation and association tests:

```bash
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

### Model Test with Factory Pattern

Generate tests using `model().create()` for test data:

```bash
wheels generate test model Order --crud --factory
```

**Output:** `tests/specs/models/OrderSpec.cfc`

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

### Basic Controller Test

Generate HTTP-based controller tests:

```bash
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

### Controller Test with CRUD Actions

Generate full CRUD controller tests via HTTP:

```bash
wheels generate test controller Products --crud
```

**Output:** `tests/specs/controllers/ProductsControllerSpec.cfc`

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

### View Test

Generate view rendering tests:

```bash
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

### Unit Test

Generate unit tests for custom services/libraries:

```bash
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

### Unit Test with Mock Examples

Generate unit tests with MockBox mocking examples:

```bash
wheels generate test unit PaymentService --mock
```

**Output:** `tests/specs/unit/PaymentServiceSpec.cfc`

**Additional Mock Test:**
```cfc
it("should work with mocked dependencies", function() {
    // Example of using MockBox for mocking
    // var mockDependency = createMock("app.lib.DependencyService");
    // mockDependency.$("someMethod").$results("mocked value");
    // Test with mocked dependency
});
```

### Integration Test

Generate end-to-end workflow tests:

```bash
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

### API Test

Generate API endpoint tests with JSON handling:

```bash
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

### Force Overwrite

Overwrite existing test files without confirmation:

```bash
wheels generate test model User --force
```

**Effect:** Overwrites `tests/specs/models/UserSpec.cfc` without prompting.

### Generate and Open

Create test and open in default editor:

```bash
wheels generate test controller Products --crud --open
```

**Effect:** Creates test file and opens it in your system's default `.cfc` file editor.

## Generated Test Features

All generated tests include:

- **TestBox 5 BDD Syntax**: Modern `describe()` and `it()` syntax
- **Proper Lifecycle Methods**: `beforeAll()`, `beforeEach()`, `afterEach()` hooks
- **HTTP-Based Testing**: Uses `cfhttp()` for controller, view, integration, and API tests
- **Model Testing**: Uses `model().new()`, `model().create()`, and `model().findByKey()`
- **CRUD Operations**: Complete create, read, update, delete test cases (with `--crud`)
- **Factory Pattern**: Test data creation using `model().create()` (with `--factory`)
- **Mock Examples**: MockBox stub examples (with `--mock`)
- **JSON Handling**: `serializeJSON()` and `deserializeJSON()` for API tests
- **Placeholder Comments**: Helpful comments guiding test implementation

## Common Test Patterns

### Model Validation Testing
```cfc
it("should validate required fields", function() {
    expect(user.valid()).toBe(false);
    expect(user.errors).toHaveKey("email");
});
```

### Model CRUD Testing
```cfc
it("should create a new user", function() {
    var user = model("User").create({
        email = "test@example.com",
        firstName = "Test"
    });
    expect(user.id).toBeGT(0);
});
```

### HTTP Controller Testing
```cfc
it("should return 200 status", function() {
    cfhttp(url = "#baseUrl#/users", method = "GET", result = "response");
    expect(response.status_code).toBe(200);
});
```

### API JSON Testing
```cfc
it("should return valid JSON", function() {
    cfhttp(url = "#apiUrl#/users", method = "GET", result = "response") {
        cfhttpparam(type = "header", name = "Accept", value = "application/json");
    }
    var data = deserializeJSON(response.filecontent);
    expect(data).toHaveKey("data");
});
```

## Running Tests

Run the generated tests using the Wheels test command:

```bash
# Run all tests
wheels test run

# Run specific test bundle
wheels test run --testBundles=ProductSpec

# Run with coverage
wheels test run --coverage
```

## Best Practices

1. **Fill in Test Attributes**: Generated tests include `// Add test attributes` comments - replace with actual model attributes
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
