---
description: >-
  Learn how to use SQLite with CFWheels for lightweight, file-based database
  development and testing. Understand SQLite's capabilities, limitations, and
  best practices.
---

# Using SQLite with CFWheels

SQLite is a self-contained, serverless, zero-configuration, file-based SQL database engine. It's perfect for development, testing, and lightweight applications. CFWheels provides full support for SQLite with some important considerations to keep in mind.

## What is SQLite?

SQLite is different from traditional client-server databases like MySQL, PostgreSQL, or SQL Server:

- **File-Based**: The entire database is stored in a single file on disk
- **Zero Configuration**: No server setup or administration required
- **Lightweight**: Minimal memory footprint and fast performance
- **Cross-Platform**: Works identically on Windows, macOS, and Linux
- **ACID Compliant**: Supports transactions with full ACID properties

## When to Use SQLite

### ✅ Ideal Use Cases

- **Local Development**: Fast setup without running a database server
- **Automated Testing**: Clean, isolated test databases for each test run
- **Prototyping**: Quick proof-of-concept applications
- **Small Applications**: Desktop apps, mobile apps, or embedded systems
- **Read-Heavy Workloads**: Applications with more reads than writes

### ❌ Not Recommended For

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

SQLite has a unique type system. Wheels automatically maps CFML types to SQLite:

| Wheels Type | SQLite Type | Notes |
|-------------|-------------|-------|
| `string` | `TEXT` | Variable length text |
| `integer` | `INTEGER` | 64-bit signed integer |
| `float` | `REAL` | Floating point number |
| `decimal` | `NUMERIC` | Decimal with precision |
| `boolean` | `INTEGER` | 0 = false, 1 = true |
| `datetime` | `TEXT` | ISO 8601 format: `YYYY-MM-DD HH:MM:SS` |
| `date` | `TEXT` | ISO 8601 format: `YYYY-MM-DD` |
| `time` | `TEXT` | ISO 8601 format: `HH:MM:SS` |
| `blob` | `BLOB` | Binary data |

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

SQLite has limited `ALTER TABLE` support. You cannot:

- Add or remove foreign key constraints on existing tables
- Drop columns (prior to SQLite 3.35.0)
- Modify column types
- Add constraints to existing columns

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

Foreign keys must be enabled per connection in SQLite:

```javascript
// In Application.cfc or a global helper
function enableForeignKeys() {
    queryExecute("PRAGMA foreign_keys = ON", [], {datasource: "myapp"});
}
```

**Note**: Wheels automatically handles foreign key differences across databases, but you should be aware of this when writing raw SQL queries.

### Concurrent Writes

SQLite locks the entire database during write operations. For applications with high write concurrency:

- Use a dedicated database server (MySQL, PostgreSQL)
- Keep SQLite for development/testing only
- Use Write-Ahead Logging (WAL) mode for better concurrency:

```javascript
// Enable WAL mode
queryExecute("PRAGMA journal_mode=WAL", [], {datasource: "myapp"});
```

### Case Sensitivity

SQLite is case-insensitive for ASCII characters by default, but this can cause issues:

```javascript
// These might not match as expected
users = model("User").findAll(where="email = 'JOHN@EXAMPLE.COM'");

// Use COLLATE for explicit case handling
users = model("User").findAll(
    where="email = :email COLLATE NOCASE",
    email: "john@example.com"
);
```

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

Disable connection pooling for SQLite as it's file-based:

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
// ✅ Correct
user.createdAt = Now();
user.save();

// ❌ Incorrect (manual string formatting)
user.createdAt = DateFormat(Now(), "yyyy-mm-dd");
```

### Missing JDBC Driver

**Symptom**: `Unable to load class: org.sqlite.JDBC`

**Solution**: Download and install the SQLite JDBC driver (see Installation section above).

## Best Practices

### ✅ Do

- Use SQLite for development and testing
- Enable foreign keys per connection if using constraints
- Use migrations for schema changes
- Keep database files in your project's `db/` directory
- Add `*.db` to `.gitignore` to avoid committing database files
- Use WAL mode for better concurrency: `PRAGMA journal_mode=WAL`

### ❌ Don't

- Use SQLite for high-traffic production applications
- Store databases on network file systems (NFS/SMB)
- Keep long-running transactions open
- Rely on case-sensitive string comparisons
- Forget to back up your database files

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
# Export SQLite data to SQL
sqlite3 db/development.db .dump > dump.sql
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
- [CFWheels Database Interaction Guide](../database-interaction-through-models/)
- [CFWheels Migrations Guide](./database-migrations.md)

## Summary

SQLite is an excellent choice for CFWheels development and testing:

- **Zero configuration** makes it perfect for getting started quickly
- **File-based** nature simplifies deployment and backup
- **Full ORM support** works seamlessly with Wheels' ActiveRecord pattern
- **Limitations** are well-understood and can be worked around
- **Migration path** to production databases is straightforward

Use SQLite to accelerate your development workflow, and migrate to a client-server database when your application demands higher concurrency and scale.
