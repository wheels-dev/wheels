# Controller Testing

## Description
Comprehensive guide to testing CFWheels controllers using TestBox 5 with modern BDD (Behavior Driven Development) syntax. Wheels 3.0 uses TestBox integration for testing controllers with `describe()`, `it()`, and `expect()` patterns.

## TestBox BDD Testing Structure

### Modern Test Structure (TestBox 5)
```cfm
// tests/specs/controllers/ProductsControllerSpec.cfc
component extends="wheels.Testbox" {

    function beforeAll() {
        // Setup once before all tests
        variables.baseUrl = "http://localhost:8080";
    }

    function run() {
        describe("Products Controller", () => {

            beforeEach(() => {
                // Setup before each test
                variables.testProduct = model("Product").create({
                    name: "Test Product",
                    price: 99.99,
                    active: true
                });
            });

            afterEach(() => {
                // Clean up after each test
                if (structKeyExists(variables, "testProduct") && isObject(variables.testProduct)) {
                    variables.testProduct.delete();
                }
            });

            // Test specs go here
        });
    }
}
```

### Testing Controller Actions with BDD

#### Testing Index Action
```cfm
it("should display products index page", () => {
    cfhttp(url=variables.baseUrl & "/products", method="GET", result="response");

    expect(response.status_code).toBe(200);
    expect(response.filecontent).toInclude("products");
    expect(response.responseheader["Content-Type"]).toInclude("text/html");
});

it("should handle pagination correctly", () => {
    // Create multiple products for pagination testing
    for (var i = 1; i <= 30; i++) {
        model("Product").create({
            name: "Product #i#",
            price: i * 10
        });
    }

    cfhttp(
        url=variables.baseUrl & "/products?page=2&perPage=10",
        method="GET",
        result="response"
    );

    expect(response.status_code).toBe(200);
    expect(response.filecontent).toInclude("page 2");
});
```

#### Testing Show Action
```cfm
it("should display specific product when ID is valid", () => {
    cfhttp(
        url=variables.baseUrl & "/products/" & variables.testProduct.id,
        method="GET",
        result="response"
    );

    expect(response.status_code).toBe(200);
    expect(response.filecontent).toInclude(variables.testProduct.name);
    expect(response.filecontent).toInclude("Test Product");
});

it("should handle invalid product ID gracefully", () => {
    cfhttp(
        url=variables.baseUrl & "/products/99999",
        method="GET",
        result="response"
    );

    // Either 404 or redirect depending on implementation
    expect([404, 302]).toInclude(response.status_code);
});

it("should reject non-numeric product ID", () => {
    cfhttp(
        url=variables.baseUrl & "/products/invalid",
        method="GET",
        result="response"
    );

    expect([400, 404]).toInclude(response.status_code);
});
```

#### Testing Create Action
```cfm
it("should create new product with valid data", () => {
    var productData = {
        name: "New Test Product",
        price: 149.99,
        categoryId: 1
    };

    cfhttp(
        url=variables.baseUrl & "/products/create",
        method="POST",
        result="response"
    ) {
        cfhttpparam(type="formfield", name="name", value=productData.name);
        cfhttpparam(type="formfield", name="price", value=productData.price);
        cfhttpparam(type="formfield", name="categoryId", value=productData.categoryId);
        cfhttpparam(type="formfield", name="csrf_token", value=session.csrf_token);
    }

    // Should redirect after successful creation
    expect([201, 302]).toInclude(response.status_code);

    // Verify product was created
    var newProduct = model("Product").findOne(where="name = 'New Test Product'");
    expect(newProduct).toBeInstanceOf("Product");
    expect(newProduct.name).toBe(productData.name);
});

it("should reject invalid product data", () => {
    cfhttp(
        url=variables.baseUrl & "/products/create",
        method="POST",
        result="response"
    ) {
        cfhttpparam(type="formfield", name="name", value=""); // Invalid
        cfhttpparam(type="formfield", name="price", value="invalid"); // Invalid
        cfhttpparam(type="formfield", name="csrf_token", value=session.csrf_token);
    }

    expect(response.status_code).toBe(200); // Should render form again
    expect(response.filecontent).toInclude("error");
});
```

