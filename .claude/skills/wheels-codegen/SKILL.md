---
name: Wheels Code Generator
description: Generate and validate Wheels MVC components — models, controllers, views, migrations, and routes. Detects anti-patterns (mixed args, query/array confusion, missing setPrimaryKey, wrong validation params, non-existent helpers, database-specific SQL). Use when creating any Wheels component, modifying schema, defining routes, or reviewing generated code for correctness.
---

# Wheels Code Generator

Generates models, controllers, views, migrations, and routes for CFWheels 3.0+ applications. Includes inline anti-pattern detection to catch common errors before they reach production.

## Anti-Pattern Rules

These rules apply to ALL generated Wheels code. Check every file before writing.

### 1. Never Mix Positional and Named Arguments

```cfm
hasMany("comments", dependent="delete")           // WRONG
hasMany(name="comments", dependent="delete")       // CORRECT
belongsTo("user", foreignKey="userId")             // WRONG
belongsTo(name="user", foreignKey="userId")        // CORRECT
validatesPresenceOf("title", message="Required")   // WRONG
findByKey(params.key, include="comments")          // WRONG
findByKey(key=params.key, include="comments")      // CORRECT
```

Use the SAME style throughout the entire config() function. If any call needs named params, use named params for ALL calls.

### 2. Validation Parameter Is "properties" (Plural)

```cfm
validatesPresenceOf(property="username,email")     // WRONG - silently ignored
validatesPresenceOf(properties="username,email")   // CORRECT
validatesUniquenessOf(properties="email")          // CORRECT
validatesFormatOf(properties="email", regEx="...") // CORRECT
validatesLengthOf(properties="username", minimum=3)// CORRECT
validate(methods="customValidation")               // CORRECT ("methods" plural)
```

### 3. Always Add setPrimaryKey() to Models

Even when migrations correctly create the primary key, models MUST declare it explicitly:

```cfm
component extends="Model" {
    function config() {
        table("users");
        setPrimaryKey("id");  // MANDATORY - causes NoPrimaryKey error if missing
        hasMany(name="posts");
    }
}
```

### 4. structKeyExists() Before Property Access in Callbacks

In beforeCreate/beforeValidation callbacks, properties may not exist yet:

```cfm
// WRONG - throws "no accessible Member" error
if (!len(this.followersCount)) { this.followersCount = 0; }

// CORRECT
if (!structKeyExists(this, "followersCount") || !len(this.followersCount)) {
    this.followersCount = 0;
}
```

### 5. Associations Return Queries, Not Arrays

```cfm
ArrayLen(post.comments())                          // WRONG
post.comments().recordCount                        // CORRECT
<cfloop array="#comments#" index="c">              // WRONG
<cfloop query="comments">                          // CORRECT
```

### 6. No Direct Association Access in Query Loops

```cfm
// WRONG - query rows are not objects
<cfloop query="posts">
    #posts.comments().recordCount#                 // FAILS
</cfloop>

// CORRECT - use include to preload, or reload object
tweets = model("Tweet").findAll(include="user", order="createdAt DESC");
<cfloop query="tweets">
    #tweets.username#                              // Works - joined data
</cfloop>
```

### 7. Non-Existent Form Helpers

Wheels does NOT have emailField(), passwordField(), numberField(), urlField(). Use textField() with type:

```cfm
#textField(objectName="user", property="email", type="email")#
#textField(objectName="user", property="password", type="password")#
#textField(objectName="user", property="age", type="number")#
```

### 8. Database-Specific SQL in Migrations

Never use NOW(), DATE_SUB(), CURDATE(), INTERVAL in execute() statements:

```cfm
// WRONG
execute("INSERT INTO posts (publishedAt) VALUES (NOW())");

// CORRECT
var now = Now();
var formatted = "TIMESTAMP '#DateFormat(now, 'yyyy-mm-dd')# #TimeFormat(now, 'HH:mm:ss')#'";
execute("INSERT INTO posts (publishedAt) VALUES (#formatted#)");
```

### 9. Use startFormTag() for CSRF Protection

```cfm
<form method="post" action="/users">               // WRONG - no CSRF token
#startFormTag(action="create")#                     // CORRECT - auto CSRF
```

### 10. linkTo() Escapes HTML in Text Param

```cfm
// WRONG - HTML will be escaped
#linkTo(text="<span>Brand</span>", controller="home", action="index")#

// CORRECT - use urlFor() with manual anchor
<a href="#urlFor(controller='home', action='index')#"><span>Brand</span></a>
```

