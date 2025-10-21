---
name: Wheels Migration Generator
description: Generate database-agnostic Wheels migrations for creating tables, altering schemas, and managing database changes. Use when creating or modifying database schema, adding tables, columns, indexes, or foreign keys. Prevents database-specific SQL and ensures cross-database compatibility.
---

# Wheels Migration Generator

## When to Use This Skill

Activate automatically when:
- User requests to create a migration (e.g., "create posts table")
- User wants to add/modify/remove columns
- User needs to add indexes or foreign keys
- User is changing database schema
- User mentions: migration, database, table, column, index, schema

## Critical Anti-Pattern to Prevent

### ❌ ANTI-PATTERN: Database-Specific Date Functions

**NEVER use database-specific functions like DATE_SUB(), NOW(), CURDATE()!**

**WRONG:**
```cfm
execute("INSERT INTO posts (publishedAt) VALUES (DATE_SUB(NOW(), INTERVAL 1 DAY))");  ❌ MySQL only!
```

**CORRECT:**
```cfm
var pastDate = DateAdd("d", -1, Now());
execute("INSERT INTO posts (publishedAt) VALUES (TIMESTAMP '#DateFormat(pastDate, "yyyy-mm-dd")# #TimeFormat(pastDate, "HH:mm:ss")#')");  ✅ Cross-database!
```

## Migration Structure

### Basic Migration Template

```cfm
component extends="wheels.migrator.Migration" {

    function up() {
        transaction {
            try {
                // Your migration code here

            } catch (any e) {
                local.exception = e;
            }

            if (StructKeyExists(local, "exception")) {
                transaction action="rollback";
                Throw(
                    errorCode="1",
                    detail=local.exception.detail,
                    message=local.exception.message,
                    type="any"
                );
            } else {
                transaction action="commit";
            }
        }
    }

    function down() {
        // Rollback code here
    }
}
```

## Create Table Migration

```cfm
component extends="wheels.migrator.Migration" {

    function up() {
        transaction {
            try {
                // Create table
                t = createTable(name="posts", force=false);

                // String columns
                t.string(columnNames="title", allowNull=false, limit=200);
                t.string(columnNames="slug", allowNull=false, limit=200);

                // Text columns
                t.text(columnNames="content", allowNull=false);
                t.text(columnNames="excerpt", allowNull=true);

                // Integer columns
                t.integer(columnNames="viewCount", default=0);
                t.integer(columnNames="userId", allowNull=false);

                // Boolean columns
                t.boolean(columnNames="published", default=false);

                // DateTime columns
                t.datetime(columnNames="publishedAt", allowNull=true);

                // Timestamps (createdAt, updatedAt)
                t.timestamps();

                // Create the table
                t.create();

                // Add indexes
                addIndex(table="posts", columnNames="slug", unique=true);
                addIndex(table="posts", columnNames="userId");
                addIndex(table="posts", columnNames="published,publishedAt");

                // Add foreign key
                addForeignKey(
                    table="posts",
                    referenceTable="users",
                    column="userId",
                    referenceColumn="id",
                    onDelete="cascade"
                );

            } catch (any e) {
                local.exception = e;
            }

            if (StructKeyExists(local, "exception")) {
                transaction action="rollback";
                Throw(
                    errorCode="1",
                    detail=local.exception.detail,
                    message=local.exception.message,
                    type="any"
                );
            } else {
                transaction action="commit";
            }
        }
    }

    function down() {
        dropTable("posts");
    }
}
```

## Alter Table Migration

```cfm
component extends="wheels.migrator.Migration" {

    function up() {
        transaction {
            try {
                // Add column
                addColumn(
                    table="posts",
                    columnType="string",
                    columnName="metaDescription",
                    limit=300,
                    allowNull=true
                );

                // Change column
                changeColumn(
                    table="posts",
                    columnName="title",
                    columnType="string",
                    limit=255,  // Changed from 200
                    allowNull=false
                );

                // Rename column
                renameColumn(
                    table="posts",
                    oldColumnName="summary",
                    newColumnName="excerpt"
                );

                // Remove column
                removeColumn(table="posts", columnName="oldField");

                // Add index
                addIndex(table="posts", columnNames="metaDescription");

            } catch (any e) {
                local.exception = e;
            }

            if (StructKeyExists(local, "exception")) {
                transaction action="rollback";
                Throw(
                    errorCode="1",
                    detail=local.exception.detail,
                    message=local.exception.message,
                    type="any"
                );
            } else {
                transaction action="commit";
            }
        }
    }

    function down() {
        removeColumn(table="posts", columnName="metaDescription");
        // Reverse other changes...
    }
}
```

## Data Migration (Seed Data)

### Database-Agnostic Date Formatting

```cfm
component extends="wheels.migrator.Migration" {

    function up() {
        transaction {
            try {
                // CORRECT: Use CFML date functions
                var now = Now();
                var day1 = DateAdd("d", -7, now);
                var day2 = DateAdd("d", -6, now);
                var day3 = DateAdd("d", -5, now);

                // Format dates for SQL
                var nowFormatted = "TIMESTAMP '#DateFormat(now, "yyyy-mm-dd")# #TimeFormat(now, "HH:mm:ss")#'";
                var day1Formatted = "TIMESTAMP '#DateFormat(day1, "yyyy-mm-dd")# #TimeFormat(day1, "HH:mm:ss")#'";
                var day2Formatted = "TIMESTAMP '#DateFormat(day2, "yyyy-mm-dd")# #TimeFormat(day2, "HH:mm:ss")#'";

                // Insert data
                execute("
                    INSERT INTO posts (title, slug, content, published, publishedAt, createdAt, updatedAt)
                    VALUES (
                        'Getting Started with HTMX',
                        'getting-started-with-htmx',
                        '<p>HTMX is a modern approach to building web applications...</p>',
                        1,
                        #day1Formatted#,
                        #day1Formatted#,
                        #day1Formatted#
                    )
                ");

                execute("
                    INSERT INTO posts (title, slug, content, published, publishedAt, createdAt, updatedAt)
                    VALUES (
                        'Tailwind CSS Best Practices',
                        'tailwind-css-best-practices',
                        '<p>Tailwind provides utility-first CSS...</p>',
                        1,
                        #day2Formatted#,
                        #day2Formatted#,
                        #day2Formatted#
                    )
                ");

            } catch (any e) {
                local.exception = e;
            }

            if (StructKeyExists(local, "exception")) {
                transaction action="rollback";
                Throw(
                    errorCode="1",
                    detail=local.exception.detail,
                    message=local.exception.message,
                    type="any"
                );
            } else {
                transaction action="commit";
            }
        }
    }

    function down() {
        execute("DELETE FROM posts WHERE slug IN ('getting-started-with-htmx', 'tailwind-css-best-practices')");
    }
}
```

