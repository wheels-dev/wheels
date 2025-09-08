# CLAUDE.md - Database Migrations

This file provides guidance to Claude Code (claude.ai/code) when working with Wheels database migrations.

## Overview

Database migrations in Wheels provide version control for your database schema. They allow you to:
- Track and apply schema changes over time
- Share database structure changes with your team
- Deploy schema updates safely to production
- Roll back changes if needed
- Keep database schema and application code in sync

## Migration File Structure

Migration files are stored in this directory (`/app/migrator/migrations/`) with timestamp-based naming:
```
[YYYYMMDDHHmmss]_[description].cfc
```

Example filenames:
```
20240125143022_create_users_table.cfc
20240125143523_add_email_to_users.cfc
20250131101530_add_indexes_to_products.cfc
```

## Basic Migration Template

Every migration extends `wheels.migrator.Migration` and must have `up()` and `down()` methods:

```cfc
component extends="wheels.migrator.Migration" hint="Description of what this migration does" {

    function up() {
        transaction {
            try {
                // Apply changes here
                // Example: createTable, addColumn, addIndex, etc.
            } catch (any e) {
                local.exception = e;
            }

            if (StructKeyExists(local, "exception")) {
                transaction action="rollback";
                throw(errorCode="1", detail=local.exception.detail, message=local.exception.message, type="any");
            } else {
                transaction action="commit";
            }
        }
    }

    function down() {
        transaction {
            try {
                // Reverse the changes from up() here
                // Example: dropTable, removeColumn, removeIndex, etc.
            } catch (any e) {
                local.exception = e;
            }

            if (StructKeyExists(local, "exception")) {
                transaction action="rollback";
                throw(errorCode="1", detail=local.exception.detail, message=local.exception.message, type="any");
            } else {
                transaction action="commit";
            }
        }
    }
}
```

## CLI Commands for Migrations

### Creating Migrations
```bash
# ALWAYS use CLI to generate migrations
wheels g migration MigrationName
wheels dbmigrate create blank description_of_change
wheels dbmigrate create table products
wheels dbmigrate create column users email
```

### Running Migrations
```bash
# Check migration status
wheels dbmigrate info

# Run all pending migrations (most common)
wheels dbmigrate latest

# Run next migration only
wheels dbmigrate up

# Rollback last migration
wheels dbmigrate down

# Run specific version
wheels dbmigrate exec 20240125143022

# Reset all migrations (DANGEROUS)
wheels dbmigrate reset
```

## Table Operations

### Creating Tables
```cfc
function up() {
    transaction {
        t = createTable("products");
        
        // Column types
        t.string(columnNames="name", limit=100, null=false);
        t.text(columnNames="description");
        t.text(columnNames="content", size="mediumtext"); // MySQL: 16MB
        t.text(columnNames="longDescription", size="longtext"); // MySQL: 4GB
        t.integer(columnNames="quantity", default=0);
        t.biginteger(columnNames="views", default=0);
        t.float(columnNames="weight");
        t.decimal(columnNames="price", precision=10, scale=2);
        t.boolean(columnNames="active", default=true);
        t.date(columnNames="releaseDate");
        t.datetime(columnNames="publishedAt");
        t.timestamp(columnNames="lastModified");
        t.time(columnNames="openingTime");
        t.binary(columnNames="data");
        t.uuid(columnNames="uniqueId");
        
        // Special columns
        t.timestamps(); // Creates createdAt, updatedAt, deletedAt
        t.references(columnNames="user"); // Creates userId foreign key
        
        t.create();
    }
}

function down() {
    transaction {
        dropTable("products");
    }
}
```

### Table Options
```cfc
function up() {
    transaction {
        // Table without auto-increment id
        t = createTable("user_roles", id=false);
        t.primaryKey(["userId", "roleId"]); // Composite primary key
        t.integer("userId", null=false);
        t.integer("roleId", null=false);
        t.create();
        
        // Table with custom options (MySQL)
        t = createTable("products", 
            force=true, // Drop if exists
            options="ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
        );
        t.string("name");
        t.create();
    }
}
```

## Column Operations

