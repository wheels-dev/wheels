# dbmigrate create table
*This command may not work with options as expected. A complete and stable version with fully functional options is **coming soon**.*

Generate a migration file for creating a new database table.

## Synopsis

```bash
wheels dbmigrate create table name=<table_name> [--force] [--id] primary-key=<key_name>
```

Alias: `wheels db create table`

## Description

The `dbmigrate create table` command generates a migration file that creates a new database table. The generated migration includes the table structure following Wheels conventions.

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `name` | string | Yes | - | The name of the table to create |
| `--force` | boolean | No | false | Force the creation of the table |
| `--id` | boolean | No | true | Auto create ID column as autoincrement ID |
| `primary-key` | string | No | "id" | Overrides the default primary key column name |

## Notes About Column Definition

The generated migration file will contain a basic table structure. You'll need to manually edit the migration file to add columns with their types and options. The migration template includes comments showing how to add columns.

## Examples

### Create a basic table
```bash
wheels dbmigrate create table name=user
```

### Create table without ID column
```bash
wheels dbmigrate create table name=user_roles --id=false
```

### Create table with custom primary key
```bash
wheels dbmigrate create table name=products primary-key=productCode
```

### Force creation (overwrite existing)
```bash
wheels dbmigrate create table name=users --force
```

## Generated Migration Example

For the command:
```bash
wheels dbmigrate create table name=users
```

Generates a migration file that you can customize:
```cfml
component extends="wheels.migrator.Migration" hint="create users table" {

    function up() {
        transaction {
            t = createTable(name="users", force=false, id=true, primaryKey="id");
            // Add your columns here
            // t.string(columnName="name");
            // t.integer(columnName="age");
            t.timestamps();
            t.create();
        }
    }

    function down() {
        transaction {
            dropTable("users");
        }
    }

}
```

## Use Cases

### Standard Entity Table
Create a typical entity table:
```bash
# Generate the migration
wheels dbmigrate create table name=customer

# Then edit the migration file to add columns
```

### Join Table for Many-to-Many
Create a join table without primary key:
```bash
wheels dbmigrate create table name=products_categories --id=false
```

### Table with Custom Primary Key
Create a table with non-standard primary key:
```bash
wheels dbmigrate create table name=legacy_customer primary-key=customer_code
```

## Best Practices

### 1. Use Singular Table Names
Wheels conventions expect singular table names:
```bash
# Good
wheels dbmigrate create table name=user
wheels dbmigrate create table name=product

# Avoid
wheels dbmigrate create table name=users
wheels dbmigrate create table name=products
```

### 2. Edit Migration Files
After generating the migration, edit it to add columns:
```cfml
// In the generated migration file
t = createTable(name="orders", force=false, id=true, primaryKey="id");
t.integer(columnName="customer_id");
t.decimal(columnName="total", precision=10, scale=2);
t.string(columnName="status", default="pending");
t.timestamps();
t.create();
```

### 3. Plan Your Schema
Think through your table structure before creating:
- Primary key strategy
- Required columns and their types
- Foreign key relationships
- Indexes needed for performance

## Working with the Generated Migration

The command generates a basic migration template. You'll need to edit it to add columns:

```cfml
component extends="wheels.migrator.Migration" {
    function up() {
        transaction {
            t = createTable(name="tableName", force=false, id=true, primaryKey="id");
            // Add your columns here:
            t.string(columnName="name");
            t.integer(columnName="age");
            t.boolean(columnName="active", default=true);
            t.text(columnName="description");
            // MySQL only: use size parameter for larger text fields
            t.text(columnName="content", size="mediumtext"); // 16MB
            t.text(columnName="largeContent", size="longtext"); // 4GB
            t.timestamps();
            t.create();
        }
    }
    
    function down() {
        transaction {
            dropTable("tableName");
        }
    }
}
```

## Notes

- Table names should follow your database naming conventions
- The migration automatically handles rollback with dropTable()
- Column order in the command is preserved in the migration
- Use `wheels dbmigrate up` to run the generated migration

## Related Commands

- [`wheels dbmigrate create column`](dbmigrate-create-column.md) - Add columns to existing table
- [`wheels dbmigrate create blank`](dbmigrate-create-blank.md) - Create custom migration
- [`wheels dbmigrate remove table`](dbmigrate-remove-table.md) - Create table removal migration
- [`wheels dbmigrate up`](dbmigrate-up.md) - Run migrations
- [`wheels dbmigrate info`](dbmigrate-info.md) - View migration status