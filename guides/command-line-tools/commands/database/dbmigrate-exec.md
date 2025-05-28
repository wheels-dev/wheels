# dbmigrate exec

Execute a specific database migration by version number.

## Synopsis

```bash
wheels dbmigrate exec <version> [options]
```

## Description

The `dbmigrate exec` command allows you to run a specific migration identified by its version number, regardless of the current migration state. This is useful for applying individual migrations out of sequence during development or for special maintenance operations.

## Arguments

### `<version>`
- **Type:** String
- **Required:** Yes
- **Description:** The version number of the migration to execute (e.g., 20240115123456)

## Options

### `--env`
- **Type:** String
- **Default:** `development`
- **Description:** The environment to run the migration in

### `--datasource`
- **Type:** String
- **Default:** Application default
- **Description:** Specify a custom datasource for the migration

### `--direction`
- **Type:** String
- **Default:** `up`
- **Values:** `up`, `down`
- **Description:** Direction to run the migration (up or down)

### `--force`
- **Type:** Boolean
- **Default:** `false`
- **Description:** Force execution even if migration is already run

### `--verbose`
- **Type:** Boolean
- **Default:** `false`
- **Description:** Display detailed output during execution

### `--dry-run`
- **Type:** Boolean
- **Default:** `false`
- **Description:** Preview the migration without executing it

## Examples

### Execute a specific migration
```bash
wheels dbmigrate exec 20240115123456
```

### Execute migration's down method
```bash
wheels dbmigrate exec 20240115123456 --direction=down
```

### Force re-execution of a migration
```bash
wheels dbmigrate exec 20240115123456 --force --verbose
```

### Execute in production environment
```bash
wheels dbmigrate exec 20240115123456 --env=production
```

### Preview migration execution
```bash
wheels dbmigrate exec 20240115123456 --dry-run --verbose
```

## Use Cases

### Applying Hotfix Migrations
Apply a critical fix out of sequence:
```bash
# Create hotfix migration
wheels dbmigrate create blank --name=hotfix_critical_issue

# Execute it immediately
wheels dbmigrate exec 20240115123456 --env=production
```

### Re-running Failed Migrations
When a migration partially fails:
```bash
# Check migration status
wheels dbmigrate info

# Re-run the failed migration
wheels dbmigrate exec 20240115123456 --force --verbose
```

### Testing Specific Migrations
Test individual migrations during development:
```bash
# Run specific migration up
wheels dbmigrate exec 20240115123456

# Test the changes
# Run it down
wheels dbmigrate exec 20240115123456 --direction=down
```

### Selective Migration Application
Apply only certain migrations from a set:
```bash
# List all migrations
wheels dbmigrate info

# Execute only the ones you need
wheels dbmigrate exec 20240115123456
wheels dbmigrate exec 20240115134567
```

## Important Considerations

### Migration Order
Executing migrations out of order can cause issues if migrations have dependencies. Always ensure that any required preceding migrations have been run.

### Version Tracking
The command updates the migration tracking table to reflect the execution status. Using --force will update the timestamp of execution.

### Down Direction
When running with --direction=down, the migration must have already been executed (unless --force is used).

## Best Practices

1. **Check Dependencies**: Ensure required migrations are already applied
2. **Test First**: Run in development/testing before production
3. **Use Sparingly**: Prefer normal migration flow with up/latest
4. **Document Usage**: Record when and why specific executions were done
5. **Verify State**: Check migration status before and after execution

## Version Number Format

Migration versions are typically timestamps in the format:
- `YYYYMMDDHHmmss` (e.g., 20240115123456)
- Year: 2024
- Month: 01
- Day: 15
- Hour: 12
- Minute: 34
- Second: 56

## Notes

- The migration file must exist in the migrations directory
- Using --force bypasses normal safety checks
- The command will fail if the migration file has syntax errors
- Both up() and down() methods should be defined in the migration

## Related Commands

- [`wheels dbmigrate up`](dbmigrate-up.md) - Run the next migration
- [`wheels dbmigrate down`](dbmigrate-down.md) - Rollback last migration
- [`wheels dbmigrate latest`](dbmigrate-latest.md) - Run all pending migrations
- [`wheels dbmigrate info`](dbmigrate-info.md) - View migration status
- [`wheels dbmigrate create blank`](dbmigrate-create-blank.md) - Create a new migration