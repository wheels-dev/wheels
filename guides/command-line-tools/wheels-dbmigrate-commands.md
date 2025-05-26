# Database Commands

The Wheels CLI provides comprehensive database management through migration commands and database utilities. These commands help you version control your database schema and manage data seeding.

## Overview

Database commands are organized into two main categories:
- **Migration Commands** (`wheels dbmigrate`) - Schema versioning and migration
- **Database Utilities** (`wheels db`) - Schema dumps and data seeding

All migration commands support multiple database platforms including MySQL, PostgreSQL, SQL Server, and H2.

## Migration Concepts

Wheels uses a migration system to:
- Track database schema changes over time
- Enable team collaboration on database changes
- Support rollback to previous versions
- Maintain consistency across environments

Each migration has:
- A unique timestamp-based version number
- An `up()` method for applying changes
- A `down()` method for reverting changes

## wheels dbmigrate create

Create new migration files for database changes.

### Subcommands

### dbmigrate create table

Create a migration for a new database table.

#### Syntax

```bash
wheels dbmigrate create table [name] [options]
```

#### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| name | string | Yes | - | Table name |
| --id | boolean | No | true | Include id column |
| --timestamps | boolean | No | true | Include createdAt/updatedAt |
| --force | boolean | No | false | Overwrite existing |

#### Examples

Basic table:
```bash
wheels dbmigrate create table products
```

Table without timestamps:
```bash
wheels dbmigrate create table products --timestamps=false
```

#### Generated Migration

```cfm
component extends="wheels.dbmigrate.Migration" {
    
    function up() {
        transaction {
            t = createTable("products");
            t.primaryKey();
            t.timestamps();
            t.create();
        }
    }
    
    function down() {
        transaction {
            dropTable("products");
        }
    }
}
```

---

### dbmigrate create column

Create a migration to add columns to an existing table.

#### Syntax

```bash
wheels dbmigrate create column [table] [columnName] [columnType] [options]
```

#### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| table | string | Yes | - | Table name |
| columnName | string | Yes | - | Column name |
| columnType | string | Yes | - | Column type |
| --default | string | No | - | Default value |
| --null | boolean | No | true | Allow nulls |
| --limit | integer | No | - | Column length |
| --precision | integer | No | - | Numeric precision |
| --scale | integer | No | - | Numeric scale |

#### Column Types

- `string` - Variable length string
- `text` - Long text
- `integer` - Integer number
- `biginteger` - Large integer
- `float` - Floating point
- `decimal` - Precise decimal
- `boolean` - True/false
- `binary` - Binary data
- `date` - Date only
- `time` - Time only
- `datetime` - Date and time
- `timestamp` - Timestamp

#### Examples

Add string column:
```bash
wheels dbmigrate create column products name string
```

Add decimal with precision:
```bash
wheels dbmigrate create column products price decimal --precision=10 --scale=2
```

Add non-nullable column with default:
```bash
wheels dbmigrate create column products active boolean --null=false --default=true
```

#### Generated Migration

```cfm
component extends="wheels.dbmigrate.Migration" {
    
    function up() {
        transaction {
            addColumn(table="products", columnName="price", columnType="decimal", precision=10, scale=2);
        }
    }
    
    function down() {
        transaction {
            removeColumn(table="products", columnName="price");
        }
    }
}
```

---

### dbmigrate create blank

Create a blank migration file for custom changes.

#### Syntax

```bash
wheels dbmigrate create blank [migrationName]
```

#### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| migrationName | string | Yes | - | Migration description |

#### Examples

```bash
wheels dbmigrate create blank AddIndexToUsersEmail
wheels dbmigrate create blank UpdateProductPrices
wheels dbmigrate create blank MigrateOldDataFormat
```

#### Generated Migration

```cfm
component extends="wheels.dbmigrate.Migration" {
    
    function up() {
        transaction {
            // Add your migration code here
        }
    }
    
    function down() {
        transaction {
            // Add your rollback code here
        }
    }
}
```

#### Use Cases

Blank migrations are useful for:
- Complex schema changes
- Data migrations
- Adding indexes
- Custom SQL execution
- Multi-step migrations

---

## wheels dbmigrate remove

Create migrations to remove database objects.

### dbmigrate remove table

Create a migration to drop a table.

#### Syntax

```bash
wheels dbmigrate remove table [name]
```

#### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| name | string | Yes | - | Table name to drop |

#### Examples

```bash
wheels dbmigrate remove table legacy_products
```

#### Generated Migration

