# Advanced Migration Operations

## Description
Advanced database migration operations for complex schema changes, data manipulation, and custom SQL execution in Wheels migrations.

## Key Points
- Use `removeTable()` to drop entire tables
- Use `renameTable()` to rename existing tables
- Use `execute()` to run custom SQL commands
- Support for views, triggers, and stored procedures
- Data migration and transformation operations
- Batch operations for large datasets

## Code Sample
```cfm
component extends="wheels.migrator.Migration" {

    function up() {
        transaction {
            // Remove table completely
            removeTable("old_user_sessions");

            // Rename table
            renameTable(oldName="users", newName="customers");

            // Add new table with foreign key
            t = createTable(name="customer_profiles");
            t.integer(columnNames="customerId", allowNull=false);
            t.text(columnNames="biography");
            t.string(columnNames="website", limit=255);
            t.timestamps();
            t.create();

            // Add foreign key constraint
            addForeignKey(
                table="customer_profiles",
                column="customerId",
                referencedTable="customers",
                referencedColumn="id",
                onDelete="CASCADE"
            );

            // Execute custom SQL for data migration
            execute("
                INSERT INTO customer_profiles (customerId, biography, website, createdAt, updatedAt)
                SELECT id, bio, website_url, createdAt, updatedAt
                FROM legacy_profiles
                WHERE bio IS NOT NULL
            ");

            // Create database view
            execute("
                CREATE VIEW active_customers AS
                SELECT c.*, cp.biography, cp.website
                FROM customers c
                LEFT JOIN customer_profiles cp ON c.id = cp.customerId
                WHERE c.active = 1 AND c.deletedAt IS NULL
            ");

            // Create index on view (database-specific)
            execute("CREATE INDEX idx_active_customers_email ON customers(email) WHERE active = 1");

            // Add check constraint
            execute("
                ALTER TABLE customers
                ADD CONSTRAINT chk_email_format
                CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
            ");
        }
    }

    function down() {
        transaction {
            // Reverse operations in opposite order
            execute("ALTER TABLE customers DROP CONSTRAINT IF EXISTS chk_email_format");
            execute("DROP INDEX IF EXISTS idx_active_customers_email");
            execute("DROP VIEW IF EXISTS active_customers");

            removeForeignKey(
                table="customer_profiles",
                keyName="fk_customer_profiles_customerId"
            );

            removeTable("customer_profiles");
            renameTable(oldName="customers", newName="users");

            // Recreate original table if needed
            t = createTable(name="old_user_sessions");
            t.integer(columnNames="userId", allowNull=false);
            t.string(columnNames="sessionId", limit=128, allowNull=false);
            t.datetime(columnNames="expiresAt");
            t.timestamps();
            t.create();
        }
    }
}

// Data migration example
component extends="wheels.migrator.Migration" {

    function up() {
        transaction {
            // Add new column
            addColumn(table="users", columnType="string", columnName="fullName", limit=255);

            // Populate new column from existing data
            execute("
                UPDATE users
                SET fullName = TRIM(firstName || ' ' || lastName)
                WHERE firstName IS NOT NULL AND lastName IS NOT NULL
            ");

            // Remove old columns after data migration
            removeColumn(table="users", columnName="firstName");
            removeColumn(table="users", columnName="lastName");
        }
    }

    function down() {
        transaction {
            // Add back original columns
            addColumn(table="users", columnType="string", columnName="firstName", limit=100);
            addColumn(table="users", columnType="string", columnName="lastName", limit=100);

            // Split fullName back into components
            execute("
                UPDATE users
                SET firstName = SPLIT_PART(fullName, ' ', 1),
                    lastName = CASE
                        WHEN ARRAY_LENGTH(STRING_TO_ARRAY(fullName, ' '), 1) > 1
                        THEN SUBSTRING(fullName FROM LENGTH(SPLIT_PART(fullName, ' ', 1)) + 2)
                        ELSE NULL
                    END
                WHERE fullName IS NOT NULL
            ");

            // Remove the fullName column
            removeColumn(table="users", columnName="fullName");
        }
    }
}

// Complex schema changes
component extends="wheels.migrator.Migration" {

    function up() {
        transaction {
            // Create lookup table
            t = createTable(name="user_roles");
            t.string(columnNames="name", limit=50, allowNull=false);
            t.string(columnNames="description", limit=255);
            t.timestamps();
            t.create();

            addIndex(table="user_roles", columnNames="name", unique=true);

            // Seed lookup table
            execute("
                INSERT INTO user_roles (name, description, createdAt, updatedAt) VALUES
                ('admin', 'System Administrator', NOW(), NOW()),
                ('editor', 'Content Editor', NOW(), NOW()),
                ('user', 'Regular User', NOW(), NOW())
            ");

            // Add role foreign key to users
            addColumn(table="users", columnType="integer", columnName="roleId", allowNull=true);

            // Set default role for existing users
            execute("
                UPDATE users
                SET roleId = (SELECT id FROM user_roles WHERE name = 'user')
                WHERE roleId IS NULL
            ");

            // Make role required
            changeColumn(table="users", columnName="roleId", columnType="integer", allowNull=false);

            // Add foreign key constraint
            addForeignKey(
                table="users",
                column="roleId",
                referencedTable="user_roles",
                referencedColumn="id"
            );

            // Create function for role checking (PostgreSQL example)
            execute("
                CREATE OR REPLACE FUNCTION user_has_role(user_id INTEGER, role_name TEXT)
                RETURNS BOOLEAN AS $$
                BEGIN
                    RETURN EXISTS(
                        SELECT 1
                        FROM users u
                        JOIN user_roles r ON u.roleId = r.id
                        WHERE u.id = user_id AND r.name = role_name
                    );
                END;
                $$ LANGUAGE plpgsql;
            ");
        }
    }

    function down() {
        transaction {
            execute("DROP FUNCTION IF EXISTS user_has_role(INTEGER, TEXT)");

            removeForeignKey(table="users", keyName="fk_users_roleId");
            removeColumn(table="users", columnName="roleId");
            removeTable("user_roles");
        }
    }
}

// Performance optimization migration
component extends="wheels.migrator.Migration" {

    function up() {
        transaction {
            // Add optimized indexes
            addIndex(table="orders", columnNames="customerId,status,createdAt");
            addIndex(table="order_items", columnNames="orderId,productId");

            // Create materialized view for reporting (PostgreSQL)
            execute("
                CREATE MATERIALIZED VIEW daily_sales AS
                SELECT
                    DATE(o.createdAt) as sale_date,
                    COUNT(*) as order_count,
                    SUM(oi.quantity * oi.price) as total_sales,
                    COUNT(DISTINCT o.customerId) as unique_customers
                FROM orders o
                JOIN order_items oi ON o.id = oi.orderId
                WHERE o.status = 'completed'
                GROUP BY DATE(o.createdAt)
                ORDER BY sale_date DESC
            ");

            // Create index on materialized view
            execute("CREATE UNIQUE INDEX idx_daily_sales_date ON daily_sales(sale_date)");

            // Add trigger to refresh materialized view (PostgreSQL)
            execute("
                CREATE OR REPLACE FUNCTION refresh_daily_sales()
                RETURNS TRIGGER AS $$
                BEGIN
                    REFRESH MATERIALIZED VIEW CONCURRENTLY daily_sales;
                    RETURN NULL;
                END;
                $$ LANGUAGE plpgsql;
            ");

            execute("
                CREATE TRIGGER trigger_refresh_daily_sales
                AFTER INSERT OR UPDATE OR DELETE ON orders
                FOR EACH STATEMENT
                EXECUTE FUNCTION refresh_daily_sales();
            ");

            // Archive old data
            t = createTable(name="orders_archive");
            t.integer(columnNames="originalId", allowNull=false);
            t.integer(columnNames="customerId", allowNull=false);
            t.string(columnNames="status", limit=50);
            t.decimal(columnNames="totalAmount", precision=10, scale=2);
            t.datetime(columnNames="originalCreatedAt");
            t.datetime(columnNames="archivedAt", default="NOW()");
            t.create();

            // Move old orders to archive
            execute("
                INSERT INTO orders_archive (originalId, customerId, status, totalAmount, originalCreatedAt)
                SELECT id, customerId, status, totalAmount, createdAt
                FROM orders
                WHERE createdAt < DATE('now', '-2 years')
            ");

            // Remove archived orders from main table
            execute("DELETE FROM orders WHERE createdAt < DATE('now', '-2 years')");
        }
    }

    function down() {
        transaction {
            execute("DROP TRIGGER IF EXISTS trigger_refresh_daily_sales ON orders");
            execute("DROP FUNCTION IF EXISTS refresh_daily_sales()");
            execute("DROP MATERIALIZED VIEW IF EXISTS daily_sales");

            removeIndex(table="orders", indexName="idx_orders_customerId_status_createdAt");
            removeIndex(table="order_items", indexName="idx_order_items_orderId_productId");

            removeTable("orders_archive");
        }
    }
}
```

