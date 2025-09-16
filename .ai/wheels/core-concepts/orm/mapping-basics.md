# ORM Mapping Basics

## Description
Wheels maps database tables to CFC classes, records to objects, and columns to properties using convention-based ORM.

## Key Points
- Tables map to classes (plural table name, singular class name)
- Records map to object instances
- Columns map to object properties in `this` scope
- No getters/setters needed
- Database schema is introspected automatically

## Code Sample
```cfm
// Author.cfc maps to 'authors' table
component extends="Model" {
}

// Usage - class method returns object instance
author = model("author").findByKey(1);

// Properties available directly in this scope
author.firstName = "Joe";
author.save();
```

## Usage
1. Create `.cfc` file in `/app/models` folder
2. Extend `Model.cfc`
3. Use `model("className")` to get class reference
4. Call methods to create/find/update records

## Related
- [Primary Keys](./primary-keys.md)
- [Properties](./properties.md)
- [Tableless Models](./tableless-models.md)
- [MVC Models](../mvc-architecture/models.md)

## Important Notes
- First method call triggers database introspection
- Model files can be empty - methods inherited from Model.cfc
- File naming: `Author.cfc` maps to `authors` table by default
- Requires appropriate database permissions for schema reading