# Authorization Filters

## Description
Implement role-based access control and permissions checking after authentication to restrict access based on user privileges.

## Key Points
- Run after authentication filters
- Check user roles and permissions
- Restrict access based on resource ownership
- Support admin, moderator, and custom roles
- Provide appropriate error messages

## Code Sample
```cfm
component extends="Controller" {
    function config() {
        // Authentication first, then authorization
        filters(through="authenticate");
        filters(through="requireAdmin", only="delete,destroy");
        filters(through="requireOwnership", only="edit,update");
        filters(through="requireModeratorOrOwner", only="moderate");
    }

    // Filter methods for different authorization levels
    private function requireAdmin() {
        if (!currentUser().isAdmin()) {
            flashInsert(error="Administrator privileges required");
            redirectTo(action="index");
        }
    }

    private function requireOwnership() {
        post = model("Post").findByKey(params.key);
        if (!IsObject(post) || post.userId != session.userId) {
            flashInsert(error="You can only edit your own posts");
            redirectTo(action="index");
        }
        // Store for use in action
        variables.post = post;
    }

    private function requireModeratorOrOwner() {
        user = currentUser();
        post = model("Post").findByKey(params.key);

        if (!user.isModerator() && post.userId != user.id) {
            flashInsert(error="Insufficient privileges");
            redirectTo(action="show", key=params.key);
        }
    }

    // Helper methods
    private function currentUser() {
        if (!StructKeyExists(variables, "currentUser")) {
            variables.currentUser = model("User").findByKey(session.userId);
        }
        return variables.currentUser;
    }

    private function authorize(requiredRole) {
        user = currentUser();
        if (!user.hasRole(requiredRole)) {
            flashInsert(error="You don't have permission to access this page");
            redirectTo(action="index");
        }
    }
}
```

## Usage
1. Define authorization filters after authentication filters
2. Check user roles, permissions, or ownership
3. Use helper methods to get current user
4. Store found resources in variables for action use
5. Provide specific error messages for different restrictions

## Related
- [Authentication Filters](./authentication.md)
- [Before and After Filters](./before-after.md)
- [User Roles Pattern](../../patterns/authentication.md)

## Important Notes
- Always run authorization after authentication
- Cache current user to avoid multiple database calls
- Check both resource existence and ownership
- Use descriptive error messages
- Consider using role-based or permission-based systems