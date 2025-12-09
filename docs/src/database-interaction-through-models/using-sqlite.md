---
description: >-
  Learn how to use SQLite with Wheels for lightweight, file-based database
  development and testing. Understand SQLite's capabilities, limitations, and
  best practices.
---

# Using SQLite with Wheels

SQLite is a self-contained, serverless, zero-configuration, file-based SQL database engine. It's perfect for development, testing, and lightweight applications. Wheels provides full support for SQLite with some important considerations to keep in mind.

## What is SQLite?

SQLite is different from traditional client-server databases like MySQL, PostgreSQL, or SQL Server:

- **File-Based**: The entire database is stored in a single file on disk
- **Zero Configuration**: No server setup or administration required
- **Lightweight**: Minimal memory footprint and fast performance
- **Cross-Platform**: Works identically on Windows, macOS, and Linux
- **ACID Compliant**: Supports transactions with full ACID properties

## When to Use SQLite

### Ideal Use Cases

- **Local Development**: Fast setup without running a database server
- **Automated Testing**: Clean, isolated test databases for each test run
- **Prototyping**: Quick proof-of-concept applications
- **Small Applications**: Desktop apps, mobile apps, or embedded systems
- **Read-Heavy Workloads**: Applications with more reads than writes

### Not Recommended For

- **High-Concurrency Writes**: SQLite locks the entire database file during writes
- **Large-Scale Production**: Better options exist for high-traffic applications
- **Distributed Systems**: Not designed for multi-server architectures
- **Network File Systems**: Performance degrades significantly on NFS/SMB

## Setting Up SQLite

### Installation

SQLite support is built into most CFML engines, but you may need to add the JDBC driver:

#### Lucee

Lucee includes SQLite support by default. No additional installation needed.

#### Adobe ColdFusion

