# CFWheels Migration Date Function Issues

## Critical Problem: CFML Date Functions in Migrations

### ❌ **The Problem**
```cfm
<!-- This causes migration failures -->
component extends="wheels.migrator.Migration" {
    function up() {
        execute("INSERT INTO posts (title, publishedAt, createdAt) VALUES (
            'My Post',
            '" & DateFormat(DateAdd('d', -10, Now()), 'yyyy-mm-dd') & "',
            '" & DateFormat(Now(), 'yyyy-mm-dd') & "'
        )");
    }
}
```

**Error Messages:**
- `Variable [NOW] doesn't exist`
- `Function [DATEFORMAT] not found`
- Migration execution failures

### ✅ **The Solution**
```cfm
<!-- Use static date strings instead -->
component extends="wheels.migrator.Migration" {
    function up() {
        execute("INSERT INTO posts (title, publishedAt, createdAt) VALUES (
            'My Post',
            '2025-09-08 10:00:00',
            '2025-09-18 20:00:00'
        )");
    }
}
```

## Why This Happens

**Root Cause**: The migration execution context has limited access to CFML functions, and string concatenation with date functions often fails during SQL execution.

**Migration Context Limitations:**
- Restricted function scope
- SQL string parsing issues
- Date format inconsistencies
- Transaction rollback complications

## Safe Migration Patterns

### ✅ **Static Date Values**
```cfm
<!-- Best practice: Use ISO format static dates -->
execute("INSERT INTO posts (title, publishedAt, createdAt, updatedAt) VALUES (
    'Machine Learning in Web Development',
    '2025-09-08 10:00:00',
    '2025-09-08 10:00:00',
    '2025-09-18 20:00:00'
)");
```

### ✅ **Database-Native Functions**
```cfm
<!-- Use database-specific date functions -->
execute("INSERT INTO posts (title, publishedAt, createdAt, updatedAt) VALUES (
    'Current Post',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
)");

<!-- For H2 database -->
execute("INSERT INTO posts (title, publishedAt, createdAt, updatedAt) VALUES (
    'Recent Post',
    DATEADD('DAY', -7, CURRENT_TIMESTAMP),
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
)");
```

### ✅ **Loop-Based Data Generation**
```cfm
component extends="wheels.migrator.Migration" {
    function up() {
        transaction {
            try {
                // Define static data array
                var posts = [
                    {title: "Post 1", date: "2025-09-08 10:00:00"},
                    {title: "Post 2", date: "2025-09-09 11:00:00"},
                    {title: "Post 3", date: "2025-09-10 12:00:00"}
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
            } catch (any e) {
                local.exception = e;
            }

            if (StructKeyExists(local, "exception")) {
                transaction action="rollback";
                Throw(errorCode = "1", detail = local.exception.detail, message = local.exception.message, type = "any");
            } else {
                transaction action="commit";
            }
        }
    }
}
```

## Database-Specific Date Handling

### H2 Database (Development)
```cfm
<!-- H2 date functions -->
execute("INSERT INTO posts (publishedAt) VALUES (CURRENT_TIMESTAMP)");
execute("INSERT INTO posts (publishedAt) VALUES (DATEADD('DAY', -30, CURRENT_TIMESTAMP))");
execute("INSERT INTO posts (publishedAt) VALUES (PARSEDATETIME('2025-09-18 10:00:00', 'yyyy-MM-dd HH:mm:ss'))");
```

### MySQL
```cfm
<!-- MySQL date functions -->
execute("INSERT INTO posts (publishedAt) VALUES (NOW())");
execute("INSERT INTO posts (publishedAt) VALUES (DATE_SUB(NOW(), INTERVAL 30 DAY))");
execute("INSERT INTO posts (publishedAt) VALUES (STR_TO_DATE('2025-09-18 10:00:00', '%Y-%m-%d %H:%i:%s'))");
```

### PostgreSQL
```cfm
<!-- PostgreSQL date functions -->
execute("INSERT INTO posts (publishedAt) VALUES (CURRENT_TIMESTAMP)");
execute("INSERT INTO posts (publishedAt) VALUES (CURRENT_TIMESTAMP - INTERVAL '30 days')");
execute("INSERT INTO posts (publishedAt) VALUES (TO_TIMESTAMP('2025-09-18 10:00:00', 'YYYY-MM-DD HH24:MI:SS'))");
```

## Safe Migration Template

