# Database Management

The Wheels CLI provides comprehensive database management commands that make it easy to create, manage, and maintain your application's database throughout the development lifecycle.

## Overview

Database management in Wheels is divided into two main categories:

1. **Database Commands (`wheels db`)** - High-level database operations
2. **Migration Commands (`wheels dbmigrate`)** - Schema versioning and changes

This guide covers the database management commands. For migration-specific operations, see the [migrations guide](dbmigrate-latest.md).

## Database Lifecycle Commands

### Creating a Database

The `wheels db create` command creates a new database based on your datasource configuration:

```bash
# Create database using default datasource
wheels db create

# Create database for specific datasource
wheels db create --datasource=myapp_dev

# Create database for specific environment
wheels db create --environment=production
```

**Note**: The datasource must already be configured in your CFML server admin. The command will create the database itself but not the datasource configuration.

### Dropping a Database

The `wheels db drop` command removes an existing database:

```bash
# Drop database (with confirmation)
wheels db drop

# Drop database without confirmation
wheels db drop --force

# Drop specific datasource
wheels db drop --datasource=myapp_dev
```

**Warning**: This is a destructive operation. Always backup important data before dropping a database.

### Database Setup

The `wheels db setup` command performs a complete database initialization:

```bash
# Full setup: create + migrate + seed
wheels db setup

# Setup without seeding
wheels db setup --skip-seed

# Setup with custom seed count
wheels db setup --seed-count=20
```

This is ideal for setting up a new development environment or initializing a test database.

### Database Reset

The `wheels db reset` command completely rebuilds your database:

```bash
# Reset database (drop + create + migrate + seed)
wheels db reset

# Reset without confirmation
wheels db reset --force

# Reset without seeding
wheels db reset --skip-seed

# Reset specific environment
wheels db reset --environment=testing
```

**Important**: This command will destroy all existing data. Use with caution, especially in production environments.

## Data Management

### Seeding the Database

The `wheels db seed` command populates your database with test or sample data:

```bash
# Seed with default settings (5 records per model)
wheels db seed

# Seed with custom record count
wheels db seed --count=10

# Seed specific models only
wheels db seed --models=user,post,comment

# Seed from a JSON file
wheels db seed --dataFile=seeds/test-data.json
```

Example seed data file format:
```json
{
  "users": [
    {
      "name": "John Doe",
      "email": "john@example.com",
      "role": "admin"
    },
    {
      "name": "Jane Smith",
      "email": "jane@example.com",
      "role": "user"
    }
  ],
  "posts": [
    {
      "title": "Welcome Post",
      "content": "This is the first post",
      "userId": 1
    }
  ]
}
```

## Status and Information Commands

### Checking Migration Status

The `wheels db status` command shows the current state of your migrations:

```bash
# Show migration status in table format
wheels db status

# Show status in JSON format
wheels db status --format=json

# Show only pending migrations
wheels db status --pending
```

Output example:
```
| Version              | Description                      | Status   | Applied At         |
|---------------------|----------------------------------|----------|-------------------|
| 20231201120000      | CreateUsersTable                 | applied  | 2023-12-01 12:30  |
| 20231202140000      | AddEmailToUsers                  | applied  | 2023-12-02 14:15  |
| 20231203160000      | CreatePostsTable                 | pending  | Not applied       |
```

### Checking Database Version

The `wheels db version` command shows the current schema version:

```bash
# Show current version
wheels db version

# Show detailed version information
wheels db version --detailed
```

## Migration Management

### Rolling Back Migrations

The `wheels db rollback` command reverses previously applied migrations:

```bash
# Rollback last migration
wheels db rollback

# Rollback multiple migrations
wheels db rollback --steps=3

# Rollback to specific version
wheels db rollback --target=20231201120000

# Force rollback without confirmation
wheels db rollback --steps=5 --force
```

## Backup and Restore

### Creating Database Backups

The `wheels db dump` command exports your database:

```bash
# Basic dump (auto-named with timestamp)
wheels db dump

# Dump to specific file
wheels db dump --output=backup.sql

# Dump schema only (no data)
wheels db dump --schema-only

# Dump data only (no schema)
wheels db dump --data-only

# Dump specific tables
wheels db dump --tables=users,posts,comments

# Dump with compression
wheels db dump --output=backup.sql.gz --compress
```

### Restoring from Backups

The `wheels db restore` command imports a database dump:

```bash
# Restore from SQL file
wheels db restore backup.sql

# Restore compressed file
wheels db restore backup.sql.gz --compressed

# Clean restore (drop existing objects first)
wheels db restore backup.sql --clean

# Force restore without confirmation
wheels db restore backup.sql --force
```

## Common Workflows

### Setting Up a New Development Environment

```bash
# 1. Clone the repository
git clone https://github.com/myapp/repo.git
cd repo

# 2. Install dependencies
box install

# 3. Setup database
wheels db setup

# 4. Start the server
server start
```

### Resetting Development Database

```bash
# Quick reset with fresh data
wheels db reset --force

# Or manually:
wheels db drop --force
wheels db create
wheels dbmigrate latest
wheels db seed --count=10
```

### Production Database Backup

```bash
# Create timestamped backup
wheels db dump --compress

# Or with custom filename
wheels db dump --output=prod-backup-$(date +%Y%m%d).sql.gz --compress
```

### Migrating Between Environments

```bash
# Export from development
wheels db dump --output=dev-data.sql --environment=development

# Import to staging
wheels db restore dev-data.sql --environment=staging
```

## Interactive Database Shell

The `wheels db shell` command provides direct access to your database's interactive shell:

```bash
# Launch CLI shell for current datasource
wheels db shell

# Launch web-based console (H2 only)
wheels db shell --web

# Use specific datasource
wheels db shell --datasource=myapp_dev

# Execute single command
wheels db shell --command="SELECT COUNT(*) FROM users"
```

### Database-Specific Shells

**H2 Database:**
```bash
# CLI shell
wheels db shell

# Web console (opens in browser)
wheels db shell --web
```

**MySQL:**
```bash
# Opens mysql client
wheels db shell
# Connects to: mysql -h host -P port -u user -p database
```

**PostgreSQL:**
```bash
# Opens psql client
wheels db shell
# Connects to: psql -h host -p port -U user -d database
```

**SQL Server:**
```bash
# Opens sqlcmd client
wheels db shell
# Connects to: sqlcmd -S server -d database -U user
```

### Shell Requirements

The database shell commands require the appropriate database client tools to be installed:

- **H2**: No additional installation needed (included with Lucee)
- **MySQL**: Install `mysql` client
- **PostgreSQL**: Install `psql` client
- **SQL Server**: Install `sqlcmd` client

## Database Support

The database commands support multiple database engines:

- **MySQL/MariaDB** - Full support for all operations
- **PostgreSQL** - Full support for all operations
- **SQL Server** - Full support for most operations
- **H2** - Full support (auto-created databases)
- **Oracle** - Limited support (basic operations)

## Configuration

Database commands use the datasource configuration from your Wheels application. You can override settings using command parameters:

```bash
# Use specific datasource
wheels db create --datasource=myapp_test

# Use specific environment
wheels db setup --environment=testing
```

## Safety Features

1. **Confirmation Prompts** - Destructive operations require confirmation
2. **Force Flag** - Use `--force` to skip confirmations in scripts
3. **Environment Detection** - Extra warnings for production environments
4. **Transaction Support** - Operations are wrapped in transactions where possible

## Troubleshooting

### Common Issues

**Datasource Not Found**
```bash
Error: Datasource 'myapp' not found in server configuration
```
Solution: Create the datasource in your CFML server admin first.

**Database Already Exists**
```bash
Error: Database already exists: myapp_dev
```
Solution: Use `wheels db drop` first or use `wheels db reset` instead.

**Permission Denied**
```bash
Error: Access denied for user 'myuser'@'localhost'
```
Solution: Ensure the database user has CREATE/DROP privileges.

**Missing Database Tools**
```bash
Error: mysqldump not found in PATH
```
Solution: Install database client tools for dump/restore operations.

### Best Practices

1. **Always backup before destructive operations**
   ```bash
   wheels db dump --output=backup-before-reset.sql
   wheels db reset
   ```

2. **Use environment-specific datasources**
   - `myapp_dev` for development
   - `myapp_test` for testing
   - `myapp_prod` for production

3. **Automate with scripts**
   ```bash
   #!/bin/bash
   # reset-db.sh
   wheels db dump --output=backups/pre-reset-$(date +%s).sql
   wheels db reset --force
   echo "Database reset complete"
   ```

4. **Version control your seeds**
   - Keep seed files in `db/seeds/`
   - Use environment-specific seed files
   - Document seed data structure

## Related Commands

- [`wheels dbmigrate`](dbmigrate-latest.md) - Database migration commands
- [`wheels test`](../testing/test-run.md) - Test database operations
- [`wheels generate model`](../generate/model.md) - Generate models with migrations