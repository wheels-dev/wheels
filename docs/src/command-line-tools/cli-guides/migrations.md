# Database Migration Guide

Learn how to manage database schema changes effectively using Wheels CLI migrations.

## Overview

Database migrations provide version control for your database schema. They allow you to:
- Track schema changes over time
- Share database changes with your team
- Deploy schema updates safely
- Roll back changes if needed
- Keep database and code in sync

## Migration Basics

### What is a Migration?

A migration is a CFC file that describes a database change. Each migration has:
- A timestamp-based version number
- An `up()` method to apply changes
- An optional `down()` method to reverse changes

### Migration Files

Migrations are stored in `/app/migrator/migrations/` with this naming convention:
```
[YYYYMMDDHHmmss]_[description].cfc
```

Example:
```
20240125143022_create_users_table.cfc
20240125143523_add_email_to_users.cfc
```

## Creating Migrations

### Generate Migration Commands

```bash
# Create blank migration
wheels dbmigrate create blank add_status_to_orders

# Create table migration
wheels dbmigrate create table products

# Add column migration
wheels dbmigrate create column users email
```

### Migration Structure

Basic migration template:

```cfc
component extends="wheels.migrator.Migration" {
    
    function up() {
        transaction {
            // Apply changes
        }
    }
    
    function down() {
        transaction {
            // Reverse changes
        }
    }
    
}
```

## Table Operations

### Creating Tables

```cfc
function up() {
    transaction {
        t = createTable("products");
        
        // Primary key (auto-created as 'id' by default)
        t.primaryKey("productId"); // Custom primary key
        
        // Column types
        t.string(columnNames="name", limit=100);
        t.text(columnNames="description");
        t.text(columnNames="content", size="mediumtext"); // MySQL only: mediumtext (16MB)
        t.text(columnNames="longDescription", size="longtext"); // MySQL only: longtext (4GB)
        t.integer(columnNames="quantity");
        t.bigInteger(columnNames="views");
        t.float(columnNames="weight");
        t.decimal(columnNames="price", precision=10, scale=2);
        t.boolean(columnNames="active", default=true);
        t.date(columnNames="releaseDate");
        t.datetime(columnNames="publishedAt");
        t.timestamp(columnNames="lastModified");
        t.time(columnNames="openingTime");
        t.binary(columnNames="data");
        t.uniqueidentifier(columnNames="uniqueId");
        
        // Special columns
        t.timestamps(); // Creates createdAt and updatedAt
        t.references(referenceNames="user"); // Creates userId foreign key
        
        // Create the table
        t.create();
    }
}
```

### Table Options

```cfc
function up() {
    transaction {
        t = createTable("products", 
            id=false, // Don't create auto-increment id
            force=true, // Drop if exists
            options="ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
        );
        
        // Composite primary key
        t.primaryKey(["orderId", "productId"]);
        
        t.create();
    }
}
```

### Dropping Tables

```cfc
function down() {
    transaction {
        dropTable("products");
    }
}
```

## Column Operations

### Adding Columns

```cfc
function up() {
    transaction {
        addColumn(
            table="users",
            column="phoneNumber",
            type="string",
            limit=20,
            allowNull=true
        );
        
        // Multiple columns
        t = changeTable("users");
        t.string(columnNames="address");
        t.string(columnNames="city");
        t.string(columnNames="postalCode", limit=10);
        t.update();
    }
}
```

### Modifying Columns

```cfc
function up() {
    transaction {
        changeColumn(
            table="products",
            column="price",
            type="decimal",
            precision=12,
            scale=2,
            allowNull=false,
            default=0
        );
    }
}
```

### Renaming Columns

```cfc
function up() {
    transaction {
        renameColumn(
            table="users",
            column="email_address",
            newName="email"
        );
    }
}
```

### Removing Columns

```cfc
function up() {
    transaction {
        removeColumn(table="users", column="deprecated_field");
        
        // Multiple columns
        t = changeTable("products");
        t.removeColumn("oldPrice");
        t.removeColumn("legacyCode");
        t.update();
    }
}
```

## Index Operations

### Creating Indexes

