# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with view files in a Wheels application.

## 🚨 CRITICAL: PRE-VIEW IMPLEMENTATION CHECKLIST 🚨

### 🛑 MANDATORY DOCUMENTATION READING (COMPLETE BEFORE ANY CODE)

**YOU MUST READ THESE FILES IN ORDER:**

✅ **Step 1: Error Prevention (ALWAYS FIRST)**
- [ ] `.ai/wheels/troubleshooting/common-errors.md` - PREVENT FATAL ERRORS
- [ ] `.ai/wheels/patterns/validation-templates.md` - VIEW CHECKLIST

✅ **Step 2: View-Specific Documentation**
- [ ] `.ai/wheels/views/layouts/structure.md` - Layout patterns
- [ ] `.ai/cfml/control-flow/loops.md` - Loop syntax (QUERY vs ARRAY)
- [ ] `.ai/wheels/views/helpers/forms.md` - Form helpers

### 🔴 CRITICAL ANTI-PATTERN CHECK (MUST VERIFY BEFORE WRITING)

**Before writing ANY view code, verify you will NOT:**
- [ ] ❌ Use ArrayLen() on queries: `ArrayLen(posts)` or `ArrayLen(post.comments())`
- [ ] ❌ Loop queries as arrays: `<cfloop array="#posts#" index="post">`
- [ ] ❌ Treat model results as arrays in any context
- [ ] ❌ Mix loop types (array syntax on queries)

**And you WILL:**
- [ ] ✅ Use .recordCount for query counts: `posts.recordCount`
- [ ] ✅ Use query loops: `<cfloop query="posts">`
- [ ] ✅ Understand associations return QUERIES
- [ ] ✅ Check data types before processing

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

### 🔍 POST-IMPLEMENTATION VALIDATION (REQUIRED BEFORE COMPLETION)

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

## Overview

Views in Wheels are template files that generate the HTML (or other content) that users see in their browsers. They follow the MVC (Model-View-Controller) pattern where the controller sets up data and the view handles presentation. Views are written in CFML and can include HTML, CSS, JavaScript, and any other content type.

## 🚨 CRITICAL: CFWheels Data Types in Views

**CFWheels associations and model methods return QUERIES, not ARRAYS. This is the #2 most common view error.**

### ❌ WRONG - Treating Queries as Arrays
```cfm
<!--- Model associations return queries, NOT arrays --->
<cfset commentCount = ArrayLen(post.comments())>  <!-- ERROR! -->
<cfset userCount = ArrayLen(model("User").findAll())>  <!-- ERROR! -->

<!--- Can't loop queries as arrays --->
<cfloop array="#post.comments()#" index="comment">  <!-- ERROR! -->
    #comment.content#
</cfloop>
```

### ✅ CORRECT - Using Query Methods and Loops
```cfm
<!--- Use .recordCount for query record counts --->
<cfset commentCount = post.comments().recordCount>
<cfset userCount = model("User").findAll().recordCount>

<!--- Loop queries with query="..." --->
<cfset comments = post.comments()>
<cfloop query="comments">
    #comments.content#  <!--- Access fields directly from query --->
</cfloop>

<!--- Check if query has records --->
<cfif post.comments().recordCount gt 0>
    <cfloop query="post.comments()">
        <p>#post.comments().content#</p>
    </cfloop>
<cfelse>
    <p>No comments found.</p>
</cfif>
```

### 📊 Query vs Array Reference

| **Data Type** | **Count Method** | **Loop Method** | **Check if Empty** |
|---------------|------------------|-----------------|-------------------|
| **Query** | `.recordCount` | `<cfloop query="...">` | `query.recordCount gt 0` |
| **Array** | `ArrayLen()` | `<cfloop array="...">` | `ArrayLen(array) gt 0` |

