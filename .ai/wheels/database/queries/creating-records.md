# Creating Records

## Description
Create new database records using `new()` and `save()` methods or the shorthand `create()` method.

## Key Points
- Use `new()` to create object in memory, `save()` to persist
- Use `create()` to create and save in one step
- Pass struct of attributes to populate object
- Primary key auto-populated after save
- Support for database and model defaults

## Code Sample
```cfm
// Create empty object, set properties, save
newAuthor = model("author").new();
newAuthor.firstName = "John";
newAuthor.lastName = "Doe";
newAuthor.save();

// Create from struct (form params)
newAuthor = model("author").new(params.author);
newAuthor.save();

// Create and save in one step
author = model("author").create(params.author);

// Access auto-generated primary key after save
newAuthor = model("author").new(firstName="Jane", lastName="Smith");
newAuthor.save();
newID = newAuthor.id; // Available after save
```

## Usage
1. Create object: `model("name").new()`
2. Set properties: `object.property = value`
3. Save to database: `object.save()`
4. Or use shorthand: `model("name").create(struct)`
5. Access generated keys after save

## Related
- [Finding Records](./finding-records.md)
- [Updating Records](./updating-records.md)
- [Object Validation](../validations/presence.md)

## Important Notes
- Objects exist in memory until `save()` called
- Primary keys available immediately after save
- Use `reload=true` to get database defaults
- Validations run automatically on save
- Failed saves return false, successful saves return true