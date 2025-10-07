# wheels generate route

Generate route definitions for your Wheels application's `/config/routes.cfm` file.

## Synopsis

```bash
wheels generate route [objectname]
#can also be used as:
wheels g route [objectname]

# HTTP method routes
wheels generate route --get="pattern,controller##action"
wheels generate route --post="pattern,controller##action"
wheels generate route --put="pattern,controller##action"
wheels generate route --patch="pattern,controller##action"
wheels generate route --delete="pattern,controller##action"

# Root route
wheels generate route --root="controller##action"

# Resources route (explicit)
wheels generate route --resources=true [objectname]
```

## Description

The `wheels generate route` command helps you create route definitions in your Wheels application's `/config/routes.cfm` file. It supports individual HTTP method routes, RESTful resource routes, and root routes.

**IMPORTANT**: All HTTP method parameters must use the equals syntax: `--get="pattern,handler"` not `--get pattern,handler`

## Parameter Syntax

CommandBox supports multiple parameter formats:

- **Named parameters**: `name=value` (e.g., `objectname=products`, `get="pattern,handler"`)
- **Flag parameters**: `--flag` equals `flag=true` (e.g., `--resources` equals `resources=true`)
- **Flag with value**: `--flag=value` equals `flag=value` (e.g., `--get="pattern,handler"`)

**Note**: Flag syntax (`--flag`) avoids positional/named parameter conflicts and is recommended for boolean options.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `objectname` | The name of the resource for resources route | Optional (required for resources routes) |

## Options

| Option | Description | Example | Default |
|--------|-------------|---------|---------|
| `--get` | Create a GET route with pattern,handler format | `--get="products/sale,products##sale"` | |
| `--post` | Create a POST route with pattern,handler format | `--post="contact,contact##send"` | |
| `--put` | Create a PUT route with pattern,handler format | `--put="users/[key],users##update"` | |
| `--patch` | Create a PATCH route with pattern,handler format | `--patch="profiles,profiles##update"` | |
| `--delete` | Create a DELETE route with pattern,handler format | `--delete="sessions,sessions##destroy"` | |
| `--resources` | Create a resources route (use with objectname) | `--resources=true` | `false` |
| `--root` | Create a root route with handler | `--root="pages##home"` | |

## Examples

### Resources Route (default)
```bash
wheels generate route products
```

Generates in `/config/routes.cfm`:
```cfm
.resources("products")
```

This creates all standard RESTful routes:
- GET `/products` (index)
- GET `/products/new` (new)
- POST `/products` (create)
- GET `/products/[key]` (show)
- GET `/products/[key]/edit` (edit)
- PUT/PATCH `/products/[key]` (update)
- DELETE `/products/[key]` (delete)

### GET Route
```bash
wheels generate route --get="products/sale,products##sale"
```

Generates:
```cfm
.get(pattern="products/sale", to="products##sale")
```

### POST Route
```bash
wheels generate route --post="api/users,api.users##create"
```

Generates:
```cfm
.post(pattern="api/users", to="api.users##create")
```

### PUT Route
```bash
wheels generate route --put="users/[key]/activate,users##activate"
```

Generates:
```cfm
.put(pattern="users/[key]/activate", to="users##activate")
```

### DELETE Route
```bash
wheels generate route --delete="sessions,sessions##destroy"
```

Generates:
```cfm
.delete(pattern="sessions", to="sessions##destroy")
```

### Root Route
```bash
wheels generate route --root="pages##home"
```

Generates:
```cfm
.root(to="pages##home", method="get")
```

### Explicit Resources Route
```bash
wheels generate route --resources=true users
```

Generates:
```cfm
.resources("users")
```

## Route Patterns

### Dynamic Segments
Routes support dynamic segments using `[key]` notation:

```bash
wheels generate route --get="users/[key]/profile,users##profile"
```

Generates:
```cfm
.get(pattern="users/[key]/profile", to="users##profile")
```

The `[key]` parameter will be available as `params.key` in your controller.

### Custom Parameters
You can use any parameter name:

```bash
wheels generate route --get="posts/[year]/[month],posts##archive"
```

Generates:
```cfm
.get(pattern="posts/[year]/[month]", to="posts##archive")
```

Parameters will be available as `params.year` and `params.month` in your controller.

### Pattern Only Routes
If you omit the handler, the route will use standard controller/action mapping:

```bash
wheels generate route --get="products/search"
```

Generates:
```cfm
.get(pattern="products/search")
```

This will map to the `search` action in the `products` controller.

## Route File Integration

### Generated Routes Location
All routes are added to `/config/routes.cfm` at the CLI marker position:

```cfm
<cfscript>
mapper()
    .resources("products")        // Existing routes
    .get(pattern="about", to="pages#about")    // Existing routes

    // CLI-Appends-Here            // CLI adds new routes here

    .wildcard()                   // Wildcard should stay last
    .root(to="home#index")        // Root route
.end();
</cfscript>
```

### Route Order
The command automatically places new routes at the correct position before the wildcard route. Routes are processed in order, so specific routes must come before general ones.

## Using Generated Routes

### Route Helpers
Resource routes automatically create URL helpers:

```cfm
<!--- For resources("products") --->
#linkTo(route="products", text="All Products")#       <!-- /products -->
#linkTo(route="product", key=123, text="View")#       <!-- /products/123 -->
#linkTo(route="newProduct", text="Add Product")#     <!-- /products/new -->
#linkTo(route="editProduct", key=123, text="Edit")#  <!-- /products/123/edit -->

#urlFor(route="products")#           <!-- /products -->
#urlFor(route="product", key=123)#   <!-- /products/123 -->
```

### Custom Route Helpers
For custom routes, you'll need to manually create route names in your routes.cfm:

```cfm
<!--- Add name parameter manually in routes.cfm --->
.get(name="productSale", pattern="products/sale", to="products##sale")

<!--- Then use in views --->
#linkTo(route="productSale", text="Special Sale")#
```

## Detailed Parameter Usage

### Command Line Parameter Formats

Building on CommandBox's parameter syntax, Wheels route generation supports:

#### 1. Named Parameters (Recommended)
```bash
wheels generate route --get="products/sale,products##sale"
wheels generate route --post="contact/send,contact##send"
wheels generate route --resources=true --objectname=users
wheels generate route --root="pages##home"
```

#### 2. Positional Parameters
```bash
wheels generate route products              # objectname (resources route)
wheels g route users                        # Short alias with objectname
```

#### 3. Mixed Parameters
```bash
wheels generate route users --resources=true
wheels generate route --objectname=products --resources=true
```

### Parameter Validation Rules

#### HTTP Method Parameters
- **Format**: `--method="pattern,handler"` or `--method="pattern"`
- **Methods**: `get`, `post`, `put`, `patch`, `delete`
- **Separator**: Comma (`,`) between pattern and handler
- **Quotes**: Always use quotes around the value
- **Handler Format**: `controller##action` (double hash required in CFML)

#### Resources Parameters
- **Format**: `--resources=true objectname` or `objectname --resources=true`
- **Boolean**: Must be explicit `true` or `false`
- **Objectname**: Required when using resources flag

#### Root Parameters
- **Format**: `--root="controller##action"`
- **Handler**: Required controller and action
- **Quotes**: Always use quotes

### Parameter Examples by Type

#### String Parameters with Handlers
```bash
# GET route with handler
wheels generate route --get="api/users,api##index"

# POST route with handler
wheels generate route --post="users/login,sessions##create"

# PUT route with handler
wheels generate route --put="profiles/[key],profiles##update"
```

#### String Parameters without Handlers
```bash
# Pattern-only routes (uses convention)
wheels generate route --get="products/search"
wheels generate route --post="newsletter/signup"
```

#### Boolean Parameters
```bash
# Resources flag (explicit true/false)
wheels generate route --resources=true products
wheels generate route --resources=false    # Invalid - needs objectname
```

#### Mixed Parameter Combinations
```bash
# Objectname with resources flag
wheels generate route products --resources=true
wheels generate route --resources=true users

# Multiple routes in sequence
wheels generate route --get="login,sessions##new"
wheels generate route --post="login,sessions##create"
wheels generate route --delete="logout,sessions##destroy"
```

### Common Parameter Mistakes

❌ **Missing equals sign:**
```bash
wheels generate route --get products/sale,products##sale
```

❌ **Missing quotes:**
```bash
wheels generate route --get=products/sale,products##sale
```

❌ **Single hash instead of double:**
```bash
wheels generate route --get="products/sale,products#sale"
```

❌ **Missing objectname with resources:**
```bash
wheels generate route --resources=true        # No objectname
```

✅ **Correct formats:**
```bash
wheels generate route --get="products/sale,products##sale"
wheels generate route products --resources
wheels generate route --root="pages##home"
wheels generate route users    # Positional objectname
```

### Advanced Parameter Usage

#### Dynamic URL Segments
```bash
# Single parameter
wheels generate route --get="users/[key],users##show"

# Multiple parameters
wheels generate route --get="posts/[year]/[month],posts##archive"

# Optional parameters (configure manually in routes.cfm)
wheels generate route --get="blog/[category]" # Add [category?] manually
```

