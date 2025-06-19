# wheels db drop

Drop an existing database.

## Synopsis

```bash
wheels db drop [--datasource=<name>] [--environment=<env>] [--force]
```

## Description

The `wheels db drop` command permanently deletes a database. This is a destructive operation that cannot be undone. By default, it requires confirmation unless the `--force` flag is used.

## Options

### --datasource=<name>
Specify which datasource's database to drop. If not provided, uses the default datasource from your Wheels configuration.

```bash
wheels db drop --datasource=myapp_dev
```

### --environment=<env>
Specify the environment to use. Defaults to the current environment.

```bash
wheels db drop --environment=testing
```

### --force
Skip the confirmation prompt. Useful for scripting.

```bash
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

### PostgreSQL
- Terminates existing connections before dropping
- Uses `DROP DATABASE IF EXISTS` statement
- Connects to `postgres` system database

### SQL Server
- Sets database to single-user mode to close connections
- Uses `DROP DATABASE IF EXISTS` statement
- Connects to `master` system database

### H2
- Deletes database files (.mv.db, .lock.db, .trace.db)
- Shows which files were deleted

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

## Related Commands

- [`wheels db create`](db-create.md) - Create a new database
- [`wheels db reset`](db-reset.md) - Drop and recreate database
- [`wheels db dump`](db-dump.md) - Backup before dropping