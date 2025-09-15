# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with the application structure in a Wheels application.

## Overview

The `/app` directory is the heart of your Wheels application, containing all the core application logic organized according to the Model-View-Controller (MVC) architectural pattern. This directory structure enforces separation of concerns, maintainability, and follows Rails-inspired conventions that make Wheels applications predictable and easy to navigate. Every file in the app directory serves a specific purpose in the request lifecycle and application architecture.

## Directory Structure and Purpose

### MVC Architecture Foundation
```
app/
├── controllers/         (Controllers - Handle requests and coordinate responses)
│   └── Controller.cfc  (Base controller with shared functionality)
├── models/             (Models - Data and business logic)
│   └── Model.cfc      (Base model with ORM functionality)
├── views/             (Views - Presentation layer and templates)
│   └── layout.cfm     (Default application layout)
├── events/            (Application lifecycle event handlers)
│   └── onapplicationstart.cfc
├── global/            (Globally accessible functions)
│   └── functions.cfm
├── migrator/          (Database migration system)
│   └── migrations/    (Individual migration files)
├── mailers/           (Email components and templates)
├── jobs/              (Background job processing)
├── lib/               (Custom libraries and utilities)
├── plugins/           (Third-party and custom plugins)
└── snippets/          (Code generation templates)
```

## Core MVC Components

### Controllers (`/app/controllers/`)

Controllers are the traffic directors of your application, handling incoming HTTP requests, orchestrating data retrieval from models, and determining which views to render. Every controller extends the base `Controller.cfc` and uses actions (methods) to handle specific requests.

**Base Controller Structure:**
```cfm
// /app/controllers/Controller.cfc
component extends="wheels.Controller" {
    
    // Shared functionality for all controllers
    function config() {
        // Global filters, verification, and configuration
    }
    
}
```

**Example Application Controller:**
```cfm
// /app/controllers/Users.cfc
component extends="Controller" {

    function config() {
        // Controller-specific configuration
        verifies(except="index,new,create", params="key", paramsTypes="integer", handler="objectNotFound");
        filters(through="authenticate", except="login,logout");
        provides("html,json");
    }

    // GET /users
    function index() {
        users = model("User").findAll(order="createdat DESC");
    }

    // GET /users/12 
    function show() {
        user = model("User").findByKey(params.key);
    }

    // GET /users/new
    function new() {
        user = model("User").new();
    }

    // POST /users
    function create() {
        user = model("User").new(params.user);
        if (user.save()) {
            redirectTo(route="user", key=user.id, success="User created successfully!");
        } else {
            renderView(action="new");
        }
    }

    // GET /users/12/edit
    function edit() {
        user = model("User").findByKey(params.key);
    }

    // PUT /users/12
    function update() {
        user = model("User").findByKey(params.key);
        if (user.update(params.user)) {
            redirectTo(route="user", key=user.id, success="User updated successfully!");
        } else {
            renderView(action="edit");
        }
    }

    // DELETE /users/12
    function delete() {
        user = model("User").findByKey(params.key);
        user.delete();
        redirectTo(route="users", success="User deleted successfully!");
    }

    private function objectNotFound() {
        renderView(controller="errors", action="notFound");
    }

    private function authenticate() {
        if (!session.authenticated) {
            redirectTo(controller="sessions", action="new");
        }
    }
}
```

**API Controller Example:**
```cfm
// /app/controllers/api/Users.cfc
component extends="wheels.Controller" {

    function config() {
        provides("json");
        filters(through="setJsonResponse,authenticate");
    }

    function index() {
        users = model("User").findAll();
        renderWith(data={users=users});
    }

    function show() {
        user = model("User").findByKey(params.key);
        
        if (IsObject(user)) {
            renderWith(data={user=user});
        } else {
            renderWith(data={error="User not found"}, status=404);
        }
    }

    function create() {
        user = model("User").new(params.user);
        
        if (user.save()) {
            renderWith(data={user=user}, status=201);
        } else {
            renderWith(data={error="Validation failed", errors=user.allErrors()}, status=422);
        }
    }

    private function setJsonResponse() {
        params.format = "json";
    }

    private function authenticate() {
        if (!IsAuthenticated()) {
            renderWith(data={error="Authentication required"}, status=401);
        }
    }
}
```

