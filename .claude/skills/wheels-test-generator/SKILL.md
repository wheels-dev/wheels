---
name: Wheels Test Generator
description: Generate TestBox BDD test specs for Wheels models, controllers, and integration tests. Use when creating tests for models (validations, associations), controllers (actions, filters), or integration workflows. Ensures comprehensive test coverage with proper setup/teardown and Wheels testing conventions.
---

# Wheels Test Generator

## When to Use This Skill

Activate automatically when:
- User requests to create tests/specs
- User wants to test a model, controller, or workflow
- User mentions: test, spec, TestBox, BDD, describe, it, expect
- After generating models/controllers (proactive testing)

## Model Test Template

```cfm
component extends="wheels.Test" {

    function setup() {
        // Runs before each test
        super.setup();
        model = model("Post").new();
    }

    function teardown() {
        // Runs after each test
        if (isObject(model) && model.isPersisted()) {
            model.delete();
        }
        super.teardown();
    }

    function testValidatesPresenceOfTitle() {
        model.title = "";
        assert("!model.valid()");
        assert("model.hasErrors('title')");
    }

    function testHasManyComments() {
        model = model("Post").create(title="Test", content="Content");
        comment = model("Comment").create(postId=model.id, content="Comment");

        assert("model.comments().recordCount == 1");

        model.delete(); // Cascade should delete comment
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

    function testShowRequiresKey() {
        params.action = "show";
        controller = controller("Posts", params);
        // Should redirect due to missing key
    }

    function testCreateWithValidData() {
        params.action = "create";
        params.post = {title="Test", content="Content"};

        controller = controller("Posts", params);
        controller.processAction("create");

        assert("flashKeyExists('success')");
    }
}
```

## Integration Test Template

```cfm
component extends="wheels.Test" {

    function testCompletePostLifecycle() {
        // Create
        post = model("Post").create(title="Test", content="Content");
        assert("isObject(post) && post.isPersisted()");

        // Update
        post.update(title="Updated");
        assert("post.title == 'Updated'");

        // Add comment
        comment = model("Comment").create(postId=post.id, content="Comment");
        assert("post.comments().recordCount == 1");

        // Delete (cascade)
        post.delete();
        assert("!isObject(model('Comment').findByKey(comment.id))");
    }
}
```

## Browser-Based Integration Testing

For end-to-end testing of user workflows, use MCP browser tools:

### Basic Browser Test Flow
```javascript
// 1. Start server and navigate
mcp__wheels__wheels_server(action="status")

// 2. Use available browser MCP (in order of preference):

// Option A: Puppeteer MCP (preferred)
mcp__puppeteer__puppeteer_navigate(url="http://localhost:PORT/posts")
mcp__puppeteer__puppeteer_screenshot(name="posts-index")
mcp__puppeteer__puppeteer_click(selector="a[href*='new']")
mcp__puppeteer__puppeteer_screenshot(name="posts-new-form")

// Option B: Playwright MCP
mcp__playwright__playwright_navigate(url="http://localhost:PORT/posts")
mcp__playwright__playwright_screenshot()

// Option C: Browser MCP (fallback)
mcp__browsermcp__browser_navigate(url="http://localhost:PORT/posts")
mcp__browsermcp__browser_screenshot()
```

### Complete User Workflow Test
```javascript
// Test: Create new post
// 1. Navigate to new post form
mcp__puppeteer__puppeteer_navigate(url="http://localhost:PORT/posts/new")
mcp__puppeteer__puppeteer_screenshot(name="step1-form")

// 2. Fill form fields
mcp__puppeteer__puppeteer_click(selector="input[name='post[title]']")
// Enter data...

// 3. Submit and verify
mcp__puppeteer__puppeteer_click(selector="button[type='submit']")
mcp__puppeteer__puppeteer_screenshot(name="step2-created")

// 4. Verify success message or redirect
// Check screenshot for success indicators
```

### Testing CRUD Operations
```javascript
// CREATE: Test form submission
mcp__puppeteer__puppeteer_navigate(url="http://localhost:PORT/posts/new")

// READ: Test index and show pages
mcp__puppeteer__puppeteer_navigate(url="http://localhost:PORT/posts")
mcp__puppeteer__puppeteer_navigate(url="http://localhost:PORT/posts/1")

// UPDATE: Test edit form
mcp__puppeteer__puppeteer_navigate(url="http://localhost:PORT/posts/1/edit")

// DELETE: Test delete action
// Verify through index page
```

## Related Skills

- **wheels-model-generator**: Creates models to test
- **wheels-controller-generator**: Creates controllers to test
- **wheels-debugging**: Use when tests fail

---

**Generated by:** Wheels Test Generator Skill v1.1
