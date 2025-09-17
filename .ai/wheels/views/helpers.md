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

## Best Practices

1. **Keep helpers simple**: Each helper should do one thing well
2. **Use meaningful names**: `formatCurrency()` instead of `format()`
3. **Provide defaults**: Use default parameters for optional arguments
4. **Return safe HTML**: Encode user input within helpers
5. **Document complex helpers**: Add comments for non-obvious functionality
6. **Test helpers**: Write unit tests for complex helper functions