### Complete Migration Example
```cfm
component extends="wheels.migrator.Migration" hint="SeedBlogPosts" {

    function up() {
        transaction {
            try {
                // Insert posts with static dates
                execute("INSERT INTO posts (title, content, slug, published, publishedAt, createdAt, updatedAt) VALUES (
                    'Getting Started with CFWheels',
                    '<p>CFWheels is a powerful CFML framework...</p>',
                    'getting-started-cfwheels',
                    1,
                    '2025-09-01 09:00:00',
                    '2025-09-01 09:00:00',
                    CURRENT_TIMESTAMP
                )");

                execute("INSERT INTO posts (title, content, slug, published, publishedAt, createdAt, updatedAt) VALUES (
                    'Advanced CFWheels Patterns',
                    '<p>Learn advanced patterns for CFWheels development...</p>',
                    'advanced-cfwheels-patterns',
                    1,
                    '2025-09-02 10:00:00',
                    '2025-09-02 10:00:00',
                    CURRENT_TIMESTAMP
                )");

            } catch (any e) {
                local.exception = e;
            }

            if (StructKeyExists(local, "exception")) {
                transaction action="rollback";
                Throw(errorCode = "1", detail = local.exception.detail, message = local.exception.message, type = "any");
            } else {
                transaction action="commit";
            }
        }
    }

    function down() {
        transaction {
            try {
                execute("DELETE FROM posts WHERE slug IN (
                    'getting-started-cfwheels',
                    'advanced-cfwheels-patterns'
                )");
            } catch (any e) {
                local.exception = e;
            }

            if (StructKeyExists(local, "exception")) {
                transaction action="rollback";
                Throw(errorCode = "1", detail = local.exception.detail, message = local.exception.message, type = "any");
            } else {
                transaction action="commit";
            }
        }
    }
}
```

## Migration Best Practices

### 1. Date Format Standards
```cfm
<!-- Always use ISO 8601 format -->
'2025-09-18 20:00:00'  <!-- YYYY-MM-DD HH:MM:SS -->

<!-- Avoid these formats in migrations -->
'9/18/2025'            <!-- Ambiguous -->
'18-Sep-2025'          <!-- Text month -->
'2025.09.18'           <!-- Non-standard separator -->
```

### 2. Transaction Safety
```cfm
<!-- Always wrap in transactions -->
transaction {
    try {
        // Migration operations
    } catch (any e) {
        local.exception = e;
    }

    if (StructKeyExists(local, "exception")) {
        transaction action="rollback";
        Throw(errorCode = "1", detail = local.exception.detail, message = local.exception.message, type = "any");
    } else {
        transaction action="commit";
    }
}
```

### 3. Error Handling
```cfm
<!-- Include detailed error information -->
catch (any e) {
    WriteLog(
        file="migration-errors",
        text="Migration failed: #e.message# - #e.detail#",
        type="error"
    );
    local.exception = e;
}
```

### 4. Data Validation
```cfm
<!-- Validate data before insertion -->
if (len(trim(postTitle)) AND len(trim(postContent))) {
    execute("INSERT INTO posts (title, content) VALUES ('#postTitle#', '#postContent#')");
} else {
    Throw(message="Invalid post data: title and content required");
}
```

## Testing Migration Data

### Verify Data After Migration
```cfm
<!-- After running migration, verify in controller or view -->
posts = model("Post").findAll(order="createdAt DESC");
WriteDump(var=posts, label="Migrated Posts");

<!-- Check date formats -->
<cfloop query="posts">
    <p>#posts.title# - Published: #DateFormat(posts.publishedAt, "mmm d, yyyy")#</p>
</cfloop>
```

### Debug Migration Issues
```cfm
<!-- Add debug output to migrations (remove before production) -->
execute("INSERT INTO posts (title, publishedAt) VALUES ('Test Post', '2025-09-18 10:00:00')");
WriteOutput("Inserted test post successfully<br>");

<!-- Check database state -->
<cfquery name="checkPosts" datasource="#get('dataSourceName')#">
    SELECT COUNT(*) as postCount FROM posts
</cfquery>
WriteOutput("Total posts: #checkPosts.postCount#<br>");
```

## Common Pitfalls to Avoid

1. **Don't use CFML date functions** in SQL strings within migrations
2. **Don't rely on server timezone** - use explicit dates
3. **Don't use complex date calculations** - keep it simple
4. **Don't forget transaction handling** for data integrity
5. **Don't skip the down() method** - always provide rollback

This pattern was discovered during actual blog development when date function migrations consistently failed until switching to static date strings.