### 11. Update Forms Need Route + Key

```cfm
#startFormTag(action="update", method="patch")#              // WRONG
#startFormTag(route="user", key=user.id, method="patch")#    // CORRECT
```

### 12. CLI Generator Produces String Booleans

After using `wheels g migration`, fix createTable calls:

```cfm
t = createTable(name='users', force='false', id='true');    // WRONG - generated
t = createTable(name='users');                               // CORRECT - use defaults
```

### 13. timestamps() Includes deletedAt

```cfm
t.datetime(columnNames="deletedAt");
t.timestamps();    // WRONG - duplicate deletedAt

t.timestamps();    // CORRECT - creates createdAt, updatedAt, AND deletedAt
```

---

## Model Generation

### Base Template

Every model MUST follow this structure:

```cfm
component extends="Model" {
    function config() {
        table("tablename");
        setPrimaryKey("id");

        // Associations - ALL named params
        hasMany(name="comments", dependent="delete");
        belongsTo(name="author", modelName="User", foreignKey="userId");
        hasOne(name="profile");

        // Validations - use "properties" (plural)
        validatesPresenceOf(properties="title,email");
        validatesUniquenessOf(properties="email", message="already taken");
        validatesFormatOf(properties="email", regEx="^[\w\.-]+@[\w\.-]+\.\w+$");
        validatesLengthOf(properties="username", minimum=3, maximum=50);

        // Callbacks
        beforeCreate("setDefaults");
        beforeSave("hashPassword");
        afterCreate("sendWelcomeEmail");
    }
}
```

### Association Patterns

**One-to-Many:**
```cfm
// Parent
hasMany(name="comments", dependent="delete");
// Child
belongsTo(name="post");
```

**Many-to-Many (through join table):**
```cfm
// Post model
hasMany(name="postTags");
hasManyThrough(name="tags", through="postTags");
// Tag model
hasMany(name="postTags");
hasManyThrough(name="posts", through="postTags");
// PostTag join model
belongsTo(name="post");
belongsTo(name="tag");
```

**Self-Referential:**
```cfm
hasMany(name="followings", modelName="Follow", foreignKey="followerId");
hasMany(name="followers", modelName="Follow", foreignKey="followingId");
```

### Validation Reference

All use `properties=` (plural). Key options: `message=`, `allowBlank=`, `condition=`.

```cfm
validatesPresenceOf(properties="name,email");
validatesUniquenessOf(properties="email");
validatesUniquenessOf(properties="slug", scope="categoryId");
validatesFormatOf(properties="email", regEx="^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$");
validatesLengthOf(properties="password", minimum=8);
validatesNumericalityOf(properties="price", greaterThan=0);
validatesInclusionOf(properties="status", list="draft,published,archived");
validatesExclusionOf(properties="username", list="admin,root,system");
validatesConfirmationOf(properties="password");
validatesPresenceOf(properties="password", condition="isNew()");
```

**Custom:** `validate(methods="myCheck")` then `addError(property="field", message="msg")` in private method. Use `structKeyExists()` before comparing properties.

### Callbacks

Available: `beforeValidation`, `beforeValidationOnCreate`, `beforeValidationOnUpdate`, `beforeSave`, `beforeCreate`, `beforeUpdate`, `beforeDelete`, `afterValidation`, `afterSave`, `afterCreate`, `afterUpdate`, `afterDelete`, `afterNew`, `afterFind`. All callback methods must be `private`.

```cfm
// Slug generation (beforeValidationOnCreate)
private function generateSlug() {
    if (!len(this.slug) && len(this.title)) {
        this.slug = lCase(reReplace(this.title, "[^a-zA-Z0-9]", "-", "ALL"));
    }
}

// Password hashing (beforeSave)
private function hashPassword() {
    if (structKeyExists(this, "password") && len(this.password)) {
        this.password = hash(this.password, "SHA-512");
    }
}

// Default values (beforeCreate) - ALWAYS check structKeyExists
private function setDefaults() {
    if (!structKeyExists(this, "viewCount") || !len(this.viewCount)) {
        this.viewCount = 0;
    }
}
```

---

## Controller Generation

### CRUD Template