### Common View Patterns - CORRECT Examples
```cfm
<!--- Association counts --->
<cfset postCount = user.posts().recordCount>
<cfset commentCount = post.comments().recordCount>

<!--- Association loops --->
<cfloop query="user.posts()">
    <h3>#user.posts().title#</h3>
</cfloop>

<!--- Model finder results --->
<cfset users = model("User").findAll()>
<cfif users.recordCount gt 0>
    <cfloop query="users">
        <p>#users.name# - #users.email#</p>
    </cfloop>
</cfif>

<!--- Conditional display based on associations --->
<cfif post.comments().recordCount gt 0>
    <h3>Comments (#post.comments().recordCount#)</h3>
    <cfloop query="post.comments()">
        <div class="comment">
            <strong>#post.comments().author#:</strong>
            #post.comments().content#
        </div>
    </cfloop>
<cfelse>
    <p>No comments yet.</p>
</cfif>
```

**⚡ MEMORY RULE**: In CFWheels views, if it comes from a model (associations, finders), it's a QUERY. Use `.recordCount` and `<cfloop query="...">`.

## File Structure and Conventions

### View File Location
- All view files are stored in `/app/views/`
- Each controller gets its own subfolder: `/app/views/[controller-name]/`
- View files use `.cfm` extension (not `.cfc`)
- Standard action views are named after the action: `/app/views/users/show.cfm`

### Naming Conventions
- **Actions**: Named after controller actions (`index.cfm`, `show.cfm`, `new.cfm`, `edit.cfm`)
- **Partials**: Start with underscore (`_form.cfm`, `_user.cfm`, `_navigation.cfm`)
- **Layouts**: Named `layout.cfm` (controller-specific) or placed in `/app/views/layout.cfm` (global)
- **Shared views**: Place in `/app/views/shared/` for cross-controller use

### File Structure Example
```
/app/views/
├── layout.cfm                 (global layout)
├── helpers.cfm               (global view helpers)
├── users/
│   ├── layout.cfm            (users controller layout)
│   ├── index.cfm             (users#index action)
│   ├── show.cfm              (users#show action)
│   ├── new.cfm               (users#new action)
│   ├── edit.cfm              (users#edit action)
│   └── _form.cfm             (partial for user form)
├── shared/
│   ├── _navigation.cfm       (shared navigation partial)
│   └── _footer.cfm           (shared footer partial)
└── emails/
    └── usermailer/
        └── welcome.cfm       (email template)
```

## Basic View Structure

### Simple View Example
```cfm
<!--- /app/views/users/show.cfm --->
<cfparam name="user">
<cfoutput>
<h1>User Profile</h1>
<div class="user-details">
    <h2>#EncodeForHtml(user.name)#</h2>
    <p>Email: #EncodeForHtml(user.email)#</p>
    <p>Created: #DateFormat(user.createdAt, "mmmm dd, yyyy")#</p>
</div>

<div class="actions">
    #linkTo(text="Edit User", route="editUser", key=user.id)#
    #linkTo(text="All Users", route="users")#
</div>
</cfoutput>
```

### Basic HTML Structure
```cfm
<!--- Always wrap output in cfoutput tags --->
<cfoutput>
    <!-- Your HTML content here -->
    <h1>#pageTitle#</h1>
    <p>#user.description#</p>
</cfoutput>
```

## Layouts

### Global Layout
The default layout at `/app/views/layout.cfm` wraps all views unless overridden:

```cfm
<!--- /app/views/layout.cfm --->
<cfif application.contentOnly>
    <cfoutput>
        #flashMessages()#
        #includeContent()#
    </cfoutput>
<cfelse>
    <html>
        <head>
            <title>My App</title>
            <cfoutput>#csrfMetaTags()#</cfoutput>
        </head>
        <body>
            <cfoutput>
                #flashMessages()#
                #includeContent()#
            </cfoutput>
        </body>
    </html>
</cfif>
```

### Controller-Specific Layout
Create `/app/views/[controller]/layout.cfm` to override global layout:

```cfm
<!--- /app/views/admin/layout.cfm --->
<cfoutput>
<html>
    <head>
        <title>Admin Panel</title>
        #csrfMetaTags()#
    </head>
    <body class="admin">
        <nav class="admin-nav">
            #includePartial("/shared/adminNav")#
        </nav>
        <main>
            #flashMessages()#
            #includeContent()#
        </main>
    </body>
</html>
</cfoutput>
```

### Using Different Layouts
Override layout in controller action:
```cfm
// In controller
function display() {
    renderView(layout="visitorLayout");
}
```

### Nested Layouts
Use `includeLayout()` and `contentFor()` for layout inheritance:

```cfm
<!--- Child layout --->
<cfscript>
    contentFor(pageTitle="My Custom Title");
</cfscript>
<cfoutput>#includeLayout("layout")#</cfoutput>

<!--- Parent layout --->
<html>
    <head>
        <title><cfoutput>#includeContent("pageTitle")#</cfoutput></title>
    </head>
    <body>
        <cfoutput>#includeContent()#</cfoutput>
    </body>
</html>
```

## Partials

Partials are reusable view components that help keep code DRY and organized.

### Basic Partial Usage
```cfm
<!--- Include a partial --->
<cfoutput>
    #includePartial("form")#
    #includePartial("/shared/navigation")#
</cfoutput>
```

### Partial with Data
```cfm
<!--- Pass data to partial --->
<cfoutput>
    #includePartial(partial="userCard", user=currentUser, showActions=true)#
</cfoutput>

<!--- _userCard.cfm partial --->
<cfparam name="arguments.user">
<cfparam name="arguments.showActions" default="false">
<cfoutput>
<div class="user-card">
    <h3>#EncodeForHtml(arguments.user.name)#</h3>
    <p>#EncodeForHtml(arguments.user.email)#</p>
    <cfif arguments.showActions>
        <div class="actions">
            #linkTo(text="Edit", route="editUser", key=arguments.user.id)#
        </div>
    </cfif>
</div>
</cfoutput>
```

### Partials with Objects
```cfm
<!--- Pass object to partial - automatically creates variables --->
<cfset user = model("user").findByKey(params.key)>
<cfoutput>#includePartial(user)#</cfoutput>

<!--- _user.cfm partial can access user properties directly --->
<cfoutput>
<div class="user">
    <h3>#EncodeForHtml(name)#</h3>
    <p>#EncodeForHtml(email)#</p>
    <!-- arguments.object also available for direct access -->
</div>
</cfoutput>
```

### Partials with Queries
```cfm
<!--- Loop through query with partial --->
<cfset users = model("user").findAll()>
<cfoutput>
<div class="users">
    #includePartial(partial="user", query=users)#
</div>
</cfoutput>

<!--- With spacer between items --->
<cfoutput>
<ul>
    <li>#includePartial(partial="user", query=users, spacer="</li><li>")#</li>
</ul>
</cfoutput>
```

### Partials with Layouts
```cfm
<!--- Partial with its own layout --->
<cfoutput>
    #includePartial(partial="newsItem", layout="/boxes/blue")#
</cfoutput>

<!--- /app/views/boxes/_blue.cfm --->
<cfoutput>
<div class="news-box blue">
    #includeContent()#
</div>
</cfoutput>
```

## Form Views and CRUD Patterns

### CRUD View Structure
```cfm
<!--- Index view - /app/views/users/index.cfm --->
<cfparam name="users">
<cfoutput>
<h1>Users</h1>
<p>#linkTo(route="newUser", text="Create New User", class="btn btn-primary")#</p>

<cfif users.recordcount>
    <table class="table">
        <thead>
            <tr>
                <th>ID</th>
                <th>Name</th>
                <th>Email</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            <cfloop query="users">
            <tr>
                <td>#id#</td>
                <td>#EncodeForHtml(name)#</td>
                <td>#EncodeForHtml(email)#</td>
                <td>
                    #linkTo(route="user", key=id, text="View", class="btn btn-info")#
                    #linkTo(route="editUser", key=id, text="Edit", class="btn btn-primary")#
                    #buttonTo(route="user", method="delete", key=id, text="Delete", 
                              class="btn btn-danger", confirm="Are you sure?")#
                </td>
            </tr>
            </cfloop>
        </tbody>
    </table>
<cfelse>
    <p>No users found.</p>
</cfif>
</cfoutput>
```

