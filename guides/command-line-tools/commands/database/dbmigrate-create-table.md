# dbmigrate create table

Generate a migration file for creating a new database table.

## Synopsis

```bash
wheels dbmigrate create table <table_name> [columns...] [options]
```

## Description

The `dbmigrate create table` command generates a migration file that creates a new database table with specified columns. It automatically includes timestamp columns (createdAt, updatedAt) and provides a complete table structure following CFWheels conventions.

## Arguments

### `<table_name>`
- **Type:** String
- **Required:** Yes
- **Description:** The name of the table to create (singular form recommended)

### `[columns...]`
- **Type:** String (multiple)
- **Required:** No
- **Format:** `name:type:options`
- **Description:** Column definitions in the format name:type:options

## Options

### `--id`
- **Type:** String
- **Default:** `id`
- **Description:** Name of the primary key column (use --no-id to skip)

### `--no-id`
- **Type:** Boolean
- **Default:** `false`
- **Description:** Skip creating a primary key column

### `--timestamps`
- **Type:** Boolean
- **Default:** `true`
- **Description:** Include createdAt and updatedAt columns

### `--no-timestamps`
- **Type:** Boolean
- **Default:** `false`
- **Description:** Skip creating timestamp columns

### `--datasource`
- **Type:** String
- **Default:** Application default
- **Description:** Target datasource for the migration

### `--force`
- **Type:** Boolean
- **Default:** `false`
- **Description:** Overwrite existing migration file

## Column Types

Supported column types:
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

Column options are specified after the type with colons:
- `:null` - Allow NULL values
- `:default=value` - Set default value
- `:limit=n` - Set column length/size
- `:precision=n` - Set decimal precision
- `:scale=n` - Set decimal scale

## Examples

### Create a basic table
```bash
wheels dbmigrate create table user
```

### Create table with columns
```bash
wheels dbmigrate create table post title:string content:text author_id:integer published:boolean
```

### Create table with column options
```bash
wheels dbmigrate create table product name:string:limit=100 price:decimal:precision=10:scale=2 description:text:null
```

### Create table without timestamps
```bash
wheels dbmigrate create table configuration key:string value:text --no-timestamps
```

### Create join table without primary key
```bash
wheels dbmigrate create table users_roles user_id:integer role_id:integer --no-id
```

## Generated Migration Example

For the command:
```bash
wheels dbmigrate create table post title:string content:text author_id:integer published:boolean
```

Generates:
```cfml
component extends="wheels.migrator.Migration" hint="Create post table" {

    function up() {
        transaction {
            createTable(name="post", force=false) {
                t.increments("id");
                t.string("title");
                t.text("content");
                t.integer("author_id");
                t.boolean("published");
                t.timestamps();
            }
        }
    }

    function down() {
        transaction {
            dropTable("post");
        }
    }

}
```

## Use Cases

### Standard Entity Table
Create a typical entity table:
```bash
wheels dbmigrate create table customer \
  first_name:string \
  last_name:string \
  email:string:limit=150 \
  phone:string:null \
  is_active:boolean:default=true
```

### Join Table for Many-to-Many
Create a join table for relationships:
```bash
wheels dbmigrate create table products_categories \
  product_id:integer \
  category_id:integer \
  display_order:integer:default=0 \
  --no-id
```

### Configuration Table
Create a settings/configuration table:
```bash
wheels dbmigrate create table setting \
  key:string:limit=50 \
  value:text \
  description:text:null \
  --no-timestamps
```

### Audit Log Table
Create an audit trail table:
```bash
wheels dbmigrate create table audit_log \
  table_name:string \
  record_id:integer \
  action:string:limit=10 \
  user_id:integer \
  old_values:text:null \
  new_values:text:null \
  ip_address:string:limit=45
```

## Best Practices

### 1. Use Singular Table Names
CFWheels conventions expect singular table names:
```bash
# Good
wheels dbmigrate create table user
wheels dbmigrate create table product

# Avoid
wheels dbmigrate create table users
wheels dbmigrate create table products
```

### 2. Include Foreign Keys
Add foreign key columns for relationships:
```bash
wheels dbmigrate create table order \
  customer_id:integer \
  total:decimal:precision=10:scale=2 \
  status:string:default='pending'
```

### 3. Set Appropriate Defaults
Provide sensible defaults where applicable:
```bash
wheels dbmigrate create table article \
  title:string \
  content:text \
  is_published:boolean:default=false \
  view_count:integer:default=0
```

### 4. Consider Indexes
Plan for indexes (add them in separate migrations):
```bash
# Create table
wheels dbmigrate create table user email:string username:string

# Create index migration
wheels dbmigrate create blank --name=add_user_indexes
```

## Advanced Options

### Custom Primary Key
Specify a custom primary key name:
```bash
wheels dbmigrate create table legacy_customer \
  customer_code:string \
  name:string \
  --id=customer_code
```

### Composite Keys
For composite primary keys, use blank migration:
```bash
# First create without primary key
wheels dbmigrate create table order_item \
  order_id:integer \
  product_id:integer \
  quantity:integer \
  --no-id

# Then create blank migration for composite key
wheels dbmigrate create blank --name=add_order_item_composite_key
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