# wheels generate test

Generate test files for models, controllers, views, and other components.

## Synopsis

```bash
wheels generate test [type] [name] [options]
wheels g test [type] [name] [options]
```

## Description

The `wheels generate test` command creates test files for various components of your Wheels application. It generates appropriate test scaffolding based on the component type and includes common test cases to get you started.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `type` | Type of test (model, controller, view, helper, route) | Required |
| `name` | Name of the component to test | Required |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--methods` | Specific methods to test | All methods |
| `--integration` | Generate integration tests | `false` |
| `--coverage` | Include coverage setup | `false` |
| `--fixtures` | Generate test fixtures | `true` |
| `--force` | Overwrite existing files | `false` |
| `--help` | Show help information | |

## Examples

### Model Test
```bash
wheels generate test model product
```

Generates `/tests/models/ProductTest.cfc`:
```cfc
component extends="wheels.Test" {
    
    function setup() {
        super.setup();
        // Clear test data
        model("Product").deleteAll();
        
        // Setup test fixtures
        variables.validProduct = {
            name: "Test Product",
            price: 19.99,
            description: "Test product description"
        };
    }
    
    function teardown() {
        super.teardown();
        // Clean up after tests
        model("Product").deleteAll();
    }
    
    // Validation Tests
    
    function test_valid_product_saves_successfully() {
        // Arrange
        product = model("Product").new(variables.validProduct);
        
        // Act
        result = product.save();
        
        // Assert
        assert(result, "Product should save successfully");
        assert(product.id > 0, "Product should have an ID after saving");
    }
    
    function test_product_requires_name() {
        // Arrange
        product = model("Product").new(variables.validProduct);
        product.name = "";
        
        // Act
        result = product.save();
        
        // Assert
        assert(!result, "Product should not save without name");
        assert(ArrayLen(product.errorsOn("name")) > 0, "Should have error on name");
    }
    
    function test_product_requires_positive_price() {
        // Arrange
        product = model("Product").new(variables.validProduct);
        product.price = -10;
        
        // Act
        result = product.save();
        
        // Assert
        assert(!result, "Product should not save with negative price");
        assert(ArrayLen(product.errorsOn("price")) > 0, "Should have error on price");
    }
    
    function test_product_name_must_be_unique() {
        // Arrange
        product1 = model("Product").create(variables.validProduct);
        product2 = model("Product").new(variables.validProduct);
        
        // Act
        result = product2.save();
        
        // Assert
        assert(!result, "Should not save duplicate product name");
        assert(ArrayLen(product2.errorsOn("name")) > 0, "Should have uniqueness error");
    }
    
    // Association Tests
    
    function test_product_has_many_reviews() {
        // Arrange
        product = model("Product").create(variables.validProduct);
        review = product.createReview(rating=5, comment="Great product!");
        
        // Act
        reviews = product.reviews();
        
        // Assert
        assert(reviews.recordCount == 1, "Product should have one review");
        assert(reviews.rating == 5, "Review rating should be 5");
    }
    
    // Callback Tests
    
    function test_before_save_sanitizes_input() {
        // Arrange
        product = model("Product").new(variables.validProduct);
        product.name = "  Test Product  ";
        
        // Act
        product.save();
        
        // Assert
        assert(product.name == "Test Product", "Name should be trimmed");
    }
    
    // Scope Tests
    
    function test_active_scope_returns_only_active_products() {
        // Arrange
        activeProduct = model("Product").create(
            variables.validProduct & {isActive: true}
        );
        inactiveProduct = model("Product").create(
            name="Inactive Product",
            price=29.99,
            isActive=false
        );
        
        // Act
        activeProducts = model("Product").active();
        
        // Assert
        assert(activeProducts.recordCount == 1, "Should have one active product");
        assert(activeProducts.id == activeProduct.id, "Should return active product");
    }
    
    // Method Tests
    
    function test_calculate_discount_price() {
        // Arrange
        product = model("Product").create(variables.validProduct);
        
        // Act
        discountPrice = product.calculateDiscountPrice(0.20); // 20% discount
        
        // Assert
        expected = product.price * 0.80;
        assert(discountPrice == expected, "Discount price should be 80% of original");
    }
    
    // Integration Tests
    
    function test_product_lifecycle() {
        transaction {
            // Create
            product = model("Product").new(variables.validProduct);
            assert(product.save(), "Should create product");
            productId = product.id;
            
            // Read
            foundProduct = model("Product").findByKey(productId);
            assert(IsObject(foundProduct), "Should find product");
            assert(foundProduct.name == variables.validProduct.name, "Should have correct name");
            
            // Update
            foundProduct.price = 24.99;
            assert(foundProduct.save(), "Should update product");
            
            // Verify update
            updatedProduct = model("Product").findByKey(productId);
            assert(updatedProduct.price == 24.99, "Price should be updated");
            
            // Delete
            assert(updatedProduct.delete(), "Should delete product");
            
            // Verify deletion
            deletedProduct = model("Product").findByKey(productId);
            assert(!IsObject(deletedProduct), "Product should not exist");
            
            // Rollback transaction
            transaction action="rollback";
        }
    }
    
}
```

### Controller Test
```bash
wheels generate test controller products
```

Generates `/tests/controllers/ProductsTest.cfc`:

### View Test
```bash
wheels generate test view products --name=index
```

Generates a test for the products/index view.

### CRUD Tests
```bash
wheels generate test controller products --crud
```

Generates complete CRUD test methods for the controller.
```cfc
component extends="wheels.Test" {
    
    function setup() {
        super.setup();
        // Setup test data
        model("Product").deleteAll();
        
        variables.testProducts = [];
        for (i = 1; i <= 3; i++) {
            ArrayAppend(variables.testProducts, 
                model("Product").create(
                    name="Product #i#",
                    price=19.99 * i,
                    description="Description #i#"
                )
            );
        }
    }
    
    function teardown() {
        super.teardown();
        model("Product").deleteAll();
    }
    
    // Action Tests
    
    function test_index_returns_all_products() {
        // Act
        result = processRequest(route="products", method="GET");
        
        // Assert
        assert(result.status == 200, "Should return 200 status");
        assert(Find("<h1>Products</h1>", result.body), "Should have products heading");
        
        for (product in variables.testProducts) {
            assert(Find(product.name, result.body), "Should display product: #product.name#");
        }
    }
    
    function test_show_displays_product_details() {
        // Arrange
        product = variables.testProducts[1];
        
        // Act
        result = processRequest(route="product", key=product.id, method="GET");
        
        // Assert
        assert(result.status == 200, "Should return 200 status");
        assert(Find(product.name, result.body), "Should display product name");
        assert(Find(DollarFormat(product.price), result.body), "Should display formatted price");
    }
    
    function test_show_returns_404_for_invalid_product() {
        // Act
        result = processRequest(route="product", key=99999, method="GET");
        
        // Assert
        assert(result.status == 302, "Should redirect");
        assert(result.flash.error == "Product not found.", "Should have error message");
    }
    
    function test_new_displays_form() {
        // Act
        result = processRequest(route="newProduct", method="GET");
        
        // Assert
        assert(result.status == 200, "Should return 200 status");
        assert(Find("<form", result.body), "Should have form");
        assert(Find('name="product[name]"', result.body), "Should have name field");
        assert(Find('name="product[price]"', result.body), "Should have price field");
    }
    
    function test_create_with_valid_data() {
        // Arrange
        params = {
            product: {
                name: "New Test Product",
                price: 39.99,
                description: "New product description"
            }
        };
        
        // Act
        result = processRequest(route="products", method="POST", params=params);
        
        // Assert
        assert(result.status == 302, "Should redirect after creation");
        assert(result.flash.success == "Product was created successfully.", "Should have success message");
        
        // Verify product was created
        newProduct = model("Product").findOne(where="name='New Test Product'");
        assert(IsObject(newProduct), "Product should be created");
        assert(newProduct.price == 39.99, "Should have correct price");
    }
    
    function test_create_with_invalid_data() {
        // Arrange
        params = {
            product: {
                name: "",
                price: -10,
                description: "Invalid product"
            }
        };
        
        // Act
        result = processRequest(route="products", method="POST", params=params);
        
        // Assert
        assert(result.status == 200, "Should render form again");
        assert(Find("error", result.body), "Should display errors");
        assert(model("Product").count(where="description='Invalid product'") == 0, 
               "Should not create invalid product");
    }
    
    function test_edit_displays_form_with_product_data() {
        // Arrange
        product = variables.testProducts[1];
        
        // Act
        result = processRequest(route="editProduct", key=product.id, method="GET");
        
        // Assert
        assert(result.status == 200, "Should return 200 status");
        assert(Find('value="#product.name#"', result.body), "Should pre-fill name");
        assert(Find(ToString(product.price), result.body), "Should pre-fill price");
    }
    
    function test_update_with_valid_data() {
        // Arrange
        product = variables.testProducts[1];
        params = {
            product: {
                name: "Updated Product Name",
                price: 49.99
            }
        };
        
        // Act
        result = processRequest(route="product", key=product.id, method="PUT", params=params);
        
        // Assert
        assert(result.status == 302, "Should redirect after update");
        assert(result.flash.success == "Product was updated successfully.", "Should have success message");
        
        // Verify update
        updatedProduct = model("Product").findByKey(product.id);
        assert(updatedProduct.name == "Updated Product Name", "Name should be updated");
        assert(updatedProduct.price == 49.99, "Price should be updated");
    }
    
    function test_delete_removes_product() {
        // Arrange
        product = variables.testProducts[1];
        initialCount = model("Product").count();
        
        // Act
        result = processRequest(route="product", key=product.id, method="DELETE");
        
        // Assert
        assert(result.status == 302, "Should redirect after deletion");
        assert(result.flash.success == "Product was deleted successfully.", "Should have success message");
        assert(model("Product").count() == initialCount - 1, "Should have one less product");
        assert(!IsObject(model("Product").findByKey(product.id)), "Product should be deleted");
    }
    
    // Filter Tests
    
    function test_authentication_required_for_protected_actions() {
        // Test that certain actions require authentication
        protectedRoutes = [
            {route: "newProduct", method: "GET"},
            {route: "products", method: "POST"},
            {route: "editProduct", key: variables.testProducts[1].id, method: "GET"},
            {route: "product", key: variables.testProducts[1].id, method: "PUT"},
            {route: "product", key: variables.testProducts[1].id, method: "DELETE"}
        ];
        
        for (route in protectedRoutes) {
            // Act without authentication
            result = processRequest(argumentCollection=route);
            
            // Assert
            assert(result.status == 302, "Should redirect unauthenticated user");
            assert(result.redirectUrl contains "login", "Should redirect to login");
        }
    }
    
    // Helper method for processing requests
    private function processRequest(
        required string route,
        string method = "GET",
        struct params = {},
        numeric key = 0
    ) {
        local.args = {
            route: arguments.route,
            method: arguments.method,
            params: arguments.params
        };
        
        if (arguments.key > 0) {
            local.args.key = arguments.key;
        }
        
        return $processRequest(argumentCollection=local.args);
    }
    
}
```

### View Test
```bash
wheels generate test view products/index
```

Generates `/tests/views/products/IndexTest.cfc`:
```cfc
component extends="wheels.Test" {
    
    function setup() {
        super.setup();
        // Create test data
        variables.products = QueryNew(
            "id,name,price,createdAt",
            "integer,varchar,decimal,timestamp"
        );
        
        for (i = 1; i <= 3; i++) {
            QueryAddRow(variables.products, {
                id: i,
                name: "Product #i#",
                price: 19.99 * i,
                createdAt: Now()
            });
        }
    }
    
    function test_index_view_renders_product_list() {
        // Act
        result = $renderView(
            view="/products/index",
            products=variables.products,
            layout=false
        );
        
        // Assert
        assert(Find("<h1>Products</h1>", result), "Should have products heading");
        assert(Find("<table", result), "Should have products table");
        assert(Find("Product 1", result), "Should display first product");
        assert(Find("Product 2", result), "Should display second product");
        assert(Find("Product 3", result), "Should display third product");
    }
    
    function test_index_view_shows_empty_state() {
        // Arrange
        emptyQuery = QueryNew("id,name,price,createdAt");
        
        // Act
        result = $renderView(
            view="/products/index",
            products=emptyQuery,
            layout=false
        );
        
        // Assert
        assert(Find("No products found", result), "Should show empty state message");
        assert(Find("Create one now", result), "Should have create link");
        assert(!Find("<table", result), "Should not show table when empty");
    }
    
    function test_index_view_formats_prices_correctly() {
        // Act
        result = $renderView(
            view="/products/index",
            products=variables.products,
            layout=false
        );
        
        // Assert
        assert(Find("$19.99", result), "Should format first price");
        assert(Find("$39.98", result), "Should format second price");
        assert(Find("$59.97", result), "Should format third price");
    }
    
    function test_index_view_includes_action_links() {
        // Act
        result = $renderView(
            view="/products/index",
            products=variables.products,
            layout=false
        );
        
        // Assert
        assert(Find("New Product", result), "Should have new product link");
        assert(FindNoCase("href=""/products/new""", result), "New link should be correct");
        
        // Check action links for each product
        for (row in variables.products) {
            assert(Find("View</a>", result), "Should have view link");
            assert(Find("Edit</a>", result), "Should have edit link");
            assert(Find("Delete</a>", result), "Should have delete link");
        }
    }
    
    function test_index_view_with_pagination() {
        // Arrange
        paginatedProducts = Duplicate(variables.products);
        paginatedProducts.currentPage = 2;
        paginatedProducts.totalPages = 5;
        paginatedProducts.totalRecords = 50;
        
        // Act
        result = $renderView(
            view="/products/index",
            products=paginatedProducts,
            layout=false
        );
        
        // Assert
        assert(Find("class=""pagination""", result), "Should have pagination");
        assert(Find("Previous", result), "Should have previous link");
        assert(Find("Next", result), "Should have next link");
        assert(Find("Page 2 of 5", result), "Should show current page");
    }
    
    function test_index_view_escapes_html() {
        // Arrange
        productsWithHtml = QueryNew("id,name,price,createdAt");
        QueryAddRow(productsWithHtml, {
            id: 1,
            name: "<script>alert('XSS')</script>",
            price: 19.99,
            createdAt: Now()
        });
        
        // Act
        result = $renderView(
            view="/products/index",
            products=productsWithHtml,
            layout=false
        );
        
        // Assert
        assert(!Find("<script>alert('XSS')</script>", result), 
               "Should not have unescaped script tag");
        assert(Find("&lt;script&gt;", result), "Should have escaped HTML");
    }
    
}
```

### Integration Test
```bash
wheels generate test controller products --integration
```

Generates additional integration tests:
```cfc
component extends="wheels.Test" {
    
    function test_complete_product_workflow() {
        transaction {
            // 1. View product list (empty)
            result = $visit(route="products");
            assert(result.status == 200);
            assert(Find("No products found", result.body));
            
            // 2. Navigate to new product form
            result = $click("Create one now");
            assert(result.status == 200);
            assert(Find("<form", result.body));
            
            // 3. Submit new product form
            result = $submitForm({
                "product[name]": "Integration Test Product",
                "product[price]": "29.99",
                "product[description]": "Test description"
            });
            assert(result.status == 302);
            assert(result.flash.success);
            
            // 4. View created product
            product = model("Product").findOne(order="id DESC");
            result = $visit(route="product", key=product.id);
            assert(result.status == 200);
            assert(Find("Integration Test Product", result.body));
            
            // 5. Edit product
            result = $click("Edit");
            assert(Find('value="Integration Test Product"', result.body));
            
            result = $submitForm({
                "product[name]": "Updated Product",
                "product[price]": "39.99"
            });
            assert(result.status == 302);
            
            // 6. Verify update
            result = $visit(route="product", key=product.id);
            assert(Find("Updated Product", result.body));
            assert(Find("$39.99", result.body));
            
            // 7. Delete product
            result = $click("Delete", confirm=true);
            assert(result.status == 302);
            assert(result.flash.success contains "deleted");
            
            // 8. Verify deletion
            assert(!IsObject(model("Product").findByKey(product.id)));
            
            transaction action="rollback";
        }
    }
    
}
```

## Test Types

### Model Tests
Focus on:
- Validations
- Associations
- Callbacks
- Scopes
- Custom methods
- Data integrity

### Controller Tests
Focus on:
- Action responses
- Parameter handling
- Authentication/authorization
- Flash messages
- Redirects
- Error handling

### View Tests
Focus on:
- Content rendering
- Data display
- HTML structure
- Escaping/security
- Conditional display
- Helpers usage

### Helper Tests
```bash
wheels generate test helper format
```

```cfc
component extends="wheels.Test" {
    
    function test_format_currency() {
        assert(formatCurrency(19.99) == "$19.99");
        assert(formatCurrency(1000) == "$1,000.00");
        assert(formatCurrency(0) == "$0.00");
        assert(formatCurrency(-50.5) == "-$50.50");
    }
    
}
```

### Route Tests
```bash
wheels generate test route products
```

```cfc
component extends="wheels.Test" {
    
    function test_products_routes() {
        // Test route resolution
        assert($resolveRoute("/products") == {controller: "products", action: "index"});
        assert($resolveRoute("/products/new") == {controller: "products", action: "new"});
        assert($resolveRoute("/products/123") == {controller: "products", action: "show", key: "123"});
        
        // Test route generation
        assert(urlFor(route="products") == "/products");
        assert(urlFor(route="product", key=123) == "/products/123");
        assert(urlFor(route="newProduct") == "/products/new");
    }
    
}
```

## Test Fixtures

### Generate Fixtures
```bash
wheels generate test model product --fixtures
```

Creates `/tests/fixtures/products.cfc`:
```cfc
component {
    
    function load() {
        // Clear existing data
        model("Product").deleteAll();
        
        // Load fixture data
        fixtures = [
            {
                name: "Widget",
                price: 19.99,
                description: "Standard widget",
                categoryId: 1,
                isActive: true
            },
            {
                name: "Gadget",
                price: 29.99,
                description: "Premium gadget",
                categoryId: 2,
                isActive: true
            },
            {
                name: "Doohickey",
                price: 9.99,
                description: "Budget doohickey",
                categoryId: 1,
                isActive: false
            }
        ];
        
        for (fixture in fixtures) {
            model("Product").create(fixture);
        }
        
        return fixtures;
    }
    
    function loadWithAssociations() {
        products = load();
        
        // Add reviews
        model("Review").create(
            productId: products[1].id,
            rating: 5,
            comment: "Excellent product!"
        );
        
        return products;
    }
    
}
```

## Test Helpers

### Custom Assertions
```cfc
// In test file
function assertProductValid(required any product) {
    assert(IsObject(arguments.product), "Product should be an object");
    assert(arguments.product.id > 0, "Product should have valid ID");
    assert(Len(arguments.product.name), "Product should have name");
    assert(arguments.product.price > 0, "Product should have positive price");
}