### Form Partial Pattern
```cfm
<!--- _form.cfm partial --->
<cfparam name="user">
<cfoutput>
<div class="form-group">
    #textField(objectName="user", property="name", label="Name:", class="form-control")#
</div>
<div class="form-group">
    #emailField(objectName="user", property="email", label="Email:", class="form-control")#
</div>
<div class="form-group">
    #textArea(objectName="user", property="bio", label="Bio:", class="form-control")#
</div>
</cfoutput>

<!--- New form - /app/views/users/new.cfm --->
<cfparam name="user">
<cfoutput>
<h1>Create New User</h1>
#errorMessagesFor("user")#
#startFormTag(action="create")#
    #includePartial("form")#
    #submitTag(value="Create User", class="btn btn-primary")#
#endFormTag()#
</cfoutput>

<!--- Edit form - /app/views/users/edit.cfm --->
<cfparam name="user">
<cfoutput>
<h1>Edit User</h1>
#errorMessagesFor("user")#
#startFormTag(route="user", method="patch", key=user.id)#
    #includePartial("form")#
    #submitTag(value="Update User", class="btn btn-primary")#
#endFormTag()#
</cfoutput>
```

## View Helpers and Form Helpers

### Common View Helpers
```cfm
<cfoutput>
<!-- Links -->
#linkTo(text="Home", route="root")#
#linkTo(text="User Profile", route="user", key=5)#
#linkTo(text="External Link", href="https://example.com")#

<!-- Assets -->
#imageTag(source="logo.png", alt="Company Logo")#
#styleSheetLinkTag("application.css")#
#javaScriptIncludeTag("application.js")#

<!-- Text helpers -->
#capitalize(user.name)#
#truncate(text=article.body, length=100)#
#excerpt(text=article.body, phrase="Wheels", radius=50)#

<!-- Date helpers -->
#dateTimeSelect(objectName="article", property="publishedAt")#
#dateSelect(objectName="user", property="birthday")#
</cfoutput>
```

### Form Helpers
```cfm
<cfoutput>
#startFormTag(route="users", method="post")#

    <!-- Text inputs -->
    #textField(objectName="user", property="name", label="Full Name:")#
    #emailField(objectName="user", property="email", label="Email Address:")#
    #passwordField(objectName="user", property="password", label="Password:")#
    #hiddenField(objectName="user", property="id")#

    <!-- Text areas -->
    #textArea(objectName="user", property="bio", label="Biography:")#

    <!-- Checkboxes and radios -->
    #checkBox(objectName="user", property="active", label="Active User")#
    #radioButton(objectName="user", property="type", tagValue="admin", label="Administrator")#
    #radioButton(objectName="user", property="type", tagValue="user", label="Regular User")#

    <!-- Select dropdowns -->
    #select(objectName="user", property="countryId", 
            options=countries, textField="name", valueField="id", 
            label="Country:")#

    <!-- File uploads -->
    #fileField(objectName="user", property="avatar", label="Profile Picture:")#

    <!-- Submit button -->
    #submitTag(value="Save User", class="btn btn-primary")#

#endFormTag()#
</cfoutput>
```

### Error Handling in Forms
```cfm
<cfoutput>
<!-- Display all errors for an object -->
#errorMessagesFor("user")#

<!-- Display error for specific property -->
#errorMessageOn(objectName="user", property="email")#

<!-- Custom error styling -->
<div class="form-group #errorClass(objectName='user', property='name')#">
    #textField(objectName="user", property="name", label="Name:")#
    #errorMessageOn(objectName="user", property="name")#
</div>
</cfoutput>
```

## Content Types and Format-Specific Views

### Multiple Format Support
```cfm
<!--- Controller provides formats --->
function config() {
    provides("html,json,xml");
}

<!--- Default view: show.cfm --->
<cfoutput>
<h1>User: #user.name#</h1>
<p>Email: #user.email#</p>
</cfoutput>

<!--- JSON view: show.json.cfm --->
<cfoutput>
#renderWith(user)#
</cfoutput>

<!--- XML view: show.xml.cfm --->
<cfoutput>
#renderWith(user, xml=true)#
</cfoutput>
```

## Data Access in Views

### Variable Scoping
```cfm
<!--- Variables set in controller are available unscoped --->
<cfoutput>
    <h1>#pageTitle#</h1>  <!--- Set as variables.pageTitle in controller --->
    <p>User: #user.name#</p>  <!--- Set as variables.user in controller --->
</cfoutput>

<!--- Access params struct (though controller should handle this) --->
<cfoutput>
    <p>Current page: #params.page#</p>
</cfoutput>
```

### Data Validation and Security
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

