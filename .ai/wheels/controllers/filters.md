# Controller Filters

## Description
Wheels filters allow you to run code before or after actions without explicit calls, enabling cross-cutting concerns like authentication, logging, data loading, and authorization.

## Filter Basics

Filters allow you to run code before or after actions without explicit calls in each method. They're perfect for:
- Authentication and authorization
- Loading common data
- Logging and auditing
- Setting up request context
- Cleaning up after requests

## Basic Filter Setup

### Before Filters (Default)
```cfm
function config() {
    super.config();

    // Before filters (default type)
    filters(through="authenticate");
    filters(through="loadUser", only="show,edit,update,delete");
    filters(through="adminRequired", except="index,show");
}

/**
 * Authentication filter
 */
private function authenticate() {
    if (!StructKeyExists(session, "userId")) {
        redirectTo(controller="sessions", action="new", error="Please log in");
    }
}

/**
 * Load user for actions that need it
 */
private function loadUser() {
    user = model("User").findByKey(session.userId);
    if (!IsObject(user)) {
        redirectTo(controller="sessions", action="new", error="Invalid session");
    }
}

/**
 * Admin access required
 */
private function adminRequired() {
    if (!user.isAdmin()) {
        redirectTo(back=true, error="Access denied");
    }
}
```

### After Filters
```cfm
function config() {
    super.config();

    // After filters
    filters(through="logAccess", type="after");
    filters(through="cleanup", type="after", only="create,update,delete");
}

private function logAccess() {
    writeLog(
        file="access",
        text="User #session.userId ?: 'anonymous'# accessed #params.controller#.#params.action#"
    );
}

private function cleanup() {
    // Clean up temporary files, clear caches, etc.
    clearTempFiles();
    clearObjectCache();
}
```

## Filter Targeting

### Including/Excluding Actions
```cfm
function config() {
    super.config();

    // Run on all actions
    filters(through="authenticate");

    // Run only on specific actions
    filters(through="loadProduct", only="show,edit,update,delete");

    // Run on all except specified actions
    filters(through="requireAuth", except="index,show");

    // Multiple actions with different filters
    filters(through="loadCategories", only="new,edit");
    filters(through="checkPermissions", only="edit,update,delete");
}
```

### Multiple Filters in Order
```cfm
function config() {
    super.config();

    // Filters run in the order they're defined
    filters(through="authenticate");        // First
    filters(through="loadUser");           // Second
    filters(through="checkPermissions");   // Third
    filters(through="loadCommonData");     // Fourth
}
```

## Filter Arguments

### Static Arguments
```cfm
function config() {
    super.config();

    // Static arguments passed to filter
    filters(through="checkPermission", permission="read");
    filters(through="requireRole", role="admin");
}

private function checkPermission(permission = "read") {
    if (!user.hasPermission(arguments.permission)) {
        redirectTo(back=true, error="Insufficient permissions");
    }
}

private function requireRole(role = "user") {
    if (!user.hasRole(arguments.role)) {
        redirectTo(back=true, error="Access denied");
    }
}
```

### Dynamic Arguments
```cfm
function config() {
    super.config();

    // Dynamic arguments (evaluated at runtime)
    filters(through="checkOwnership", userId="##session.userId##");
    filters(through="logActivity", controller="##params.controller##");
}

private function checkOwnership(userId = "") {
    if (arguments.userId != resource.userId) {
        redirectTo(back=true, error="You can only modify your own records");
    }
}
```

### Arguments as Struct
```cfm
function config() {
    super.config();

    // Arguments as struct
    filterArgs = {permission: "admin", strict: true, logAccess: true};
    filters(through="authorize", authorizeArguments=filterArgs);
}

private function authorize(permission = "read", strict = false, logAccess = false) {
    if (!user.hasPermission(arguments.permission)) {
        if (arguments.logAccess) {
            logUnauthorizedAccess();
        }

        if (arguments.strict) {
            throw(type="AccessDenied", message="Access denied");
        } else {
            redirectTo(back=true, error="Access denied");
        }
    }
}
```

