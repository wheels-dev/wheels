# wheels db create

Create a new database based on your datasource configuration.

## Synopsis

```bash
wheels db create [--datasource=<name>] [--environment=<env>] [--database=<dbname>] [--force]
```

## Description

The `wheels db create` command creates a new database using the connection information from your configured datasource. If the datasource doesn't exist, the command offers an interactive wizard to create it for you, supporting MySQL, PostgreSQL, SQL Server, Oracle, and H2 databases.

### Key Features

- **Automatic .env file reading**: Reads actual database credentials from `.env.{environment}` files using generic `DB_*` variable names
- **Interactive datasource creation**: Prompts for credentials when datasource doesn't exist
- **Environment validation**: Checks if environment exists before prompting for credentials
- **Smart error handling**: Single, clear error messages without duplication
- **Post-creation setup**: Automatically creates environment files and writes datasource to `app.cfm` after successful database creation

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `datasource` | string | Current datasource | Specify which datasource to use. If not provided, uses the default datasource from your Wheels configuration. |
| `environment` | string | Current environment | Specify the environment to use. Defaults to the current environment (development if not set). |
| `database` | string | `wheels_dev` | Specify the database name to create. **Note for Oracle:** Database names cannot contain hyphens. Use underscores instead (e.g., `myapp_dev` not `myapp-dev`). |
| `force` | boolean | `false` | Drop the existing database if it already exists and recreate it. Without this flag, the command will error if the database already exists. |

**Examples:**

```bash
# Use specific datasource
wheels db create --datasource=myapp_dev

# Specify environment
wheels db create --environment=testing

# Custom database name
wheels db create --database=myapp_production

# Force recreation
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

### SQLite Database

Create SQLite database (file-based, no server required):
```bash
# Using existing datasource
wheels db create --datasource=myapp_dev

# With specific database type
wheels db create --dbtype=sqlite --database=myapp_dev

# Force recreate SQLite database
wheels db create --dbtype=sqlite --force
```

Output:
```
[OK] SQLite JDBC driver loaded
[OK] Database connection established
[OK] Database schema initialized
[OK] Database file created: D:\MyApp\db\myapp_dev.db
[OK] File size: 16384 bytes

SQLite database created successfully!
```

## Interactive Datasource Creation

If the specified datasource doesn't exist, the command will prompt you to create it interactively:

```
Datasource 'myapp_dev' not found in server configuration.

Would you like to create this datasource now? [y/n]: y

=== Interactive Datasource Creation ===

Select database type:
  1. MySQL
  2. PostgreSQL
  3. SQL Server (MSSQL)
  4. Oracle
  5. H2
  6. SQLite

Select database type [1-6]: 1
Selected: MySQL

Enter connection details:
Host [localhost]:
Port [3306]:
Database name [wheels_dev]: myapp_dev
Username [root]:
Password: ****

Review datasource configuration:
  Datasource Name: myapp_dev
  Database Type: MySQL
  Host: localhost
  Port: 3306
  Database: myapp_dev
  Username: root
  Connection String: jdbc:mysql://localhost:3306/myapp_dev

