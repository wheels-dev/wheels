# wheels db restore

Restore a database from a dump file.

## Synopsis

```bash
wheels db restore <file> [--datasource=<name>] [--environment=<env>] 
                        [--clean] [--force] [--compressed]
```

## Description

The `wheels db restore` command imports a database dump file created by `wheels db dump` or other database export tools. It can handle both plain SQL files and compressed dumps.

## Arguments

### file
Required. Path to the dump file to restore.

```bash
wheels db restore backup.sql
```

## Options

### --datasource=<name>
Specify which datasource to restore to. If not provided, uses the default datasource.

```bash
wheels db restore backup.sql --datasource=myapp_dev
```

### --environment=<env>
Specify the environment to use. Defaults to the current environment.

```bash
wheels db restore backup.sql --environment=staging
```

### --clean
Drop existing database objects before restore.

```bash
wheels db restore backup.sql --clean
```

### --force
Skip confirmation prompts.

```bash
wheels db restore backup.sql --force
```

### --compressed
Indicate the file is compressed. Auto-detected for .gz files.

```bash
wheels db restore backup.sql.gz --compressed
```

## Examples

### Basic Restore

```bash
wheels db restore backup.sql
```

### Restore Compressed Backup

```bash
# Auto-detects compression from .gz extension
wheels db restore backup.sql.gz

# Or explicitly specify
wheels db restore backup.sql --compressed
```

### Clean Restore

Drop existing objects first:
```bash
wheels db restore backup.sql --clean
```

### Force Restore

Skip confirmation in scripts:
```bash
wheels db restore backup.sql --force
```

### Restore to Different Environment

```bash
wheels db restore prod-backup.sql --environment=staging --force
```

## Safety Features

1. **Confirmation Required**: Prompts before overwriting data
2. **Production Warning**: Extra warning for production environments
3. **File Validation**: Checks file exists before starting

## Database-Specific Behavior

### MySQL/MariaDB
- Uses `mysql` client
- Handles large files efficiently
- Preserves character sets

### PostgreSQL
- Uses `psql` client
- Supports custom formats from pg_dump
- Handles permissions and ownership

### SQL Server
- Uses `sqlcmd` client
- Limited support for complex backups
- Best with SSMS for full restores

### H2
- Uses RUNSCRIPT command
- Native support for compressed files
- Fast for embedded databases

## Common Workflows

### Development Reset

```bash
# Get fresh production data
wheels db dump --environment=production --output=prod-latest.sql
wheels db restore prod-latest.sql --environment=development --clean
```

### Disaster Recovery

```bash
# Restore from latest backup
wheels db restore backups/daily-20231204.sql.gz --force
```

### Environment Cloning

```bash
# Clone staging to test
wheels db dump --environment=staging --output=staging-snapshot.sql
wheels db restore staging-snapshot.sql --environment=test --clean
```

## Important Warnings

### Data Loss
- **Restoring overwrites existing data**
- Always backup current database first
- Use `--clean` carefully

### Version Compatibility
- Ensure dump is from compatible database version
- Check character set compatibility
- Verify schema matches application version

### Large Files
- Monitor disk space during restore
- Consider using `--compressed` dumps
- May need to adjust timeout settings

## Pre-Restore Checklist

1. **Backup current database**
   ```bash
   wheels db dump --output=pre-restore-backup.sql
   ```

2. **Verify dump file**
   ```bash
   ls -lh backup.sql
   head -n 20 backup.sql  # Check format
   ```

3. **Check disk space**
   ```bash
   df -h  # Ensure enough space
   ```

4. **Stop application** (if needed)
   ```bash
   server stop
   ```

## Troubleshooting

### "Access denied"
- Check database user has CREATE/DROP permissions
- Verify credentials in datasource

### "File not found"
- Check file path is correct
- Use absolute paths for clarity

### "Syntax error"
- Verify dump file isn't corrupted
- Check database version compatibility
- Ensure correct database type

### Restore Hangs
- Large databases take time
- Check database server resources
- Monitor with `wheels db shell` in another terminal

### Character Set Issues
- Ensure database charset matches dump
- Check connection encoding settings

## Best Practices

1. **Test restores regularly** - Verify backups work
2. **Document source** - Note where dumps came from
3. **Version control** - Track schema version with dumps
4. **Automate testing** - Script restore verification
5. **Secure dumps** - Protect sensitive data in dumps

## Recovery Scenarios

### Partial Restore

If full restore fails:
```bash
# Extract specific tables from dump
grep -E "(CREATE TABLE|INSERT INTO) users" backup.sql > users-only.sql
wheels db restore users-only.sql
```

### Manual Recovery

Use database shell for control:
```bash
wheels db shell
# Then manually run SQL from dump file
```

## Related Commands

- [`wheels db dump`](db-dump.md) - Create database dumps
- [`wheels db reset`](db-reset.md) - Alternative fresh start
- [`wheels db shell`](db-shell.md) - Manual restore control
- [`wheels db status`](db-status.md) - Verify after restore