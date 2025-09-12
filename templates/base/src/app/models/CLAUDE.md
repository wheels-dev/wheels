# CLAUDE.md - Models (Object-Relational Mapping)

This file provides guidance to Claude Code (claude.ai/code) when working with Wheels model components.

## Overview

The `/app/models/` folder contains model classes that represent your application's data layer and implement the Active Record pattern. Models in Wheels extend `Model.cfc` and provide object-relational mapping (ORM) between database tables and CFML objects.

**⚠️ IMPORTANT:** Wheels models do NOT have a `scope()` function. The `scope()` function exists only in the routing system (`/config/routes.cfm`) for grouping routes. Do not confuse this with Ruby on Rails ActiveRecord scopes. In Wheels models, use custom finder methods instead.

**Why Use Models:**
- Implement the Active Record pattern for database interactions
- Define business logic and data validation rules
- Establish relationships between different data entities
- Provide a clean interface for database operations
- Enable automatic query generation and caching
- Support advanced features like callbacks, soft deletes, and dirty tracking

**Key Concept:** Models represent both the structure (database schema) and behavior (business logic) of your data.

## Model Architecture

### Base Model Structure
All models extend `wheels.Model`, which provides:
- Database interaction methods (CRUD operations)
- Validation framework
- Association management
- Callback system
- Query building and caching
- Transaction support

### Core Model Methods

#### Class Methods (called on model class)
- **`findAll()`** - Find multiple records with conditions
- **`findByKey(key)`** - Find single record by primary key
- **`findOne()`** - Find single record with conditions
- **`create(properties)`** - Create and save new record
- **`new(properties)`** - Create new unsaved record
- **`updateAll()`** - Update multiple records
- **`deleteAll()`** - Delete multiple records
- **`count()`** - Count records matching conditions
- **`exists()`** - Check if records exist

#### Instance Methods (called on model object)
- **`save()`** - Save changes to database
- **`update(properties)`** - Update and save record
- **`delete()`** - Delete record from database
- **`valid()`** - Check if record passes validation
- **`hasErrors()`** - Check if record has validation errors
- **`reload()`** - Reload record from database

#### Configuration Methods (used in config())
- **`property()`** - Define custom properties and mappings
- **`table()`** - Specify database table name
- **`dataSource()`** - Specify custom data source for this model
- **`belongsTo(name="model name", foreignKey="")`** - Define parent relationship
- **`hasMany()`** - Define child collection relationship
- **`hasOne()`** - Define one-to-one relationship
- **`validate*()`** - Define validation rules
- **`validate(method="")`** - Define custom validation methods
- **`nestedProperties()`** - Enable saving of associated models in single operation
- **`timeStampOnCreateProperty`** - Enable automatic createdAt timestamp using `set` function
- **`timeStampOnUpdateProperty`** - Enable automatic updatedAt timestamp using `set` function
- **`protectedProperties()`** - Protect properties from mass assignment
- **`accessibleProperties()`** - Allow specific properties for mass assignment

#### Query and Statistical Methods
- **`sum(property)`** - Calculate sum of property values
- **`average(property)`** - Calculate average of property values  
- **`minimum(property)`** - Find minimum property value
- **`maximum(property)`** - Find maximum property value
- **`findBySQL(sql)`** - Execute raw SQL queries
- **`invokeWithTransaction()`** - Execute method within transaction

#### Change Tracking Methods
- **`hasChanged(property="")`** - Check if object/property has changed
- **`changedFrom(property)`** - Get previous value of property
- **`changedProperties()`** - Get list of changed property names
- **`allChanges()`** - Get struct of all changes (names and values)
- **`isNew()`** - Check if object is new (not yet saved to database)

#### Dynamic Finder Methods
- **`findOneBy[Property](value)`** - Dynamic finder for single property
- **`findAllBy[Property](value)`** - Dynamic finder for single property
- **`findOneBy[Property]And[Property](values)`** - Dynamic finder for multiple properties
- **`[property]HasChanged()`** - Dynamic change check for specific property
- **`[property]ChangedFrom()`** - Dynamic previous value check for specific property

## Model Generation

### CLI Generator
Use the Wheels CLI to generate model classes and optionally create database migrations:

```bash
# Basic model
wheels g model User

# Model with properties
wheels g model User name:string,email:string,age:integer

# Model with associations
wheels g model Post belongsTo=User hasMany=Comments

# Model with custom table name
wheels g model Product tableName=tbl_products

# Model without migration
wheels g model Category migration=false
```

### Generator Options
- **`name`** - Model name (singular form, becomes class name)
- **`properties`** - Column definitions (name:type,name2:type2)
- **`belongsTo`** - Parent model relationships (comma-separated)
- **`hasMany`** - Child model relationships (comma-separated)
- **`hasOne`** - One-to-one relationships (comma-separated)
- **`primaryKey`** - Primary key column name (default: id)
- **`tableName`** - Custom database table name
- **`migration`** - Generate database migration (default: true)
- **`force`** - Overwrite existing files

## Basic Model Structure

### Simple Model Template
```cfm
/**
 * User Model - Represents application users
 * Table: users
 * Primary Key: id
 */
component extends="Model" {

    /**
     * Model configuration - associations, validations, properties
     */
    function config() {
        // Table configuration (if different from convention)
        // table("custom_users_table");
        
        // Associations
        hasMany("posts");
        hasMany("comments");
        hasOne("profile");
        
        // Validations
        validatesPresenceOf("name,email");
        validatesUniquenessOf("email");
        validatesLengthOf(property="name", minimum=2, maximum=100);
        validatesFormatOf(property="email", with="^[^@]+@[^@]+\.[^@]+$");
        
        // Custom properties
        property(name="fullName", sql=false); // Virtual property
        
        // Callbacks
        beforeSave("encryptPassword");
        afterCreate("sendWelcomeEmail");
        
        // Soft delete enabled automatically if deletedat column exists
    }
    
    // Custom business logic methods go here
    
    /**
     * Get user's full display name
     */
    function getFullName() {
        return trim(this.firstname & " " & this.lastname);
    }
    
    /**
     * Check if user has specific role
     */
    function hasRole(required string roleName) {
        return listFindNoCase(this.roles, arguments.roleName) > 0;
    }
    
    /**
     * Callback: Encrypt password before saving
     */
    private void function encryptPassword() {
        if (hasChanged("password") && len(this.password)) {
            this.password = hash(this.password, "SHA-256");
        }
    }
    
    /**
     * Callback: Send welcome email after user creation
     */
    private void function sendWelcomeEmail() {
        // Queue welcome email job
        local.mailer = createObject("component", "mailers.UserMailer");
        local.mailer.welcomeEmail(to=this.email, user=this);
    }
}
```

## Advanced Model Patterns