Create this datasource? [y/n]: y
```

The datasource will be saved to both `/config/app.cfm` and `CFConfig.json`.

## Database-Specific Behavior

### MySQL/MariaDB
- Creates database with UTF8MB4 character set
- Uses utf8mb4_unicode_ci collation
- Connects to `information_schema` system database
- Supports MySQL 5.x, MySQL 8.0+, and MariaDB drivers
- Default port: 3306

### PostgreSQL
- Creates database with UTF8 encoding
- Uses en_US.UTF-8 locale settings
- Terminates active connections before dropping (when using --force)
- Connects to `postgres` system database
- Default port: 5432

### SQL Server
- Creates database with default settings
- Connects to `master` system database
- Supports Microsoft SQL Server JDBC driver
- Default port: 1433

### Oracle
- Creates a USER/schema (Oracle's equivalent of a database)
- Grants CONNECT and RESOURCE privileges automatically
- Connects using SID (e.g., FREE, ORCL, XE)
- Supports Oracle 12c+ with Container Database (CDB) architecture
- Uses `_ORACLE_SCRIPT` session variable for non-C## users
- **Important:** Database names cannot contain hyphens (use underscores)
- Default port: 1521
- Default SID: FREE (Oracle XE)

### H2
- Embedded database - no server required
- Database file created automatically on first connection
- Only prompts for database name and optional credentials
- No host/port configuration needed
- Ideal for development and testing

### SQLite
- Lightweight file-based database - serverless and zero-configuration
- **Database file created immediately** (unlike H2's lazy creation)
- Creates database file with metadata table: `wheels_metadata`
- Database stored at: `./db/database_name.db`
- Automatically creates `db` directory if it doesn't exist
- No username/password required (file-based authentication)
- No host/port configuration needed
- JDBC driver: `org.sqlite.JDBC` (org.xerial.sqlite-jdbc bundle v3.47.1.0)
- Creates auxiliary files during operation:
  - `database.db-wal` (Write-Ahead Log)
  - `database.db-shm` (Shared Memory)
  - `database.db-journal` (Rollback Journal)
- **Use absolute paths** - paths are stored absolutely in configuration
- Ideal for development, testing, prototyping, and portable applications
- **Limitations:** Single writer, not recommended for high-concurrency production

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
> **⚠️ Note:** This command depends on configuration values. Please verify your database configuration before executing it.

1. **Datasource Configuration**: The datasource can be configured in `/config/app.cfm` or created interactively
2. **Database Privileges**: The database user must have CREATE DATABASE privileges (CREATE USER for Oracle, not applicable for H2/SQLite)
3. **Network Access**: The database server must be accessible (not applicable for H2/SQLite file-based databases)
4. **JDBC Drivers**: Appropriate JDBC drivers must be available in the classpath
5. **File Permissions** (SQLite/H2 only): Write permissions required in application root directory

### Oracle JDBC Driver Installation

If you see "Driver not found" error for Oracle, you need to manually install the Oracle JDBC driver:

**Steps to install Oracle JDBC driver:**

1. **Download the driver** from Oracle's official website:
   - Visit: [official Oracle JDBC Driver download page](https://www.oracle.com/database/technologies/appdev/jdbc-downloads.html)
   - Download the appropriate `ojdbc` JAR file (e.g., `ojdbc11.jar` or `ojdbc8.jar`)

2. **Place the JAR file** in CommandBox's JRE library directory:
   ```
   [CommandBox installed path]/jre/lib/
   ```

   Common paths:
   - **Windows**: `C:\Program Files\CommandBox\jre\lib\`
   - **Mac/Linux**: `/usr/local/lib/CommandBox/jre/lib/`

3. **Restart CommandBox completely**:
   - **Important**: Close ALL CommandBox instances
   - Don't just run `reload` - fully exit and restart CommandBox
   - This ensures the JDBC driver is properly loaded into the classpath

4. **Verify installation**:
   ```bash
   wheels db create datasource=myOracleDS
   ```

   You should see: `[OK] Driver found: oracle.jdbc.OracleDriver`

**Note:** Other database drivers (MySQL, PostgreSQL, MSSQL, H2, SQLite) are typically included with CommandBox/Lucee by default.

## Error Messages

### "No datasource configured"
No datasource was specified and none could be found in your Wheels configuration. Use the datasource= parameter or set dataSourceName in settings.

### "Datasource not found"
The specified datasource doesn't exist in your server configuration. The command will prompt you to create it interactively.

### "Driver not found" (Oracle-specific)
Oracle JDBC driver is not installed in CommandBox.

**Fix:** Follow the [Oracle JDBC Driver Installation](#oracle-jdbc-driver-installation) instructions above.

**Quick steps:**
1. Download `ojdbc11.jar` from [Oracle's website](https://www.oracle.com/database/technologies/appdev/jdbc-downloads.html)
2. Place it in `[CommandBox path]/jre/lib/`
3. **Close ALL CommandBox instances** and restart (don't just reload)
4. Try the command again

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
6. For Oracle: TNS listener not running or incorrect SID

### "Invalid Oracle identifier" (Oracle-specific)
Database name contains invalid characters. Oracle usernames can only contain letters, numbers, and underscores.

**Fix:** Use underscores instead of hyphens:
```bash
# Wrong
wheels db create --database=my-app-dev

