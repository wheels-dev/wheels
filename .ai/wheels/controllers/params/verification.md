# Parameter Verification

## Description
Ensure required parameters exist and have correct types before controller actions execute to prevent errors and security issues.

## Key Points
- Use `verifies()` in controller's `config()` method
- Check parameter existence and types
- Specify which actions require verification
- Automatic error handling with helpful messages
- Prevents actions from running with invalid parameters

## Code Sample
```cfm
component extends="Controller" {
    function config() {
        // Basic parameter verification
        verifies(params="key", paramsTypes="integer", only="show,edit,update,delete");

        // Multiple parameters with types
        verifies(
            params="userId,postId",
            paramsTypes="integer,integer",
            only="addComment"
        );

        // Complex verification
        verifies(
            params="key,slug",
            paramsTypes="integer,string",
            only="showBySlug",
            handler="handleMissingParams"
        );

        // Required struct parameters
        verifies(
            params="user",
            paramsTypes="struct",
            only="create,update"
        );
    }

    function show() {
        // params.key guaranteed to be integer
        user = model("User").findByKey(params.key);
    }

    function addComment() {
        // Both params.userId and params.postId guaranteed to be integers
        post = model("Post").findByKey(params.postId);
        // ... rest of action
    }

    // Custom error handler
    private function handleMissingParams() {
        flashInsert(error="Invalid or missing parameters");
        redirectTo(action="index");
    }
}
```

## Usage
1. Add `verifies()` calls in controller's `config()` method
2. Specify required parameters with `params` argument
3. Define expected types with `paramsTypes` argument
4. Limit to specific actions with `only` or `except`
5. Optionally provide custom error handler

## Related
- [Before and After Filters](../filters/before-after.md)
- [Parameter Types](./types.md)
- [Security Best Practices](./security.md)

## Important Notes
- Verification runs before filters and actions
- Failed verification prevents action execution
- Supports types: integer, string, struct, array, boolean
- Use for all actions that depend on specific parameters
- Custom handlers allow for better error messages