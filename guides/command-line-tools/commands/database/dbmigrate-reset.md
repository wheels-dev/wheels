# dbmigrate reset

Reset all database migrations by rolling back all executed migrations and optionally re-running them.

## Synopsis

```bash
wheels dbmigrate reset [options]
```

## Description

The `dbmigrate reset` command provides a way to completely reset your database migrations. It rolls back all executed migrations in reverse order and can optionally re-run them all. This is particularly useful during development when you need to start fresh or when testing migration sequences.

## Options

### `--env`
- **Type:** String
- **Default:** `development`
- **Description:** The environment to reset migrations in

### `--datasource`
- **Type:** String
- **Default:** Application default
- **Description:** Specify a custom datasource for the reset

### `--remigrate`
- **Type:** Boolean
- **Default:** `false`
- **Description:** After rolling back all migrations, run them all again

### `--verbose`
- **Type:** Boolean
- **Default:** `false`
- **Description:** Display detailed output during reset

### `--force`
- **Type:** Boolean
- **Default:** `false`
- **Description:** Skip confirmation prompts (use with caution)

### `--dry-run`
- **Type:** Boolean
- **Default:** `false`
- **Description:** Preview the reset without executing it

## Examples

### Reset all migrations (rollback only)
```bash
wheels dbmigrate reset
```

### Reset and re-run all migrations
```bash
wheels dbmigrate reset --remigrate
```

### Reset in testing environment with verbose output
```bash
wheels dbmigrate reset --env=testing --verbose
```

### Force reset without confirmation
```bash
wheels dbmigrate reset --force --remigrate
```

### Preview reset operation
```bash
wheels dbmigrate reset --dry-run --verbose
```

## Use Cases

### Fresh Development Database
Start with a clean slate during development:
```bash
# Reset and rebuild database schema
wheels dbmigrate reset --remigrate --verbose

# Seed with test data
wheels db seed
```

### Testing Migration Sequence
Verify that all migrations run correctly from scratch:
```bash
# Reset all migrations
wheels dbmigrate reset

# Run migrations one by one to test
wheels dbmigrate up
wheels dbmigrate up
# ... continue as needed
```

### Fixing Migration Order Issues
When migrations have dependency problems:
```bash
# Reset all migrations
wheels dbmigrate reset

# Manually fix migration files
# Re-run all migrations
wheels dbmigrate latest
```

### Continuous Integration Setup
Reset database for each test run:
```bash
# CI script
wheels dbmigrate reset --env=testing --force --remigrate
wheels test run --env=testing
```

## Important Warnings

### Data Loss
**WARNING**: This command will result in complete data loss as it rolls back all migrations. Always ensure you have proper backups before running this command, especially in production environments.

### Production Usage
Using this command in production is strongly discouraged. If you must use it in production:
1. Take a complete database backup
2. Put the application in maintenance mode
3. Use the confirmation prompts (don't use --force)
4. Have a rollback plan ready

### Migration Dependencies
The reset process rolls back migrations in reverse chronological order. Ensure all your down() methods are properly implemented.

## Best Practices

1. **Development Only**: Primarily use this command in development environments
2. **Backup First**: Always backup your database before resetting
3. **Test Down Methods**: Ensure all migrations have working down() methods
4. **Use Confirmation**: Don't use --force unless in automated environments
5. **Document Usage**: If used in production, document when and why

## Process Flow

1. Confirms the operation (unless --force is used)
2. Retrieves all executed migrations
3. Rolls back each migration in reverse order
4. Clears the migration tracking table
5. If --remigrate is specified, runs all migrations again

## Notes

- The command will fail if any migration's down() method fails
- Migration files must still exist for rollback to work
- The migration tracking table itself is preserved
- Use `wheels dbmigrate info` after reset to verify status

## Related Commands

- [`wheels dbmigrate up`](dbmigrate-up.md) - Run the next migration
- [`wheels dbmigrate down`](dbmigrate-down.md) - Rollback last migration
- [`wheels dbmigrate latest`](dbmigrate-latest.md) - Run all pending migrations
- [`wheels dbmigrate info`](dbmigrate-info.md) - View migration status
- [`wheels db seed`](db-seed.md) - Seed the database with data