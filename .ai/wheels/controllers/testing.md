# Controller Testing

## Description
Comprehensive guide to testing CFWheels controllers, including unit testing, integration testing, testing patterns, and best practices for ensuring controller reliability.

## Basic Controller Testing

### Test Structure
```cfm
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

    function teardown() {
        super.teardown();

        // Clean up test data
        if (IsObject(testProduct)) {
            testProduct.delete();
        }
    }

    // Test methods go here
}
```

### Testing Actions

#### Testing Index Action
```cfm
function testIndex() {
    params = {};
    result = processAction(controller="products", action="index", params=params);

    assert("StructKeyExists(variables, 'products')");
    assert("IsQuery(products)");
    assert("products.recordCount >= 1"); // At least our test product
}

function testIndexWithPagination() {
    // Create multiple products for pagination testing
    for (local.i = 1; local.i <= 30; local.i++) {
        model("Product").create({
            name: "Product #local.i#",
            price: local.i * 10
        });
    }

    params = {page: 2, perPage: 10};
    result = processAction(controller="products", action="index", params=params);

    assert("StructKeyExists(variables, 'products')");
    assert("products.recordCount <= 10");
    assert("products.currentPage == 2");
}
```

#### Testing Show Action
```cfm
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
    assert("flashKeyExists('error')");
}

function testShowWithNonNumericKey() {
    params = {key: "invalid"};

    // Should trigger verification failure
    expectException("VerificationException");
    processAction(controller="products", action="show", params=params);
}
```

#### Testing Create Action
```cfm
function testCreateWithValidData() {
    params = {
        product: {
            name: "New Test Product",
            price: 149.99,
            categoryId: 1
        }
    };

    result = processAction(controller="products", action="create", params=params);

    // Should redirect to show action
    assert("IsRedirect()");
    assert("result.location CONTAINS 'show'");
    assert("flashKeyExists('success')");

    // Verify product was created
    newProduct = model("Product").findOne(where="name = 'New Test Product'");
    assert("IsObject(newProduct)");
}

function testCreateWithInvalidData() {
    params = {
        product: {
            name: "", // Invalid - name required
            price: "invalid"
        }
    };

    result = processAction(controller="products", action="create", params=params);

    // Should render new action again
    assert("!IsRedirect()");
    assert("result.view == 'products/new'");
}
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

## Testing Authentication and Authorization

### Testing Authentication Filters
```cfm
function testRequiresAuthentication() {
    // Test without session
    params = {controller: "products", action: "edit", key: 1};
    result = processAction(params);

    // Should redirect to login
    assert("IsRedirect()");
    assert("result.location CONTAINS 'sessions'");
}

function testAuthenticationFilterWithValidSession() {
    // Set up valid session
    session.userId = createTestUser().id;

    params = {controller: "products", action: "edit", key: testProduct.id};
    result = processAction(params);

    // Should proceed normally
    assert("!IsRedirect()");
}

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

## Testing API Controllers

### JSON Response Testing
```cfm
function testApiIndexReturnsJson() {
    params = {
        controller: "api.products",
        action: "index",
        format: "json"
    };

    result = processAction(params);

    assert("result.contentType == 'application/json'");
    assert("isJSON(result.content)");

    data = deserializeJSON(result.content);
    assert("StructKeyExists(data, 'products')");
}

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

## Testing Flash Messages

### Flash Message Testing
```cfm
function testSuccessFlashMessage() {
    params = {
        controller: "products",
        action: "create",
        product: {
            name: "Flash Test Product",
            price: 99.99
        }
    };

    result = processAction(params);

    assert("flashKeyExists('success')");
    assert("findNoCase('created', flash('success'))");
}

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

## Integration Testing

### Full Workflow Testing
```cfm
function testCompleteProductWorkflow() {
    // 1. Create user and authenticate
    user = createTestUser();
    session.userId = user.id;

    // 2. Navigate to new product form
    params = {controller: "products", action: "new"};
    result = processAction(params);
    assert("!IsRedirect()");

    // 3. Create product
    params = {
        controller: "products",
        action: "create",
        product: {
            name: "Workflow Test Product",
            price: 199.99
        }
    };
    result = processAction(params);
    assert("IsRedirect()");

    // 4. Verify product was created
    newProduct = model("Product").findOne(where="name = 'Workflow Test Product'");
    assert("IsObject(newProduct)");

    // 5. Edit the product
    params = {
        controller: "products",
        action: "update",
        key: newProduct.id,
        product: {
            name: "Updated Workflow Product",
            price: 249.99
        }
    };
    result = processAction(params);
    assert("IsRedirect()");

    // 6. Verify update
    newProduct.reload();
    assert("newProduct.name == 'Updated Workflow Product'");

    // 7. Delete the product
    params = {
        controller: "products",
        action: "delete",
        key: newProduct.id
    };
    result = processAction(params);
    assert("IsRedirect()");

    // 8. Verify deletion
    deletedProduct = model("Product").findByKey(newProduct.id);
    assert("!IsObject(deletedProduct)");
}
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

## Best Practices

### 1. Test One Thing at a Time
```cfm
// Good - focused test
function testCreateRedirectsOnSuccess() {
    params = getValidProductParams();
    result = processAction(controller="products", action="create", params=params);

    assert("IsRedirect()");
}

// Avoid - testing multiple concerns
function testCreateEverything() {
    // Testing validation, success, database, flash messages, etc.
}
```

### 2. Use Descriptive Test Names
```cfm
// Good - clear intent
function testCreateWithValidDataRedirectsToShow() { }
function testCreateWithInvalidDataRendersNewAction() { }
function testUpdateRequiresAuthentication() { }

// Avoid - unclear purpose
function testCreate() { }
function testUpdate() { }
function testAuth() { }
```

### 3. Test Error Conditions
```cfm
function testErrorConditions() {
    // Test missing data
    // Test invalid data
    // Test unauthorized access
    // Test server errors
}
```

### 4. Use Test Doubles When Appropriate
```cfm
function testEmailSending() {
    // Mock email service to avoid sending real emails
    mockEmailService = createMock("EmailService");
    mockEmailService.sendWelcomeEmail().returns(true);

    // Inject mock
    controller.setEmailService(mockEmailService);

    // Test action
    params = getValidUserParams();
    result = processAction(controller="users", action="create", params=params);

    // Verify mock was called
    mockEmailService.verify().sendWelcomeEmail();
}
```

## Related Documentation
- [Controller Architecture](./architecture.md)
- [Controller Security](./security.md)
- [Model Testing](../models/testing.md)
- [Testing Best Practices](../../testing/best-practices.md)