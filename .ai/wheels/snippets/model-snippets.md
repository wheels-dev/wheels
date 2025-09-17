# Model Code Snippets

## Description
Common model patterns and code snippets for Wheels applications.

## Basic Model Structure
```cfm
component extends="Model" {
    function config() {
        // Table mapping (if different from convention)
        table("custom_table_name");

        // Associations
        hasMany("comments");
        belongsTo("user");

        // Validations
        validatesPresenceOf("title,body");
        validatesUniquenessOf(property="slug");

        // Callbacks
        beforeSave("generateSlug");
        afterCreate("sendNotifications");

        // Properties
        property(name="fullTitle", sql="CONCAT(title, ' - ', subtitle)");
    }

    // Custom methods
    function fullName() {
        return trim("#firstName# #lastName#");
    }
}
```

## Validation Patterns
```cfm
function config() {
    // Presence validation
    validatesPresenceOf("firstName,lastName,email");

    // Format validation
    validatesFormatOf(
        property="email",
        regEx="^[\w\.-]+@[\w\.-]+\.\w+$",
        message="Please enter a valid email address"
    );

    // Length validation
    validatesLengthOf(
        properties="firstName,lastName",
        maximum=50,
        message="Name cannot exceed 50 characters"
    );

    // Uniqueness validation
    validatesUniquenessOf(
        property="email",
        message="Email address already taken"
    );

    // Custom validation
    validate("validateBusinessRules");
}

private function validateBusinessRules() {
    if (this.age < 18 && this.accountType == "premium") {
        addError(property="age", message="Premium accounts require age 18+");
    }
}
```

## Association Patterns
```cfm
function config() {
    // One-to-many
    hasMany("orders");
    hasMany("activeOrders", modelName="order", where="status = 'active'");

    // Many-to-one
    belongsTo("category");
    belongsTo("author", modelName="user", foreignKey="authorId");

    // One-to-one
    hasOne("profile");

    // Many-to-many through join table
    hasMany("tags", through="posttags");

    // Nested properties for forms
    nestedProperties(association="comments", allowDelete=true);
}
```

## Callback Patterns
```cfm
function config() {
    // Before callbacks
    beforeSave("normalizeData");
    beforeCreate("generateSlug");
    beforeUpdate("updateTimestamp");
    beforeDelete("archiveRelatedData");

    // After callbacks
    afterCreate("sendWelcomeEmail");
    afterUpdate("clearCache");
    afterDelete("cleanupFiles");
}

private function generateSlug() {
    if (hasChanged("title")) {
        this.slug = createSlug(this.title);
    }
}

private function sendWelcomeEmail() {
    if (this.isNewRecord()) {
        sendMail(
            to=this.email,
            subject="Welcome!",
            template="welcome"
        );
    }
}
```

## Query Helpers
```cfm
// Custom finder methods
function findActive() {
    return findAll(where="active = 1");
}

function findBySlug(required string slug) {
    return findOne(where="slug = '#arguments.slug#'");
}

function findPublished() {
    return findAll(where="publishedAt IS NOT NULL", order="publishedAt DESC");
}

// Scoped queries
function recent(days=30) {
    return findAll(
        where="createdAt >= '#DateAdd('d', -arguments.days, Now())#'",
        order="createdAt DESC"
    );
}
```

## Calculated Properties
```cfm
function config() {
    // SQL-based calculated property
    property(name="orderTotal", sql="(SELECT SUM(amount) FROM order_items WHERE order_id = orders.id)");
}

// Method-based calculated property
function displayName() {
    if (Len(this.nickName)) {
        return this.nickName;
    } else {
        return this.fullName();
    }
}

function isExpired() {
    return IsDate(this.expiresAt) && this.expiresAt < Now();
}
```