# Controller Model Interactions

## Description
Comprehensive guide to how controllers interact with models in Wheels, including CRUD operations, association handling, validation, and data loading patterns.

## 🚨 CRITICAL REMINDERS

**Model Argument Consistency:**
ALL model method calls in controllers MUST use consistent argument syntax - either all named OR all positional arguments. Mixed arguments will cause "Missing argument name" errors.

**Association Return Types:**
Model associations return QUERY objects, not arrays. Use `.recordCount` for counts and `<cfloop query="...">` for iteration in views.

## Basic Model Operations in Controllers

### Index Action - Listing Records
```cfm
function index() {
    // Find all records with common controller patterns
    products = model("Product").findAll(
        page=params.page ?: 1,
        perPage=25,
        order="createdAt DESC"
    );

    // With search filtering
    if (StructKeyExists(params, "q") && len(params.q)) {
        products = model("Product").findAll(
            where="name LIKE '%#params.q#%' OR description LIKE '%#params.q#%'",
            page=params.page ?: 1,
            perPage=25
        );
    }
}
```

### Show Action - Finding Single Record
```cfm
function show() {
    // Find by primary key with error handling
    product = model("Product").findByKey(params.key);

    if (!IsObject(product)) {
        redirectTo(action="index", error="Product not found");
        return;
    }

    // Load related data for display
    product = model("Product").findByKey(
        key=params.key,
        include="category,reviews.user"
    );
}
```

### New Action - Creating Form Objects
```cfm
function new() {
    // Create new model instance for form
    product = model("Product").new();

    // Load related data for form dropdowns
    categories = model("Category").findAll(order="name");
}
```

### Create Action - Processing Form Data
```cfm
function create() {
    // Create with form data and handle validation
    product = model("Product").create(params.product);

    if (product.hasErrors()) {
        // Re-display form with errors
        categories = model("Category").findAll(order="name");
        renderView(action="new");
    } else {
        redirectTo(action="show", key=product.id, success="Product created successfully");
    }
}
```

### Edit Action - Loading for Editing
```cfm
function edit() {
    // Load record for editing
    product = model("Product").findByKey(params.key);
    categories = model("Category").findAll(order="name");
}
```

### Update Action - Modifying Records
```cfm
function update() {
    // Update existing record
    product = model("Product").findByKey(params.key);

    if (product.update(params.product)) {
        redirectTo(action="show", key=product.id, success="Product updated successfully");
    } else {
        categories = model("Category").findAll(order="name");
        renderView(action="edit");
    }
}
```

### Delete Action - Removing Records
```cfm
function delete() {
    // Delete record with confirmation
    product = model("Product").findByKey(params.key);
    product.delete();
    redirectTo(action="index", success="Product deleted successfully");
}
```

## Pagination in Controllers

### Standard Pagination Pattern
```cfm
function index() {
    // Standard pagination pattern
    products = model("Product").findAll(
        page=params.page ?: 1,
        perPage=params.perPage ?: 25,
        order="name"
    );

    // Make pagination info available to view
    pagination = {
        currentPage: products.currentPage,
        totalPages: products.pageCount,
        totalRecords: products.totalRecords
    };
}
```

### Pagination with Search
```cfm
function search() {
    local.searchOptions = {
        page: params.page ?: 1,
        perPage: 20,
        order: "createdAt DESC"
    };

    // Add search conditions
    if (len(params.q ?: "")) {
        local.searchOptions.where = "name LIKE '%#params.q#%' OR description LIKE '%#params.q#%'";
    }

    products = model("Product").findAll(argumentCollection=local.searchOptions);
}
```

## Search and Filtering

### Building Dynamic Where Clauses
```cfm
function search() {
    local.where = "";
    local.conditions = [];

    // Build where clause dynamically
    if (Len(params.q ?: "")) {
        arrayAppend(local.conditions, "name LIKE '%#params.q#%' OR description LIKE '%#params.q#%'");
    }

    if (IsNumeric(params.categoryId ?: "")) {
        arrayAppend(local.conditions, "categoryId = #params.categoryId#");
    }

    if (IsNumeric(params.minPrice ?: "")) {
        arrayAppend(local.conditions, "price >= #params.minPrice#");
    }

    if (IsNumeric(params.maxPrice ?: "")) {
        arrayAppend(local.conditions, "price <= #params.maxPrice#");
    }

    // Combine conditions
    if (arrayLen(local.conditions)) {
        local.where = arrayToList(local.conditions, " AND ");
    }

    products = model("Product").findAll(
        where=local.where,
        page=params.page ?: 1,
        perPage=25
    );
}
```

