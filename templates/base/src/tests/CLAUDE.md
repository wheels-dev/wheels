# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with tests in a Wheels application.

## Testing Framework Overview

Wheels 3.0 uses **TestBox 5** as its primary testing framework, providing modern BDD (Behavior Driven Development) and TDD (Test Driven Development) capabilities. TestBox is automatically included through the `box.json` dependency management.

### Key TestBox Features
- BDD style (`describe()`, `it()`, `expect()`) and xUnit style testing
- Comprehensive assertion library with fluent syntax
- MockBox integration for mocking and stubbing
- Multiple output formats (HTML, JSON, XML, JUnit, TAP)
- Test lifecycle methods (`beforeAll()`, `beforeEach()`, `afterEach()`, `afterAll()`)
- Asynchronous testing support
- Code coverage reporting via FusionReactor

## Test Directory Structure

```
tests/
├── runner.cfm              # Web-based test runner
├── populate.cfm            # Test database setup
├── routes.cfm              # Test-specific routes
├── _assets/                # Test assets and helpers
├── specs/                  # Test specifications
│   ├── unit/              # Unit tests
│   │   ├── models/        # Model tests
│   │   ├── controllers/   # Controller tests
│   │   └── services/      # Service tests
│   ├── integration/       # Integration tests
│   └── functions/         # Function/helper tests
├── fixtures/              # Test data files
└── support/               # Test utilities and factories
```

### File Naming Conventions
- Model tests: `UserTest.cfc` or `UserSpec.cfc`
- Controller tests: `UsersControllerTest.cfc` or `UsersControllerSpec.cfc`
- Integration tests: `UserRegistrationFlowTest.cfc`
- Function tests: `StringHelpersTest.cfc`

## Writing Tests

### Basic Test Structure

All test components extend `testbox.system.BaseSpec`:

```cfm
component extends="testbox.system.BaseSpec" {

    function beforeAll() {
        // Setup once for all tests in this component
        variables.testData = {
            email: "test@example.com",
            firstName: "Test",
            lastName: "User"
        };
    }

    function afterAll() {
        // Cleanup once after all tests complete
        model("User").deleteAll(where = "email LIKE '%@example.com'");
    }

    function run() {
        describe("User Model", function() {

            it("should validate email presence", function() {
                var user = model("User").new();
                user.email = "";
                expect(user.valid()).toBeFalse();
                expect(user.errors).toHaveKey("email");
            });

            it("should create valid user", function() {
                var user = model("User").new(variables.testData);
                expect(user.valid()).toBeTrue();
            });

        });
    }
}
```

### Model Testing Patterns

Focus on validations, associations, callbacks, scopes, and custom methods:

```cfm
component extends="testbox.system.BaseSpec" {

    function beforeAll() {
        // Setup test data once for all tests in this component
        variables.testCategory = model("Category").create(name = "Test Category");
        variables.validProductData = {
            name = "Test Product",
            price = 19.99,
            categoryId = variables.testCategory.id
        };
    }

    function afterAll() {
        // Cleanup once after all tests complete
        model("Product").deleteAll(where = "name LIKE 'Test%'");
        if (isDefined("variables.testCategory")) variables.testCategory.delete();
    }

    function run() {
        describe("Product Model", function() {

            describe("Validations", function() {
                
                it("should require a name", function() {
                    var product = model("Product").new();
                    expect(product.valid()).toBeFalse();
                    expect(product.errors).toHaveKey("name");
                });

                it("should require positive price", function() {
                    var product = model("Product").new(
                        name = "Test Product",
                        price = -10
                    );
                    expect(product.valid()).toBeFalse();
                    expect(product.errors.price).toInclude("greater than 0");
                });

                it("should validate email format", function() {
                    var user = model("User").new(email = "invalid-email");
                    expect(user.valid()).toBeFalse();
                    expect(user.errors.email).toInclude("valid email");
                });

            });

            describe("Associations", function() {
                
                it("should have many reviews", function() {
                    var product = model("Product").findOne();
                    expect(product).toHaveKey("reviews");
                    expect(product.reviews()).toBeQuery();
                });

                it("should belong to category", function() {
                    var product = createProduct(categoryId = 1);
                    expect(product.category()).toBeObject();
                    expect(product.category().id).toBe(1);
                });

            });

            describe("Scopes", function() {
                
                it("should filter active products", function() {
                    // Create test data
                    model("Product").create(name = "Active", active = true);
                    model("Product").create(name = "Inactive", active = false);

                    var activeProducts = model("Product").active().findAll();
                    expect(activeProducts.recordCount).toBe(1);
                    expect(activeProducts.name).toBe("Active");
                });

            });

            describe("Custom Methods", function() {
                
                it("should calculate discount price", function() {
                    var product = model("Product").new(price = 100);
                    var discountPrice = product.calculateDiscountPrice(0.20);
                    expect(discountPrice).toBe(80);
                });

                it("should generate slug from name", function() {
                    var product = model("Product").new(name = "Test Product Name");
                    expect(product.generateSlug()).toBe("test-product-name");
                });

            });

        });
    }
}
```

