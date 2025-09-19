# /wheels_execute - Comprehensive CFWheels Development Workflow

## Description
Execute a complete, systematic CFWheels development workflow that implements features with professional quality, comprehensive testing, and bulletproof error prevention.

## Usage
```
/wheels_execute [task_description]
```

## Examples
```
/wheels_execute create a blog with posts and comments
/wheels_execute add user authentication to the application
/wheels_execute build an e-commerce product catalog with shopping cart
/wheels_execute create admin dashboard for user management
/wheels_execute implement contact form with email notifications
```

## Workflow Overview

The `/wheels_execute` command implements a comprehensive 7-phase development workflow:

1. **Pre-Flight Documentation Loading** - Systematically load relevant patterns from `.ai` folder
2. **Intelligent Analysis & Planning** - Parse requirements and create detailed implementation plan
3. **Template-Driven Implementation** - Generate code using established patterns with error recovery
4. **TestBox BDD Test Suite Creation** - Write comprehensive BDD tests before marking complete
5. **Multi-Level Testing Execution** - Run unit tests, integration tests, and validation
6. **Comprehensive Browser Testing** - Test every button, form, and link automatically
7. **Quality Assurance & Reporting** - Anti-pattern detection and final validation

## Phase Details

### Phase 1: Pre-Flight Documentation Loading (2-3 minutes)
- **Critical Error Prevention**: Always load `common-errors.md` and `validation-templates.md` first
- **Smart Documentation Discovery**: Analyze task type and load relevant `.ai` documentation
- **Project Context Loading**: Understand existing codebase patterns and conventions
- **Pattern Recognition**: Detect argument styles and naming conventions already in use

### Phase 2: Intelligent Analysis & Planning (3-5 minutes)
- **Requirement Analysis**: Parse natural language into specific CFWheels components
- **Component Mapping**: Identify models, controllers, views, migrations needed
- **Dependency Analysis**: Determine implementation order and resolve conflicts
- **Browser Test Planning**: Plan comprehensive user flow testing scenarios
- **Risk Assessment**: Identify potential issues and mitigation strategies

### Phase 3: Template-Driven Implementation (5-15 minutes)
- **Code Generation**: Use templates from `.ai/wheels/snippets/` as starting points
- **Incremental Validation**: Validate each component after generation
- **Error Recovery**: Intelligent fallbacks when generation fails
- **Consistency Enforcement**: Ensure patterns match existing codebase
- **Security Integration**: Add CSRF protection, validation, authentication

### Phase 4: TestBox BDD Test Suite Creation (10-20 minutes)
- **Model Tests**: Write BDD specs for all model functionality, validations, and associations
- **Controller Tests**: Write BDD specs for all controller actions and security filters
- **Integration Tests**: Write BDD specs for complete user workflows and CRUD operations
- **Test Data Setup**: Create fixtures and test data for comprehensive testing
- **Validation Testing**: Write BDD specs for all form validation scenarios
- **Security Testing**: Write BDD specs for authentication, authorization, and CSRF protection

### Phase 5: Multi-Level Testing Execution (3-8 minutes)
- **Unit Test Execution**: Run all model and controller BDD specs
- **Integration Test Execution**: Run all workflow and CRUD BDD specs
- **Migration Testing**: Verify database changes work correctly
- **Test Coverage Analysis**: Ensure all code paths are tested
- **Test Failure Resolution**: Fix any failing tests before proceeding

### Phase 6: Comprehensive Browser Testing (5-10 minutes)
- **Server Verification**: Ensure development server is running
- **Navigation Testing**: Test all menu links, buttons, and navigation paths
- **CRUD Flow Testing**: Test complete create, read, update, delete operations
- **Form Testing**: Submit all forms, test validation scenarios
- **Interactive Testing**: Test JavaScript, Alpine.js, HTMX functionality
- **Responsive Testing**: Validate mobile, tablet, desktop layouts
- **Error Scenario Testing**: Test 404s, validation failures, edge cases