### Advanced Search with Parameterized Queries
```cfm
function advancedSearch() {
    local.where = "";
    local.params = {};

    // Use parameterized queries for security
    if (len(params.q ?: "")) {
        local.where = "name LIKE :search OR description LIKE :search";
        local.params.search = "%#params.q#%";
    }

    if (IsNumeric(params.categoryId ?: "")) {
        if (len(local.where)) {
            local.where &= " AND ";
        }
        local.where &= "categoryId = :categoryId";
        local.params.categoryId = params.categoryId;
    }

    products = model("Product").findAll(
        where=local.where,
        params=local.params,
        page=params.page ?: 1,
        perPage=25
    );
}
```

## Association Loading

### Eager Loading to Avoid N+1 Queries
```cfm
function dashboard() {
    // Load multiple models efficiently
    recentProducts = model("Product").findAll(
        limit=5,
        order="createdAt DESC",
        include="category"  // Avoid N+1 queries
    );

    topCategories = model("Category").findAll(
        joins="INNER JOIN products p ON categories.id = p.categoryId",
        group="categories.id",
        order="COUNT(p.id) DESC",
        limit=10
    );

    // Use statistical functions
    totalProducts = model("Product").count();
    averagePrice = model("Product").average("price");
}
```

### Complex Association Loading
```cfm
function userProfile() {
    user = model("User").findByKey(
        key=params.key,
        include="profile,posts.comments.author,orders.items.product"
    );

    if (!IsObject(user)) {
        redirectTo(action="index", error="User not found");
    }
}
```

### Handling Association Queries
```cfm
function showPost() {
    post = model("Post").findByKey(params.key);

    if (!IsObject(post)) {
        redirectTo(action="index", error="Post not found");
    }

    // Get comments (returns QUERY, not array)
    comments = post.comments();

    // Get comment count
    commentCount = comments.recordCount;

    // Check if has comments
    hasComments = comments.recordCount > 0;
}
```

## Validation Handling

### Standard Validation Pattern
```cfm
function create() {
    product = model("Product").new(params.product);

    if (product.save()) {
        redirectTo(action="show", key=product.id, success="Created successfully");
    } else {
        // Make errors available to view
        errors = product.allErrors();

        // Reload supporting data
        categories = model("Category").findAll(order="name");

        renderView(action="new");
    }
}
```

### Advanced Validation Handling
```cfm
function update() {
    product = model("Product").findByKey(params.key);

    if (product.update(params.product)) {
        redirectTo(action="show", key=product.id, success="Updated successfully");
    } else {
        // Handle specific validation errors
        if (product.hasErrors("name")) {
            flashInsert(error="Product name is required and must be unique");
        }

        if (product.hasErrors("price")) {
            flashInsert(error="Price must be a positive number");
        }

        // Reload form data
        categories = model("Category").findAll(order="name");
        renderView(action="edit");
    }
}
```

### Bulk Operations with Validation
```cfm
function bulkUpdate() {
    errors = [];
    successes = 0;

    for (productId in params.selectedIds) {
        product = model("Product").findByKey(productId);

        if (IsObject(product)) {
            if (product.update(params.bulkData)) {
                successes++;
            } else {
                arrayAppend(errors, "Product ##productId##: #arrayToList(product.errorMessages())#");
            }
        }
    }

    if (successes > 0) {
        flashInsert(success="#successes# products updated");
    }
    if (arrayLen(errors) > 0) {
        flashInsert(error="Errors: #arrayToList(errors, '; ')#");
    }

    redirectTo(action="index");
}
```

## Dynamic Finders in Controllers

### Basic Dynamic Finders
```cfm
function findByEmail() {
    // Use dynamic finders for specific searches
    user = model("User").findOneByEmail(params.email);

    if (IsObject(user)) {
        renderWith(user);
    } else {
        renderWith(data={error: "User not found"}, status=404);
    }
}

function filterByStatus() {
    // Dynamic finder with additional parameters
    products = model("Product").findAllByStatus(
        value=params.status,
        order="createdAt DESC",
        page=params.page ?: 1
    );
}
```

### Multiple Property Finders
```cfm
function findByLocation() {
    // Find by multiple properties
    users = model("User").findAllByCityAndState(
        values="#params.city#,#params.state#",
        order="lastName",
        page=params.page ?: 1
    );
}
```

