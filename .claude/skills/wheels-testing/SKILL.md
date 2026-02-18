---
name: Wheels Testing & Debugging
description: Generate TestBox BDD tests for Wheels models, controllers, and integration workflows. Diagnose and fix common Wheels errors. Use when creating tests, running test suites, or troubleshooting failures.
---

# Wheels Testing & Debugging

## Model Test Template

```cfm
component extends="wheels.Test" {
    function setup() {
        super.setup();
        model = model("Post").new();
    }
    function teardown() {
        if (isObject(model) && model.isPersisted()) model.delete();
        super.teardown();
    }

    // Validation tests
    function testValidatesPresenceOfTitle() {
        model.title = "";
        assert("!model.valid()");
        assert("model.hasErrors('title')");
    }
    function testValidatesUniquenessOfEmail() {
        model("User").create(email="test@example.com", firstname="A", lastname="B");
        var dupe = model("User").new(email="test@example.com", firstname="C", lastname="D");
        assert("!dupe.valid()");
    }
    function testValidatesFormatOfEmail() {
        model.email = "not-an-email";
        assert("!model.valid()");
    }

    // Association tests
    function testHasManyComments() {
        model = model("Post").create(title="Test", content="Content");
        model("Comment").create(postId=model.id, content="A comment");
        assert("model.comments().recordCount == 1");
    }
    function testBelongsToAuthor() {
        var author = model("Author").create(name="Jane");
        model = model("Post").create(title="Test", authorId=author.id);
        assert("isObject(model.author())");
        assert("model.author().name == 'Jane'");
    }

    // Custom method tests
    function testFullNameMethod() {
        var user = model("User").new(firstname="John", lastname="Doe");
        assert("user.fullName() == 'John Doe'");
    }

    // CRUD tests
    function testCreateWithValidData() {
        var post = model("Post").create(title="New", content="Body");
        assert("isObject(post) && post.isPersisted()");
    }
    function testDeleteCascadesComments() {
        model = model("Post").create(title="Test", content="Content");
        var comment = model("Comment").create(postId=model.id, content="Comment");
        model.delete();
        assert("!isObject(model('Comment').findByKey(comment.id))");
    }
}
```

## Controller Test Template

```cfm
component extends="wheels.Test" {
    function setup() {
        super.setup();
        params = {controller="posts", action="index"};
    }

    function testIndexLoadsAllPosts() {
        controller = controller("Posts", params);
        controller.processAction("index");
        assert("isQuery(controller.posts)");
    }
    function testShowFindsPost() {
        var post = model("Post").create(title="Test", content="Body");
        params.action = "show";
        params.key = post.id;
        controller = controller("Posts", params);
        controller.processAction("show");
        assert("isObject(controller.post)");
    }
    function testCreateWithValidData() {
        params.action = "create";
        params.post = {title="Test", content="Content"};
        controller = controller("Posts", params);
        controller.processAction("create");
        assert("flashKeyExists('success')");
    }
    function testCreateWithInvalidData() {
        params.action = "create";
        params.post = {title="", content=""};
        controller = controller("Posts", params);
        controller.processAction("create");
        // Should render new form again, not redirect
    }
    function testRequiresAuthentication() {
        params.action = "edit";
        params.key = 1;
        controller = controller("Posts", params);
        controller.processAction("edit");
        // Without session auth, should redirect
    }
}
```

## Integration Test Template

```cfm
component extends="wheels.Test" {
    function testCompletePostLifecycle() {
        // Create
        var post = model("Post").create(title="Integration Test", content="Body");
        assert("isObject(post) && post.isPersisted()");
        // Read
        var found = model("Post").findByKey(post.id);
        assert("found.title == 'Integration Test'");
        // Update
        found.update(title="Updated Title");
        var refreshed = model("Post").findByKey(post.id);
        assert("refreshed.title == 'Updated Title'");
        // Delete
        found.delete();
        assert("!isObject(model('Post').findByKey(post.id))");
    }

    function testAssociationWorkflow() {
        var author = model("Author").create(name="Jane");
        var post = model("Post").create(title="Test", authorId=author.id);
        model("Comment").create(postId=post.id, content="Great post");
        assert("post.author().name == 'Jane'");
        assert("post.comments().recordCount == 1");
        post.delete();
    }
}
```

## Test Setup: beforeAll/afterAll Patterns

```cfm
component extends="wheels.Test" {
    function beforeAll() {
        // Runs once before all tests - seed shared data
        variables.testAuthor = model("Author").create(name="Test Author");
    }
    function afterAll() {
        // Runs once after all tests - cleanup shared data
        if (isObject(variables.testAuthor)) variables.testAuthor.delete();
    }
    function setup() {
        super.setup();
        // Runs before EACH test - fresh per-test state
        variables.post = "";
    }
    function teardown() {
        if (isObject(variables.post) && variables.post.isPersisted()) variables.post.delete();
        super.teardown();
    }
}
```