function assertHasError(required any model, required string property) {
    local.errors = arguments.model.errorsOn(arguments.property);
    assert(ArrayLen(local.errors) > 0, 
           "Expected error on #arguments.property# but found none");
}
```

### Test Data Builders
```cfc
function createTestProduct(struct overrides = {}) {
    local.defaults = {
        name: "Test Product #CreateUUID()#",
        price: RandRange(10, 100) + (RandRange(0, 99) / 100),
        description: "Test description",
        isActive: true
    };
    
    StructAppend(local.defaults, arguments.overrides, true);
    
    return model("Product").create(local.defaults);
}

function createTestUser(struct overrides = {}) {
    local.defaults = {
        email: "test-#CreateUUID()#@example.com",
        password: "password123",
        firstName: "Test",
        lastName: "User"
    };
    
    StructAppend(local.defaults, arguments.overrides, true);
    
    return model("User").create(local.defaults);
}
```

## Running Tests

### Run all tests
```bash
wheels test
```

### Run specific test file
```bash
wheels test app tests/models/ProductTest.cfc
```

### Run specific test method
```bash
wheels test app tests/models/ProductTest.cfc::test_product_requires_name
```

### Run with coverage
```bash
wheels test --coverage
```

## Best Practices

1. **Test in isolation**: Each test should be independent
2. **Use descriptive names**: Test names should explain what they test
3. **Follow AAA pattern**: Arrange, Act, Assert
4. **Clean up data**: Use setup/teardown or transactions
5. **Test edge cases**: Empty data, nulls, extremes
6. **Mock external services**: Don't rely on external APIs
7. **Keep tests fast**: Optimize slow tests
8. **Test one thing**: Each test should verify one behavior
9. **Use fixtures wisely**: Share common test data
10. **Run tests frequently**: Before commits and in CI

## Common Testing Patterns

### Testing Private Methods
```cfc
function test_private_method_through_public_interface() {
    // Don't test private methods directly
    // Test them through public methods that use them
    product = model("Product").new(name: "  Test  ");
    product.save(); // Calls private sanitize method
    assert(product.name == "Test");
}
```

### Testing Time-Dependent Code
```cfc
function test_expiration_date() {
    // Use specific dates instead of Now()
    testDate = CreateDate(2024, 1, 1);
    product = model("Product").new(
        expiresAt: DateAdd("d", 30, testDate)
    );
    
    // Test with mocked current date
    request.currentDate = testDate;
    assert(!product.isExpired());
    
    request.currentDate = DateAdd("d", 31, testDate);
    assert(product.isExpired());
}
```

### Testing Randomness
```cfc
function test_random_discount() {
    // Test the range, not specific values
    product = model("Product").new(price: 100);
    
    for (i = 1; i <= 100; i++) {
        discount = product.getRandomDiscount();
        assert(discount >= 0.05 && discount <= 0.25, 
               "Discount should be between 5% and 25%");
    }
}
```

## See Also

- [wheels test run](../testing/test-run.md) - Run tests
- [wheels test coverage](../testing/test-coverage.md) - Test coverage
- [Testing Guide](../../../working-with-wheels/testing-your-application.md) - Testing documentation