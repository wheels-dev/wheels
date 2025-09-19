# Model Callbacks

## Description
CFWheels model callbacks allow you to execute code at specific points in a model's lifecycle, enabling automatic data processing, validation, logging, and business logic execution.

## Available Callback Points

### Before Callbacks
Callbacks that execute before an operation:

```cfm
component extends="Model" {
    function config() {
        // Before validation runs
        beforeValidation("normalizeData");

        // Before save (create or update)
        beforeSave("updateTimestamps");

        // Before create only
        beforeCreate("generateId");

        // Before update only
        beforeUpdate("trackChanges");

        // Before delete
        beforeDelete("checkReferences");
    }
}
```

### After Callbacks
Callbacks that execute after an operation:

```cfm
component extends="Model" {
    function config() {
        // After validation passes
        afterValidation("processData");

        // After save (create or update)
        afterSave("clearCache");

        // After create only
        afterCreate("sendNotifications");

        // After update only
        afterUpdate("logChanges");

        // After delete
        afterDelete("cleanupFiles");
    }
}
```

## Callback Implementation Examples

### Data Normalization and Cleanup
```cfm
component extends="Model" {
    function config() {
        beforeValidation("normalizeData");
        beforeSave("cleanupData");
    }

    /**
     * Normalize data before validation
     */
    private void function normalizeData() {
        // Normalize email to lowercase
        if (len(this.email)) {
            this.email = lCase(trim(this.email));
        }

        // Clean phone number (remove non-digits)
        if (len(this.phone)) {
            this.phone = reReplace(this.phone, "[^\d]", "", "all");
        }

        // Normalize text fields
        if (len(this.name)) {
            this.name = trim(this.name);
            // Capitalize first letter of each word
            this.name = uCase(left(this.name, 1)) & right(this.name, len(this.name) - 1);
        }
    }

    /**
     * Additional cleanup before saving
     */
    private void function cleanupData() {
        // Remove extra whitespace from text fields
        if (len(this.description)) {
            this.description = reReplace(this.description, "\s+", " ", "all");
            this.description = trim(this.description);
        }

        // Ensure URLs have protocol
        if (len(this.website) && !reFindNoCase("^https?://", this.website)) {
            this.website = "http://" & this.website;
        }
    }
}
```

### Automatic Timestamp Management
```cfm
component extends="Model" {
    function config() {
        beforeCreate("setCreatedTimestamp");
        beforeSave("setUpdatedTimestamp");
    }

    /**
     * Set creation timestamp
     */
    private void function setCreatedTimestamp() {
        if (!len(this.createdat)) {
            this.createdat = now();
        }
    }

    /**
     * Always update the modified timestamp
     */
    private void function setUpdatedTimestamp() {
        this.updatedat = now();
    }
}
```

### ID Generation and Slug Creation
```cfm
component extends="Model" {
    function config() {
        beforeCreate("generateUUID", "createSlug");
        beforeSave("updateSlug");
    }

    /**
     * Generate UUID for primary key
     */
    private void function generateUUID() {
        if (!len(this.id)) {
            this.id = createUUID();
        }
    }

    /**
     * Create URL slug from title
     */
    private void function createSlug() {
        if (!len(this.slug) && len(this.title)) {
            this.slug = createUrlSlug(this.title);
        }
    }

    /**
     * Update slug if title changes
     */
    private void function updateSlug() {
        if (hasChanged("title")) {
            this.slug = createUrlSlug(this.title);
        }
    }

    /**
     * Helper: Create URL-friendly slug
     */
    private string function createUrlSlug(required string text) {
        local.slug = lCase(trim(arguments.text));
        local.slug = reReplace(local.slug, "[^\w\s-]", "", "all");
        local.slug = reReplace(local.slug, "[\s-]+", "-", "all");
        local.slug = reReplace(local.slug, "^-+|-+$", "", "all");

        // Ensure uniqueness
        local.counter = 1;
        local.originalSlug = local.slug;
        while (model(this.getModelName()).exists(where="slug = '#local.slug#' AND id != '#this.id ?: 0#'")) {
            local.slug = local.originalSlug & "-" & local.counter;
            local.counter++;
        }

        return local.slug;
    }
}
```