# Correct
wheels db create --database=my_app_dev
```

### "ORA-65096: common user or role name must start with C##" (Oracle-specific)
Oracle Container Database (CDB) requires common users to start with C## prefix, or the connecting user needs privileges to set the `_ORACLE_SCRIPT` session variable.

**Fix:** Either use a C## prefixed name or grant additional privileges:
```bash
wheels db create --database=C##MYAPP
```

### "ORA-28014: cannot drop administrative user" (Oracle-specific)
Attempting to drop an Oracle system user (SYS, SYSTEM, etc.). Choose a different database name.

**Fix:** Use a non-system username:
```bash
wheels db create --database=myapp_dev --force
```

### "SQLite JDBC driver not found" (SQLite-specific)
The SQLite JDBC driver is not available in the classpath.

**Fix:** The SQLite driver (`org.xerial.sqlite-jdbc`) should be bundled with CommandBox/Lucee by default. If you see this error:
1. Verify CommandBox version is up-to-date
2. Check if the bundle is available in Lucee Admin
3. Restart CommandBox completely (close all instances)

### "Could not delete existing database file" (SQLite-specific)
The existing SQLite database file is locked and cannot be deleted when using `--force`.

**Fix:**
1. Stop the application server: `box server stop`
2. Close any database tools (DB Browser for SQLite, etc.)
3. Try the command again:
```bash
wheels db create --force
```

The command will automatically attempt to stop the server and retry deletion.

### "File permission error" (SQLite-specific)
Insufficient permissions to create database file or `db` directory.

**Fix:**
1. Check file permissions on the application root directory
2. Ensure the user running CommandBox has write permissions
3. On Unix/Linux: `chmod 755 ./db` or create the directory manually

### "Database file was not created" (SQLite-specific)
The SQLite database file was not successfully created after connection.

**Fix:**
1. Verify disk space is available
2. Check parent directory permissions
3. Ensure the path doesn't contain invalid characters
4. Try with a simpler database name

## Configuration Detection

The command intelligently detects datasource configuration from multiple sources:

### Priority Order:

1. **`.env.{environment}` file** (highest priority - NEW!)
   - Reads actual credential values using generic `DB_*` variable names
   - Example: `DB_HOST=localhost`, `DB_USER=sa`, `DB_PASSWORD=MyPass123!`
   - Solves the issue where `app.cfm` contains unresolved placeholders like `##this.env.DB_HOST##`

2. **Datasource definitions in `/config/app.cfm`**
   - Falls back to parsing connection strings if `.env` file doesn't exist
   - Maintains backward compatibility

3. **Environment-specific settings: `/config/[environment]/settings.cfm`**
   - Detects datasource name from `set(dataSourceName="...")`

4. **General settings: `/config/settings.cfm`**
   - Global datasource configuration

### What It Extracts:

- Database driver type (MySQL, PostgreSQL, MSSQL, Oracle, H2)
- Connection details:
  - Host and port
  - Database name
  - Username and password
  - Oracle SID (if applicable)

### Generic Variable Names

All database types now use **consistent `DB_*` variable names** in `.env` files:

```bash
DB_TYPE=mssql           # Database type
DB_HOST=localhost       # Host (not MSSQL_HOST)
DB_PORT=1433            # Port (not MSSQL_PORT)
DB_DATABASE=wheels_dev  # Database name (not MSSQL_DATABASE)
DB_USER=sa              # Username (not MSSQL_USER)
DB_PASSWORD=Pass123!    # Password (not MSSQL_PASSWORD)
DB_DATASOURCE=wheels_dev
```

This makes it easy to switch database types without changing variable names.

## Related Commands

- [`wheels db drop`](db-drop.md) - Drop an existing database
- [`wheels db setup`](db-setup.md) - Create and setup database
- [`wheels dbmigrate latest`](dbmigrate-latest.md) - Run migrations after creating database