## Authentication Filters

### Basic Authentication
```cfm
function config() {
    super.config();

    // Require authentication for all actions except public ones
    filters(through="requireAuth", except="index,show");
}

private function requireAuth() {
    if (!StructKeyExists(session, "userId") || !IsNumeric(session.userId)) {
        session.returnTo = cgi.request_url;
        redirectTo(controller="sessions", action="new", error="Please log in to continue");
    }
}
```

### User Loading
```cfm
function config() {
    super.config();

    filters(through="loadCurrentUser");
}

private function loadCurrentUser() {
    if (StructKeyExists(session, "userId")) {
        currentUser = model("User").findByKey(session.userId);
        if (!IsObject(currentUser)) {
            StructDelete(session, "userId");
            redirectTo(controller="sessions", action="new", error="Invalid session");
        }
    }
}
```

### Session Validation
```cfm
private function validateSession() {
    // Check session timeout
    if (StructKeyExists(session, "lastActivity")) {
        if (dateDiff("n", session.lastActivity, now()) > 30) {
            StructClear(session);
            redirectTo(controller="sessions", action="new", error="Session expired");
        }
    }

    // Update last activity
    session.lastActivity = now();
}
```

## Authorization Filters

### Role-Based Access
```cfm
function config() {
    super.config();

    filters(through="requireRole", role="admin", only="destroy,bulk");
    filters(through="requireRole", role="moderator", only="approve,reject");
}

private function requireRole(role = "user") {
    if (!currentUser.hasRole(arguments.role)) {
        redirectTo(back=true, error="You don't have permission to perform this action");
    }
}
```

### Permission-Based Access
```cfm
function config() {
    super.config();

    filters(through="requirePermission", permission="posts.create", only="new,create");
    filters(through="requirePermission", permission="posts.edit", only="edit,update");
    filters(through="requirePermission", permission="posts.delete", only="delete");
}

private function requirePermission(permission = "") {
    if (!currentUser.hasPermission(arguments.permission)) {
        logUnauthorizedAccess(arguments.permission);
        redirectTo(back=true, error="Access denied");
    }
}
```

### Resource Ownership
```cfm
function config() {
    super.config();

    filters(through="loadPost", only="show,edit,update,delete");
    filters(through="checkOwnership", only="edit,update,delete");
}

private function loadPost() {
    post = model("Post").findByKey(params.key);
    if (!IsObject(post)) {
        redirectTo(action="index", error="Post not found");
    }
}

private function checkOwnership() {
    if (post.authorId != currentUser.id && !currentUser.isAdmin()) {
        redirectTo(back=true, error="You can only modify your own posts");
    }
}
```

## Data Loading Filters

### Common Data Loading
```cfm
function config() {
    super.config();

    // Load data needed by multiple actions
    filters(through="loadCategories", only="new,edit");
    filters(through="loadAuthors", only="new,edit");
}

private function loadCategories() {
    categories = model("Category").findAll(order="name");
}

private function loadAuthors() {
    authors = model("User").findAll(
        where="isAuthor = 1",
        order="lastName, firstName"
    );
}
```

### Resource Loading
```cfm
function config() {
    super.config();

    filters(through="loadResource", only="show,edit,update,delete");
}

private function loadResource() {
    // Generic resource loading based on controller name
    resourceName = params.controller;
    if (right(resourceName, 1) == "s") {
        resourceName = left(resourceName, len(resourceName) - 1);
    }

    // Set resource in variables scope
    variables[resourceName] = model(resourceName).findByKey(params.key);

    if (!IsObject(variables[resourceName])) {
        redirectTo(action="index", error="#resourceName# not found");
    }
}
```