### Adding Columns
```cfc
function up() {
    transaction {
        // Single column
        addColumn(
            table="users",
            columnName="phoneNumber", 
            columnType="string",
            limit=20,
            null=true
        );
        
        // Multiple columns using changeTable
        t = changeTable("users");
        t.string(columnNames="address");
        t.string(columnNames="city", limit=100);
        t.string(columnNames="postalCode", limit=10);
        t.update();
    }
}

function down() {
    transaction {
        removeColumn(table="users", columnName="phoneNumber");
        
        t = changeTable("users");
        t.removeColumn(columnNames="address");
        t.removeColumn(columnNames="city");
        t.removeColumn(columnNames="postalCode");
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
            columnName="price",
            columnType="decimal",
            precision=12,
            scale=2,
            null=false,
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
            columnName="email_address",
            newColumnName="email"
        );
    }
}

function down() {
    transaction {
        renameColumn(
            table="users", 
            columnName="email",
            newColumnName="email_address"
        );
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
        addIndex(table="users", columnNames="username", unique=true);
        
        // Composite index
        addIndex(
            table="products",
            columnNames="category,status",
            indexName="idx_products_category_status"
        );
        
        // Index during table creation
        t = createTable("orders");
        t.string(columnNames="orderNumber");
        t.index(columnNames="orderNumber", unique=true);
        t.create();
    }
}

function down() {
    transaction {
        removeIndex(table="users", indexName="idx_users_email");
        removeIndex(table="products", indexName="products_sku");
    }
}
```

## Foreign Key Operations

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
        
        // With cascade options
        addForeignKey(
            table="orderItems",
            column="orderId", 
            referenceTable="orders",
            referenceColumn="id",
            onDelete="CASCADE",
            onUpdate="CASCADE"
        );
        
        // During table creation
        t = createTable("posts");
        t.references("user", onDelete="SET NULL");
        t.references("category", foreignKey=true);
        t.create();
    }
}

