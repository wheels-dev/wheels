# Link Helpers

## Description
Generate HTML links using Wheels routing system with automatic URL building and parameter handling.

## Key Points
- Use `linkTo()` for all internal links
- Automatic URL generation from routes
- Support for named routes and controller/action pairs
- Automatic HTML encoding and parameter handling
- Support for additional HTML attributes

## Code Sample
```cfm
<cfoutput>
<!-- Named route links -->
#linkTo(route="user", key=user.id, text="View Profile")#
#linkTo(route="editUser", key=user.id, text="Edit User")#

<!-- Controller/action links -->
#linkTo(controller="posts", action="index", text="All Posts")#
#linkTo(controller="users", action="show", key=5, text="User #5")#

<!-- Links with additional attributes -->
#linkTo(
    route="user",
    key=user.id,
    text="View Profile",
    class="btn btn-primary",
    title="Click to view full profile"
)#

<!-- Confirmation links -->
#linkTo(
    route="user",
    method="delete",
    key=user.id,
    text="Delete User",
    confirm="Are you sure you want to delete this user?"
)#

<!-- External links -->
#linkTo(href="https://wheels.dev", text="Wheels Framework")#

<!-- Mail and telephone links -->
#mailTo("user@example.com", "Send Email")#
#linkTo(href="tel:+1234567890", text="Call Us")#

<!-- Links with complex parameters -->
#linkTo(
    controller="search",
    action="results",
    params={category: "books", sort: "title"},
    text="Search Books"
)#

<!-- Conditional linking -->
<cfif user.canEdit>
    #linkTo(route="editUser", key=user.id, text="Edit")#
<cfelse>
    <span class="disabled">Edit</span>
</cfif>
</cfoutput>
```

## Usage
1. Use `linkTo()` for internal application links
2. Specify `route` for named routes or `controller`/`action` for direct links
3. Include required route parameters (`key`, custom params)
4. Add `text` parameter for link content
5. Include HTML attributes as additional parameters

## Related
- [Form Helpers](./forms.md)
- [Routing](../../core-concepts/routing/basics.md)
- [URL Helpers](./custom.md)

## Important Notes
- Always use `linkTo()` instead of hardcoded URLs
- Route parameters automatically encoded for security
- Method override supported for REST actions
- Confirmation dialogs available with `confirm` parameter
- Supports both simple text and HTML content