### Nested Resource Loading
```cfm
function config() {
    super.config();

    // For nested resources like /users/123/posts/456
    filters(through="loadUser", only="show,edit,update,delete");
    filters(through="loadPost", only="show,edit,update,delete");
}

private function loadUser() {
    if (StructKeyExists(params, "userId")) {
        user = model("User").findByKey(params.userId);
        if (!IsObject(user)) {
            redirectTo(controller="users", action="index", error="User not found");
        }
    }
}

private function loadPost() {
    if (StructKeyExists(params, "key") && IsObject(user)) {
        post = user.posts().findByKey(params.key);
        if (!IsObject(post)) {
            redirectTo(controller="users", action="show", key=user.id, error="Post not found");
        }
    }
}
```

## Logging and Auditing Filters

### Access Logging
```cfm
function config() {
    super.config();

    filters(through="logAccess", type="after");
}

private function logAccess() {
    local.logData = {
        userId = session.userId ?: 0,
        controller = params.controller,
        action = params.action,
        ip = cgi.remote_addr,
        userAgent = cgi.http_user_agent ?: "",
        timestamp = now()
    };

    writeLog(
        file="access",
        text=serializeJSON(local.logData)
    );
}
```

### Activity Auditing
```cfm
function config() {
    super.config();

    filters(through="auditActivity", type="after", only="create,update,delete");
}

private function auditActivity() {
    // Only audit successful operations (no redirects due to errors)
    if (!hasRedirected()) {
        model("AuditLog").create({
            userId = currentUser.id,
            action = params.action,
            resource = params.controller,
            resourceId = params.key ?: "",
            details = serializeJSON(params),
            timestamp = now()
        });
    }
}

private function hasRedirected() {
    return StructKeyExists(variables, "redirect");
}
```

## Performance and Caching Filters

### Response Time Monitoring
```cfm
function config() {
    super.config();

    filters(through="startTimer", type="before");
    filters(through="endTimer", type="after");
}

private function startTimer() {
    variables.startTime = getTickCount();
}

private function endTimer() {
    local.duration = getTickCount() - variables.startTime;

    if (local.duration > 5000) { // Log slow requests > 5 seconds
        writeLog(
            file="slow_requests",
            text="Slow request: #params.controller#.#params.action# took #local.duration#ms"
        );
    }

    // Add timing header for development
    if (application.environment == "development") {
        header name="X-Response-Time" value="#local.duration#ms";
    }
}
```

### Cache Headers
```cfm
function config() {
    super.config();

    filters(through="setCacheHeaders", only="index,show");
}

private function setCacheHeaders() {
    if (application.environment == "production") {
        // Cache public pages for 1 hour
        header name="Cache-Control" value="public, max-age=3600";
    } else {
        // No caching in development
        header name="Cache-Control" value="no-cache";
    }
}
```

## CORS and API Filters

### CORS Headers
```cfm
function config() {
    super.config();

    filters(through="corsHeaders", type="before");
}

private function corsHeaders() {
    header name="Access-Control-Allow-Origin" value="*";
    header name="Access-Control-Allow-Methods" value="GET,POST,PUT,DELETE,OPTIONS";
    header name="Access-Control-Allow-Headers" value="Content-Type,Authorization";

    // Handle preflight requests
    if (cgi.request_method == "OPTIONS") {
        renderNothing();
    }
}
```

### API Format Setting
```cfm
function config() {
    super.config();

    filters(through="setJsonFormat");
}

private function setJsonFormat() {
    params.format = "json";
}
```

## Error Handling in Filters

### Graceful Filter Errors
```cfm
private function authenticateWithErrorHandling() {
    try {
        if (!StructKeyExists(session, "userId")) {
            redirectTo(controller="sessions", action="new", error="Please log in");
        }

        // Validate user still exists
        currentUser = model("User").findByKey(session.userId);
        if (!IsObject(currentUser)) {
            StructDelete(session, "userId");
            redirectTo(controller="sessions", action="new", error="Invalid session");
        }

    } catch (any e) {
        // Log error but don't break the application
        writeLog(
            file="filter_errors",
            text="Authentication filter error: #e.message#"
        );

        // Redirect to safe page
        redirectTo(controller="home", action="index", error="Authentication error");
    }
}
```

