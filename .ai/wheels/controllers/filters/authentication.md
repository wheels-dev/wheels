# Authentication Filters

## Description
Common pattern for implementing user authentication checks before allowing access to protected controller actions.

## Key Points
- Use before filters to check authentication status
- Redirect unauthenticated users to login
- Store authentication state in session
- Apply to specific actions or exclude public actions
- Provide helpful flash messages

## Code Sample
```cfm
component extends="Controller" {
    function config() {
        // Authenticate all actions except public ones
        filters(through="authenticate", except="index,show");

        // More granular authentication
        filters(through="requireLogin", only="edit,update,delete,create,new");
    }

    // Public actions don't require authentication
    function index() {
        posts = model("Post").findAll(where="published = 1");
    }

    function show() {
        post = model("Post").findByKey(params.key);
    }

    // Protected actions require authentication
    function new() {
        post = model("Post").new();
    }

    function create() {
        post = model("Post").create(params.post);
        // ... rest of action
    }

    // Private filter methods
    private function authenticate() {
        if (!StructKeyExists(session, "userId") || !session.userId) {
            flashInsert(error="Please login to continue");
            redirectTo(controller="sessions", action="new");
        }
    }

    private function requireLogin() {
        if (!isLoggedIn()) {
            flashInsert(error="You must be logged in to access this page");
            redirectTo(controller="sessions", action="new", returnUrl=cgi.request_url);
        }
    }

    // Helper method
    private function isLoggedIn() {
        return StructKeyExists(session, "userId") && IsNumeric(session.userId);
    }
}
```

## Usage
1. Create private authentication filter methods
2. Check session for user ID or authentication token
3. Redirect to login page if not authenticated
4. Use `except` for public actions or `only` for protected ones
5. Store return URL for post-login redirects

## Related
- [Before and After Filters](./before-after.md)
- [Authorization Filters](./authorization.md)
- [Session Management](../../patterns/authentication.md)

## Important Notes
- Always use private methods for filters
- Check both existence and validity of session data
- Provide clear error messages for users
- Store return URLs for better user experience
- Consider token-based authentication for APIs