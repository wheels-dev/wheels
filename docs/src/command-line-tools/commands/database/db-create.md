# wheels db create

Create a new database based on your datasource configuration.

## Synopsis

```bash
wheels db create [--datasource=<name>] [--environment=<env>] [--database=<dbname>] [--dbtype=<type>] [--force]
```

## Description

The `wheels db create` command creates a new database using the connection information from your configured datasource. If the datasource doesn't exist, the command offers an interactive wizard to create it for you, supporting MySQL, PostgreSQL, SQL Server, Oracle, H2, and SQLite databases.

### Key Features

- **Automatic .env file reading**: Reads actual database credentials from `.env.{environment}` files using generic `DB_*` variable names
- **Interactive datasource creation**: Prompts for credentials when datasource doesn't exist
- **Environment validation**: Checks if environment exists before prompting for credentials
- **Smart error handling**: Single, clear error messages without duplication
- **Enhanced driver guidance**: Provides specific installation instructions when JDBC drivers are missing
- **Post-creation setup**: Automatically creates environment files and writes datasource to `app.cfm` after successful database creation

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `datasource` | string | Current datasource | Specify which datasource to use. If not provided, uses the default datasource from your Wheels configuration. |
| `environment` | string | Current environment | Specify the environment to use. Defaults to the current environment (development if not set). |
| `database` | string | `wheels_dev` | Specify the database name to create. **Note for Oracle:** Database names cannot contain hyphens. Use underscores instead (e.g., `myapp_dev` not `myapp-dev`). |
| `dbtype` | string | Auto-detected | Database type: `h2`, `sqlite`, `mysql`, `postgres`, `mssql`, `oracle`. If not specified, the command will prompt you to select a type when creating a new datasource. |
| `force` | boolean | `false` | Drop the existing database if it already exists and recreate it. Without this flag, the command will error if the database already exists. |

**Examples:**

```bash
# Use specific datasource
wheels db create --datasource=myapp_dev

# Specify environment
wheels db create --environment=testing

# Custom database name
wheels db create --database=myapp_production

# Specify database type
wheels db create --dbtype=postgres --database=myapp_dev

# Force recreation
wheels db create --force
```

## Examples

### Basic Usage

Create database using default datasource:
```bash
wheels db create
```

### General Examples

```bash
# Using existing datasource
wheels db create datasource=myapp_dev

# Specify environment
wheels db create --environment=testing

# Custom database name
wheels db create --database=myapp_v2

# Force recreation (drop and recreate)
wheels db create --force
```

## Database-Specific Guides

### H2 Database (Embedded)

**Characteristics:**
- Embedded database - no server required
- Database file created automatically on first connection
- Only prompts for database name and optional credentials
- No host/port configuration needed
- Ideal for development and testing
- JDBC Driver included with Lucee/CommandBox

**Example Commands:**
```bash
# Basic H2 database
wheels db create --dbtype=h2 --database=myapp_dev

# With specific environment
wheels db create --dbtype=h2 --database=myapp_test --environment=testing

# Force recreate
wheels db create --dbtype=h2 --database=myapp_dev --force
```

---

### SQLite Database (File-based)

**Characteristics:**
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

**Example Commands:**
```bash
# Basic SQLite database
wheels db create --dbtype=sqlite --database=myapp_dev

# Force recreate SQLite database
wheels db create --dbtype=sqlite --database=myapp_dev --force

# With specific environment
wheels db create --dbtype=sqlite --database=myapp_test --environment=testing
```

**Output Example:**
```
[OK] SQLite JDBC driver loaded
[OK] Database connection established
[OK] Database schema initialized
[OK] Database file created: D:\MyApp\db\myapp_dev.db
[OK] File size: 16384 bytes

SQLite database created successfully!
```

**Common Issues:**
- **"Could not delete existing database file"**: The database file is locked. Stop the server (`box server stop`) and close any database tools.
- **"File permission error"**: Ensure write permissions on the application root directory.
- **"Database file was not created"**: Check disk space and directory permissions.

