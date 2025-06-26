# wheels routes

Display all defined routes in your Wheels application with filtering and format options.

## Synopsis

```bash
wheels routes [name=<filter>] [format=<format>]
```

## Description

The `routes` command displays all routes defined in your application's `config/routes.cfm` file. It provides a clear overview of your application's URL structure, showing which controllers and actions handle each route.

## Options

### name
- **Type**: String
- **Default**: (none)
- **Description**: Filter routes by name or pattern. Case-insensitive partial matching.

### format
- **Type**: String
- **Default**: table
- **Options**: table, json
- **Description**: Output format for the route information.

## Examples

### Basic Usage

Display all routes in table format:
```bash
wheels routes
```

Output:
```
Application Routes:

Name                Method    Pattern                 Controller          Action
--------------------------------------------------------------------------------
users_index         GET       /users                  users               index
users_new           GET       /users/new              users               new
users_create        POST      /users                  users               create
users_show          GET       /users/[key]            users               show
users_edit          GET       /users/[key]/edit       users               edit
users_update        PUT,PATCH /users/[key]            users               update
users_delete        DELETE    /users/[key]            users               delete
root                GET       /                       main                index

Total routes: 8
```

### Filter Routes

Filter routes by name:
```bash
wheels routes name=user
```

Filter routes containing "admin":
```bash
wheels routes name=admin
```

### JSON Output

Get routes in JSON format for parsing:
```bash
wheels routes format=json
```

Output:
```json
[
  {
    "name": "users_index",
    "methods": "GET",
    "pattern": "/users",
    "controller": "users",
    "action": "index"
  },
  {
    "name": "users_show",
    "methods": "GET",
    "pattern": "/users/[key]",
    "controller": "users",
    "action": "show"
  }
]
```

### Combined Options

Filter and format together:
```bash
wheels routes name=admin format=json
```

## Route Information

The command displays the following information for each route:

- **Name**: The route's name (used for link generation)
- **Method**: HTTP method(s) (GET, POST, PUT, PATCH, DELETE)
- **Pattern**: URL pattern with placeholders (e.g., [key])
- **Controller**: The controller that handles the route
- **Action**: The action method within the controller

## Understanding Route Patterns

Wheels uses special placeholders in route patterns:

- `[key]` - Matches numeric IDs (e.g., /users/123)
- `:param` - Matches named parameters (e.g., :slug)
- `*` - Wildcard matching

## Limitations

The current implementation extracts routes by parsing the routes.cfm file. It recognizes:

- Resource routes (`resources()`)
- Named routes (`get()`, `post()`, etc. with name parameter)
- Root route (`root()`)

For complete route information, the routes.cfm file would need to be executed in the application context.

## Use Cases

### 1. Debugging Routing Issues
```bash
# Check if a route exists
wheels routes name=products

# Verify API routes
wheels routes name=api
```

### 2. Documentation
```bash
# Export routes for API documentation
wheels routes format=json > routes.json
```

### 3. Development Reference
```bash
# Quick lookup during development
wheels routes name=user
```

## Related Commands

- [`wheels routes:match`](routes-match.md) - Find which route matches a URL
- [`wheels generate route`](../generate/route.md) - Generate new routes
- [`wheels info`](../core/info.md) - General application information

## Tips

- Route names are used with link helpers like `linkTo(route="users_show", key=user.id)`
- RESTful resources automatically generate 7 standard routes
- Custom routes can be added before or after resource definitions
- Routes are matched in the order they are defined

## Common Issues

### No Routes Found
If no routes are displayed:
1. Ensure you're in a Wheels application directory
2. Check that `config/routes.cfm` exists
3. Verify the routes file has proper syntax

### Missing Routes
If expected routes are missing:
1. Check route definition order in routes.cfm
2. Ensure resources are properly defined
3. Look for conditional route definitions