# Deleting Records

## Description
Delete records from the database using object methods or bulk deletion with criteria matching.

## Key Points
- Use `delete()` method on objects for single record deletion
- Use `deleteAll()` for bulk deletion with WHERE criteria
- Soft delete supported with `softDelete()` method
- Callbacks and validations run on deletion
- Associated records handled based on association settings

## Code Sample
```cfm
// Delete single record by object
author = model("author").findByKey(1);
author.delete();

// Delete single record directly
model("author").deleteByKey(1);

// Bulk delete with criteria
model("user").deleteAll(where="active = 0 AND lastLoginAt < '2022-01-01'");

// Soft delete (marks as deleted, doesn't remove)
author = model("author").findByKey(1);
author.softDelete();

// Check if deletion was successful
author = model("author").findByKey(1);
if (author.delete()) {
    flashInsert(success="Author deleted successfully");
} else {
    flashInsert(error="Could not delete author");
}
```

## Usage
1. Find record to delete
2. Call `delete()` method on object
3. Or use `deleteByKey()` with primary key
4. Use `deleteAll()` for bulk operations
5. Handle return value (true/false)

## Related
- [Finding Records](./finding-records.md)
- [Soft Delete](../soft-delete.md)
- [Associations](../associations/has-many.md)

## Important Notes
- Deletion callbacks run before/after deletion
- Associated records handled per association settings
- `deleteAll()` bypasses individual object callbacks
- Soft delete preserves data with deleted flag
- Always handle potential deletion failures