#### Testing Update Action
```cfm
function testUpdateWithValidData() {
    params = {
        key: testProduct.id,
        product: {
            name: "Updated Product Name",
            price: 199.99
        }
    };

    result = processAction(controller="products", action="update", params=params);

    // Should redirect to show action
    assert("IsRedirect()");
    assert("flashKeyExists('success')");

    // Verify product was updated
    testProduct.reload();
    assert("testProduct.name == 'Updated Product Name'");
    assert("testProduct.price == 199.99");
}

function testUpdateWithInvalidData() {
    params = {
        key: testProduct.id,
        product: {
            name: "", // Invalid
            price: -10 // Invalid
        }
    };

    result = processAction(controller="products", action="update", params=params);

    // Should render edit action again
    assert("!IsRedirect()");
    assert("result.view == 'products/edit'");
}
```

#### Testing Delete Action
```cfm
function testDelete() {
    productId = testProduct.id;

    params = {key: productId};
    result = processAction(controller="products", action="delete", params=params);

    // Should redirect to index
    assert("IsRedirect()");
    assert("result.location CONTAINS 'index'");
    assert("flashKeyExists('success')");

    // Verify product was deleted
    deletedProduct = model("Product").findByKey(productId);
    assert("!IsObject(deletedProduct)");
}
```

## Testing Authentication and Authorization with BDD

### Testing Authentication Requirements
```cfm
describe("Authentication Requirements", () => {

    it("should redirect to login when not authenticated", () => {
        cfhttp(
            url=variables.baseUrl & "/products/edit/1",
            method="GET",
            result="response"
        );

        expect(response.status_code).toBe(302);
        expect(response.responseheader).toHaveKey("Location");
        expect(response.responseheader.Location).toInclude("login");
    });

    it("should allow access when authenticated", () => {
        // First login
        cfhttp(
            url=variables.baseUrl & "/auth/login",
            method="POST",
            result="loginResponse"
        ) {
            cfhttpparam(type="formfield", name="username", value="testuser");
            cfhttpparam(type="formfield", name="password", value="password123");
            cfhttpparam(type="formfield", name="csrf_token", value=session.csrf_token);
        }

        // Then access protected resource
        cfhttp(
            url=variables.baseUrl & "/products/edit/" & variables.testProduct.id,
            method="GET",
            result="response"
        );

        expect(response.status_code).toBe(200);
        expect(response.filecontent).toInclude("edit");
    });

function testSessionTimeout() {
    // Set up expired session
    session.userId = createTestUser().id;
    session.lastActivity = dateAdd("h", -2, now()); // 2 hours ago

    params = {controller: "products", action: "edit", key: testProduct.id};
    result = processAction(params);

    // Should redirect to login due to timeout
    assert("IsRedirect()");
    assert("result.location CONTAINS 'sessions'");
    assert("!StructKeyExists(session, 'userId')"); // Session should be cleared
}
```

### Testing Authorization
```cfm
function testAdminRequired() {
    // Set up non-admin user
    session.userId = createTestUser(role="user").id;

    params = {controller: "admin", action: "index"};
    result = processAction(params);

    // Should redirect with error
    assert("IsRedirect()");
    assert("flashKeyExists('error')");
}

function testAdminAccess() {
    // Set up admin user
    session.userId = createTestUser(role="admin").id;

    params = {controller: "admin", action: "index"};
    result = processAction(params);

    // Should proceed normally
    assert("!IsRedirect()");
}

function testResourceOwnership() {
    // Create user and their post
    user = createTestUser();
    userPost = model("Post").create(title="User Post", authorId=user.id);

    // Set up different user
    otherUser = createTestUser();
    session.userId = otherUser.id;

    params = {controller: "posts", action: "edit", key=userPost.id};
    result = processAction(params);

    // Should deny access
    assert("IsRedirect()");
    assert("flashKeyExists('error')");
}
```

