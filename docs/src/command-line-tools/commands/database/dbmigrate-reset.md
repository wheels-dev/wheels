# dbmigrate reset

Reset all database migrations by migrating to version 0.

## Synopsis

```bash
wheels dbmigrate reset
```

## Description

The `dbmigrate reset` command resets your database by migrating to version 0, effectively rolling back all executed migrations. This is useful during development when you need to start fresh.

## Parameters

None.

## Examples

### Reset all migrations
```bash
wheels dbmigrate reset
```

This will migrate the database to version 0, rolling back all migrations.

## Use Cases

### Fresh Development Database
Start with a clean slate during development:
```bash
# Reset all migrations
wheels dbmigrate reset

# Re-run all migrations
wheels dbmigrate latest

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
wheels dbmigrate reset
wheels dbmigrate latest
wheels test run
```

## Important Warnings

### Data Loss
**WARNING**: This command will result in complete data loss as it rolls back all migrations. Always ensure you have proper backups before running this command, especially in production environments.

### Production Usage
Using this command in production is strongly discouraged. If you must use it in production:
1. Take a complete database backup
2. Put the application in maintenance mode
3. Have a rollback plan ready

### Migration Dependencies
The reset process rolls back migrations in reverse chronological order. Ensure all your down() methods are properly implemented.

## Best Practices

1. **Development Only**: Primarily use this command in development environments
2. **Backup First**: Always backup your database before resetting
3. **Test Down Methods**: Ensure all migrations have working down() methods
4. **Document Usage**: If used in production, document when and why

## Process Flow

1. Displays "Resetting Database Schema"
2. Executes `dbmigrate exec version=0`
3. Automatically runs `dbmigrate info` to show the reset status

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