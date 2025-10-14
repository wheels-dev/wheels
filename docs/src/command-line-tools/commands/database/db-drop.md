# wheels db drop
> **⚠️ Note:** This command depends on configuration values. Please verify your database configuration before executing it.

Drop an existing database.

## Synopsis

```bash
wheels db drop [--datasource=<name>] [--environment=<env>] [--database=<dbname>] [--force]
```

## Description

The `wheels db drop` command permanently deletes a database. This is a destructive operation that cannot be undone. By default, it requires confirmation unless the `--force` flag is used.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `datasource` | string | Current datasource | Specify which datasource's database to drop. If not provided, uses the default datasource from your Wheels configuration. |
| `environment` | string | Current environment | Specify the environment to use. Defaults to the current environment. |
| `database` | string | `wheels_dev` | Specify the database name to drop. **Note for Oracle:** Database names cannot contain hyphens. Use underscores instead (e.g., `myapp_dev` not `myapp-dev`). |
| `force` | boolean | `false` | Skip the confirmation prompt. Useful for scripting. |

**Examples:**

```bash
# Use specific datasource
wheels db drop --datasource=myapp_dev

# Specify environment
wheels db drop --environment=testing

# Custom database name
wheels db drop --database=myapp_test

# Force drop without confirmation
wheels db drop --force
```

## Examples

### Basic Usage

Drop database with confirmation:
```bash
wheels db drop
# Will prompt: Are you sure you want to drop the database 'myapp_dev'? Type 'yes' to confirm:
```

### Force Drop

Drop without confirmation:
```bash
wheels db drop --force
```

### Drop Test Database

```bash
wheels db drop --datasource=myapp_test --environment=testing --force
```

## Safety Features

1. **Confirmation Required**: By default, you must type "yes" to confirm
2. **Production Warning**: Extra warning when dropping production databases
3. **Clear Messaging**: Shows database name and environment before dropping

## Database-Specific Behavior

### MySQL/MariaDB
- Uses `DROP DATABASE IF EXISTS` statement
- Connects to `information_schema` to execute command
- Automatically handles active connections

### PostgreSQL
- Terminates existing connections before dropping
- Uses `DROP DATABASE IF EXISTS` statement
- Connects to `postgres` system database

### SQL Server
- Sets database to single-user mode to close connections
- Uses `DROP DATABASE IF EXISTS` statement
- Connects to `master` system database

### Oracle
- Drops USER/schema (Oracle's equivalent of a database)
- Uses `DROP USER ... CASCADE` to remove all objects
- Supports Oracle 12c+ with Container Database (CDB) architecture
- Uses `_ORACLE_SCRIPT` session variable for non-C## users
- **Important:** Database names cannot contain hyphens (use underscores)
- Cannot drop system users (SYS, SYSTEM, ADMIN, XDB, etc.)

### H2
- Deletes database files (.mv.db, .lock.db, .trace.db)
- Shows which files were deleted
- No server connection required

## Warning

**This operation is irreversible!** Always ensure you have backups before dropping a database.

## Best Practices

1. **Always backup first**:
   ```bash
   wheels db dump --output=backup-before-drop.sql
   wheels db drop
   ```

2. **Use --force carefully**: Only in scripts where you're certain

3. **Double-check environment**: Especially important for production

## Error Messages

### "Database not found"
The database doesn't exist. No action needed.

### "Access denied"
The database user doesn't have permission to drop databases. Grant DROP privileges to the user.

### "Database in use"
Some databases prevent dropping while connections are active. The command attempts to close connections automatically.

### "Invalid Oracle identifier" (Oracle-specific)
Database name contains invalid characters. Oracle usernames can only contain letters, numbers, and underscores.

**Fix:** Use underscores instead of hyphens:
```bash
# Wrong
wheels db drop --database=my-app-dev

# Correct
wheels db drop --database=my_app_dev
```

### "ORA-01918: user does not exist" (Oracle-specific)
The Oracle user/schema doesn't exist. No action needed.

### "ORA-28014: cannot drop administrative user" (Oracle-specific)
Attempting to drop an Oracle system user. System users like SYS, SYSTEM, ADMIN, XDB cannot be dropped.

**Fix:** Verify you're targeting the correct database. System users are protected and cannot be removed.

## Related Commands

- [`wheels db create`](db-create.md) - Create a new database
- [`wheels db reset`](db-reset.md) - Drop and recreate database
- [`wheels db dump`](db-dump.md) - Backup before dropping