### Controller Testing Patterns

Test actions, responses, parameters, authentication, and redirects:

```cfm
component extends="testbox.system.BaseSpec" {

    function beforeAll() {
        variables.baseUrl = "http://localhost:8080";
    }

    function run() {
        describe("Products Controller", function() {

            describe("index action", function() {
                
                it("should return 200 status for products listing", function() {
                    cfhttp(url = "#variables.baseUrl#/products", method = "GET", result = "response");
                    
                    expect(response.status_code).toBe(200);
                    expect(response.filecontent).toInclude("Products");
                });

                it("should display all products", function() {
                    // Create test products
                    var product1 = createProduct(name = "Product 1");
                    var product2 = createProduct(name = "Product 2");

                    cfhttp(url = "#variables.baseUrl#/products", method = "GET", result = "response");
                    
                    expect(response.filecontent).toInclude("Product 1");
                    expect(response.filecontent).toInclude("Product 2");
                });

            });

            describe("create action", function() {
                
                it("should create product with valid data", function() {
                    var productData = {
                        name = "New Product",
                        price = 29.99,
                        description = "Test description"
                    };

                    cfhttp(url = "#variables.baseUrl#/products", method = "POST", result = "response") {
                        cfhttpparam(type = "formfield", name = "product[name]", value = productData.name);
                        cfhttpparam(type = "formfield", name = "product[price]", value = productData.price);
                        cfhttpparam(type = "formfield", name = "product[description]", value = productData.description);
                    }

                    expect(response.status_code).toBe(302); // Redirect after creation
                    
                    // Verify product was created
                    var product = model("Product").findOne(where = "name = 'New Product'");
                    expect(product).toBeObject();
                    expect(product.price).toBe(29.99);
                });

                it("should reject invalid data", function() {
                    cfhttp(url = "#variables.baseUrl#/products", method = "POST", result = "response") {
                        cfhttpparam(type = "formfield", name = "product[name]", value = "");
                        cfhttpparam(type = "formfield", name = "product[price]", value = "-10");
                    }

                    expect(response.status_code).toBe(200); // Returns to form with errors
                    expect(response.filecontent).toInclude("error");
                });

            });

            describe("authentication", function() {
                
                it("should require authentication for protected actions", function() {
                    cfhttp(url = "#variables.baseUrl#/products/new", method = "GET", result = "response");
                    
                    expect(response.status_code).toBe(302);
                    expect(response.responseheader).toHaveKey("Location");
                    expect(response.responseheader.Location).toInclude("login");
                });

            });

        });
    }
}
```

### API Testing Patterns

Test JSON responses, status codes, and API-specific functionality:

```cfm
component extends="testbox.system.BaseSpec" {

    function beforeAll() {
        variables.apiUrl = "http://localhost:8080/api/v1";
    }

    function run() {
        describe("API Endpoints", function() {

            describe("GET /api/v1/users", function() {
                
                it("should return JSON with user list", function() {
                    cfhttp(url = "#variables.apiUrl#/users", method = "GET", result = "response") {
                        cfhttpparam(type = "header", name = "Accept", value = "application/json");
                    }

                    expect(response.status_code).toBe(200);
                    expect(response.responseheader["Content-Type"]).toInclude("application/json");
                    
                    var data = deserializeJSON(response.filecontent);
                    expect(data).toHaveKey("data");
                    expect(data.data).toBeArray();
                });

            });

            describe("POST /api/v1/users", function() {
                
                it("should create user with valid JSON data", function() {
                    var userData = {
                        email = "api-test@example.com",
                        firstName = "API",
                        lastName = "Test"
                    };

                    cfhttp(url = "#variables.apiUrl#/users", method = "POST", result = "response") {
                        cfhttpparam(type = "header", name = "Content-Type", value = "application/json");
                        cfhttpparam(type = "body", value = serializeJSON(userData));
                    }

                    expect(response.status_code).toBe(201);
                    
                    var responseData = deserializeJSON(response.filecontent);
                    expect(responseData.data.email).toBe(userData.email);
                });

            });

        });
    }
}
```

### Integration Testing Patterns

Test complete workflows and user interactions:

```cfm
component extends="testbox.system.BaseSpec" {

    function beforeAll() {
        variables.baseUrl = "http://localhost:8080";
    }

    function run() {
        describe("User Registration Flow", function() {

            it("should allow complete user registration process", function() {
                // 1. Visit registration page
                cfhttp(url = "#variables.baseUrl#/register", method = "GET", result = "response");
                expect(response.status_code).toBe(200);
                expect(response.filecontent).toInclude("Register");

                // 2. Submit registration form
                var userData = {
                    email = "integration-test@example.com",
                    password = "SecurePass123!",
                    firstName = "Integration",
                    lastName = "Test"
                };

                cfhttp(url = "#variables.baseUrl#/users", method = "POST", result = "response") {
                    cfhttpparam(type = "formfield", name = "user[email]", value = userData.email);
                    cfhttpparam(type = "formfield", name = "user[password]", value = userData.password);
                    cfhttpparam(type = "formfield", name = "user[firstName]", value = userData.firstName);
                    cfhttpparam(type = "formfield", name = "user[lastName]", value = userData.lastName);
                }

                // 3. Should redirect after successful registration
                expect(response.status_code).toBe(302);

                // 4. Verify user was created
                var user = model("User").findOne(where = "email = '#userData.email#'");
                expect(user).toBeObject();
                expect(user.firstName).toBe(userData.firstName);

                // 5. Should be able to login with new credentials
                cfhttp(url = "#variables.baseUrl#/login", method = "POST", result = "loginResponse") {
                    cfhttpparam(type = "formfield", name = "email", value = userData.email);
                    cfhttpparam(type = "formfield", name = "password", value = userData.password);
                }

                expect(loginResponse.status_code).toBe(302); // Successful login redirect
            });

        });
    }
}
```

### Function/Helper Testing

Test utility functions and global helpers:

```cfm
component extends="testbox.system.BaseSpec" {

    function run() {
        describe("String Helper Functions", function() {

            it("should format currency correctly", function() {
                expect(formatCurrency(19.99)).toBe("$19.99");
                expect(formatCurrency(1000)).toBe("$1,000.00");
                expect(formatCurrency(0)).toBe("$0.00");
                expect(formatCurrency(-50.50)).toBe("-$50.50");
            });

            it("should truncate text properly", function() {
                var longText = "This is a very long text that needs truncation";
                expect(truncateText(longText, 20)).toBe("This is a very long...");
                expect(truncateText("Short", 20)).toBe("Short");
            });

            it("should validate email addresses", function() {
                expect(isValidEmail("test@example.com")).toBeTrue();
                expect(isValidEmail("user+tag@domain.co.uk")).toBeTrue();
                expect(isValidEmail("invalid-email")).toBeFalse();
                expect(isValidEmail("")).toBeFalse();
            });

        });

        describe("Date Helper Functions", function() {

            it("should format dates for display", function() {
                var testDate = createDate(2024, 3, 15);
                expect(formatDisplayDate(testDate)).toInclude("Mar");
                expect(formatDisplayDate(testDate)).toInclude("15");
                expect(formatDisplayDate(testDate)).toInclude("2024");
            });

            it("should calculate time differences", function() {
                var startTime = now();
                var endTime = dateAdd("h", 2, startTime);
                expect(hoursBetween(startTime, endTime)).toBe(2);
            });

        });
    }
}
```

