# wheels db schema

Visualize the current database schema.

## Synopsis

```bash
wheels db schema [options]
```

## Description

The `wheels db schema` command retrieves and displays the current database schema in various formats. This is useful for documentation, debugging, and understanding your database structure.

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `format` | string | No | "sql" | Output format (text, json, or sql) |
| `--save` | boolean | No | false | Save output to file instead of console |
| `file` | string | No | - | File path to write schema to (when using --save) |
| `engine` | string | No | "default" | Database engine to use |

## Examples

### Display schema in console (default SQL format)
```bash
wheels db schema
```

### Display schema as text
```bash
wheels db schema format=text
```

### Export schema to file
```bash
wheels db schema --save file=schema.sql
```

### Export as JSON
```bash
wheels db schema format=json --save file=schema.json
```

## Output Formats

### Text Format
Displays a human-readable table structure:
```
TABLE: USERS
--------------------------------------------------------------------------------
  id INTEGER NOT NULL PRIMARY KEY
  username VARCHAR(50) NOT NULL
  email VARCHAR(150) NOT NULL
  created_at TIMESTAMP
  updated_at TIMESTAMP

  INDEXES:
  - UNIQUE INDEX idx_users_email (email)
  - INDEX idx_users_username (username)
```

### SQL Format (Default)
Generates CREATE TABLE statements:
```sql
CREATE TABLE users (
    id INTEGER NOT NULL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(150) NOT NULL,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE UNIQUE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
```

### JSON Format
Provides structured schema information:
```json
{
  "tables": {
    "users": {
      "columns": [
        {"name": "id", "type": "INTEGER", "nullable": false, "primaryKey": true},
        {"name": "username", "type": "VARCHAR(50)", "nullable": false},
        {"name": "email", "type": "VARCHAR(150)", "nullable": false}
      ],
      "indexes": [
        {"name": "idx_users_email", "columns": ["email"], "unique": true}
      ]
    }
  }
}
```

## Use Cases

### Version Control
Track schema changes in git:
```bash
# Export schema after migrations
wheels dbmigrate latest
wheels db schema --save file=db/schema.sql

# Commit schema file
git add db/schema.sql
git commit -m "Update database schema"
```

### Documentation
Generate schema documentation:
```bash
# Export human-readable schema
wheels db schema format=text --save file=docs/database-schema.txt

# Export as JSON for documentation tools
wheels db schema format=json --save file=docs/database-schema.json
```

### Backup Before Changes
Create schema backups before major updates:
```bash
# Backup current schema
wheels db schema format=sql --save file=backups/schema-$(date +%Y%m%d).sql

# Make your changes
wheels dbmigrate latest

# Export new schema
wheels db schema format=sql --save file=db/schema.sql
```

### Review Database Structure
Quickly review your database structure:
```bash
# View all tables in text format
wheels db schema format=text

# Export for team review
wheels db schema format=text --save file=database-review.txt
```

## Notes on Table Filtering

Currently, the command exports all tables in the database. Future versions may support filtering specific tables.

## Best Practices

### 1. Regular Exports
Export schema after migrations:
```bash
# After running migrations
wheels dbmigrate latest
wheels db schema --save file=db/schema.sql
```

### 2. Use Version Control
Track schema changes over time:
```bash
# Add to git
git add db/schema.sql
git commit -m "Update schema after adding user table"
```

### 3. Document Changes
Keep a record of schema state:
```bash
# Before major changes
wheels db schema --save file=db/schema-before-refactor.sql

# After changes
wheels db schema --save file=db/schema-after-refactor.sql
```

## Integration with Migrations

### Schema vs Migrations
- Migrations: Track incremental changes over time
- Schema: Shows current database state

### Typical Workflow
1. Create migration: `wheels dbmigrate create table name=users`
2. Edit and run migration: `wheels dbmigrate up`
3. Export current schema: `wheels db schema --save file=db/schema.sql`
4. Commit both: `git add app/migrator/migrations/* db/schema.sql`

## Notes

- Schema export captures current database state
- The command connects to your configured datasource
- Output varies based on your database type (MySQL, PostgreSQL, etc.)
- Some database-specific features may require manual adjustment
- Use migrations for incremental changes, schemas for documentation

## Related Commands

- [`wheels dbmigrate latest`](dbmigrate-latest.md) - Run all migrations
- [`wheels dbmigrate info`](dbmigrate-info.md) - View migration status
- [`wheels db seed`](db-seed.md) - Seed database with data
- [`wheels generate model`](../generate/model.md) - Generate models from schema