### Phase 7: Quality Assurance & Reporting (2-3 minutes)
- **Anti-Pattern Detection**: Scan for mixed arguments, query/array confusion
- **Security Review**: Verify CSRF, authentication, input validation
- **Performance Analysis**: Check for N+1 queries, optimization opportunities
- **Documentation Compliance**: Validate against `.ai` documentation patterns
- **Test Coverage Report**: Generate detailed test coverage analysis
- **Comprehensive Reporting**: Generate detailed results with screenshots and test results

## Anti-Pattern Prevention

The workflow specifically prevents the two most common CFWheels errors:

### ❌ Mixed Argument Styles (PREVENTED)
```cfm
// BAD - will cause "Missing argument name" errors
hasMany("comments", dependent="delete");
model("Post").findByKey(params.key, include="comments");
```

### ✅ Consistent Argument Styles (ENFORCED)
```cfm
// GOOD - all named arguments
hasMany(name="comments", dependent="delete");
model("Post").findByKey(key=params.key, include="comments");

// ALSO GOOD - all positional arguments
hasMany("comments");
model("Post").findByKey(params.key);
```

### ❌ Query/Array Confusion (PREVENTED)
```cfm
// BAD - ArrayLen() on query objects
<cfset commentCount = ArrayLen(post.comments())>
<cfloop array="#comments#" index="comment">
```

### ✅ Proper Query Handling (ENFORCED)
```cfm
// GOOD - use .recordCount for queries
<cfset commentCount = post.comments().recordCount>
<cfloop query="comments" startrow="1" endrow="#comments.recordCount#">
```

## Success Criteria

A feature is only considered complete when ALL of the following are true:
- [ ] ✅ All relevant `.ai` documentation was consulted
- [ ] ✅ No anti-patterns detected in generated code
- [ ] ✅ **Comprehensive TestBox BDD test suite written and passing**
- [ ] ✅ **All model BDD specs pass (validations, associations, methods)**
- [ ] ✅ **All controller BDD specs pass (actions, filters, security)**
- [ ] ✅ **All integration BDD specs pass (user workflows, CRUD)**
- [ ] ✅ **Test coverage >= 90% for all components**
- [ ] ✅ All browser tests pass
- [ ] ✅ Every button, form, and link has been tested
- [ ] ✅ Responsive design works on mobile, tablet, desktop
- [ ] ✅ Security validations are in place
- [ ] ✅ Performance is acceptable
- [ ] ✅ Error scenarios are handled properly
- [ ] ✅ Screenshot evidence exists for all user flows
- [ ] ✅ Implementation follows CFWheels conventions

## Browser Testing Coverage

The workflow automatically tests:

### Navigation Testing
- Homepage load and layout
- All menu links and navigation paths
- Breadcrumb navigation
- Footer links and utility pages

### CRUD Operations Testing
- Index pages (list views)
- Show pages (detail views)
- New/Create forms and submission
- Edit/Update forms and submission
- Delete actions and confirmations

### Form Validation Testing
- Empty form submissions (should show errors)
- Partial form submissions
- Invalid data submissions
- Complete valid form submissions
- CSRF protection verification

### Interactive Elements Testing
- JavaScript functionality
- Alpine.js components and interactions
- HTMX requests and responses
- Modal dialogs and dropdowns
- Dynamic content updates

### Responsive Design Testing
- Mobile viewport (375x667)
- Tablet viewport (768x1024)
- Desktop viewport (1920x1080)
- Wide screen viewport (2560x1440)
- Mobile navigation (hamburger menus)

### Error Scenario Testing
- 404 pages for nonexistent resources
- Authentication redirects
- Authorization failures
- Validation error displays
- Server error handling

## Quality Gates

### Automatic Rejection Criteria
Code will be automatically rejected if:
- Any mixed argument styles are detected
- Any `ArrayLen()` calls on model associations exist
- **Any TestBox BDD spec fails**
- **Test coverage is below 90%**
- **Missing BDD specs for any component**
- Any browser test fails
- Any security check fails
- Any anti-pattern is detected
- Routes don't follow RESTful conventions