<!--- Wheels helpers handle encoding automatically --->
<cfoutput>
    #linkTo(text=user.name, route="user", key=user.id)# <!--- Automatically encoded --->
    #textField(objectName="user", property="name")# <!--- Automatically encoded --->
</cfoutput>
```

## Flash Messages and Session Data

### Flash Messages
```cfm
<!--- Display flash messages in layout --->
<cfoutput>
    #flashMessages()#
</cfoutput>

<!--- Custom flash message display --->
<cfif flashKeyExists("success")>
    <cfoutput>
    <div class="alert alert-success">
        #flash("success")#
    </div>
    </cfoutput>
</cfif>

<cfif flashKeyExists("error")>
    <cfoutput>
    <div class="alert alert-danger">
        #flash("error")#
    </div>
    </cfoutput>
</cfif>
```

## Advanced View Patterns

### Content Sections
```cfm
<!--- Define content sections in views --->
<cfscript>
    contentFor(head="<link rel='stylesheet' href='user-styles.css'>");
    contentFor(pageTitle="User Profile - " & user.name);
</cfscript>

<!--- Use in layout --->
<html>
    <head>
        <title><cfoutput>#includeContent("pageTitle")#</cfoutput></title>
        <cfoutput>#includeContent("head")#</cfoutput>
    </head>
    <body>
        <cfoutput>#includeContent()#</cfoutput>
    </body>
</html>
```

### Conditional Content
```cfm
<cfoutput>
<div class="user-profile">
    <h1>#EncodeForHtml(user.name)#</h1>
    
    <cfif user.isActive()>
        <span class="status active">Active</span>
    <cfelse>
        <span class="status inactive">Inactive</span>
    </cfif>
    
    <cfif user.hasPermission("admin")>
        <div class="admin-actions">
            #linkTo(text="Admin Panel", route="adminUsers")#
        </div>
    </cfif>
</div>
</cfoutput>
```

### AJAX and Partial Updates
```cfm
<!--- Render partial for AJAX responses --->
<!--- In controller action --->
function updateUser() {
    user = model("user").findByKey(params.id);
    user.update(params.user);
    renderPartial(user); // Returns just the partial HTML
}

<!--- _user.cfm partial for AJAX updates --->
<cfparam name="arguments.user">
<cfoutput>
<div id="user-#arguments.user.id#" class="user-card">
    <h3>#EncodeForHtml(arguments.user.name)#</h3>
    <p>#EncodeForHtml(arguments.user.email)#</p>
    <p>Last updated: #TimeFormat(Now())#</p>
</div>
</cfoutput>
```

## Performance and Caching

### Caching Partials
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

## Testing Views

### View Helper Testing
```cfm
<!--- In test files --->
component extends="BaseSpec" {
    function run() {
        describe("User view", function() {
            beforeEach(function() {
                user = model("user").new(name="John Doe", email="john@example.com");
            });

            it("should display user information", function() {
                result = includePartial(partial="user", user=user);
                expect(result).toInclude("John Doe");
                expect(result).toInclude("john@example.com");
            });
        });
    }
}
```

## Common Patterns and Best Practices

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

### 7. Organize Views Logically
- Group related partials in controller folders
- Use `/shared/` for cross-controller partials
- Name partials descriptively (`_userCard.cfm`, not `_card.cfm`)

## Helper Functions Access

Views have access to all Wheels helper functions and can include view-specific helpers:

### Global View Helpers
Place common helpers in `/app/views/helpers.cfm`:

```cfm
<!--- /app/views/helpers.cfm --->
<cfscript>
// Custom helper functions available in all views
function formatCurrency(required numeric amount) {
    return DollarFormat(arguments.amount);
}

function userAvatarUrl(required user) {
    if (arguments.user.hasAvatar()) {
        return "/uploads/avatars/" & arguments.user.avatar;
    } else {
        return "/images/default-avatar.png";
    }
}
</cfscript>
```

### Using Custom Helpers
```cfm
<cfoutput>
    <p>Price: #formatCurrency(product.price)#</p>
    <img src="#userAvatarUrl(user)#" alt="User Avatar">
</cfoutput>
```

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

This is a Wheels framework requirement that applies to all helper functions including form helpers, link helpers, and custom application helpers.