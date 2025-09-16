# MVC Models

## Description
Models represent the data layer in Wheels' MVC architecture, handling database interactions, validations, and business logic.

## Key Points
- Extend `Model.cfc` for database-backed models
- Located in `/app/models/` directory
- Handle data validation and business rules
- Support associations (relationships) between models
- Include callbacks for lifecycle events

## Code Sample
```cfm
// /app/models/User.cfc
component extends="Model" {
    function config() {
        // Associations
        hasMany("orders");
        belongsTo("role");

        // Validations
        validatesPresenceOf("firstName,lastName,email");
        validatesUniquenessOf(property="email");
        validatesFormatOf(property="email", regEx="^[\w\.-]+@[\w\.-]+\.\w+$");

        // Callbacks
        beforeSave("hashPassword");
        afterCreate("sendWelcomeEmail");
    }

    function fullName() {
        return trim("#firstName# #lastName#");
    }
}
```

## Usage
- Create `.cfc` files in `/app/models/`
- Use singular names (User.cfc for users table)
- Add validations and associations in `config()`
- Define custom methods for business logic
- Access via `model("user")` in controllers

## Related
- [Controllers](./controllers.md)
- [Views](./views.md)
- [ORM Mapping](../orm/mapping-basics.md)
- [Associations](../../database/associations/has-many.md)

## Important Notes
- Models contain business logic, not just data
- Keep controllers thin, models fat
- Use descriptive method names
- Validate all user input at model level