```cfm
component extends="Controller" {

    function config() {
        verifies(only="show,edit,update,delete", params="key", paramsTypes="integer");
        filters(through="findResource", only="show,edit,update,delete");
        filters(through="requireAuth", except="index,show");
    }

    function index() {
        resources = model("Resource").findAll(order="createdAt DESC", page=params.page);
    }

    function show() {
        // resource loaded by filter
    }

    function new() {
        resource = model("Resource").new();
    }

    function create() {
        resource = model("Resource").new(params.resource);
        if (resource.save()) {
            flashInsert(success="Resource created!");
            redirectTo(action="show", key=resource.key());
        } else {
            flashInsert(error="Please correct the errors below.");
            renderView(action="new");
        }
    }

    function edit() {
        // resource loaded by filter
    }

    function update() {
        if (resource.update(params.resource)) {
            flashInsert(success="Resource updated!");
            redirectTo(action="show", key=resource.key());
        } else {
            flashInsert(error="Please correct the errors below.");
            renderView(action="edit");
        }
    }

    function delete() {
        if (resource.delete()) {
            flashInsert(success="Resource deleted!");
        } else {
            flashInsert(error="Unable to delete.");
        }
        redirectTo(action="index");
    }

    // PRIVATE filters

    private function findResource() {
        resource = model("Resource").findByKey(key=params.key);
        if (!isObject(resource)) {
            flashInsert(error="Resource not found.");
            redirectTo(action="index");
        }
    }

    private function requireAuth() {
        if (!structKeyExists(session, "userId")) {
            flashInsert(error="Please log in.");
            redirectTo(controller="sessions", action="new");
        }
    }
}
```

### Filter Patterns

Filters MUST be private functions. Always include filters for ALL actions that use loaded data:

```cfm
// WRONG - show expects resource but filter doesn't cover it
filters(through="findResource", only="edit,update,delete");

// CORRECT
filters(through="findResource", only="show,edit,update,delete");
```

**Ownership filter:**
```cfm
private function requireOwnership() {
    if (!isObject(resource) || resource.userId != session.userId) {
        flashInsert(error="Permission denied.");
        redirectTo(action="index");
    }
}
```

**Key parameter fallback (profile controllers):**
```cfm
private function findUser() {
    if (!structKeyExists(params, "key") && structKeyExists(session, "userId")) {
        params.key = session.userId;
    }
    user = model("User").findByKey(key=params.key);
    if (!isObject(user)) {
        flashInsert(error="User not found.");
        redirectTo(controller="home", action="index");
    }
}
```

### Optional Password Update

For profile edits where password is optional: strip blank password before update.

```cfm
if (structKeyExists(params.user, "password") && !len(trim(params.user.password))) {
    structDelete(params.user, "password");
    structDelete(params.user, "passwordConfirmation");
}
```

### Rendering & Redirects

```cfm
renderView(action="new");                                    // Explicit view
provides("json"); renderWith(data=items, format="json");     // JSON API
redirectTo(action="show", key=resource.key());               // After save
redirectTo(controller="home", action="index");               // Cross-controller
```

---

## View Generation

### Index View (List)

```cfm
<cfparam name="resources">
<cfoutput>
#contentFor(pageTitle="Resources")#

<h1>Resources</h1>
#linkTo(text="New Resource", action="new", class="btn btn-primary")#

<cfif resources.recordCount>
    <cfloop query="resources">
        <div>
            <h2>#linkTo(text=resources.title, action="show", key=resources.id)#</h2>
            <p>#left(resources.description, 200)#...</p>
            <span>#dateFormat(resources.createdAt, "mmm dd, yyyy")#</span>
        </div>
    </cfloop>
    #paginationLinks(prependToLink="page=")#
<cfelse>
    <p>No resources found.</p>
</cfif>
</cfoutput>
```

### Show View (Detail)

Use `<cfparam name="resource">`, display properties directly, use `#dateFormat()#` for dates, `#linkTo()#` for edit/back, `#buttonTo(method="delete", confirm="Are you sure?")#` for delete.

### Form View (New/Edit)

Key patterns for form views:

```cfm
<cfparam name="resource">
<cfoutput>

<!--- Dynamic form target: route+key for update, action for create --->
<cfif resource.isNew()>
    #startFormTag(action="create", method="post")#
<cfelse>
    #startFormTag(route="resource", key=resource.id, method="patch")#
</cfif>

    <!--- Text field with inline error display --->
    <div class="form-group">
        <label>Title *</label>
        #textField(objectName="resource", property="title", label=false, class="form-control")#
        <cfif resource.hasErrors("title")>
            <cfset titleErr = resource.allErrors("title")>
            <span class="error">#isArray(titleErr) ? titleErr[1] : titleErr#</span>
        </cfif>
    </div>

    <!--- Email (use textField with type=) --->
    #textField(objectName="resource", property="email", type="email", label=false)#

    <!--- Select from query --->
    #select(objectName="resource", property="categoryId",
        options=model("Category").findAll(), valueField="id", textField="name",
        includeBlank="-- Select --", label=false)#

    <!--- Checkbox --->
    <label>#checkBox(objectName="resource", property="active", label=false)# Active</label>

    #submitTag(value=resource.isNew() ? "Create" : "Update", class="btn btn-primary")#
    #linkTo(text="Cancel", action="index", class="btn")#
#endFormTag()#
</cfoutput>
```

