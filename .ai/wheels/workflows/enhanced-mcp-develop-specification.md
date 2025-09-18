# Enhanced mcp__wheels__develop Workflow Specification

## Overview

This specification defines the enhanced `mcp__wheels__develop` tool that provides a comprehensive, systematic development workflow for CFWheels applications. The goal is to create a bulletproof development process that produces professional-quality, thoroughly tested features consistently.

## Core Principles

1. **Documentation-Driven Development**: Always consult .ai documentation before implementation
2. **Anti-Pattern Prevention**: Systematically prevent common CFWheels errors
3. **Comprehensive Testing**: Every button, form, and link must be tested
4. **Template-Based Implementation**: Use established patterns from .ai documentation
5. **Error Recovery**: Intelligent error handling with documentation re-consultation
6. **Quality Assurance**: Built-in validation and security checks

## Enhanced Workflow Phases

### Phase 1: Pre-Flight Documentation Loading (2-3 minutes)

#### 1.1 Critical Error Prevention (MANDATORY FIRST STEP)
**ALWAYS load these files first, regardless of task type:**
- `.ai/wheels/troubleshooting/common-errors.md`
- `.ai/wheels/patterns/validation-templates.md`

**Purpose**: Prevent the two most common CFWheels errors:
- Mixed argument styles (`hasMany("comments", dependent="delete")`)
- Query/Array confusion (`ArrayLen(post.comments())`)

#### 1.2 Smart Documentation Discovery
**Task Type Detection Algorithm:**
```
IF task contains ("model", "User", "Post", etc.) → MODEL workflow
IF task contains ("controller", "action", "CRUD") → CONTROLLER workflow
IF task contains ("view", "template", "form") → VIEW workflow
IF task contains ("migration", "database", "table") → MIGRATION workflow
IF task contains ("route", "routing", "URL") → ROUTING workflow
IF multiple types detected → MULTI-COMPONENT workflow
```

**Documentation Loading by Task Type:**

**Model Tasks:**
1. `.ai/wheels/models/architecture.md` - Model structure and fundamentals
2. `.ai/wheels/models/associations.md` - Relationship patterns (CRITICAL)
3. `.ai/wheels/models/validations.md` - Validation methods and patterns
4. `.ai/wheels/models/best-practices.md` - Development guidelines
5. `.ai/wheels/snippets/model-snippets.md` - Code templates

**Controller Tasks:**
1. `.ai/wheels/controllers/architecture.md` - Controller fundamentals and CRUD
2. `.ai/wheels/controllers/rendering.md` - View rendering and responses
3. `.ai/wheels/controllers/filters.md` - Authentication and authorization
4. `.ai/wheels/controllers/model-interactions.md` - Controller-model patterns
5. `.ai/wheels/snippets/controller-snippets.md` - Code templates

**View Tasks:**
1. `.ai/wheels/views/data-handling.md` - CRITICAL query vs array patterns
2. `.ai/wheels/views/architecture.md` - View structure and conventions
3. `.ai/wheels/views/forms.md` - Form helpers and limitations (CRITICAL)
4. `.ai/wheels/views/layouts.md` - Layout patterns and inheritance
5. `.ai/wheels/snippets/view-snippets.md` - Code templates

**Migration Tasks:**
1. `.ai/wheels/database/migrations/creating-migrations.md` - Migration basics
2. `.ai/wheels/database/migrations/column-types.md` - Column types
3. `.ai/wheels/database/migrations/advanced-operations.md` - Complex operations

#### 1.3 Project Context Loading
- Current project structure analysis
- Existing models, controllers, views inventory
- Current route configuration
- Migration status and history
- Test coverage assessment

#### 1.4 Pattern Recognition
- Identify existing code patterns in the project
- Detect argument style consistency (named vs positional)
- Catalog existing associations and validations
- Note naming conventions already in use

### Phase 2: Intelligent Analysis & Planning (3-5 minutes)

#### 2.1 Requirement Analysis
**Natural Language Processing:**
- Parse user request for specific components needed
- Identify CRUD operations required
- Detect authentication/authorization needs
- Identify form and validation requirements
- Recognize testing scenarios mentioned

**Component Mapping:**
```
"blog with posts and comments" →
  Models: Post, Comment
  Controllers: PostsController, CommentsController
  Views: posts/index, posts/show, comments/_form
  Migrations: CreatePosts, CreateComments
  Tests: Post model, Comment model, integration tests
  Browser Tests: Navigation, CRUD flows, form submissions
```

