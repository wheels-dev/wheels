# View Best Practices

## 🚨 CRITICAL: Pre-View Implementation Checklist

### 🛑 MANDATORY DOCUMENTATION READING (COMPLETE BEFORE ANY CODE)

**YOU MUST READ THESE FILES IN ORDER:**

✅ **Step 1: Error Prevention (ALWAYS FIRST)**
- [ ] `.ai/wheels/troubleshooting/common-errors.md` - PREVENT FATAL ERRORS
- [ ] `.ai/wheels/patterns/validation-templates.md` - VIEW CHECKLIST

✅ **Step 2: View-Specific Documentation**
- [ ] `.ai/wheels/views/data-handling.md` - CRITICAL query vs array patterns
- [ ] `.ai/wheels/views/architecture.md` - View structure and conventions
- [ ] `.ai/wheels/views/forms.md` - Form helper limitations and patterns

### 🔴 CRITICAL ANTI-PATTERN CHECK (MUST VERIFY BEFORE WRITING)

**Before writing ANY view code, verify you will NOT:**
- [ ] ❌ Use ArrayLen() on queries: `ArrayLen(posts)` or `ArrayLen(post.comments())`
- [ ] ❌ Loop queries as arrays: `<cfloop array="#posts#" index="post">`
- [ ] ❌ Treat model results as arrays in any context
- [ ] ❌ Mix loop types (array syntax on queries)
- [ ] ❌ Add HTML to view helper text without `encode=false`: `linkTo(text="<span>Blog</span>")`
- [ ] ❌ Use buttonTo() for DELETE without method parameter: `buttonTo(action="delete", key=id)`

**And you WILL:**
- [ ] ✅ Use .recordCount for query counts: `posts.recordCount`
- [ ] ✅ Use query loops: `<cfloop query="posts">`
- [ ] ✅ Understand associations return QUERIES
- [ ] ✅ Check data types before processing
- [ ] ✅ Use method parameter for buttonTo() HTTP verbs: `buttonTo(action="delete", method="delete", key=id)`
- [ ] ✅ Use `encode=false` for HTML in helpers: `linkTo(text="<span>Blog</span>", encode=false)`

### 📋 VIEW IMPLEMENTATION TEMPLATE (MANDATORY STARTING POINT)

```cfm
<cfparam name="posts">
<cfoutput>

<!-- Check record count correctly -->
<cfif posts.recordCount gt 0>
    <!-- Loop query correctly -->
    <cfloop query="posts">
        <h2>#posts.title#</h2>
        <!-- Access associations correctly -->
        <p>Comments: #posts.comments().recordCount#</p>

        <!-- Loop nested associations correctly -->
        <cfif posts.comments().recordCount gt 0>
            <cfloop query="posts.comments()">
                <div>#posts.comments().content#</div>
            </cfloop>
        </cfif>
    </cfloop>
<cfelse>
    <p>No posts found.</p>
</cfif>

</cfoutput>
```

## Core Best Practices

### 1. Always Use cfoutput

```cfm
<!--- Correct --->
<cfoutput>
    <h1>#user.name#</h1>
</cfoutput>

<!--- Incorrect --->
<h1><cfoutput>#user.name#</cfoutput></h1>
```

### 2. Encode User Data

```cfm
<!--- Always encode user-generated content --->
<cfoutput>
    <h1>#EncodeForHtml(user.name)#</h1>
    <p>#EncodeForHtml(user.bio)#</p>
</cfoutput>
```

### 3. Use Partials for Reusability

```cfm
<!--- Extract repeated code into partials --->
<cfoutput>
    <cfloop query="users">
        #includePartial(partial="userCard", user=users)#
    </cfloop>
</cfoutput>
```

### 4. Parameter Validation

```cfm
<!--- Always validate expected variables --->
<cfparam name="user">
<cfparam name="showActions" default="true">
```

### 5. Consistent Error Handling

```cfm
<!--- Standard error display pattern --->
<cfoutput>
    #errorMessagesFor("user")#
</cfoutput>
```

### 6. Use Wheels Helpers

```cfm
<!--- Prefer Wheels helpers over raw HTML --->
<cfoutput>
    <!--- Good --->
    #linkTo(text="Edit", route="editUser", key=user.id)#

    <!--- Avoid when possible --->
    <a href="/users/#user.id#/edit">Edit</a>
</cfoutput>
```

## Security Best Practices

### HTML Encoding

```cfm
<!--- Always encode user data for HTML output --->
<cfoutput>
    <h1>#EncodeForHtml(user.name)#</h1>
    <p>Bio: #EncodeForHtml(user.bio)#</p>

    <!--- For URLs --->
    <a href="mailto:#EncodeForUrl(user.email)#">Contact</a>

    <!--- For HTML attributes --->
    <div title="#EncodeForHtmlAttribute(user.bio)#">User Info</div>
</cfoutput>
```

### CSRF Protection

```cfm
<!--- Include CSRF tokens in forms --->
<cfoutput>
#startFormTag(route="user", method="put", key=user.id)#
    <!--- CSRF token automatically included --->
    #includePartial("form")#
    #submitTag(value="Update User")#
#endFormTag()#
</cfoutput>

<!--- In layout head --->
<cfoutput>#csrfMetaTags()#</cfoutput>
```

### Input Sanitization

