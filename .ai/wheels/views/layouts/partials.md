# Partials

## Description
Reusable view components that can be included in multiple templates to reduce duplication and improve maintainability.

## Key Points
- Create partial files with underscore prefix: `_partial.cfm`
- Use `includePartial()` to render partials
- Pass local variables to partials
- Can include partials from other controllers
- Useful for repeated UI components

## Code Sample
```cfm
<!-- Create partial: /app/views/shared/_user_card.cfm -->
<cfparam name="user">
<cfparam name="showActions" default="true">

<cfoutput>
<div class="user-card">
    <div class="user-avatar">
        #userAvatar(user, "medium")#
    </div>
    <div class="user-info">
        <h3>#user.fullName()#</h3>
        <p>#user.email#</p>
        <p>Joined #timeAgoInWords(user.createdAt)#</p>
    </div>
    <cfif showActions>
        <div class="user-actions">
            #linkTo(route="user", key=user.id, text="View", class="btn btn-sm")#
            #linkTo(route="editUser", key=user.id, text="Edit", class="btn btn-sm")#
        </div>
    </cfif>
</div>
</cfoutput>

<!-- Use partial in view: /app/views/users/index.cfm -->
<cfoutput>
<h1>All Users</h1>

<div class="users-grid">
    <cfloop query="users">
        #includePartial("shared/user_card", user=users, showActions=currentUser().isAdmin())#
    </cfloop>
</div>
</cfoutput>

<!-- Form partial: /app/views/users/_form.cfm -->
<cfparam name="user">

<cfoutput>
#textField(objectName="user", property="firstName", label="First Name")#
#textField(objectName="user", property="lastName", label="Last Name")#
#textField(objectName="user", property="email", label="Email")#

#select(
    objectName="user",
    property="roleId",
    options=model("Role").findAll(),
    label="Role"
)#

#checkBox(objectName="user", property="active", label="Active")#
</cfoutput>

<!-- Use form partial in multiple views -->
<!-- /app/views/users/new.cfm -->
<cfoutput>
#startFormTag(route="users", method="post")#
    #includePartial("form", user=user)#
    #submitTag(value="Create User")#
#endFormTag()#
</cfoutput>

<!-- /app/views/users/edit.cfm -->
<cfoutput>
#startFormTag(route="user", method="patch", key=user.id)#
    #includePartial("form", user=user)#
    #submitTag(value="Update User")#
#endFormTag()#
</cfoutput>
```

## Usage
1. Create partial files with underscore prefix in `/app/views/`
2. Use `includePartial("partialName")` to render
3. Pass variables: `includePartial("partial", var1=value1, var2=value2)`
4. Reference partials from other controllers: `includePartial("controller/partial")`
5. Use `<cfparam>` to define expected variables

## Related
- [Layout Structure](./structure.md)
- [Content For](./content-for.md)
- [Custom Helpers](../helpers/custom.md)

## Important Notes
- Prefix partial files with underscore
- Use shared folder for cross-controller partials
- Define expected parameters with `<cfparam>`
- Keep partials focused and reusable
- Can nest partials within other partials