## Testing CSRF Protection

### CSRF Token Testing
```cfm
function testCSRFProtection() {
    // Test POST without CSRF token
    params = {
        controller: "products",
        action: "create",
        product: {name: "Test"}
    };

    // Should fail due to missing CSRF token
    expectException("CSRFTokenMissing");
    processAction(params);
}

function testCSRFWithValidToken() {
    // Set up valid CSRF token
    local.token = authenticityToken();
    params = {
        controller: "products",
        action: "create",
        authenticityToken: local.token,
        product: {
            name: "Test Product",
            price: 99.99
        }
    };

    result = processAction(params);

    // Should proceed normally
    assert("IsRedirect() OR !flashKeyExists('error')");
}
```

## Testing API Controllers with BDD

### JSON API Response Testing
```cfm
describe("Products API", () => {

    beforeEach(() => {
        variables.apiUrl = variables.baseUrl & "/api";
        variables.headers = {
            "Content-Type": "application/json",
            "Accept": "application/json"
        };
    });

    it("should return JSON response for products list", () => {
        cfhttp(
            url=variables.apiUrl & "/products",
            method="GET",
            result="response"
        ) {
            cfhttpparam(type="header", name="Content-Type", value="application/json");
            cfhttpparam(type="header", name="Accept", value="application/json");
        }

        expect(response.status_code).toBe(200);
        expect(response.responseheader["Content-Type"]).toInclude("application/json");

        var jsonResponse = deserializeJSON(response.filecontent);
        expect(jsonResponse).toBeStruct();
        expect(jsonResponse).toHaveKey("data");
    });

function testApiShowWithValidId() {
    params = {
        controller: "api.products",
        action: "show",
        key: testProduct.id,
        format: "json"
    };

    result = processAction(params);

    assert("result.statusCode == 200");

    data = deserializeJSON(result.content);
    assert("StructKeyExists(data, 'product')");
    assert("data.product.id == #testProduct.id#");
}

function testApiShowWithInvalidId() {
    params = {
        controller: "api.products",
        action: "show",
        key: 99999,
        format: "json"
    };

    result = processAction(params);

    assert("result.statusCode == 404");

    data = deserializeJSON(result.content);
    assert("StructKeyExists(data, 'error')");
}
```

### API Authentication Testing
```cfm
function testAPIRequiresAuthentication() {
    params = {
        controller: "api.products",
        action: "create",
        format: "json",
        product: {name: "Test"}
    };

    result = processAction(params);

    assert("result.statusCode == 401");

    data = deserializeJSON(result.content);
    assert("StructKeyExists(data, 'error')");
}

function testAPIWithValidToken() {
    // Create API token
    user = createTestUser();
    token = generateApiToken(user);

    // Set authorization header
    request.headers["Authorization"] = "Bearer #token#";

    params = {
        controller: "api.products",
        action: "create",
        format: "json",
        product: {
            name: "API Test Product",
            price: 99.99
        }
    };

    result = processAction(params);

    assert("result.statusCode == 201");
}
```

## Testing Filters

### Testing Before Filters
```cfm
function testLoadUserFilter() {
    // Set up user ID in session
    user = createTestUser();
    session.userId = user.id;

    params = {controller: "dashboard", action: "index"};
    result = processAction(params);

    // User should be loaded by filter
    assert("StructKeyExists(variables, 'currentUser')");
    assert("IsObject(currentUser)");
    assert("currentUser.id == #user.id#");
}

function testFilterExceptionHandling() {
    // Set up invalid user ID to trigger filter error
    session.userId = 99999;

    params = {controller: "dashboard", action: "index"};
    result = processAction(params);

    // Should redirect to login
    assert("IsRedirect()");
    assert("result.location CONTAINS 'sessions'");
}
```

### Testing After Filters
```cfm
function testLoggingFilter() {
    // Clear log file before test
    clearLogFile("access");

    params = {controller: "products", action: "show", key: testProduct.id};
    result = processAction(params);

    // Check that access was logged
    logContent = readLogFile("access");
    assert("findNoCase('products.show', logContent)");
}
```

