# View Helpers and Helper Functions

## Common View Helpers

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

## Helper Functions Access

Views have access to all Wheels helper functions and can include view-specific helpers.

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

function timeAgo(required date datetime) {
    local.diff = DateDiff("n", arguments.datetime, Now());

    if (local.diff < 1) {
        return "just now";
    } else if (local.diff < 60) {
        return "#local.diff# minute#(local.diff == 1 ? '' : 's')# ago";
    } else if (local.diff < 1440) {
        local.hours = Int(local.diff / 60);
        return "#local.hours# hour#(local.hours == 1 ? '' : 's')# ago";
    } else {
        local.days = Int(local.diff / 1440);
        return "#local.days# day#(local.days == 1 ? '' : 's')# ago";
    }
}

function displayRole(required user) {
    if (arguments.user.isAdmin()) {
        return "<span class='badge badge-danger'>Admin</span>";
    } else if (arguments.user.isModerator()) {
        return "<span class='badge badge-warning'>Moderator</span>";
    } else {
        return "<span class='badge badge-secondary'>User</span>";
    }
}

function pluralize(required numeric count, required string singular, string plural = "") {
    if (arguments.count == 1) {
        return arguments.singular;
    } else {
        return Len(arguments.plural) ? arguments.plural : arguments.singular & "s";
    }
}
</cfscript>
```

### Using Custom Helpers

```cfm
<cfoutput>
    <p>Price: #formatCurrency(product.price)#</p>
    <img src="#userAvatarUrl(user)#" alt="User Avatar">
    <p>Posted #timeAgo(post.createdAt)#</p>
    <p>Role: #displayRole(user)#</p>
    <p>You have #pluralize(user.orders().recordCount, "order")#</p>
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

## Conditional Content

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

## Asset Optimization

```cfm
<!--- Bundle CSS and JavaScript --->
<cfoutput>
    #styleSheetLinkTag("reset.css,typography.css,application.css")#
    #javaScriptIncludeTag("jquery.js,application.js")#
</cfoutput>
```

## Helper Function Examples

### Navigation Helper

```cfm
<cfscript>
function navigationLink(required string text, required string route, string key = "", string cssClass = "") {
    local.isActive = (params.controller == arguments.route ||
                     (params.action == arguments.route && params.controller == "pages"));

    local.classes = arguments.cssClass;
    if (local.isActive) {
        local.classes = ListAppend(local.classes, "active", " ");
    }

    if (Len(arguments.key)) {
        return linkTo(text=arguments.text, route=arguments.route, key=arguments.key, class=local.classes);
    } else {
        return linkTo(text=arguments.text, route=arguments.route, class=local.classes);
    }
}
</cfscript>
```

### Form Helper Extensions

```cfm
<cfscript>
function requiredField(required string objectName, required string property, string label = "", string type = "text") {
    local.labelText = Len(arguments.label) ? arguments.label : Humanize(arguments.property);
    local.fieldHtml = textField(objectName=arguments.objectName, property=arguments.property, type=arguments.type, class="form-control");
    local.errorHtml = errorMessageOn(objectName=arguments.objectName, property=arguments.property);

    return '<div class="form-group">
        <label for="#arguments.objectName#-#arguments.property#">#local.labelText# *</label>
        #local.fieldHtml#
        #local.errorHtml#
    </div>';
}

function optionalField(required string objectName, required string property, string label = "", string type = "text") {
    local.labelText = Len(arguments.label) ? arguments.label : Humanize(arguments.property);
    local.fieldHtml = textField(objectName=arguments.objectName, property=arguments.property, type=arguments.type, class="form-control");
    local.errorHtml = errorMessageOn(objectName=arguments.objectName, property=arguments.property);

    return '<div class="form-group">
        <label for="#arguments.objectName#-#arguments.property#">#local.labelText#</label>
        #local.fieldHtml#
        #local.errorHtml#
    </div>';
}
</cfscript>
```

### Status Helper

```cfm
<cfscript>
function statusBadge(required string status) {
    switch (arguments.status) {
        case "active":
            return "<span class='badge badge-success'>Active</span>";
        case "inactive":
            return "<span class='badge badge-secondary'>Inactive</span>";
        case "pending":
            return "<span class='badge badge-warning'>Pending</span>";
        case "suspended":
            return "<span class='badge badge-danger'>Suspended</span>";
        default:
            return "<span class='badge badge-light'>#arguments.status#</span>";
    }
}
</cfscript>
```

## 🚨 CRITICAL: HTML Encoding in View Helpers

### Understanding the `encode` Attribute

**Most CFWheels view helpers have an `encode` attribute that controls HTML rendering:**

- **`encode=true`** (DEFAULT): HTML tags are escaped and displayed as literal text
- **`encode=false`**: HTML tags are rendered as actual HTML