function down() {
    transaction {
        removeForeignKey(
            table="orders",
            name="fk_orders_users"
        );
    }
}
```

## Data Migration Operations

### Inserting Data
```cfc
function up() {
    transaction {
        // Using SQL
        sql("
            INSERT INTO roles (name, description, createdAt) 
            VALUES ('admin', 'Administrator', NOW())
        ");
        
        // Using helper method
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
        // Update with where clause
        updateRecord(
            table="products",
            where="status IS NULL",
            values={status: "active"}
        );
        
        // Complex update with SQL
        sql("
            UPDATE users 
            SET fullName = CONCAT(firstName, ' ', lastName)
            WHERE fullName IS NULL
        ");
    }
}
```

## Advanced Migration Patterns

### Conditional Operations
```cfc
function up() {
    transaction {
        // Check if column exists
        if (!hasColumn("users", "avatar")) {
            addColumn(table="users", columnName="avatar", columnType="string");
        }
        
        // Check if table exists  
        if (!hasTable("analytics")) {
            t = createTable("analytics");
            t.integer(columnNames="views");
            t.timestamps();
            t.create();
        }
        
        // Database-specific operations
        if (getDatabaseType() == "mysql") {
            sql("ALTER TABLE users ENGINE=InnoDB");
        }
    }
}
```

### Environment-Specific Migrations
```cfc
function up() {
    transaction {
        // Always run
        addColumn(table="users", columnName="lastLoginAt", columnType="datetime");
        
        // Development environment only
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

### Raw SQL Operations
```cfc
function up() {
    transaction {
        // Create view
        sql("
            CREATE VIEW active_products AS
            SELECT * FROM products
            WHERE active = 1 AND deletedAt IS NULL
        ");
        
        // Create stored procedure
        sql("
            CREATE PROCEDURE CleanupOldData()
            BEGIN
                DELETE FROM logs WHERE createdAt < DATE_SUB(NOW(), INTERVAL 90 DAY);
            END
        ");
    }
}
```

## Column Type Reference

### MySQL Types
- `biginteger` = BIGINT UNSIGNED
- `binary` = BLOB
- `boolean` = TINYINT (limit=1)
- `date` = DATE
- `datetime` = DATETIME
- `decimal` = DECIMAL
- `float` = FLOAT
- `integer` = INT
- `string` = VARCHAR (limit=255 default)
- `text` = TEXT
- `text(size="mediumtext")` = MEDIUMTEXT (16MB)
- `text(size="longtext")` = LONGTEXT (4GB)
- `time` = TIME
- `timestamp` = TIMESTAMP
- `uuid` = VARBINARY (limit=16)

### SQL Server Types
- `primaryKey` = "int NOT NULL IDENTITY (1, 1)"
- `binary` = IMAGE
- `boolean` = BIT
- `date` = DATETIME
- `datetime` = DATETIME
- `decimal` = DECIMAL
- `float` = FLOAT
- `integer` = INT
- `string` = VARCHAR (limit=255 default)
- `text` = TEXT
- `time` = DATETIME
- `timestamp` = DATETIME
- `uniqueidentifier` = UNIQUEIDENTIFIER
- `char` = CHAR (limit=10 default)

## Best Practices

### 1. Transaction Wrapper
Always wrap migration operations in transactions for atomicity:
```cfc
function up() {
    transaction {
        // All operations succeed or all fail
    }
}
```

### 2. Reversible Migrations
Always implement the down() method to reverse up() changes:
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
Keep migrations focused on a single logical change:
```bash
# Good: Separate migrations
wheels dbmigrate create blank add_status_to_orders
wheels dbmigrate create blank add_priority_to_orders

# Bad: Multiple unrelated changes
wheels dbmigrate create blank update_orders_and_users_and_products
```

### 4. Test Thoroughly
Test both up and down migrations:
```bash
# Test up
wheels dbmigrate latest

# Test down  
wheels dbmigrate down

# Test up again
wheels dbmigrate up
```

### 5. Never Modify Completed Migrations
Once a migration has been run in production, never edit it. Create a new migration instead:
```bash
# Bad: Editing existing migration
# Good: Create fix migration
wheels dbmigrate create blank fix_users_email_column
```

## Common Migration Patterns

### Adding Non-Nullable Column Safely
```cfc
function up() {
    transaction {
        // Add nullable first
        addColumn(table="users", columnName="role", columnType="string", null=true);
        
        // Set default values
        updateRecord(table="users", where="1=1", values={role: "member"});
        
        // Make non-nullable
        changeColumn(table="users", columnName="role", null=false);
    }
}
```

### Renaming Table with Foreign Keys
```cfc
function up() {
    transaction {
        // Drop foreign keys first
        removeForeignKey(table="posts", keyName="fk_posts_users");
        
        // Rename table
        renameTable(oldName="posts", newName="articles");
        
        // Recreate foreign keys
        addForeignKey(
            table="articles",
            columnName="userId",
            referenceTable="users", 
            referenceColumn="id"
        );
    }
}
```

### Performance for Large Tables
```cfc
function up() {
    // Increase timeout for large operations
    setting requestTimeout="300";
    
    transaction {
        // Use database-specific optimizations
        if (getDatabaseType() == "mysql") {
            sql("ALTER TABLE large_table ADD INDEX idx_column (column) ALGORITHM=INPLACE");
        } else {
            addIndex(table="large_table", columnNames="column");
        }
    }
}
```

## Production Migration Strategies

### 1. Manual Migration via GUI
- Put site in maintenance mode
- Access migration GUI: `?controller=wheels&action=wheels&view=migrate`
- Run migrations
- Return to production mode

### 2. Automatic Migration
Set in production settings:
```cfc
// config/production/settings.cfm
set(autoMigrateDatabase=true);
```

### 3. CLI Migration in Production
```bash
# Backup first
mysqldump myapp_production > backup_$(date +%Y%m%d_%H%M%S).sql

# Run migrations
wheels dbmigrate latest

# Verify
wheels dbmigrate info
```

## Configuration Options

Available in settings files:
- `autoMigrateDatabase` = false (auto-run on app start)
- `migratorTableName` = "c_o_r_e_migrator_versions"
- `createMigratorTable` = true
- `writeMigratorSQLFiles` = false (save SQL to files)
- `migratorObjectCase` = "lower" (database object case)
- `allowMigrationDown` = false (true in development)

## Troubleshooting

### Migration Failed
```bash
# Check error details
wheels dbmigrate info

# Fix migration file and retry
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
    // Increase timeout
    setting requestTimeout="600";
    
    transaction {
        // Use efficient operations
        sql("CREATE INDEX CONCURRENTLY idx_users_email ON users(email)");
    }
}
```

## Integration with Development Workflow

### With Git
```bash
# After creating migration
git add app/migrator/migrations/
git commit -m "Add user email column migration"

# Team members pull and run
git pull
wheels dbmigrate latest
```

### With CI/CD
```yaml
# .github/workflows/deploy.yml
- name: Run migrations
  run: |
    wheels dbmigrate latest
    wheels dbmigrate info
```

## Important Notes

- Migration files are executed in timestamp order
- Each migration runs in its own transaction
- Failed migrations can be retried after fixes
- Always backup production databases before migrations
- Test migrations in development and staging first
- Use descriptive names for migration files
- Keep migrations small and focused
- Document complex operations with comments

## Available Helper Methods in Migrations

**IMPORTANT: Argument Passing Rules**
- Helper functions require **either** all positional arguments **or** all named arguments
- **Cannot mix positional and named arguments** in the same function call
- Choose one style and use it consistently throughout your migration

### Table Methods
- `createTable(name, options)` - Create table
- `dropTable(name)` - Drop table  
- `renameTable(oldName, newName)` - Rename table
- `hasTable(name)` - Check if table exists

**Examples:**
```cfc
// Positional arguments (correct)
t = createTable("users");
dropTable("old_table");

// Named arguments (correct)
t = createTable(name="users", id=true);
dropTable(name="old_table");

// Mixed arguments (WRONG - will cause errors)
t = createTable("users", id=true); // Don't do this!
```

### Column Methods
- `addColumn(table, column, type, options)` - Add column
- `removeColumn(table, column)` - Remove column
- `changeColumn(table, column, type, options)` - Modify column
- `renameColumn(table, column, newName)` - Rename column
- `hasColumn(table, column)` - Check if column exists

**Examples:**
```cfc
// Positional arguments (correct)
addColumn("users", "email", "string", {limit: 255, null: false});
removeColumn("users", "old_field");

// Named arguments (correct)
addColumn(table="users", columnName="email", columnType="string", limit=255, null=false);
removeColumn(table="users", columnName="old_field");

// Mixed arguments (WRONG - will cause errors)
addColumn("users", columnName="email", columnType="string"); // Don't do this!
```

### Index Methods
- `addIndex(table, columnNames, options)` - Add index
- `removeIndex(table, indexName)` - Remove index

**Examples:**
```cfc
// Positional arguments (correct)
addIndex("users", "email", {unique: true});
removeIndex("users", "users_email");

// Named arguments (correct)
addIndex(table="users", columnNames="email", unique=true);
removeIndex(table="users", indexName="users_email");
```

### Foreign Key Methods
- `addForeignKey(table, columnName, referenceTable, referenceColumn, options)` - Add FK
- `removeForeignKey(table, keyName)` - Remove FK

**Examples:**
```cfc
// Positional arguments (correct)
addForeignKey("orders", "userId", "users", "id", {onDelete: "CASCADE"});
removeForeignKey("orders", "fk_orders_users");

// Named arguments (correct)
addForeignKey(
    table="orders",
    columnName="userId", 
    referenceTable="users",
    referenceColumn="id",
    onDelete="CASCADE"
);
removeForeignKey(table="orders", keyName="fk_orders_users");
```

### Data Methods
- `addRecord(table, fields)` - Insert record
- `updateRecord(table, where, values)` - Update records
- `removeRecord(table, where)` - Delete records

**Examples:**
```cfc
// Named arguments (recommended for data methods)
addRecord(table="users", email="test@example.com", name="Test User");
updateRecord(table="users", where="id = 1", values={email: "updated@example.com"});
removeRecord(table="users", where="email = 'test@example.com'");
```

### Utility Methods
- `sql(statement)` - Execute raw SQL
- `announce(message)` - Output message during migration
- `getDatabaseType()` - Get database engine type
- `getEnvironment()` - Get current environment

**Examples:**
```cfc
// Simple functions with positional arguments
sql("CREATE INDEX idx_users_email ON users(email)");
announce("Creating user indexes");

// Functions that return values
if (getDatabaseType() == "mysql") {
    // MySQL-specific logic
}

if (getEnvironment() == "development") {
    // Development-only operations
}
```