#### 2.2 Dependency Analysis
- Model association requirements
- Controller filter needs
- Route configuration changes
- Migration sequence planning
- Asset and layout dependencies

#### 2.3 Anti-Pattern Pre-validation
**Check planned approach against common errors:**
- Will any associations use mixed argument styles?
- Are there any plans to use ArrayLen() on model results?
- Will naming conventions be consistent?
- Are all routes following RESTful patterns?

#### 2.4 Browser Test Scenario Planning
**Comprehensive User Flow Mapping:**
- **Navigation Flows**: Every menu, link, button pathway
- **CRUD Flows**: Create, read, update, delete for each model
- **Form Flows**: Every form submission, validation scenario
- **Authentication Flows**: Login, logout, access control
- **Error Flows**: 404s, validation failures, edge cases
- **Responsive Flows**: Mobile, tablet, desktop layouts

### Phase 3: Template-Driven Systematic Implementation (5-15 minutes)

#### 3.1 Code Generation with Templates
**Template Selection Process:**
1. Load appropriate code template from `.ai/wheels/snippets/`
2. Verify template matches current project patterns
3. Apply consistent argument style (named vs positional)
4. Inject project-specific naming conventions
5. Add validation and security patterns

**Template Application Examples:**
```cfm
// Model Template (from .ai documentation)
component extends="Model" {
    function config() {
        // Consistent named arguments throughout
        hasMany(name="comments", dependent="delete");
        belongsTo(name="user");
        validatesPresenceOf(properties="title,content");

        // Security validations
        validatesLengthOf(property="title", minimum=5, maximum=200);
        validatesFormatOf(property="slug", regEx="^[a-z0-9-]+$");
    }
}
```

#### 3.2 Incremental Validation
**After each component generation:**
1. Syntax validation using CFWheels parser
2. Anti-pattern detection scan
3. Consistency check against existing code
4. Security pattern verification
5. Template compliance validation

#### 3.3 Error Recovery System
**If generation fails:**
1. **Step 1**: Re-read relevant documentation section
2. **Step 2**: Try alternative template or pattern
3. **Step 3**: Simplify approach and retry
4. **Step 4**: Log error pattern for future prevention
5. **Step 5**: Request human intervention if needed

**Common Recovery Patterns:**
- Mixed arguments → Convert to consistent style
- Query/Array confusion → Use .recordCount and proper loops
- Route conflicts → Adjust route ordering
- Validation failures → Add missing required fields

### Phase 4: Multi-Level Testing Framework (3-8 minutes)

#### 4.1 Unit Testing (Models)
**Automatic test generation for each model:**
```cfm
component extends="testbox.system.BaseSpec" {
    function run() {
        describe("User Model", function() {
            it("should validate required fields", function() {
                var user = model("User").new();
                expect(user.valid()).toBeFalse();
                expect(arrayLen(user.allErrors())).toBeGT(0);
            });

            it("should create valid user", function() {
                var userData = {
                    firstname = "John",
                    lastname = "Doe",
                    email = "john@example.com"
                };
                var user = model("User").create(userData);
                expect(user.valid()).toBeTrue();
            });
        });
    }
}
```

#### 4.2 Integration Testing (Controllers)
**Automatic controller test generation:**
- Test each CRUD action
- Verify authentication filters
- Test parameter validation
- Check response formats (HTML/JSON)
- Validate redirect behaviors

#### 4.3 Migration Testing
- Test migration up() and down() methods
- Verify data integrity after migrations
- Test rollback scenarios
- Validate foreign key constraints

#### 4.4 Syntax and Configuration Testing
- CFWheels syntax validation
- Route configuration testing
- Application startup testing
- Framework setting validation

### Phase 5: Comprehensive Browser Testing Automation (5-10 minutes)

#### 5.1 Server Status Verification
```javascript
// Verify development server is running
mcp__wheels__server(action="status")

// If not running, start server
if (serverNotRunning) {
    mcp__wheels__server(action="start")
    wait(5000) // Allow startup time
}
```

#### 5.2 Homepage and Navigation Testing
```javascript
// Navigate to application
mcp__puppeteer__puppeteer_navigate(url="http://localhost:PORT")

// Take homepage screenshot
mcp__puppeteer__puppeteer_screenshot(name="01_homepage", width=1200, height=800)

// Test all navigation links
document.querySelectorAll('nav a, .menu a').forEach(async (link, index) => {
    await mcp__puppeteer__puppeteer_click(selector=`nav a:nth-child(${index+1})`)
    await mcp__puppeteer__puppeteer_screenshot(name=`02_nav_${index}`, width=1200, height=800)
})
```