### Models (`/app/models/`)

Models represent your application's data and business logic, providing an ActiveRecord-style ORM interface to your database. Each model typically corresponds to a database table and handles data validation, relationships, and business rules.

**Base Model Structure:**
```cfm
// /app/models/Model.cfc
component extends="wheels.Model" {
    
    // Shared model functionality
    function config() {
        // Global validations, callbacks, and configuration
    }
    
}
```

**Example Application Model:**
```cfm
// /app/models/User.cfc
component extends="Model" {

    function config() {
        // Associations
        hasMany(name="orders", dependent="delete");
        hasMany(name="comments", dependent="nullify");
        belongsTo(name="role");

        // Validations
        validatesPresenceOf(properties="firstname,lastname,email");
        validatesUniquenessOf(property="email", message="Email address is already taken");
        validatesFormatOf(property="email", regEx="^[\w\.-]+@[\w\.-]+\.\w+$", message="Please enter a valid email address");
        validatesLengthOf(property="password", minimum=6, when="onCreate");

        // Callbacks
        beforeValidation("normalizeEmail");
        beforeSave("hashPassword");
        afterCreate("sendWelcomeEmail");

        // Custom finder methods (Wheels doesn't have scope() - use custom finder methods instead)
    }

    // Custom finder methods
    function findByEmail(required string email) {
        return findOne(where="email = '#arguments.email#'");
    }
    
    function findActive() {
        return findAll(where="active = 1");
    }
    
    function findRecent(numeric limit = 10) {
        return findAll(order="createdat DESC", limit=arguments.limit);
    }

    function authenticate(required string email, required string password) {
        local.user = findByEmail(arguments.email);
        
        if (IsObject(local.user) && local.user.checkPassword(arguments.password)) {
            return local.user;
        }
        
        return false;
    }

    // Instance methods
    function fullName() {
        return trim("#firstname# #lastname#");
    }

    function checkPassword(required string password) {
        return Hash(arguments.password, "SHA-256") == this.hashedPassword;
    }

    function isAdmin() {
        return (IsObject(role) && role.name == "administrator");
    }

    // Callbacks
    private function normalizeEmail() {
        if (StructKeyExists(this, "email")) {
            this.email = Trim(LCase(this.email));
        }
    }

    private function hashPassword() {
        if (StructKeyExists(this, "password") && Len(this.password)) {
            this.hashedPassword = Hash(this.password, "SHA-256");
            // Remove plain text password
            StructDelete(this, "password");
        }
    }

    private function sendWelcomeEmail() {
        application.mailService.sendWelcomeEmail(this);
    }
}
```

**Complex Model with Advanced Features:**
```cfm
// /app/models/Order.cfc
component extends="Model" {

    function config() {
        // Associations
        belongsTo(name="user");
        hasMany(name="orderItems");
        hasMany(name="products", through="orderItems");

        // Validations
        validatesPresenceOf(properties="user,status,total");
        validatesInclusionOf(property="status", list="pending,processing,shipped,delivered,cancelled");
        validatesNumericalityOf(property="total", greaterThan=0);

        // Callbacks
        beforeValidation("calculateTotal");
        afterSave("updateInventory");

        // Custom finder methods (Wheels doesn't have scope() - use custom finder methods instead)
    }

    // Custom finder methods
    function findPending() {
        return findAll(where="status = 'pending'");
    }
    
    function findCompleted() {
        return findAll(where="status = 'delivered'");
    }
    
    function findThisMonth() {
        local.startOfMonth = CreateDate(Year(Now()), Month(Now()), 1);
        return findAll(where="createdat >= '#local.startOfMonth#'");
    }

    // Business logic methods
    function addProduct(required product, required numeric quantity) {
        local.orderItem = model("OrderItem").new({
            order = this,
            product = arguments.product,
            quantity = arguments.quantity,
            price = arguments.product.price
        });
        
        if (local.orderItem.save()) {
            calculateTotal();
            save();
            return true;
        }
        
        return false;
    }

    function canBeCancelled() {
        return ListFindNoCase("pending,processing", status);
    }

    function cancel(string reason = "") {
        if (canBeCancelled()) {
            update(status="cancelled", cancelledAt=Now(), cancelReason=arguments.reason);
            return true;
        }
        
        return false;
    }

    // Private methods
    private function calculateTotal() {
        local.total = 0;
        
        for (local.item in orderItems()) {
            local.total += (local.item.quantity * local.item.price);
        }
        
        this.total = local.total;
    }

    private function updateInventory() {
        if (status == "delivered" && !hasChanged("status")) {
            // Reduce inventory for each product
            for (local.item in orderItems()) {
                local.item.product.reduceInventory(local.item.quantity);
            }
        }
    }
}
```