### 1. E-commerce Product Model
```cfm
/**
 * Product Model - E-commerce product catalog
 */
component extends="Model" {

    function config() {
        // Associations
        belongsTo("category");
        hasMany("orderItems");
        hasMany("productImages");
        hasMany("reviews");
        hasOne("inventory");
        
        // Validations
        validatesPresenceOf("name,price,categoryid");
        validatesNumericalityOf("price", greaterThan=0);
        validatesNumericalityOf("weight", greaterThan=0, allowBlank=true);
        validatesLengthOf(property="name", minimum=3, maximum=255);
        validatesLengthOf(property="sku", maximum=50, allowBlank=true);
        validatesUniquenessOf("sku", allowBlank=true);
        
        // Custom properties
        property(name="isactive", type="boolean", defaultValue=true);
        property(name="discountedPrice", sql=false); // Calculated property
        property(name="inStock", sql=false);
        
        // Callbacks
        beforeSave("generateSku", "updateSlug");
        afterUpdate("clearProductCache");
        
        // Soft delete enabled automatically if deletedat column exists
    }
    
    /**
     * Get discounted price if on sale
     */
    function getDiscountedPrice() {
        if (this.salePrice > 0 && this.salePrice < this.price) {
            return this.salePrice;
        }
        return this.price;
    }
    
    /**
     * Check if product is in stock
     */
    function getInStock() {
        return this.inventory().quantity > 0;
    }
    
    /**
     * Get primary product image
     */
    function getPrimaryImage() {
        return this.productImages(where="isPrimary = 1").first();
    }
    
    /**
     * Calculate average rating from reviews
     */
    function getAverageRating() {
        return this.reviews().average("rating");
    }
    
    /**
     * Find active products only
     */
    function findActive() {
        return findAll(where="isactive = 1 AND deletedat IS NULL");
    }
    
    /**
     * Find products in specific category
     */
    function findInCategory(required numeric categoryid) {
        return findAll(where="categoryid = ?", whereParams=[arguments.categoryid]);
    }
    
    /**
     * Find products on sale
     */
    function findOnSale() {
        return findAll(where="salePrice > 0 AND salePrice < price");
    }
    
    /**
     * Search products by name and description
     */
    function searchByText(required string searchTerm) {
        local.term = "%" & arguments.searchTerm & "%";
        return this.where("name LIKE ? OR description LIKE ?", [local.term, local.term]);
    }
    
    /**
     * Callback: Generate SKU if not provided
     */
    private void function generateSku() {
        if (!len(this.sku)) {
            // Generate SKU from category and name
            local.categoryCode = this.category().code ?: "GEN";
            local.namePart = reReplace(this.name, "[^A-Za-z0-9]", "", "all");
            local.namePart = left(uCase(local.namePart), 8);
            this.sku = local.categoryCode & "-" & local.namePart & "-" & randRange(1000, 9999);
        }
    }
    
    /**
     * Callback: Update URL slug from name
     */
    private void function updateSlug() {
        if (hasChanged("name")) {
            this.slug = createSlug(this.name);
        }
    }
    
    /**
     * Callback: Clear cached product data
     */
    private void function clearProductCache() {
        // Clear relevant cache entries
        cacheRemove("product_#this.id#_details");
        cacheRemove("category_#this.categoryid#_products");
    }
    
    /**
     * Helper: Create URL-friendly slug
     */
    private string function createSlug(required string text) {
        local.slug = lCase(trim(arguments.text));
        local.slug = reReplace(local.slug, "[^a-z0-9\s]", "", "all");
        local.slug = reReplace(local.slug, "\s+", "-", "all");
        local.slug = reReplace(local.slug, "-+", "-", "all");
        local.slug = reReplace(local.slug, "^-|-$", "", "all");
        
        // Ensure uniqueness
        local.counter = 1;
        local.originalSlug = local.slug;
        while (model("Product").exists(where="slug = ? AND id != ?", whereParams=[local.slug, this.id ?: 0])) {
            local.slug = local.originalSlug & "-" & local.counter;
            local.counter++;
        }
        
        return local.slug;
    }
}
```

### 2. Blog Post Model with Rich Features
```cfm
/**
 * Post Model - Blog posts with rich content management
 */
component extends="Model" {

    function config() {
        // Associations
        belongsTo("author", modelName="User", foreignKey="authorid");
        belongsTo("category");
        hasMany("comments");
        hasMany("tags", through="postTags");
        hasMany("postTags");
        
        // Validations
        validatesPresenceOf("title,content,authorid");
        validatesLengthOf(property="title", minimum=5, maximum=255);
        validatesLengthOf(property="excerpt", maximum=500, allowBlank=true);
        validatesLengthOf(property="content", minimum=50);
        validatesUniquenessOf("slug");
        
        // Custom properties
        property(name="status", type="string", defaultValue="draft");
        property(name="publishedAt", type="timestamp", null=true);
        property(name="wordCount", sql=false);
        property(name="readingTime", sql=false);
        property(name="isPublished", sql=false);
        
        // Callbacks
        beforeValidation("generateSlugFromTitle");
        beforeSave("calculateWordCount", "setPublishedDate");
        afterCreate("notifySubscribers");
        afterUpdate("clearPostCache");
        
        // Automatic timestamps
        set(timeStampOnCreateProperty="createdAt");
        set(timeStampOnUpdateProperty="updatedAt");
    }
    
    /**
     * Get calculated word count
     */
    function getWordCount() {
        local.plainText = reReplace(this.content, "<[^>]*>", "", "all");
        local.words = listToArray(local.plainText, " " & chr(10) & chr(13) & chr(9));
        return arrayLen(local.words);
    }
    
    /**
     * Calculate estimated reading time
     */
    function getReadingTime() {
        local.wordsPerMinute = 200; // Average reading speed
        local.minutes = ceiling(getWordCount() / local.wordsPerMinute);
        return max(1, local.minutes); // Minimum 1 minute
    }
    
    /**
     * Check if post is published
     */
    function getIsPublished() {
        return this.status == "published" && 
               isDate(this.publishedAt) && 
               this.publishedAt <= now();
    }
    
    /**
     * Get formatted excerpt or auto-generate from content
     */
    function getFormattedExcerpt(numeric length = 200) {
        if (len(this.excerpt)) {
            return this.excerpt;
        }
        
        // Auto-generate from content
        local.plainText = reReplace(this.content, "<[^>]*>", "", "all");
        local.plainText = reReplace(local.plainText, "\s+", " ", "all");
        
        if (len(local.plainText) <= arguments.length) {
            return local.plainText;
        }
        
        local.truncated = left(local.plainText, arguments.length - 3);
        local.lastSpace = find(" ", reverse(local.truncated));
        if (local.lastSpace > 0 && local.lastSpace < 20) {
            local.truncated = left(local.truncated, len(local.truncated) - local.lastSpace + 1);
        }
        
        return trim(local.truncated) & "...";
    }
    
    /**
     * Get next published post
     */
    function getNextPost() {
        return model("Post")
            .where("status = ? AND publishedAt > ?", ["published", this.publishedAt])
            .order("publishedAt ASC")
            .first();
    }
    
    /**
     * Get previous published post
     */
    function getPreviousPost() {
        return model("Post")
            .where("status = ? AND publishedAt < ?", ["published", this.publishedAt])
            .order("publishedAt DESC")
            .first();
    }
    
    /**
     * Get related posts by tags
     */
    function getRelatedPosts(numeric limit = 5) {
        if (!this.tags().count()) {
            return [];
        }
        
        local.tagIds = [];
        for (local.tag in this.tags()) {
            arrayAppend(local.tagIds, local.tag.id);
        }
        
        return model("Post")
            .joins("INNER JOIN postTags pt ON posts.id = pt.postId")
            .where("pt.tagId IN (?) AND posts.id != ? AND posts.status = ?", 
                   [arrayToList(local.tagIds), this.id, "published"])
            .group("posts.id")
            .order("COUNT(pt.tagId) DESC, posts.publishedAt DESC")
            .limit(arguments.limit);
    }
    
    /**
     * Publish the post
     */
    function publish() {
        if (this.status != "published") {
            this.status = "published";
            this.publishedAt = now();
            return this.save();
        }
        return true;
    }
    
    /**
     * Unpublish the post (set to draft)
     */
    function unpublish() {
        this.status = "draft";
        this.publishedAt = "";
        return this.save();
    }
    
    /**
     * Find published posts only
     */
    function findPublished() {
        return findAll(where="status = 'published' AND publishedAt <= '#Now()#'");
    }
    
    /**
     * Find draft posts only
     */
    function findDrafts() {
        return findAll(where="status = 'draft'");
    }
    
    /**
     * Find posts by specific author
     */
    function findByAuthor(required numeric authorid) {
        return findAll(where="authorid = ?", whereParams=[arguments.authorid]);
    }
    
    /**
     * Find posts in date range
     */
    function findInDateRange(required date startDate, required date endDate) {
        return findAll(where="publishedAt BETWEEN ? AND ?", whereParams=[arguments.startDate, arguments.endDate]);
    }
    
    // Callback methods
    
    /**
     * Callback: Generate slug from title if not provided
     */
    private void function generateSlugFromTitle() {
        if (!len(this.slug) && len(this.title)) {
            this.slug = createUrlSlug(this.title);
        }
    }
    
    /**
     * Callback: Calculate and store word count
     */
    private void function calculateWordCount() {
        // Store actual word count for database queries/sorting
        this.actualWordCount = getWordCount();
    }
    
    /**
     * Callback: Set published date when status changes to published
     */
    private void function setPublishedDate() {
        if (hasChanged("status") && this.status == "published" && !isDate(this.publishedAt)) {
            this.publishedAt = now();
        }
    }
    
    /**
     * Callback: Notify subscribers when post is published
     */
    private void function notifySubscribers() {
        if (this.status == "published") {
            // Queue job to send notifications
            local.job = createObject("component", "jobs.NotifySubscribersJob");
            local.job.enqueue({postId: this.id});
        }
    }
    
    /**
     * Callback: Clear cached post data
     */
    private void function clearPostCache() {
        cacheRemove("post_#this.id#_details");
        cacheRemove("recent_posts");
        cacheRemove("category_#this.categoryid#_posts");
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
        while (model("Post").exists(where="slug = ? AND id != ?", whereParams=[local.slug, this.id ?: 0])) {
            local.slug = local.originalSlug & "-" & local.counter;
            local.counter++;
        }
        
        return local.slug;
    }
}
```

