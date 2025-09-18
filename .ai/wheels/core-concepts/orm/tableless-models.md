# Tableless Models

## Description
Models that don't map to database tables but still provide validation, callbacks, and object lifecycle features.

## Key Points
- Use `table(false)` to disable database mapping
- Supports properties, validations, and callbacks
- Lifecycle methods still run (save, create, update, delete)
- Useful for forms, APIs, email processing
- Override persistence methods for custom storage

## Code Sample
```cfm
component extends="Model" {
    function config() {
        table(false);

        // Manual property definitions
        property(name="name", type="string");
        property(name="email", type="string");

        // Validations still work
        validatesPresenceOf("name,email");
        validatesFormatOf(property="email", regEx="^[\w\.-]+@[\w\.-]+\.\w+$");
    }

    // Override save for custom persistence
    function save() {
        if (valid()) {
            // Custom save logic (email, session, external API)
            return true;
        }
        return false;
    }
}
```

## Usage
1. Set `table(false)` in `config()` method
2. Define properties manually with `property()`
3. Add validations as needed
4. Override persistence methods for custom storage
5. Use normally - validations and callbacks work

## Related
- [ORM Mapping Basics](./mapping-basics.md)
- [Object Validation](../../database/validations/presence.md)
- [Form Helpers](../../views/helpers/forms.md)

## Important Notes
- Perfect for contact forms and search forms
- Still supports full object lifecycle
- No automatic persistence - you control storage
- Validations and callbacks function normally
- See blog post: "Building search forms with tableless models"