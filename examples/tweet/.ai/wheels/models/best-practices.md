# Model Best Practices

## Description
Essential best practices for developing maintainable, secure, and performant Wheels models.

## Model Organization and Structure

### 1. Logical config() Method Organization
```cfm
/**
 * Organize config() method logically for maintainability
 */
function config() {
    // 1. Table configuration (if different from convention)
    table("custom_table_name");

    // 2. Associations (grouped by type)
    belongsTo("category");
    belongsTo("author", modelName="User", foreignKey="authorid");
    hasMany("comments");
    hasOne("profile");

    // 3. Validations (grouped by type)
    validatesPresenceOf("name,email");
    validatesUniquenessOf("email");
    validatesLengthOf(property="name", maximum=100);
    validatesFormatOf(property="email", with="^[^\s@]+@[^\s@]+\.[^\s@]+$");

    // 4. Custom properties
    property(name="customField", type="string");
    property(name="fullName", sql=false); // Virtual property

    // 5. Callbacks (in lifecycle order)
    beforeValidation("normalizeData");
    beforeSave("updateTimestamps");
    afterCreate("sendNotification");

    // 6. Other configuration
    set(timeStampOnCreateProperty="createdAt");
    set(timeStampOnUpdateProperty="updatedAt");
    // Note: Soft delete enabled automatically if deletedat column exists
}
```

### 2. Clear Method Organization
```cfm
component extends="Model" {

    function config() {
        // Configuration here
    }

    // === CLASS METHODS (Static-like) ===

    /**
     * Custom finder methods
     */
    function findByEmail(required string email) {
        return findOne(where="email = '#arguments.email#'");
    }

    function findActive() {
        return findAll(where="isactive = 1");
    }

    // === INSTANCE METHODS ===

    /**
     * Business logic methods
     */
    function getFullName() {
        return trim("#this.firstname# #this.lastname#");
    }

    function isAdmin() {
        return this.role.name == "administrator";
    }

    // === CALLBACK METHODS (Private) ===

    /**
     * Callback implementations
     */
    private void function normalizeData() {
        if (len(this.email)) {
            this.email = lCase(trim(this.email));
        }
    }

    // === VALIDATION METHODS (Private) ===

    /**
     * Custom validation methods
     */
    private void function validatePasswordStrength() {
        // Password strength validation logic
    }

    // === HELPER METHODS (Private) ===

    /**
     * Internal helper methods
     */
    private string function generateSlug(required string text) {
        // Slug generation logic
    }
}
```

## Business Logic Placement

### 1. Keep Complex Business Logic in Models
```cfm
component extends="Model" {

    /**
     * ✅ GOOD: Complex business logic belongs in models
     */
    function calculateShippingCost(required string shippingMethod) {
        switch (arguments.shippingMethod) {
            case "standard":
                return this.weight * 0.5 + 5.99;
            case "express":
                return this.weight * 1.0 + 12.99;
            case "overnight":
                return this.weight * 2.0 + 24.99;
            default:
                return 0;
        }
    }

    /**
     * ✅ GOOD: Provide clear interfaces for complex operations
     */
    function processOrder() {
        transaction {
            this.status = "processing";
            this.processedAt = now();

            // Update inventory
            for (local.item in this.orderItems()) {
                local.item.product().decrementStock(local.item.quantity);
            }

            // Send confirmation
            this.sendConfirmationEmail();

            this.save();
        }
    }

    /**
     * ✅ GOOD: Encapsulate business rules
     */
    function canBeModified() {
        return this.status == "draft" || this.status == "pending";
    }

    /**
     * ✅ GOOD: Domain-specific calculations
     */
    function getDiscountedPrice() {
        if (this.salePrice > 0 && this.salePrice < this.price) {
            return this.salePrice;
        }
        return this.price;
    }
}
```