### Change Tracking and Auditing
```cfm
component extends="Model" {
    function config() {
        beforeUpdate("trackChanges");
        afterUpdate("logChanges");
        afterSave("clearCache");
    }

    /**
     * Store changed properties before update
     */
    private void function trackChanges() {
        // Store changed data for later use
        variables.changedData = changedProperties();
        variables.originalValues = {};

        for (local.field in variables.changedData) {
            variables.originalValues[local.field] = changedFrom(local.field);
        }
    }

    /**
     * Log changes to audit table after update
     */
    private void function logChanges() {
        if (structKeyExists(variables, "changedData") && structCount(variables.changedData)) {
            for (local.field in variables.changedData) {
                model("AuditLog").create(
                    tableName = this.getTableName(),
                    recordId = this.id,
                    fieldName = local.field,
                    oldValue = variables.originalValues[local.field] ?: "",
                    newValue = this[local.field] ?: "",
                    changedAt = now(),
                    changedBy = session.userid ?: 0
                );
            }
        }
    }

    /**
     * Clear related cache entries
     */
    private void function clearCache() {
        // Clear object-specific cache
        cacheRemove("model_#this.getModelName()#_#this.id#");

        // Clear listing caches
        cacheRemove("recent_#this.getTableName()#");
        cacheRemove("featured_#this.getTableName()#");
    }
}
```

### Security and Password Handling
```cfm
component extends="Model" {
    function config() {
        beforeCreate("generateSalt");
        beforeSave("hashPasswordIfChanged");
        afterCreate("sendWelcomeEmail");
    }

    /**
     * Generate cryptographic salt for new users
     */
    private void function generateSalt() {
        this.salt = hash(createUUID() & now() & randRange(1, 100000), "MD5");
    }

    /**
     * Hash password if it has changed
     */
    private void function hashPasswordIfChanged() {
        if (hasChanged("password") && len(this.password)) {
            // Hash with salt
            this.passwordHash = hash(this.password & this.salt, "SHA-256");

            // Clear plain text password
            this.password = "";
            this.passwordConfirmation = "";
        }
    }

    /**
     * Send welcome email to new users
     */
    private void function sendWelcomeEmail() {
        try {
            local.mailer = createObject("component", "mailers.UserMailer");
            local.mailer.welcomeEmail(user=this);
        } catch (any e) {
            // Log error but don't fail the save
            writeLog(
                file="application",
                text="Failed to send welcome email to user #this.id#: #e.message#",
                type="error"
            );
        }
    }
}
```

### Business Logic and Notifications
```cfm
component extends="Model" {
    function config() {
        afterCreate("notifySubscribers", "updateCounters");
        afterUpdate("checkStatusChange");
        beforeDelete("preventIfHasOrders");
    }

    /**
     * Notify subscribers when new content is created
     */
    private void function notifySubscribers() {
        if (this.status == "published") {
            // Queue background job for notifications
            local.job = createObject("component", "jobs.NotifySubscribersJob");
            local.job.enqueue({
                modelName = this.getModelName(),
                recordId = this.id,
                action = "created"
            });
        }
    }

    /**
     * Update related counters
     */
    private void function updateCounters() {
        // Update category post count
        if (isObject(this.category())) {
            this.category().updatePostCount();
        }

        // Update author post count
        if (isObject(this.author())) {
            this.author().updatePostCount();
        }
    }

    /**
     * Check if status changed to published
     */
    private void function checkStatusChange() {
        if (hasChanged("status") && this.status == "published") {
            // Set published date
            this.publishedAt = now();

            // Send publication notifications
            local.job = createObject("component", "jobs.PublishNotificationJob");
            local.job.enqueue({postId: this.id});
        }
    }

    /**
     * Prevent deletion if has related orders
     */
    private void function preventIfHasOrders() {
        if (model("Order").exists(where="customerId = '#this.id#'")) {
            throw(
                type="ReferentialIntegrityError",
                message="Cannot delete customer with existing orders"
            );
        }
    }
}
```