## Usage
1. Use `removeTable(tableName)` to drop complete tables
2. Use `renameTable(oldName, newName)` to rename tables
3. Use `execute(sql)` for custom SQL commands
4. Always wrap operations in transactions
5. Test both up and down operations thoroughly

## Advanced Operations
- **`removeTable(name)`** - Drops a table completely
- **`renameTable(oldName, newName)`** - Renames an existing table
- **`execute(sql)`** - Executes raw SQL commands
- **`addForeignKey()`** - Adds foreign key constraints
- **`removeForeignKey()`** - Removes foreign key constraints
- **`changeColumn()`** - Modifies existing column properties

## Related
- [Creating Migrations](./creating-migrations.md)
- [Column Types](./column-types.md)
- [Running Migrations](./running-migrations.md)

## Important Notes
- Always test migrations on development data first
- Use transactions to ensure atomicity
- Consider performance impact of large data migrations
- Database-specific SQL may not be portable
- Backup data before running destructive operations
- Test rollback scenarios thoroughly

## Best Practices

### Data Migration Safety
```cfm
function up() {
    transaction {
        // Create backup before major changes
        execute("CREATE TABLE users_backup AS SELECT * FROM users");

        // Perform migration
        // ... migration code ...

        // Verify migration success
        local.originalCount = queryExecute("SELECT COUNT(*) as cnt FROM users_backup").cnt;
        local.newCount = queryExecute("SELECT COUNT(*) as cnt FROM users").cnt;

        if (local.originalCount != local.newCount) {
            throw("Data migration failed: record count mismatch");
        }

        // Drop backup on success
        execute("DROP TABLE users_backup");
    }
}
```