```cfm
component extends="wheels.dbmigrate.Migration" {
    
    function up() {
        transaction {
            dropTable("legacy_products");
        }
    }
    
    function down() {
        transaction {
            // Optionally recreate the table structure
            t = createTable("legacy_products");
            t.primaryKey();
            t.timestamps();
            t.create();
        }
    }
}
```

---

## wheels dbmigrate up

Migrate the database forward by one version.

### Syntax

```bash
wheels dbmigrate up [options]
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| --version | string | No | Next version | Target version |

### Description

Executes the next pending migration's `up()` method. Useful for:
- Step-by-step migration during development
- Debugging migration issues
- Controlled production deployments

### Examples

Run next migration:
```bash
wheels dbmigrate up
```

Migrate to specific version:
```bash
wheels dbmigrate up --version=20231215120000
```

### Notes

- Updates the migration version in the database
- Wraps migration in a transaction
- Shows execution time and status
- Stops on first error

---

## wheels dbmigrate down

Rollback the database by one version.

### Syntax

```bash
wheels dbmigrate down [options]
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| --version | string | No | Previous version | Target version |

### Description

Executes the current migration's `down()` method to revert changes. Essential for:
- Fixing migration mistakes
- Testing rollback procedures
- Development iterations

### Examples

Rollback one migration:
```bash
wheels dbmigrate down
```

Rollback to specific version:
```bash
wheels dbmigrate down --version=20231215110000
```

### Notes

- Requires properly implemented down() methods
- Not all migrations can be safely reversed
- Always backup before rolling back production

---

## wheels dbmigrate latest

Migrate the database to the latest version.

### Syntax

```bash
wheels dbmigrate latest
```

### Parameters

None

### Description

Runs all pending migrations to bring the database to the latest version. This is the most commonly used migration command.

### Examples

```bash
wheels dbmigrate latest
```

Output:
```
Migrating from version 20231215110000 to 20231215130000

[20231215120000] CreateProductsTable.cfc
  ↳ Migrated (0.023s)

[20231215130000] AddIndexToProductsSku.cfc
  ↳ Migrated (0.015s)

Database migrated successfully to version 20231215130000
```

### Notes

- Runs migrations in chronological order
- Skips already applied migrations
- Shows progress for each migration
- Stops on first error

---

## wheels dbmigrate reset

Reset the database by rolling back all migrations.

### Syntax

```bash
wheels dbmigrate reset
```

### Parameters

None

### Description

Rolls back all migrations to version 0, effectively returning the database to its initial state. **Use with extreme caution**.

### Examples

```bash
wheels dbmigrate reset
```

You'll be prompted:
```
WARNING: This will rollback ALL migrations!
Are you sure you want to reset the database? (y/N)
```

### Notes

- Destroys all data in migrated tables
- Cannot be undone
- Requires confirmation
- Useful for development environments only

---

## wheels dbmigrate info

Display current migration status and pending migrations.

### Syntax

```bash
wheels dbmigrate info
```

### Parameters

None

### Description

Shows:
- Current database version
- List of pending migrations
- Migration history
- Database connection info

### Examples

```bash
wheels dbmigrate info
```

Output:
```
=====================================
Database Migration Status
=====================================
Current Version:    20231215120000
Latest Version:     20231215130000
Pending Migrations: 1

Applied Migrations:
  ✓ 20231215110000 - CreateUsersTable
  ✓ 20231215120000 - CreateProductsTable

Pending Migrations:
  ○ 20231215130000 - AddIndexToProductsSku

Database: myapp_development
=====================================
```

---

## wheels dbmigrate exec

Execute a specific migration version.

### Syntax

```bash
wheels dbmigrate exec [version] [options]
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| version | string | Yes | - | Migration version |
| --direction | string | No | up | Direction (up/down) |

### Description

Manually execute a specific migration, regardless of current version. Useful for:
- Re-running failed migrations
- Testing specific migrations
- Fixing migration issues

### Examples

Run specific migration up:
```bash
wheels dbmigrate exec 20231215120000
```

Run specific migration down:
```bash
wheels dbmigrate exec 20231215120000 --direction=down
```

### Notes

- Bypasses version checking
- Use carefully to avoid version conflicts
- Doesn't update version table when direction=down

---

## wheels db schema

Manage database schema dumps and loads.

### Syntax

```bash
wheels db schema [options]
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| --dump | boolean | No | false | Dump schema to file |
| --load | boolean | No | false | Load schema from file |
| --format | string | No | sql | Output format |

### Description

Export or import database schema for:
- Backup purposes
- Setting up new environments
- Schema documentation
- Database replication

### Examples

Dump schema:
```bash
wheels db schema --dump
```

Dump as JSON:
```bash
wheels db schema --dump --format=json
```