## Test Helpers and Utilities

### Creating Test Data Factories

Create reusable factory functions for consistent test data:

```cfm
// In /tests/support/Factories.cfc
component {

    function createUser(struct overrides = {}) {
        var defaults = {
            email = "user-#createUUID()#@test.com",
            password = "password123",
            firstName = "Test",
            lastName = "User",
            isActive = true
        };
        
        defaults.append(arguments.overrides);
        return model("User").create(defaults);
    }

    function createProduct(struct overrides = {}) {
        var defaults = {
            name = "Product #createUUID()#",
            price = randRange(10, 100) + (randRange(0, 99) / 100),
            description = "Test product description",
            isActive = true
        };
        
        defaults.append(arguments.overrides);
        return model("Product").create(defaults);
    }

    function buildUser(struct overrides = {}) {
        // Build without saving to database
        var defaults = createUserDefaults();
        defaults.append(arguments.overrides);
        return model("User").new(defaults);
    }

}
```

### Custom Assertion Helpers

Create domain-specific assertions for cleaner tests:

```cfm
// In your test file
function assertValidUser(required any user) {
    expect(arguments.user).toBeObject("User should be an object");
    expect(arguments.user.id).toBeGT(0, "User should have a valid ID");
    expect(arguments.user.email).toMatch(".*@.*\\..*", "User should have valid email");
    expect(arguments.user.firstName).notToBeEmpty("User should have first name");
}

function assertHasErrors(required any model, required string property) {
    expect(arguments.model.valid()).toBeFalse("#arguments.property# should have validation errors");
    expect(arguments.model.errors).toHaveKey(arguments.property);
}

function assertRedirectsTo(required any response, required string expectedUrl) {
    expect(arguments.response.status_code).toBe(302, "Should redirect");
    expect(arguments.response.responseheader).toHaveKey("Location");
    expect(arguments.response.responseheader.Location).toInclude(arguments.expectedUrl);
}
```

### Test Database Management

Manage test data with transactions or cleanup methods:

```cfm
// Using transactions (automatic rollback) - Valid use of beforeEach/afterEach
// This is one of the few cases where beforeEach/afterEach are appropriate
describe("Product Model", function() {
    
    beforeEach(function() {
        transaction action="begin";
    });

    afterEach(function() {
        transaction action="rollback";
    });

    it("should create product", function() {
        var product = createProduct();
        expect(product.id).toBeGT(0);
        // Automatically rolled back after test
    });

});

// Using manual cleanup - AVOID if possible, slower performance
describe("User Registration", function() {
    
    afterEach(function() {
        // AVOID: This runs after every single test, slowing down the suite
        model("User").deleteAll(where = "email LIKE '%@test.com'");
    });

    // Multiple test methods here...
    
});

// PREFERRED: Performance-optimized approach
// /tests/specs/models/ProductModelTest.cfc
component extends="testbox.system.BaseSpec" {
    
    function beforeAll() {
        // Expensive setup once per component - much faster
        variables.testCategory = model("Category").create(name = "Test Category");
        variables.testUser = model("User").create(email = "test@example.com");
    }

    function afterAll() {
        // Clean up once per component
        model("Product").deleteAll(where = "name LIKE 'Test%'");
        if (isDefined("variables.testCategory")) variables.testCategory.delete();
        if (isDefined("variables.testUser")) variables.testUser.delete();
    }

    function run() {
        describe("Product Model Tests", function() {

            // Tests can use shared test data - much faster than recreating for each test
            it("should create product with category", function() {
                var product = model("Product").create(
                    name = "Test Product",
                    categoryId = variables.testCategory.id
                );
                expect(product.categoryId).toBe(variables.testCategory.id);
            });

            it("should create product with user", function() {
                var product = model("Product").create(
                    name = "Test User Product", 
                    userId = variables.testUser.id
                );
                expect(product.userId).toBe(variables.testUser.id);
            });

        });
    }
}
```