#### 5.3 CRUD Operation Testing
**For each model (e.g., Post):**
```javascript
// Test index page
mcp__puppeteer__puppeteer_navigate(url="http://localhost:PORT/posts")
mcp__puppeteer__puppeteer_screenshot(name="posts_index")

// Test new/create flow
mcp__puppeteer__puppeteer_click(selector="a:contains('New Post')")
mcp__puppeteer__puppeteer_screenshot(name="posts_new_form")

mcp__puppeteer__puppeteer_fill(selector="input[name='post[title]']", value="Test Post")
mcp__puppeteer__puppeteer_fill(selector="textarea[name='post[content]']", value="Test content")
mcp__puppeteer__puppeteer_click(selector="input[type='submit']")
mcp__puppeteer__puppeteer_screenshot(name="posts_created")

// Test show page
mcp__puppeteer__puppeteer_click(selector="article:first-child h2 a")
mcp__puppeteer__puppeteer_screenshot(name="posts_show")

// Test edit flow
mcp__puppeteer__puppeteer_click(selector="a:contains('Edit')")
mcp__puppeteer__puppeteer_screenshot(name="posts_edit_form")

mcp__puppeteer__puppeteer_fill(selector="input[name='post[title]']", value="Updated Test Post")
mcp__puppeteer__puppeteer_click(selector="input[type='submit']")
mcp__puppeteer__puppeteer_screenshot(name="posts_updated")
```

#### 5.4 Form Validation Testing
```javascript
// Test validation errors
mcp__puppeteer__puppeteer_navigate(url="http://localhost:PORT/posts/new")
mcp__puppeteer__puppeteer_click(selector="input[type='submit']") // Submit empty form
mcp__puppeteer__puppeteer_screenshot(name="validation_errors")

// Verify error messages are displayed
const errors = await mcp__puppeteer__puppeteer_evaluate({
    script: "document.querySelectorAll('.error, .alert-danger').length"
})
expect(errors).toBeGT(0)
```

#### 5.5 Interactive Element Testing
```javascript
// Test JavaScript/Alpine.js/HTMX functionality
mcp__puppeteer__puppeteer_click(selector="button[x-on\\:click], [hx-get], .btn-js")
mcp__puppeteer__puppeteer_screenshot(name="interactive_elements")

// Test modal/dropdown functionality
mcp__puppeteer__puppeteer_click(selector="[data-modal-trigger], .dropdown-toggle")
mcp__puppeteer__puppeteer_screenshot(name="modal_dropdown")
```

#### 5.6 Responsive Design Testing
```javascript
// Test mobile viewport
mcp__puppeteer__puppeteer_screenshot(name="mobile_view", width=375, height=667)

// Test tablet viewport
mcp__puppeteer__puppeteer_screenshot(name="tablet_view", width=768, height=1024)

// Test desktop viewport
mcp__puppeteer__puppeteer_screenshot(name="desktop_view", width=1920, height=1080)
```

#### 5.7 Error Scenario Testing
```javascript
// Test 404 handling
mcp__puppeteer__puppeteer_navigate(url="http://localhost:PORT/nonexistent")
mcp__puppeteer__puppeteer_screenshot(name="404_error")

// Test authentication redirects
mcp__puppeteer__puppeteer_navigate(url="http://localhost:PORT/admin")
mcp__puppeteer__puppeteer_screenshot(name="auth_redirect")
```

### Phase 6: Quality Assurance & Reporting (2-3 minutes)

#### 6.1 Anti-Pattern Detection
**Automated scanning for common errors:**
```bash
# Check for mixed argument styles
grep -r "hasMany(\"[^\"]*\",[[:space:]]*[a-zA-Z]" app/models/

# Check for query/array confusion
grep -r "ArrayLen(" app/views/
grep -r "for.*in.*\(\)" app/views/

# Check for incorrect naming conventions
find app/models/ -name "*s.cfc" # Should find no plural model names
find app/controllers/ -name "*[^s]Controller.cfc" # Should find no singular controllers
```

#### 6.2 Security Review
**Automatic security validation:**
- CSRF protection verification
- Parameter validation checks
- Input sanitization validation
- Authentication filter coverage
- SQL injection prevention checks