Load schema:
```bash
wheels db schema --load
```

### Notes

- Schema dumps exclude data
- Useful for CI/CD pipelines
- Format options: sql, json
- Creates db/schema.sql or db/schema.json

---

## wheels db seed

Seed the database with initial or test data.

### Syntax

```bash
wheels db seed [options]
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| --file | string | No | db/seeds.cfm | Seed file |
| --environment | string | No | Current | Target environment |

### Description

Populates database with:
- Initial application data
- Test data for development
- Demo data for staging
- Reference data

### Examples

Run default seeds:
```bash
wheels db seed
```

Run specific seed file:
```bash
wheels db seed --file=db/seeds/products.cfm
```

Seed test environment:
```bash
wheels db seed --environment=testing
```

### Seed File Example

```cfm
// db/seeds.cfm
<cfscript>
// Create admin user
user = model("User").create(
    email = "admin@example.com",
    password = "secure123",
    role = "admin"
);

// Create sample products
products = [
    {name: "Widget", price: 19.99},
    {name: "Gadget", price: 29.99},
    {name: "Doohickey", price: 39.99}
];

for (product in products) {
    model("Product").create(product);
}

writeOutput("Database seeded successfully!");
</cfscript>
```

---

## Migration Best Practices

### Writing Migrations

1. **Keep migrations focused** - One logical change per migration
2. **Always include down()** - Even if it just logs that reversal isn't possible
3. **Use transactions** - Wrap changes in transaction blocks
4. **Test rollbacks** - Ensure down() methods work correctly
5. **Name descriptively** - Use clear, descriptive migration names

### Migration Examples

#### Adding an Index

```cfm
component extends="wheels.dbmigrate.Migration" {
    
    function up() {
        transaction {
            addIndex(table="products", columnNames="sku", unique=true);
        }
    }
    
    function down() {
        transaction {
            removeIndex(table="products", indexName="idx_products_sku");
        }
    }
}
```

#### Renaming a Column

```cfm
component extends="wheels.dbmigrate.Migration" {
    
    function up() {
        transaction {
            renameColumn(table="users", columnName="lastname", newColumnName="last_name");
        }
    }
    
    function down() {
        transaction {
            renameColumn(table="users", columnName="last_name", newColumnName="lastname");
        }
    }
}
```

#### Data Migration

```cfm
component extends="wheels.dbmigrate.Migration" {
    
    function up() {
        transaction {
            // Add new column
            addColumn(table="products", columnName="slug", columnType="string");
            
            // Populate with data
            products = model("Product").findAll();
            for (product in products) {
                product.update(slug=createSlug(product.name));
            }
        }
    }
    
    function down() {
        transaction {
            removeColumn(table="products", columnName="slug");
        }
    }
    
    private function createSlug(required string text) {
        return lCase(reReplace(arguments.text, "[^a-zA-Z0-9]", "-", "all"));
    }
}
```

### Environment Considerations

#### Development

- Run migrations frequently
- Test rollbacks regularly
- Use `wheels dbmigrate reset` for clean slate
- Seed with test data

#### Testing

- Reset between test runs
- Use minimal seed data
- Consider in-memory databases

#### Production

- Always backup first
- Test migrations in staging
- Use `wheels dbmigrate info` to verify
- Plan for rollback scenarios
- Consider maintenance windows

## Troubleshooting

### Common Issues

**Port Detection Failed**
```
Error: Cannot connect to database on port 0
```
Solution: Ensure server.json contains correct port configuration

**Migration Already Exists**
```
Error: Migration 20231215120000 already exists
```
Solution: Migrations are timestamp-based; wait a second before creating another

**Foreign Key Constraints**
```
Error: Cannot drop table due to foreign key constraint
```
Solution: Drop constraints before dropping tables:
```cfm
removeForeignKey(table="orders", keyName="fk_orders_users");
dropTable("users");
```

**Transaction Rollback**
```
Error: Migration failed and was rolled back
```
Solution: Check migration code for syntax errors or constraint violations

### Debugging Migrations

1. **Run migrations individually** with `wheels dbmigrate up`
2. **Check SQL output** by adding `debug=true` to migration methods
3. **Verify database state** with `wheels dbmigrate info`
4. **Test in development** before applying to production
5. **Keep backups** before major migrations

## Summary

The Wheels database commands provide a robust system for managing database changes:

- **Version control** your schema with migrations
- **Collaborate** with team members on database changes
- **Deploy** with confidence using tested migrations
- **Rollback** when needed with down migrations
- **Seed** data for development and testing

Remember: Migrations are code. Test them, review them, and version control them just like your application code.