## Running Tests

### Web Interface

Access tests through the browser:
```
# Run all tests
http://localhost:8080/tests/runner.cfm

# JSON output for CI/CD
http://localhost:8080/tests/runner.cfm?format=json

# Text output
http://localhost:8080/tests/runner.cfm?format=txt

# JUnit XML output
http://localhost:8080/tests/runner.cfm?format=junit
```

### CommandBox CLI

Run tests from the command line:

```bash
# Run all tests
box testbox run

# Run specific test directory
box testbox run --directory=tests/specs/unit

# Run specific test bundle
box testbox run --testBundles=tests.specs.unit.models.UserTest

# Watch mode for continuous testing
box testbox watch

# Generate coverage report
box testbox run --coverage --coverageReporter=html
```

### Wheels CLI Commands

Use Wheels-specific test commands:

```bash
# Run tests (if available)
wheels test run

# Generate test files
wheels generate test model User
wheels generate test controller Products --crud

# Run tests with specific database
wheels test run --db=mysql
```

## Test Configuration

### Test Environment Setup

Configure test-specific settings in `/tests/populate.cfm`:

```cfm
<cfscript>
    // Set test environment variables
    application.wheels.dataSourceName = "myapp_test";
    application.wheels.environment = "testing";
    
    // Disable certain features during testing
    application.wheels.sendEmailOnError = false;
    application.wheels.cachePages = false;
    
    // Create test data
    try {
        // Create test users
        var testUser = model("User").findOne(where = "email = 'test@example.com'");
        if (!isObject(testUser)) {
            testUser = model("User").create({
                email = "test@example.com",
                password = "password123",
                firstName = "Test",
                lastName = "User"
            });
        }
        
        // Create test categories
        var testCategory = model("Category").findOne(where = "name = 'Test Category'");
        if (!isObject(testCategory)) {
            testCategory = model("Category").create({
                name = "Test Category",
                description = "Category for testing"
            });
        }
        
    } catch (any e) {
        writeOutput("Error setting up test data: #e.message#<br>");
    }
</cfscript>
```

### Database Configuration for Testing

Use a separate test database:

```cfm
// In /config/testing/settings.cfm
<cfscript>
    set(dataSourceName = "myapp_test");
    set(environment = "testing");
    set(showErrorInformation = true);
    set(sendEmailOnError = false);
    set(cachePages = false);
    set(cacheQueries = false);
    set(transactionMode = "rollback"); // Auto-rollback transactions
</cfscript>
```

## Best Practices

### Test Organization
1. **Group related tests** in `describe()` blocks by feature or method
2. **Use nested describe blocks** for complex scenarios
3. **Keep test files focused** on single components
4. **Name tests descriptively** - explain the expected behavior

### Test Data Management
1. **Use factories** for consistent test data creation
2. **Clean up after tests** using transactions or explicit cleanup
3. **Avoid dependencies** between tests - each should be independent
4. **Use fixtures** for complex, shared test scenarios

### Test Writing Guidelines
1. **Follow AAA pattern**: Arrange, Act, Assert
2. **Test one thing per test** - single responsibility
3. **Use meaningful assertions** with custom error messages
4. **Test edge cases** - empty data, null values, boundary conditions
5. **Mock external dependencies** - APIs, file systems, email services