## H2 Test Database Syntax

Test environment uses H2. Use H2-compatible syntax in `tests/populate.cfm`:

```sql
-- Primary key (CRITICAL - wrong syntax causes "no primary key" errors)
id INT IDENTITY PRIMARY KEY          -- CORRECT for H2
id INT AUTO_INCREMENT PRIMARY KEY    -- WRONG (MySQL syntax)

-- H2 column type mappings
VARCHAR(255)   -- not VARCHAR2
TIMESTAMP      -- not DATETIME
INT            -- not INTEGER
BOOLEAN        -- supported natively
TEXT           -- for long text
DECIMAL(10,2)  -- for decimals
```

Example `tests/populate.cfm` table creation:
```cfm
queryExecute("DROP TABLE IF EXISTS posts", {}, {datasource: application.wheels.dataSourceName});
queryExecute("
    CREATE TABLE posts (
        id INT IDENTITY PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        content TEXT,
        authorId INT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        deletedAt TIMESTAMP
    )
", {}, {datasource: application.wheels.dataSourceName});
```

## Running Tests

**MCP tools (preferred when .mcp.json exists):**
```javascript
mcp__wheels__wheels_test()                    // Run all tests
mcp__wheels__wheels_test(target="models")     // Model tests only
mcp__wheels__wheels_test(target="controllers") // Controller tests only
```

**CLI fallback:** `wheels test run`

**Test file organization:**
```
tests/
  Test.cfc              # Base test component
  models/               # Model tests (one per model)
  controllers/          # Controller tests (one per controller)
  integration/          # End-to-end workflow tests
```

**New table checklist:**
1. Create migration in `app/migrator/migrations/`
2. Run migration: `mcp__wheels__wheels_migrate(action="latest")`
3. Update `tests/populate.cfm` with H2-compatible CREATE TABLE
4. Use `IDENTITY` for primary keys, match column names/types exactly
5. Run tests to verify

## Debugging Guide: Common Errors

### "No matching function [RENDERPAGE] found"
Wheels uses `renderView()` not `renderPage()`:
```cfm
renderPage(action="new")    // WRONG
renderView(action="new")    // CORRECT
```

### "Missing argument name" Error
Mixed positional and named arguments. Use consistent style:
```cfm
hasMany("comments", dependent="delete")        // WRONG - mixed
hasMany(name="comments", dependent="delete")   // CORRECT - all named
hasMany("comments")                            // CORRECT - all positional

.resources("sessions", only="new,create")      // WRONG
.resources(name="sessions", only="new,create") // CORRECT
```

### "key [onCreate,onUpdate] doesn't exist"
Comma-separated `when` parameter. Validations run on create and update by default:
```cfm
validatesConfirmationOf(properties="password", when="onCreate,onUpdate")  // WRONG
validatesConfirmationOf(properties="password")                            // CORRECT
```

### "Can't cast Object type [Query] to [Array]"
Associations return queries, not arrays:
```cfm
ArrayLen(post.comments())       // WRONG - returns query
post.comments().recordCount     // CORRECT
```

### "Association not found" Error
1. Association not defined in model `config()` -- add `hasMany()`/`belongsTo()`
2. Typo in association name -- verify spelling matches model name
3. Model file missing or misnamed -- check `/app/models/`

### "Table not found" Error
1. Migration not run -- `mcp__wheels__wheels_migrate(action="latest")`
2. Table name mismatch -- Wheels pluralizes model names (User -> users)
3. Test environment -- update `tests/populate.cfm` with CREATE TABLE

### "Column not found" Error
1. Column missing -- add via migration
2. Spelling/case mismatch -- check exact column name in database
3. Migration not applied -- run pending migrations

### "No primary key" in Tests
H2 requires `IDENTITY`, not `AUTO_INCREMENT`:
```sql
id INT IDENTITY PRIMARY KEY          -- CORRECT for H2
id INT AUTO_INCREMENT PRIMARY KEY    -- WRONG for H2
```

## Debugging Tools & Strategies

**Enable debug output:**
```cfm
// config/settings.cfm
set(showDebugInformation=true);
set(showErrorInformation=true);
```

**Inspect variables:** `<cfdump var="#post#" label="Post Object"><cfabort>`

**Check SQL:** Wheels logs all SQL to debug output. Red queries indicate errors.

**Debugging strategy:**
1. Read the full error message -- Wheels errors are descriptive
2. Check model `config()` for association/validation definitions
3. Verify migrations: `mcp__wheels__wheels_migrate(action="info")`
4. Use `?reload=true` after config changes
5. Check debug footer for route information
6. Test associations and routes in isolation before combining
7. Start simple, add complexity incrementally
