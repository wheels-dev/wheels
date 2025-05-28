# dbmigrate remove table

Generate a migration file for dropping a database table.

## Synopsis

```bash
wheels dbmigrate remove table <table_name> [options]
```

## Description

The `dbmigrate remove table` command generates a migration file that drops an existing database table. The generated migration includes both the drop operation and a reversible up method that recreates the table structure, making the migration fully reversible.

## Arguments

### `<table_name>`
- **Type:** String
- **Required:** Yes
- **Description:** The name of the table to drop

## Options

### `--datasource`
- **Type:** String
- **Default:** Application default
- **Description:** Target datasource for the migration

### `--force`
- **Type:** Boolean
- **Default:** `false`
- **Description:** Skip safety prompts and generate migration immediately

### `--no-backup`
- **Type:** Boolean
- **Default:** `false`
- **Description:** Don't include table structure backup in the down() method

### `--cascade`
- **Type:** Boolean
- **Default:** `false`
- **Description:** Include CASCADE option to drop dependent objects

## Examples

### Basic table removal
```bash
wheels dbmigrate remove table temp_import_data
```

### Remove table with cascade
```bash
wheels dbmigrate remove table user --cascade
```

### Force removal without prompts
```bash
wheels dbmigrate remove table obsolete_log --force
```

### Remove without backup structure
```bash
wheels dbmigrate remove table temporary_data --no-backup
```

## Generated Migration Example

For the command:
```bash
wheels dbmigrate remove table product_archive
```

Generates:
```cfml
component extends="wheels.migrator.Migration" hint="Drop product_archive table" {

    function up() {
        transaction {
            dropTable("product_archive");
        }
    }

    function down() {
        transaction {
            // Recreate table structure for rollback
            createTable(name="product_archive") {
                t.increments("id");
                t.string("name");
                t.text("description");
                t.decimal("price", precision=10, scale=2);
                t.timestamps();
            }
        }
    }

}
```

## Use Cases

### Removing Temporary Tables
Clean up temporary or staging tables:
```bash
# Remove import staging table
wheels dbmigrate remove table temp_customer_import

# Remove data migration table
wheels dbmigrate remove table migration_backup_20240115
```

### Refactoring Database Schema
Remove tables during schema refactoring:
```bash
# Remove old table after data migration
wheels dbmigrate remove table legacy_orders --force

# Remove normalized table
wheels dbmigrate remove table user_preferences_old
```

### Cleaning Up Failed Features
Remove tables from cancelled features:
```bash
# Remove tables from abandoned feature
wheels dbmigrate remove table beta_feature_data
wheels dbmigrate remove table beta_feature_settings
```

### Archive Table Cleanup
Remove old archive tables:
```bash
# Remove yearly archive tables
wheels dbmigrate remove table orders_archive_2020
wheels dbmigrate remove table orders_archive_2021
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

### Using CASCADE
The `--cascade` option drops dependent objects:
```bash
# Drops table and all dependent objects
wheels dbmigrate remove table user --cascade
```

## Best Practices

### 1. Document Removals
Add clear documentation about why the table is being removed:
```bash
# Create descriptive migration
wheels dbmigrate remove table obsolete_analytics_cache

# Then edit the migration to add comments
component extends="wheels.migrator.Migration" 
  hint="Remove obsolete_analytics_cache table - replaced by Redis caching" {
```

### 2. Backup Data First
Before removing tables, create data backups:
```bash
# First create backup migration
wheels dbmigrate create blank --name=backup_user_preferences_data

# Then remove table
wheels dbmigrate remove table user_preferences
```

### 3. Staged Removal
For production systems, consider staged removal:
```bash
# Stage 1: Rename table (keep for rollback)
wheels dbmigrate create blank --name=rename_orders_to_orders_deprecated

# Stage 2: After verification period, remove
wheels dbmigrate remove table orders_deprecated
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

## Migration Structure Details

### With Backup (Default)
The generated down() method includes table structure:
```cfml
function down() {
    transaction {
        createTable(name="product") {
            t.increments("id");
            // All columns recreated
            t.timestamps();
        }
        // Indexes recreated
        addIndex(table="product", column="sku", unique=true);
    }
}
```

### Without Backup
With `--no-backup`, down() is simpler:
```cfml
function down() {
    transaction {
        announce("Table structure not backed up - manual recreation required");
    }
}
```

## Recovery Strategies

### If Removal Was Mistake
1. Don't run the migration in production
2. Use `wheels dbmigrate down` if already run
3. Restore from backup if down() fails

### Preserving Table Structure
Before removal, capture structure:
```bash
# Export table structure
wheels db schema --table=user_preferences > user_preferences_backup.sql

# Then remove
wheels dbmigrate remove table user_preferences
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