#### API-Style Routes
```bash
# RESTful API endpoints
wheels generate route --get="api/v1/users,api.v1.users##index"
wheels generate route --post="api/v1/users,api.v1.users##create"
wheels generate route --put="api/v1/users/[key],api.v1.users##update"
wheels generate route --delete="api/v1/users/[key],api.v1.users##destroy"
```

#### Namespace-Style Controllers
```bash
# Admin controllers
wheels generate route --get="admin/dashboard,admin.dashboard##index"
wheels generate route --get="admin/users,admin.users##index"

# Module-based controllers
wheels generate route --get="shop/products,shop.products##index"
wheels generate route --post="shop/checkout,shop.checkout##process"
```

### Parameter Processing Details

#### Command Line Processing
1. **Quoted Parameters**: Preserve spaces and special characters
2. **Equals Processing**: Splits parameter name from value
3. **Boolean Conversion**: Converts "true"/"false" strings to boolean values
4. **Array Processing**: CommandBox processes space-separated values as arrays

#### Internal Parameter Handling
1. **reconstructArgs()**: Processes CommandBox parameter format
2. **Validation**: Checks required parameters are present
3. **Route Generation**: Formats parameters for Wheels router syntax
4. **File Injection**: Places routes at correct position in routes.cfm

## Integration with Routes.cfm

### CLI Marker
The command looks for `// CLI-Appends-Here` comment to place new routes. If not found, it tries different indentation levels:

1. `			// CLI-Appends-Here` (3 tabs)
2. `		// CLI-Appends-Here` (2 tabs)
3. `	// CLI-Appends-Here` (1 tab)
4. `// CLI-Appends-Here` (no tabs)

### Manual Route Organization
After using the CLI, you may want to reorganize routes manually:

```cfm
<cfscript>
mapper()
    // Public pages first
    .get(pattern="about", to="pages##about")
    .get(pattern="contact", to="contact##index")

    // Resources grouped together
    .resources("products")
    .resources("users")

    // Authentication routes
    .get(pattern="login", to="sessions##new")
    .post(pattern="login", to="sessions##create")

    // CLI generated routes will appear here
    // CLI-Appends-Here

    .wildcard()  // Always keep wildcard last
    .root(to="home##index", method="get")
.end();
</cfscript>
```

## Best Practices

1. **Use equals syntax**: Always use `--get="pattern,handler"` format
2. **Resources for CRUD**: Use resources route for full CRUD operations
3. **Custom routes for special actions**: Use HTTP method routes for non-CRUD actions
4. **Check route order**: Specific routes before general ones
5. **Test after generation**: Visit URLs to ensure routes work
6. **Reload application**: Use `?reload=true` after route changes

## Troubleshooting

### Common Issues and Solutions

#### 1. Parameter Syntax Errors

**Issue**: `"Missing argument"` errors when using HTTP method parameters

❌ **Incorrect:**
```bash
wheels generate route --get products/sale,products##sale    # Missing =
wheels generate route --post contact send                   # Missing quotes and =
```

✅ **Correct:**
```bash
wheels generate route --get="products/sale,products##sale"  # With = and quotes
wheels generate route --post="contact,sessions##create"     # Proper format
```

**Solution**: Always use equals syntax with quotes for HTTP method parameters.

#### 2. CFML Syntax Errors

**Issue**: Template compilation errors with single hash (`#`) in handlers

❌ **Incorrect:**
```bash
wheels generate route --get="users,users#show"   # Single # causes CFML errors
```

✅ **Correct:**
```bash
wheels generate route --get="users,users##show"  # Double ## for CFML escaping
```

**Solution**: Always use double hash (`##`) in controller##action handlers.

#### 3. Routes Not Working

**Issue**: Generated routes don't respond or show 404 errors

**Possible Causes:**
- Application not reloaded after route changes
- Route order conflicts (specific routes after wildcard)
- Controller or action doesn't exist

**Solutions:**
```bash
# 1. Always reload after route changes
http://localhost:8080/?reload=true

# 2. Check route order in routes.cfm
# Ensure wildcard() comes AFTER specific routes

# 3. Verify controller exists
# For route: --get="products,products##sale"
# Need: /app/controllers/Products.cfc with sale() function
```

#### 4. Parameter Parsing Issues

**Issue**: Complex patterns not parsed correctly

❌ **Problematic:**
```bash
# Spaces in patterns without quotes
wheels generate route --get=api/v1/users,api##index

# Special characters not escaped
wheels generate route --get="api-users,api#index"
```

