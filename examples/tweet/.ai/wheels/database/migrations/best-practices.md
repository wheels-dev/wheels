# Migration Best Practices

## Working with Existing Database Schemas

### Pre-Migration Schema Check (CRITICAL)

**Before creating ANY migration, always check for existing tables:**

```bash
# Check current migration status
wheels dbmigrate info

# Verify existing tables in database
# (Check your database directly or use database tools)
```

### Common Scenario: Tables Already Exist

**Situation:** Installation already has tables from previous work

**Problem:** Attempting to create new migrations for existing tables causes errors:
```
Error migrating: Table "POSTS" already exists
Error migrating: Object "COMMENTS_POSTID_FK" already exists
```

### Solutions for Existing Schemas

#### Option 1: Use Existing Tables (Recommended)
```cfm
// Instead of creating new migration for existing table
// Verify table structure matches your model needs
// Only create migrations for missing columns/tables

component extends="wheels.migrator.Migration" {
    function up() {
        // Add only NEW columns to existing table
        t = changeTable(name="posts");
        t.text(columnNames="excerpt");  // Add missing column
        t.change();
    }

    function down() {
        t = changeTable(name="posts");
        t.removeColumn(columnNames="excerpt");
        t.change();
    }
}
```

#### Option 2: Check Before Creating
```cfm
component extends="wheels.migrator.Migration" {
    function up() {
        // Check if table exists before creating
        var tables = getAvailableTables();

        if (!arrayContains(tables, "posts")) {
            t = createTable(name="posts");
            t.string(columnNames="title");
            t.text(columnNames="content");
            t.timestamps();
            t.create();
        }
    }
}
```

#### Option 3: Clean Up Conflicting Migrations
```bash
# Remove migrations that try to recreate existing tables
rm app/migrator/migrations/[timestamp]_CreatePostsTable.cfc
rm app/migrator/migrations/[timestamp]_CreateCommentsTable.cfc
```

### Schema Mismatch Resolution

**Problem:** Seed migration expects columns that don't exist in existing table

**Example Error:**
```
Column "excerpt" not found in table "posts"
```

**Solution:** Modify migrations to match actual schema:

```cfm
// ❌ BEFORE (fails with existing schema):
execute("INSERT INTO posts (title, slug, content, excerpt, ...)
         VALUES ('Title', 'slug', 'Content', 'Excerpt', ...)");

// ✅ AFTER (works with existing schema):
execute("INSERT INTO posts (title, slug, content, ...)
         VALUES ('Title', 'slug', 'Content', ...)");
// Removed excerpt column from INSERT
```

### Schema Inspection Best Practices

**Always inspect existing schema before writing migrations:**

```cfm
// Method 1: Use database info functions
var tables = getAvailableTables();
var columns = getTableInfo("posts");

// Method 2: Query information schema
<cfquery name="tableInfo" datasource="#get('dataSourceName')#">
    SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'posts'
    ORDER BY ORDINAL_POSITION
</cfquery>

// Method 3: Test with simple query
<cfquery name="testSchema" datasource="#get('dataSourceName')#">
    SELECT * FROM posts WHERE 1=0
</cfquery>
<cfset availableColumns = ListToArray(testSchema.columnList)>
```

## Data Seeding Best Practices

### Direct SQL for Reliability

**Use direct SQL statements, not parameter binding:**

```cfm
// ✅ RELIABLE: Direct SQL
execute("INSERT INTO posts (title, content, createdAt, updatedAt)
         VALUES ('Sample Post', 'Content here...', NOW(), NOW())");

// ❌ UNRELIABLE: Parameter binding in migrations
execute(
    sql="INSERT INTO posts (title, content) VALUES (?, ?)",
    parameters=[
        {value=title, cfsqltype="cf_sql_varchar"},
        {value=content, cfsqltype="cf_sql_longvarchar"}
    ]
);
```

### Database-Agnostic Date Handling

**Use CFML date functions for portability:**

```cfm
// ✅ PORTABLE: Works with H2, MySQL, PostgreSQL, SQL Server
var now = Now();
var day7 = DateAdd("d", -7, now);

execute("INSERT INTO posts (title, publishedAt, createdAt) VALUES (
    'Recent Post',
    TIMESTAMP '#DateFormat(day7, "yyyy-mm-dd")# #TimeFormat(day7, "HH:mm:ss")#',
    TIMESTAMP '#DateFormat(now, "yyyy-mm-dd")# #TimeFormat(now, "HH:mm:ss")#'
)");

// ❌ DATABASE-SPECIFIC: Only works with MySQL
execute("INSERT INTO posts (publishedAt) VALUES (DATE_SUB(NOW(), INTERVAL 7 DAY))");
```

### Incremental Data Seeding

**Break large data sets into manageable chunks:**

```cfm
component extends="wheels.migrator.Migration" {
    function up() {
        transaction {
            // Define data array
            var posts = [
                {title: "Post 1", date: "2025-09-01 10:00:00"},
                {title: "Post 2", date: "2025-09-02 11:00:00"},
                {title: "Post 3", date: "2025-09-03 12:00:00"}
            ];

            // Insert each post
            for (var post in posts) {
                execute("INSERT INTO posts (title, publishedAt, createdAt, updatedAt) VALUES (
                    '#post.title#',
                    '#post.date#',
                    '#post.date#',
                    CURRENT_TIMESTAMP
                )");
            }
        }
    }
}
```

