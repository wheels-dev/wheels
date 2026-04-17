---
title: dbmigrate up
---
# dbmigrate up

Run the next pending database migration.

## Synopsis

```bash
wheels dbmigrate up
```

Alias: `wheels db up`

## Description

The `dbmigrate up` command executes the next pending migration in your database migration queue. This command is used to incrementally apply database changes one migration at a time, allowing for controlled and reversible database schema updates.

## Parameters

None.

## Examples

### Run the next pending migration
```bash
wheels dbmigrate up
```

This will execute the next migration in the sequence and update the database schema version.

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

### Controlled Migration Application
Apply migrations one at a time for better control:
```bash
# Check current status
wheels dbmigrate info

# Apply next migration
wheels dbmigrate up

# Verify the change was applied
wheels dbmigrate info
```

## Notes

- Migrations are executed in chronological order based on their timestamps
- Each migration is tracked in the database to prevent duplicate execution
- If already at latest version, displays: "We're all up to date already!"
- If no more versions available, displays: "No more versions to go to?"
- Automatically runs `dbmigrate info` after successful migration
- Always backup your database before running migrations in production

## Related Commands

- [`wheels dbmigrate down`](/v3-1-0/command-line-tools/commands/database/dbmigrate-down/) - Rollback the last migration
- [`wheels dbmigrate latest`](/v3-1-0/command-line-tools/commands/database/dbmigrate-latest/) - Run all pending migrations
- [`wheels dbmigrate info`](/v3-1-0/command-line-tools/commands/database/dbmigrate-info/) - View migration status
- [`wheels dbmigrate reset`](/v3-1-0/command-line-tools/commands/database/dbmigrate-reset/) - Reset all migrations