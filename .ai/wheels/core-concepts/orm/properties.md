# Properties

## Description
Object properties correspond directly to database columns and are available in the `this` scope without getters/setters.

## Key Points
- Properties mapped automatically from database columns
- Available directly in `this` scope
- Use `property()` method to customize column mapping
- No getters/setters required
- Blank strings converted to NULL on save

## Code Sample
```cfm
component extends="Model" {
    function config() {
        // Map property to different column name
        property(name="firstName", column="tbl_auth_f_name");
    }
}

// Usage
user = model("user").findByKey(1);
user.firstName = "John";      // Direct property access
user.email = "john@test.com";
user.save();
```

## Usage
1. Properties auto-mapped from database columns
2. Access directly: `object.propertyName`
3. Override mapping with `property(name="prop", column="col_name")`
4. Set values directly, call `save()` to persist

## Related
- [ORM Mapping Basics](./mapping-basics.md)
- [Creating Records](../../database/queries/creating-records.md)
- [Updating Records](../../database/queries/updating-records.md)

## Important Notes
- No concept of `null` in CFML - blank strings become NULL
- Avoid storing blank strings in database
- Properties reflect database column types
- First model access triggers schema introspection