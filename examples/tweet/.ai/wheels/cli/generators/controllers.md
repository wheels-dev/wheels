# Controller Generation

## Description
Generate controller files with standard CRUD actions and proper REST structure using Wheels CLI commands.

## Key Points
- Use `wheels g controller` to generate controller files
- Specify actions to include in controller
- Automatic REST action structure
- Creates controller in `/app/controllers/` directory
- Generates corresponding view templates

## Code Sample
```bash
# Basic controller with standard REST actions
wheels g controller Users index,show,new,create,edit,update,delete

# Controller with custom actions
wheels g controller Posts index,show,new,create,edit,update,delete,publish,archive

# API-only controller
wheels g controller Api::Users index,show,create,update,delete

# Generated file: /app/controllers/Users.cfc
component extends="Controller" {
    function config() {
        // Parameter verification
        verifies(params="key", paramsTypes="integer", only="show,edit,update,delete");

        // Content types
        provides("html");
    }

    function index() {
        users = model("User").findAll();
    }

    function show() {
        user = model("User").findByKey(params.key);
    }

    function new() {
        user = model("User").new();
    }

    function create() {
        user = model("User").new(params.user);

        if (user.save()) {
            redirectTo(route="user", key=user.id, success="User created!");
        } else {
            renderView(action="new");
        }
    }

    function edit() {
        user = model("User").findByKey(params.key);
    }

    function update() {
        user = model("User").findByKey(params.key);

        if (user.update(params.user)) {
            redirectTo(route="user", key=user.id, success="User updated!");
        } else {
            renderView(action="edit");
        }
    }

    function delete() {
        user = model("User").findByKey(params.key);
        user.delete();
        redirectTo(route="users", success="User deleted!");
    }
}
```

## Usage
1. Run `wheels g controller ControllerName action1,action2,action3`
2. Use plural controller names (Users, Posts, Products)
3. Standard REST actions: index, show, new, create, edit, update, delete
4. Edit generated file to customize logic
5. Add filters, validations, and custom methods

## Related
- [MVC Controllers](../../core-concepts/mvc-architecture/controllers.md)
- [Routing Resources](../../core-concepts/routing/resources.md)
- [View Generation](./views.md)

## Important Notes
- Controller names should be plural (Users, not User)
- Generates basic CRUD structure - customize for your needs
- Creates corresponding view templates automatically
- Includes parameter verification and error handling
- Add authentication and authorization as needed