### Views (`/app/views/`)

Views handle the presentation layer of your application, typically generating HTML output but also supporting other formats like JSON, XML, and CSV. Views are organized by controller names and use CFML with Wheels helper functions.

**Layout Structure:**
```cfm
<!-- /app/views/layout.cfm -->
<cfoutput>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    #csrfMetaTags()#
    <title>#contentFor("title", "MyApp")#</title>
    
    #styleSheetLinkTag("application")#
    #javaScriptIncludeTag("application")#
    
    #contentFor("head")#
</head>
<body>
    <nav class="navbar">
        <div class="container">
            #linkTo(route="root", text="MyApp", class="navbar-brand")#
            <ul class="nav">
                <li>#linkTo(route="users", text="Users")#</li>
                <li>#linkTo(route="orders", text="Orders")#</li>
            </ul>
        </div>
    </nav>
    
    <main class="container">
        #flashMessages()#
        #includeContent()#
    </main>
    
    <footer>
        #contentFor("footer")#
    </footer>
</body>
</html>
</cfoutput>
```

**Controller-Specific Views:**
```cfm
<!-- /app/views/users/index.cfm -->
<cfparam name="users">
<cfoutput>

#contentFor("title", "Users")#

<div class="page-header">
    <h1>Users</h1>
    <div class="actions">
        #linkTo(route="newUser", text="New User", class="btn btn-primary")#
    </div>
</div>

<cfif users.recordCount>
    <table class="table">
        <thead>
            <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Role</th>
                <th>Created</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            <cfloop query="users">
                <tr>
                    <td>
                        #linkTo(route="user", key=users.id, text="#users.firstname# #users.lastname#")#
                    </td>
                    <td>#users.email#</td>
                    <td>
                        <cfif Len(users.roleName)>
                            <span class="badge">#users.roleName#</span>
                        </cfif>
                    </td>
                    <td>#dateTimeFormat(users.createdat, "mm/dd/yyyy")#</td>
                    <td>
                        #linkTo(route="editUser", key=users.id, text="Edit", class="btn btn-sm btn-secondary")#
                        #buttonTo(route="user", method="delete", key=users.id, text="Delete", 
                                 class="btn btn-sm btn-danger", confirm="Are you sure?")#
                    </td>
                </tr>
            </cfloop>
        </tbody>
    </table>
<cfelse>
    <div class="empty-state">
        <h3>No users found</h3>
        <p>Get started by creating your first user.</p>
        #linkTo(route="newUser", text="Create User", class="btn btn-primary")#
    </div>
</cfif>

</cfoutput>
```