---

### MySQL/MariaDB

**Characteristics:**
- Creates database with UTF8MB4 character set
- Uses utf8mb4_unicode_ci collation
- Connects to `information_schema` system database
- Supports MySQL 5.x, MySQL 8.0+, and MariaDB drivers
- Default port: 3306
- JDBC Driver included with Lucee/CommandBox

**Example Commands:**
```bash
# Basic MySQL database
wheels db create --dbtype=mysql --database=myapp_dev

# With specific environment
wheels db create --dbtype=mysql --database=myapp_production --environment=production

# With custom datasource name
wheels db create --dbtype=mysql --database=myapp_test --datasource=test_db --environment=testing

# Force recreate
wheels db create --dbtype=mysql --database=myapp_dev --force
```

**Output Example:**
```
==================================================================
  Database Creation Process
==================================================================
  Datasource:         myapp_dev
  Environment:        development
------------------------------------------------------------------
  Database Type:      MySQL
  Database Name:      myapp_dev
------------------------------------------------------------------

>> Initializing MySQL database creation...
  [OK] Driver found: com.mysql.cj.jdbc.Driver
  [OK] Connected successfully to MySQL server!

>> Creating MySQL database 'myapp_dev'...
  [OK] Database 'myapp_dev' created successfully!

>> Verifying database creation...
  [OK] Database 'myapp_dev' verified successfully!
------------------------------------------------------------------
  [OK] MySQL database creation completed successfully!
```

---

### PostgreSQL

**Characteristics:**
- Creates database with UTF8 encoding
- Uses en_US.UTF-8 locale settings
- Terminates active connections before dropping (when using --force)
- Connects to `postgres` system database
- Default port: 5432
- JDBC Driver included with Lucee/CommandBox

**Example Commands:**
```bash
# Basic PostgreSQL database
wheels db create --dbtype=postgres --database=myapp_dev

# With specific environment
wheels db create --dbtype=postgres --database=myapp_staging --environment=staging

# Force recreate (automatically terminates active connections)
wheels db create --dbtype=postgres --database=myapp_dev --force

# Custom datasource
wheels db create --dbtype=postgres --database=myapp_prod --datasource=prod_db --environment=production
```

**Special Notes:**
- When using `--force`, the command automatically terminates active connections before dropping the database
- Check `pg_hba.conf` if you encounter authentication issues

---

### SQL Server (MSSQL)

**Characteristics:**
- Creates database with default settings
- Connects to `master` system database
- Supports Microsoft SQL Server JDBC driver
- Default port: 1433
- Default username: sa
- JDBC Driver included with Lucee/CommandBox

**Example Commands:**
```bash
# Basic SQL Server database
wheels db create --dbtype=mssql --database=myapp_dev

# With specific environment
wheels db create --dbtype=mssql --database=myapp_production --environment=production

# With custom datasource
wheels db create --dbtype=mssql --database=MyAppDB --datasource=production_ds

# Force recreate
wheels db create --dbtype=mssql --database=myapp_dev --force
```

---

### Oracle Database

