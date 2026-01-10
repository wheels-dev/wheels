# MVC Conventions

## Description
Wheels follows convention-over-configuration principles with specific naming and organizational patterns for MVC components.

## Key Points
- Models: singular names (User.cfc → users table)
- Controllers: plural names (Users.cfc handles users)
- Views: organized by controller (users/index.cfm)
- Files follow PascalCase for classes, lowercase for views
- Database tables use plural, lowercase names

## Code Sample
```cfm
// File structure conventions
/app/models/User.cfc              // Singular model name
/app/controllers/Users.cfc        // Plural controller name
/app/views/users/index.cfm        // Controller/action path
/app/views/users/show.cfm
/app/views/layout.cfm             // Default layout

// Naming patterns
model("user")                     // Lowercase reference
Users.index()                     // Controller.action
users table                       // Plural table name
```

## Usage
- Follow naming conventions for automatic mapping
- Override with configuration when needed
- Use generators to ensure proper conventions
- Maintain consistency across application

## Related
- [Models](./models.md)
- [Controllers](./controllers.md)
- [Views](./views.md)
- [Routing Conventions](../routing/basics.md)

## Important Notes
- Conventions reduce configuration overhead
- Generators follow conventions automatically
- Breaking conventions requires explicit mapping
- Consistency improves maintainability
- REST conventions align with HTTP verbs