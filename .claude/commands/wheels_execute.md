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

The `/wheels_execute` command implements a comprehensive 6-phase development workflow:

1. **Pre-Flight Documentation Loading** - Systematically load relevant patterns from `.ai` folder
2. **Intelligent Analysis & Planning** - Parse requirements and create detailed implementation plan
3. **Template-Driven Implementation** - Generate code using established patterns with error recovery
4. **Multi-Level Testing** - Unit tests, integration tests, and validation
5. **Comprehensive Browser Testing** - Test every button, form, and link automatically
6. **Quality Assurance & Reporting** - Anti-pattern detection and final validation

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

### Phase 4: Multi-Level Testing (3-8 minutes)
- **Unit Testing**: Test individual models, controllers, and their methods
- **Integration Testing**: Test component interactions and CRUD operations
- **Migration Testing**: Verify database changes work correctly
- **Syntax Validation**: Check CFWheels-specific syntax patterns

### Phase 5: Comprehensive Browser Testing (5-10 minutes)
- **Server Verification**: Ensure development server is running
- **Navigation Testing**: Test all menu links, buttons, and navigation paths
- **CRUD Flow Testing**: Test complete create, read, update, delete operations
- **Form Testing**: Submit all forms, test validation scenarios
- **Interactive Testing**: Test JavaScript, Alpine.js, HTMX functionality
- **Responsive Testing**: Validate mobile, tablet, desktop layouts
- **Error Scenario Testing**: Test 404s, validation failures, edge cases

### Phase 6: Quality Assurance & Reporting (2-3 minutes)
- **Anti-Pattern Detection**: Scan for mixed arguments, query/array confusion
- **Security Review**: Verify CSRF, authentication, input validation
- **Performance Analysis**: Check for N+1 queries, optimization opportunities
- **Documentation Compliance**: Validate against `.ai` documentation patterns
- **Comprehensive Reporting**: Generate detailed results with screenshots

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
- **Browser Testing**: Full Puppeteer integration for comprehensive testing
- **Reporting**: Rich, detailed reporting with screenshots and explanations
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