✅ **Solutions:**
```bash
# Always quote complex patterns
wheels generate route --get="api/v1/users,api##index"

# Use proper CFML escaping
wheels generate route --get="api-users,api##index"
```

#### 5. Resources Route Issues

**Issue**: Resources flag not working or missing objectname

❌ **Common Mistakes:**
```bash
wheels generate route --resources=true              # Missing objectname
wheels generate route --resources products          # Missing =true
wheels generate route products --resource           # Wrong flag name
```

✅ **Correct Usage:**
```bash
wheels generate route --resources=true products     # Explicit flag with objectname
wheels generate route products --resources=true     # Alternative order
wheels generate route products                      # Default resources (implicit)
```

#### 6. Route Placement Issues

**Issue**: Routes added in wrong location or break existing routes

**Common Problems:**
- CLI marker `// CLI-Appends-Here` not found
- Routes added after wildcard route
- Malformed routes.cfm syntax

**Solutions:**
```cfm
<!-- Ensure routes.cfm has proper structure -->
<cfscript>
mapper()
    // Existing routes
    .resources("products")

    // CLI marker for new routes
    // CLI-Appends-Here

    // Wildcard MUST be last
    .wildcard()

    // Root route
    .root(to="home##index", method="get")
.end();  // Don't forget .end()!
</cfscript>
```

### Validation and Testing

#### Pre-Generation Checklist
Before generating routes, verify:

```bash
# 1. Check current directory is Wheels app root
ls config/routes.cfm    # Should exist

# 2. Verify routes.cfm has CLI marker
grep "CLI-Appends-Here" config/routes.cfm    # Should find marker

# 3. Check routes.cfm syntax is valid
# Look for proper mapper() and .end() structure
```

#### Post-Generation Validation
After generating routes, always:

```bash
# 1. Reload application
http://localhost:8080/?reload=true

# 2. Test route in browser
http://localhost:8080/your-new-route

# 3. Check debug footer for route information
# Look for your new route in the Routes section
```

#### Testing Generated Routes

```bash
# Test different HTTP methods
curl -X GET http://localhost:8080/api/users
curl -X POST http://localhost:8080/api/users -d "name=test"
curl -X PUT http://localhost:8080/api/users/1 -d "name=updated"
curl -X DELETE http://localhost:8080/api/users/1
```

### Error Reference

#### Common Error Messages

**"Please provide either an objectname for a resources route or specify a route type"**
- **Cause**: No parameters provided to command
- **Solution**: Provide either objectname or HTTP method parameter

**"key [TYPE] doesn't exist"**
- **Cause**: Internal processing error (rare)
- **Solution**: Try simpler route first, then add complexity

**"Template compilation error"**
- **Cause**: Single hash (`#`) in generated route
- **Solution**: Check for double hash (`##`) in all handlers

**"Route not found" (404 errors)**
- **Cause**: Route not added or application not reloaded
- **Solution**: Check routes.cfm and reload application

### Best Practices for Avoiding Issues

#### 1. Parameter Formatting
```bash
# Always use consistent formatting
wheels generate route --get="pattern,handler"    # ✅ Consistent
wheels generate route --get pattern,handler      # ❌ Inconsistent
```

#### 2. Route Planning
```bash
# Plan route structure before generating
# 1. Resources routes first
wheels generate route products
wheels generate route users

# 2. Custom routes second
wheels generate route --get="search,search##index"
wheels generate route --post="contact,contact##send"

# 3. API routes with namespace pattern
wheels generate route --get="api/products,api.products##index"
```

#### 3. Testing Strategy
```bash
# Generate one route at a time
wheels generate route --get="test,test##index"
# Test it works
curl http://localhost:8080/test
# Then generate next route
```

#### 4. Documentation
```bash
# Document custom routes in routes.cfm
.get(name="productSearch", pattern="products/search", to="products##search")
// Custom search endpoint for products - returns JSON
```

### Getting Help

If you encounter issues not covered here:

1. **Check the debug footer**: Shows all registered routes
2. **Verify controller exists**: Match route handler to actual controller/action
3. **Test with simple routes first**: Basic patterns before complex ones
4. **Check Wheels routing guide**: For advanced routing features
5. **Reload frequently**: Always reload after route changes

## See Also

- [wheels generate scaffold](scaffold.md) - Generate complete CRUD with routes
- [wheels generate controller](controller.md) - Generate controllers
- [wheels generate model](model.md) - Generate models
- [Wheels Routing Guide](https://wheels.dev/3.0.0/guides/handling-requests-with-controllers/routing) - Complete routing documentation