**Form Views:**
```cfm
<!-- /app/views/users/_form.cfm -->
<cfparam name="user">
<cfparam name="buttonText" default="Save User">
<cfoutput>

#errorMessagesFor("user")#

<div class="form-group">
    #label(objectName="user", property="firstname", text="First Name")#
    #textField(objectName="user", property="firstname", class="form-control")#
    #errorMessageOn(objectName="user", property="firstname")#
</div>

<div class="form-group">
    #label(objectName="user", property="lastname", text="Last Name")#
    #textField(objectName="user", property="lastname", class="form-control")#
    #errorMessageOn(objectName="user", property="lastname")#
</div>

<div class="form-group">
    #label(objectName="user", property="email", text="Email Address")#
    #emailField(objectName="user", property="email", class="form-control")#
    #errorMessageOn(objectName="user", property="email")#
</div>

<div class="form-group">
    #label(objectName="user", property="roleId", text="Role")#
    #select(objectName="user", property="roleId", 
            options=model("Role").findAll(), 
            textField="name", valueField="id",
            includeBlank="Select a role...",
            class="form-control")#
    #errorMessageOn(objectName="user", property="roleId")#
</div>

<cfif user.isNew()>
    <div class="form-group">
        #label(objectName="user", property="password", text="Password")#
        #passwordField(objectName="user", property="password", class="form-control")#
        #errorMessageOn(objectName="user", property="password")#
    </div>
</cfif>

<div class="form-actions">
    #submitTag(value=buttonText, class="btn btn-primary")#
    #linkTo(route="users", text="Cancel", class="btn btn-secondary")#
</div>

</cfoutput>
```

**JSON API Views:**
```cfm
<!-- /app/views/users/show.json.cfm -->
<cfparam name="user">
<cfoutput>
{
    "user": {
        "id": #user.id#,
        "firstname": "#JSStringFormat(user.firstname)#",
        "lastname": "#JSStringFormat(user.lastname)#", 
        "email": "#JSStringFormat(user.email)#",
        "role": <cfif IsObject(user.role)>"#JSStringFormat(user.role.name)#"<cfelse>null</cfif>,
        "createdat": "#dateFormat(user.createdat, 'yyyy-mm-dd')#T#timeFormat(user.createdat, 'HH:mm:ss')#Z",
        "updatedat": "#dateFormat(user.updatedat, 'yyyy-mm-dd')#T#timeFormat(user.updatedat, 'HH:mm:ss')#Z"
    }
}
</cfoutput>
```

## Request Lifecycle and URL Mapping

### URL Structure and Routing

Wheels follows a predictable URL structure that maps directly to your application structure:

**Basic URL Pattern:**
```
http://localhost:8080/[controller]/[action]/[key]
```

**URL Mapping Examples:**
- `/users` → `Users.cfc` controller, `index()` action
- `/users/show/12` → `Users.cfc` controller, `show()` action, `params.key = 12`
- `/users/new` → `Users.cfc` controller, `new()` action
- `/site-map/search-engines` → `SiteMap.cfc` controller, `searchEngines()` action

**Request Flow:**
1. **Route Resolution**: Wheels matches the incoming URL to a route pattern
2. **Controller Instantiation**: Creates an instance of the appropriate controller
3. **Filter Execution**: Runs any before filters defined for the action
4. **Action Execution**: Calls the specified action method
5. **View Rendering**: Renders the corresponding view (unless redirected or explicitly rendered)
6. **Response**: Sends the final output to the browser

### Naming Conventions

**Controllers:**
- File names: `PascalCase` (e.g., `Users.cfc`, `SiteMap.cfc`)
- URL mapping: Hyphenated lowercase (e.g., `/users`, `/site-map`)

**Actions:**
- Method names: `camelCase` (e.g., `index()`, `searchEngines()`)
- URL mapping: Hyphenated lowercase (e.g., `/index`, `/search-engines`)

**Views:**
- Directory names: Lowercase controller name (e.g., `/users`, `/sitemap`)
- File names: Lowercase action name (e.g., `index.cfm`, `searchengines.cfm`)

**Models:**
- File names: `PascalCase` singular (e.g., `User.cfc`, `OrderItem.cfc`)
- Table names: Lowercase plural (e.g., `users`, `orderitems`)
- Database columns: Lowercase (e.g., `first_name`, `created_at`)

## Advanced Application Patterns

### Service Layer Integration