### Form Helper Reference

```cfm
// Text inputs (use type= for email/password/number/url)
#textField(objectName="obj", property="name", class="form-control")#
#textField(objectName="obj", property="email", type="email")#
#textField(objectName="obj", property="password", type="password")#

// Textarea
#textArea(objectName="obj", property="content", rows=10)#

// Select
#select(objectName="obj", property="status", options="draft,published,archived")#
#select(objectName="obj", property="categoryId", options=categories,
    valueField="id", textField="name", includeBlank="-- Select --")#

// Checkbox / Radio
#checkBox(objectName="obj", property="active")#
#radioButton(objectName="obj", property="role", tagValue="admin")#

// Date/Time
#dateSelect(objectName="obj", property="eventDate")#
#timeSelect(objectName="obj", property="eventTime")#
```

### allErrors() Return Type

allErrors() can return string OR array depending on context. Always handle both:

```cfm
<cfif resource.hasErrors("email")>
    <cfset emailErr = resource.allErrors("email")>
    <span class="error">#isArray(emailErr) ? emailErr[1] : emailErr#</span>
</cfif>
```

### Layout Essentials

Layouts must include: `#csrfMetaTags()#` in head, flash message display, `#includeContent()#` for body, `#styleSheetLinkTag()#` and `#javaScriptIncludeTag()#` for assets. Use `#contentFor("pageTitle")#` for dynamic titles. Display flashes with `<cfif flashKeyExists("success")>#flash("success")#</cfif>`.

---

## Migration Generation

### Location

Migrations go in: `app/migrator/migrations/` (NOT `db/migrate/`)

### Create Table Template

All migrations: extend `wheels.migrator.Migration`, wrap in `transaction` with try/catch, rollback on error, commit on success.

```cfm
component extends="wheels.migrator.Migration" {
    function up() {
        transaction {
            try {
                t = createTable(name="posts");
                t.string(columnNames="title", allowNull=false, limit=200);
                t.text(columnNames="content", allowNull=false);
                t.integer(columnNames="userId", allowNull=false);
                t.boolean(columnNames="published", default=false);
                t.timestamps();
                t.create();

                addIndex(table="posts", columnNames="userId");
            } catch (any e) { local.exception = e; }

            if (StructKeyExists(local, "exception")) {
                transaction action="rollback";
                Throw(errorCode="1", detail=local.exception.detail,
                    message=local.exception.message, type="any");
            } else { transaction action="commit"; }
        }
    }

    function down() { dropTable("posts"); }
}
```

### Column Types Reference

```cfm
t.string(columnNames="name", limit=255, allowNull=false, default="");
t.text(columnNames="description", allowNull=true);
t.integer(columnNames="count", default=0);
t.biginteger(columnNames="largeNumber");
t.float(columnNames="rating", default=0.0);
t.decimal(columnNames="price", precision=10, scale=2);
t.boolean(columnNames="active", default=true);
t.date(columnNames="birthDate");
t.datetime(columnNames="publishedAt", allowNull=true);
t.time(columnNames="startTime");
t.binary(columnNames="fileData");
t.timestamps();  // Creates createdAt, updatedAt, AND deletedAt
```

### Alter Table

```cfm
addColumn(table="posts", columnType="string", columnName="metaDescription", limit=300, allowNull=true);
changeColumn(table="posts", columnName="title", columnType="string", limit=255);
renameColumn(table="posts", oldColumnName="summary", newColumnName="excerpt");
removeColumn(table="posts", columnName="oldField");
addIndex(table="posts", columnNames="metaDescription");
```

### Foreign Keys

```cfm
addForeignKey(table="posts", referenceTable="users", column="userId",
    referenceColumn="id", onDelete="cascade");
```

For self-referential tables (e.g., follows), use explicit `keyName=` to avoid duplicate constraint names: `keyName="FK_follows_follower"` and `keyName="FK_follows_following"`.

### Join Table Pattern

