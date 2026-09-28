---
name: Wheels Anti-Pattern Detector
description: Automatically detect and prevent common Wheels framework errors before code is generated. This skill activates during ANY Wheels code generation (models, controllers, views, migrations) to validate patterns and prevent known issues. Scans for mixed arguments, query/array confusion, non-existent helpers, and database-specific SQL.
---

# Wheels Anti-Pattern Detector

## Purpose

This skill runs **AUTOMATICALLY** during any Wheels code generation to catch common errors before they're written to files.

## When to Use This Skill

Activate automatically during:
- Model generation (check associations, validations)
- Controller generation (check method calls)
- View generation (check queries, form helpers)
- Migration generation (check SQL compatibility)
- Code review and refactoring
- Any Wheels code modification

## Anti-Patterns

### 1. Property Access Without structKeyExists() Check

Properties that weren't passed to `new()` don't exist on the object yet, so reading them in a `beforeCreate` / `beforeValidation` callback throws unless you check first.

**Detection Pattern:**
```regex
function\s+(beforeCreate|beforeValidation|setDefaults)[\s\S]*?if\s*\(\s*!len\s*\(\s*this\.\w+\s*\)\s*\)(?![\s\S]*?structKeyExists)
```

**Examples to Detect:**
```cfm
❌ function setDefaults() {
    if (!len(this.followersCount)) {  // Error if property doesn't exist!
        this.followersCount = 0;
    }
}
```

**Auto-Fix:**
```cfm
✅ function setDefaults() {
    if (!structKeyExists(this, "followersCount") || !len(this.followersCount)) {
        this.followersCount = 0;
    }
}
```

**Error Message:**
```
⚠️  CRITICAL: Property access without structKeyExists() check
Line: 15
Found: if (!len(this.followersCount)) in beforeCreate callback
Fix:   if (!structKeyExists(this, "followersCount") || !len(this.followersCount))

In beforeCreate/beforeValidation callbacks, properties may not exist yet.
Without the check this throws a "no accessible Member" error.
```

### 2. Mixed Argument Styles

**Detection Pattern:**
```regex
(hasMany|belongsTo|hasManyThrough|validatesPresenceOf|validatesUniquenessOf|validatesFormatOf|validatesLengthOf|findByKey|findAll|findOne)\s*\(\s*"[^"]+"\s*,\s*\w+\s*=
```

**Examples:**
```cfm
❌ hasMany("comments", dependent="delete")
❌ belongsTo("user", foreignKey="userId")
❌ validatesPresenceOf("title", message="Required")
❌ findByKey(params.key, include="comments")
❌ findAll(order="id DESC", where="active = 1")
```

**Auto-Fix:**
```cfm
✅ hasMany(name="comments", dependent="delete")
✅ belongsTo(name="user", foreignKey="userId")
✅ validatesPresenceOf(property="title", message="Required")
✅ findByKey(key=params.key, include="comments")
✅ findAll(order="id DESC", where="active = 1")  // No positional args, OK
```

**Error Message:**
```
⚠️  ANTI-PATTERN DETECTED: Mixed argument styles
Line: 5
Found: hasMany("comments", dependent="delete")
Fix:   hasMany(name="comments", dependent="delete")

Wheels requires consistent parameter syntax - either ALL positional OR ALL named.
When using options like 'dependent', you MUST use named arguments for ALL parameters.
```

### 3. Query/Array Confusion

**Detection Pattern:**
```regex
ArrayLen\s*\(\s*\w+\.(comments|posts|tags|users|[a-z]+)\(\s*\)\s*\)
```

**Examples:**
```cfm
❌ <cfset count = ArrayLen(post.comments())>
❌ <cfloop array="#post.comments()#" index="comment">
❌ <cfif ArrayIsEmpty(user.posts())>
```

**Auto-Fix:**
```cfm
✅ <cfset count = post.comments().recordCount>
✅ <cfloop query="comments">  // After: comments = post.comments()
✅ <cfif user.posts().recordCount == 0>
```