```cfm
<!--- Wheels helpers handle encoding automatically --->
<cfoutput>
    #linkTo(text=user.name, route="user", key=user.id)# <!--- Automatically encoded --->
    #textField(objectName="user", property="name")# <!--- Automatically encoded --->
</cfoutput>
```

## Performance Best Practices

### Query Optimization

```cfm
<!--- Store query results to avoid multiple executions --->
<cfset comments = post.comments()>
<cfif comments.recordCount gt 0>
    <h3>Comments (#comments.recordCount#)</h3>
    <cfloop query="comments">
        <div class="comment">
            #comments.content#
        </div>
    </cfloop>
</cfif>
```

### Caching

```cfm
<!--- Cache expensive partials --->
<cfoutput>
    #includePartial(partial="expensiveReport", cache=60)# <!--- Cache for 60 minutes --->
</cfoutput>
```

### Asset Optimization

```cfm
<!--- Bundle CSS and JavaScript --->
<cfoutput>
    #styleSheetLinkTag("reset.css,typography.css,application.css")#
    #javaScriptIncludeTag("jquery.js,application.js")#
</cfoutput>
```

## Organization Best Practices

### 7. Organize Views Logically

- Group related partials in controller folders
- Use `/shared/` for cross-controller partials
- Name partials descriptively (`_userCard.cfm`, not `_card.cfm`)

### File Structure Best Practices

```
/app/views/
├── layout.cfm                 (global layout)
├── helpers.cfm               (global view helpers)
├── shared/                   (cross-controller partials)
│   ├── _navigation.cfm
│   ├── _footer.cfm
│   └── _flash_messages.cfm
├── users/
│   ├── layout.cfm            (controller-specific layout)
│   ├── index.cfm
│   ├── show.cfm
│   ├── _form.cfm             (form partial)
│   └── _user_card.cfm        (display partial)
└── errors/
    ├── 404.cfm
    ├── 500.cfm
    └── forbidden.cfm
```

### Naming Conventions

- **Views**: Lowercase action names (`index.cfm`, `show.cfm`)
- **Partials**: Underscore prefix, descriptive names (`_user_card.cfm`)
- **Layouts**: `layout.cfm` in appropriate directory
- **Shared**: Use `/shared/` directory for cross-controller components

## Argument Passing Rules

**CRITICAL**: Helper functions require either positional arguments OR named arguments, but CANNOT mix both.

### Correct Usage

```cfm
<!--- All positional arguments --->
<cfoutput>
    #linkTo("Home", "users", "index")#
    #textField("user", "name")#
</cfoutput>

<!--- All named arguments --->
<cfoutput>
    #linkTo(text="Home", controller="users", action="index")#
    #textField(objectName="user", property="name")#
</cfoutput>
```

### Incorrect Usage (Will Cause Errors)

```cfm
<!--- NEVER mix positional and named arguments --->
<cfoutput>
    #linkTo("Home", controller="users", action="index")# <!--- ERROR --->
    #textField("user", property="name")# <!--- ERROR --->
</cfoutput>
```

## 🔍 POST-IMPLEMENTATION VALIDATION (REQUIRED BEFORE COMPLETION)

**After writing view code, you MUST run these checks:**

```bash
# 1. Syntax validation
wheels server start --validate

# 2. Anti-pattern detection
grep -r "ArrayLen(" app/views/  # Check for array operations on queries
grep -r "<cfloop array=" app/views/  # Check for array loops on queries
```

**Manual checklist verification:**
- [ ] No ArrayLen() calls anywhere in views
- [ ] No array loop syntax on query objects
- [ ] All query counts use .recordCount
- [ ] All loops use appropriate syntax for data type
- [ ] Proper HTML escaping in output

## Testing Best Practices

### Test Your Views

```cfm
<!--- Test partial rendering --->
component extends="wheels.Test" {
    function testUserCardPartial() {
        user = model("User").new(name="John Doe", email="john@example.com");
        result = includePartial(partial="userCard", user=user);

        assert("Find('John Doe', result) GT 0");
        assert("Find('john@example.com', result) GT 0");
    }
}
```

### Test Error Cases

```cfm
function testEmptyQueryDisplay() {
    emptyUsers = QueryNew("id,firstname,lastname,email");
    content = includePartial(partial="userList", users=emptyUsers);
    assert("Find('No users found', content) GT 0");
}
```

## Documentation and Maintenance

### Comment Complex Logic

```cfm
<cfoutput>
<!--- Complex conditional logic should be documented --->
<cfif user.isAdmin() AND user.hasPermission("users.manage") AND NOT user.isSystemAccount()>
    <!--- Only non-system admin users with user management permissions can access these controls --->
    <div class="admin-controls">
        #includePartial("admin/userControls", user=user)#
    </div>
</cfif>
</cfoutput>
```

### Keep Views Simple

```cfm
<!--- Good: Simple view logic --->
<cfoutput>
<cfif user.isActive()>
    <span class="status active">Active</span>
<cfelse>
    <span class="status inactive">Inactive</span>
</cfif>
</cfoutput>

<!--- Better: Move complex logic to helpers --->
<cfoutput>
    #userStatusBadge(user)#
</cfoutput>
```

This comprehensive approach ensures your views are secure, performant, maintainable, and follow CFWheels best practices.