### File Management and Cleanup
```cfm
component extends="Model" {
    function config() {
        afterCreate("createDirectories");
        afterUpdate("moveFiles");
        afterDelete("cleanupFiles");
    }

    /**
     * Create user directories after account creation
     */
    private void function createDirectories() {
        local.userDir = expandPath("/uploads/users/#this.id#");
        if (!directoryExists(local.userDir)) {
            directoryCreate(local.userDir);
            directoryCreate("#local.userDir#/avatars");
            directoryCreate("#local.userDir#/documents");
        }
    }

    /**
     * Move files if username changed
     */
    private void function moveFiles() {
        if (hasChanged("username")) {
            local.oldPath = expandPath("/uploads/users/#changedFrom('username')#");
            local.newPath = expandPath("/uploads/users/#this.username#");

            if (directoryExists(local.oldPath) && !directoryExists(local.newPath)) {
                directoryMove(local.oldPath, local.newPath);
            }
        }
    }

    /**
     * Clean up associated files when deleting
     */
    private void function cleanupFiles() {
        // Delete user avatar
        if (len(this.avatarPath) && fileExists(expandPath(this.avatarPath))) {
            fileDelete(expandPath(this.avatarPath));
        }

        // Delete user directory
        local.userDir = expandPath("/uploads/users/#this.id#");
        if (directoryExists(local.userDir)) {
            directoryDelete(local.userDir, true);
        }
    }
}
```

## Advanced Callback Patterns

### Conditional Callbacks
```cfm
component extends="Model" {
    function config() {
        beforeSave("validateInventory");
        afterSave("updateSearchIndex");
    }

    /**
     * Only validate inventory for certain product types
     */
    private void function validateInventory() {
        if (this.trackInventory && this.quantity < 0) {
            throw(
                type="InventoryError",
                message="Cannot save product with negative inventory"
            );
        }
    }

    /**
     * Only update search index for published content
     */
    private void function updateSearchIndex() {
        if (this.status == "published") {
            local.searchService = createObject("component", "services.SearchService");
            local.searchService.indexDocument(this);
        }
    }
}
```

### Callback Chains
```cfm
component extends="Model" {
    function config() {
        // Multiple callbacks in order
        beforeSave("validateData", "processImages", "generateSEOFields");
        afterSave("clearCache", "updateRelated", "sendNotifications");
    }

    private void function validateData() {
        // First validation step
    }

    private void function processImages() {
        // Image processing step
    }

    private void function generateSEOFields() {
        // SEO field generation step
    }
}
```

### Error Handling in Callbacks
```cfm
component extends="Model" {
    function config() {
        afterCreate("processAsyncTasks");
    }

    /**
     * Handle errors gracefully in callbacks
     */
    private void function processAsyncTasks() {
        try {
            // Queue background processing
            local.processor = createObject("component", "services.BackgroundProcessor");
            local.processor.queueTask(this);

        } catch (any e) {
            // Log error but don't fail the save operation
            writeLog(
                file="callbacks",
                text="Failed to queue background task for #this.getModelName()# #this.id#: #e.message#",
                type="error"
            );

            // Optionally store error for later retry
            this.updateColumn("lastProcessingError", e.message);
        }
    }
}
```

## Testing Callbacks