### 3. User Authentication Model
```cfm
/**
 * User Model - User authentication and profile management
 */
component extends="Model" {

    function config() {
        // Associations
        hasOne("profile");
        hasMany("posts", foreignKey="authorid");
        hasMany("comments");
        hasMany("sessions");
        hasMany("loginAttempts");
        hasMany("userRoles");
        hasMany("roles", through="userRoles");
        
        // Validations
        validatesPresenceOf("email,username");
        validatesUniquenessOf("email,username");
        validatesLengthOf(property="username", minimum=3, maximum=50);
        validatesLengthOf(property="password", minimum=8, when="onCreate");
        validatesFormatOf(property="email", with="^[^\s@]+@[^\s@]+\.[^\s@]+$");
        validatesConfirmationOf(property="password", when="onCreate");
        
        // Custom validations
        validate(method="validatePasswordStrength", when="onCreate");
        validate(method="validateUsernameFormat");
        
        // Custom properties
        property(name="isactive", type="boolean", defaultValue=true);
        property(name="lastloginat", type="timestamp", null=true);
        property(name="logincount", type="integer", defaultValue=0);
        property(name="failedloginattempts", type="integer", defaultValue=0);
        property(name="lockeduntil", type="timestamp", null=true);
        property(name="emailverifiedat", type="timestamp", null=true);
        property(name="twofactorenabled", type="boolean", defaultValue=false);
        
        // Virtual properties
        property(name="fullName", sql=false);
        property(name="isLocked", sql=false);
        property(name="isEmailVerified", sql=false);
        
        // Callbacks
        beforeCreate("generateVerificationToken");
        beforeSave("hashPasswordIfChanged");
        afterCreate("sendVerificationEmail");
        afterUpdate("logProfileChanges");
        
        // Soft delete enabled automatically if deletedat column exists
        
        // Automatic timestamps
        set(timeStampOnCreateProperty="createdAt");
        set(timeStampOnUpdateProperty="updatedAt");
    }
    
    /**
     * Authenticate user with email/username and password
     */
    static function authenticate(required string identifier, required string password) {
        // Find user by email or username
        local.user = model("User").findOne(
            where="(email = ? OR username = ?) AND deletedat IS NULL",
            whereParams=[arguments.identifier, arguments.identifier]
        );
        
        if (!isObject(local.user)) {
            return {success: false, error: "Invalid credentials"};
        }
        
        // Check if account is locked
        if (local.user.getIsLocked()) {
            return {success: false, error: "Account is temporarily locked"};
        }
        
        // Verify password
        if (local.user.verifyPassword(arguments.password)) {
            // Update login statistics
            local.user.recordSuccessfulLogin();
            return {success: true, user: local.user};
        } else {
            // Record failed attempt
            local.user.recordFailedLogin();
            return {success: false, error: "Invalid credentials"};
        }
    }
    
    /**
     * Verify password against stored hash
     */
    function verifyPassword(required string password) {
        return hash(arguments.password & this.salt, "SHA-256") == this.passwordHash;
    }
    
    /**
     * Get user's full display name
     */
    function getFullName() {
        if (len(this.firstname) && len(this.lastname)) {
            return this.firstname & " " & this.lastname;
        } else if (len(this.firstname)) {
            return this.firstname;
        } else if (len(this.lastname)) {
            return this.lastname;
        } else {
            return this.username;
        }
    }
    
    /**
     * Check if account is locked
     */
    function getIsLocked() {
        return isDate(this.lockeduntil) && this.lockeduntil > now();
    }
    
    /**
     * Check if email is verified
     */
    function getIsEmailVerified() {
        return isDate(this.emailverifiedat);
    }
    
    /**
     * Check if user has specific role
     */
    function hasRole(required string roleName) {
        return this.roles().exists(where="name = ?", whereParams=[arguments.roleName]);
    }
    
    /**
     * Check if user has any of the specified roles
     */
    function hasAnyRole(required string roleNames) {
        local.roleList = listToArray(arguments.roleNames);
        return this.roles().exists(where="name IN (?)", whereParams=[roleList]);
    }
    
    /**
     * Check if user has permission
     */
    function hasPermission(required string permission) {
        return this.roles().joins("INNER JOIN rolePermissions rp ON roles.id = rp.roleid")
                          .joins("INNER JOIN permissions p ON rp.permissionId = p.id")
                          .exists(where="p.name = ?", whereParams=[arguments.permission]);
    }
    
    /**
     * Add role to user
     */
    function addRole(required string roleName) {
        local.role = model("Role").findOne(where="name = ?", whereParams=[arguments.roleName]);
        if (isObject(local.role) && !this.hasRole(arguments.roleName)) {
            model("UserRole").create(userid=this.id, roleid=local.role.id);
        }
    }
    
    /**
     * Remove role from user
     */
    function removeRole(required string roleName) {
        local.role = model("Role").findOne(where="name = ?", whereParams=[arguments.roleName]);
        if (isObject(local.role)) {
            model("UserRole").deleteAll(where="userid = ? AND roleid = ?", whereParams=[this.id, local.role.id]);
        }
    }
    
    /**
     * Generate password reset token
     */
    function generatePasswordResetToken() {
        this.passwordResetToken = createUUID();
        this.passwordResetExpires = dateAdd("h", 2, now()); // 2 hour expiry
        return this.save();
    }
    
    /**
     * Reset password with token
     */
    function resetPassword(required string token, required string newPassword) {
        if (this.passwordResetToken != arguments.token || 
            !isDate(this.passwordResetExpires) || 
            this.passwordResetExpires < now()) {
            return {success: false, error: "Invalid or expired reset token"};
        }
        
        // Validate new password
        this.password = arguments.newPassword;
        this.passwordConfirmation = arguments.newPassword;
        
        if (!this.valid()) {
            return {success: false, errors: this.allErrors()};
        }
        
        // Clear reset token and save
        this.passwordResetToken = "";
        this.passwordResetExpires = "";
        
        if (this.save()) {
            return {success: true, message: "Password updated successfully"};
        } else {
            return {success: false, error: "Failed to update password"};
        }
    }
    
    /**
     * Verify email with token
     */
    function verifyEmail(required string token) {
        if (this.emailVerificationToken == arguments.token) {
            this.emailverifiedat = now();
            this.emailVerificationToken = "";
            return this.save();
        }
        return false;
    }
    
    /**
     * Record successful login
     */
    function recordSuccessfulLogin() {
        this.lastloginat = now();
        this.logincount = this.logincount + 1;
        this.failedloginattempts = 0;
        this.lockeduntil = "";
        this.save();
        
        // Clean up old login attempts
        this.loginAttempts().deleteAll(where="createdat < ?", whereParams=[dateAdd("d", -7, now())]);
    }
    
    /**
     * Record failed login attempt
     */
    function recordFailedLogin() {
        this.failedloginattempts = this.failedloginattempts + 1;
        
        // Lock account after 5 failed attempts
        if (this.failedloginattempts >= 5) {
            this.lockeduntil = dateAdd("n", 30, now()); // 30 minutes
        }
        
        this.save();
        
        // Log failed attempt
        model("LoginAttempt").create(
            userid = this.id,
            ipAddress = getClientIP(),
            success = false,
            attemptedAt = now()
        );
    }
    
    /**
     * Find active users only
     */
    function findActive() {
        return findAll(where="isactive = 1 AND deletedat IS NULL");
    }
    
    /**
     * Find email verified users
     */
    function findEmailVerified() {
        return findAll(where="emailverifiedat IS NOT NULL");
    }
    
    /**
     * Find users with specific role
     */
    function findWithRole(required string roleName) {
        return findAll(
            include="userRoles(role)", 
            where="roles.name = ?", 
            whereParams=[arguments.roleName]
        );
    }
    
    // Callback methods
    
    /**
     * Callback: Generate email verification token
     */
    private void function generateVerificationToken() {
        this.emailVerificationToken = createUUID();
        this.salt = generateSalt();
    }
    
    /**
     * Callback: Hash password if it has changed
     */
    private void function hashPasswordIfChanged() {
        if (hasChanged("password") && len(this.password)) {
            this.passwordHash = hash(this.password & this.salt, "SHA-256");
            // Clear plain text password
            this.password = "";
            this.passwordConfirmation = "";
        }
    }
    
    /**
     * Callback: Send verification email after creation
     */
    private void function sendVerificationEmail() {
        local.mailer = createObject("component", "mailers.UserMailer");
        local.mailer.emailVerification(
            user = this,
            token = this.emailVerificationToken
        );
    }
    
    /**
     * Callback: Log significant profile changes
     */
    private void function logProfileChanges() {
        local.significantFields = "email,username,isactive";
        local.changedFields = changedProperties();
        
        for (local.field in local.changedFields) {
            if (listFindNoCase(local.significantFields, local.field)) {
                model("UserAuditLog").create(
                    userid = this.id,
                    action = "profile_change",
                    field = local.field,
                    oldValue = local.changedFields[local.field].oldValue,
                    newValue = local.changedFields[local.field].newValue,
                    changedAt = now()
                );
            }
        }
    }
    
    // Validation methods
    
    /**
     * Custom validation: Password strength
     */
    private void function validatePasswordStrength() {
        if (len(this.password)) {
            local.errors = [];
            
            // Check length
            if (len(this.password) < 8) {
                arrayAppend(local.errors, "must be at least 8 characters long");
            }
            
            // Check for uppercase letter
            if (!reFindNoCase("[A-Z]", this.password)) {
                arrayAppend(local.errors, "must contain at least one uppercase letter");
            }
            
            // Check for lowercase letter
            if (!reFindNoCase("[a-z]", this.password)) {
                arrayAppend(local.errors, "must contain at least one lowercase letter");
            }
            
            // Check for number
            if (!reFindNoCase("[0-9]", this.password)) {
                arrayAppend(local.errors, "must contain at least one number");
            }
            
            // Check for special character
            if (!reFindNoCase("[^A-Za-z0-9]", this.password)) {
                arrayAppend(local.errors, "must contain at least one special character");
            }
            
            if (arrayLen(local.errors)) {
                addError(property="password", message="Password #arrayToList(local.errors, ', ')#");
            }
        }
    }
    
    /**
     * Custom validation: Username format
     */
    private void function validateUsernameFormat() {
        if (len(this.username)) {
            // Check for valid characters
            if (reFindNoCase("[^A-Za-z0-9_-]", this.username)) {
                addError(property="username", message="Username can only contain letters, numbers, hyphens, and underscores");
            }
            
            // Check for reserved usernames
            local.reserved = "admin,administrator,root,system,api,www,mail,ftp";
            if (listFindNoCase(local.reserved, this.username)) {
                addError(property="username", message="This username is not available");
            }
        }
    }
    
    // Helper methods
    
    /**
     * Generate cryptographic salt
     */
    private string function generateSalt() {
        return hash(createUUID() & now() & randRange(1, 100000), "MD5");
    }
    
    /**
     * Get client IP address
     */
    private string function getClientIP() {
        if (structKeyExists(cgi, "http_x_forwarded_for") && len(cgi.http_x_forwarded_for)) {
            return listFirst(cgi.http_x_forwarded_for);
        } else {
            return cgi.remote_addr ?: "0.0.0.0";
        }
    }
}
```