#### 6.3 Performance Analysis
- Query count analysis (N+1 detection)
- Asset optimization validation
- Caching strategy verification
- Database index usage review

#### 6.4 Documentation Compliance
**Verify implementation matches documentation:**
- Compare against templates in `.ai/wheels/snippets/`
- Check adherence to patterns in `.ai/wheels/patterns/`
- Validate against best practices in `.ai/wheels/*/best-practices.md`

#### 6.5 Comprehensive Report Generation
**Final report includes:**
- ✅ **Components Created**: List of all generated files
- ✅ **Tests Passed**: Unit, integration, browser test results
- ✅ **Screenshots**: Evidence of all user flows working
- ✅ **Security Checks**: CSRF, validation, authentication status
- ✅ **Performance Metrics**: Query counts, load times, optimization
- ✅ **Anti-Pattern Status**: Confirmation of error prevention
- ⚠️ **Issues Found**: Any problems requiring attention
- 📋 **Next Steps**: Recommended follow-up tasks

## Error Recovery and Fallback Mechanisms

### Documentation Re-consultation
**If errors occur during any phase:**
1. **Identify error type** (syntax, logic, pattern, security)
2. **Load relevant documentation** from `.ai` folder based on error
3. **Apply documented solution** or alternative pattern
4. **Retry operation** with corrected approach
5. **Log pattern** for future prevention

### Common Error Recovery Flows

#### Mixed Argument Error Recovery
```
Error: "Missing argument name" detected
→ Load: .ai/wheels/troubleshooting/common-errors.md
→ Identify: Mixed argument pattern
→ Fix: Convert all to named arguments OR all to positional
→ Retry: Code generation with consistent style
→ Validate: Syntax check passes
```

#### Query/Array Confusion Recovery
```
Error: ArrayLen() on query object detected
→ Load: .ai/wheels/models/data-handling.md
→ Identify: Query vs Array confusion
→ Fix: Use .recordCount for count, proper loop syntax
→ Retry: View generation with correct patterns
→ Validate: Browser test confirms functionality
```

### Progressive Fallback Strategy
1. **Template-based solution** (primary)
2. **Alternative pattern** from documentation
3. **Simplified approach** (remove complex features)
4. **Manual intervention request** (last resort)

## Success Criteria

### Feature is complete when ALL of the following are true:
- [ ] ✅ All relevant `.ai` documentation was consulted
- [ ] ✅ No anti-patterns detected in generated code
- [ ] ✅ All unit tests pass
- [ ] ✅ All integration tests pass
- [ ] ✅ All browser tests pass
- [ ] ✅ Every button, form, and link has been tested
- [ ] ✅ Responsive design works on mobile, tablet, desktop
- [ ] ✅ Security validations are in place
- [ ] ✅ Performance is acceptable
- [ ] ✅ Error scenarios are handled properly
- [ ] ✅ Screenshot evidence exists for all user flows
- [ ] ✅ Implementation follows CFWheels conventions

### Quality Gates

**No feature may be marked complete if:**
- Any mixed argument styles exist
- Any ArrayLen() calls on model associations exist
- Any browser test fails
- Any security check fails
- Any anti-pattern is detected
- Documentation wasn't consulted for the relevant component type

## Implementation Priority

### Phase 1 Implementation (Core Workflow)
1. Enhanced documentation loading system
2. Anti-pattern prevention integration
3. Template-driven code generation
4. Basic browser testing automation

### Phase 2 Implementation (Advanced Features)
1. Intelligent error recovery
2. Comprehensive testing automation
3. Quality assurance integration
4. Performance analysis

### Phase 3 Implementation (Polish & Optimization)
1. Advanced reporting
2. Pattern learning system
3. Custom template generation
4. Workflow optimization

## Integration with Existing Systems

### MCP Tool Integration
- Leverage existing `mcp__wheels__*` tools
- Enhance with systematic workflow orchestration
- Add documentation loading capabilities
- Integrate browser testing automation

### Documentation System Integration
- Systematically load `.ai` documentation
- Apply patterns from `.ai/wheels/snippets/`
- Validate against `.ai/wheels/patterns/`
- Reference `.ai/wheels/troubleshooting/`

### Testing Framework Integration
- Extend TestBox integration
- Add browser testing with Puppeteer
- Integrate with existing test commands
- Add automated test generation

This specification provides a comprehensive framework for creating a robust, systematic development workflow that produces professional-quality, thoroughly tested CFWheels applications consistently.