```cfc
function up() {
    transaction {
        // Simple index
        addIndex(table="users", columnNames="email");
        
        // Unique index
        addIndex(
            table="users",
            columnNames="username",
            unique=true
        );
        
        // Composite index
        addIndex(
            table="products",
            columnNames="category,status",
            name="idx_category_status"
        );
        
        // In table creation
        t = createTable("orders");
        t.string(columnNames="orderNumber");
        t.index("orderNumber", unique=true);
        t.create();
    }
}
```

### Removing Indexes

```cfc
function down() {
    transaction {
        removeIndex(table="users", name="idx_users_email");
        
        // Or by column
        removeIndex(table="products", column="sku");
    }
}
```

## Foreign Keys

### Adding Foreign Keys

```cfc
function up() {
    transaction {
        // Simple foreign key
        addForeignKey(
            table="orders",
            column="userId",
            referenceTable="users",
            referenceColumn="id"
        );
        
        // With options
        addForeignKey(
            table="orderItems",
            column="orderId",
            referenceTable="orders",
            referenceColumn="id",
            onDelete="CASCADE",
            onUpdate="CASCADE"
        );
        
        // In table creation
        t = createTable("posts");
        t.references(referenceNames="user", onDelete="SET NULL");
        t.references(referenceNames="category", foreignKey=true);
        t.create();
    }
}
```

### Removing Foreign Keys

```cfc
function down() {
    transaction {
        removeForeignKey(
            table="orders",
            name="fk_orders_users"
        );
    }
}
```

## Data Migrations

### Inserting Data

```cfc
function up() {
    transaction {
        // Single record
        sql("
            INSERT INTO roles (name, description, createdAt) 
            VALUES ('admin', 'Administrator', NOW())
        ");
        
        // Multiple records
        addRecord(table="permissions", name="users.create");
        addRecord(table="permissions", name="users.read");
        addRecord(table="permissions", name="users.update");
        addRecord(table="permissions", name="users.delete");
    }
}
```

### Updating Data

```cfc
function up() {
    transaction {
        updateRecord(
            table="products",
            where="status IS NULL",
            values={status: "active"}
        );
        
        // Complex updates
        sql("
            UPDATE users 
            SET fullName = CONCAT(firstName, ' ', lastName)
            WHERE fullName IS NULL
        ");
    }
}
```

### Removing Data

```cfc
function down() {
    transaction {
        removeRecord(
            table="roles",
            where="name = 'temp_role'"
        );
    }
}
```

## Advanced Migrations

### Conditional Migrations

```cfc
function up() {
    transaction {
        // Check if column exists
        if (!hasColumn("users", "avatar")) {
            addColumn(table="users", column="avatar", type="string");
        }
        
        // Check if table exists
        if (!hasTable("analytics")) {
            t = createTable("analytics");
            t.integer("views");
            t.timestamps();
            t.create();
        }
        
        // Database-specific
        if (getDatabaseType() == "mysql") {
            sql("ALTER TABLE users ENGINE=InnoDB");
        }
    }
}
```

### Using Raw SQL

```cfc
function up() {
    transaction {
        // Complex operations
        sql("
            CREATE VIEW active_products AS
            SELECT * FROM products
            WHERE active = 1 AND deletedAt IS NULL
        ");
        
        // Stored procedures
        sql("
            CREATE PROCEDURE CleanupOldData()
            BEGIN
                DELETE FROM logs WHERE createdAt < DATE_SUB(NOW(), INTERVAL 90 DAY);
            END
        ");
    }
}
```

### Environment-Specific

```cfc
function up() {
    transaction {
        // Always run
        addColumn(table="users", column="lastLoginAt", type="datetime");
        
        // Development only
        if (getEnvironment() == "development") {
            // Add test data
            for (var i = 1; i <= 100; i++) {
                addRecord(
                    table="users",
                    email="test#i#@example.com",
                    password="hashed_password"
                );
            }
        }
    }
}
```

## Running Migrations

### Basic Commands

```bash
# Check migration status
wheels dbmigrate info

# Run all pending migrations
wheels dbmigrate latest

# Run next migration only
wheels dbmigrate up

# Rollback last migration
wheels dbmigrate down

# Run specific version
wheels dbmigrate exec 20240125143022

# Reset all migrations
wheels dbmigrate reset
```

