# wheels dbmigrate info

Display database migration status and information.

## Synopsis

```bash
wheels dbmigrate info
```

## Description

The `wheels dbmigrate info` command shows the current state of database migrations, including which migrations have been run, which are pending, and the current database version.

## Options

| Option | Description |
|--------|-------------|
| `--help` | Show help information |

## Output

The command displays:

1. **Current Version**: The latest migration that has been run
2. **Available Migrations**: All migration files found
3. **Migration Status**: Which migrations are completed vs pending
4. **Database Details**: Connection information

## Example Output

```
╔═══════════════════════════════════════════════╗
║         Database Migration Status             ║
╚═══════════════════════════════════════════════╝

Current Version: 20240115120000
Database: myapp_development
Connection: MySQL 8.0

╔═══════════════════════════════════════════════╗
║              Migration History                ║
╚═══════════════════════════════════════════════╝

✓ 20240101100000_create_users_table.cfc
✓ 20240105150000_create_products_table.cfc
✓ 20240110090000_add_email_to_users.cfc
✓ 20240115120000_create_orders_table.cfc
○ 20240120140000_add_status_to_orders.cfc (pending)
○ 20240125160000_create_categories_table.cfc (pending)

Status: 4 completed, 2 pending

To run pending migrations, use: wheels dbmigrate latest
```

## Migration Files Location

Migrations are stored in `/db/migrate/` and follow the naming convention:
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
- Check file is in `/db/migrate/`
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