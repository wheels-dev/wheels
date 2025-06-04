# dbmigrate down

Rollback the last executed database migration.

## Synopsis

```bash
wheels dbmigrate down
```

Alias: `wheels db down`

## Description

The `dbmigrate down` command reverses the last executed migration by running its `down()` method. This is useful for undoing database changes when issues are discovered or when you need to modify a migration. The command ensures safe rollback of schema changes while maintaining database integrity.

## Parameters

None.

## Examples

### Rollback the last migration
```bash
wheels dbmigrate down
```

This will execute the down() method of the most recently applied migration, reverting the database changes.

## Use Cases

### Fixing Migration Errors
When a migration contains errors or needs modification:
```bash
# Run the migration
wheels dbmigrate up

# Discover an issue
# Rollback the migration
wheels dbmigrate down

# Edit the migration file
# Re-run the migration
wheels dbmigrate up
```

### Development Iteration
During development when refining migrations:
```bash
# Apply migration
wheels dbmigrate up

# Test the changes
# Need to modify? Rollback
wheels dbmigrate down

# Make changes to migration
# Apply again
wheels dbmigrate up
```

### Emergency Rollback
When a migration causes issues:
```bash
# Check current migration status
wheels dbmigrate info

# Rollback the problematic migration
wheels dbmigrate down

# Verify rollback
wheels dbmigrate info
```

## Important Considerations

### Data Loss Warning
Rolling back migrations that drop columns or tables will result in data loss. Always ensure you have backups before rolling back destructive migrations.

### Down Method Requirements
For a migration to be rolled back, it must have a properly implemented `down()` method that reverses the changes made in the `up()` method.

### Migration Dependencies
Be cautious when rolling back migrations that other migrations depend on. This can break the migration chain.

## Best Practices

1. **Always implement down() methods**: Even if you think you'll never need to rollback
2. **Test rollbacks**: In development, always test that your down() method works correctly
3. **Backup before rollback**: Especially in production environments
4. **Document destructive operations**: Clearly indicate when rollbacks will cause data loss

## Notes

- Only the last executed migration can be rolled back with this command
- To rollback multiple migrations, run the command multiple times
- If already at version 0, displays: "We're already on zero! No migrations to go to"
- Automatically runs `dbmigrate info` after successful rollback
- The migration version is removed from the database tracking table upon successful rollback
- Some operations (like dropping columns with data) cannot be fully reversed
- When migrating to version 0, displays: "Database should now be empty."

## Related Commands

- [`wheels dbmigrate up`](dbmigrate-up.md) - Run the next migration
- [`wheels dbmigrate reset`](dbmigrate-reset.md) - Reset all migrations
- [`wheels dbmigrate info`](dbmigrate-info.md) - View migration status
- [`wheels dbmigrate exec`](dbmigrate-exec.md) - Run a specific migration