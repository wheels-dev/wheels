# dbmigrate exec

Execute a specific database migration by version number.

## Synopsis

```bash
wheels dbmigrate exec version=<version>
```

Alias: `wheels db exec`

## Description

The `dbmigrate exec` command allows you to migrate to a specific version identified by its version number, regardless of the current migration state. This is useful for moving to any specific point in your migration history.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `version` | string | Yes | Version to migrate to |

## Examples

### Execute a specific migration
```bash
wheels dbmigrate exec version=20240115123456
```

### Migrate to version 0 (revert all migrations)
```bash
wheels dbmigrate exec version=0
```

## Use Cases

### Migrating to a Specific Version
Move to any point in migration history:
```bash
# Check current status
wheels dbmigrate info

# Migrate to specific version
wheels dbmigrate exec version=20240115123456
```

### Rolling Back to Previous Version
Move to an earlier migration state:
```bash
# Check migration history
wheels dbmigrate info

# Go back to specific version
wheels dbmigrate exec version=20240101000000
```

### Reset Database
Clear all migrations:
```bash
# Migrate to version 0
wheels dbmigrate exec version=0

# Verify empty state
wheels dbmigrate info
```

## Important Considerations

### Migration Order
Executing migrations out of order can cause issues if migrations have dependencies. Always ensure that any required preceding migrations have been run.

### Version Tracking
The command updates the migration tracking table to reflect the execution status.

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

- The command will migrate UP or DOWN to reach the specified version
- Version must be a valid migration version or 0 to reset all
- The migration file must exist in the migrations directory
- The command displays the migration progress message
- Both up() and down() methods should be defined in the migration

## Related Commands

- [`wheels dbmigrate up`](dbmigrate-up.md) - Run the next migration
- [`wheels dbmigrate down`](dbmigrate-down.md) - Rollback last migration
- [`wheels dbmigrate latest`](dbmigrate-latest.md) - Run all pending migrations
- [`wheels dbmigrate info`](dbmigrate-info.md) - View migration status
- [`wheels dbmigrate create blank`](dbmigrate-create-blank.md) - Create a new migration