## Statistical Queries in Controllers

### Basic Statistics
```cfm
function reports() {
    // Use model statistical functions
    totalRevenue = model("Order").sum("total", where="status = 'completed'");
    averageOrderValue = model("Order").average("total", where="status = 'completed'");
    orderCount = model("Order").count(where="status = 'completed'");

    // Complex statistics with raw SQL
    local.sql = "SELECT p.*, COUNT(oi.id) as orderCount
        FROM products p
        INNER JOIN orderItems oi ON p.id = oi.productId
        GROUP BY p.id
        ORDER BY orderCount DESC
        LIMIT 10";

    topProducts = queryExecute(local.sql, {}, {datasource = application.datasource});
}
```

### Dashboard Statistics
```cfm
function dashboard() {
    // Current user's statistics
    userStats = {
        postCount = model("Post").count(where="authorId = #currentUser.id#"),
        commentCount = model("Comment").count(where="userId = #currentUser.id#"),
        totalViews = model("Post").sum("viewCount", where="authorId = #currentUser.id#"),
        averageRating = model("Post").average("rating", where="authorId = #currentUser.id#")
    };

    // System-wide statistics
    systemStats = {
        totalUsers = model("User").count(),
        activeUsers = model("User").count(where="lastLoginAt > '#dateAdd("d", -30, now())#'"),
        totalPosts = model("Post").count(),
        publishedPosts = model("Post").count(where="status = 'published'")
    };
}
```

## Change Tracking in Controllers

### Detecting Changes
```cfm
function update() {
    product = model("Product").findByKey(params.key);
    originalPrice = product.price;

    if (product.update(params.product)) {
        // Use dirty tracking to detect changes
        if (product.hasChanged("price")) {
            // Log price change
            writeLog("Price changed for product #product.id#: #originalPrice# to #product.price#");
        }

        redirectTo(action="show", key=product.id, success="Updated successfully");
    } else {
        renderView(action="edit");
    }
}
```

### Tracking All Changes
```cfm
function auditedUpdate() {
    product = model("Product").findByKey(params.key);

    // Get all changed properties
    if (product.update(params.product)) {
        changedProps = product.changedProperties();

        for (prop in changedProps) {
            oldValue = product.changedFrom(prop);
            newValue = product[prop];

            // Log each change
            model("AuditLog").create({
                tableName = "products",
                recordId = product.id,
                fieldName = prop,
                oldValue = oldValue,
                newValue = newValue,
                changedBy = currentUser.id,
                changedAt = now()
            });
        }

        redirectTo(action="show", key=product.id, success="Updated successfully");
    }
}
```

## Nested Properties in Controllers

### One-to-One Nested Properties
```cfm
function new() {
    // Create user with nested profile
    newProfile = model("Profile").new();
    user = model("User").new(profile=newProfile);
}

function create() {
    // Save user and profile together
    user = model("User").new(params.user);

    if (user.save()) {
        redirectTo(action="show", key=user.id, success="User created with profile");
    } else {
        renderView(action="new");
    }
}
```

### One-to-Many Nested Properties
```cfm
function new() {
    // Create customer with addresses
    newAddresses = [model("Address").new(), model("Address").new()];
    customer = model("Customer").new(addresses=newAddresses);
}

function create() {
    customer = model("Customer").new(params.customer);

    if (customer.save()) {
        redirectTo(action="show", key=customer.id, success="Customer created with addresses");
    } else {
        // Reload form with errors
        renderView(action="new");
    }
}
```

## Transaction Handling

### Manual Transactions
```cfm
function transferFunds() {
    fromAccount = model("Account").findByKey(params.fromAccountId);
    toAccount = model("Account").findByKey(params.toAccountId);
    amount = params.amount;

    transaction {
        // Withdraw from source account
        if (!fromAccount.withdraw(amount)) {
            transaction action="rollback";
            redirectTo(action="index", error="Insufficient funds");
            return;
        }

        // Deposit to destination account
        if (!toAccount.deposit(amount)) {
            transaction action="rollback";
            redirectTo(action="index", error="Transfer failed");
            return;
        }

        // Log transaction
        model("Transaction").create({
            fromAccountId = fromAccount.id,
            toAccountId = toAccount.id,
            amount = amount,
            type = "transfer",
            timestamp = now()
        });
    }

    redirectTo(action="index", success="Transfer completed successfully");
}
```