### Performance Requirements
- Pages must load within 3 seconds
- Forms must submit within 2 seconds
- No N+1 query patterns allowed
- Database queries must be optimized

### Security Requirements
- CSRF protection must be enabled
- All forms must include CSRF tokens
- Authentication filters must be present
- Input validation must be implemented
- SQL injection prevention must be verified

## TestBox BDD Testing Requirements

### Mandatory BDD Test Structure

Every component MUST have comprehensive TestBox BDD specs using the following structure:

#### Model Specs (`/tests/specs/models/`)
```cfm
component extends="wheels.Testbox" {

    function beforeAll() {
        // Setup database and test environment
        application.testbox = new testbox.system.TestBox();
    }

    function afterAll() {
        // Cleanup test data
    }

    function run() {
        describe("Post Model", function() {

            beforeEach(function() {
                variables.post = model("Post").new();
            });

            afterEach(function() {
                if (isObject(variables.post) && variables.post.isPersisted()) {
                    variables.post.delete();
                }
            });

            describe("Validations", function() {
                it("should require title", function() {
                    variables.post.title = "";
                    expect(variables.post.valid()).toBeFalse();
                    expect(variables.post.allErrors()).toHaveKey("title");
                });

                it("should require content", function() {
                    variables.post.content = "";
                    expect(variables.post.valid()).toBeFalse();
                    expect(variables.post.allErrors()).toHaveKey("content");
                });

                it("should require unique slug", function() {
                    var existingPost = model("Post").create({
                        title: "Test Post",
                        content: "Test content",
                        slug: "test-slug",
                        published: false
                    });

                    variables.post.slug = "test-slug";
                    expect(variables.post.valid()).toBeFalse();
                    expect(variables.post.allErrors()).toHaveKey("slug");

                    existingPost.delete();
                });
            });

            describe("Associations", function() {
                it("should have many comments", function() {
                    expect(variables.post.comments()).toBeQuery();
                });

                it("should delete associated comments", function() {
                    var savedPost = model("Post").create({
                        title: "Test Post",
                        content: "Test content",
                        published: false
                    });

                    var comment = model("Comment").create({
                        content: "Test comment",
                        authorName: "Test Author",
                        authorEmail: "test@example.com",
                        postId: savedPost.id
                    });

                    expect(savedPost.comments().recordCount).toBe(1);
                    savedPost.delete();
                    expect(model("Comment").findByKey(comment.id)).toBeFalse();
                });
            });

            describe("Methods", function() {
                it("should generate excerpt", function() {
                    variables.post.content = "<p>This is a long content that should be truncated at some point for the excerpt.</p>";
                    expect(len(variables.post.excerpt(20))).toBeLTE(23); // 20 + "..."
                });

                it("should auto-generate slug from title", function() {
                    variables.post.title = "This is a Test Title!";
                    variables.post.setSlugAndPublishDate();
                    expect(variables.post.slug).toBe("this-is-a-test-title");
                });
            });
        });
    }
}
```