## Column Types

### Available Column Types

```cfm
// String (VARCHAR)
t.string(columnNames="name", limit=255, allowNull=false, default="");

// Text (TEXT/CLOB)
t.text(columnNames="description", allowNull=true);

// Integer
t.integer(columnNames="count", default=0, allowNull=false);

// Big Integer
t.biginteger(columnNames="largeNumber");

// Float
t.float(columnNames="rating", default=0.0);

// Decimal
t.decimal(columnNames="price", precision=10, scale=2);

// Boolean
t.boolean(columnNames="active", default=true);

// Date
t.date(columnNames="birthDate");

// DateTime
t.datetime(columnNames="publishedAt");

// Time
t.time(columnNames="startTime");

// Binary
t.binary(columnNames="fileData");

// UUID
t.string(columnNames="uuid", limit=36);

// Timestamps (adds createdAt and updatedAt)
t.timestamps();
```

## Index Management

```cfm
// Simple index
addIndex(table="posts", columnNames="title");

// Unique index
addIndex(table="posts", columnNames="slug", unique=true);

// Composite index
addIndex(table="posts", columnNames="published,publishedAt");

// Remove index
removeIndex(table="posts", indexName="idx_posts_title");
```

## Foreign Key Management

```cfm
// Add foreign key
addForeignKey(
    table="posts",
    referenceTable="users",
    column="userId",
    referenceColumn="id",
    onDelete="cascade",  // Options: cascade, setNull, setDefault, restrict
    onUpdate="cascade"
);

// Remove foreign key
removeForeignKey(table="posts", keyName="fk_posts_userId");
```

## Join Table Migration

```cfm
component extends="wheels.migrator.Migration" {

    function up() {
        transaction {
            try {
                // Create join table for many-to-many
                t = createTable(name="postTags", force=false);
                t.integer(columnNames="postId", allowNull=false);
                t.integer(columnNames="tagId", allowNull=false);
                t.timestamps();
                t.create();

                // Add indexes
                addIndex(table="postTags", columnNames="postId");
                addIndex(table="postTags", columnNames="tagId");
                addIndex(table="postTags", columnNames="postId,tagId", unique=true);

                // Add foreign keys
                addForeignKey(
                    table="postTags",
                    referenceTable="posts",
                    column="postId",
                    referenceColumn="id",
                    onDelete="cascade"
                );

                addForeignKey(
                    table="postTags",
                    referenceTable="tags",
                    column="tagId",
                    referenceColumn="id",
                    onDelete="cascade"
                );

            } catch (any e) {
                local.exception = e;
            }

            if (StructKeyExists(local, "exception")) {
                transaction action="rollback";
                Throw(
                    errorCode="1",
                    detail=local.exception.detail,
                    message=local.exception.message,
                    type="any"
                );
            } else {
                transaction action="commit";
            }
        }
    }

    function down() {
        dropTable("postTags");
    }
}
```

## Implementation Checklist

When generating a migration:

- [ ] Extends wheels.migrator.Migration
- [ ] Wrapped in transaction block
- [ ] Try/catch for error handling
- [ ] Rollback on exception
- [ ] Commit on success
- [ ] Use CFML date functions (NOT SQL date functions)
- [ ] Format dates with DateFormat/TimeFormat
- [ ] Include down() method for rollback
- [ ] Add appropriate indexes
- [ ] Add foreign keys where needed
- [ ] Use database-agnostic column types

## Common Patterns

### Adding Soft Delete

```cfm
addColumn(
    table="posts",
    columnType="datetime",
    columnName="deletedAt",
    allowNull=true
);
addIndex(table="posts", columnNames="deletedAt");
```

### Adding Full Text Search

```cfm
// Add column for search
addColumn(
    table="posts",
    columnType="text",
    columnName="searchContent",
    allowNull=true
);

// Create search index (database-specific, document it)
// For PostgreSQL: CREATE INDEX ... USING GIN
// For MySQL: CREATE FULLTEXT INDEX
```

### Adding Versioning

```cfm
addColumn(table="posts", columnType="integer", columnName="version", default=1);
addColumn(table="posts", columnType="integer", columnName="lockVersion", default=0);
```

## Migration Commands

```bash
# Create new migration
wheels g migration CreatePostsTable

# Run pending migrations
wheels dbmigrate latest

# Run single migration
wheels dbmigrate up

# Rollback last migration
wheels dbmigrate down

# Show migration status
wheels dbmigrate info
```

## Related Skills

- **wheels-model-generator**: Creates models for tables
- **wheels-anti-pattern-detector**: Validates migration code

---

**Generated by:** Wheels Migration Generator Skill v1.0
**Framework:** CFWheels 3.0+
**Last Updated:** 2025-10-20
