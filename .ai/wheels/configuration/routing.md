# Routing Configuration

## 🔴 CRITICAL ROUTING ANTI-PATTERNS (MOST COMMON CONFIG ERRORS)

**Before writing ANY routing code, verify you will NOT:**
- [ ] ❌ Use Rails-style nested resources: `.resources("posts", function(nested) { nested.resources("comments"); })`
- [ ] ❌ Put wildcard route before other routes
- [ ] ❌ Mix argument styles in route definitions
- [ ] ❌ Forget to call `.end()` to close mapper

**And you WILL:**
- [ ] ✅ Use separate resource declarations: `.resources("posts").resources("comments")`
- [ ] ✅ Put routes in correct order: resources → custom → root → wildcard
- [ ] ✅ Use consistent argument syntax throughout
- [ ] ✅ Always close mapper with `.end()`

## 📋 ROUTING IMPLEMENTATION TEMPLATE (MANDATORY STARTING POINT)

```cfm
<cfscript>
mapper()
    // 1. Resource routes FIRST
    .resources("posts")
    .resources("comments")
    .resources("users")

    // 2. Custom routes SECOND
    .get(name="login", to="sessions##new")
    .post(name="authenticate", to="sessions##create")
    .delete(name="logout", to="sessions##delete")

    // 3. Root route THIRD
    .root(to="posts##index", method="get")

    // 4. Wildcard route LAST (ALWAYS LAST)
    .wildcard()
.end(); // CRITICAL: Always end with .end()
</cfscript>
```

## Routing Configuration (`routes.cfm`)

Define URL patterns and map them to controller actions:

```cfm
<cfscript>
    // Use this file to add routes to your application
    // Don't forget to reload after changes: ?reload=true
    // See https://wheels.dev/3.0.0/guides/handling-requests-with-controllers/routing

    mapper()
        // Resource-based routing (recommended)
        .resources("users")
        .resources("posts")
        .resources("comments")  // Nested resources use separate declarations

        // Singular resource (no primary key in URL)
        .resource("profile")
        .resource("cart")

        // Custom routes
        .get(name="search", pattern="search", to="search##index")
        .get(name="about", pattern="about", to="pages##about")
        .post(name="contact", pattern="contact", to="contact##create")

        // API routes with namespace
        .namespace("api", {
            resources: ["users", "posts"]
        })

        // Catch-all wildcard routing
        .wildcard()

        // Root route (homepage)
        .root(to="home##index", method="get")
    .end();
</cfscript>
```

## Routing Patterns

### Resource Routing

```cfm
.resources("products")
// Creates: index, show, new, create, edit, update, delete actions

.resources("categories", {
    except: ["delete"]
})
.resources("products")  // Nested resources declared separately
```

### Custom Routes

```cfm
.get(name="productSearch", pattern="products/search", to="products##search")
.post(name="newsletter", pattern="newsletter/signup", to="newsletter##signup")
.patch(name="activate", pattern="users/[key]/activate", to="users##activate")
.delete(name="clearCart", pattern="cart/clear", to="cart##clear")
```

### Route Constraints

```cfm
.get(name="userPosts", pattern="users/[userId]/posts/[postId]", to="posts##show", {
    constraints: {
        userId: "\d+",
        postId: "\d+"
    }
})
```

### Route Parameters

- **`[key]`** - Primary key parameter (maps to `params.key`)
- **`[slug]`** - URL-friendly identifier
- **`[any-name]`** - Custom parameter name
- **Optional parameters**: Use `?` suffix like `[category?]`

## Route Helper Usage

After defining routes, use them in views:

```cfm
<!--- Resource routes --->
#linkTo(route="products", text="All Products")#
#linkTo(route="newProduct", text="New Product")#
#linkTo(route="product", key=product.id, text="View Product")#
#linkTo(route="editProduct", key=product.id, text="Edit")#

<!--- Custom routes --->
#linkTo(route="search", text="Search Products")#
#linkTo(route="about", text="About Us")#

<!--- With parameters --->
#linkTo(route="userPosts", userId=user.id, postId=post.id)#
```

## Routing Best Practices

### Route Ordering

Routes are processed in order - first match wins. Order routes from most specific to most general:

```cfm
mapper()
    // 1. Resource routes first
    .resources("posts")
    .resources("comments")

    // 2. Custom routes
    .get(name="search", pattern="search", to="search##index")
    .get(name="admin", pattern="admin", to="admin##dashboard")

    // 3. Root route
    .root(to="posts##index", method="get")

    // 4. Wildcard routing last
    .wildcard()
.end();
```

## Common Routing Mistakes

### ❌ Incorrect nested resource syntax:

```cfm
.resources("posts", function(nested) {
    nested.resources("comments");  // This doesn't work in Wheels
})
```

### ✅ Correct approach - separate declarations:

```cfm
.resources("posts")
.resources("comments")
```

### ❌ Wrong route ordering:

```cfm
mapper()
    .wildcard()        // Too early - catches everything
    .resources("posts") // Never reached
.end();
```

### ✅ Correct ordering:

```cfm
mapper()
    .resources("posts") // Specific routes first
    .wildcard()         // Catch-all last
.end();
```

## Route Testing

Always test routes after changes:

1. Use `?reload=true` to reload configuration
2. Check the debug footer "Routes" link to view all routes
3. Test both positive and negative cases
4. Verify route helpers generate correct URLs

## 🔍 POST-IMPLEMENTATION VALIDATION (REQUIRED BEFORE COMPLETION)

**After writing configuration code, you MUST:**

```bash
# 1. Syntax validation
wheels server start --validate

# 2. Route testing
wheels server start
# Test routes in browser to ensure they work

# 3. Manual verification
# Check that routes.cfm follows correct ordering
# Verify all mappers end with .end()
```

**Manual checklist verification:**
- [ ] Resources declared separately (not nested)
- [ ] Routes in correct order (resources, custom, root, wildcard)
- [ ] Mapper closed with .end()
- [ ] No mixed argument styles
- [ ] Wildcard route is last