### 2. Use Service Objects for Very Complex Operations
```cfm
// ✅ GOOD: Move extremely complex logic to services
component extends="Model" {

    function processComplexOrder() {
        // Delegate to service for complex operations
        local.orderService = createObject("component", "services.OrderService");
        return local.orderService.processOrder(this);
    }

    function generateReport() {
        local.reportService = createObject("component", "services.ReportService");
        return local.reportService.generateOrderReport(this);
    }
}
```

## Security Best Practices

### 1. Mass Assignment Protection
```cfm
component extends="Model" {

    function config() {
        // ✅ RECOMMENDED: Protect sensitive properties
        protectedProperties("isAdmin,createdat,updatedat,passwordHash");

        // ✅ ALTERNATIVE: Whitelist approach (more secure)
        accessibleProperties("name,email,bio,phone");
    }
}
```

### 2. Input Sanitization and Validation
```cfm
component extends="Model" {

    function config() {
        // Always validate input
        validatesPresenceOf("name,email");
        validatesFormatOf(property="email", with="^[^\s@]+@[^\s@]+\.[^\s@]+$");

        // Custom validation for complex rules
        validate(method="sanitizeInput");
    }

    /**
     * ✅ GOOD: Sanitize input data
     */
    private void function sanitizeInput() {
        if (len(this.bio)) {
            // Remove potentially harmful HTML
            this.bio = reReplace(this.bio, "<script[^>]*>.*?</script>", "", "all");
            this.bio = reReplace(this.bio, "javascript:", "", "all");
            this.bio = htmlEditFormat(this.bio);
        }
    }
}
```

### 3. Secure Password Handling
```cfm
component extends="Model" {

    function config() {
        beforeCreate("generateSalt");
        beforeSave("hashPasswordIfChanged");

        // Protect password fields
        protectedProperties("passwordHash,salt");
    }

    /**
     * ✅ GOOD: Secure password hashing
     */
    private void function hashPasswordIfChanged() {
        if (hasChanged("password") && len(this.password)) {
            this.passwordHash = hash(this.password & this.salt, "SHA-256");
            // Clear plain text password
            this.password = "";
        }
    }

    /**
     * ✅ GOOD: Secure password verification
     */
    function verifyPassword(required string password) {
        return hash(arguments.password & this.salt, "SHA-256") == this.passwordHash;
    }
}
```

### 4. Permission Checking
```cfm
component extends="Model" {

    /**
     * ✅ GOOD: Validate permissions before sensitive operations
     */
    function deleteWithPermissionCheck(required numeric currentUserId) {
        if (this.userid != arguments.currentUserId && !hasAdminRole(arguments.currentUserId)) {
            throw(type="PermissionDenied", message="Cannot delete another user's record");
        }

        return this.delete();
    }

    /**
     * ✅ GOOD: Role-based access control
     */
    function canEdit(required user) {
        return this.userid == arguments.user.id || arguments.user.hasRole("admin");
    }
}
```

## Error Handling

### 1. Graceful Error Handling in Models
```cfm
component extends="Model" {

    /**
     * ✅ GOOD: Return structured results for complex operations
     */
    function processPayment(required struct paymentData) {
        try {
            transaction {
                local.result = chargeCard(arguments.paymentData);

                if (local.result.success) {
                    this.paymentStatus = "paid";
                    this.transactionId = local.result.transactionId;
                    this.save();
                    return {success: true, transactionId: local.result.transactionId};
                } else {
                    throw(type="PaymentError", message=local.result.error);
                }
            }
        } catch (any e) {
            // Log error
            writeLog(text="Payment failed for order #this.id#: #e.message#", file="payments");

            // Return structured error
            return {
                success: false,
                error: e.message,
                errorType: e.type
            };
        }
    }

    /**
     * ✅ GOOD: Fail gracefully in callbacks
     */
    private void function sendNotificationEmail() {
        try {
            local.mailer = createObject("component", "mailers.UserMailer");
            local.mailer.welcomeEmail(this);
        } catch (any e) {
            // Log but don't fail the save operation
            writeLog(file="notifications", text=e.message, type="error");
        }
    }
}
```

