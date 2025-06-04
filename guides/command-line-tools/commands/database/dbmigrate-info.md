# wheels dbmigrate info

Display database migration status and information.

## Synopsis

```bash
wheels dbmigrate info
```

Alias: `wheels db info`

## Description

The `wheels dbmigrate info` command shows the current state of database migrations, including which migrations have been run, which are pending, and the current database version.

## Parameters

None.

## Output

The command displays:

1. **Datasource**: The database connection being used
2. **Database Type**: The type of database (MySQL, PostgreSQL, etc.)
3. **Total Migrations**: Count of all migration files found
4. **Available Migrations**: Number of pending migrations
5. **Current Version**: The latest migration that has been run
6. **Latest Version**: The newest migration available
7. **Migration List**: All migrations with their status (migrated or pending)

## Example Output

```
+-----------------------------------------+-----------------------------------------+
| Datasource: myapp_development           | Total Migrations: 6                     |
| Database Type: MySQL                    | Available Migrations: 2                 |
|                                         | Current Version: 20240115120000         |
|                                         | Latest Version: 20240125160000          |
+-----------------------------------------+-----------------------------------------+
+----------+------------------------------------------------------------------------+
| migrated | 20240101100000_create_users_table.cfc                                 |
| migrated | 20240105150000_create_products_table.cfc                              |
| migrated | 20240110090000_add_email_to_users.cfc                                 |
| migrated | 20240115120000_create_orders_table.cfc                                |
|          | 20240120140000_add_status_to_orders.cfc                               |
|          | 20240125160000_create_categories_table.cfc                            |
+----------+------------------------------------------------------------------------+
```

## Migration Files Location

Migrations are stored in `/app/migrator/migrations/` and follow the naming convention:
```
[timestamp]_[description].cfc
```

Example:
```
20240125160000_create_users_table.cfc
```

## Understanding Version Numbers

- Version numbers are timestamps in format: `YYYYMMDDHHmmss`
- Higher numbers are newer migrations
- Migrations run in chronological order

## Database Schema Table

Migration status is tracked in `schema_migrations` table:

```sql
SELECT * FROM schema_migrations;
+----------------+
| version        |
+----------------+
| 20240101100000 |
| 20240105150000 |
| 20240110090000 |
| 20240115120000 |
+----------------+
```

## Use Cases

1. **Check before deployment**
   ```bash
   wheels dbmigrate info
   ```

2. **Verify after migration**
   ```bash
   wheels dbmigrate latest
   wheels dbmigrate info
   ```

3. **Troubleshoot issues**
   - See which migrations have run
   - Identify pending migrations
   - Confirm database version

## Common Scenarios

### All Migrations Complete
```
Current Version: 20240125160000
Status: 6 completed, 0 pending
✓ Database is up to date
```

### Fresh Database
```
Current Version: 0
Status: 0 completed, 6 pending
⚠ No migrations have been run
```

### Partial Migration
```
Current Version: 20240110090000
Status: 3 completed, 3 pending
⚠ Database needs migration
```

## Troubleshooting

### Migration Not Showing
- Check file is in `/app/migrator/migrations/`
- Verify `.cfc` extension
- Ensure proper timestamp format

### Version Mismatch
- Check `schema_migrations` table
- Verify migration files haven't been renamed
- Look for duplicate timestamps

### Connection Issues
- Verify datasource configuration
- Check database credentials
- Ensure database server is running

## Integration with CI/CD

Use in deployment scripts:
```bash
#!/bin/bash
# Check migration status
wheels dbmigrate info

# Run if needed
if [[ $(wheels dbmigrate info | grep "pending") ]]; then
    echo "Running pending migrations..."
    wheels dbmigrate latest
fi
```

## Best Practices

1. Always check info before running migrations
2. Review pending migrations before deployment
3. Keep migration files in version control
4. Don't modify completed migration files
5. Use info to verify production deployments

## See Also

- [wheels dbmigrate latest](dbmigrate-latest.md) - Run all pending migrations
- [wheels dbmigrate up](dbmigrate-up.md) - Run next migration
- [wheels dbmigrate down](dbmigrate-down.md) - Rollback migration
- [wheels dbmigrate create blank](dbmigrate-create-blank.md) - Create new migration