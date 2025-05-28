# wheels generate route

Generate route definitions for your application.

## Synopsis

```bash
wheels generate route [pattern] [options]
wheels g route [pattern] [options]
```

## Description

The `wheels generate route` command helps you create route definitions in your Wheels application. It can generate individual routes, RESTful resources, nested routes, and complex routing patterns while maintaining proper syntax and organization in your routes file.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `pattern` | Route pattern or resource name | Required |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--to` | Controller#action destination | Required for non-resource |
| `--method` | HTTP method (GET, POST, PUT, DELETE) | `GET` |
| `--name` | Route name for URL helpers | Auto-generated |
| `--resource` | Generate RESTful resource routes | `false` |
| `--api` | Generate API routes (no new/edit) | `false` |
| `--nested` | Parent resource for nesting | |
| `--only` | Only include specific actions | All actions |
| `--except` | Exclude specific actions | |
| `--namespace` | Wrap in namespace | |
| `--constraints` | Add route constraints | |
| `--force` | Add even if route exists | `false` |
| `--help` | Show help information | |

## Examples

### Basic Route
```bash
wheels generate route "/about" --to="pages#about" --name="about"
```

Generates in `/config/routes.cfm`:
```cfm
<cfset get(name="about", pattern="/about", to="pages##about")>
```

### POST Route
```bash
wheels generate route "/contact" --to="contact#send" --method="POST" --name="sendContact"
```

Generates:
```cfm
<cfset post(name="sendContact", pattern="/contact", to="contact##send")>
```

### RESTful Resource
```bash
wheels generate route products --resource
```

Generates:
```cfm
<cfset resources("products")>
```

This creates all standard routes:
- GET /products (index)
- GET /products/new (new)
- POST /products (create)
- GET /products/:key (show)
- GET /products/:key/edit (edit)
- PUT/PATCH /products/:key (update)
- DELETE /products/:key (delete)

### API Resource
```bash
wheels generate route products --api
```

Generates:
```cfm
<cfset resources(name="products", nested=false, except="new,edit")>
```

### Nested Resources
```bash
wheels generate route comments --resource --nested="posts"
```

Generates:
```cfm
<cfset resources("posts")>
    <cfset resources("comments")>
</cfset>
```

Creates routes like:
- /posts/:postKey/comments
- /posts/:postKey/comments/:key

## Route Patterns

### Dynamic Segments
```bash
wheels generate route "/users/[key]/profile" --to="users#profile" --name="userProfile"
```

Generates:
```cfm
<cfset get(name="userProfile", pattern="/users/[key]/profile", to="users##profile")>
```

### Optional Segments
```bash
wheels generate route "/blog/[year]/[month?]/[day?]" --to="blog#archive" --name="blogArchive"
```

Generates:
```cfm
<cfset get(name="blogArchive", pattern="/blog/[year]/[month?]/[day?]", to="blog##archive")>
```

### Wildcards
```bash
wheels generate route "/docs/*" --to="documentation#show" --name="docs"
```

Generates:
```cfm
<cfset get(name="docs", pattern="/docs/*", to="documentation##show")>
```

## Advanced Routing

### With Constraints
```bash
wheels generate route "/users/[id]" --to="users#show" --constraints="id=[0-9]+"
```

Generates:
```cfm
<cfset get(pattern="/users/[id]", to="users##show", constraints={id="[0-9]+"})>
```

### Namespace Routes
```bash
wheels generate route users --resource --namespace="admin"
```

Generates:
```cfm
<cfset namespace("admin")>
    <cfset resources("users")>
</cfset>
```

### Module Routes
```bash
wheels generate route dashboard --resource --namespace="admin" --module="backend"
```

Generates:
```cfm
<cfset module("backend")>
    <cfset namespace("admin")>
        <cfset resources("dashboard")>
    </cfset>
</cfset>
```

### Shallow Nesting
```bash
wheels generate route comments --resource --nested="posts" --shallow
```

Generates:
```cfm
<cfset resources("posts")>
    <cfset resources(name="comments", shallow=true)>
</cfset>
```

## Custom Actions

### Member Routes
```bash
wheels generate route "products/[key]/activate" --to="products#activate" --method="PUT" --member
```

Generates:
```cfm
<cfset resources("products")>
    <cfset put(pattern="[key]/activate", to="products##activate", on="member")>
</cfset>
```

### Collection Routes
```bash
wheels generate route "products/search" --to="products#search" --collection
```

Generates:
```cfm
<cfset resources("products")>
    <cfset get(pattern="search", to="products##search", on="collection")>
</cfset>
```

## Route Files Organization

### Main Routes File
`/config/routes.cfm`:
```cfm
<!--- 
    Routes Configuration
    Define your application routes below
--->

<!--- Public routes --->
<cfset get(name="home", pattern="/", to="main##index")>
<cfset get(name="about", pattern="/about", to="pages##about")>
<cfset get(name="contact", pattern="/contact", to="pages##contact")>
<cfset post(name="sendContact", pattern="/contact", to="pages##sendContact")>

<!--- Authentication --->
<cfset get(name="login", pattern="/login", to="sessions##new")>
<cfset post(name="createSession", pattern="/login", to="sessions##create")>
<cfset delete(name="logout", pattern="/logout", to="sessions##delete")>

<!--- Resources --->
<cfset resources("products")>
<cfset resources("categories")>