### 2. Validation Error Management
```cfm
component extends="Model" {

    /**
     * ✅ GOOD: Provide helpful validation methods
     */
    function hasValidationErrors() {
        return this.hasErrors();
    }

    function getValidationErrorsAsString() {
        local.errors = this.allErrors();
        local.messages = [];

        for (local.error in local.errors) {
            arrayAppend(local.messages, local.error.message);
        }

        return arrayToList(local.messages, "; ");
    }

    /**
     * ✅ GOOD: Clear, descriptive error messages
     */
    private void function validateBusinessRules() {
        if (this.startDate >= this.endDate) {
            addError(
                property="endDate",
                message="End date must be after start date"
            );
        }

        if (this.discountPercent > 100) {
            addError(
                property="discountPercent",
                message="Discount cannot exceed 100%"
            );
        }
    }
}
```

## Performance Best Practices

### 1. Efficient Query Patterns
```cfm
component extends="Model" {

    /**
     * ✅ GOOD: Use includes to prevent N+1 queries
     */
    function getPostsWithAuthors() {
        return this.findAll(
            include="author",
            order="createdat DESC"
        );
    }

    /**
     * ✅ GOOD: Limit data with select
     */
    function getPostTitles() {
        return this.findAll(
            select="id, title, createdat",
            order="createdat DESC"
        );
    }

    /**
     * ✅ GOOD: Use exists() for boolean checks
     */
    function hasRecentActivity() {
        return this.posts().exists(
            where="createdat > '#dateAdd("d", -30, now())#'"
        );
    }
}
```

### 2. Smart Caching
```cfm
component extends="Model" {

    function config() {
        afterSave("clearRelatedCaches");
    }

    /**
     * ✅ GOOD: Cache expensive calculations
     */
    function getStatistics() {
        local.cacheKey = "user_#this.id#_stats";

        if (!cacheKeyExists(local.cacheKey)) {
            local.stats = {
                postCount = this.posts().count(),
                totalViews = this.posts().sum("viewCount")
            };
            cachePut(local.cacheKey, local.stats, createTimeSpan(0, 1, 0, 0));
        }

        return cacheGet(local.cacheKey);
    }

    /**
     * ✅ GOOD: Clear related caches when data changes
     */
    private void function clearRelatedCaches() {
        cacheRemove("user_#this.id#_stats");
        cacheRemove("recent_posts");
    }
}
```

## Testing Best Practices

### 1. Comprehensive Model Testing
```cfm
component extends="tests.Test" {

    function setup() {
        // ✅ GOOD: Set up clean test data
        variables.validUserData = {
            name = "Test User",
            email = "test@example.com",
            password = "SecurePassword123!"
        };
    }

    function teardown() {
        // ✅ GOOD: Clean up after tests
        model("User").deleteAll(where="email LIKE '%test%'");
    }

    /**
     * ✅ GOOD: Test validation scenarios
     */
    function testUserValidation() {
        local.user = model("User").new();
        assert(!local.user.valid(), "User should be invalid without required fields");

        local.user = model("User").new(variables.validUserData);
        assert(local.user.valid(), "User should be valid with all required fields");
    }

    /**
     * ✅ GOOD: Test business logic
     */
    function testUserFullNameGeneration() {
        local.user = model("User").new(firstname="John", lastname="Doe");
        assert(local.user.getFullName() == "John Doe", "Should generate correct full name");
    }
}
```

## Naming and Convention Best Practices

### 1. Follow Wheels Conventions
```cfm
// ✅ GOOD: Proper naming conventions

// Model files: Singular, PascalCase
User.cfc
OrderItem.cfc
ProductCategory.cfc

// Table names: Plural, lowercase
users
orderitems
productcategories

// Column names: Lowercase
first_name, email, created_at

// Foreign keys: Singular model name + "id"
userid, categoryid, orderitemid
```

### 2. Descriptive Method Names
```cfm
component extends="Model" {

    // ✅ GOOD: Clear, descriptive method names
    function findActiveUsers() { }
    function findRecentPosts() { }
    function calculateTotalPrice() { }
    function canBeModified() { }
    function hasPermissionToEdit() { }

    // ❌ BAD: Unclear method names
    function getStuff() { }
    function doAction() { }
    function check() { }
}
```

