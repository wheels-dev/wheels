# Uniqueness Validation

## Description
Ensures that property values are unique across all records in the database table.

## Key Points
- Use `validatesUniquenessOf()` for unique constraints
- Performs database query to check for existing values
- Supports scoped uniqueness (unique within a subset)
- Case-sensitive by default, can be made case-insensitive
- Should be paired with database unique indexes

## Code Sample
```cfm
component extends="Model" {
    function config() {
        // Basic uniqueness validation
        validatesUniquenessOf(property="email");

        // Case-insensitive uniqueness
        validatesUniquenessOf(
            property="username",
            caseSensitive=false
        );

        // Scoped uniqueness (unique within a group)
        validatesUniquenessOf(
            property="name",
            scope="categoryId",
            message="Product name must be unique within category"
        );

        // Multiple scoped uniqueness
        validatesUniquenessOf(
            property="email",
            scope="tenantId,status"
        );
    }
}
```

## Usage
1. Add `validatesUniquenessOf()` in model's `config()` method
2. Specify property to check for uniqueness
3. Use `scope` for uniqueness within a subset
4. Set `caseSensitive=false` for case-insensitive checks
5. Always add corresponding database unique index

## Related
- [Presence Validation](./presence.md)
- [Format Validation](./format.md)
- [Database Indexes](../migrations/creating-migrations.md)

## Important Notes
- Requires database query - has performance impact
- Race condition possible - use database unique constraints
- Case-sensitive by default
- Scope limits uniqueness to subset of records
- Update operations ignore current record in uniqueness check