### Common Use Cases for `encode=false`

#### 1. Links with HTML Content
```cfm
<!-- ❌ WRONG: Shows literal HTML text -->
#linkTo(controller="posts", action="index", text="<span class='logo'>My Blog</span>")#
<!-- Output: <span class='logo'>My Blog</span> -->

<!-- ✅ CORRECT: Renders HTML properly -->
#linkTo(controller="posts", action="index", text="<span class='logo'>My Blog</span>", encode=false)#
<!-- Output: My Blog (with logo styling) -->
```

#### 2. Form Labels with Icons
```cfm
<!-- ❌ WRONG: Shows literal HTML -->
#textField(objectName="user", property="email", label="<i class='icon-email'></i> Email Address")#

<!-- ✅ CORRECT: Renders icon -->
#textField(objectName="user", property="email", label="<i class='icon-email'></i> Email Address", encode=false)#
```

#### 3. Buttons with HTML Content
```cfm
<!-- ❌ WRONG: Shows literal HTML -->
#buttonTo(text="<i class='icon-delete'></i> Delete", controller="posts", action="delete", key=post.id)#

<!-- ✅ CORRECT: Renders icon in button -->
#buttonTo(text="<i class='icon-delete'></i> Delete", controller="posts", action="delete", key=post.id, encode=false)#
```

#### 4. Submit Tags with Icons
```cfm
<!-- ❌ WRONG: Shows literal HTML -->
#submitTag(value="<i class='icon-save'></i> Save Post")#

<!-- ✅ CORRECT: Renders icon -->
#submitTag(value="<i class='icon-save'></i> Save Post", encode=false)#
```

### 🔍 View Helpers That Support `encode` Attribute

**Common helpers with `encode` support:**
- `linkTo()` - Links and navigation
- `buttonTo()` - Form buttons
- `submitTag()` - Submit buttons
- `textField()` - Input labels
- `textArea()` - Textarea labels
- `checkBox()` - Checkbox labels
- `radioButton()` - Radio button labels
- `select()` - Select field labels

### ⚠️ Security Considerations

**When using `encode=false`, ensure HTML content is safe:**

```cfm
<!-- ✅ SAFE: Static HTML from developer -->
#linkTo(text="<span class='brand'>Tech Blog</span>", encode=false)#

<!-- ⚠️ DANGEROUS: User-provided content (potential XSS) -->
#linkTo(text="<span>#user.displayName#</span>", encode=false)# <!-- DON'T DO THIS -->

<!-- ✅ SAFE: Sanitize user content first -->
#linkTo(text="<span>#HTMLEditFormat(user.displayName)#</span>", encode=false)#
```

### 🧪 Testing HTML Encoding

**Always test HTML rendering with browser testing:**

```javascript
// Test that HTML renders correctly
mcp__puppeteer__puppeteer_screenshot(name="html_rendering_test")

// Verify no literal HTML tags are visible
// Check that styling/icons appear as expected
```

### 📋 Quick Reference Checklist

**When adding HTML to view helper `text` or `value` attributes:**

- [ ] Are you using static HTML (safe) or user content (potentially unsafe)?
- [ ] Have you added `encode=false` to render the HTML?
- [ ] If using user content, have you sanitized it with `HTMLEditFormat()`?
- [ ] Have you tested the rendering with browser testing?
- [ ] Does the HTML display correctly (not as literal text)?

### Common Patterns

#### Navigation with Icons
```cfm
<nav>
    #linkTo(text="<i class='home-icon'></i> Home", controller="home", encode=false)#
    #linkTo(text="<i class='blog-icon'></i> Blog", controller="posts", encode=false)#
    #linkTo(text="<i class='contact-icon'></i> Contact", controller="contact", encode=false)#
</nav>
```

#### Form Buttons with Icons
```cfm
#startFormTag()#
    <!-- Form fields -->
    <div class="form-actions">
        #submitTag(value="<i class='save-icon'></i> Save", class="btn btn-primary", encode=false)#
        #linkTo(text="<i class='cancel-icon'></i> Cancel", controller="posts", class="btn btn-secondary", encode=false)#
    </div>
#endFormTag()#
```

#### Branded Links
```cfm
<header>
    #linkTo(controller="posts", action="index", text="<span class='logo-text'>My Amazing Blog</span>", encode=false)#
</header>
```

## Best Practices

1. **Keep helpers simple**: Each helper should do one thing well
2. **Use meaningful names**: `formatCurrency()` instead of `format()`
3. **Provide defaults**: Use default parameters for optional arguments
4. **Return safe HTML**: Encode user input within helpers, use `encode=false` for trusted HTML
5. **Document complex helpers**: Add comments for non-obvious functionality
6. **Test helpers**: Write unit tests for complex helper functions
7. **Always test HTML rendering**: Use browser testing to verify `encode=false` works correctly