### Complex Multi-Model Operations
```cfm
function processOrder() {
    order = model("Order").findByKey(params.key);

    transaction {
        // Update order status
        if (!order.update(status="processing")) {
            transaction action="rollback";
            redirectTo(action="show", key=order.id, error="Could not process order");
            return;
        }

        // Update inventory for each item
        for (item in order.orderItems()) {
            product = item.product();
            if (!product.decrementStock(item.quantity)) {
                transaction action="rollback";
                redirectTo(action="show", key=order.id, error="Insufficient inventory for #product.name#");
                return;
            }
        }

        // Send confirmation email
        try {
            sendOrderConfirmation(order);
        } catch (any e) {
            writeLog("Failed to send order confirmation: #e.message#");
            // Don't rollback for email failures
        }
    }

    redirectTo(action="show", key=order.id, success="Order processed successfully");
}
```

## Error Handling with Models

### Graceful Model Error Handling
```cfm
function show() {
    try {
        product = model("Product").findByKey(params.key);

        if (!IsObject(product)) {
            redirectTo(action="index", error="Product not found");
            return;
        }

        // Load related data that might fail
        try {
            reviews = product.reviews();
            avgRating = reviews.recordCount > 0 ? product.averageRating() : 0;
        } catch (any e) {
            writeLog("Failed to load product reviews: #e.message#");
            reviews = queryNew("id");
            avgRating = 0;
        }

    } catch (any e) {
        writeLog("Error in product show: #e.message#");
        redirectTo(action="index", error="An error occurred while loading the product");
    }
}
```

### Validation Error Handling
```cfm
function safeCreate() {
    try {
        product = model("Product").new(params.product);

        if (product.save()) {
            redirectTo(action="show", key=product.id, success="Product created");
        } else {
            // Handle validation errors gracefully
            errorMessages = [];
            for (error in product.allErrors()) {
                arrayAppend(errorMessages, error.message);
            }

            flashInsert(error="Please correct these errors: #arrayToList(errorMessages, ', ')#");
            renderView(action="new");
        }
    } catch (any e) {
        writeLog("Error creating product: #e.message#");
        flashInsert(error="An unexpected error occurred while creating the product");
        renderView(action="new");
    }
}
```

## Performance Optimization

### Efficient Query Patterns
```cfm
function optimizedIndex() {
    // Use specific columns to reduce memory usage
    products = model("Product").findAll(
        select="id,name,price,createdAt",
        order="createdAt DESC",
        page=params.page ?: 1,
        perPage=25
    );

    // Use count for pagination instead of loading all records
    totalProducts = model("Product").count();
}
```

### Caching Model Results
```cfm
function cachedReports() {
    cacheKey = "monthly_report_#dateFormat(now(), 'yyyy-mm')#";

    if (!cacheKeyExists(cacheKey)) {
        reportData = {
            totalSales = model("Order").sum("total", where="status = 'completed'"),
            orderCount = model("Order").count(where="status = 'completed'"),
            topProducts = getTopProducts()
        };

        cachePut(cacheKey, reportData, createTimeSpan(0, 6, 0, 0)); // Cache for 6 hours
    }

    reportData = cacheGet(cacheKey);
}
```

## Best Practices

### 1. Use Consistent Argument Syntax
```cfm
// ✅ GOOD: All named arguments
product = model("Product").findByKey(key=params.key, include="category");

// ❌ BAD: Mixed arguments
product = model("Product").findByKey(params.key, include="category");
```

### 2. Handle Missing Records Gracefully
```cfm
// ✅ GOOD: Check for null and redirect
product = model("Product").findByKey(params.key);
if (!IsObject(product)) {
    redirectTo(action="index", error="Product not found");
    return;
}
```

### 3. Use Eager Loading for Performance
```cfm
// ✅ GOOD: Load associations upfront
products = model("Product").findAll(include="category,reviews");

// ❌ BAD: Causes N+1 queries
products = model("Product").findAll();
// Then accessing product.category() in view causes N+1 queries
```

### 4. Validate Input Properly
```cfm
// ✅ GOOD: Proper validation handling
if (product.save()) {
    redirectTo(action="show", key=product.id, success="Created");
} else {
    renderView(action="new");
}
```

## Related Documentation
- [Model Architecture](../models/architecture.md)
- [Model Associations](../models/associations.md)
- [Model Validations](../models/validations.md)
- [Controller Architecture](./architecture.md)
- [Controller Rendering](./rendering.md)