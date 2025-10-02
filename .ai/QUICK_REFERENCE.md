# CFWheels Quick Reference - Most Common Issues

## 🔴 Top 5 Critical Patterns (Learn These First!)

### 1. Layout cfoutput Block Coverage (MOST COMMON ERROR)

❌ **WRONG - Expressions don't render:**
```cfm
<cfif application.contentOnly>
    <cfoutput>#includeContent()#</cfoutput>
<cfelse>
<!DOCTYPE html>
<html>
<head>
    #csrfMetaTags()#  <!-- ❌ Outside cfoutput -->
</head>
<body>
    <a href="#urlFor(controller='posts')#">Posts</a>  <!-- ❌ Shows as literal text -->
</body>
</html>
</cfif>
```

✅ **CORRECT - Wrap entire HTML in cfoutput:**
```cfm
<cfif application.contentOnly>
    <cfoutput>#includeContent()#</cfoutput>
<cfelse>
<cfoutput>
<!DOCTYPE html>
<html>
<head>
    #csrfMetaTags()#
</head>
<body>
    <a href="#urlFor(controller='posts')#">Posts</a>
    #includeContent()#
</body>
</html>
</cfoutput>
</cfif>
```

**Rule**: Open `<cfoutput>` after `<cfelse>`, close before `</cfif>`

---

### 2. Form Helper Duplicate Labels

❌ **WRONG - Creates duplicate labels:**
```cfm
<label for="post-title">Title</label>
#textField(objectName="post", property="title")#
```
**Result**: "Title Title" appears

✅ **CORRECT - Use label=false:**
```cfm
<label for="post-title">Title</label>
#textField(objectName="post", property="title", label=false)#
```

**Rule**: When using HTML labels, add `label=false` to form helpers

---

### 3. Association Query Handling in Views

❌ **WRONG - Associations aren't counted properties:**
```cfm
<cfloop query="posts">
    <p>#posts.comments_count# comments</p>  <!-- ❌ Column doesn't exist -->
</cfloop>
```

✅ **CORRECT - Load association and use recordCount:**
```cfm
<cfloop query="posts">
    <cfset comments = model("Post").findByKey(posts.id).comments()>
    <p>#comments.recordCount# comments</p>
</cfloop>
```

**Rule**: Associations return QUERY objects with `.recordCount`, not computed properties

---

### 4. Consistent Argument Style

❌ **WRONG - Mixed positional and named:**
```cfm
hasMany("comments", dependent="delete")  <!-- ❌ ERROR -->
model("Post").findByKey(1, include="comments")  <!-- ❌ ERROR -->
```

✅ **CORRECT - All named arguments:**
```cfm
hasMany(name="comments", dependent="delete")
model("Post").findByKey(key=1, include="comments")
```

**Rule**: Never mix positional and named arguments

---

### 5. Database-Agnostic Migration Dates

❌ **WRONG - Database-specific functions:**
```cfm
execute("INSERT INTO posts (publishedAt) VALUES (DATE_SUB(NOW(), INTERVAL 7 DAY))");
```
**Problem**: Only works with MySQL

✅ **CORRECT - Use CFML date functions:**
```cfm
var day7 = DateAdd("d", -7, Now());
execute("INSERT INTO posts (publishedAt) VALUES (
    TIMESTAMP '#DateFormat(day7, "yyyy-mm-dd")# #TimeFormat(day7, "HH:mm:ss")#'
)");
```

**Rule**: Use CFML DateAdd/DateFormat for portability

---

## 🧪 Testing Best Practice

❌ **WRONG - Only check status code:**
```bash
curl -I http://localhost:8080 | grep "200 OK"
```
**Problem**: 200 doesn't mean content is correct

✅ **CORRECT - Verify actual content:**
```bash
curl -s http://localhost:8080 | grep "Expected Content"
curl -s http://localhost:8080 | grep -c "article"  # Count elements
curl -s http://localhost:8080 | grep '#urlFor'    # Should be empty
```

**Rule**: Always verify content rendering, not just HTTP status

---

## 🗄️ Migration Best Practices

### Check Before Creating Tables

❌ **WRONG - Assume clean database:**
```cfm
function up() {
    t = createTable(name="posts");
    t.create();
}
```
**Error**: "Table already exists"

✅ **CORRECT - Check existing schema first:**
```bash
# Before creating migration
wheels dbmigrate info  # Check current state

# If table exists, modify instead
t = changeTable(name="posts");
t.text(columnNames="excerpt");  # Add missing column only
t.change();
```

### Direct SQL for Data Seeding

❌ **WRONG - Parameter binding:**
```cfm
execute(sql="INSERT INTO posts VALUES (?)", parameters=[{value=title}]);
```

✅ **CORRECT - Direct SQL:**
```cfm
execute("INSERT INTO posts (title, createdAt, updatedAt)
         VALUES ('My Post', NOW(), NOW())");
```

---

## 🛣️ Route Configuration Order

❌ **WRONG - Wildcard first:**
```cfm
mapper()
    .wildcard()      <!-- ❌ Catches everything -->
    .resources("posts")  <!-- Never reached -->
.end();
```

✅ **CORRECT - Specific to general:**
```cfm
mapper()
    .resources("posts")      // 1. Resource routes
    .get(name="about", ...)  // 2. Custom routes
    .root(to="posts##index") // 3. Root route
    .wildcard()              // 4. Wildcard LAST
.end();
```

---

## 🔍 Quick Debugging Checklist

When something doesn't work, check in this order:

### Views Not Rendering:
1. ✅ Is entire layout in `<cfoutput>` block?
2. ✅ Did you reload after changes (`?reload=true`)?
3. ✅ Are associations stored in variables before loops?

### Forms Have Issues:
1. ✅ Did you add `label=false` when using custom labels?
2. ✅ Are arguments all named or all positional (not mixed)?
3. ✅ Did you test delete buttons with `method="delete"`?

### Migrations Failing:
1. ✅ Did you check if tables already exist?
2. ✅ Are you using CFML date functions, not database-specific?
3. ✅ Are operations wrapped in `transaction` blocks?

### Routes Not Working:
1. ✅ Is route order correct (resources → custom → root → wildcard)?
2. ✅ Did mapper end with `.end()`?
3. ✅ Did you reload routes (`?reload=true`)?

---

## 📚 Full Documentation References

- **Layout Issues**: [views/layouts.md](wheels/views/layouts.md)
- **Form Problems**: [views/forms.md](wheels/views/forms.md)
- **Query/Association**: [views/query-association-patterns.md](wheels/views/query-association-patterns.md)
- **All Common Errors**: [troubleshooting/common-errors.md](wheels/troubleshooting/common-errors.md)
- **Migration Best Practices**: [database/migrations/best-practices.md](wheels/database/migrations/best-practices.md)
- **Testing Strategies**: [views/testing.md](wheels/views/testing.md)
- **Modern Frontend**: [integration/modern-frontend-stack.md](wheels/integration/modern-frontend-stack.md)

---

**Remember**: These 5 patterns solve 80%+ of common CFWheels issues. Master them first!
