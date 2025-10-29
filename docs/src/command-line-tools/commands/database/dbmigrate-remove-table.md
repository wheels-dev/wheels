# dbmigrate remove table

Generate a migration file for dropping a database table.

## Synopsis

```bash
wheels dbmigrate remove table name=<table_name>
```

Alias: `wheels db remove table`

## CommandBox Parameter Syntax

This command supports multiple parameter formats:

- **Named parameters**: `name=value` (e.g., `name=users`)
- **Flag parameters**: `--flag=value` (e.g., `--name=users`)

**Parameter Mixing Rules:**

✅ **ALLOWED:**
- Named: `wheels dbmigrate remove table name=users`
- Flag: `wheels dbmigrate remove table --name=users`

❌ **NOT ALLOWED:**
- Positional parameters: This command does not support positional parameters

**Recommendation:** Use named parameters: `wheels dbmigrate remove table name=users`

## Description

The `dbmigrate remove table` command generates a migration file that drops an existing database table. The generated migration includes a dropTable() call in the up() method.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | string | Yes | The name of the table to remove |

## Examples

### Basic table removal
```bash
wheels dbmigrate remove table name=temp_import_data
```

### Remove user table
```bash
wheels dbmigrate remove table name=user
```

### Remove archive table
```bash
wheels dbmigrate remove table name=orders_archive_2023
```

## Generated Migration Example

For the command:
```bash
wheels dbmigrate remove table name=product_archive
```

Generates:
```cfml
component extends="wheels.migrator.Migration" hint="remove product_archive table" {

    function up() {
        transaction {
            dropTable("product_archive");
        }
    }

    function down() {
        transaction {
            // Add code here to recreate the table if needed for rollback
            // createTable(name="product_archive") { ... }
        }
    }

}
```

## Use Cases

### Removing Temporary Tables
Clean up temporary or staging tables:
```bash
# Remove import staging table
wheels dbmigrate remove table name=temp_customer_import

# Remove data migration table
wheels dbmigrate remove table name=migration_backup_20240115
```

### Refactoring Database Schema
Remove tables during schema refactoring:
```bash
# Remove old table after data migration
wheels dbmigrate remove table name=legacy_orders

# Remove deprecated table
wheels dbmigrate remove table name=user_preferences_old
```

### Cleaning Up Failed Features
Remove tables from cancelled features:
```bash
# Remove tables from abandoned feature
wheels dbmigrate remove table name=beta_feature_data
wheels dbmigrate remove table name=beta_feature_settings
```

### Archive Table Cleanup
Remove old archive tables:
```bash
# Remove yearly archive tables
wheels dbmigrate remove table name=orders_archive_2020
wheels dbmigrate remove table name=orders_archive_2021
```

## Safety Considerations

### Data Loss Warning
**CRITICAL**: Dropping a table permanently deletes all data. Always:
1. Backup the table data before removal
2. Verify data has been migrated if needed
3. Test in development/staging first
4. Have a rollback plan

### Dependent Objects
Consider objects that depend on the table:
- Foreign key constraints
- Views
- Stored procedures
- Triggers
- Application code

### Handling Dependencies
Be aware of dependent objects when removing tables:
- Foreign key constraints
- Views that reference the table
- Stored procedures using the table
- Application code dependencies

## Best Practices

### 1. Document Removals
Add clear documentation about why the table is being removed:
```bash
# Create descriptive migration
wheels dbmigrate remove table name=obsolete_analytics_cache

# Then edit the migration file to add detailed comments about why it's being removed
```

### 2. Backup Data First
Before removing tables, create data backups:
```bash
# First backup the data
wheels db schema format=sql > backup_before_removal.sql

# Then create removal migration
wheels dbmigrate remove table name=user_preferences
```

### 3. Staged Removal
For production systems, consider staged removal:
```bash
# Stage 1: Rename table (keep for rollback)
wheels dbmigrate create blank name=rename_orders_to_orders_deprecated

# Stage 2: After verification period, remove
wheels dbmigrate remove table name=orders_deprecated
```

### 4. Check Dependencies
Verify no active dependencies before removal:
```sql
-- Check foreign keys
SELECT * FROM information_schema.referential_constraints 
WHERE referenced_table_name = 'table_name';

-- Check views
SELECT * FROM information_schema.views 
WHERE table_schema = DATABASE() 
AND view_definition LIKE '%table_name%';
```

## Migration Structure

The generated migration contains:
- An `up()` method with `dropTable()` 
- An empty `down()` method for you to implement rollback logic if needed

You should edit the `down()` method to add table recreation logic if you want the migration to be reversible.

## Recovery Strategies

### If Removal Was Mistake
1. Don't run the migration in production
2. Use `wheels dbmigrate down` if already run
3. Restore from backup if down() fails

### Preserving Table Structure
Before removal, capture structure:
```bash
# Export entire database schema
wheels db schema format=sql --save file=schema_backup.sql

# Then remove table
wheels dbmigrate remove table name=user_preferences
```

## Notes

- The command analyzes table structure before generating migration
- Foreign key constraints must be removed before table removal
- The migration is reversible if table structure is preserved
- Always review generated migration before running

## Related Commands

- [`wheels dbmigrate create table`](dbmigrate-create-table.md) - Create tables
- [`wheels dbmigrate create blank`](dbmigrate-create-blank.md) - Create custom migrations
- [`wheels dbmigrate up`](dbmigrate-up.md) - Run migrations
- [`wheels dbmigrate down`](dbmigrate-down.md) - Rollback migrations
- [`wheels db schema`](db-schema.md) - Export table schemas