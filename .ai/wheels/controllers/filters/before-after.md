# Before and After Filters

## Description
Filters run code before or after controller actions to avoid repetition and implement cross-cutting concerns.

## Key Points
- Define filters in controller's `config()` method
- Use `filters()` for before filters, `filters(through="method", type="after")` for after filters
- Filter methods should be private
- Support `only` and `except` to control which actions run filters
- Filters can redirect or abort action execution

## Code Sample
```cfm
component extends="Controller" {
    function config() {
        // Before filters (default type)
        filters(through="authenticate");
        filters(through="findUser", only="show,edit,update,delete");
        filters(through="requireAdmin", except="index,show");

        // After filters
        filters(through="logAccess", type="after");
        filters(through="cleanup", type="after", only="create,update,delete");
    }

    // Action methods
    function index() {
        users = model("User").findAll();
    }

    function show() {
        // user already found by findUser filter
    }

    // Private filter methods
    private function authenticate() {
        if (!session.authenticated) {
            flashInsert(error="Please login first");
            redirectTo(controller="sessions", action="new");
        }
    }

    private function findUser() {
        user = model("User").findByKey(params.key);
        if (!IsObject(user)) {
            flashInsert(error="User not found");
            redirectTo(action="index");
        }
    }
}
```

## Usage
1. Add `filters()` calls in controller's `config()` method
2. Create private methods for filter logic
3. Use `only="action1,action2"` to limit scope
4. Use `except="action1,action2"` to exclude actions
5. Use `type="after"` for after filters

## Related
- [Authentication Patterns](../authentication.md)
- [Authorization Patterns](../authorization.md)
- [Parameter Verification](../params/verification.md)

## Important Notes
- Filter methods must be private for security
- Filters run in order they're defined
- Before filters can prevent action execution
- Use filters for authentication, logging, setup
- Keep filter logic focused and reusable