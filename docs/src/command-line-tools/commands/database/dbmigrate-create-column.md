# dbmigrate create column
*This command may not work with options as expected. A complete and stable version with fully functional options is **coming soon**.*

Generate a migration file for adding columns to an existing database table.

## Synopsis

```bash
wheels dbmigrate create column name=<table_name> data-type=<type> column-name=<column> [options]
```

Alias: `wheels db create column`

## Description

The `dbmigrate create column` command generates a migration file that adds a column to an existing database table. It supports standard column types and various options for column configuration.

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `name` | string | Yes | - | The name of the database table to modify |
| `data-type` | string | Yes | - | The column type to add |
| `column-name` | string | No | - | The column name to add |
| `default` | any | No | - | The default value to set for the column |
| `--null` | boolean | No | true | Should the column allow nulls |
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
[timestamp]_create_column_[columnname]_in_[tablename]_table.cfc
```

Example:
```
20240125160000_create_column_email_in_user_table.cfc
```

## Examples

### Add a simple column
```bash
wheels dbmigrate create column name=user data-type=string column-name=email
```

### Add column with default value
```bash
wheels dbmigrate create column name=user data-type=boolean column-name=is_active default=true
```

### Add nullable column with limit
```bash
wheels dbmigrate create column name=user data-type=string column-name=bio --null=true limit=500
```

### Add decimal column with precision
```bash
wheels dbmigrate create column name=product data-type=decimal column-name=price precision=10 scale=2
```

## Generated Migration Example

For the command:
```bash
wheels dbmigrate create column name=user data-type=string column-name=phone --null=true
```

Generates:
```cfml
component extends="wheels.migrator.Migration" hint="create column phone in user table" {

    function up() {
        transaction {
            addColumn(table="user", columnType="string", columnName="phone", null=true);
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
wheels dbmigrate create column name=user data-type=boolean column-name=newsletter_subscribed default=true
wheels dbmigrate create column name=user data-type=string column-name=theme_preference default="light"
```

### Adding Audit Fields
Add tracking column to any table:
```bash
wheels dbmigrate create column name=product data-type=integer column-name=last_modified_by --null=true
wheels dbmigrate create column name=product data-type=datetime column-name=last_modified_at --null=true
```

### Adding Price Fields
Add decimal columns for pricing:
```bash
wheels dbmigrate create column name=product data-type=decimal column-name=price precision=10 scale=2 default=0
wheels dbmigrate create column name=product data-type=decimal column-name=cost precision=10 scale=2
```

## Best Practices

### 1. Consider NULL Values
For existing tables with data, make new columns nullable or provide defaults:
```bash
# Good - nullable
wheels dbmigrate create column name=user data-type=text column-name=bio --null=true

# Good - with default
wheels dbmigrate create column name=user data-type=string column-name=status default="active"

# Bad - will fail if table has data (not nullable, no default)
wheels dbmigrate create column name=user data-type=string column-name=required_field --null=false
```

### 2. Use Appropriate Types
Choose the right column type for your data:
```bash
# For short text
wheels dbmigrate create column name=user data-type=string column-name=username limit=50

# For long text
wheels dbmigrate create column name=post data-type=text column-name=content

# For money
wheels dbmigrate create column name=invoice data-type=decimal column-name=amount precision=10 scale=2
```

### 3. One Column Per Migration
This command creates one column at a time:
```bash
# Create separate migrations for related columns
wheels dbmigrate create column name=customer data-type=string column-name=address_line1
wheels dbmigrate create column name=customer data-type=string column-name=city
wheels dbmigrate create column name=customer data-type=string column-name=state limit=2
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
wheels dbmigrate create column name=order data-type=integer column-name=customer_id

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
wheels dbmigrate create column name=user data-type=string column-name=required_field --null=false

# Do this instead
wheels dbmigrate create column name=user data-type=string column-name=required_field default="pending"
```

### 2. Changing Column Types
This command adds columns, not modifies them:
```bash
# Wrong - trying to change existing column type
wheels dbmigrate create column name=user data-type=integer column-name=age

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