```cfm
// /app/lib/UserService.cfc
component {

    function init() {
        return this;
    }

    function createUser(required struct userData) {
        local.user = model("User").new(arguments.userData);
        
        transaction {
            if (local.user.save()) {
                // Send welcome email
                mailService.sendWelcomeEmail(local.user);
                
                // Log the creation
                auditService.logUserCreation(local.user);
                
                // Update statistics
                statsService.incrementUserCount();
                
                return local.user;
            } else {
                transaction action="rollback";
                return false;
            }
        }
    }

    function authenticateUser(required string email, required string password) {
        local.user = model("User").findByEmail(arguments.email);
        
        if (IsObject(local.user) && local.user.authenticate(arguments.password)) {
            // Update last login
            local.user.update(lastLoginAt=Now());
            
            // Log successful login
            auditService.logUserLogin(local.user);
            
            return local.user;
        }
        
        // Log failed login attempt
        auditService.logFailedLogin(arguments.email);
        
        return false;
    }

    private property mailService inject="MailService";
    private property auditService inject="AuditService"; 
    private property statsService inject="StatsService";
}
```

### Controller Organization Patterns

**Nested Controllers:**
```cfm
// /app/controllers/admin/Users.cfc
component extends="admin.Base" {

    function config() {
        super.config();
        filters(through="requireAdmin");
    }

    function index() {
        users = model("User").findAll(include="role", order="createdat DESC");
    }

    private function requireAdmin() {
        if (!session.user.isAdmin()) {
            redirectTo(controller="errors", action="forbidden");
        }
    }
}

// /app/controllers/admin/Base.cfc  
component extends="Controller" {

    function config() {
        filters(through="requireAuthentication");
        provides("html");
    }

    private function requireAuthentication() {
        if (!session.authenticated) {
            redirectTo(controller="sessions", action="new");
        }
    }
}
```

### Model Concerns and Mixins

```cfm
// /app/lib/concerns/Trackable.cfc
component {

    function addTrackingToModel(required model) {
        arguments.model.property(name="createdat", type="datetime");
        arguments.model.property(name="updatedat", type="datetime");
        
        arguments.model.beforeCreate("setCreatedAt");
        arguments.model.beforeUpdate("setUpdatedAt");
    }

    function setCreatedAt() {
        if (!StructKeyExists(this, "createdat")) {
            this.createdat = Now();
        }
    }

    function setUpdatedAt() {
        this.updatedat = Now();
    }
}

// Usage in model
// /app/models/User.cfc
component extends="Model" {

    function config() {
        // Add tracking functionality
        application.trackable.addTrackingToModel(this);
        
        // Other model configuration...
    }
}
```

## Content Negotiation and API Support

### Multi-Format Support

```cfm
// Controller supporting multiple formats
component extends="Controller" {

    function config() {
        provides("html,json,xml,csv");
    }

    function index() {
        users = model("User").findAll();
        
        // Response varies by requested format
        renderWith(data={users=users});
    }

    function show() {
        user = model("User").findByKey(params.key);
        
        if (IsObject(user)) {
            renderWith(data={user=user});
        } else {
            renderWith(data={error="User not found"}, status=404);
        }
    }
}
```

**Format-Specific Views:**
- `show.cfm` - HTML view
- `show.json.cfm` - JSON view  
- `show.xml.cfm` - XML view
- `show.csv.cfm` - CSV view

### RESTful API Patterns

```cfm
// /app/controllers/api/v1/Base.cfc
component extends="wheels.Controller" {

    function config() {
        provides("json");
        filters(through="setJsonResponse,authenticate,setHeaders");
    }

    private function setJsonResponse() {
        params.format = "json";
    }

    private function authenticate() {
        local.token = getHttpRequestData().headers["Authorization"];
        
        if (!IsValid("string", local.token) || !validateApiToken(local.token)) {
            renderWith(data={error="Invalid or missing API token"}, status=401);
        }
    }

    private function setHeaders() {
        setHttpHeader(name="Content-Type", value="application/json");
        setHttpHeader(name="API-Version", value="1.0");
    }

    private function validateApiToken(required string token) {
        // Token validation logic
        return true;
    }
}
```

