# wheels db shell (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Launch an interactive database shell for direct SQL access to your database.

## Synopsis

```bash
wheels db shell [--datasource=<name>] [--environment=<env>] [--web] [--command=<sql>]
```

## Description

The `wheels db shell` command provides direct access to your database through its native command-line interface. It automatically detects your database type and launches the appropriate shell client.

For H2 databases (commonly used with Lucee), it can also launch a web-based console interface.

## Options

### --datasource=<name>
Specify which datasource to connect to. If not provided, uses the default datasource from your Wheels configuration.

```bash
wheels db shell --datasource=myapp_dev
```

### --environment=<env>
Specify the environment to use. Defaults to the current environment.

```bash
wheels db shell --environment=production
```

### --web
For H2 databases only, launches the web-based console interface instead of the CLI shell.

```bash
wheels db shell --web
```

### --command=<sql>
Execute a single SQL command and exit, rather than entering interactive mode.

```bash
wheels db shell --command="SELECT COUNT(*) FROM users"
```

## Database-Specific Behavior

### H2 Database

For H2 databases (default with Lucee), you have two options:

**CLI Shell:**
```bash
wheels db shell
```
- Provides a command-line SQL interface
- Type SQL commands directly
- Use `help` for available commands
- Exit with `exit` or Ctrl+D

**Web Console:**
```bash
wheels db shell --web
```
- Opens H2's web interface in your default browser
- Provides a GUI for browsing tables and running queries
- More user-friendly for complex operations
- Press Ctrl+C in terminal to stop the console server

### MySQL/MariaDB

```bash
wheels db shell
```
- Launches the `mysql` client
- Connects using datasource credentials
- Full MySQL command-line interface
- Exit with `exit`, `quit`, or Ctrl+D

### PostgreSQL

```bash
wheels db shell
```
- Launches the `psql` client
- Connects using datasource credentials
- Full PostgreSQL command-line interface
- Type `\h` for help, `\q` to quit

### SQL Server

```bash
wheels db shell
```
- Launches the `sqlcmd` client
- Connects using datasource credentials
- Full SQL Server command-line interface
- Type `:help` for help, `:quit` to exit

## Examples

### Basic Usage

Launch shell for default datasource:
```bash
wheels db shell
```

### Web Console for H2

Open H2's web interface:
```bash
wheels db shell --web
```

### Execute Single Command

Get row count without entering interactive mode:
```bash
wheels db shell --command="SELECT COUNT(*) FROM users"
```

Check database version:
```bash
wheels db shell --command="SELECT VERSION()"
```

### Different Datasources

Connect to test database:
```bash
wheels db shell --datasource=myapp_test
```

Connect to production (with caution):
```bash
wheels db shell --datasource=myapp_prod --environment=production
```

## Common SQL Commands

Once in the shell, here are some useful commands:

### Show Tables
```sql
-- H2/MySQL
SHOW TABLES;

-- PostgreSQL
\dt

-- SQL Server
SELECT name FROM sys.tables;
```

### Describe Table Structure
```sql
-- H2/MySQL
DESCRIBE users;

-- PostgreSQL
\d users

-- SQL Server
sp_help users;
```

### Basic Queries
```sql
-- Count records
SELECT COUNT(*) FROM users;

-- View recent records
SELECT * FROM users ORDER BY created_at DESC LIMIT 10;

-- Check for specific data
SELECT * FROM users WHERE email = 'admin@example.com';
```

## Requirements

### Client Tools

The shell command requires database-specific client tools:

- **H2**: No additional installation (included with Lucee)
- **MySQL**: Install `mysql` client
  ```bash
  # macOS
  brew install mysql-client
  
  # Ubuntu/Debian
  sudo apt-get install mysql-client
  
  # RHEL/CentOS
  sudo yum install mysql
  ```
- **PostgreSQL**: Install `psql` client
  ```bash
  # macOS
  brew install postgresql
  
  # Ubuntu/Debian
  sudo apt-get install postgresql-client
  
  # RHEL/CentOS
  sudo yum install postgresql
  ```
- **SQL Server**: Install `sqlcmd`
  ```bash
  # macOS
  brew install mssql-tools
  
  # Linux
  # Follow Microsoft's instructions for your distribution
  ```

## Troubleshooting

### "Command not found" Errors

If you get errors about mysql/psql/sqlcmd not being found:

1. Install the appropriate client tool (see Requirements above)
2. Ensure the tool is in your PATH
3. Restart your terminal/command prompt

### H2 Connection Issues

If the H2 shell fails to connect:

1. Check that your datasource is properly configured
2. Ensure the database file exists (check `db/h2/` directory)
3. Try the web console instead: `wheels db shell --web`

### Authentication Failures

If you get authentication errors:

1. Verify datasource credentials in your CFML admin
2. Check that the database user has appropriate permissions
3. For PostgreSQL, you might need to set PGPASSWORD environment variable

### H2 JAR Not Found

If you get "H2 JAR not found" error:

1. Ensure H2 is installed as a Lucee extension
2. Check for `org.lucee.h2-*.jar` in Lucee's lib directory
3. Try reinstalling the H2 extension through Lucee admin

## Security Considerations

- **Be careful in production**: The shell provides full database access
- **Avoid hardcoding credentials**: Use datasource configuration
- **Limit permissions**: Database users should have appropriate restrictions
- **Audit usage**: Shell commands may not be logged by your application

## Related Commands

- [`wheels db create`](db-create.md) - Create a new database
- [`wheels db status`](db-status.md) - Check migration status
- [`wheels db dump`](db-dump.md) - Export database
- [`wheels dbmigrate`](dbmigrate-latest.md) - Run migrations
- [`wheels console`](../environment/console.md) - CFML interactive console