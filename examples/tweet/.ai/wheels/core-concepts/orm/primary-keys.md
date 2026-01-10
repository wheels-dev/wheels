# Primary Keys

## Description
Wheels supports flexible primary key configurations including auto-incrementing integers, natural keys, and composite keys.

## Key Points
- Default: `id` column, integer, auto-incrementing
- Supports natural keys (varchar, etc.)
- Supports composite keys (multiple columns)
- Database creates key automatically or you create in code
- Wheels introspects database to determine key configuration

## Code Sample
```cfm
// Default auto-incrementing integer 'id'
component extends="Model" {
}

// Custom primary key column name
component extends="Model" {
    function config() {
        property(name="userId", column="user_id");
    }
}

// Usage with different key types
user = model("user").findByKey(12345);           // Integer key
product = model("product").findByKey("ABC123");  // Natural key
```

## Usage
- No configuration needed for default `id` integer keys
- Use `property()` method in `config()` for custom mappings
- Wheels automatically detects key type and behavior
- Works with database-generated or application-generated keys

## Related
- [ORM Mapping Basics](./mapping-basics.md)
- [Properties](./properties.md)
- [Database Queries](../../database/queries/finding-records.md)

## Important Notes
- Composite keys supported but less common
- Natural keys should be immutable
- Performance: integer keys generally faster than varchar keys
- Database permissions required for introspection