## Transaction Management

### Always Wrap Operations in Transactions

```cfm
component extends="wheels.migrator.Migration" {
    function up() {
        transaction {
            try {
                // All migration operations
                t = createTable(name="posts");
                t.string(columnNames="title");
                t.create();

                execute("INSERT INTO posts (title) VALUES ('First Post')");

            } catch (any e) {
                local.exception = e;
            }

            if (StructKeyExists(local, "exception")) {
                transaction action="rollback";
                Throw(
                    errorCode = "1",
                    detail = local.exception.detail,
                    message = local.exception.message,
                    type = "any"
                );
            } else {
                transaction action="commit";
            }
        }
    }

    function down() {
        transaction {
            try {
                dropTable("posts");
            } catch (any e) {
                local.exception = e;
            }

            if (StructKeyExists(local, "exception")) {
                transaction action="rollback";
                Throw(
                    errorCode = "1",
                    detail = local.exception.detail,
                    message = local.exception.message,
                    type = "any"
                );
            } else {
                transaction action="commit";
            }
        }
    }
}
```

## Migration Workflow Best Practices

### 1. Plan Before Creating

**Checklist before generating migration:**
- [ ] Check if tables already exist
- [ ] Verify current schema matches needs
- [ ] Identify only NEW changes needed
- [ ] Plan both `up()` and `down()` methods
- [ ] Consider data seeding requirements

### 2. One Logical Change Per Migration

```cfm
// ✅ GOOD: Single focused migration
component extends="wheels.migrator.Migration" hint="AddExcerptToPosts" {
    function up() {
        t = changeTable(name="posts");
        t.text(columnNames="excerpt");
        t.change();
    }
}

// ❌ BAD: Multiple unrelated changes
component extends="wheels.migrator.Migration" hint="MiscChanges" {
    function up() {
        // Multiple unrelated table changes
        t = changeTable(name="posts");
        t.text(columnNames="excerpt");
        t.change();

        t = createTable(name="comments");
        // ...
        t.create();

        execute("INSERT INTO users ...");  // Unrelated data seeding
    }
}
```

### 3. Always Implement down() Method

**Every migration must be reversible:**

```cfm
component extends="wheels.migrator.Migration" {
    function up() {
        addIndex(table="posts", columnNames="slug", unique=true);
    }

    function down() {
        removeIndex(table="posts", indexName="posts_slug");
    }
}
```

### 4. Test Migrations Both Ways

```bash
# Test up migration
wheels dbmigrate up

# Verify changes in database

# Test down migration
wheels dbmigrate down

# Verify rollback worked

# Re-run up migration
wheels dbmigrate up
```

### 5. Never Modify Completed Migrations

**If migration is already run in production:**
- ❌ Don't edit the existing migration
- ✅ Create a NEW migration to make changes

```cfm
// ❌ DON'T edit 20250901120000_CreatePostsTable.cfc

// ✅ CREATE new migration: 20250902140000_AddExcerptToPosts.cfc
component extends="wheels.migrator.Migration" {
    function up() {
        t = changeTable(name="posts");
        t.text(columnNames="excerpt");
        t.change();
    }
}
```

## Testing Migrations

### Verify Data After Migration

```cfm
// After running migration, verify in controller or view
posts = model("Post").findAll(order="createdAt DESC");

// Check data loaded correctly
<cfloop query="posts">
    <p>#posts.title# - Published: #DateFormat(posts.publishedAt, "mmm d, yyyy")#</p>
</cfloop>
```

### Debug Migration Issues

```cfm
// Add temporary debug output (remove before production)
execute("INSERT INTO posts (title, createdAt) VALUES ('Test Post', CURRENT_TIMESTAMP)");
WriteOutput("Inserted test post successfully<br>");

// Check database state
<cfquery name="checkPosts" datasource="#get('dataSourceName')#">
    SELECT COUNT(*) as postCount FROM posts
</cfquery>
WriteOutput("Total posts: #checkPosts.postCount#<br>");
```

### Test in Development First

**Migration testing workflow:**

1. **Development**: Test migration with dev database
2. **Staging**: Test migration with production-like data
3. **Production**: Deploy with confidence

```bash
# Development testing
wheels dbmigrate latest
# Verify functionality
wheels dbmigrate down
wheels dbmigrate up

# Staging testing
# (repeat same tests with larger dataset)

# Production deployment
# (coordinate with team, have rollback plan)
```

## Common Pitfalls to Avoid

1. **Don't assume clean slate** - Always check for existing schema
2. **Don't use database-specific functions** - Use CFML for portability
3. **Don't skip transactions** - Always wrap operations for safety
4. **Don't forget down() method** - Every migration must be reversible
5. **Don't modify completed migrations** - Create new ones instead
6. **Don't skip testing** - Test both up and down migrations
7. **Don't use complex parameter binding** - Direct SQL is more reliable

## Related Documentation

- [Creating Migrations](./creating-migrations.md)
- [Running Migrations](./running-migrations.md)
- [Date Function Issues](./date-function-issues.md)
- [Column Types](./column-types.md)
- [Rollback](./rollback.md)
