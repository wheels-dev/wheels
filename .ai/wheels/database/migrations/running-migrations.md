# Running Migrations

## Description
Execute database migrations to apply schema changes using Wheels CLI commands.

## Key Points
- `wheels dbmigrate info` shows current status
- `wheels dbmigrate latest` runs all pending migrations
- `wheels dbmigrate up` runs next migration only
- Migrations tracked in `c_o_r_e_migrator_versions` table
- Can automate in production with settings

## Code Sample
```bash
# Check migration status
wheels dbmigrate info

# Run all pending migrations (most common)
wheels dbmigrate latest

# Run one migration at a time
wheels dbmigrate up

# Run specific migration version
wheels dbmigrate exec 20240125143022

# Production automation in settings.cfm
set(autoMigrateDatabase=true);        // Auto-run on app start
set(allowMigrationDown=false);        // Prevent rollbacks
```

## Usage
1. Check status: `wheels dbmigrate info`
2. Run pending: `wheels dbmigrate latest`
3. Monitor output for errors
4. Verify changes in database
5. Use automation for production deployments

## Related
- [Creating Migrations](./creating-migrations.md)
- [Rollback](./rollback.md)
- [Production Configuration](../../configuration/environments.md)

## Important Notes
- Always backup production before migrations
- Test migrations in development first
- Migration versions stored in database
- Failed migrations may leave partial changes
- Use `latest` for production deployments