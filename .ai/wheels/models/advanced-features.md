# Advanced Model Features

## Description
Advanced Wheels model features including timestamps, statistics, calculated properties, change tracking, dynamic finders, nested properties, transactions, and other sophisticated functionality.

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
    where="name LIKE '%#params.q#%' OR description LIKE '%#params.q#%'",
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
sql = "SELECT c.*, COUNT(o.id) as orderCount, SUM(o.total) as totalSpent
    FROM customers c
    INNER JOIN orders o ON c.id = o.customerId
    WHERE c.active = :active
    GROUP BY c.id
    ORDER BY totalSpent DESC
    LIMIT 10";

topCustomers = queryExecute(sql, { active = { value = "1", cfsqltype = "cf_sql_integer" } }, { datasource = "yourDatasourceName" });
```

### Boolean Existence Checks
```cfm
// More efficient than count() > 0
hasOrders = model("Customer").exists(where="id = '#customerId#'");
hasRecentActivity = model("User").posts().exists(where="createdat > '#lastWeek#'");
```

### Query Optimization with Includes and Select
```cfm
// Eager load associations to avoid N+1 queries
posts = model("Post").findAll(include="author,category,tags");

// Limit columns to reduce data transfer
recentTitles = model("Post").findAll(
    select="id, title, createdat",
    where="createdat > '#dateAdd("d", -7, now())#'",
    order="createdat DESC"
);
```

## Wheels vs Ruby on Rails - Common Mistakes to Avoid

**❌ INCORRECT (Rails-style):**
```cfm
// These Rails patterns DO NOT work in Wheels:
scope(name="active", where="isactive = 1");           // ❌ No scope() in models
function scopeActive() { return this.where(...); }   // ❌ No scopeXXX() methods
User.active.published                                 // ❌ No chainable scopes
has_many :posts, dependent: :destroy                 // ❌ Wrong syntax
```

**✅ CORRECT (Wheels-style):**
```cfm
// Use custom finder methods instead:
function findActive() {
    return findAll(where="isactive = 1");
}

function findPublished() {
    return findAll(where="status = 'published'");
}

// Proper Wheels associations:
hasMany("posts");                                   // ✅ Correct syntax - positional parameters
hasMany(name="posts", dependent="delete");         // ✅ Correct syntax - named parameters with options
```

## Model Feature Comparison

### Wheels Model Features

**✅ Available in Wheels:**
- Active Record pattern
- Associations (belongsTo, hasMany, hasOne)
- Validations (presence, format, uniqueness, etc.)
- Callbacks (before/after save, create, update, delete)
- Change tracking (dirty records)
- Automatic timestamps
- Soft deletes (automatic with deletedat column)
- Pagination
- Caching
- Transactions
- Dynamic finders
- Nested properties
- Calculated properties
- Statistical functions
- Multiple data sources

**❌ NOT Available in Wheels:**
- ActiveRecord scopes (use custom finder methods)
- Chainable query methods (use single findAll call)
- Migration rollback (Wheels has up/down methods)
- Polymorphic associations (work around with conventions)

## Usage Patterns

### Model Initialization
```cfm
// Create new instance
user = model("User").new();
user = model("User").new(name="John", email="john@example.com");

// Create and save
user = model("User").create(name="John", email="john@example.com");

// Find existing
user = model("User").findByKey(1);
user = model("User").findOne(where="email = 'john@example.com'");
users = model("User").findAll();
```

### Data Manipulation
```cfm
// Update single record
user.update(name="Jane");

// Update multiple records
model("User").updateAll(isActive=true, where="lastLogin > '#dateAdd("d", -30, now())#'");

// Delete records
user.delete();
model("User").deleteAll(where="isActive = 0");
```

### Query Building
```cfm
// Complex queries
users = model("User").findAll(
    where="isActive = 1 AND age >= 18",
    include="profile,orders",
    order="lastName, firstName",
    page=2,
    perPage=25
);

// Statistical queries
avgAge = model("User").average("age", where="isActive = 1");
userCount = model("User").count(where="lastLogin > '#dateAdd("d", -7, now())#'");
```

## Related Documentation
- [Model Architecture](./architecture.md)
- [Model Associations](./associations.md)
- [Model Validations](./validations.md)
- [Model Callbacks](./callbacks.md)
- [Model Performance](./performance.md)
- [Model Best Practices](./best-practices.md)