<!--- API routes --->
<cfset namespace("api")>
    <cfset namespace("v1")>
        <cfset resources(name="products", nested=false, except="new,edit")>
        <cfset resources(name="users", nested=false, except="new,edit")>
    </cfset>
</cfset>

<!--- Admin routes --->
<cfset namespace("admin")>
    <cfset get(name="adminDashboard", pattern="/", to="dashboard##index")>
    <cfset resources("users")>
    <cfset resources("products")>
    <cfset resources("orders")>
</cfset>

<!--- Catch-all route --->
<cfset get(pattern="*", to="errors##notFound")>
```

## Route Helpers

Generated routes create URL helpers:

### Basic Helpers
```cfm
<!--- For route: get(name="about", pattern="/about", to="pages##about") --->
#linkTo(route="about", text="About Us")#
#urlFor(route="about")#
#redirectTo(route="about")#
```

### Resource Helpers
```cfm
<!--- For route: resources("products") --->
#linkTo(route="products", text="All Products")# <!--- /products --->
#linkTo(route="product", key=product.id, text="View")# <!--- /products/123 --->
#linkTo(route="newProduct", text="Add Product")# <!--- /products/new --->
#linkTo(route="editProduct", key=product.id, text="Edit")# <!--- /products/123/edit --->

#urlFor(route="products")# <!--- /products --->
#urlFor(route="product", key=123)# <!--- /products/123 --->
```

### Nested Resource Helpers
```cfm
<!--- For nested resources("posts") > resources("comments") --->
#linkTo(route="postComments", postKey=post.id, text="Comments")# <!--- /posts/1/comments --->
#linkTo(route="postComment", postKey=post.id, key=comment.id, text="View")# <!--- /posts/1/comments/5 --->
```

## Route Constraints

### Pattern Constraints
```bash
wheels generate route "/posts/[year]/[month]" --to="posts#archive" --constraints="year=[0-9]{4},month=[0-9]{2}"
```

### Format Constraints
```bash
wheels generate route "/api/users" --to="api/users#index" --format="json"
```

Generates:
```cfm
<cfset get(pattern="/api/users", to="api/users##index", format="json")>
```

## Route Testing

### Generate Route Tests
```bash
wheels generate route products --resource
wheels generate test routes products
```

### Route Test Example
```cfc
component extends="wheels.Test" {
    
    function test_products_routes() {
        // Test index route
        result = $resolve(path="/products", method="GET");
        assert(result.controller == "products");
        assert(result.action == "index");
        
        // Test show route
        result = $resolve(path="/products/123", method="GET");
        assert(result.controller == "products");
        assert(result.action == "show");
        assert(result.params.key == "123");
        
        // Test create route
        result = $resolve(path="/products", method="POST");
        assert(result.controller == "products");
        assert(result.action == "create");
    }
    
}
```

## Route Debugging

### List All Routes
```bash
wheels routes list
```

### Test Specific Route
```bash
wheels routes test "/products/123" --method=GET
```

Output:
```
Route resolved:
  Controller: products
  Action: show
  Params: {key: "123"}
  Name: product
```

## Best Practices

1. **Order matters**: Place specific routes before generic ones
2. **Use RESTful routes**: Prefer `resources()` over individual routes
3. **Name your routes**: Always provide names for URL helpers
4. **Group related routes**: Use namespaces and modules
5. **Add constraints**: Validate dynamic segments
6. **Document complex routes**: Add comments explaining purpose
7. **Test route resolution**: Ensure routes work as expected

## Common Patterns

### Authentication Required
```cfm
<!--- Public routes --->
<cfset get(name="home", pattern="/", to="main##index")>

<!--- Authenticated routes --->
<cfset namespace(name="authenticated", path="/app")>
    <!--- All routes here require authentication --->
    <cfset resources("projects")>
    <cfset resources("tasks")>
</cfset>
```

### API Versioning
```cfm
<cfset namespace("api")>
    <cfset namespace(name="v1", path="/v1")>
        <cfset resources(name="users", except="new,edit")>
    </cfset>
    <cfset namespace(name="v2", path="/v2")>
        <cfset resources(name="users", except="new,edit")>
    </cfset>
</cfset>
```

### Subdomain Routing
```cfm
<cfset subdomain("api")>
    <cfset resources("products")>
</cfset>

<cfset subdomain("admin")>
    <cfset resources("users")>
</cfset>
```

### Redirect Routes
```cfm
<cfset get(pattern="/old-about", redirect="/about")>
<cfset get(pattern="/products/category/[name]", redirect="/categories/[name]")>
```

## Performance Considerations

1. **Route caching**: Routes are cached in production
2. **Minimize regex**: Complex patterns slow routing
3. **Avoid wildcards**: Be specific when possible
4. **Order efficiently**: Most-used routes first

## Troubleshooting

### Route Not Found
- Check route order
- Verify HTTP method
- Test with `wheels routes test`
- Check for typos in pattern

### Naming Conflicts
- Ensure unique route names
- Check for duplicate patterns
- Use namespaces to avoid conflicts

### Parameter Issues
- Verify parameter names match
- Check constraint patterns
- Test with various inputs

## See Also

- [wheels scaffold](scaffold.md) - Generate complete CRUD with routes
- [wheels generate controller](controller.md) - Generate controllers
- [wheels generate resource](resource.md) - Generate RESTful resources
- [wheels generate api-resource](api-resource.md) - Generate API resources