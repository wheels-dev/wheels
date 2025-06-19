# wheels db status

Show the status of database migrations.

## Synopsis

```bash
wheels db status [--format=<format>] [--pending]
```

## Description

The `wheels db status` command displays information about the current state of database migrations, showing which migrations have been applied and which are pending.

## Options

### --format=<format>
Output format. Options are `table` (default) or `json`.

```bash
wheels db status --format=json
```

### --pending
Show only pending migrations.

```bash
wheels db status --pending
```

## Examples

### Basic Usage

Show all migrations in table format:
```bash
wheels db status
```

Output:
```
Current database version: 20231203160000

| Version              | Description                      | Status   | Applied At         |
|--------------------|----------------------------------|----------|-------------------|
| 20231201120000     | CreateUsersTable                 | applied  | 2023-12-01 12:30  |
| 20231202140000     | AddEmailToUsers                  | applied  | 2023-12-02 14:15  |
| 20231203160000     | CreatePostsTable                 | applied  | 2023-12-03 16:45  |
| 20231204180000     | AddIndexToPostsUserId            | pending  | Not applied       |

Total migrations: 4
Applied: 3
Pending: 1
```

### Show Only Pending

```bash
wheels db status --pending
```

### JSON Output

```bash
wheels db status --format=json
```

Output:
```json
{
  "success": true,
  "currentVersion": "20231203160000",
  "migrations": [
    {
      "version": "20231201120000",
      "description": "CreateUsersTable",
      "status": "applied",
      "appliedAt": "2023-12-01 12:30:00"
    },
    {
      "version": "20231204180000",
      "description": "AddIndexToPostsUserId",
      "status": "pending",
      "appliedAt": null
    }
  ],
  "summary": {
    "total": 4,
    "applied": 3,
    "pending": 1
  }
}
```

## Understanding the Output

### Table Format

- **Version**: Migration timestamp/version number
- **Description**: Human-readable migration name
- **Status**: Either "applied" or "pending"
- **Applied At**: When the migration was run

### Status Colors

- **Green**: Applied migrations
- **Yellow**: Pending migrations

### Summary Section

Shows counts of:
- Total migrations in the migrations folder
- Applied migrations in the database
- Pending migrations to be run

## Common Scenarios

### Check Before Deployment

```bash
# See what migrations will run in production
wheels db status --environment=production --pending
```

### Verify Migration Applied

```bash
# Check if specific migration was applied
wheels db status | grep "AddEmailToUsers"
```

### CI/CD Integration

```bash
# Get pending count for automation
wheels db status --format=json | jq '.summary.pending'
```

## Troubleshooting

### "No migrations found"
- Check that migration files exist in `/db/migrate/` directory
- Ensure file naming follows pattern: `YYYYMMDDHHMMSS_Description.cfc`

### Version Mismatch
If the database version doesn't match expected:
- Check migration history in database
- Verify no migrations were manually deleted
- Consider running `wheels dbmigrate latest`

## Related Commands

- [`wheels db version`](db-version.md) - Show just the current version
- [`wheels dbmigrate latest`](dbmigrate-latest.md) - Apply pending migrations
- [`wheels db rollback`](db-rollback.md) - Rollback migrations
- [`wheels dbmigrate info`](dbmigrate-info.md) - Similar migration information