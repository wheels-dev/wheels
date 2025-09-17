# Migration Column Types

## Description
Wheels migrations support various column types with options for constraints, defaults, and database-specific features.

## Key Points
- Standard SQL types with CFML-friendly names
- Options for length, precision, null constraints
- Default values and auto-increment support
- Database-specific type variations supported
- Timestamps helper for audit fields

## Code Sample
```cfm
function up() {
    transaction {
        t = createTable(name="products", force=false);

        // String types
        t.string(columnNames="name", limit=100, allowNull=false);
        t.text(columnNames="description");

        // Numeric types
        t.integer(columnNames="quantity", allowNull=false, default=0);
        t.bigInteger(columnNames="views");
        t.decimal(columnNames="price", precision=10, scale=2);
        t.float(columnNames="rating");

        // Date/time types
        t.date(columnNames="releaseDate");
        t.datetime(columnNames="lastModified");
        t.timestamps(); // Creates createdAt, updatedAt, deletedAt

        // Other types
        t.boolean(columnNames="active", default=true);
        t.binary(columnNames="image");

        t.create();
    }
}
```

## Usage
- Use type methods on table builder: `t.string()`, `t.integer()`
- Specify constraints: `allowNull=false`, `default=value`
- Set limits: `limit=255`, `precision=10, scale=2`
- Use `timestamps()` for automatic audit fields

## Related
- [Creating Migrations](./creating-migrations.md)
- [Running Migrations](./running-migrations.md)

## Important Notes
- `timestamps()` creates createdAt, updatedAt, deletedAt
- `text(size="longtext")` for MySQL large text
- Use appropriate precision for decimal financial data
- Database introspection shows actual column types