## Security Best Practices

### Input Validation and Sanitization

```cfm
// Controller with comprehensive validation
component extends="Controller" {

    function config() {
        // Verify required parameters
        verifies(only="show,edit,update,delete", params="key", paramsTypes="integer");
        
        // CSRF protection
        protectFromForgery();
    }

    function create() {
        // Validate and sanitize input
        params.user = sanitizeUserInput(params.user);
        
        local.user = model("User").new(params.user);
        
        if (local.user.save()) {
            redirectTo(route="user", key=local.user.id, success="User created successfully!");
        } else {
            renderView(action="new");
        }
    }

    private function sanitizeUserInput(required struct userData) {
        // Remove potentially harmful content
        for (local.key in arguments.userData) {
            if (IsSimpleValue(arguments.userData[local.key])) {
                arguments.userData[local.key] = HTMLEditFormat(Trim(arguments.userData[local.key]));
            }
        }
        
        return arguments.userData;
    }
}
```

### Authentication and Authorization

```cfm
// /app/lib/AuthenticationService.cfc
component {

    function authenticateUser(required string email, required string password) {
        local.user = model("User").findByEmail(arguments.email);
        
        if (IsObject(local.user) && local.user.authenticate(arguments.password)) {
            session.userid = local.user.id;
            session.authenticated = true;
            session.user = local.user;
            
            return local.user;
        }
        
        return false;
    }

    function requireAuthentication() {
        if (!isAuthenticated()) {
            redirectTo(controller="sessions", action="new");
        }
    }

    function requireRole(required string role) {
        if (!isAuthenticated() || !session.user.hasRole(arguments.role)) {
            redirectTo(controller="errors", action="forbidden");
        }
    }

    function isAuthenticated() {
        return StructKeyExists(session, "authenticated") && session.authenticated;
    }

    function currentUser() {
        if (isAuthenticated()) {
            return session.user;
        }
        
        return "";
    }
}
```

## Testing Application Components

### Controller Testing

```cfm
// /tests/controllers/UsersTest.cfc
component extends="tests.Test" {

    function setup() {
        super.setup();
        user = model("User").create(firstname="John", lastname="Doe", email="john@example.com");
    }

    function testIndexAction() {
        params = {controller="users", action="index"};
        controller = controller("users", params);
        
        controller.index();
        
        assert("IsDefined('controller.users')");
        assert("controller.users.recordCount GT 0");
    }

    function testShowAction() {
        params = {controller="users", action="show", key=user.id};
        controller = controller("users", params);
        
        controller.show();
        
        assert("IsDefined('controller.user')");
        assert("controller.user.id EQ #user.id#");
    }

    function testCreateActionWithValidData() {
        params = {
            controller = "users",
            action = "create", 
            user = {
                firstname = "Jane",
                lastname = "Smith", 
                email = "jane@example.com"
            }
        };
        controller = controller("users", params);
        
        controller.create();
        
        assert("controller.$performedRender() EQ false");
        assert("controller.$performedRedirect()");
    }

    function teardown() {
        super.teardown();
        if (IsObject(user)) {
            user.delete();
        }
    }
}
```

### Model Testing

```cfm
// /tests/models/UserTest.cfc  
component extends="tests.Test" {

    function testUserValidation() {
        user = model("User").new();
        
        assert("!user.valid()");
        assert("ArrayLen(user.allErrors()) GT 0");
    }

    function testUserCreationWithValidData() {
        userData = {
            firstname = "John",
            lastname = "Doe",
            email = "john@example.com",
            password = "password123"
        };
        
        user = model("User").create(userData);
        
        assert("IsObject(user)");
        assert("user.valid()");
        assert("user.firstname EQ 'John'");
        assert("!StructKeyExists(user, 'password')"); // Password should be hashed and removed
    }

    function testUserAssociations() {
        user = model("User").findByKey(1);
        orders = user.orders();
        
        assert("IsQuery(orders) || IsArray(orders)");
    }
}
```

## Performance Optimization