**Characteristics:**
- Creates a USER/schema (Oracle's equivalent of a database)
- Grants CONNECT and RESOURCE privileges automatically
- Connects using SID (e.g., FREE, ORCL, XE)
- Supports Oracle 12c+ with Container Database (CDB) architecture
- Uses `_ORACLE_SCRIPT` session variable for non-C## users
- **Important:** Database names cannot contain hyphens (use underscores)
- Default port: 1521
- Default SID: FREE (Oracle XE)
- **Requires manual JDBC driver installation** (see below)

**Example Commands:**
```bash
# Basic Oracle database (creates user/schema)
wheels db create --dbtype=oracle --database=myapp_dev

# With specific environment
wheels db create --dbtype=oracle --database=myapp_prod --environment=production

# Force recreate (drops and recreates user)
wheels db create --dbtype=oracle --database=myapp_dev --force

# IMPORTANT: Use underscores, not hyphens
wheels db create --dbtype=oracle --database=myapp_test  # ✓ Correct
# wheels db create --dbtype=oracle --database=myapp-test  # ✗ Wrong! Will fail
```

**Oracle JDBC Driver Installation:**

If you see "Driver not found" error, you need to manually install the Oracle JDBC driver:

1. **Download the driver** from [Oracle's official website](https://www.oracle.com/database/technologies/appdev/jdbc-downloads.html)
    - Download `ojdbc11.jar` or `ojdbc8.jar`

2. **Find the correct location on *your* machine**
    - Run this in CommandBox:
        ```bash
        info
        ```
    - Look for the line: **CommandBox Home** `/Users/yourname/.CommandBox`, there you will be able to find the exact commandBox path.

3. **Place the JAR file** in CommandBox's library directory:
    - **Windows**: `path\to\CommandBox\lib\`
    - **Mac/Linux**: `path\to\CommandBox/lib/`

4. **Restart CommandBox completely**:
    - **Important**: Close all CommandBox instances (don't just reload)
    - This ensures the JDBC driver is properly loaded

5. **Verify installation**:
    ```bash
    wheels db create datasource=myOracleDS
    ```
    You should see: `[OK] Driver found: oracle.jdbc.OracleDriver`

**Common Oracle Errors:**
- **"Invalid Oracle identifier"**: Database name contains hyphens. Use underscores instead.
- **"ORA-65096: common user must start with C##"**: Either use `C##MYAPP` as the database name or grant additional privileges to the connecting user.
- **"ORA-28014: cannot drop administrative user"**: Don't use system usernames (SYS, SYSTEM, etc.).

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

## Prerequisites
> **⚠️ Note:** This command depends on configuration values. Please verify your database configuration before executing it.

1. **Datasource Configuration**: The datasource can be configured in `/config/app.cfm` or created interactively
2. **Database Privileges**: The database user must have CREATE DATABASE privileges (CREATE USER for Oracle, not applicable for H2/SQLite)
3. **Network Access**: The database server must be accessible (not applicable for H2/SQLite file-based databases)
4. **JDBC Drivers**:
   - MySQL, PostgreSQL, MSSQL, H2, and SQLite drivers are included with CommandBox/Lucee by default
   - **Oracle requires manual driver installation** - see [Oracle Database](#oracle-database) section for details
5. **File Permissions** (SQLite/H2 only): Write permissions required in application root directory

## Error Messages

### "No datasource configured"
No datasource was specified and none could be found in your Wheels configuration. Use the datasource= parameter or set dataSourceName in settings.

### "Datasource not found"
The specified datasource doesn't exist in your server configuration. The command will prompt you to create it interactively.

### "Driver not found" (Oracle-specific)
The JDBC driver for the database type is not available in CommandBox by default.

**Fix:** The CLI will automatically provide specific installation guidance when a driver is missing:

- **Oracle:** Shows detailed step-by-step Oracle JDBC driver installation instructions
- **MySQL/PostgreSQL/MSSQL/SQLite:** Provides guidance on verifying CommandBox installation
- **General:** Suggests restarting CommandBox and checking library directory

**Fix:** See the [Oracle Database](#oracle-database) section above for detailed instructions.

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

### Oracle-Specific Errors

For Oracle errors, see the [Oracle Database](#oracle-database) section for detailed information on:
- **"Invalid Oracle identifier"**: Use underscores instead of hyphens
- **"ORA-65096: common user must start with C##"**: Use `C##` prefix or grant privileges
- **"ORA-28014: cannot drop administrative user"**: Don't use system usernames (SYS, SYSTEM, etc.)

### SQLite-Specific Errors

For SQLite errors, see the [SQLite Database](#sqlite-database-file-based) section for detailed information on:
- **"Could not delete existing database file"**: Database is locked. Stop server and close database tools
- **"File permission error"**: Check write permissions on application root
- **"Database file was not created"**: Verify disk space and permissions

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