## Testing Validation and Error Handling

### Parameter Validation Testing
```cfm
function testParameterVerification() {
    // Test missing required parameter
    params = {controller: "products", action: "show"}; // Missing key

    expectException("VerificationException");
    processAction(params);
}

function testInvalidParameterType() {
    // Test invalid parameter type
    params = {
        controller: "products",
        action: "show",
        key: "invalid" // Should be integer
    };

    expectException("VerificationException");
    processAction(params);
}
```

### Model Validation Testing
```cfm
function testModelValidationErrors() {
    params = {
        controller: "products",
        action: "create",
        product: {
            name: "", // Invalid
            price: "not a number" // Invalid
        }
    };

    result = processAction(params);

    // Should render new action with errors
    assert("!IsRedirect()");
    assert("result.view == 'products/new'");
    assert("StructKeyExists(variables, 'product')");
    assert("product.hasErrors()");
}
```

## Testing File Uploads

### File Upload Testing
```cfm
function testFileUpload() {
    // Create test file
    testFilePath = createTestFile("test.jpg", "fake image content");

    form.uploadFile = testFilePath;
    params = {
        controller: "products",
        action: "upload",
        key: testProduct.id
    };

    result = processAction(params);

    assert("IsRedirect()");
    assert("flashKeyExists('success')");

    // Clean up
    if (fileExists(testFilePath)) {
        fileDelete(testFilePath);
    }
}

function testInvalidFileType() {
    // Create test file with invalid extension
    testFilePath = createTestFile("test.exe", "executable content");

    form.uploadFile = testFilePath;
    params = {
        controller: "products",
        action: "upload",
        key: testProduct.id
    };

    result = processAction(params);

    assert("IsRedirect()");
    assert("flashKeyExists('error')");

    // Clean up
    if (fileExists(testFilePath)) {
        fileDelete(testFilePath);
    }
}
```

## Testing Flash Messages with BDD

### Flash Message Validation
```cfm
describe("Flash Messages", () => {

    it("should display success message after product creation", () => {
        cfhttp(
            url=variables.baseUrl & "/products/create",
            method="POST",
            result="response"
        ) {
            cfhttpparam(type="formfield", name="name", value="Flash Test Product");
            cfhttpparam(type="formfield", name="price", value="99.99");
            cfhttpparam(type="formfield", name="csrf_token", value=session.csrf_token);
        }

        expect([201, 302]).toInclude(response.status_code);

        // Follow redirect to see flash message
        if (response.status_code == 302) {
            cfhttp(
                url=response.responseheader.Location,
                method="GET",
                result="followUpResponse"
            );

            expect(followUpResponse.filecontent).toInclude("success");
            expect(followUpResponse.filecontent).toInclude("created");
        }
    });

function testErrorFlashMessage() {
    params = {
        controller: "products",
        action: "create",
        product: {
            name: "" // Invalid
        }
    };

    result = processAction(params);

    // May set error flash for validation failures
    // (depends on controller implementation)
}
```

## Integration Testing with BDD

