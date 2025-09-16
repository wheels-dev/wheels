# Form Helpers

## Description
Wheels form helpers generate HTML form elements tied to model objects with automatic value binding and error display.

## Key Points
- Use `startFormTag()` and `endFormTag()` to wrap forms
- Form helpers bind to model objects and properties
- Automatic value population and error display
- Support for all HTML form elements
- Consistent naming conventions across helpers

## Code Sample
```cfm
<cfoutput>
<!-- Basic form structure -->
#startFormTag(route="user", method="patch", key=user.id)#

    <!-- Text fields -->
    #textField(
        objectName="user",
        property="firstName",
        label="First Name"
    )#

    #textField(
        objectName="user",
        property="email",
        label="Email Address"
    )#

    <!-- Password fields -->
    #passwordField(
        objectName="user",
        property="password",
        label="Password"
    )#

    <!-- Select dropdowns -->
    #select(
        objectName="user",
        property="roleId",
        options=roles,
        label="Role"
    )#

    <!-- Checkboxes and radio buttons -->
    #checkBox(
        objectName="user",
        property="active",
        label="Active User"
    )#

    #radioButton(
        objectName="user",
        property="accountType",
        tagValue="premium",
        label="Premium Account"
    )#

    <!-- Text areas -->
    #textArea(
        objectName="user",
        property="bio",
        label="Biography"
    )#

    <!-- Submit button -->
    #submitTag(value="Save User")#

#endFormTag()#
</cfoutput>
```

## Usage
1. Start with `startFormTag(route="routeName", method="httpMethod")`
2. Use form helpers with `objectName` and `property` parameters
3. Add `label` parameter for automatic label generation
4. Include validation display with error styling
5. End with `endFormTag()`

## Related
- [Linking Pages](./links.md)
- [Object Validation](../../database/validations/presence.md)
- [Routing](../../core-concepts/routing/basics.md)

## Important Notes
- Form helpers automatically bind to object properties
- Errors display automatically when validation fails
- CSRF protection included automatically
- Use `objectName` to bind to specific model instances
- HTML encoding handled automatically for security