# dbmigrate create column

Generate a migration file for adding columns to an existing database table.

## Synopsis

```bash
wheels dbmigrate create column <table_name> <column_name>:<type>[:options] [more_columns...] [options]
```

## Description

The `dbmigrate create column` command generates a migration file that adds one or more columns to an existing database table. It supports all standard column types and options, making it easy to evolve your database schema incrementally.

## Arguments

### `<table_name>`
- **Type:** String
- **Required:** Yes
- **Description:** The name of the table to add columns to

### `<column_name>:<type>[:options]`
- **Type:** String
- **Required:** Yes (at least one)
- **Format:** `name:type:option1:option2=value`
- **Description:** Column definition(s) to add

## Options

### `--datasource`
- **Type:** String
- **Default:** Application default
- **Description:** Target datasource for the migration

### `--after`
- **Type:** String
- **Default:** None
- **Description:** Position new column(s) after specified column

### `--force`
- **Type:** Boolean
- **Default:** `false`
- **Description:** Overwrite existing migration file

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

## Column Options

- `:null` - Allow NULL values
- `:default=value` - Set default value
- `:limit=n` - Set column length
- `:precision=n` - Set decimal precision
- `:scale=n` - Set decimal scale
- `:index` - Create an index on this column
- `:unique` - Add unique constraint

## Examples

### Add a single column
```bash
wheels dbmigrate create column user email:string
```

### Add multiple columns
```bash
wheels dbmigrate create column product sku:string:unique weight:decimal:precision=8:scale=2 is_featured:boolean:default=false
```

### Add column with positioning
```bash
wheels dbmigrate create column user middle_name:string:null --after=first_name
```

### Add columns with indexes
```bash
wheels dbmigrate create column order shipped_at:datetime:index tracking_number:string:index
```

## Generated Migration Example

For the command:
```bash
wheels dbmigrate create column user phone:string:null country_code:string:limit=2:default='US'
```

Generates:
```cfml
component extends="wheels.migrator.Migration" hint="Add columns to user table" {

    function up() {
        transaction {
            addColumn(table="user", column="phone", type="string", null=true);
            addColumn(table="user", column="country_code", type="string", limit=2, default="US");
        }
    }

    function down() {
        transaction {
            removeColumn(table="user", column="country_code");
            removeColumn(table="user", column="phone");
        }
    }

}
```

## Use Cases

### Adding User Preferences
Add preference columns to user table:
```bash
wheels dbmigrate create column user \
  newsletter_subscribed:boolean:default=true \
  notification_email:boolean:default=true \
  theme_preference:string:default='light'
```

### Adding Audit Fields
Add tracking columns to any table:
```bash
wheels dbmigrate create column product \
  last_modified_by:integer:null \
  last_modified_at:datetime:null \
  version:integer:default=1
```

### Adding Calculated Fields
Add columns for denormalized/cached data:
```bash
wheels dbmigrate create column order \
  item_count:integer:default=0 \
  subtotal:decimal:precision=10:scale=2:default=0 \
  tax_amount:decimal:precision=10:scale=2:default=0
```

### Adding Search Columns
Add columns optimized for searching:
```bash
wheels dbmigrate create column article \
  search_text:text:null \
  slug:string:unique:index \
  tags:string:null
```

## Best Practices

### 1. Consider NULL Values
For existing tables with data, make new columns nullable or provide defaults:
```bash
# Good - nullable
wheels dbmigrate create column user bio:text:null

# Good - with default
wheels dbmigrate create column user status:string:default='active'

# Bad - will fail if table has data
wheels dbmigrate create column user required_field:string
```

### 2. Use Appropriate Types
Choose the right column type for your data:
```bash
# For short text
wheels dbmigrate create column user username:string:limit=50

# For long text
wheels dbmigrate create column post content:text

# For money
wheels dbmigrate create column invoice amount:decimal:precision=10:scale=2
```

### 3. Plan for Indexes
Add indexes for columns used in queries:
```bash
# Add indexed column
wheels dbmigrate create column order customer_email:string:index

# Or create separate index migration
wheels dbmigrate create blank --name=add_order_customer_email_index
```

### 4. Group Related Changes
Add related columns in a single migration:
```bash
# Add all address fields together
wheels dbmigrate create column customer \
  address_line1:string \
  address_line2:string:null \
  city:string \
  state:string:limit=2 \
  postal_code:string:limit=10 \
  country:string:limit=2:default='US'
```

## Advanced Scenarios

### Adding Foreign Keys
Add foreign key columns with appropriate types:
```bash
# Add foreign key column
wheels dbmigrate create column order customer_id:integer:index

# Then create constraint in blank migration
wheels dbmigrate create blank --name=add_order_customer_foreign_key
```

### Adding JSON Columns
For databases that support JSON:
```bash
# Create blank migration for JSON column
wheels dbmigrate create blank --name=add_user_preferences_json
# Then manually add JSON column type
```

### Positional Columns
Control column order in table:
```bash
# Add after specific column
wheels dbmigrate create column user display_name:string --after=username
```

## Common Pitfalls

### 1. Non-Nullable Without Default
```bash
# This will fail if table has data
wheels dbmigrate create column user required_field:string

# Do this instead
wheels dbmigrate create column user required_field:string:default='TBD'
```

### 2. Changing Column Types
This command adds columns, not modifies them:
```bash
# Wrong - trying to change type
wheels dbmigrate create column user age:integer

# Right - use blank migration for modifications
wheels dbmigrate create blank --name=change_user_age_to_integer
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