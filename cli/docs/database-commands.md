# Database Commands

The Wheels CLI includes comprehensive database management commands, including migrations, seeding, and schema visualization.

## DBMigrate Commands

Database migrations allow you to evolve your database schema over time while keeping track of the changes.

### DBMigrate Create

Creates a new database migration file.

#### Usage

```bash
wheels dbmigrate create [type] [name] [column] [columnType] [default] [null] [limit] [precision] [scale]
```

#### Parameters

- `type`: Type of migration (table, column, blank)
- `name`: Name of the migration target (e.g., table name)
- `column`: Column name (for column migrations)
- `columnType`: Data type of column (string, text, integer, float, boolean, date, datetime, etc.)
- `default`: Default value for the column
- `null`: Allow NULL values (true/false)
- `limit`: Character limit for string columns
- `precision`: Precision for decimal columns
- `scale`: Scale for decimal columns

#### Examples

```bash
# Create a new table migration
wheels dbmigrate create table users

# Create a column migration
wheels dbmigrate create column email string table=users

# Create a blank migration
wheels dbmigrate create blank add_indexes
```

### DBMigrate Up

Runs all pending migrations or a specified number of pending migrations.

#### Usage

```bash
wheels dbmigrate up [migrationsToRun]
```

#### Parameters

- `migrationsToRun`: Number of migrations to run (optional, default: all)

#### Examples

```bash
# Run all pending migrations
wheels dbmigrate up

# Run only the next 2 pending migrations
wheels dbmigrate up 2
```

### DBMigrate Down

Reverts the last migration or a specified number of migrations.

#### Usage

```bash
wheels dbmigrate down [migrationsToRun]
```

#### Parameters

- `migrationsToRun`: Number of migrations to revert (optional, default: 1)

#### Examples

```bash
# Revert the last migration
wheels dbmigrate down

# Revert the last 3 migrations
wheels dbmigrate down 3
```

### DBMigrate Reset

Resets the database by reverting and reapplying all migrations.

#### Usage

```bash
wheels dbmigrate reset
```

#### Examples

```bash
# Reset the database
wheels dbmigrate reset
```

### DBMigrate Latest

Migrates the database to the latest version by running all pending migrations.

#### Usage

```bash
wheels dbmigrate latest
```

#### Examples

```bash
# Update database to the latest version
wheels dbmigrate latest
```

### DBMigrate Info

Displays information about migration status.

#### Usage

```bash
wheels dbmigrate info
```

#### Examples

```bash
# Show migration information
wheels dbmigrate info
```

## DB Seed

Generate and populate test data for your application.

### Usage

```bash
wheels db:seed [--models=] [--count=5] [--environment=] [--dataFile=]
```

### Parameters

- `models`: Comma-delimited list of models to seed (default: all)
- `count`: Number of records to generate per model (default: 5)
- `environment`: Environment to seed (default: current)
- `dataFile`: Path to JSON file containing seed data (optional)

### Examples

```bash
# Seed all models with default count
wheels db:seed

# Seed specific models with a custom count
wheels db:seed --models=user,post --count=10

# Seed using data from a file
wheels db:seed --dataFile=seed-data.json
```

### Data File Format

When using a data file, it should be structured as a JSON object with model names as keys and arrays of records as values:

```json
{
  "user": [
    {
      "firstName": "John",
      "lastName": "Smith",
      "email": "john@example.com"
    },
    {
      "firstName": "Jane",
      "lastName": "Doe",
      "email": "jane@example.com"
    }
  ],
  "post": [
    {
      "title": "First Post",
      "body": "This is the content of the first post."
    }
  ]
}
```

## DB Schema

Visualize the current database schema in various formats.

### Usage

```bash
wheels db:schema [--format=text] [--output=] [--tables=]
```

### Parameters

- `format`: Output format (text, json, or sql) (default: text)
- `output`: File to write schema to (optional, defaults to console)
- `tables`: Comma-delimited list of tables to include (default: all)

### Examples

```bash
# Display schema in text format
wheels db:schema

# Output schema as SQL to a file
wheels db:schema --format=sql --output=schema.sql

# Display schema for specific tables
wheels db:schema --tables=users,posts

# Output schema as JSON
wheels db:schema --format=json
```

### Output Formats

- **text**: Human-readable text format with tables, columns, and relationships
- **json**: Structured JSON format with detailed schema information
- **sql**: SQL statements that can be used to recreate the schema

## Notes on Database Management

### Migrations Best Practices

1. Always use migrations for schema changes to maintain consistency across environments
2. Keep migrations small and focused on a single change
3. Never modify existing migrations after they've been applied to production
4. Use timestamps in migration names to ensure proper ordering

### Seeding Data

- Use seeding for development and testing environments
- Create meaningful test data that resembles production data
- Consider using factories for generating consistent test data
- Seed files can be used to provide a consistent starting point for all developers

### Schema Management

- Regularly generate schema documentation to keep track of your database structure
- Store SQL schema dumps in version control as a reference
- Use schema visualization to understand relationships between tables