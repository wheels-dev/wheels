# Form Helpers

## Description
Wheels form helpers generate HTML form elements tied to model objects with automatic value binding and error display.

## Key Points
- Use `startFormTag()` and `endFormTag()` to wrap forms
- Form helpers bind to model objects and properties
- Automatic value population and error display
- Support for all standard and HTML5 form elements
- Tag-based variants available for non-object-bound forms
- Consistent naming conventions across helpers

## Object-Bound Form Helpers

Object-bound helpers automatically bind to model properties, populate values, and display validation errors.

```cfm
<cfoutput>
#startFormTag(route="user", method="patch", key=user.id)#

    <!-- Text field -->
    #textField(objectName="user", property="firstName", label="First Name")#

    <!-- Password field -->
    #passwordField(objectName="user", property="password", label="Password")#

    <!-- Email field (HTML5) -->
    #emailField(objectName="user", property="email", label="Email Address")#

    <!-- URL field (HTML5) -->
    #urlField(objectName="user", property="website", label="Website")#

    <!-- Telephone field (HTML5) -->
    #telField(objectName="user", property="phone", label="Phone Number")#

    <!-- Number field (HTML5) with constraints -->
    #numberField(objectName="product", property="quantity", label="Quantity", min="1", max="100", step="1")#

    <!-- Date field (HTML5) -->
    #dateField(objectName="event", property="startDate", label="Start Date")#

    <!-- Color picker (HTML5) -->
    #colorField(objectName="theme", property="primaryColor", label="Primary Color")#

    <!-- Range slider (HTML5) -->
    #rangeField(objectName="settings", property="volume", label="Volume", min="0", max="100")#

    <!-- Search field (HTML5) -->
    #searchField(objectName="search", property="query", label="Search")#

    <!-- Select dropdown -->
    #select(objectName="user", property="roleId", options=roles, label="Role")#

    <!-- Checkbox -->
    #checkBox(objectName="user", property="active", label="Active User")#

    <!-- Radio button -->
    #radioButton(objectName="user", property="accountType", tagValue="premium", label="Premium Account")#

    <!-- Text area -->
    #textArea(objectName="user", property="bio", label="Biography")#

    #submitTag(value="Save User")#
#endFormTag()#
</cfoutput>
```

## Complete List of Object-Bound Helpers

| Helper | HTML Input Type | Extra Attributes |
|--------|----------------|-----------------|
| `textField()` | `text` | `type` (overridable) |
| `passwordField()` | `password` | — |
| `emailField()` | `email` | — |
| `urlField()` | `url` | — |
| `numberField()` | `number` | `min`, `max`, `step` |
| `telField()` | `tel` | — |
| `dateField()` | `date` | `min`, `max` |
| `colorField()` | `color` | — |
| `rangeField()` | `range` | `min`, `max`, `step` |
| `searchField()` | `search` | — |
| `hiddenField()` | `hidden` | — |
| `fileField()` | `file` | — |
| `textArea()` | `<textarea>` | — |
| `select()` | `<select>` | `options`, `includeBlank` |
| `checkBox()` | `checkbox` | `checkedValue`, `uncheckedValue` |
| `radioButton()` | `radio` | `tagValue` |

## Tag-Based Form Helpers

Tag-based helpers accept `name` and `value` instead of `objectName` and `property`. Every object-bound helper has a corresponding tag version with a `Tag` suffix.

```cfm
<cfoutput>
#startFormTag(route="search", method="get")#

    <!-- Text input -->
    #textFieldTag(name="query", value=params.query, label="Search")#

    <!-- Email input -->
    #emailFieldTag(name="email", value="", label="Email")#

    <!-- Number input with constraints -->
    #numberFieldTag(name="quantity", value="1", min="0", max="99", step="1")#

    <!-- Date input -->
    #dateFieldTag(name="startDate", value="", min="2020-01-01")#

    <!-- Range slider -->
    #rangeFieldTag(name="rating", value="5", min="1", max="10")#

    <!-- Color picker -->
    #colorFieldTag(name="color", value="##336699")#

    <!-- Search input -->
    #searchFieldTag(name="q", value="")#

    <!-- URL input -->
    #urlFieldTag(name="website", value="")#

    <!-- Telephone input -->
    #telFieldTag(name="phone", value="")#

    #submitTag(value="Search")#
#endFormTag()#
</cfoutput>
```

## HTML5 Form Helpers in Detail