## Model Associations

### Association Types and Usage

#### belongsTo (Many-to-One)
```cfm
component extends="Model" {
    function config() {
        // Post belongs to User (author)
        belongsTo("author", modelName="User", foreignKey="authorid");
        
        // Order belongs to Customer
        belongsTo("customer");
        
        // Comment belongs to Post
        belongsTo("post");
    }
}
```

#### hasMany (One-to-Many)
```cfm
component extends="Model" {
    function config() {
        // User has many Posts
        hasMany("posts", foreignKey="authorid");
        
        // Category has many Products
        hasMany("products");
        
        // Post has many Comments with dependency
        hasMany("comments", dependent="delete");
    }
}
```

#### hasOne (One-to-One)
```cfm
component extends="Model" {
    function config() {
        // User has one Profile
        hasOne("profile", dependent="delete");
        
        // Product has one Inventory
        hasOne("inventory");
    }
}
```

#### Many-to-Many with Shortcuts
```cfm
component extends="Model" {
    function config() {
        // User has many Roles through UserRoles
        hasMany("userRoles");
        hasMany(name="userRoles", shortcut="roles");
        
        // Post has many Tags through PostTags
        hasMany("postTags");
        hasMany(name="postTags", shortcut="tags");
    }
}
```

### Dynamic Association Methods

#### hasMany Methods Example
```cfm
// Given: Post hasMany("comments")
post = model("Post").findByKey(1);

// Get all comments
comments = post.comments();

// Get comments with conditions
recentComments = post.comments(where="createdat > ?", whereParams=[dateAdd("d", -7, now())]);

// Count comments
commentCount = post.commentCount();

// Check if has comments
hasComments = post.hasComments();

// Create new comment
newComment = post.createComment(content="Great post!", authorName="John");

// Add existing comment
post.addComment(existingComment);

// Remove comment (set foreign key to null)
post.removeComment(comment);

// Delete comment
post.deleteComment(comment);
```

## Model Validations

### Built-in Validation Methods

#### Presence and Format Validations
```cfm
component extends="Model" {
    function config() {
        // Required fields
        validatesPresenceOf("name,email,password");
        
        // Email format
        validatesFormatOf(
            property="email", 
            with="^[^\s@]+@[^\s@]+\.[^\s@]+$",
            message="Please enter a valid email address"
        );
        
        // Phone format
        validatesFormatOf(
            property="phone",
            with="^\(\d{3}\) \d{3}-\d{4}$",
            message="Phone must be in format (123) 456-7890"
        );
        
        // URL format
        validatesFormatOf(
            property="website",
            with="^https?://[^\s]+$",
            allowBlank=true
        );
    }
}
```

#### Length and Numerical Validations
```cfm
component extends="Model" {
    function config() {
        // String length constraints
        validatesLengthOf(property="username", minimum=3, maximum=50);
        validatesLengthOf(property="password", minimum=8);
        validatesLengthOf(property="bio", maximum=500, allowBlank=true);
        
        // Exact length
        validatesLengthOf(property="postalCode", is=6);
        
        // Numerical constraints
        validatesNumericalityOf(property="age", onlyInteger=true, greaterThan=0, lessThan=150);
        validatesNumericalityOf(property="price", greaterThan=0);
        validatesNumericalityOf(property="discount", greaterThanOrEqualTo=0, lessThanOrEqualTo=100);
    }
}
```

#### Uniqueness and Confirmation
```cfm
component extends="Model" {
    function config() {
        // Unique values
        validatesUniquenessOf("email");
        validatesUniquenessOf("username");
        validatesUniquenessOf("sku", allowBlank=true);
        
        // Scoped uniqueness (within category)
        validatesUniquenessOf(property="name", scope="categoryid");
        
        // Password confirmation
        validatesConfirmationOf("password");
        
        // Email confirmation
        validatesConfirmationOf("email", when="onCreate");
    }
}
```