### Complete Workflow Testing
```cfm
describe("Complete Product Workflow", () => {

    var workflowProduct;

    it("should handle complete product CRUD workflow", () => {
        // 1. Login first
        cfhttp(
            url=variables.baseUrl & "/auth/login",
            method="POST",
            result="loginResponse"
        ) {
            cfhttpparam(type="formfield", name="username", value="testuser");
            cfhttpparam(type="formfield", name="password", value="password123");
            cfhttpparam(type="formfield", name="csrf_token", value=session.csrf_token);
        }

        expect(loginResponse.status_code).toBe(302); // Redirect after login

        // 2. Create product
        cfhttp(
            url=variables.baseUrl & "/products/create",
            method="POST",
            result="createResponse"
        ) {
            cfhttpparam(type="formfield", name="name", value="Workflow Test Product");
            cfhttpparam(type="formfield", name="price", value="199.99");
            cfhttpparam(type="formfield", name="csrf_token", value=session.csrf_token);
        }

        expect([201, 302]).toInclude(createResponse.status_code);

        // 3. Verify product was created
        workflowProduct = model("Product").findOne(where="name = 'Workflow Test Product'");
        expect(workflowProduct).toBeInstanceOf("Product");
        expect(workflowProduct.name).toBe("Workflow Test Product");

        // 4. Update the product
        cfhttp(
            url=variables.baseUrl & "/products/" & workflowProduct.id & "/update",
            method="POST",
            result="updateResponse"
        ) {
            cfhttpparam(type="formfield", name="name", value="Updated Workflow Product");
            cfhttpparam(type="formfield", name="price", value="249.99");
            cfhttpparam(type="formfield", name="csrf_token", value=session.csrf_token);
        }

        expect([200, 302]).toInclude(updateResponse.status_code);

        // 5. Verify update
        workflowProduct.reload();
        expect(workflowProduct.name).toBe("Updated Workflow Product");
        expect(workflowProduct.price).toBe(249.99);

        // 6. Delete the product
        cfhttp(
            url=variables.baseUrl & "/products/" & workflowProduct.id & "/delete",
            method="POST",
            result="deleteResponse"
        ) {
            cfhttpparam(type="formfield", name="csrf_token", value=session.csrf_token);
        }

        expect([200, 302]).toInclude(deleteResponse.status_code);

        // 7. Verify deletion
        var deletedProduct = model("Product").findByKey(workflowProduct.id);
        expect(deletedProduct).toBeFalse(); // Should not exist
    });
```

## Testing Helpers and Utilities

### Test Helper Functions
```cfm
/**
 * Create test user with optional attributes
 */
function createTestUser(struct attributes = {}) {
    local.defaultData = {
        username: "testuser" & randRange(1000, 9999),
        email: "test#randRange(1000, 9999)#@example.com",
        password: "password123",
        firstName: "Test",
        lastName: "User"
    };

    structAppend(local.defaultData, arguments.attributes);

    return model("User").create(local.defaultData);
}

/**
 * Create test file for upload testing
 */
function createTestFile(required string fileName, required string content) {
    local.tempDir = getTempDirectory();
    local.filePath = local.tempDir & arguments.fileName;

    fileWrite(local.filePath, arguments.content);

    return local.filePath;
}

/**
 * Generate API token for testing
 */
function generateApiToken(required user) {
    local.token = hash(createUUID() & now(), "SHA-256");

    arguments.user.update(
        apiToken=local.token,
        tokenExpiresAt=dateAdd("d", 30, now())
    );

    return local.token;
}

/**
 * Clear log file for testing
 */
function clearLogFile(required string logName) {
    local.logPath = expandPath("/logs/#arguments.logName#.log");
    if (fileExists(local.logPath)) {
        fileDelete(local.logPath);
    }
}

/**
 * Read log file content
 */
function readLogFile(required string logName) {
    local.logPath = expandPath("/logs/#arguments.logName#.log");
    if (fileExists(local.logPath)) {
        return fileRead(local.logPath);
    }
    return "";
}
```

## Performance Testing

### Load Testing Controllers
```cfm
function testControllerPerformance() {
    local.startTime = getTickCount();
    local.iterations = 100;

    for (local.i = 1; local.i <= local.iterations; local.i++) {
        params = {controller: "products", action: "index"};
        processAction(params);
    }

    local.totalTime = getTickCount() - local.startTime;
    local.averageTime = local.totalTime / local.iterations;

    // Assert performance requirements
    assert("local.averageTime < 100", "Average response time should be under 100ms");
}
```

## Test Organization Best Practices

### Test Structure
```
tests/
├── specs/
│   ├── controllers/
│   │   ├── ProductsTest.cfc
│   │   ├── UsersTest.cfc
│   │   └── api/
│   │       └── ProductsTest.cfc
│   ├── models/
│   └── integration/
├── fixtures/
│   ├── products.yml
│   └── users.yml
└── support/
    ├── TestHelper.cfc
    └── DatabaseCleaner.cfc
```