### Caching Strategies

```cfm
// Controller with caching
component extends="Controller" {

    function config() {
        caches(action="index", time=15); // Cache for 15 minutes
    }

    function index() {
        // Expensive query cached automatically
        users = model("User").findAll(include="role,orders");
    }

    function dashboard() {
        // Manual caching for complex data
        cacheKey = "user_dashboard_#session.userid#";
        dashboardData = $cacheRead(cacheKey);
        
        if (!IsStruct(dashboardData)) {
            dashboardData = {
                recentOrders = model("Order").findAll(where="userid=#session.userid#", limit=5),
                totalSpent = model("Order").sumOf("total", where="userid=#session.userid#"),
                favoriteProducts = getFavoriteProducts(session.userid)
            };
            
            $cacheWrite(key=cacheKey, value=dashboardData, timeSpan=CreateTimeSpan(0,1,0,0));
        }
        
        // Set variables for view
        recentOrders = dashboardData.recentOrders;
        totalSpent = dashboardData.totalSpent;
        favoriteProducts = dashboardData.favoriteProducts;
    }

    private function getFavoriteProducts(required numeric userid) {
        // Complex query to determine favorite products
        return model("Product").findBySQL("
            SELECT p.*, COUNT(oi.id) as orderCount
            FROM products p
            INNER JOIN orderitems oi ON p.id = oi.productId  
            INNER JOIN orders o ON oi.orderId = o.id
            WHERE o.userid = ?
            GROUP BY p.id
            ORDER BY orderCount DESC
            LIMIT 10
        ", [arguments.userid]);
    }
}
```

### Database Query Optimization

```cfm
// Model with optimized queries
component extends="Model" {

    function config() {
        // Define relationships for eager loading
        hasMany(name="orders", dependent="delete");
        belongsTo(name="role");

        // Add database indexes via migrations
        // wheels generate migration AddIndexToUsersEmail --attributes="email:index"
    }

    function findActiveUsersWithOrders() {
        // Use includes to avoid N+1 queries
        return findAll(
            where = "active = 1",
            include = "role,orders",
            order = "createdat DESC"
        );
    }

    function findTopCustomers(numeric limit = 10) {
        // Use raw SQL for complex aggregations
        return findBySQL("
            SELECT u.*, 
                   COUNT(o.id) as orderCount,
                   SUM(o.total) as totalSpent
            FROM users u
            INNER JOIN orders o ON u.id = o.userid
            WHERE u.active = 1
            GROUP BY u.id
            ORDER BY totalSpent DESC
            LIMIT ?
        ", [arguments.limit]);
    }
}
```

## Error Handling and Debugging

### Application Error Handling

```cfm
// /app/controllers/Errors.cfc
component extends="Controller" {

    function config() {
        filters(through="setLayout");
    }

    function notFound() {
        // Handle 404 errors
        response.setStatus(404);
    }

    function serverError() {
        // Handle 500 errors  
        response.setStatus(500);
        
        // Log the error details
        if (StructKeyExists(params, "exception")) {
            WriteLog(
                file = "application",
                text = "Server Error: #params.exception.message# - #params.exception.detail#",
                type = "error"
            );
        }
    }

    function forbidden() {
        // Handle 403 errors
        response.setStatus(403);
    }

    private function setLayout() {
        renderView(layout="error");
    }
}
```

### Debug Information in Development

```cfm
// Development-only debugging helpers
component extends="Controller" {

    function config() {
        if (application.environment == "development") {
            filters(through="debugInfo", type="after");
        }
    }

    private function debugInfo() {
        if (application.environment == "development" && params.debug) {
            // Add debug information to response
            content = renderView();
            debugPanel = renderPartial(partial="shared/debugPanel", layout=false);
            
            renderText(content & debugPanel);
        }
    }
}
```

The `/app` directory serves as the foundation for your entire Wheels application, organizing code according to proven MVC patterns while providing flexibility for complex application requirements. Understanding this structure and following established conventions will make your applications more maintainable, testable, and easier for other developers to understand and contribute to.