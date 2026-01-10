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
2. **Database Type**: The type of database (MySQL, PostgreSQL, H2, MSSQL(SQL Server), Oracle.)
3. **Total Migrations**: Count of all migration files found
4. **Available Migrations**: Number of pending migrations
5. **Current Version**: The latest migration that has been run
6. **Latest Version**: The newest migration available
7. **Migration List**: All migrations with their status (migrated or pending)

## Example Output

```
+-----------------------------------------+-----------------------------------------+
| Datasource:                       myApp | Total Migrations:                     4 |
| Database Type:                       H2 | Available Migrations:                 4 |
|                                         | Current Version:                      0 |
|                                         | Latest Version:          20250812161449 |
+-----------------------------------------+-----------------------------------------+
+----------+------------------------------------------------------------------------+
|          | 20250812161449_cli__create_reporting_procedures                        |
|          | 20250812161302_cli__blacnk                                             |
|          | 20250812161250_cli__name                                               |
|          | 20250812154338_cli__0                                                  |
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

Migration status is tracked in `c_o_r_e_migrator_versions` table:

```sql
SELECT * FROM c_o_r_e_migrator_versions;
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


## Troubleshooting

### Migration Not Showing
- Check file is in `/app/migrator/migrations/`
- Verify `.cfc` extension
- Ensure proper timestamp format

### Version Mismatch
- Check `c_o_r_e_migrator_versions` table
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