# wheels db version

Show the current database schema version.

## Synopsis

```bash
wheels db version [--detailed]
```

## Description

The `wheels db version` command displays the current version of your database schema based on the last applied migration. This is useful for quickly checking which migration version your database is at.

## Options

### --detailed
Show additional information about the database state.

```bash
wheels db version --detailed
```

## Examples

### Basic Usage

Show current version:
```bash
wheels db version
```

Output:
```
Current database version: 20231203160000
```

### Detailed Information

```bash
wheels db version --detailed
```

Output:
```
Current database version: 20231203160000

Last migration:
  Version: 20231203160000
  Description: CreatePostsTable
  Applied at: 2023-12-03 16:45:32

Total migrations: 15
Pending migrations: 2

Next migration to apply:
  Version: 20231204180000
  Description: AddIndexToPostsUserId

Environment: development
Datasource: myapp_dev
```

## Understanding Versions

### Version Format

Migrations use timestamp-based versions:
- Format: `YYYYMMDDHHMMSS`
- Example: `20231203160000` = December 3, 2023 at 4:00:00 PM

### No Version

If you see "No migrations have been applied yet":
- Database is fresh with no migrations run
- Run `wheels dbmigrate latest` to apply migrations

## Common Use Cases

### Quick Check

Before running migrations:
```bash
wheels db version
wheels dbmigrate latest
```

### Deployment Verification

```bash
# Check production is up to date
wheels db version --environment=production --detailed
```

### Troubleshooting

Compare versions across environments:
```bash
# Development
wheels db version --environment=development

# Staging
wheels db version --environment=staging

# Production
wheels db version --environment=production
```

## Related Information

The version corresponds to:
- The latest migration file that has been applied
- An entry in the migration tracking table
- The current schema state of your database

## Related Commands

- [`wheels db status`](db-status.md) - Show all migrations and their status
- [`wheels dbmigrate latest`](dbmigrate-latest.md) - Update to latest version
- [`wheels db rollback`](db-rollback.md) - Rollback to previous version
- [`wheels dbmigrate info`](dbmigrate-info.md) - Detailed migration information