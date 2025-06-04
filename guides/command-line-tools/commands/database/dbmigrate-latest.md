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
╔═══════════════════════════════════════════════╗
║          Running Pending Migrations           ║
╚═══════════════════════════════════════════════╝

Current Version: 20240110090000
Target Version: 20240125160000

Migrating...

→ Running 20240115120000_create_orders_table.cfc
  Creating table: orders
  Adding indexes...
  ✓ Success (0.125s)

→ Running 20240120140000_add_status_to_orders.cfc
  Adding column: status to orders
  ✓ Success (0.089s)

→ Running 20240125160000_create_categories_table.cfc
  Creating table: categories
  Adding foreign keys...
  ✓ Success (0.143s)

╔═══════════════════════════════════════════════╗
║            Migration Complete                 ║
╚═══════════════════════════════════════════════╝

Previous Version: 20240110090000
Current Version:  20240125160000
Migrations Run:   3
Total Time:       0.357s
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
        addColumn(table="users", column="email", type="string");
    }
}
```

### Add Index
```cfc
function up() {
    transaction {
        addIndex(table="users", columns="email", unique=true);
    }
}
```

### Modify Column
```cfc
function up() {
    transaction {
        changeColumn(table="products", column="price", type="decimal", precision=10, scale=2);
    }
}
```

## Error Handling

If a migration fails:

```
→ Running 20240120140000_add_status_to_orders.cfc
  Adding column: status to orders
  ✗ ERROR: Column 'status' already exists

Migration failed at version 20240115120000
Error: Column 'status' already exists in table 'orders'

To retry: Fix the migration file and run 'wheels dbmigrate latest' again
To skip: Run 'wheels dbmigrate up' to run one at a time
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