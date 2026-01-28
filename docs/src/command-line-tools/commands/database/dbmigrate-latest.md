# wheels dbmigrate latest

Run all pending database migrations to bring database to latest version.

## Synopsis

```bash
wheels dbmigrate latest
```

Alias: `wheels db latest`

## Description

The `wheels dbmigrate latest` command runs all pending migrations in chronological order, updating your database schema to the latest version. This is the most commonly used migration command.

## Parameters

None.

## How It Works

1. Retrieves current database version and latest version
2. Executes `dbmigrate exec` with the latest version
3. Automatically runs `dbmigrate info` after completion
4. Updates version tracking after successful migration

## Example Output

```
==================================================
    Updating Database Schema to Latest Version
==================================================

Latest Version:           20260123185445
==================================================
               Migration Execution
==================================================

Target Version:           20260123185445
--------------------------------------------------
Sending: http://0.0.0.0:8080/?controller=wheels&action=wheels&view=cli&command=migrateTo&version=20260123185445
[SUCCESS]: Call to bridge was successful.
[SUCCESS]: Migration completed successfully!

Sending: http://0.0.0.0:8080/?controller=wheels&action=wheels&view=cli&command=info
[SUCCESS]: Call to bridge was successful.
==================================================
            Database Migration Status
==================================================


Database Information
--------------------------------------------------
Datasource:               dbapp_test
Database Type:            MySQL

Migration Status
--------------------------------------------------
Total Migrations:         17
Available Migrations:     14
Current Version:          20260116163515
Latest Version:           20260123185445
--------------------------------------------------

Migration Files
--------------------------------------------------
╔══════════╤══════════════════════════════════════════════════════╗
║ STATUS   │ FILE                                                 ║
╠══════════╪══════════════════════════════════════════════════════╣
║          │ 20260123185445_cli_create_table_user                 ║
╟──────────┼──────────────────────────────────────────────────────╢
║          │ 20260123183026_cli_remove_table_blog_posts           ║
╟──────────┼──────────────────────────────────────────────────────╢
║          │ 20260123182948_create_blog_posts_table               ║
╟──────────┼──────────────────────────────────────────────────────╢
║          │ 20260122173254_cli_create_table_user_roles           ║
╟──────────┼──────────────────────────────────────────────────────╢
║          │ 20260119145114_cli_create_column_parts_feature       ║
╟──────────┼──────────────────────────────────────────────────────╢
║          │ 20260119144642_cli_blank_students                    ║
╟──────────┼──────────────────────────────────────────────────────╢
║          │ 20260119112924_cli_create_table_students             ║
╟──────────┼──────────────────────────────────────────────────────╢
║          │ 20260119111943_cli_create_table_books                ║
╟──────────┼──────────────────────────────────────────────────────╢
║          │ 20260116170453_cli_create_table_users                ║
╟──────────┼──────────────────────────────────────────────────────╢
║          │ 20260116170311_cli_create_table_users                ║
╟──────────┼──────────────────────────────────────────────────────╢
║          │ 20260116165727_cli_create_column_user_required_field ║
╟──────────┼──────────────────────────────────────────────────────╢
║          │ 20260116164432_cli_create_column_product_price       ║
╟──────────┼──────────────────────────────────────────────────────╢
║          │ 20260116164211_cli_create_column_user_bio            ║
╟──────────┼──────────────────────────────────────────────────────╢
║          │ 20260116163907_cli_create_column_user_email          ║
╟──────────┼──────────────────────────────────────────────────────╢
║ migrated │ 20260116163515_cli_blank_create_reporting_procedures ║
╟──────────┼──────────────────────────────────────────────────────╢
║ migrated │ 20260116160315_cli_remove_table_resources            ║
╟──────────┼──────────────────────────────────────────────────────╢
║ migrated │ 20260116155320_cli_remove_table_users                ║
╚══════════╧══════════════════════════════════════════════════════╝
```

## Migration Execution