### Performance Considerations
1. **Keep tests fast** - optimize slow database operations
2. **Use in-memory databases** for unit tests when possible
3. **Minimize I/O operations** in test setup
4. **Run unit tests frequently**, integration tests less often
5. **Use lifecycle methods efficiently**:
   - **Prefer `beforeAll()` and `afterAll()`** - Run once per test file for expensive setup/teardown
   - **Use `beforeEach()` and `afterEach()` sparingly** - These run before/after every test and can significantly slow down test suites
   - **Only use `beforeEach()`/`afterEach()` when tests need isolated state** - For example, when tests modify shared data

### Continuous Integration
1. **Run tests on every commit** using pre-commit hooks
2. **Use different test databases** for different environments
3. **Generate test reports** for CI/CD pipelines
4. **Monitor code coverage** trends over time

## Common Test Patterns

### Testing Validations
```cfm
it("should require unique email addresses", function() {
    var existingUser = createUser(email = "test@example.com");
    var duplicateUser = buildUser(email = "test@example.com");
    
    expect(duplicateUser.valid()).toBeFalse();
    assertHasErrors(duplicateUser, "email");
});
```

### Testing Callbacks
```cfm
it("should hash password before saving", function() {
    var user = model("User").new(password = "plaintext");
    user.save();
    
    expect(user.passwordHash).notToBe("plaintext");
    expect(len(user.passwordHash)).toBeGT(20);
});
```

### Testing Scopes
```cfm
it("should find only published posts", function() {
    createPost(title = "Published", published = true);
    createPost(title = "Draft", published = false);
    
    var publishedPosts = model("Post").published().findAll();
    expect(publishedPosts.recordCount).toBe(1);
    expect(publishedPosts.title).toBe("Published");
});
```

### Testing Error Handling
```cfm
it("should handle missing records gracefully", function() {
    expect(function() {
        var post = model("Post").findByKey(99999);
        if (!isObject(post)) {
            throw(message = "Post not found");
        }
    }).toThrow();
});
```

### Testing Associations
```cfm
it("should create associated records", function() {
    var user = createUser();
    var post = user.createPost(title = "My Post", content = "Content");
    
    expect(post.userId).toBe(user.id);
    expect(user.posts().recordCount).toBe(1);
});
```

## Migration from Legacy Tests

If you have legacy RocketUnit tests, you can migrate them:

### Syntax Changes
- `assert(expression)` → `expect(result).toBeTrue()`
- `assert(!expression)` → `expect(result).toBeFalse()`
- Test methods → Wrap in `describe()` and `it()` blocks
- `packageSetup()` → `beforeAll()` component-level function
- `setup()` → `beforeEach()` in describe block
- `teardown()` → `afterEach()` in describe block

### Structure Changes
- Move tests to `/tests/specs/` directory
- Change component extension from `app.tests.Test` to `testbox.system.BaseSpec`
- Wrap individual test methods in `it()` blocks within `describe()` blocks

## Testing Resources

### Documentation Links
- [TestBox Documentation](https://testbox.ortusbooks.com/) - Complete TestBox guide
- [MockBox Documentation](https://testbox.ortusbooks.com/v5.x/mockbox) - Mocking framework
- [Wheels Testing Guide](https://wheels.dev/3.0.0/guides/working-with-wheels/testing-your-application) - Framework-specific testing

### Common Matchers
- `toBe(expected)` - Exact equality
- `toBeTrue()` / `toBeFalse()` - Boolean assertions
- `toBeEmpty()` / `notToBeEmpty()` - Empty/non-empty checks
- `toHaveKey(key)` - Struct/object key existence
- `toInclude(substring)` - String/array contains
- `toBeGT(number)` / `toBeLT(number)` - Numeric comparisons
- `toMatch(regex)` - Regular expression matching
- `toThrow()` - Exception testing

This comprehensive testing approach ensures your Wheels application is thoroughly validated across all components while maintaining clean, readable, and maintainable test code.