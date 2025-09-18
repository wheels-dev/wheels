# Partials in CFWheels

## Overview

Partials are reusable view components that help keep code DRY and organized. They allow you to extract common UI elements into separate files that can be included in multiple views.

## Basic Partial Usage

```cfm
<!--- Include a partial --->
<cfoutput>
    #includePartial("form")#
    #includePartial("/shared/navigation")#
</cfoutput>
```

## Partial with Data

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

## Partials with Objects

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

## Partials with Queries

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

## Partials with Layouts

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

## AJAX and Partial Updates

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

## Caching Partials

```cfm
<!--- Cache expensive partials --->
<cfoutput>
    #includePartial(partial="expensiveReport", cache=60)# <!--- Cache for 60 minutes --->
</cfoutput>
```

## Common Partial Patterns

### Navigation Partial

```cfm
<!--- /app/views/shared/_navigation.cfm --->
<cfoutput>
<nav class="main-navigation">
    <ul>
        <li>#linkTo(route="root", text="Home")#</li>
        <li>#linkTo(route="users", text="Users")#</li>
        <li>#linkTo(route="products", text="Products")#</li>
        <cfif session.authenticated>
            <li>#linkTo(route="logout", text="Logout")#</li>
        <cfelse>
            <li>#linkTo(route="login", text="Login")#</li>
        </cfif>
    </ul>
</nav>
</cfoutput>
```

### Form Partial

```cfm
<!--- /app/views/users/_form.cfm --->
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
```

### Card Partial

```cfm
<!--- /app/views/shared/_card.cfm --->
<cfparam name="arguments.title">
<cfparam name="arguments.content">
<cfparam name="arguments.actions" default="">
<cfoutput>
<div class="card">
    <div class="card-header">
        <h3>#EncodeForHtml(arguments.title)#</h3>
    </div>
    <div class="card-body">
        #arguments.content#
    </div>
    <cfif Len(arguments.actions)>
        <div class="card-footer">
            #arguments.actions#
        </div>
    </cfif>
</div>
</cfoutput>
```

## Best Practices

1. **Use descriptive names**: `_userCard.cfm` instead of `_card.cfm`
2. **Validate parameters**: Use `<cfparam>` for required variables
3. **Keep partials focused**: Each partial should have a single responsibility
4. **Use arguments scope**: Access passed variables via `arguments.` for clarity
5. **Consider caching**: Cache expensive partials to improve performance