## Documentation Best Practices

### 1. Document Complex Logic
```cfm
component extends="Model" {

    /**
     * Calculate the user's credit score based on multiple factors
     *
     * @returns numeric Credit score between 300-850
     */
    function calculateCreditScore() {
        // Payment history (35% of score)
        local.paymentScore = this.getPaymentHistoryScore() * 0.35;

        // Credit utilization (30% of score)
        local.utilizationScore = this.getCreditUtilizationScore() * 0.30;

        // Length of credit history (15% of score)
        local.historyScore = this.getCreditHistoryScore() * 0.15;

        // Types of credit (10% of score)
        local.creditTypesScore = this.getCreditTypesScore() * 0.10;

        // New credit inquiries (10% of score)
        local.inquiriesScore = this.getInquiriesScore() * 0.10;

        return local.paymentScore + local.utilizationScore + local.historyScore +
               local.creditTypesScore + local.inquiriesScore;
    }
}
```

### 2. Document Model Relationships
```cfm
/**
 * User Model - Represents application users
 *
 * Relationships:
 * - hasMany: posts, comments, orders
 * - hasOne: profile
 * - hasMany: roles (through userRoles)
 *
 * Key Features:
 * - Authentication and password hashing
 * - Role-based permissions
 * - Email verification workflow
 * - Account locking after failed login attempts
 */
component extends="Model" {
    // Model implementation
}
```

## Common Anti-Patterns to Avoid

### 1. Mixed Argument Styles
```cfm
// ❌ BAD: Mixing positional and named arguments
hasMany("comments", dependent="delete");

// ✅ GOOD: Consistent argument style
hasMany(name="comments", dependent="delete");
// OR
hasMany("comments");
```

### 2. Business Logic in Controllers
```cfm
// ❌ BAD: Business logic in controller
function create() {
    user = model("User").new(params.user);

    // This calculation belongs in the model
    if (user.age >= 18) {
        user.canVote = true;
    }

    user.save();
}

// ✅ GOOD: Business logic in model
component extends="Model" {
    private void function setVotingEligibility() {
        this.canVote = (this.age >= 18);
    }
}
```

### 3. Fat Models
```cfm
// ❌ BAD: Model with too many responsibilities
component extends="Model" {
    // 500+ lines of code handling:
    // - User management
    // - Email sending
    // - Report generation
    // - Payment processing
    // - File uploads
}

// ✅ GOOD: Focused model with service delegation
component extends="Model" {
    function sendWelcomeEmail() {
        emailService.sendWelcomeEmail(this);
    }

    function processPayment(paymentData) {
        return paymentService.processPayment(this, paymentData);
    }
}
```

## Development Workflow Best Practices

### 1. Model Development Process
1. **Design the database schema** with proper indexes and constraints
2. **Generate the model** using Wheels CLI
3. **Add associations** based on your schema relationships
4. **Implement validations** for data integrity
5. **Add business logic methods** for domain operations
6. **Write comprehensive tests** for all functionality
7. **Optimize performance** with caching and query optimization

### 2. Code Review Checklist
- [ ] Follows Wheels naming conventions
- [ ] Uses consistent argument styles
- [ ] Includes appropriate validations
- [ ] Has proper error handling
- [ ] Includes security considerations
- [ ] Has adequate test coverage
- [ ] Documents complex business logic
- [ ] Follows performance best practices

### 3. Refactoring Guidelines
- Extract complex business logic into separate methods
- Move very complex operations to service objects
- Cache expensive calculations
- Optimize queries with includes and selects
- Remove duplicate validation logic
- Consolidate similar finder methods

## Related Documentation
- [Model Architecture](./architecture.md)
- [Model Validations](./validations.md)
- [Model Associations](./associations.md)
- [Model Performance](./performance.md)
- [Security Best Practices](../../security/authentication.md)