# dbmigrate create blank


Create an empty database migration file with up and down methods.

## Synopsis

```bash
wheels dbmigrate create blank <name>
```

## CommandBox Parameter Syntax

This command supports multiple parameter formats:

- **Positional parameters**: `wheels dbmigrate create blank addIndexes` (name as positional)
- **Named parameters**: `name=value` (e.g., `name=addIndexes`, `description="Add indexes"`)
- **Flag parameters**: `--flag=value` (e.g., `--name=addIndexes`)

**Parameter Mixing Rules:**

**ALLOWED:**
- Positional: `wheels dbmigrate create blank addIndexes`
- All named: `name=addIndexes description="Custom migration"`
- Positional + named: `wheels dbmigrate create blank addIndexes description="Add indexes"`

**NOT ALLOWED:**
- Mixing positional + named for same parameter: `wheels dbmigrate create blank addIndexes name=other`

**Recommendation:** Use positional for name, named for optional parameters: `wheels dbmigrate create blank addIndexes description="My migration"`

## Description

The `dbmigrate create blank` command generates a new empty migration file with the basic structure including `up()` and `down()` methods. This provides a starting point for custom migrations where you need full control over the migration logic.

## Options

### `--name`
- **Type:** String
- **Required:** Yes
- **Description:** The name of the migration (will be prefixed with timestamp)


### `--description`
- **Type:** String
- **Default:** Empty
- **Description:** Add a description comment to the migration file

## Examples

### Create a basic empty migration
```bash
# Positional (recommended)
wheels dbmigrate create blank add_custom_indexes

# OR flag syntax
wheels dbmigrate create blank --name=add_custom_indexes

# OR named
wheels dbmigrate create blank name=add_custom_indexes
```

### Create migration with description
```bash
# Positional + named (recommended)
wheels dbmigrate create blank update_user_permissions description="Add role-based permissions to users"

# OR all flags
wheels dbmigrate create blank --name=update_user_permissions --description="Add role-based permissions to users"

# OR all named
wheels dbmigrate create blank name=update_user_permissions description="Add role-based permissions to users"
```


## Generated File Structure

The command creates a file named `YYYYMMDDHHmmss_<name>.cfc` with the following structure:

```cfml
component extends="wheels.migrator.Migration" hint="<description>" {

    function up() {
        transaction {
            // Add your migration code here
        }
    }

    function down() {
        transaction {
            // Add code to reverse the migration
        }
    }

}
```

## Use Cases

### Custom Database Operations
For complex operations not covered by other generators:
```bash
# Create migration for custom stored procedure
wheels dbmigrate create blank --name=create_reporting_procedures

# Edit the file to add:
# - CREATE PROCEDURE statements
# - Complex SQL operations
# - Multiple related changes
```

### Data Migrations
When you need to migrate data, not just schema:
```bash
# Create data migration
wheels dbmigrate create blank --name=normalize_user_emails

# Edit to add data transformation logic
# Example: lowercase all email addresses
```

### Multi-Step Operations
For migrations requiring multiple coordinated changes:
```bash
# Create complex migration
wheels dbmigrate create blank --name=refactor_order_system

# Edit to include:
# - Create new tables
# - Migrate data
# - Drop old tables
# - Update foreign keys
```

### Database-Specific Features
For database-specific features not abstracted by Wheels:
```bash
# Create migration for PostgreSQL-specific features
wheels dbmigrate create blank --name=add_json_columns

# Edit to use PostgreSQL JSON operations
```

## Best Practices

### 1. Descriptive Names
Use clear, descriptive names that indicate the migration's purpose:
```bash
# Good
wheels dbmigrate create blank --name=add_user_authentication_tokens

# Bad
wheels dbmigrate create blank --name=update1
```

### 2. Implement Both Methods
Always implement both up() and down() methods:
```cfml
function up() {
    transaction {
        execute("CREATE INDEX idx_users_email ON users(email)");
    }
}

function down() {
    transaction {
        execute("DROP INDEX idx_users_email");
    }
}
```

### 3. Use Transactions
Wrap operations in transactions for atomicity:
```cfml
function up() {
    transaction {
        // All operations succeed or all fail
        createTable("new_table");
        execute("INSERT INTO new_table SELECT * FROM old_table");
        dropTable("old_table");
    }
}
```

### 4. Add Comments
Document complex operations:
```cfml
function up() {
    transaction {
        // Create composite index for query optimization
        // This supports the findActiveUsersByRegion() query
        execute("
            CREATE INDEX idx_users_active_region 
            ON users(is_active, region_id) 
            WHERE is_active = 1
        ");
    }
}
```

## Available Migration Methods

Within your blank migration, you can use these helper methods:

- `createTable(name, options)` - Create a new table
- `dropTable(name)` - Drop a table
- `addColumn(table, column, type, options)` - Add a column
- `removeColumn(table, column)` - Remove a column
- `changeColumn(table, column, type, options)` - Modify a column
- `addIndex(table, columnNames, unique, indexName)` - Add an index
- `removeIndex(table, column)` - Remove an index
- `execute(sql)` - Execute raw SQL
- `announce(message)` - Output a message during migration

## Notes

- Migration files are created in `/app/migrator/migrations/` or your configured migration path
- The timestamp ensures migrations run in the correct order
- Always test migrations in development before production
- Keep migrations focused on a single purpose

## Related Commands

- [`wheels dbmigrate create table`](dbmigrate-create-table.md) - Create a table migration
- [`wheels dbmigrate create column`](dbmigrate-create-column.md) - Create a column migration
- [`wheels dbmigrate up`](dbmigrate-up.md) - Run migrations
- [`wheels dbmigrate down`](dbmigrate-down.md) - Rollback migrations
- [`wheels dbmigrate info`](dbmigrate-info.md) - View migration status