# dbmigrate create column


Generate a migration file for adding columns to an existing database table.

## Synopsis

```bash
wheels dbmigrate create column name=<column_name> tableName=<table> dataType=<type> [options]
```

## CommandBox Parameter Syntax

This command supports multiple parameter formats:

- **Named parameters**: `name=value` (e.g., `name=email`, `tableName=users`, `dataType=string`)
- **Flag parameters**: `--flag` equals `flag=true` (e.g., `--allowNull=false`)
- **Flag with value**: `--flag=value` (same as named parameters)

**Parameter Mixing Rules:**

**ALLOWED:**
- All named: `name=email tableName=users dataType=string`
- Named parameters only (no positional support)

**NOT ALLOWED:**
- Positional parameters: This command does not support positional parameters

**Recommendation:** Use named parameters for all values: `name=email tableName=users dataType=string allowNull=false`

## Description

The `dbmigrate create column` command generates a migration file that adds a column to an existing database table. It supports standard column types and various options for column configuration.

## Parameters

**Note:** Parameters are listed in the order they appear in the command signature.

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `name` | string | Yes | - | The column name to add |
| `tableName` | string | Yes | - | The name of the database table to modify |
| `dataType` | string | Yes | - | The column type to add |
| `default` | any | No | - | The default value to set for the column |
| `allowNull` | boolean | No | true | Should the column allow nulls |
| `limit` | number | No | - | The character limit of the column |
| `precision` | number | No | - | The precision of the numeric column |
| `scale` | number | No | - | The scale of the numeric column |

## Column Types

- `string` - VARCHAR(255)
- `text` - TEXT/CLOB
- `integer` - INTEGER
- `biginteger` - BIGINT
- `float` - FLOAT
- `decimal` - DECIMAL
- `boolean` - BOOLEAN/BIT
- `date` - DATE
- `time` - TIME
- `datetime` - DATETIME/TIMESTAMP
- `timestamp` - TIMESTAMP
- `binary` - BLOB/BINARY

## Migration File Naming

The generated migration file will be named with a timestamp and description:
```
[timestamp]_[tablename]_[columnname]_create_column.cfc
```

Example:
```
20240125160000_user_email_create_column.cfc
```

## Examples

### Add a simple column
```bash
wheels dbmigrate create column name=email tableName=user dataType=string
```

### Add column with default value
```bash
wheels dbmigrate create column name=is_active tableName=user dataType=boolean default=true
```

### Add nullable column with limit
```bash
wheels dbmigrate create column name=bio tableName=user dataType=string allowNull=true limit=500
```

### Add decimal column with precision
```bash
wheels dbmigrate create column name=price tableName=product dataType=decimal precision=10 scale=2
```

## Generated Migration Example

For the command:
```bash
wheels dbmigrate create column name=phone tableName=user dataType=string allowNull=true
```

Generates:
```cfml
component extends="wheels.migrator.Migration" hint="create column phone in user table" {

    function up() {
        transaction {
            addColumn(table="user", columnType="string", columnName="phone", allowNull=true);
        }
    }

    function down() {
        transaction {
            removeColumn(table="user", column="phone");
        }
    }

}
```

## Use Cases

### Adding User Preferences
Add preference column to user table:
```bash
# Create separate migrations for each column
wheels dbmigrate create column name=newsletter_subscribed tableName=user dataType=boolean default=true
wheels dbmigrate create column name=theme_preference tableName=user dataType=string default="light"
```

### Adding Audit Fields
Add tracking column to any table:
```bash
wheels dbmigrate create column name=last_modified_by tableName=product dataType=integer allowNull=true
wheels dbmigrate create column name=last_modified_at tableName=product dataType=datetime allowNull=true
```

### Adding Price Fields
Add decimal columns for pricing:
```bash
wheels dbmigrate create column name=price tableName=product dataType=decimal precision=10 scale=2 default=0
wheels dbmigrate create column name=cost tableName=product dataType=decimal precision=10 scale=2
```

## Best Practices

### 1. Consider NULL Values
For existing tables with data, make new columns nullable or provide defaults:
```bash
# Good - nullable
wheels dbmigrate create column name=bio tableName=user dataType=text allowNull=true

# Good - with default
wheels dbmigrate create column name=status tableName=user dataType=string default="active"

# Bad - will fail if table has data (not nullable, no default)
wheels dbmigrate create column name=required_field tableName=user dataType=string --allowNull=false
```

### 2. Use Appropriate Types
Choose the right column type for your data:
```bash
# For short text
wheels dbmigrate create column name=username tableName=user dataType=string limit=50

# For long text
wheels dbmigrate create column name=content tableName=post dataType=text

# For money
wheels dbmigrate create column name=amount tableName=invoice dataType=decimal precision=10 scale=2
```

### 3. One Column Per Migration
This command creates one column at a time:
```bash
# Create separate migrations for related columns
wheels dbmigrate create column name=address_line1 tableName=customer dataType=string
wheels dbmigrate create column name=city tableName=customer dataType=string
wheels dbmigrate create column name=state tableName=customer dataType=string limit=2
```

### 4. Plan Your Schema
Think through column requirements before creating:
- Data type and size
- Null constraints
- Default values
- Index requirements

## Advanced Scenarios

### Adding Foreign Keys
Add foreign key columns with appropriate types:
```bash
# Add foreign key column
wheels dbmigrate create column name=customer_id tableName=order dataType=integer

# Then create index in separate migration
wheels dbmigrate create blank name=add_order_customer_id_index
```

### Complex Column Types
For special column types, use blank migrations:
```bash
# Create blank migration for custom column types
wheels dbmigrate create blank name=add_user_preferences_json
# Then manually add the column with custom SQL
```

## Common Pitfalls

### 1. Non-Nullable Without Default
```bash
# This will fail if table has data
wheels dbmigrate create column name=required_field tableName=user dataType=string --allowNull=false

# Do this instead
wheels dbmigrate create column name=required_field tableName=user dataType=string default="pending"
```

### 2. Changing Column Types
This command adds columns, not modifies them:
```bash
# Wrong - trying to change existing column type
wheels dbmigrate create column name=age tableName=user dataType=integer

# Right - use blank migration for modifications
wheels dbmigrate create blank name=change_user_age_to_integer
```

## Notes

- The migration includes automatic rollback with removeColumn()
- Column order in down() is reversed for proper rollback
- Always test migrations with data in development
- Consider the impact on existing queries and code

## Related Commands

- [`wheels dbmigrate create table`](dbmigrate-create-table.md) - Create new tables
- [`wheels dbmigrate create blank`](dbmigrate-create-blank.md) - Create custom migrations
- [`wheels dbmigrate remove table`](dbmigrate-remove-table.md) - Remove tables
- [`wheels dbmigrate up`](dbmigrate-up.md) - Run migrations
- [`wheels dbmigrate down`](dbmigrate-down.md) - Rollback migrations