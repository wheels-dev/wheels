# MVC Controllers

## Description
Controllers handle HTTP requests, coordinate with models, and render views in Wheels' MVC architecture.

## Key Points
- Extend `Controller.cfc` base class
- Located in `/app/controllers/` directory
- Use plural names (UsersController.cfc)
- Handle request parameters and user input
- Coordinate between models and views
- Implement filters for common functionality

## Code Sample
```cfm
// /app/controllers/Users.cfc
component extends="Controller" {
    function config() {
        // Filters for authentication/authorization
        filters(through="authenticate", except="index");
        filters(through="findUser", only="show,edit,update,delete");

        // Parameter verification
        verifies(except="index,new,create", params="key", paramsTypes="integer");

        // Content type support
        provides("html,json");
    }

    function index() {
        users = model("User").findAll(order="createdAt DESC");
    }

    function create() {
        user = model("User").new(params.user);

        if (user.save()) {
            redirectTo(route="user", key=user.id, success="User created!");
        } else {
            renderView(action="new");
        }
    }

    private function authenticate() {
        if (!session.authenticated) {
            redirectTo(controller="sessions", action="new");
        }
    }
}
```

## Usage
- Create `.cfc` files in `/app/controllers/`
- Use plural names matching route resources
- Define public methods for actions
- Use private methods for filters and helpers
- Set instance variables for views to access

## Related
- [Models](./models.md)
- [Views](./views.md)
- [Routing](../routing/basics.md)
- [Filters](../../controllers/filters/before-after.md)

## Important Notes
- Keep controllers thin - delegate to models
- Use filters for common functionality
- Verify parameters to prevent errors
- Handle both success and error cases