### Filter Chain Debugging
```cfm
function config() {
    super.config();

    if (application.environment == "development") {
        filters(through="debugFilters", type="before");
    }
}

private function debugFilters() {
    writeOutput("<!-- Filter chain: #params.controller#.#params.action# at #now()# -->");
}
```

## Testing Filters

### Filter Testing
```cfm
// In test file
function testAuthenticationFilter() {
    // Test without session
    params = {controller: "products", action: "edit", key: 1};
    result = processAction(params);

    // Should redirect to login
    assert("IsRedirect()");
    assert("result.location CONTAINS 'sessions'");
}

function testAuthenticationFilterWithValidSession() {
    // Set up valid session
    session.userId = createTestUser().id;

    params = {controller: "products", action: "edit", key: 1};
    result = processAction(params);

    // Should proceed normally
    assert("!IsRedirect()");
}
```

## Advanced Filter Patterns

### Conditional Filters
```cfm
function config() {
    super.config();

    // Only apply filters based on conditions
    if (application.environment == "production") {
        filters(through="requireSSL");
    }

    if (application.features.auditingEnabled) {
        filters(through="auditActivity", type="after");
    }
}

private function requireSSL() {
    if (!cgi.https) {
        location(url="https://#cgi.server_name##cgi.script_name#?#cgi.query_string#");
    }
}
```

### Filter Inheritance
```cfm
// Base controller with common filters
component name="AdminController" extends="Controller" {

    function config() {
        super.config();

        filters(through="requireAuth");
        filters(through="requireAdmin");
        filters(through="loadAdminData");
    }

    private function requireAdmin() {
        if (!currentUser.isAdmin()) {
            redirectTo(controller="home", action="index", error="Admin access required");
        }
    }

}

// Inherits admin filters
component extends="AdminController" {

    function config() {
        super.config();

        // Additional filters for this controller
        filters(through="loadReports", only="reports,analytics");
    }

}
```

## Best Practices

### 1. Order Filters Correctly
```cfm
function config() {
    super.config();

    // Order matters - authentication before authorization
    filters(through="authenticate");      // Must come first
    filters(through="loadUser");         // Needs authentication
    filters(through="checkPermissions"); // Needs user loaded
    filters(through="loadCommonData");   // Last - depends on user context
}
```

### 2. Keep Filters Focused
```cfm
// Good - single responsibility
private function authenticate() {
    if (!isLoggedIn()) {
        redirectTo(controller="sessions", action="new");
    }
}

// Avoid - doing too much
private function authenticateAndLoadDataAndCheckPermissions() {
    // Too much responsibility in one filter
}
```

### 3. Handle Errors Gracefully
```cfm
private function loadUser() {
    try {
        currentUser = model("User").findByKey(session.userId);
        if (!IsObject(currentUser)) {
            StructDelete(session, "userId");
            redirectTo(controller="sessions", action="new", error="Invalid session");
        }
    } catch (any e) {
        writeLog(file="errors", text=e.message);
        redirectTo(controller="home", action="index", error="System error");
    }
}
```

### 4. Use Descriptive Filter Names
```cfm
// Good - clear purpose
filters(through="requireAuthentication");
filters(through="loadCurrentUser");
filters(through="checkResourceOwnership");

// Avoid - unclear purpose
filters(through="doStuff");
filters(through="check");
filters(through="filter1");
```

## Related Documentation
- [Controller Architecture](./architecture.md)
- [Controller Security](./security.md)
- [Controller Rendering](./rendering.md)
- [Authentication Patterns](../security/authentication.md)