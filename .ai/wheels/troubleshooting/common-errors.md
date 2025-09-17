# Common Errors and Solutions

## Description
Frequent issues encountered when developing CFWheels applications and their solutions, based on real development experiences.

## Key Points
- CFWheels differs from Rails in several key areas
- Form helpers have different capabilities than Rails
- Association syntax has specific CFWheels conventions
- Migration parameter binding can be unreliable

## Common Association Errors

### "Missing argument name" in hasMany()
**Error:**
```
Complex object types cannot be converted to simple values.
The expression has requested a variable or an intermediate expression result as a simple value. However, the result cannot be converted to a simple value. Simple values are strings, numbers, boolean values, and date/time values. Queries, arrays, and COM objects are examples of complex values.
```

**Cause:** Mixing positional and named parameters in CFWheels function calls.

**Bad Code:**
```cfm
component extends="Model" {
    function config() {
        hasMany("comments", dependent="delete"); // Error: mixed parameter styles
    }
}
```

**Solutions:**
```cfm
component extends="Model" {
    function config() {
        // Option 1: Use consistent named parameters
        hasMany(name="comments", dependent="delete");

        // Option 2: Use all positional parameters (no dependent option)
        hasMany("comments");
    }
}
```

**Related:** CFWheels requires consistent parameter syntax - either all positional or all named parameters, not mixed.

### "Can't cast Object type [Query] to a value of type [Array]"
**Error:**
```
Can't cast Object type [Query] to a value of type [Array]
Detail: Java type of the object is lucee.runtime.type.QueryImpl
```

**Cause:** Treating CFWheels association results as arrays when they return query objects.

**Bad Code:**
```cfm
<!-- In views or controllers -->
<cfset commentCount = ArrayLen(post.comments())>  <!-- ERROR: comments() returns Query -->
<cfloop array="#post.comments()#" index="comment"> <!-- ERROR: Can't loop Query as Array -->
    #comment.content#
</cfloop>
```

**Solutions:**
```cfm
<!-- Use query methods and properties -->
<cfset commentCount = post.comments().recordCount>
<cfset comments = post.comments()>

<!-- Loop as query, not array -->
<cfloop query="comments">
    #comments.content#  <!-- Access fields directly from query -->
</cfloop>

<!-- Check if query has records -->
<cfif post.comments().recordCount gt 0>
    <cfloop query="post.comments()">
        <p>#post.comments().author#: #post.comments().content#</p>
    </cfloop>
<cfelse>
    <p>No comments found.</p>
</cfif>
```

**Key Points:**
- All CFWheels association methods return **Query objects**, not arrays
- Use `.recordCount` for counts, not `ArrayLen()`
- Use `<cfloop query="...">` for iteration, not `<cfloop array="...">`
- Model finder methods also return queries: `model("User").findAll()` returns Query

**Related:** This is the #2 most common CFWheels error after argument mixing.

## Form Helper Errors

### "No matching function [LABEL] found"
**Error:** When using `label()` with `text` parameter.

**Cause:** CFWheels `label()` helper doesn't accept a `text` parameter like Rails does.

**Bad Code:**
```cfm
#label(objectName="comment", property="authorName", text="Name *")#
```

**Solution:**
```cfm
<label for="comment-authorName">Name *</label>
#textField(objectName="comment", property="authorName")#
```

### "No matching function [EMAILFIELD] found"
**Error:** When trying to use specialized form helpers.

**Cause:** CFWheels doesn't have specialized form helpers like `emailField()` or `passwordField()`.

**Bad Code:**
```cfm
#emailField(objectName="comment", property="email")#
```

**Solution:**
```cfm
#textField(objectName="comment", property="email", type="email")#
```

**Available Form Helpers in CFWheels:**
- `textField()`
- `passwordField()` - **Wait, this does exist!**
- `hiddenField()`
- `textArea()`
- `checkBox()`
- `radioButton()`
- `select()`
- `submitTag()`

**Note:** Use `textField()` with `type` parameter for HTML5 input types.

## Routing Errors

### Incorrect .resources() Syntax
**Problem:** Using incorrect syntax for the `.resources()` function in routes.cfm can cause routing failures.

**Common Incorrect Syntax:**
```cfm
mapper()
  .resources("posts", function(nested) {
    nested.resources("comments");
  })
.end();
```

**Correct Syntax for Simple Resources:**
```cfm
mapper()
  .resources("posts")
  .resources("comments")
.end();
```

**Correct Syntax for Nested Resources (if supported):**
```cfm
mapper()
  .resources("posts")
  .resources("comments") // Separate declaration
.end();
```

**Route Ordering Issues:**
Routes must be ordered correctly in routes.cfm:
1. Resource routes first
2. Custom routes
3. Root route
4. Wildcard route last

```cfm
mapper()
  .resources("posts")           // 1. Resources first
  .resources("comments")
  .get(name="admin", ...)      // 2. Custom routes
  .root(to="posts##index")     // 3. Root route
  .wildcard()                  // 4. Wildcard last
.end();
```

**Note:** CFWheels routing syntax differs from Rails - always check the CFWheels documentation for exact syntax rather than assuming Rails patterns work.

## Migration Errors

### Parameter Binding Issues in Migrations
**Problem:** Complex parameter binding in migration `execute()` calls can fail unpredictably.

**Bad Code:**
```cfm
execute(
    sql="INSERT INTO posts (title, slug, body) VALUES (?, ?, ?)",
    parameters=[
        {value=title, cfsqltype="cf_sql_varchar"},
        {value=slug, cfsqltype="cf_sql_varchar"},
        {value=body, cfsqltype="cf_sql_longvarchar"}
    ]
);
```

**Solution:** Use direct SQL concatenation for migration data seeding:
```cfm
execute("INSERT INTO posts (title, slug, body, createdAt, updatedAt)
         VALUES ('My Blog Post', 'my-blog-post', 'Content here...', NOW(), NOW())");
```

**Best Practice:** For migrations, prefer simple direct SQL over complex parameter binding for reliability.

## Debugging Tips

### Check Function Availability
When encountering "No matching function" errors:
1. Check CFWheels documentation for exact function names
2. Verify parameter names and types
3. Consider that CFWheels may differ from Rails conventions

### Association Debugging
When models fail to load:
1. Check association syntax matches CFWheels conventions
2. Remove Rails-style options like `dependent`, `class_name`, etc.
3. Use simple association definitions first, then add complexity

### Migration Debugging
When migrations fail:
1. Use direct SQL instead of complex parameter binding
2. Test SQL queries directly in database before adding to migration
3. Wrap operations in transactions for atomicity

## Framework Differences from Rails

### Association Options
- **Rails:** `has_many :comments, dependent: :destroy`
- **CFWheels:** `hasMany("comments")` - no dependent options

### Form Helpers
- **Rails:** Rich set of specialized helpers (`email_field`, `password_field`, etc.)
- **CFWheels:** More limited set, use `textField()` with `type` parameter

### Parameter Names
- **Rails:** Uses symbols and underscores (`:text => "Label"`)
- **CFWheels:** Uses strings and camelCase (`text="Label"`)

## Related
- [Model Associations](../database/associations/)
- [Form Helpers](../views/helpers/forms.md)
- [Database Migrations](../database/migrations/)

## Important Notes
- Always consult CFWheels documentation rather than assuming Rails conventions
- Test association definitions in simple form before adding complexity
- For migrations, prefer direct SQL over parameter binding for data seeding
- CFWheels form helpers are more limited than Rails - supplement with HTML when needed