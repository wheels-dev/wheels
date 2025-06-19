# wheels db rollback

Rollback database migrations to a previous state.

## Synopsis

```bash
wheels db rollback [--steps=<n>] [--target=<version>] [--force]
```

## Description

The `wheels db rollback` command reverses previously applied migrations by running their `down` methods. You can rollback a specific number of migrations or to a specific version.

## Options

### --steps=<n>
Number of migrations to rollback. Defaults to 1.

```bash
wheels db rollback --steps=3
```

### --target=<version>
Rollback to a specific migration version.

```bash
wheels db rollback --target=20231201120000
```

### --force
Skip the confirmation prompt.

```bash
wheels db rollback --force
```

## Examples

### Basic Usage

Rollback the last migration:
```bash
wheels db rollback
```

### Rollback Multiple Migrations

Rollback the last 3 migrations:
```bash
wheels db rollback --steps=3
```

### Rollback to Specific Version

Rollback to a specific point in time:
```bash
wheels db rollback --target=20231201120000
```

### Force Rollback

Skip confirmation:
```bash
wheels db rollback --steps=5 --force
```

## How It Works

1. **Identifies Migrations**: Determines which migrations to rollback
2. **Confirmation**: Asks for confirmation (unless --force)
3. **Executes Down Methods**: Runs the `down()` method of each migration in reverse order
4. **Updates Version**: Updates the database version tracking

## Important Considerations

### Data Loss Warning

Rollbacks can result in data loss if migrations:
- Drop tables
- Remove columns
- Delete records

Always backup before rolling back:
```bash
wheels db dump --output=backup-before-rollback.sql
wheels db rollback --steps=3
```

### Migration Requirements

For rollback to work, migrations must:
- Have a properly implemented `down()` method
- Be reversible (some operations can't be undone)

Example migration with down method:
```cfc
component {
    function up() {
        addColumn(table="users", columnName="age", columnType="integer");
    }
    
    function down() {
        removeColumn(table="users", columnName="age");
    }
}
```

## Common Scenarios

### Development Corrections

Made a mistake in the last migration:
```bash
# Rollback
wheels db rollback

# Fix the migration file
# Edit: db/migrate/20231204180000_AddAgeToUsers.cfc

# Run it again
wheels dbmigrate latest
```

### Feature Rollback

Remove a feature and its database changes:
```bash
# Rollback feature migrations
wheels db rollback --target=20231201120000

# Remove feature code
# Deploy
```

### Testing Migrations

Test that migrations are reversible:
```bash
# Apply migration
wheels dbmigrate latest

# Test rollback
wheels db rollback

# Reapply
wheels dbmigrate latest
```

## Troubleshooting

### "No down method"

If you see this error:
- The migration doesn't have a `down()` method
- Add the method to make it reversible
- Or use `wheels db reset` if in development

### "Cannot rollback"

Some operations can't be reversed:
- Data deletions (unless backed up in migration)
- Complex transformations
- External system changes

### Rollback Fails

If rollback fails partway:
1. Check error message for specific issue
2. Fix the migration's down method
3. Manually correct database if needed
4. Update migration tracking table

## Best Practices

1. **Always implement down methods** in migrations
2. **Test rollbacks** in development before production
3. **Backup before rollback** in production
4. **Document irreversible changes** in migrations
5. **Use transactions** in complex rollbacks

## Related Commands

- [`wheels db status`](db-status.md) - Check current migration state
- [`wheels dbmigrate down`](dbmigrate-down.md) - Similar single rollback
- [`wheels db reset`](db-reset.md) - Full database reset
- [`wheels db dump`](db-dump.md) - Backup before rollback