Download the SQLite JDBC driver from [GitHub](https://github.com/xerial/sqlite-jdbc/releases) and place it in your ColdFusion classpath:

```bash
# Copy the JAR to ColdFusion's lib directory
cp sqlite-jdbc-3.50.3.0.jar /path/to/coldfusion/lib/
```

Restart ColdFusion after adding the driver.

#### Boxlang

Download the SQLite module for Boxlang from [ForgeBox](https://forgebox.io/view/bx-sqlite) or simply list it as a dependency in your `box.json` file and then run `install` command to install all dependencies. Your box.json may look something like this:

```bash
{
  "dependencies" : {
    "wheels-core":"3.0.0-SNAPSHOT",
    "wirebox":"^7",
    "testbox":"^6",
    "bx-compat-cfml":"^1.27.0+35",
    "bx-csrf":"^1.2.0+3",
    "bx-esapi":"^1.6.0+9",
    "bx-image":"^1.0.1",
    "bx-wddx":"^1.5.0+8",
    "bx-sqlite":"^1.1.0+2"
  }
}
```

### Creating a Data Source

#### Using CFConfig (Recommended)

Create a `CFConfig.json` in your project root:

{% code title="CFConfig.json" %}
```json
{
  "datasources": {
    "myapp": {
      "class": "org.sqlite.JDBC",
      "connectionString": "jdbc:sqlite:db/myapp.db",
      "database": "db/myapp.db"
    }
  }
}
```
{% endcode %}

#### Using ColdFusion Administrator

1. Navigate to **Data & Services** > **Data Sources**
2. Add a new data source with these settings:
   - **Name**: `myapp`
   - **Driver**: Other (or SQLite if available)
   - **JDBC Class**: `org.sqlite.JDBC`
   - **JDBC URL**: `jdbc:sqlite:db/myapp.db`

### Wheels Configuration

Update your Wheels configuration to use SQLite:

{% code title="/config/settings.cfm" %}
```javascript
<cfscript>
set(dataSourceName = "myapp");
set(dataSourceUserName = "");  // SQLite doesn't use authentication
set(dataSourcePassword = "");
</cfscript>
```
{% endcode %}

## Working with SQLite in Wheels

### Basic Model Operations

SQLite works seamlessly with Wheels' ActiveRecord pattern:

{% code title="/app/models/User.cfc" %}
```javascript
component extends="Model" {
    function config() {
        // Associations work normally
        hasMany("posts");
        hasMany("comments");

        // Validations work normally
        validatesPresenceOf("email,username");
        validatesUniquenessOf("email");

        // Timestamps work automatically
        // SQLite stores datetime as TEXT in ISO 8601 format
    }
}
```
{% endcode %}

### Creating Records

```javascript
// In your controller
user = model("User").create({
    username: "john",
    email: "john@example.com",
    createdAt: Now(),  // Automatically converted to ISO 8601 text
    updatedAt: Now()
});
```

### Querying Records

All standard Wheels query methods work with SQLite:

```javascript
// Find all users
users = model("User").findAll(order="createdAt DESC");

// Find with conditions
activeUsers = model("User").findAll(where="active = 1");

// Find with associations
posts = model("Post").findAll(include="user,comments");

// Pagination
users = model("User").findAll(page=params.page, perPage=25);
```

## SQLite-Specific Considerations

### Data Types

SQLite uses a **dynamic type system** with type affinity rather than strict types. When you declare a column type, SQLite assigns a "type affinity" that suggests how values should be stored, but it doesn't enforce it strictly. Wheels automatically maps CFML types to SQLite storage classes:

| Wheels Type | SQLite Affinity | Stored As | Notes |
|-------------|-----------------|-----------|-------|
| `string` | `TEXT` | TEXT | Variable length text, UTF-8 |
| `integer` | `INTEGER` | INTEGER | 64-bit signed integer (up to 8 bytes) |
| `float` | `REAL` | REAL | 8-byte IEEE floating point |
| `decimal` | `REAL` | REAL | Can be INTEGER, REAL, or TEXT depending on value |
| `boolean` | `INTEGER` | INTEGER | 0 = false, 1 = true |
| `datetime` | `TEXT` | TEXT | ISO 8601 format: `YYYY-MM-DD HH:MM:SS` |
| `date` | `TEXT` | TEXT | ISO 8601 format: `YYYY-MM-DD` |
| `time` | `TEXT` | TEXT | ISO 8601 format: `HH:MM:SS` |
| `blob` | `BLOB` | BLOB | Binary data as-is |

**SQLite's Five Storage Classes**:
1. `NULL` - The value is a NULL value
2. `INTEGER` - Signed integer (1, 2, 3, 4, 6, or 8 bytes)
3. `REAL` - Floating point value (8-byte IEEE)
4. `TEXT` - Text string (UTF-8, UTF-16BE, or UTF-16LE)
5. `BLOB` - Blob of data, stored exactly as input

**Important**: SQLite does not have a native datetime type. Wheels stores datetime values as TEXT in ISO 8601 format for maximum compatibility and readability.

### DateTime Handling

Wheels automatically converts CFML datetime objects to ISO 8601 text format for SQLite:

```javascript
// This works automatically
user = model("User").new();
user.createdAt = Now();  // Stored as "2025-10-30 11:12:34"
user.save();

// Timestamps are set automatically
user = model("User").create({username: "john"});
// createdAt and updatedAt are automatically set as ISO 8601 text
```

### DateTime Handling in Migrations

SQLite does not support ColdFusion datetime literals (for example `{ts '2025-01-01 10:00:00'}` or any datetime expression generated by CFML functions). Instead, SQLite stores all datetime values using the TEXT datatype in ISO-8601 format.

Because of this, when working inside migrations, you must not pass any CFML datetime literal to SQLite, or it will throw an error.

`addRecord()` and `updateRecord()` Handling

Unlike `removeRecord()`, the `addRecord()` and `updateRecord()` migration functions can safely accept ColdFusion datetime literals.

If you pass a CFML datetime literal (e.g., now(), createDateTime(), {ts '...'}) into addRecord() or updateRecord(), the migration system automatically converts the value into a valid SQLite-friendly ISO-8601 text string before inserting or updating the record.

This means:

```javascript
addRecord(table = "products", data  = { createdAt = now() })

and

updateRecord(table = "products", data  = { updatedAt = createDateTime(2025,1,1,10,0,0) }, where = "id = 5")
```

will both work correctly.

#### removeRecord() Restrictions

removeRecord() does not convert datetime literals.
Therefore, you must never use CFML datetime expressions inside the where clause in removeRecord().

ColdFusion date/time functions (e.g. now(), dateAdd(), createDateTime()) generate CFML datetime literals which SQLite cannot understand.

SQLite expects datetime values to be plain quoted text strings.

Correct Usage in removeRecord()

If you need to match a datetime using removeRecord(), manually provide the value as text:

```javascript
removeRecord(table = "products", where = "time = '2025-12-08 10:30:00'")

Incorrect Usage (Will Fail):
removeRecord(table = "products", where = "time = #now()#")
```

ColdFusion expands now() into a datetime literal which SQLite cannot parse.

### Migrations

Create and run migrations normally:

```bash
# Generate a migration
wheels g migration CreateUsersTable

# Run migrations
wheels dbmigrate latest
```

{% code title="/app/migrator/migrations/20231030112345_create_users_table.cfc" %}
```javascript
component extends="wheels.migrator.Migration" {

    function up() {
        t = createTable("users");
        t.string("username", limit=50, null=false);
        t.string("email", limit=100, null=false);
        t.boolean("active", default=true);
        t.datetime("lastLoginAt");  // Stored as TEXT
        t.timestamps();  // Creates createdAt and updatedAt as TEXT
        t.create();

        // Indexes work normally
        addIndex(table="users", columnNames="email", unique=true);
    }

    function down() {
        dropTable("users");
    }
}
```
{% endcode %}

## Limitations and Workarounds

### ALTER TABLE Limitations

SQLite has limited `ALTER TABLE` support compared to other databases. The only operations directly supported are:

- **Rename table**: `ALTER TABLE old_name RENAME TO new_name`
- **Rename column**: `ALTER TABLE table RENAME COLUMN old_col TO new_col` (SQLite 3.25.0+)
- **Add column**: `ALTER TABLE table ADD COLUMN new_col TEXT` (with restrictions - cannot have UNIQUE, PRIMARY KEY, FOREIGN KEY, or CHECK constraints, and cannot be NOT NULL unless you provide a DEFAULT value)
- **Drop column**: `ALTER TABLE table DROP COLUMN col_name` (SQLite 3.35.0+ only)

You **cannot** directly:

- Add or remove foreign key constraints on existing tables
- Modify column types
- Add constraints (UNIQUE, CHECK, NOT NULL, etc.) to existing columns
- Change default values on existing columns

**Workaround**: Use the table recreation pattern in migrations:

```javascript
function up() {
    // Backup data
    execute("CREATE TABLE users_backup AS SELECT * FROM users");

    // Drop old table
    dropTable("users");

    // Create new table with changes
    t = createTable("users");
    t.string("username");
    t.string("email");
    t.string("newColumn");  // New column added
    t.create();

    // Restore data
    execute("INSERT INTO users (username, email) SELECT username, email FROM users_backup");
    dropTable("users_backup");
}
```

### Foreign Key Constraints

SQLite supports foreign keys, but they are **disabled by default** for backwards compatibility. You must enable them per connection:

```javascript
// In onrequeststart.cfm or before each query that relies on FK constraints
<cfscript>
    queryExecute("PRAGMA foreign_keys = ON", [], {datasource: "myapp"});
</cfscript>
```

**Important Notes**:
- `PRAGMA foreign_keys` must be set on **each new database connection**. It does not persist.
- If using connection pooling, you may need to disable it or ensure the PRAGMA is set for each connection.
- Foreign key constraints are checked only when `PRAGMA foreign_keys = ON` is active.
- Wheels automatically handles foreign key differences across databases, but you should be aware of this when writing raw SQL queries or relying on CASCADE behavior.

### Concurrent Writes

SQLite uses table-level locking during write operations in rollback journal mode. Only one write transaction can be active at a time, which can limit performance when multiple writes occur simultaneously. This behavior makes it less suitable for applications with high write concurrency.

If your application performs frequent concurrent writes, consider the following options:

- Use a dedicated database server such as MySQL or PostgreSQL for production environments.
- Reserve SQLite for development or testing, where simplicity and portability matter more than concurrency.
- Enable Write-Ahead Logging (WAL) mode to improve concurrency and allow simultaneous reads and writes:

```javascript
// Enable WAL mode for better concurrent access
queryExecute("PRAGMA journal_mode = WAL", [], { datasource: "myapp" });
```

**Note about WAL mode**: Write-Ahead Logging (WAL) mode allows multiple readers to operate concurrently with a single writer by logging changes to a separate `-wal` file. Readers see a consistent snapshot while writes are being made. WAL mode is persistent per database file and significantly improves concurrency, but it creates additional files (`-wal` and `-shm`) alongside your database file.

### Case Sensitivity

SQLite's default collation (`BINARY`) is **case-sensitive** for text comparisons. However, the `LIKE` operator is case-insensitive for ASCII characters by default:

```javascript
// Case-sensitive comparison with = operator
users = model("User").findAll(where="email = 'john@example.com'");
// This will NOT match 'JOHN@EXAMPLE.COM'

// Case-insensitive comparison using LIKE
users = model("User").findAll(where="email LIKE 'john@example.com'");
// This WILL match 'JOHN@EXAMPLE.COM'

// Explicit case-insensitive comparison using COLLATE NOCASE
users = model("User").findAll(where="email = 'john@example.com' COLLATE NOCASE");
// This WILL match 'JOHN@EXAMPLE.COM'

// Or define COLLATE at column level in migration
t.string("email", collate="NOCASE");
```

**Recommendation**: Define collation at the column level in your migrations for consistent behavior.

## Testing with SQLite

SQLite is excellent for automated testing:

### In-Memory Databases

Use in-memory databases for ultra-fast tests:

{% code title="/config/test/settings.cfm" %}
```javascript
<cfscript>
// Use in-memory database for tests
set(dataSourceName = "test_db");

// Configure in CFConfig.json:
// "connectionString": "jdbc:sqlite::memory:"
</cfscript>
```
{% endcode %}

### Per-Test Isolation

Create a new database file for each test for complete isolation:

```javascript
component extends="wheels.Test" {

    function setup() {
        // Create unique DB for this test
        variables.testDB = "test_" & CreateUUID() & ".db";
        application.wheels.dataSourceName = variables.testDB;

        // Run migrations
        runMigrations();
    }

    function teardown() {
        // Clean up test database
        if (FileExists(variables.testDB)) {
            FileDelete(variables.testDB);
        }
    }
}
```

## Performance Optimization

### Indexes

Create indexes for frequently queried columns:

```javascript
// In migrations
addIndex(table="users", columnNames="email");
addIndex(table="posts", columnNames="userId,createdAt");

// Or in models
function config() {
    // Wheels doesn't auto-create indexes, define in migrations
}
```

### Analyze and Optimize

Run SQLite's ANALYZE command periodically:

```javascript
// Update query planner statistics
queryExecute("ANALYZE", [], {datasource: "myapp"});
```

### Connection Pooling

For SQLite, connection pooling behavior depends on your CFML engine and use case:

**For single-user applications** (development, testing):
- Disable pooling and use a single connection to avoid locking issues

**For multi-threaded applications**:
- Limited connection pool may be beneficial with WAL mode enabled
- Without WAL mode, multiple connections can cause SQLITE_BUSY errors

{% code title="CFConfig.json" %}
```json
{
  "datasources": {
    "myapp": {
      "class": "org.sqlite.JDBC",
      "connectionString": "jdbc:sqlite:db/myapp.db",
      "maxConnections": 1,
      "pooled": false
    }
  }
}
```
{% endcode %}

If using WAL mode for better concurrency:

```json
{
  "datasources": {
    "myapp": {
      "class": "org.sqlite.JDBC",
      "connectionString": "jdbc:sqlite:db/myapp.db?journal_mode=WAL",
      "maxConnections": 5,
      "pooled": true
    }
  }
}
```

## Troubleshooting

### Database is Locked Error

**Symptom**: `[SQLITE_ERROR] A table in the database is locked`

**Causes**:
- Multiple connections trying to write simultaneously
- Long-running transactions
- Metadata queries interfering with DDL operations

**Solutions**:
1. Ensure only one write operation at a time
2. Use shorter transactions
3. Increase busy timeout:

```javascript
queryExecute("PRAGMA busy_timeout = 10000", [], {datasource: "myapp"});
```

### Datetime Format Issues

**Symptom**: Datetime values not saving or comparing correctly

**Solution**: Wheels automatically handles datetime conversion. Ensure you're using Wheels' datetime functions:

```javascript
// Correct
user.createdAt = Now();
user.save();

// Incorrect (manual string formatting)
user.createdAt = DateFormat(Now(), "yyyy-mm-dd");
```

### Missing JDBC Driver

**Symptom**: `Unable to load class: org.sqlite.JDBC`

**Solution**: Download and install the SQLite JDBC driver (see Installation section above).

## Best Practices

### Do

- Use SQLite for development and testing environments
- Enable foreign keys per connection if using constraints: `PRAGMA foreign_keys = ON`
- Use migrations for schema changes rather than manual ALTER TABLE commands
- Keep database files in your project's `db/` directory (not in web root)
- Add `*.db`, `*.db-journal`, `*.db-wal`, `*.db-shm` to `.gitignore`
- Enable WAL mode for applications with concurrent reads: `PRAGMA journal_mode=WAL`
- Set busy timeout to handle temporary locks: `PRAGMA busy_timeout=10000`
- Use indexes on frequently queried columns for better performance
- Use transactions for bulk operations to improve performance
- Run `VACUUM` periodically to reclaim unused space and defragment
- Run `ANALYZE` after significant data changes to update query planner statistics

### Don't

- Use SQLite for high-concurrency write applications
- Store databases on network file systems (NFS/SMB/CIFS) - this can cause corruption
- Keep long-running transactions open - this blocks other writers
- Assume column types are strictly enforced - SQLite uses type affinity
- Forget to enable foreign keys if your schema relies on them
- Forget to back up your database files regularly
- Use `DELETE` on large tables without `VACUUM` - space won't be reclaimed
- Assume case-insensitive comparisons work like other databases - they don't by default

## Example Application Structure

```
myapp/
├── db/
│   ├── development.db          # Development database
│   └── test.db                # Test database (auto-created)
├── app/
│   ├── models/
│   │   └── User.cfc
│   └── migrator/
│       └── migrations/
│           └── 20231030_create_users.cfc
├── config/
│   ├── settings.cfm
│   ├── development/
│   │   └── settings.cfm
│   └── test/
│       └── settings.cfm
├── CFConfig.json
└── .gitignore                  # Add *.db here
```

{% code title=".gitignore" %}
```
# Ignore SQLite database files
db/*.db
db/*.db-journal
db/*.db-wal
db/*.db-shm

# Keep directory structure
!db/.gitkeep
```
{% endcode %}

## Migration from SQLite to Production Database

When moving to production, you'll typically migrate from SQLite to a more robust database:

### 1. Update Configuration

{% code title="/config/production/settings.cfm" %}
```javascript
<cfscript>
set(dataSourceName = "myapp_production");
set(dataSourceUserName = "dbuser");
set(dataSourcePassword = "dbpassword");
</cfscript>
```
{% endcode %}

### 2. Export Data

```bash
# Export SQLite data to SQL (full schema and data)
sqlite3 db/development.db .dump > dump.sql

# Export only data (no schema)
sqlite3 db/development.db "SELECT * FROM sqlite_master WHERE type='table'" | \
  sqlite3 db/development.db .dump | grep "^INSERT" > data.sql

# Export specific tables
sqlite3 db/development.db "SELECT sql FROM sqlite_master WHERE name='users'" > schema.sql
sqlite3 db/development.db ".mode insert users" "SELECT * FROM users" >> data.sql
```

### 3. Import to New Database

```bash
# For MySQL
mysql -u dbuser -p myapp_production < dump.sql

# For PostgreSQL
psql -U dbuser -d myapp_production -f dump.sql
```

### 4. Test Thoroughly

Ensure all queries work correctly with the new database adapter. Watch for:
- SQL dialect differences
- Date/time format differences
- Case sensitivity differences
- Transaction behavior differences

## Additional Resources

- [SQLite Official Documentation](https://www.sqlite.org/docs.html)
- [SQLite JDBC Driver](https://github.com/xerial/sqlite-jdbc)
- [Wheels Database Interaction Guide](../database-interaction-through-models/)
- [Wheels Migrations Guide](./database-migrations.md)

## Summary

SQLite is an excellent choice for Wheels development and testing:

- **Zero configuration** makes it perfect for getting started quickly
- **File-based** nature simplifies deployment and backup
- **Full ORM support** works seamlessly with Wheels' ActiveRecord pattern
- **Limitations** are well-understood and can be worked around
- **Migration path** to production databases is straightforward

Use SQLite to accelerate your development workflow, and migrate to a client-server database when your application demands higher concurrency and scale.
