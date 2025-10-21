# Rendering Views

## Description
Control which view templates are rendered and how data is passed to views from controller actions.

## Key Points
- Views render automatically based on controller/action names
- Use `renderView()` to override default view selection
- Set instance variables to pass data to views
- Support for different layouts and partial rendering
- Can render views from other controllers/actions

## Code Sample
```cfm
component extends="Controller" {
    function index() {
        // Data available in view as 'users'
        users = model("User").findAll(order="lastName");
        // Renders /app/views/users/index.cfm automatically
    }

    function show() {
        user = model("User").findByKey(params.key);

        if (!IsObject(user)) {
            // Render different view for error
            flashInsert(error="User not found");
            renderView(action="notFound");
        }
        // Otherwise renders /app/views/users/show.cfm
    }

    function create() {
        user = model("User").new(params.user);

        if (user.save()) {
            redirectTo(route="user", key=user.id, success="User created!");
        } else {
            // Render the form again with errors
            renderView(action="new");
        }
    }

    function dashboard() {
        stats = getUserStats();
        recentActivity = getRecentActivity();

        // Render custom view with custom layout
        renderView(template="admin/dashboard", layout="admin");
    }

    function export() {
        data = model("User").findAll();

        // Render without layout for API/export
        renderView(template="users/csv", layout=false);
    }
}
```

## Usage
1. Set instance variables in controller actions for view access
2. Use `renderView()` to override default view selection
3. Specify `action`, `template`, or `controller` for custom views
4. Use `layout` parameter to change or disable layouts
5. Variables set in controller available in view templates

## Related
- [View Layouts](../../views/layouts/structure.md)
- [View Helpers](../../views/helpers/forms.md)
- [Redirecting](./redirects.md)

## Important Notes
- Instance variables automatically available in views
- Default view: `/app/views/[controller]/[action].cfm`
- Use `renderView()` for custom templates or error handling
- Set `layout=false` for partial content or API responses
- Can render views from other controllers with full paths