### Conditional Operations
```cfm
function up() {
    // Check if table exists before dropping
    if (tableExists("legacy_table")) {
        removeTable("legacy_table");
    }

    // Check if column exists before adding
    if (!columnExists("users", "email_verified")) {
        addColumn(table="users", columnType="boolean", columnName="email_verified", default=false);
    }
}

private function tableExists(required string tableName) {
    local.result = queryExecute("
        SELECT COUNT(*) as cnt
        FROM information_schema.tables
        WHERE table_name = ?
    ", [arguments.tableName]);

    return local.result.cnt > 0;
}
```

### Batch Processing
```cfm
function up() {
    // Process large datasets in batches
    local.batchSize = 1000;
    local.offset = 0;

    do {
        local.processed = queryExecute("
            UPDATE users
            SET normalized_email = LOWER(email)
            WHERE id IN (
                SELECT id FROM users
                WHERE normalized_email IS NULL
                ORDER BY id
                LIMIT ?
                OFFSET ?
            )
        ", [local.batchSize, local.offset]);

        local.offset += local.batchSize;
    } while (local.processed.recordCount > 0);
}
```

## Security Considerations
- Validate all user input in custom SQL
- Use parameterized queries when possible
- Avoid concatenating user data directly into SQL
- Be cautious with `execute()` - it bypasses Wheels' SQL injection protection
- Review custom SQL for potential vulnerabilities
- Test migrations with malicious data scenarios