#### Controller Specs (`/tests/specs/controllers/`)
```cfm
component extends="wheels.Testbox" {

    function beforeAll() {
        application.testbox = new testbox.system.TestBox();
    }

    function run() {
        describe("Posts Controller", function() {

            beforeEach(function() {
                // Setup test data
                variables.testPost = model("Post").create({
                    title: "Test Post",
                    content: "Test content for controller testing",
                    published: true,
                    publishedAt: now()
                });
            });

            afterEach(function() {
                if (isObject(variables.testPost)) {
                    variables.testPost.delete();
                }
            });

            describe("index action", function() {
                it("should load published posts", function() {
                    var controller = controller("Posts");
                    controller.index();

                    expect(controller.posts).toBeQuery();
                    expect(controller.posts.recordCount).toBeGTE(1);
                });

                it("should order posts by publishedAt DESC", function() {
                    var newerPost = model("Post").create({
                        title: "Newer Post",
                        content: "Newer content",
                        published: true,
                        publishedAt: dateAdd("h", 1, now())
                    });

                    var controller = controller("Posts");
                    controller.index();

                    expect(controller.posts.title[1]).toBe("Newer Post");
                    newerPost.delete();
                });
            });

            describe("show action", function() {
                it("should load post and comments", function() {
                    var controller = controller("Posts");
                    controller.params.key = variables.testPost.id;
                    controller.show();

                    expect(controller.post.id).toBe(variables.testPost.id);
                    expect(controller.comments).toBeQuery();
                });
            });

            describe("create action", function() {
                it("should create valid post", function() {
                    var controller = controller("Posts");
                    controller.params.post = {
                        title: "New Test Post",
                        content: "New test content",
                        published: true
                    };

                    var initialCount = model("Post").count();
                    controller.create();

                    expect(model("Post").count()).toBe(initialCount + 1);

                    // Cleanup
                    var newPost = model("Post").findOne(where="title = 'New Test Post'");
                    if (isObject(newPost)) {
                        newPost.delete();
                    }
                });

                it("should handle validation errors", function() {
                    var controller = controller("Posts");
                    controller.params.post = {
                        title: "", // Invalid - empty title
                        content: "Test content"
                    };

                    controller.create();
                    expect(controller.post.hasErrors()).toBeTrue();
                });
            });
        });
    }
}
```

#### Integration Specs (`/tests/specs/integration/`)
```cfm
component extends="wheels.Testbox" {

    function run() {
        describe("Blog Workflow Integration", function() {

            beforeEach(function() {
                // Setup clean test environment
            });

            afterEach(function() {
                // Cleanup test data
            });

            describe("Complete post lifecycle", function() {
                it("should create, publish, and delete post", function() {
                    // Create post
                    var post = model("Post").create({
                        title: "Integration Test Post",
                        content: "Integration test content",
                        published: false
                    });

                    expect(post.isNew()).toBeFalse();
                    expect(post.published).toBeFalse();

                    // Publish post
                    post.update({published: true, publishedAt: now()});
                    expect(post.published).toBeTrue();

                    // Add comment
                    var comment = model("Comment").create({
                        content: "Integration test comment",
                        authorName: "Test Author",
                        authorEmail: "test@example.com",
                        postId: post.id
                    });

                    expect(post.comments().recordCount).toBe(1);

                    // Delete post (should cascade delete comments)
                    post.delete();
                    expect(model("Comment").findByKey(comment.id)).toBeFalse();
                });
            });

            describe("Form validation workflow", function() {
                it("should prevent invalid post creation", function() {
                    var post = model("Post").new({
                        title: "", // Invalid
                        content: "x" // Too short
                    });

                    expect(post.save()).toBeFalse();
                    expect(post.allErrors()).toHaveKey("title");
                    expect(post.allErrors()).toHaveKey("content");
                });
            });
        });
    }
}
```

### Test Execution Requirements

#### Mandatory Test Commands
All tests MUST be executed and pass before completion:

```bash
# Run all model specs
wheels test model --reporter=json

# Run all controller specs
wheels test controller --reporter=json

# Run all integration specs
wheels test integration --reporter=json

# Run complete test suite with coverage
wheels test all --coverage --reporter=json
```

#### Test Coverage Requirements
- **Models**: 100% coverage of all public methods, validations, and associations
- **Controllers**: 100% coverage of all actions and filters
- **Integration**: 90% coverage of complete user workflows
- **Overall**: Minimum 90% total coverage across all components

#### Test Data Management
- Use TestBox's `beforeEach()` and `afterEach()` for test isolation
- Create test fixtures for complex scenarios
- Always clean up test data to prevent test pollution
- Use database transactions for faster test execution

## Error Recovery System

When errors occur during any phase:

1. **Identify Error Type**: Syntax, logic, pattern, or security error
2. **Load Recovery Documentation**: Load relevant `.ai` documentation for the error
3. **Apply Documented Solution**: Use established patterns from documentation
4. **Retry Operation**: Attempt the operation with corrected approach
5. **Log Pattern**: Document the error pattern for future prevention

