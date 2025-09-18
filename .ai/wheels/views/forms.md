# Forms and CRUD Patterns

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

## Form Helpers

### Basic Form Structure

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

## ⚠️ CRITICAL: Form Helper Limitations

**Duplicate Label Prevention:**
CFWheels form helpers automatically generate labels. When using custom HTML labels, you MUST disable automatic labels to prevent duplication.

```cfm
<!-- ❌ INCORRECT - Creates duplicate labels -->
<div>
    <label for="post-title">Title</label>
    #textField(objectName="post", property="title")#  <!-- Also generates a label -->
</div>

<!-- ✅ CORRECT - Use label=false with custom labels -->
<div>
    <label for="post-title" class="custom-style">Title</label>
    #textField(objectName="post", property="title", label=false)#
</div>

<!-- ✅ ALTERNATIVE - Use CFWheels' built-in labels -->
<div>
    #textField(objectName="post", property="title", label="Title")#
</div>
```

**Label Helper Issues:**
The `label()` helper in CFWheels does NOT accept a `text` parameter like in Rails:

```cfm
<!-- ❌ INCORRECT - This will cause errors -->
#label(objectName="user", property="email", text="Email Address")#

<!-- ✅ CORRECT - Use standard HTML labels with label=false -->
<label for="user-email">Email Address</label>
#textField(objectName="user", property="email", label=false)#
```

**Email Field Limitation:**
CFWheels does NOT have an `emailField()` helper:

```cfm
<!-- ❌ INCORRECT - emailField() doesn't exist -->
#emailField(objectName="user", property="email")#

<!-- ✅ CORRECT - Use textField() for all input types -->
#textField(objectName="user", property="email")#

<!-- ✅ ALTERNATIVE - Add HTML5 type attribute if needed -->
#textField(objectName="user", property="email", type="email")#
```

**Password Field Limitation:**
CFWheels does NOT have a `passwordField()` helper:

```cfm
<!-- ❌ INCORRECT - passwordField() doesn't exist -->
#passwordField(objectName="user", property="password")#

<!-- ✅ CORRECT - Use textField() with type attribute -->
#textField(objectName="user", property="password", type="password")#
```

## 🚨 CRITICAL: HTML Encoding in Form Labels

**When adding HTML content to form labels (icons, styling, etc.), use `encode=false`:**

```cfm
<!-- ❌ WRONG: Shows literal HTML text -->
#textField(objectName="user", property="email", label="<i class='icon-email'></i> Email Address")#
<!-- Output label: <i class='icon-email'></i> Email Address -->

<!-- ✅ CORRECT: Renders HTML in label -->
#textField(objectName="user", property="email", label="<i class='icon-email'></i> Email Address", encode=false)#
<!-- Output label: [EMAIL_ICON] Email Address -->
```

**This applies to ALL form helpers with labels:**
- `textField()`, `textArea()`, `checkBox()`, `radioButton()`, `select()`, etc.

**See complete documentation:** [View Helpers - HTML Encoding](./helpers.md#🚨-critical-html-encoding-in-view-helpers)

## Recommended Form Helper Pattern

For maximum compatibility and to prevent duplicate labels, use this pattern:

```cfm
<cfoutput>
#startFormTag(route="users", method="post")#

    <!-- Use HTML labels with label=false to prevent duplicates -->
    <div class="form-group">
        <label for="user-firstName">First Name *</label>
        #textField(objectName="user", property="firstName", label=false, class="form-control")#
        #errorMessageOn(objectName="user", property="firstName")#
    </div>

    <div class="form-group">
        <label for="user-email">Email Address *</label>
        #textField(objectName="user", property="email", label=false, type="email", class="form-control")#
        #errorMessageOn(objectName="user", property="email")#
    </div>

    <div class="form-group">
        <label for="user-password">Password *</label>
        #textField(objectName="user", property="password", label=false, type="password", class="form-control")#
        #errorMessageOn(objectName="user", property="password")#
    </div>

    <div class="form-group">
        <label for="user-bio">Biography</label>
        #textArea(objectName="user", property="bio", label=false, class="form-control", rows="5")#
        #errorMessageOn(objectName="user", property="bio")#
    </div>

    #submitTag(value="Save User", class="btn btn-primary")#

#endFormTag()#
</cfoutput>
```

## Error Handling in Forms

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

## 🚨 CRITICAL: buttonTo() HTTP Method Requirements

**The `buttonTo()` helper REQUIRES explicit `method` parameter for non-GET requests to generate proper HTTP verbs.**

### Common Delete Button Error Pattern

**❌ INCORRECT - Missing method parameter (causes RouteNotFound errors):**
```cfm
<!-- This generates POST request, not DELETE -->
#buttonTo(controller="posts", action="delete", key=post.id, text="Delete", confirm="Are you sure?")#

<!-- Error: "Wheels.RouteNotFound - path does not allow POST requests, only GET, PATCH, PUT, DELETE" -->
```

**✅ CORRECT - Include method="delete" parameter:**
```cfm
<!-- This generates proper DELETE request -->
#buttonTo(controller="posts", action="delete", method="delete", key=post.id, text="Delete", confirm="Are you sure?")#
```

### HTTP Method Requirements for buttonTo()

```cfm
<!-- POST requests (default if no method specified) -->
#buttonTo(controller="posts", action="create", text="Create Post")#

<!-- PUT/PATCH requests -->
#buttonTo(controller="posts", action="update", method="put", key=post.id, text="Update")#
#buttonTo(controller="posts", action="update", method="patch", key=post.id, text="Update")#

<!-- DELETE requests -->
#buttonTo(controller="posts", action="delete", method="delete", key=post.id, text="Delete")#
#buttonTo(controller="comments", action="delete", method="delete", key=comment.id, text="Delete")#
```

### Why This Matters

CFWheels resource routing expects specific HTTP methods:
- `GET /posts` → `index()` action
- `POST /posts` → `create()` action
- `GET /posts/1` → `show()` action
- `PUT/PATCH /posts/1` → `update()` action
- `DELETE /posts/1` → `delete()` action

**Without the `method` parameter, `buttonTo()` defaults to POST, causing route mismatches.**

### Testing Delete Functionality

Always test delete functionality in the browser to ensure:
- [ ] No "RouteNotFound" errors occur
- [ ] Proper flash messages appear ("Post deleted successfully!")
- [ ] Correct redirects happen (back to index or show page)
- [ ] Confirmation dialogs work (`confirm="Are you sure?"` parameter)