### Test Data Management
```cfm
function setup() {
    super.setup();

    // Use database transactions for test isolation
    transaction action="begin";

    // Create test data
    setupTestData();
}

function teardown() {
    // Rollback transaction to clean up
    transaction action="rollback";

    super.teardown();
}

function setupTestData() {
    testUser = createTestUser();
    testCategory = model("Category").create(name="Test Category");
    testProduct = model("Product").create({
        name: "Test Product",
        price: 99.99,
        categoryId: testCategory.id
    });
}
```

## TestBox BDD Best Practices

### 1. Write Focused, Descriptive Tests
```cfm
// Good - focused BDD test
it("should redirect after successful product creation", () => {
    cfhttp(
        url=variables.baseUrl & "/products/create",
        method="POST",
        result="response"
    ) {
        cfhttpparam(type="formfield", name="name", value="Valid Product");
        cfhttpparam(type="formfield", name="price", value="99.99");
        cfhttpparam(type="formfield", name="csrf_token", value=session.csrf_token);
    }

    expect([201, 302]).toInclude(response.status_code);
});

// Avoid - testing multiple concerns in one test
// Instead, break into separate it() blocks
```

### 2. Use Descriptive BDD Descriptions
```cfm
// Good - clear BDD descriptions
describe("Product Creation", () => {
    it("should redirect to product detail after successful creation", () => { ... });
    it("should display validation errors when data is invalid", () => { ... });
    it("should require authentication for product creation", () => { ... });
});

// Avoid - vague descriptions
describe("Products", () => {
    it("should work", () => { ... });
    it("should do stuff", () => { ... });
});
```

### 3. Test Error Conditions with BDD
```cfm
describe("Error Handling", () => {

    it("should handle missing data gracefully", () => {
        cfhttp(
            url=variables.baseUrl & "/products/create",
            method="POST",
            result="response"
        ) {
            // Send empty data
            cfhttpparam(type="formfield", name="csrf_token", value=session.csrf_token);
        }

        expect(response.status_code).toBe(400);
    });

    it("should reject unauthorized access", () => {
        // Don't login first
        cfhttp(
            url=variables.baseUrl & "/products/create",
            method="GET",
            result="response"
        );

        expect(response.status_code).toBe(302); // Redirect to login
    });
});
```

### 4. Use MockBox for External Dependencies
```cfm
describe("Email Integration", () => {

    beforeEach(() => {
        // Create mock email service
        variables.mockEmailService = createMock("EmailService");
        variables.mockEmailService.$(
            method="sendWelcomeEmail",
            returns=true
        );

        // Inject mock into application
        application.emailService = variables.mockEmailService;
    });

    it("should send welcome email after user creation", () => {
        cfhttp(
            url=variables.baseUrl & "/users/create",
            method="POST",
            result="response"
        ) {
            cfhttpparam(type="formfield", name="username", value="newuser");
            cfhttpparam(type="formfield", name="email", value="new@example.com");
            cfhttpparam(type="formfield", name="csrf_token", value=session.csrf_token);
        }

        expect([201, 302]).toInclude(response.status_code);
        expect(variables.mockEmailService.$once("sendWelcomeEmail")).toBeTrue();
    });
});
```

## Modern TestBox Resources

For comprehensive TestBox 5 documentation:
- [TestBox BDD Documentation](https://testbox.ortusbooks.com/v6.x/getting-started/testbox-bdd-primer)
- [TestBox Expectations](https://testbox.ortusbooks.com/v6.x/getting-started/testbox-bdd-primer/expectations)
- [MockBox Documentation](https://testbox.ortusbooks.com/v6.x/mocking/mockbox)
- [TestBox Life-cycle Methods](https://testbox.ortusbooks.com/v6.x/digging-deeper/life-cycle-methods)

## Related Documentation
- [Controller Architecture](./architecture.md)
- [Controller Security](./security.md)
- [Model Testing](../models/testing.md)
- [View Testing](../views/testing.md)