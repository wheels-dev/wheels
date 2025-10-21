# Redirects

## Description
Redirect users to different URLs after successful operations or when access control is required.

## Key Points
- Use `redirectTo()` method for all redirects
- Support for named routes, controller/action pairs, and URLs
- Include flash messages for user feedback
- Prevent double rendering with automatic action termination
- Support for return URLs and relative redirects

## Code Sample
```cfm
component extends="Controller" {
    function create() {
        user = model("User").new(params.user);

        if (user.save()) {
            // Redirect to show page with success message
            redirectTo(route="user", key=user.id, success="User created successfully!");
        } else {
            // Re-render form with errors (no redirect)
            renderView(action="new");
        }
    }

    function update() {
        user = model("User").findByKey(params.key);

        if (user.update(params.user)) {
            // Redirect back with flash message
            redirectTo(back=true, success="Profile updated!");
        } else {
            renderView(action="edit");
        }
    }

    function delete() {
        user = model("User").findByKey(params.key);
        user.delete();

        // Redirect to index with different message types
        redirectTo(action="index", success="User deleted", warning="Data permanently removed");
    }

    function login() {
        // Redirect to return URL or default location
        returnUrl = params.returnUrl ?: urlFor(action="dashboard");
        redirectTo(url=returnUrl, success="Welcome back!");
    }

    // Different redirect patterns
    function examples() {
        // Named route with parameters
        redirectTo(route="editUser", key=5);

        // Controller and action
        redirectTo(controller="posts", action="index");

        // External URL
        redirectTo(url="https://example.com");

        // Back to previous page
        redirectTo(back=true);

        // Relative redirect
        redirectTo(action="show", key=params.key);
    }
}
```

## Usage
1. Use `redirectTo()` after successful operations
2. Include flash messages: `success`, `error`, `warning`, `info`
3. Use named routes for maintainable URLs
4. Use `back=true` to return to previous page
5. Store return URLs for complex navigation flows

## Related
- [Rendering Views](./views.md)
- [Routing](../../core-concepts/routing/basics.md)
- [Flash Messages](../../views/helpers/forms.md)

## Important Notes
- Redirects automatically terminate action execution
- Don't call `renderView()` after `redirectTo()`
- Flash messages survive the redirect
- Use POST-redirect-GET pattern for form submissions
- Always redirect after successful data modifications