#### Conditional Validations
```cfm
component extends="Model" {
    function config() {
        // Only on create
        validatesPresenceOf("password", when="onCreate");
        
        // Only on update
        validatesPresenceOf("currentPassword", when="onUpdate");
        
        // Custom condition
        validatesPresenceOf("parentId", condition="this.type == 'child'");
        
        // Unless condition
        validatesPresenceOf("companyName", unless="this.isIndividual");
    }
}
```

### Custom Validations

#### Method-based Custom Validations
```cfm
component extends="Model" {
    function config() {
        // Custom validation methods
        validate(method="validateAge");
        validate(method="validateCreditCard", when="onCreate");
        validate(method="validateBusinessHours");
    }
    
    /**
     * Custom validation: Age must be reasonable
     */
    private void function validateAge() {
        if (this.age < 13 || this.age > 120) {
            addError(property="age", message="Age must be between 13 and 120");
        }
    }
    
    /**
     * Custom validation: Credit card format
     */
    private void function validateCreditCard() {
        if (len(this.creditCardNumber)) {
            local.cleaned = reReplace(this.creditCardNumber, "[^\d]", "", "all");
            
            // Basic length check
            if (len(local.cleaned) < 13 || len(local.cleaned) > 19) {
                addError(property="creditCardNumber", message="Invalid credit card number");
                return;
            }
            
            // Luhn algorithm check
            if (!passesLuhnCheck(local.cleaned)) {
                addError(property="creditCardNumber", message="Invalid credit card number");
            }
        }
    }
    
    /**
     * Custom validation: Business hours format
     */
    private void function validateBusinessHours() {
        if (len(this.businessHours)) {
            // Expected format: "09:00-17:00"
            if (!reFindNoCase("^\d{2}:\d{2}-\d{2}:\d{2}$", this.businessHours)) {
                addError(property="businessHours", message="Business hours must be in format HH:MM-HH:MM");
            }
        }
    }
    
    /**
     * Helper: Luhn algorithm for credit card validation
     */
    private boolean function passesLuhnCheck(required string number) {
        local.sum = 0;
        local.alternate = false;
        
        for (local.i = len(arguments.number); local.i >= 1; local.i--) {
            local.digit = val(mid(arguments.number, local.i, 1));
            
            if (local.alternate) {
                local.digit *= 2;
                if (local.digit > 9) {
                    local.digit -= 9;
                }
            }
            
            local.sum += local.digit;
            local.alternate = !local.alternate;
        }
        
        return (local.sum % 10) == 0;
    }
}
```

## Model Callbacks

### Available Callback Points
```cfm
component extends="Model" {
    function config() {
        // Before callbacks
        beforeValidation("normalizeData");
        beforeSave("updateTimestamps");
        beforeCreate("generateId");
        beforeUpdate("trackChanges");
        beforeDelete("checkReferences");
        
        // After callbacks
        afterValidation("processData");
        afterSave("clearCache");
        afterCreate("sendNotifications");
        afterUpdate("logChanges");
        afterDelete("cleanupFiles");
    }
    
    // Callback implementations
    private void function normalizeData() {
        // Normalize email to lowercase
        if (len(this.email)) {
            this.email = lCase(trim(this.email));
        }
        
        // Normalize phone number
        if (len(this.phone)) {
            this.phone = reReplace(this.phone, "[^\d]", "", "all");
        }
    }
    
    private void function updateTimestamps() {
        if (isNew()) {
            this.createdat = now();
        }
        this.updatedat = now();
    }
    
    private void function generateId() {
        if (!len(this.id)) {
            this.id = createUUID();
        }
    }
    
    private void function trackChanges() {
        // Store changed properties for audit trail
        variables.changedData = changedProperties();
    }
    
    private void function checkReferences() {
        // Prevent deletion if referenced by other records
        if (model("Order").exists(where="customerId = ?", whereParams=[this.id])) {
            throw(type="ReferentialIntegrityError", message="Cannot delete customer with existing orders");
        }
    }
    
    private void function sendNotifications() {
        // Send welcome email for new users
        local.mailer = createObject("component", "mailers.UserMailer");
        local.mailer.welcomeEmail(user=this);
    }
    
    private void function logChanges() {
        // Log changes to audit table
        if (structKeyExists(variables, "changedData")) {
            for (local.field in variables.changedData) {
                model("AuditLog").create(
                    tableName = "users",
                    recordId = this.id,
                    fieldName = local.field,
                    oldValue = variables.changedData[local.field].oldValue,
                    newValue = variables.changedData[local.field].newValue,
                    changedAt = now(),
                    changedBy = session.userid ?: 0
                );
            }
        }
    }
    
    private void function cleanupFiles() {
        // Delete associated files
        if (len(this.avatarPath) && fileExists(expandPath(this.avatarPath))) {
            fileDelete(expandPath(this.avatarPath));
        }
    }
}
```

## Testing Models