### Migration Workflow

1. **Create migration**
   ```bash
   wheels dbmigrate create table orders
   ```

2. **Edit migration file**
   ```cfc
   // Edit /app/migrator/migrations/[timestamp]_create_orders_table.cfc
   ```

3. **Test migration**
   ```bash
   # Run migration
   wheels dbmigrate latest
   
   # Verify
   wheels dbmigrate info
   
   # Test rollback
   wheels dbmigrate down
   ```

4. **Commit and share**
   ```bash
   git add db/migrate/
   git commit -m "Add orders table migration"
   ```

## Best Practices

### 1. Always Use Transactions

```cfc
function up() {
    transaction {
        // All operations in transaction
        // Rollback on any error
    }
}
```

### 2. Make Migrations Reversible

```cfc
function up() {
    transaction {
        addColumn(table="users", column="nickname", type="string");
    }
}

function down() {
    transaction {
        removeColumn(table="users", column="nickname");
    }
}
```

### 3. One Change Per Migration

```bash
# Good: Separate migrations
wheels dbmigrate create blank add_status_to_orders
wheels dbmigrate create blank add_priority_to_orders

# Bad: Multiple unrelated changes
wheels dbmigrate create blank update_orders_and_users
```

### 4. Test Migrations Thoroughly

```bash
# Test up
wheels dbmigrate latest

# Test down
wheels dbmigrate down

# Test up again
wheels dbmigrate up
```

### 5. Never Modify Completed Migrations

```bash
# Bad: Editing existing migration
# Good: Create new migration to fix issues
wheels dbmigrate create blank fix_orders_status_column
```

## Common Patterns

### Adding Non-Nullable Column

```cfc
function up() {
    transaction {
        // Add nullable first
        addColumn(table="users", column="role", type="string", allowNull=true);
        
        // Set default values
        updateRecord(table="users", where="1=1", values={role: "member"});
        
        // Make non-nullable
        changeColumn(table="users", column="role", allowNull=false);
    }
}
```

### Renaming Table with Foreign Keys

```cfc
function up() {
    transaction {
        // Drop foreign keys first
        removeForeignKey(table="posts", name="fk_posts_users");
        
        // Rename table
        renameTable(oldName="posts", newName="articles");
        
        // Recreate foreign keys
        addForeignKey(
            table="articles",
            column="userId",
            referenceTable="users",
            referenceColumn="id"
        );
    }
}
```

### Safe Column Removal

```cfc
function up() {
    transaction {
        // First migration: deprecate column
        if (getEnvironment() != "production") {
            announce("Column 'users.oldField' is deprecated and will be removed");
        }
    }
}

// Later migration (after code deployment)
function up() {
    transaction {
        removeColumn(table="users", column="oldField");
    }
}
```

## Troubleshooting

### Migration Failed

```bash
# Check error
wheels dbmigrate info

# Fix migration file
# Retry
wheels dbmigrate latest
```

### Stuck Migration

```sql
-- Manually fix schema_migrations table
DELETE FROM schema_migrations WHERE version = '20240125143022';
```

### Performance Issues

```cfc
function up() {
    // Increase timeout for large tables
    setting requestTimeout="300";
    
    transaction {
        // Add index without locking (MySQL)
        sql("ALTER TABLE large_table ADD INDEX idx_column (column)");
    }
}
```

## Integration with CI/CD

### Pre-deployment Check

```bash
#!/bin/bash
# Check for pending migrations
if wheels dbmigrate info | grep -q "pending"; then
    echo "⚠️  Pending migrations detected!"
    wheels dbmigrate info
    exit 1
fi
```

### Automated Deployment

```yaml
# .github/workflows/deploy.yml
- name: Run migrations
  run: |
    wheels dbmigrate latest
    wheels dbmigrate info
```

## See Also

- [wheels dbmigrate commands](../commands/database/dbmigrate-info.md) - Migration command reference
- [Database Schema](../commands/database/db-schema.md) - Schema import/export
- [Model Generation](../commands/generate/model.md) - Generate models with migrations
- [Testing Guide](testing.md) - Testing migrations