### emailField / emailFieldTag
Generates `<input type="email">`. Triggers email-specific keyboard on mobile and built-in browser validation.

```cfm
<!-- Object-bound -->
#emailField(objectName="user", property="email", label="Email Address")#

<!-- Tag-based -->
#emailFieldTag(name="email", value="user@example.com", placeholder="you@example.com")#
```

### numberField / numberFieldTag
Generates `<input type="number">` with optional `min`, `max`, and `step` constraints.

```cfm
#numberField(objectName="product", property="quantity", min="1", max="100", step="1")#
#numberFieldTag(name="price", value="9.99", min="0", step="0.01")#
```

### dateField / dateFieldTag
Generates `<input type="date">` with optional `min` and `max` constraints. Values use `YYYY-MM-DD` format.

```cfm
#dateField(objectName="event", property="startDate", min="2020-01-01", max="2030-12-31")#
#dateFieldTag(name="birthday", value="2000-01-15")#
```

### rangeField / rangeFieldTag
Generates `<input type="range">` slider with `min`, `max`, and `step`.

```cfm
#rangeField(objectName="settings", property="volume", min="0", max="100", step="5")#
#rangeFieldTag(name="brightness", value="50", min="0", max="100")#
```

### colorField / colorFieldTag
Generates `<input type="color">` for color picker. Value should be a hex color code.

```cfm
#colorField(objectName="theme", property="primaryColor")#
#colorFieldTag(name="bgColor", value="##ff0000")#
```

### telField / telFieldTag
Generates `<input type="tel">`. Triggers telephone-specific keyboard on mobile.

```cfm
#telField(objectName="user", property="phone", label="Phone")#
#telFieldTag(name="mobile", value="+1234567890")#
```

### urlField / urlFieldTag
Generates `<input type="url">`. Triggers URL keyboard on mobile with built-in browser validation.

```cfm
#urlField(objectName="user", property="website", label="Website")#
#urlFieldTag(name="homepage", value="https://example.com")#
```

### searchField / searchFieldTag
Generates `<input type="search">`. Some browsers style this with a clearable "x" button.

```cfm
#searchField(objectName="search", property="query", label="Search")#
#searchFieldTag(name="q", value="", placeholder="Search...")#
```

## Common Parameters

All form helpers accept these common parameters:

| Parameter | Description |
|-----------|-------------|
| `label` | Text for the `<label>` element |
| `labelPlacement` | Where to place the label: `before`, `after`, `around` |
| `prepend` | HTML to prepend before the field |
| `append` | HTML to append after the field |
| `prependToLabel` | HTML to prepend before the label |
| `appendToLabel` | HTML to append after the label |
| `errorElement` | HTML element for error messages (default: `span`) |
| `errorClass` | CSS class for error wrapper |
| `encode` | Boolean or string controlling HTML encoding |

Additional HTML attributes (`class`, `id`, `placeholder`, `required`, `autofocus`, etc.) are passed through to the generated HTML element.

## Form Structure Best Practices

```cfm
<cfoutput>
#startFormTag(route="users", method="post")#

    <div class="form-group">
        #emailField(objectName="user", property="email", label="Email *", class="form-control")#
        #errorMessageOn(objectName="user", property="email")#
    </div>

    <div class="form-group">
        #passwordField(objectName="user", property="password", label="Password *", class="form-control")#
        #errorMessageOn(objectName="user", property="password")#
    </div>

    <div class="form-group">
        #numberField(objectName="user", property="age", label="Age", class="form-control", min="13", max="120")#
        #errorMessageOn(objectName="user", property="age")#
    </div>

    <div class="form-group">
        #telField(objectName="user", property="phone", label="Phone", class="form-control")#
    </div>

    #submitTag(value="Create Account", class="btn btn-primary")#
#endFormTag()#
</cfoutput>
```

## Related
- [Linking Pages](./links.md)
- [Object Validation](../../database/validations/presence.md)
- [Routing](../../core-concepts/routing/basics.md)
- [Form Helper Troubleshooting](../../troubleshooting/form-helper-errors.md)

## Important Notes
- Form helpers automatically bind to object properties
- Errors display automatically when validation fails
- CSRF protection included automatically
- Use `objectName` to bind to specific model instances
- HTML encoding handled automatically for security
- All HTML5 helpers follow the same pattern as `textField()` and `passwordField()`
- Pass any standard HTML attribute and it will be included in the output
