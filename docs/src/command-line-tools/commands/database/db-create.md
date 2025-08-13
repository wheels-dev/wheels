# wheels db create (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Create a new database based on your datasource configuration.

## Synopsis

```bash
wheels db create [--datasource=<name>] [--environment=<env>] [--database=<dbname>] [--force]
```

## Description

The `wheels db create` command creates a new database using the connection information from your configured datasource. The datasource must already exist in your CFML server configuration - this command creates the database itself, not the datasource.

## Options

### datasource=<name>
Specify which datasource to use. If not provided, uses the default datasource from your Wheels configuration.

```bash
wheels db create --datasource=myapp_dev
```

### --environment=<env>
Specify the environment to use. Defaults to the current environment (development if not set).

```bash
wheels db create --environment=testing
```

### --database=<dbname>
Specify the database name to create. Defaults to "wheels-dev" if not provided and not found in datasource configuration.

```bash
wheels db create --database=myapp_production
```

### --force
Drop the existing database if it already exists and recreate it. Without this flag, the command will error if the database already exists.

```bash
wheels db create --force
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
wheels db create datasource=myapp_dev
```

Create database for testing:
```bash
wheels db create datasource=myapp_test --environment=testing
```

### Custom Database Name

Create database with specific name:
```bash
wheels db create --database=myapp_v2
```

### Force Recreation

Drop existing database and recreate:
```bash
wheels db create --force
```

## Database-Specific Behavior

### MySQL/MariaDB
- Creates database with UTF8MB4 character set
- Uses utf8mb4_unicode_ci collation
- Connects without specifying a database initially
- Supports MySQL 5.x, MySQL 8.0+, and MariaDB drivers

### PostgreSQL
- Creates database with UTF8 encoding
- Uses en_US.UTF-8 locale settings
- Terminates active connections before dropping (when using --force)
- Connects to `postgres` system database

### SQL Server
- Creates database with default settings
- Connects to `master` system database
- Supports Microsoft SQL Server JDBC driver

### H2
- Displays message that H2 databases are created automatically
- No action needed - database file is created on first connection

## Output Format

The command provides real-time, formatted output showing each step:

```
==================================================================
  Database Creation Process
==================================================================
  Datasource:         myapp_dev
  Environment:        development
------------------------------------------------------------------
  Database Type:      MySQL
  Database Name:      myapp_development
------------------------------------------------------------------

>> Initializing MySQL database creation...
  [OK] Driver found: com.mysql.cj.jdbc.Driver
  [OK] Connected successfully to MySQL server!

>> Checking if database exists...
>> Creating MySQL database 'myapp_development'...
  [OK] Database 'myapp_development' created successfully!

>> Verifying database creation...
  [OK] Database 'myapp_development' verified successfully!
------------------------------------------------------------------
  [OK] MySQL database creation completed successfully!
```

## Prerequisites

1. **Datasource Configuration**: The datasource must be configured in `/config/app.cfm`
2. **Database Privileges**: The database user must have CREATE DATABASE privileges
3. **Network Access**: The database server must be accessible
4. **JDBC Drivers**: Appropriate JDBC drivers must be available in the classpath

## Error Messages

### "No datasource configured"
No datasource was specified and none could be found in your Wheels configuration. Use the datasource= parameter or set dataSourceName in settings.

### "Datasource not found"
The specified datasource doesn't exist in your server configuration. Create it in your `/config/app.cfm` first.

### "Database already exists"
The database already exists. Use `--force` flag to drop and recreate it:
```bash
wheels db create --force
```

### "Access denied"
The database user doesn't have permission to create databases. Grant CREATE privileges to the user.

### "Connection failed"
Common causes:
1. Database server is not running
2. Wrong server/port configuration
3. Invalid credentials
4. Network/firewall issues
5. For PostgreSQL: pg_hba.conf authentication issues

## Configuration Detection

The command automatically detects datasource configuration from:
1. Environment-specific settings: `/config/[environment]/settings.cfm`
2. General settings: `/config/settings.cfm`
3. Datasource definitions: `/config/app.cfm`

It extracts:
- Database driver type
- Connection string details
- Host and port information
- Username and password
- Database name (if specified in connection string)

## Related Commands

- [`wheels db drop`](db-drop.md) - Drop an existing database
- [`wheels db setup`](db-setup.md) - Create and setup database
- [`wheels dbmigrate latest`](dbmigrate-latest.md) - Run migrations after creating database