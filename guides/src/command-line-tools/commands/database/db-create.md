# wheels db create

Create a new database based on your datasource configuration.

## Synopsis

```bash
wheels db create [--datasource=<name>] [--environment=<env>]
```

## Description

The `wheels db create` command creates a new database using the connection information from your configured datasource. The datasource must already exist in your CFML server configuration - this command creates the database itself, not the datasource.

## Options

### --datasource=<name>
Specify which datasource to use. If not provided, uses the default datasource from your Wheels configuration.

```bash
wheels db create --datasource=myapp_dev
```

### --environment=<env>
Specify the environment to use. Defaults to the current environment.

```bash
wheels db create --environment=testing
```

## Examples

### Basic Usage

Create database using default datasource:
```bash
wheels db create
```

### Specific Datasource

Create database for development:
```bash
wheels db create --datasource=myapp_dev
```

Create database for testing:
```bash
wheels db create --datasource=myapp_test --environment=testing
```

## Database-Specific Behavior

### MySQL/MariaDB
- Creates database with UTF8MB4 character set
- Uses utf8mb4_unicode_ci collation
- Connects to `information_schema` to execute CREATE DATABASE

### PostgreSQL
- Creates database with UTF8 encoding
- Checks if database already exists before creating
- Connects to `postgres` system database

### SQL Server
- Creates database with default settings
- Checks if database already exists before creating
- Connects to `master` system database

### H2
- Displays message that H2 databases are created automatically
- No action needed - database file is created on first connection

## Prerequisites

1. **Datasource Configuration**: The datasource must be configured in your CFML server admin
2. **Database Privileges**: The database user must have CREATE DATABASE privileges
3. **Network Access**: The database server must be accessible

## Error Messages

### "Datasource not found"
The specified datasource doesn't exist in your server configuration. Create it in your CFML admin first.

### "Database already exists"
The database already exists. Use `wheels db drop` first if you need to recreate it.

### "Access denied"
The database user doesn't have permission to create databases. Grant CREATE privileges to the user.

## Related Commands

- [`wheels db drop`](db-drop.md) - Drop an existing database
- [`wheels db setup`](db-setup.md) - Create and setup database
- [`wheels dbmigrate latest`](dbmigrate-latest.md) - Run migrations after creating database