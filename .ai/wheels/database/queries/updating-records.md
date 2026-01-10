# Updating Records

## Description
Update existing database records by modifying object properties and saving, or using direct update methods.

## Key Points
- Modify properties directly, call `save()` to persist
- Use `update()` method to update and save in one step
- `updateAll()` for bulk updates matching criteria
- Validations run automatically on updates
- Optimistic locking supported with version columns

## Code Sample
```cfm
// Find, modify properties, save
author = model("author").findByKey(1);
author.firstName = "Jane";
author.email = "jane@example.com";
author.save();

// Update with struct in one step
author = model("author").findByKey(1);
author.update(firstName="Jane", email="jane@example.com");

// Bulk update matching criteria
model("user").updateAll(
    where="lastLoginAt < '2023-01-01'",
    values={active: false, notes: "Inactive user"}
);

// Update with validation handling
if (author.update(params.author)) {
    redirectTo(route="author", key=author.id, success="Author updated!");
} else {
    // Handle validation errors
    renderView(action="edit");
}
```

## Usage
1. Find record: `model().findByKey()` or `findOne()`
2. Modify properties: `object.property = newValue`
3. Save changes: `object.save()` or `object.update(struct)`
4. Handle validation results (true/false return)
5. Use `updateAll()` for bulk operations

## Related
- [Finding Records](./finding-records.md)
- [Creating Records](./creating-records.md)
- [Object Validation](../validations/presence.md)

## Important Notes
- Changes not persisted until `save()` or `update()` called
- Validations and callbacks run on updates
- Use transactions for multiple related updates
- `updateAll()` bypasses validations and callbacks
- Check return value for success/failure