### Model Test Structure
```cfm
/**
 * UserTest - Test User model functionality
 */
component extends="wheels.Test" {

    function setup() {
        // Set up test data
        variables.validUserData = {
            username = "testuser",
            email = "test@example.com",
            firstname = "Test",
            lastname = "User",
            password = "SecurePass123!",
            passwordConfirmation = "SecurePass123!"
        };
    }

    function teardown() {
        // Clean up test data
        model("User").deleteAll(where="email LIKE '%test%'");
    }

    // Validation tests
    function test_user_requires_email() {
        local.user = model("User").new(variables.validUserData);
        local.user.email = "";
        
        assert(!local.user.valid(), "User should be invalid without email");
        assert(local.user.hasErrors("email"), "User should have email error");
    }

    function test_user_requires_unique_email() {
        // Create first user
        local.firstUser = model("User").create(variables.validUserData);
        assert(local.firstUser.valid(), "First user should be valid");

        // Try to create second user with same email
        variables.validUserData.username = "testuser2";
        local.secondUser = model("User").new(variables.validUserData);
        
        assert(!local.secondUser.valid(), "Second user should be invalid with duplicate email");
        assert(local.secondUser.hasErrors("email"), "User should have email uniqueness error");
    }

    function test_password_validation() {
        local.user = model("User").new(variables.validUserData);
        
        // Test weak password
        local.user.password = "weak";
        local.user.passwordConfirmation = "weak";
        assert(!local.user.valid(), "User should be invalid with weak password");
        
        // Test strong password
        local.user.password = "StrongPass123!";
        local.user.passwordConfirmation = "StrongPass123!";
        assert(local.user.valid(), "User should be valid with strong password");
    }

    function test_password_confirmation() {
        local.user = model("User").new(variables.validUserData);
        local.user.passwordConfirmation = "DifferentPassword123!";
        
        assert(!local.user.valid(), "User should be invalid when passwords don't match");
        assert(local.user.hasErrors("password"), "User should have password confirmation error");
    }

    // Authentication tests
    function test_authenticate_with_valid_credentials() {
        // Create user
        local.user = model("User").create(variables.validUserData);
        
        // Test authentication
        local.result = model("User").authenticate("test@example.com", "SecurePass123!");
        
        assert(local.result.success, "Authentication should succeed with valid credentials");
        assert(isObject(local.result.user), "Result should include user object");
        assert(local.result.user.id == local.user.id, "Should return correct user");
    }

    function test_authenticate_with_invalid_password() {
        // Create user
        local.user = model("User").create(variables.validUserData);
        
        // Test with wrong password
        local.result = model("User").authenticate("test@example.com", "WrongPassword");
        
        assert(!local.result.success, "Authentication should fail with invalid password");
        assert(structKeyExists(local.result, "error"), "Result should include error message");
    }

    function test_authenticate_with_nonexistent_user() {
        local.result = model("User").authenticate("nonexistent@example.com", "AnyPassword");
        
        assert(!local.result.success, "Authentication should fail for nonexistent user");
    }

    // Association tests
    function test_user_has_many_posts() {
        local.user = model("User").create(variables.validUserData);
        local.post1 = model("Post").create(title="Post 1", content="Content 1", authorid=local.user.id);
        local.post2 = model("Post").create(title="Post 2", content="Content 2", authorid=local.user.id);
        
        local.posts = local.user.posts();
        assert(local.posts.recordCount == 2, "User should have 2 posts");
    }

    function test_user_can_have_roles() {
        local.user = model("User").create(variables.validUserData);
        local.adminRole = model("Role").findOrCreateByName("admin");
        
        local.user.addRole("admin");
        assert(local.user.hasRole("admin"), "User should have admin role");
        
        local.user.removeRole("admin");
        assert(!local.user.hasRole("admin"), "User should no longer have admin role");
    }

    // Business logic tests
    function test_full_name_generation() {
        local.user = model("User").new(variables.validUserData);
        local.fullName = local.user.getFullName();
        
        assert(local.fullName == "Test User", "Full name should combine first and last name");
    }

    function test_password_reset_workflow() {
        local.user = model("User").create(variables.validUserData);
        
        // Generate reset token
        local.result = local.user.generatePasswordResetToken();
        assert(local.result, "Password reset token generation should succeed");
        assert(len(local.user.passwordResetToken) > 0, "Should have reset token");
        assert(isDate(local.user.passwordResetExpires), "Should have expiry date");
        
        // Reset password with valid token
        local.resetResult = local.user.resetPassword(local.user.passwordResetToken, "NewSecurePass123!");
        assert(local.resetResult.success, "Password reset should succeed with valid token");
        
        // Verify old password no longer works
        local.authResult = model("User").authenticate(local.user.email, "SecurePass123!");
        assert(!local.authResult.success, "Old password should no longer work");
        
        // Verify new password works
        local.authResult = model("User").authenticate(local.user.email, "NewSecurePass123!");
        assert(local.authResult.success, "New password should work");
    }

    function test_account_locking_after_failed_attempts() {
        local.user = model("User").create(variables.validUserData);
        
        // Simulate 5 failed login attempts
        for (local.i = 1; local.i <= 5; local.i++) {
            model("User").authenticate(local.user.email, "WrongPassword");
        }
        
        // Reload user to get updated data
        local.user.reload();
        
        assert(local.user.getIsLocked(), "Account should be locked after 5 failed attempts");
        assert(local.user.failedloginattempts >= 5, "Should track failed attempts");
    }

    // Callback tests
    function test_password_encryption_on_save() {
        local.user = model("User").new(variables.validUserData);
        local.originalPassword = local.user.password;
        
        local.user.save();
        
        // Password should be cleared and hash should be set
        assert(local.user.password == "", "Plain text password should be cleared");
        assert(len(local.user.passwordHash) > 0, "Password hash should be set");
        assert(local.user.passwordHash != local.originalPassword, "Hash should be different from original");
    }

    function test_email_verification_token_generation() {
        local.user = model("User").create(variables.validUserData);
        
        assert(len(local.user.emailVerificationToken) > 0, "Should generate email verification token");
        assert(!local.user.getIsEmailVerified(), "Email should not be verified initially");
        
        // Test email verification
        local.result = local.user.verifyEmail(local.user.emailVerificationToken);
        assert(local.result, "Email verification should succeed with valid token");
        assert(local.user.getIsEmailVerified(), "Email should be verified after token validation");
    }

    // Custom finder tests
    function test_active_finder() {
        // Create active and inactive users
        local.activeUser = model("User").create(variables.validUserData);
        
        variables.validUserData.username = "inactive";
        variables.validUserData.email = "inactive@test.com";
        variables.validUserData.isactive = false;
        local.inactiveUser = model("User").create(variables.validUserData);
        
        local.activeUsers = model("User").findActive();
        local.foundActive = false;
        local.foundInactive = false;
        
        for (local.user in activeUsers) {
            if (local.user.id == local.activeUser.id) local.foundActive = true;
            if (local.user.id == local.inactiveUser.id) local.foundInactive = true;
        }
        
        assert(local.foundActive, "Active finder should include active user");
        assert(!local.foundInactive, "Active finder should not include inactive user");
    }
}
```

## Performance and Optimization

### Query Optimization
```cfm
component extends="Model" {
    
    /**
     * Efficient data loading with includes
     */
    function getPostsWithAuthors() {
        return this.findAll(
            include="author",
            select="posts.*, authors.firstname, authors.lastname",
            order="posts.createdat DESC"
        );
    }
    
    /**
     * Use specific selects to reduce data transfer
     */
    function getRecentPostTitles(numeric days = 7) {
        return this.findAll(
            select="id, title, createdat",
            where="createdat > ?",
            whereParams=[dateAdd("d", -arguments.days, now())],
            order="createdat DESC"
        );
    }
    
    /**
     * Pagination for large datasets
     */
    function getPostsPaginated(numeric page = 1, numeric perPage = 10) {
        return this.findAll(
            page=arguments.page,
            perPage=arguments.perPage,
            order="createdat DESC"
        );
    }
    
    /**
     * Use exists() instead of count() for boolean checks
     */
    function hasRecentActivity(numeric days = 30) {
        return this.posts().exists(
            where="createdat > ?",
            whereParams=[dateAdd("d", -arguments.days, now())]
        );
    }
}
```

### Caching Strategies
```cfm
component extends="Model" {
    
    function config() {
        // Enable query caching
        afterFind("enableQueryCache");
        afterSave("clearRelatedCache");
    }
    
    /**
     * Cache expensive calculations
     */
    function getStatistics() {
        local.cacheKey = "user_#this.id#_stats";
        
        if (!cacheKeyExists(local.cacheKey)) {
            local.stats = {
                postCount = this.posts().count(),
                commentCount = this.comments().count(),
                totalViews = this.posts().sum("viewCount"),
                averageRating = this.posts().average("rating")
            };
            
            cachePut(local.cacheKey, local.stats, createTimeSpan(0, 1, 0, 0)); // 1 hour
        }
        
        return cacheGet(local.cacheKey);
    }
    
    /**
     * Clear related caches when data changes
     */
    private void function clearRelatedCache() {
        cacheRemove("user_#this.id#_stats");
        cacheRemove("recent_posts");
        cacheRemove("top_authors");
    }
}
```

## Best Practices

### 1. Model Organization
```cfm
/**
 * Organize config() method logically
 */
function config() {
    // 1. Table configuration
    table("custom_table_name");
    
    // 2. Associations
    belongsTo("category");
    hasMany("comments");
    hasOne("profile");
    
    // 3. Validations (grouped by type)
    validatesPresenceOf("name,email");
    validatesUniquenessOf("email");
    validatesLengthOf(property="name", maximum=100);
    
    // 4. Properties
    property(name="customField", type="string");
    
    // 5. Callbacks
    beforeSave("normalizeData");
    afterCreate("sendNotification");
    
    // 6. Other configuration  
    set(timeStampOnCreateProperty="createdAt");
    // Note: Soft delete enabled automatically if deletedAt column exists
}
```

### 2. Business Logic Placement
```cfm
component extends="Model" {
    
    // Keep complex business logic in models
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
    
    // Provide clear interfaces for complex operations
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
}
```

### 3. Error Handling
```cfm
component extends="Model" {
    
    function processPayment(required struct paymentData) {
        try {
            transaction {
                // Process payment logic
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
}
```

### 4. Security Considerations
```cfm
component extends="Model" {
    
    function config() {
        // Mass assignment protection
        protectedProperties("isAdmin,createdat,updatedat");
        
        // Or whitelist approach
        accessibleProperties("name,email,bio");
    }
    
    /**
     * Sanitize input data
     */
    private void function sanitizeInput() {
        if (len(this.bio)) {
            // Remove potentially harmful HTML
            this.bio = reReplace(this.bio, "<script[^>]*>.*?</script>", "", "all");
            this.bio = reReplace(this.bio, "javascript:", "", "all");
        }
    }
    
    /**
     * Validate permissions before sensitive operations
     */
    function deleteWithPermissionCheck(required numeric currentUserId) {
        if (this.userid != arguments.currentUserId && !hasAdminRole(arguments.currentUserId)) {
            throw(type="PermissionDenied", message="Cannot delete another user's record");
        }
        
        return this.delete();
    }
}
```

