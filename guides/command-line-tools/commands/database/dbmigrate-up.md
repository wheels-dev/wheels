# dbmigrate up

Run the next pending database migration.

## Synopsis

```bash
wheels dbmigrate up [options]
```

## Description

The `dbmigrate up` command executes the next pending migration in your database migration queue. This command is used to incrementally apply database changes one migration at a time, allowing for controlled and reversible database schema updates.

## Options

### `--env`
- **Type:** String
- **Default:** `development`
- **Description:** The environment to run the migration in (development, testing, production)

### `--datasource`
- **Type:** String
- **Default:** Application default
- **Description:** Specify a custom datasource for the migration

### `--verbose`
- **Type:** Boolean
- **Default:** `false`
- **Description:** Display detailed output during migration execution

### `--dry-run`
- **Type:** Boolean
- **Default:** `false`
- **Description:** Preview the migration without executing it

## Examples

### Run the next pending migration
```bash
wheels dbmigrate up
```

### Run migration in production environment
```bash
wheels dbmigrate up --env=production
```

### Preview migration without executing
```bash
wheels dbmigrate up --dry-run --verbose
```

### Use a specific datasource
```bash
wheels dbmigrate up --datasource=myCustomDB
```

## Use Cases

### Incremental Database Updates
When you want to apply database changes one at a time rather than all at once:
```bash
# Check pending migrations
wheels dbmigrate info

# Apply next migration
wheels dbmigrate up

# Verify the change
wheels dbmigrate info
```

### Testing Individual Migrations
Test migrations individually before applying all pending changes:
```bash
# Run in test environment first
wheels dbmigrate up --env=testing

# If successful, apply to development
wheels dbmigrate up --env=development
```

### Controlled Production Deployments
Apply migrations incrementally in production for better control:
```bash
# Preview the migration
wheels dbmigrate up --dry-run --env=production

# Apply if preview looks good
wheels dbmigrate up --env=production

# Monitor application
# If issues arise, can rollback with 'wheels dbmigrate down'
```

## Notes

- Migrations are executed in chronological order based on their timestamps
- Each migration is tracked in the database to prevent duplicate execution
- Use `wheels dbmigrate info` to see pending and completed migrations
- Always backup your database before running migrations in production

## Related Commands

- [`wheels dbmigrate down`](dbmigrate-down.md) - Rollback the last migration
- [`wheels dbmigrate latest`](dbmigrate-latest.md) - Run all pending migrations
- [`wheels dbmigrate info`](dbmigrate-info.md) - View migration status
- [`wheels dbmigrate reset`](dbmigrate-reset.md) - Reset all migrations