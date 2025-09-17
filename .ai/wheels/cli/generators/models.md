# Model Generation

## Description
Generate model files with predefined properties, validations, and associations using Wheels CLI commands.

## Key Points
- Use `wheels g model` to generate model files
- Specify attributes with type and constraint syntax
- Automatic validation setup based on constraints
- Creates model file in `/app/models/` directory
- Supports associations and custom properties

## Code Sample
```bash
# Basic model generation
wheels g model User name:string,email:string,active:boolean

# Model with detailed attributes
wheels g model Product name:string:required,price:decimal:required,description:text,category_id:integer:foreign_key

# Model with associations
wheels g model Post title:string:required,body:text:required,user_id:integer:belongs_to,published:boolean:default=false

# Generated file: /app/models/User.cfc
component extends="Model" {
    function config() {
        // Validations based on constraints
        validatesPresenceOf("name,email");

        // Associations
        belongsTo("category");
        hasMany("comments");

        // Property overrides
        property(name="publishedAt", type="datetime");
    }
}
```

## Usage
1. Run `wheels g model ModelName attribute:type:constraint`
2. Specify multiple attributes separated by commas
3. Use constraints: `required`, `unique`, `foreign_key`, `default=value`
4. Edit generated file to add custom methods and validations
5. Run migrations if database changes needed

## Related
- [ORM Mapping](../../core-concepts/orm/mapping-basics.md)
- [Creating Migrations](../database/migrations/creating-migrations.md)
- [Object Validation](../../database/validations/presence.md)

## Important Notes
- Model names should be singular (User, not Users)
- Generators create basic structure - customize as needed
- Constraints become validations automatically
- Foreign key attributes suggest associations
- Always review and customize generated code