## Automatic Time Stamps

Wheels automatically handles time stamping of records when you have the proper columns in your database.

### Time Stamp Columns
- **`createdat`** - Automatically set to current date/time when record is created
- **`updatedat`** - Automatically set to current date/time when record is updated

```cfm
component extends="Model" {
    function config() {
        // Enable automatic timestamps
        set(timeStampOnCreateProperty="createdAt");  // Sets createdAt on creation
        set(timeStampOnUpdateProperty="updatedAt");  // Sets updatedAt on modification
    }
}
```

### Time Zone Configuration
Time stamps use UTC by default, but you can configure to use local time:
```cfm
// In /config/settings.cfm
set(timeStampMode="local");
```

### Database Column Requirements
- Columns must accept date/time values (`datetime` or `timestamp`)
- Columns should allow `null` values
- Use exact column names: `createdat` and `updatedat`

## Column Statistics

Wheels provides built-in statistical functions for performing aggregate calculations on your data.

### Basic Statistical Methods
```cfm
// Count records
authorCount = model("Author").count();
authorCount = model("Author").count(where="lastname LIKE 'A%'");

// Get average value
avgSalary = model("Employee").average(property="salary", where="departmentId=1");

// Get minimum and maximum values
highestSalary = model("Employee").maximum("salary");
lowestSalary = model("Employee").minimum("salary");

// Calculate sum
totalRevenue = model("Invoice").sum("billedAmount");
```

### Advanced Statistical Queries
```cfm
// With associations
authorCount = model("Author").count(include="profile", where="countryId=1");

// With grouping (returns query result set)
avgSalaries = model("Employee").average(property="salary", group="departmentId");

// Using distinct values
uniqueAverage = model("Product").average(property="price", distinct=true);
```

### Statistics with Associations
```cfm
// Count with hasMany association (uses DISTINCT automatically)
authorCount = model("Author").count(include="books", where="title LIKE 'Wheels%'");

// Complex joins
authorCount = model("Author").count(
    include="profile(country)", 
    where="countries.name='USA' AND lastname LIKE 'A%'"
);
```

## Calculated Properties

Generate additional properties dynamically using SQL calculations without storing redundant data.

### Basic Calculated Properties
```cfm
component extends="Model" {
    function config() {
        // Full name calculation
        property(
            name="fullName",
            sql="RTRIM(LTRIM(ISNULL(users.firstname, '') + ' ' + ISNULL(users.lastname, '')))"
        );
        
        // Age calculation from birthdate
        property(
            name="age",
            sql="(CAST(CONVERT(CHAR(8), GETDATE(), 112) AS INT) - 
                  CAST(CONVERT(CHAR(8), users.birthDate, 112) AS INT)) / 10000"
        );
        
        // Virtual property (not from database)
        property(name="displayName", sql=false);
    }
}
```

### Using Calculated Properties in Queries
```cfm
// Use calculated properties in WHERE clauses
youngAdults = model("User").findAll(
    where="age >= 18 AND age < 30",
    order="age DESC"
);

// Use in SELECT statements
users = model("User").findAll(select="id, fullName, age");
```

### Specifying Data Types
```cfm
component extends="Model" {
    function config() {
        property(
            name="createdatAlias",
            sql="posts.createdat",
            dataType="datetime"
        );
    }
}
```

## Dirty Records (Change Tracking)

Track changes to model objects to know what has been modified since loading from the database.

### Change Tracking Methods
```cfm
post = model("Post").findByKey(1);

// Check if any property has changed
result = post.hasChanged();  // false (just loaded)

// Make a change
post.title = "New Title";
result = post.hasChanged();  // true

// Check specific property
result = post.hasChanged("title");  // true
result = post.titleHasChanged();    // Dynamic method - true

// Get previous value
oldTitle = post.changedFrom("title");
oldTitle = post.titleChangedFrom();  // Dynamic method

// Get all changes
changedProps = post.changedProperties();  // Array of property names
allChanges = post.allChanges();          // Struct with old/new values
```

### Change Tracking Lifecycle
```cfm
post = model("Post").new();
result = post.hasChanged();  // true (new objects are always "changed")
result = post.isNew();       // true (hasn't been saved yet)

post.save();
result = post.hasChanged();  // false (cleared after save)

// Revert changes
post.title = "Changed Title";
post.reload();  // Reloads from database, loses changes
```

### Practical Usage in Callbacks
```cfm
component extends="Model" {
    function config() {
        beforeSave("trackImportantChanges");
    }
    
    private void function trackImportantChanges() {
        if (hasChanged("email")) {
            // Send email verification when email changes
            this.emailVerified = false;
            this.emailVerificationToken = createUUID();
        }
        
        if (hasChanged("price") && this.price > changedFrom("price")) {
            // Log price increases
            writeLog("Price increase for product #this.id#: #changedFrom('price')# to #this.price#");
        }
    }
}
```

## Dynamic Finders

Use method names to define search criteria instead of passing arguments.

### Basic Dynamic Finders
```cfm
// Instead of findOne(where="email='me@example.com'")
user = model("User").findOneByEmail("me@example.com");

// Instead of findAll(where="status='active'")  
users = model("User").findAllByStatus("active");
```

### Multiple Property Finders
```cfm
// Find by multiple properties (note: single argument with comma-separated values)
user = model("User").findOneByUsernameAndPassword("bob,secretpass");

// With named parameters when using additional arguments
users = model("User").findAllByState(
    value="NY",
    order="lastname", 
    page=2
);

// Multiple values with named parameter
users = model("User").findAllByCityAndState(
    values="Buffalo,NY",
    order="lastname DESC"
);
```

### Dynamic Finder Guidelines
```cfm
// Good - clear column names
users = model("User").findAllByFirstNameAndLastName("John,Smith");

// Bad - avoid "And" in column names (breaks parsing)
// Don't name columns like: "firstandlastname"

// Works with all finder arguments
users = model("User").findAllByState(
    value="CA",
    include="profile",
    order="lastname",
    page=3,
    perPage=25
);
```

## Nested Properties

Save parent and associated child models in a single operation using nested properties.

### One-to-One Nested Properties
```cfm
// User model with profile association
component extends="Model" {
    function config() {
        hasOne("profile");
        nestedProperties(associations="profile");
    }
}

// Controller setup
function new() {
    newProfile = model("Profile").new();
    user = model("User").new(profile=newProfile);
}

// View form with association
#textField(objectName="user", property="firstname")#
#textField(
    objectName="user", 
    association="profile", 
    property="bio"
)#

// Save both user and profile
user = model("User").new(params.user);
user.save();  // Saves both user and profile in transaction
```

### One-to-Many Nested Properties
```cfm
// User with multiple addresses
component extends="Model" {
    function config() {
        hasMany("addresses");
        nestedProperties(associations="addresses", allowDelete=true);
    }
}

// Controller setup
function new() {
    newAddresses = [model("Address").new()];
    user = model("User").new(addresses=newAddresses);
}

// Partial view for addresses (_address.cfm)
#textField(
    objectName="user",
    association="addresses", 
    position=arguments.current,
    property="street"
)#

// Form includes addresses
<div id="addresses">
    #includePartial(user.addresses)#
</div>
```

### Many-to-Many with Nested Properties
```cfm
// Customer with publication subscriptions
component extends="Model" {
    function config() {
        hasMany(name="subscriptions", shortcut="publications");
        nestedProperties(associations="subscriptions", allowDelete=true);
    }
}

// Form with checkboxes for many-to-many
<cfloop query="publications">
    #hasManyCheckBox(
        label=publications.title,
        objectName="customer",
        association="subscriptions", 
        keys="#customer.key()#,#publications.id#"
    )#
</cfloop>
```

### Nested Properties Benefits
- Automatic transaction wrapping
- Single save operation for complex data
- Maintains referential integrity
- Supports validation across all models
- Handles creates, updates, and deletes

