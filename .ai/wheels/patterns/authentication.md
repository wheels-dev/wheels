# Authentication Patterns

## Description
Common patterns for implementing user authentication and session management in Wheels applications.

## Key Points
- Store user ID in session after successful login
- Use filters to protect controller actions
- Implement secure password handling
- Provide login/logout functionality
- Handle authentication state throughout application

## Code Sample
```cfm
// Sessions Controller - handles login/logout
component extends="Controller" {
    function config() {
        filters(through="redirectIfAuthenticated", only="new,create");
    }

    // Show login form
    function new() {
        user = model("User").new();
    }

    // Process login
    function create() {
        user = model("User").findOne(where="email = '#params.email#'");

        if (IsObject(user) && user.authenticate(params.password)) {
            session.userId = user.id;
            session.authenticated = true;

            flashInsert(success="Welcome back, #user.firstName#!");

            // Redirect to return URL or dashboard
            returnUrl = params.returnUrl ?: urlFor(action="dashboard", controller="home");
            redirectTo(url=returnUrl);
        } else {
            flashInsert(error="Invalid email or password");
            renderView(action="new");
        }
    }

    // Process logout
    function delete() {
        StructClear(session);
        flashInsert(success="You have been logged out");
        redirectTo(controller="sessions", action="new");
    }

    private function redirectIfAuthenticated() {
        if (isLoggedIn()) {
            redirectTo(controller="home", action="dashboard");
        }
    }
}

// User Model with authentication
component extends="Model" {
    function config() {
        validatesPresenceOf("email,password");
        validatesUniquenessOf(property="email");

        beforeSave("hashPassword");
    }

    // Check if provided password matches stored hash
    function authenticate(required string password) {
        return BCrypt.checkpw(arguments.password, this.passwordHash);
    }

    // Hash password before saving
    private function hashPassword() {
        if (hasChanged("password") && Len(this.password)) {
            this.passwordHash = BCrypt.hashpw(this.password, BCrypt.gensalt());
            // Clear plain text password
            this.password = "";
        }
    }
}

// Application Controller - base class with authentication helpers
component extends="Controller" {
    // Get current user
    function currentUser() {
        if (!StructKeyExists(variables, "currentUser") && isLoggedIn()) {
            variables.currentUser = model("User").findByKey(session.userId);
        }
        return StructKeyExists(variables, "currentUser") ? variables.currentUser : false;
    }

    // Check if user is logged in
    function isLoggedIn() {
        return StructKeyExists(session, "userId") &&
               StructKeyExists(session, "authenticated") &&
               session.authenticated;
    }

    // Authentication filter
    private function authenticate() {
        if (!isLoggedIn()) {
            flashInsert(error="Please login to continue");
            redirectTo(controller="sessions", action="new", returnUrl=cgi.request_url);
        }
    }

    // Authorization filter
    private function requireAdmin() {
        user = currentUser();
        if (!IsObject(user) || !user.isAdmin()) {
            flashInsert(error="Administrator privileges required");
            redirectTo(controller="home", action="index");
        }
    }
}
```

## Usage
1. Create sessions controller for login/logout
2. Store user ID in session after authentication
3. Use password hashing (BCrypt) for security
4. Create authentication filters for protected actions
5. Provide helper methods for current user access

## Related
- [Controller Filters](../controllers/filters/authentication.md)
- [Authorization Patterns](./authorization.md)
- [User Management](../database/validations/presence.md)

## Important Notes
- Never store passwords in plain text
- Use BCrypt or similar for password hashing
- Clear sessions completely on logout
- Store minimal data in sessions
- Handle authentication state consistently