### Common Recovery Flows

#### Mixed Argument Error Recovery
```
Error: "Missing argument name" detected
→ Load: .ai/wheels/troubleshooting/common-errors.md
→ Fix: Convert to consistent argument style
→ Retry: Code generation with corrected pattern
→ Validate: Syntax check passes
```

#### Query/Array Confusion Recovery
```
Error: ArrayLen() on query object detected
→ Load: .ai/wheels/models/data-handling.md
→ Fix: Use .recordCount and proper loop syntax
→ Retry: View generation with correct patterns
→ Validate: Browser test confirms functionality
```

#### TestBox BDD Test Failure Recovery
```
Error: BDD specs failing or missing
→ Load: .ai/wheels/testing/ documentation
→ Fix: Write comprehensive BDD specs for all components
→ Retry: Run complete test suite
→ Validate: All tests pass with 90%+ coverage
```

#### Test Coverage Insufficient Recovery
```
Error: Test coverage below 90%
→ Analyze: Identify untested code paths
→ Fix: Add BDD specs for missing scenarios
→ Retry: Run test suite with coverage analysis
→ Validate: Coverage meets minimum requirements
```

## Implementation Strategy

### Documentation Loading Strategy
1. **Universal Critical Documentation** (always loaded first):
   - `.ai/wheels/troubleshooting/common-errors.md`
   - `.ai/wheels/patterns/validation-templates.md`
   - `.ai/wheels/workflows/pre-implementation.md`

2. **Component-Specific Documentation** (loaded based on task analysis):
   - Models: `.ai/wheels/models/architecture.md`, `associations.md`, `validations.md`
   - Controllers: `.ai/wheels/controllers/architecture.md`, `rendering.md`, `filters.md`
   - Views: `.ai/wheels/views/data-handling.md`, `architecture.md`, `forms.md`
   - Migrations: `.ai/wheels/database/migrations/creating-migrations.md`

3. **Feature-Specific Documentation** (loaded as needed):
   - Authentication: `.ai/wheels/models/user-authentication.md`
   - Security: `.ai/wheels/security/csrf-protection.md`
   - Forms: `.ai/wheels/views/helpers/forms.md`

### Task Type Detection
The workflow analyzes the task description for:
- **Model Indicators**: "model", "User", "Post", "association", "validation"
- **Controller Indicators**: "controller", "action", "CRUD", "API", "filter"
- **View Indicators**: "view", "template", "form", "layout", "responsive"
- **Feature Indicators**: "auth", "admin", "search", "email", "upload"

### Browser Testing Strategy
Based on application type detected:
- **Blog Applications**: Post CRUD, commenting, navigation
- **E-commerce Applications**: Product catalog, shopping cart, checkout
- **Admin Applications**: User management, authentication, dashboards
- **API Applications**: Endpoint testing, JSON responses, authentication

## Comparison Benefits vs MCP Tool

### Advantages of Slash Command Approach
- **Flexibility**: Claude Code can adapt the workflow dynamically
- **Error Handling**: Better error recovery and human-readable feedback
- **Documentation Integration**: Direct access to `.ai` folder without MCP resource limitations
- **Comprehensive Testing**: TestBox BDD specs + Browser testing + Integration testing
- **Test Coverage**: Mandatory 90%+ coverage with detailed analysis
- **Quality Assurance**: No feature complete without passing test suite
- **Reporting**: Rich, detailed reporting with screenshots, test results, and coverage analysis
- **Learning**: Users see the complete process and can learn from it

### Testing Strategy
Run both approaches on the same task:
```
/wheels_execute create a blog with posts and comments
vs
mcp__wheels__develop(task="create a blog with posts and comments")
```

Compare results on:
- Code quality and adherence to patterns
- Test coverage and browser testing thoroughness
- Error prevention and pattern consistency
- Implementation time and reliability
- User experience and learning value

This slash command provides a systematic, comprehensive approach to CFWheels development that ensures professional quality results with complete testing coverage.