## Transactions

Wheels automatically manages database transactions for data integrity and provides manual transaction control.

### Automatic Transactions
```cfm
// All callbacks run in single transaction
component extends="Model" {
    function config() {
        afterCreate("createFirstPost");
    }
    
    function createFirstPost() {
        post = model("Post").new(
            authorid=this.id,
            title="My First Post"
        );
        post.save();  // If this fails, author creation rolls back
    }
}
```

### Manual Transaction Control
```cfm
// Disable automatic transactions
model("Author").create(name="John", transaction=false);

// Force rollback for testing
model("Author").create(name="John", transaction="rollback");
```

### Global Transaction Configuration
```cfm
// In /config/settings.cfm
set(transactionMode=false);      // Disable all transactions
set(transactionMode="rollback"); // Rollback all transactions
```

### Nested Transaction Support
```cfm
// Use invokeWithTransaction for nested transaction support
invokeWithTransaction(
    method="transferFunds",
    personFrom=david,
    personTo=mary,
    amount=100
);

function transferFunds(required personFrom, required personTo, required numeric amount) {
    arguments.personFrom.update(balance=personFrom.balance - arguments.amount);
    arguments.personTo.update(balance=personTo.balance + arguments.amount);
}
```

## Multiple Data Sources

Configure models to use different databases for data distribution or legacy system integration.

### Per-Model Data Source Configuration
```cfm
component extends="Model" {
    function config() {
        dataSource("mySecondDatabase");  // Must be configured in CFML engine
    }
}
```

### Data Source Limitations
```cfm
// Main model determines data source for entire query
// Photo uses "myFirstDatabase", PhotoGallery uses "mySecondDatabase"
// But this query uses Photo's data source for the entire join
myPhotos = model("Photo").findAll(include="photoGalleries");
```

### Multi-Database Architecture Example
```cfm
// User data in primary database
component name="User" extends="Model" {
    function config() {
        dataSource("primaryDB");
        hasMany("orders");
    }
}

// Analytics data in separate database  
component name="UserAnalytics" extends="Model" {
    function config() {
        dataSource("analyticsDB");
        table("user_analytics");
    }
}
```

## Pagination

Efficiently handle large datasets by breaking results into pages.

### Basic Pagination
```cfm
// Get records 26-50 (page 2, 25 per page)
authors = model("Author").findAll(page=2, perPage=25, order="lastname");

// Pagination is object-based, not record-based
authorsWithBooks = model("Author").findAll(
    include="books",
    page=2, 
    perPage=25  // 25 authors, but may return more records due to books
);

// For record-based pagination, flip the relationship
booksWithAuthors = model("Book").findAll(
    include="author",
    page=2,
    perPage=25  // Always returns exactly 25 records
);
```

### Pagination Metadata
```cfm
// Get pagination information
users = model("User").findAll(page=params.page, perPage=20);
paginationInfo = pagination();

// Available metadata
currentPage = paginationInfo.currentPage;
totalPages = paginationInfo.totalPages;
totalRecords = paginationInfo.totalRecords;
```

### Advanced Pagination Examples
```cfm
// Paginated search results
searchResults = model("Product").findAll(
    where="name LIKE ? OR description LIKE ?",
    whereParams=["%#params.q#%", "%#params.q#%"],
    page=params.page ?: 1,
    perPage=24,
    order="name"
);

// Paginated with complex associations
posts = model("Post").findAll(
    include="author,category,comments",
    where="posts.status = 'published'",
    page=params.page ?: 1,
    perPage=10,
    order="posts.publishedAt DESC"
);
```

## Soft Delete

Implement logical deletion where records are marked as deleted rather than physically removed from the database.

### How Soft Delete Works in Wheels

Soft delete is enabled automatically when you add a `deletedat` column to your database table. No configuration is needed in your model.

### Database Column Requirements
- Column name: `deletedat` (exact case)
- Column type: `date`, `datetime`, or `timestamp` (depends on your database)
- Should allow `NULL` values

### Soft Delete Behavior
```cfm
// When deletedat column exists, delete() sets timestamp instead of removing record
user = model("User").findByKey(1);
user.delete();  // Sets deletedat to current timestamp, record stays in database

// Normal finders automatically exclude soft-deleted records
users = model("User").findAll();  // Won't include records where deletedat IS NOT NULL

// Include soft-deleted records explicitly
allUsers = model("User").findAll(includeSoftDeletes=true);

// Manual queries need to exclude soft deletes explicitly
activeUsers = model("User").findAll(where="deletedat IS NULL");
```

### Benefits of Soft Delete
- Keep deleted data for audit trails
- Maintain referential integrity
- Allow data recovery if needed
- Business logic can treat data as deleted while preserving it
- No application code changes needed once column exists

## Advanced Query Methods

### Raw SQL Queries
```cfm
// Execute custom SQL
topCustomers = model("Customer").findBySQL("
    SELECT c.*, COUNT(o.id) as orderCount, SUM(o.total) as totalSpent
    FROM customers c
    INNER JOIN orders o ON c.id = o.customerId  
    WHERE c.active = ?
    GROUP BY c.id
    ORDER BY totalSpent DESC
    LIMIT 10
", [1]);
```

### Boolean Existence Checks
```cfm
// More efficient than count() > 0
hasOrders = model("Customer").exists(where="id = ?", whereParams=[customerId]);
hasRecentActivity = model("User").posts().exists(where="createdat > ?", whereParams=[lastWeek]);
```

### Query Optimization with Includes and Select
```cfm
// Eager load associations to avoid N+1 queries
posts = model("Post").findAll(include="author,category,tags");

// Limit columns to reduce data transfer
recentTitles = model("Post").findAll(
    select="id, title, createdat",
    where="createdat > ?",
    whereParams=[dateAdd("d", -7, now())],
    order="createdat DESC"
);
```

## CFWheels vs Ruby on Rails - Common Mistakes to Avoid

**❌ INCORRECT (Rails-style):**
```cfm
// These Rails patterns DO NOT work in CFWheels:
scope(name="active", where="isactive = 1");           // ❌ No scope() in models
function scopeActive() { return this.where(...); }   // ❌ No scopeXXX() methods  
User.active.published                                 // ❌ No chainable scopes
has_many :posts, dependent: :destroy                 // ❌ Wrong syntax
```

**✅ CORRECT (CFWheels-style):**
```cfm
// Use custom finder methods instead:
function findActive() {
    return findAll(where="isactive = 1");
}

function findPublished() {
    return findAll(where="status = 'published'");
}

// Proper CFWheels associations:
hasMany("posts", dependent="delete");               // ✅ Correct syntax
```

## Important Notes

- **Convention over Configuration**: Follow Wheels naming conventions for tables, columns, and foreign keys
- **Active Record Pattern**: Models represent both data and behavior - use them for business logic
- **Database First**: Wheels introspects database schema to determine model properties automatically
- **Configuration in config()**: All model configuration should be done in the `config()` method
- **Validation Lifecycle**: Validations run automatically before save/create/update operations
- **Association Benefits**: Proper associations enable powerful query capabilities and data integrity
- **Performance Considerations**: Use includes, specific selects, and caching for optimal performance
- **Testing**: Always test models thoroughly including validations, associations, and business logic
- **Security**: Protect against mass assignment and always validate/sanitize input data
- **Transactions**: Use database transactions for operations that modify multiple records
- **Change Tracking**: Leverage dirty record functionality for audit trails and conditional logic
- **Dynamic Methods**: Use dynamic finders and change tracking methods for cleaner code
- **Statistical Functions**: Utilize built-in aggregate functions instead of raw SQL when possible
- **Time Stamps**: Configure automatic time stamping to track record creation and modification
- **Calculated Properties**: Use SQL-based calculated properties for computed values
- **Soft Deletes**: Add `deletedat` column to enable automatic soft delete functionality

Models are the foundation of your data layer in Wheels applications, providing a rich, object-oriented interface to your database while maintaining the simplicity and conventions that make Wheels productive.