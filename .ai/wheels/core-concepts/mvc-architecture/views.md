# MVC Views

## Description
Views handle the presentation layer in Wheels' MVC architecture, rendering HTML templates with data from controllers.

## Key Points
- Located in `/app/views/` directory
- Use `.cfm` template files
- Access controller instance variables directly
- Support layouts, partials, and helpers
- Automatic view selection based on controller/action

## Code Sample
```cfm
<!-- /app/views/users/index.cfm -->
<cfparam name="users">
<cfoutput>
#contentFor("title", "Users")#

<h1>Users</h1>
#linkTo(route="newUser", text="New User", class="btn btn-primary")#

<cfif users.recordCount>
    <table class="table">
        <cfloop query="users">
        <tr>
            <td>#linkTo(route="user", key=users.id, text=users.firstName)#</td>
            <td>#users.email#</td>
            <td>
                #linkTo(route="editUser", key=users.id, text="Edit")#
                #buttonTo(route="user", method="delete", key=users.id,
                         text="Delete", confirm="Are you sure?")#
            </td>
        </tr>
        </cfloop>
    </table>
<cfelse>
    <p>No users found.</p>
</cfif>
</cfoutput>
```

## Usage
- Create `.cfm` files in `/app/views/[controller]/[action].cfm`
- Use `<cfparam>` to define expected variables from controller
- Wrap dynamic content in `<cfoutput>` tags
- Use view helpers for forms, links, and formatting
- Leverage layouts for consistent page structure

## Related
- [Controllers](./controllers.md)
- [Models](./models.md)
- [Layouts](../../views/layouts/structure.md)
- [View Helpers](../../views/helpers/forms.md)

## Important Notes
- Views should contain minimal logic
- Use helpers for complex formatting
- Always validate data from controllers
- Escape output to prevent XSS attacks