**Error Message:**
```
⚠️  ANTI-PATTERN DETECTED: ArrayLen() on query object
Line: 12
Found: ArrayLen(post.comments())
Fix:   post.comments().recordCount

Wheels associations return QUERIES, not arrays. Use .recordCount for count.
```

### 4. Association Access Inside Query Loops

**Detection Pattern:**
```regex
<cfloop\s+query="[^"]+">[\s\S]*?\.\w+\(\)\.recordCount
```

**Examples:**
```cfm
❌ <cfloop query="posts">
    <p>#posts.comments().recordCount# comments</p>
</cfloop>
```

**Auto-Fix:**
```cfm
✅ <cfloop query="posts">
    <cfset postComments = model("Post").findByKey(posts.id).comments()>
    <p>#postComments.recordCount# comments</p>
</cfloop>
```

**Error Message:**
```
⚠️  ANTI-PATTERN DETECTED: Association access inside query loop
Line: 15
Found: posts.comments().recordCount inside <cfloop query="posts">
Fix:   Load association separately: postComments = model("Post").findByKey(posts.id).comments()

Cannot access associations directly on query objects inside loops.
Must reload the model object first.
```

### 5. Use the HTML5 Form Helpers

`emailField`, `passwordField`, `numberField`, `urlField`, `telField`, `dateField`, `colorField`, `rangeField` and `searchField` all exist (object and `*Tag` forms). Prefer them over `textField(type="...")`, which loses the helper's type-specific attributes.

```cfm
✅ #emailField(objectName="user", property="email")#
✅ #numberField(objectName="product", property="price", min="0")#
```

### 6. Nested Routes Use callback=

Wheels nests resources with a `callback=` function (or `nested=true` plus `.end()`), not Rails-style inline blocks.

```cfm
❌ .resources("posts", function(r) { r.resources("comments"); })

✅ .resources(name="posts", callback=function(map) {
       map.resources("comments");
   })
```

### 7. Database-Specific SQL Functions

**Detection Pattern:**
```regex
(DATE_SUB|DATE_ADD|NOW|CURDATE|CURTIME|DATEDIFF|INTERVAL)\s*\(
```

`NOW()`, `CURDATE()` and `DATE_SUB(... INTERVAL ...)` are MySQL-specific; `NOW()` fails on SQLite (the `wheels new` default) and SQL Server. In raw SQL use `CURRENT_TIMESTAMP`. For relative dates in application code, compute the value in CFML and pass it through the model layer, which binds it as a parameter.

```cfm
❌ execute("UPDATE posts SET modifiedAt = NOW()")
✅ execute("UPDATE posts SET modifiedAt = CURRENT_TIMESTAMP")

❌ model("Post").findAll(where="createdAt > DATE_SUB(NOW(), INTERVAL 1 DAY)")
✅ model("Post").findAll(where="createdAt > '#DateFormat(DateAdd("d", -1, Now()), "yyyy-mm-dd")#'")
```

### 8. Missing CSRF Protection Check

**Detection Pattern:**
```regex
<form[^>]*method\s*=\s*["']post["'][^>]*>(?![\s\S]*csrf)
```

**Examples:**
```cfm
❌ <form method="post" action="/users/create">
    <!--- No CSRF token --->
</form>
```

**Auto-Fix:**
```cfm
✅ #startFormTag(action="create", method="post")#
    <!--- token added automatically when the controller calls protectsFromForgery() --->
#endFormTag()#
```

**Error Message:**
```
⚠️  ANTI-PATTERN DETECTED: Form without CSRF protection
Line: 45
Found: <form method="post"> without CSRF token
Fix:   Use #startFormTag()# which includes CSRF automatically

startFormTag() adds the authenticity token for non-GET forms when the
controller (usually app/controllers/Controller.cfc) calls protectsFromForgery().
```

## Related Skills

All Wheels generator skills depend on this skill for validation.