Each migration file must contain:

```cfc
component extends="wheels.migrator.Migration" {

    function up() {
        // Database changes go here
        transaction {
            // Use transaction for safety
        }
    }

    function down() {
        // Rollback logic (optional)
        transaction {
            // Reverse the up() changes
        }
    }

}
```

## Transaction Safety

Migrations run within transactions:
- All changes in a migration succeed or fail together
- Database remains consistent
- Failed migrations can be retried

## Common Migration Operations

### Create Table
```cfc
function up() {
    transaction {
        t = createTable("products");
        t.string("name");
        t.decimal("price");
        t.timestamps();
        t.create();
    }
}
```

### Add Column
```cfc
function up() {
    transaction {
        addColumn(table="users", columnNames="email", type="string");
    }
}
```

### Add Index
```cfc
function up() {
    transaction {
        addIndex(table="users", columnNames="email", unique=true);
    }
}
```

### Modify Column
```cfc
function up() {
    transaction {
        changeColumn(table="products", columnNames="price", type="decimal", precision=10, scale=2);
    }
}
```


## Best Practices

1. **Test migrations locally first**
   ```bash
   # Test on development database
   wheels dbmigrate latest
   
   # Verify
   wheels dbmigrate info
   ```

2. **Backup before production migrations**
   ```bash
   # Backup database
   mysqldump myapp_production > backup.sql
   
   # Run migrations
   wheels dbmigrate latest
   ```

3. **Use transactions**
   ```cfc
   function up() {
       transaction {
           // All changes here
       }
   }
   ```

4. **Make migrations reversible**
   ```cfc
   function down() {
       transaction {
           dropTable("products");
       }
   }
   ```

## Environment-Specific Migrations

Migrations can check environment:

```cfc
function up() {
    transaction {
        // Always run
        addColumn(table="users", column="lastLogin", type="datetime");
        
        // Development only
        if (get("environment") == "development") {
            // Add test data
            sql("INSERT INTO users (email) VALUES ('test@example.com')");
        }
    }
}
```

## Checking Migrations

Preview migrations before running:

```bash
# Check what would run
wheels dbmigrate info

# Review migration files
ls app/migrator/migrations/
```

## Performance Considerations

For large tables:

```cfc
function up() {
    transaction {
        // Add index concurrently (if supported)
        if (get("databaseType") == "postgresql") {
            sql("CREATE INDEX CONCURRENTLY idx_users_email ON users(email)");
        } else {
            addIndex(table="users", columns="email");
        }
    }
}
```

## Continuous Integration

Add to CI/CD pipeline:

```yaml
# .github/workflows/deploy.yml
- name: Run migrations
  run: |
    wheels dbmigrate latest
    wheels test app
```

## Rollback Strategy

If issues occur after migration:

1. **Use down migrations**
   ```bash
   wheels dbmigrate down
   wheels dbmigrate down
   ```

2. **Restore from backup**
   ```bash
   mysql myapp_production < backup.sql
   ```

3. **Fix and retry**
   - Fix migration file
   - Run `wheels dbmigrate latest`

## Common Issues

### Timeout on Large Tables
```cfc
function up() {
    // Increase timeout for large operations
    setting requestTimeout="300";
    
    transaction {
        // Long running operation
    }
}
```

### Foreign Key Constraints
```cfc
function up() {
    transaction {
        // Disable checks temporarily
        sql("SET FOREIGN_KEY_CHECKS=0");
        
        // Make changes
        dropTable("orders");
        
        // Re-enable
        sql("SET FOREIGN_KEY_CHECKS=1");
    }
}
```

## See Also

- [wheels dbmigrate info](dbmigrate-info.md) - Check migration status
- [wheels dbmigrate up](dbmigrate-up.md) - Run single migration
- [wheels dbmigrate down](dbmigrate-down.md) - Rollback migration
- [wheels dbmigrate create blank](dbmigrate-create-blank.md) - Create migration