```cfm
t = createTable(name="likes");
t.integer(columnNames="userId", allowNull=false);
t.integer(columnNames="tweetId", allowNull=false);
t.datetime(columnNames="createdAt", allowNull=false);
t.create();

// Composite unique index FIRST (covers single-column queries on first column)
addIndex(table="likes", columnNames="userId,tweetId", unique=true);
addIndex(table="likes", columnNames="tweetId");
```

### Data Seeding (Database-Agnostic)

Always use CFML date functions, never SQL-specific functions:

```cfm
var now = Now();
var weekAgo = DateAdd("d", -7, now);
var fmt = "TIMESTAMP '#DateFormat(weekAgo, 'yyyy-mm-dd')# #TimeFormat(weekAgo, 'HH:mm:ss')#'";

execute("INSERT INTO posts (title, slug, createdAt, updatedAt)
    VALUES ('First Post', 'first-post', #fmt#, #fmt#)");
```

### Development Workflow

When iterating on migrations during development:
```bash
wheels dbmigrate reset    # Clean slate (drops all tables)
wheels dbmigrate latest   # Run all migrations fresh
```

Never use `reset` in production. Use `wheels dbmigrate latest` only.

---

## Route Configuration

### File Location: `/config/routes.cfm`

### Basic Structure

```cfm
<cfscript>
mapper()
    // Resources first
    .resources("posts")
    .resources("users")

    // Custom routes
    .get(name="login", pattern="login", to="sessions##new")
    .post(name="authenticate", pattern="login", to="sessions##create")
    .delete(name="logout", pattern="logout", to="sessions##delete")

    // Root
    .root(to="home##index")

    // Wildcard LAST
    .wildcard()
.end();
</cfscript>
```

### Route Ordering

1. `.resources()` declarations
2. Custom named routes (.get, .post, .patch, .delete)
3. `.root()` route
4. `.wildcard()` — always last

### Resources

`.resources("posts")` creates 7 routes: GET /posts (index), GET /posts/new (new), POST /posts (create), GET /posts/[key] (show), GET /posts/[key]/edit (edit), PATCH /posts/[key] (update), DELETE /posts/[key] (delete).

```cfm
.resources("posts")                              // All 7 CRUD routes
.resources(name="comments", only="index,show")   // Limited actions
.resources(name="photos", except="delete")       // Exclude actions
```

### Constraints, Namespaces, API Scoping

```cfm
// Constraints
.get(name="post", pattern="posts/[key]", to="posts##show", constraints={key="[0-9]+"})

// Admin namespace: /admin/users -> admin.Users.index()
.namespace("admin")
    .resources("users")
.endNamespace()

// API scoping: /api/v1/posts -> api.v1.Posts.index()
.scope(path="api/v1", module="api.v1")
    .resources("posts")
.endScope()
```

### Route Helpers

```cfm
redirectTo(route="post", key=1);                             // Controller
#linkTo(route="post", key=post.id, text=post.title)#         // View link
#urlFor(route="post", key=1)#                                // URL string
#startFormTag(route="post", key=post.id, method="patch")#    // Form
```

### No Rails-Style Nested Resources

Wheels does not support closure-based nesting. Declare resources separately:

```cfm
.resources("posts")
.resources("comments")
```

---

## Pre-Generation Checklist

Before generating any Wheels component, verify:

- [ ] Does a migration exist for the database table?
- [ ] Is the migration in `app/migrator/migrations/` (not `db/migrate/`)?
- [ ] Does the model have `setPrimaryKey("id")` in config()?
- [ ] Are ALL association/validation calls using consistent named params?
- [ ] Do validations use `properties=` (plural)?
- [ ] Do callbacks use `structKeyExists()` before property access?
- [ ] Do views use `<cfloop query="">` (not array loops)?
- [ ] Do forms use `startFormTag()` (not raw `<form>`)?
- [ ] Do update forms use `route=` with `key=` (not `action="update"`)?
- [ ] Are date values in migrations using CFML functions (not SQL-specific)?

## Post-Generation Checklist

After generating code, validate:

- [ ] No mixed positional/named arguments in any function call
- [ ] No `emailField()`, `passwordField()`, `numberField()` in views
- [ ] No `ArrayLen()` on query results
- [ ] No database-specific SQL functions in migrations
- [ ] All filter methods are `private`
- [ ] Controller filters cover ALL actions that use loaded data
- [ ] Flash messages provide user feedback on create/update/delete
- [ ] Redirects follow POST/PUT/DELETE actions (PRG pattern)
- [ ] Model can be instantiated: `model("Name").new()` without error
