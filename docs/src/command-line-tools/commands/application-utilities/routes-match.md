# wheels routes:match

Find which route matches a given URL and HTTP method.

## Synopsis

```bash
wheels routes:match <url> [method=<method>]
```

## Description

The `routes:match` command helps you debug routing issues by showing which route would handle a specific URL. It displays the matching route's pattern, controller, action, and any extracted parameters.

## Arguments

### url
- **Type**: String
- **Required**: Yes
- **Description**: The URL path to match (with or without leading slash)

## Options

### method
- **Type**: String
- **Default**: GET
- **Options**: GET, POST, PUT, PATCH, DELETE
- **Description**: HTTP method to use for matching

## Examples

### Basic URL Matching

Find route for a simple URL:
```bash
wheels routes:match /users
```

Output:
```
Matching route found!

URL: /users [GET]

Route Name: users_index
Pattern: /users
Controller: users
Action: index
```

### URL with Parameters

Match URL with ID parameter:
```bash
wheels routes:match /users/123
```

Output:
```
Matching route found!

URL: /users/123 [GET]

Route Name: users_show
Pattern: /users/[key]
Controller: users
Action: show

Parameters:
  key: 123
```

### Different HTTP Methods

Match POST request:
```bash
wheels routes:match /users method=POST
```

Match DELETE request:
```bash
wheels routes:match /users/123 method=DELETE
```

### Complex URLs

Match nested resource:
```bash
wheels routes:match /users/123/posts/456/edit
```

Match URL with query string (ignored in routing):
```bash
wheels routes:match "/products?category=electronics"
```

## Understanding the Output

The command provides:

1. **Matching Status**: Whether a route was found
2. **URL & Method**: The URL and HTTP method being tested
3. **Route Details**:
   - Name: Used for link generation
   - Pattern: The route pattern that matched
   - Controller: Which controller handles the request
   - Action: Which action method will be called
4. **Parameters**: Extracted URL parameters (like IDs)
5. **Other Matches**: Alternative routes that could match

## Route Matching Rules

Wheels matches routes based on:

1. **Method**: HTTP method must match (or be "*" for any)
2. **Pattern**: URL must match the pattern
3. **Order**: First matching route wins

Pattern matching:
- `[key]` matches numeric values
- `:param` matches named parameters
- Exact strings must match exactly

## Use Cases

### 1. Debugging 404 Errors
```bash
# Check why a URL returns 404
wheels routes:match /api/v1/users
```

### 2. Verifying RESTful Routes
```bash
# Verify all CRUD operations
wheels routes:match /products method=GET      # index
wheels routes:match /products/new method=GET  # new
wheels routes:match /products method=POST     # create
wheels routes:match /products/123 method=GET  # show
wheels routes:match /products/123/edit method=GET  # edit
wheels routes:match /products/123 method=PUT  # update
wheels routes:match /products/123 method=DELETE # delete
```

### 3. API Endpoint Testing
```bash
# Test API endpoints
wheels routes:match /api/users method=POST
wheels routes:match /api/auth/login method=POST
```

## Troubleshooting

### No Routes Match

If no routes match:
```
No routes match URL: /unknown [GET]
```

Solutions:
1. Check spelling of the URL
2. Verify the HTTP method
3. Use `wheels routes` to see all available routes
4. Check if routes are conditionally defined

### Multiple Matches

When multiple routes could match:
```
Other possible matches:
  - /products/* -> products#catch_all
  - /* -> main#not_found
```

This helps identify route conflicts or fallback routes.

### Parameter Extraction

The command shows extracted parameters:
```
Parameters:
  key: 123
  slug: my-product
```

This helps verify that parameters are correctly extracted from URLs.

## Related Commands

- [`wheels routes`](routes.md) - Display all routes
- [`wheels generate route`](../generate/route.md) - Generate new routes
- [`wheels server`](../server/server.md) - Start server to test routes

## Tips

- Always include the HTTP method for accurate matching
- Use quotes for URLs with special characters: `wheels routes:match "/search?q=test"`
- The leading slash is optional: `users` and `/users` are equivalent
- Remember that routes are matched in the order they're defined

## Common Patterns

### RESTful Resources
```bash
wheels routes:match /articles         # GET -> index
wheels routes:match /articles/123     # GET -> show
wheels routes:match /articles/new     # GET -> new
wheels routes:match /articles/123/edit # GET -> edit
```

### Nested Resources
```bash
wheels routes:match /blogs/45/posts/123
wheels routes:match /users/1/settings
```

### API Versioning
```bash
wheels routes:match /api/v1/users
wheels routes:match /api/v2/users
```