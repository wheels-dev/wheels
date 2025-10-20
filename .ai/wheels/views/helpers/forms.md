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

## ⚠️ CRITICAL: Form Helper Limitations

**Label Helper Issues:**
The `label()` helper in Wheels does NOT accept a `text` parameter like in Rails:

```cfm
<!-- ❌ INCORRECT - This will cause errors -->
#label(objectName="user", property="email", text="Email Address")#

<!-- ✅ CORRECT - Use standard HTML labels instead -->
<label for="user-email">Email Address</label>
#textField(objectName="user", property="email")#
```

**Email Field Limitation:**
Wheels does NOT have an `emailField()` helper:

```cfm
<!-- ❌ INCORRECT - emailField() doesn't exist -->
#emailField(objectName="user", property="email")#

<!-- ✅ CORRECT - Use textField() for all input types -->
#textField(objectName="user", property="email")#

<!-- ✅ ALTERNATIVE - Add HTML5 type attribute if needed -->
#textField(objectName="user", property="email", type="email")#
```

**Password Field Limitation:**
Wheels does NOT have a `passwordField()` helper:

```cfm
<!-- ❌ INCORRECT - passwordField() doesn't exist -->
#passwordField(objectName="user", property="password")#

<!-- ✅ CORRECT - Use textField() with type attribute -->
#textField(objectName="user", property="password", type="password")#
```

## Recommended Form Helper Pattern

For maximum compatibility, use this pattern:

```cfm
<cfoutput>
#startFormTag(route="users", method="post")#

    <!-- Use HTML labels for reliability -->
    <div class="form-group">
        <label for="user-firstName">First Name *</label>
        #textField(objectName="user", property="firstName", class="form-control")#
        #errorMessageOn(objectName="user", property="firstName")#
    </div>

    <div class="form-group">
        <label for="user-email">Email Address *</label>
        #textField(objectName="user", property="email", type="email", class="form-control")#
        #errorMessageOn(objectName="user", property="email")#
    </div>

    <div class="form-group">
        <label for="user-password">Password *</label>
        #textField(objectName="user", property="password", type="password", class="form-control")#
        #errorMessageOn(objectName="user", property="password")#
    </div>

    <div class="form-group">
        <label for="user-bio">Biography</label>
        #textArea(objectName="user", property="bio", class="form-control", rows="5")#
        #errorMessageOn(objectName="user", property="bio")#
    </div>

    #submitTag(value="Save User", class="btn btn-primary")#

#endFormTag()#
</cfoutput>
```

This pattern ensures compatibility and avoids the common form helper errors.