### Callback Testing Examples
```cfm
component extends="tests.Test" {

    function testBeforeCreateCallback() {
        user = model("User").new(name="John", email="john@example.com");

        // Ensure UUID is not set before save
        assert(!len(user.id), "ID should not be set before save");

        user.save();

        // Ensure UUID was generated by callback
        assert(len(user.id) > 0, "ID should be set after save");
        assert(isValid("uuid", user.id), "ID should be valid UUID");
    }

    function testSlugGeneration() {
        post = model("Post").create(title="This is a Test Post");

        assert(post.slug == "this-is-a-test-post", "Slug should be generated from title");
    }

    function testPasswordHashing() {
        user = model("User").new(name="John", email="john@example.com", password="plaintext");

        user.save();

        // Password should be cleared and hash should be set
        assert(user.password == "", "Plain text password should be cleared");
        assert(len(user.passwordHash) > 0, "Password hash should be set");
        assert(user.passwordHash != "plaintext", "Hash should be different from original");
    }

    function testChangeTracking() {
        user = model("User").create(name="John", email="john@example.com");
        originalName = user.name;

        // Update name
        user.update(name="Jane");

        // Check audit log was created
        auditLogs = model("AuditLog").findAll(
            where="tableName = 'users' AND recordId = '#user.id#' AND fieldName = 'name'"
        );

        assert(auditLogs.recordCount > 0, "Audit log should be created");
        assert(auditLogs.oldValue == originalName, "Old value should be recorded");
        assert(auditLogs.newValue == "Jane", "New value should be recorded");
    }

    function testCacheClearing() {
        // Set up cache
        cachePut("recent_posts", "test data");

        post = model("Post").create(title="Test Post", content="Test content");

        // Cache should be cleared by callback
        assert(!cacheKeyExists("recent_posts"), "Cache should be cleared after save");
    }

    function testErrorHandlingInCallback() {
        // Mock a service that will fail
        application.mockService = createObject("component", "tests.mocks.FailingService");

        // Save should still succeed even if callback fails
        post = model("Post").create(title="Test Post", content="Test content");

        assert(isObject(post), "Post should be created despite callback error");
        assert(post.id > 0, "Post should have valid ID");
    }
}
```

## Callback Best Practices

### 1. Keep Callbacks Simple and Fast
```cfm
// ✅ GOOD: Simple, quick operations
private void function normalizeEmail() {
    if (len(this.email)) {
        this.email = lCase(trim(this.email));
    }
}

// ❌ BAD: Expensive operations that block
private void function processLargeFile() {
    // Don't do heavy processing in callbacks
    imageResize(this.imagePath, 1000, 1000); // Could take seconds
}
```

### 2. Handle Errors Gracefully
```cfm
// ✅ GOOD: Error handling that doesn't break saves
private void function sendNotification() {
    try {
        emailService.sendNotification(this);
    } catch (any e) {
        writeLog(file="notifications", text=e.message, type="error");
        // Don't re-throw - let save continue
    }
}
```

### 3. Use Callbacks for Data Integrity
```cfm
// ✅ GOOD: Ensuring data consistency
private void function updateCounters() {
    if (this.categoryid) {
        this.category().incrementPostCount();
    }
}
```

### 4. Avoid Complex Business Logic
```cfm
// ✅ GOOD: Move complex logic to services
private void function processOrder() {
    orderService = createObject("component", "services.OrderService");
    orderService.processOrder(this);
}

// ❌ BAD: Complex logic directly in callback
private void function processOrder() {
    // 50 lines of complex business logic...
}
```

### 5. Test Callback Behavior
```cfm
// Always test that callbacks work as expected
function testCallbackChain() {
    // Test that all callbacks in chain execute
    // Test callback order
    // Test error scenarios
}
```

## Common Callback Use Cases

1. **Data Normalization**: Clean and format data before validation
2. **Slug Generation**: Create URL-friendly slugs from titles
3. **Password Hashing**: Secure password storage
4. **Timestamp Management**: Track creation and modification times
5. **Cache Management**: Clear relevant caches when data changes
6. **Audit Logging**: Track changes for compliance and debugging
7. **File Management**: Handle file uploads and cleanup
8. **Notifications**: Send emails or trigger events
9. **Search Indexing**: Update search indexes when content changes
10. **Counter Updates**: Maintain denormalized counters

## Related Documentation
- [Model Architecture](./architecture.md)
- [Model Validations](./validations.md)
- [User Authentication](./user-authentication.md)
- [Performance Optimization](../patterns/performance.md)