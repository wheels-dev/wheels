# Validation Templates

## Description
Pre-code validation checklists, code review templates, and anti-pattern detection for ensuring CFWheels code quality.

## Key Points
- Mandatory validation checklists for each component type
- Code review templates that must be completed before implementation
- Common anti-patterns with examples
- Post-implementation validation scripts

## Pre-Code Validation Checklists

### Model Validation Checklist
**Before writing ANY model code, verify:**

✅ **Documentation Loaded:**
- [ ] Read `.ai/wheels/database/associations/has-many.md`
- [ ] Read `.ai/wheels/core-concepts/mvc-architecture/models.md`
- [ ] Read `.ai/wheels/database/validations/presence.md`
- [ ] Read `.ai/wheels/troubleshooting/common-errors.md`

✅ **Anti-Pattern Check:**
- [ ] Will NOT mix argument styles: `hasMany("comments", dependent="delete")` ❌
- [ ] Will use consistent naming: Model names are SINGULAR
- [ ] Will NOT treat associations as arrays: `ArrayLen(model.association())` ❌

✅ **Implementation Pattern:**
```cfm
component extends="Model" {
    function config() {
        // ALL NAMED arguments
        hasMany(name="comments", dependent="delete");
        belongsTo(name="user");

        // OR ALL POSITIONAL arguments
        hasMany("comments");
        belongsTo("user");

        // Validations
        validatesPresenceOf("title,content");
        validatesUniquenessOf(property="slug");
    }
}
```

### Controller Validation Checklist
**Before writing ANY controller code, verify:**

✅ **Documentation Loaded:**
- [ ] Read `.ai/wheels/controllers/rendering/views.md`
- [ ] Read `.ai/wheels/controllers/filters/authentication.md`
- [ ] Read `.ai/wheels/controllers/params/verification.md`
- [ ] Read `.ai/wheels/troubleshooting/common-errors.md`

✅ **Anti-Pattern Check:**
- [ ] Will NOT mix argument styles: `renderText("error", status=404)` ❌
- [ ] Will use correct naming: Controller names are PLURAL
- [ ] Will NOT treat model results as arrays

✅ **Implementation Pattern:**
```cfm
component extends="Controller" {
    function config() {
        // Filters
        filters(through="authenticate");
        verifies(params="key", paramsTypes="integer");
    }

    function show() {
        // ALL NAMED arguments
        post = model("Post").findByKey(key=params.key, include="comments");

        if (!isObject(post)) {
            renderText(text="Not found", status=404);
        }
    }
}
```

### View Validation Checklist
**Before writing ANY view code, verify:**

✅ **Documentation Loaded:**
- [ ] Read `.ai/wheels/views/layouts/structure.md`
- [ ] Read `.ai/wheels/views/helpers/forms.md`
- [ ] Read `.ai/cfml/control-flow/loops.md`
- [ ] Read `.ai/wheels/troubleshooting/common-errors.md`

✅ **Anti-Pattern Check:**
- [ ] Will NOT loop queries as arrays: `<cfloop array="#query#">` ❌
- [ ] Will NOT use `ArrayLen()` on queries: `ArrayLen(post.comments())` ❌
- [ ] Will use correct query syntax

✅ **Implementation Pattern:**
```cfm
<cfparam name="posts">
<cfoutput>
<!-- Count records correctly -->
<cfif posts.recordCount gt 0>
    <!-- Loop queries correctly -->
    <cfloop query="posts">
        <h2>#posts.title#</h2>
        <p>Comments: #posts.comments().recordCount#</p>
    </cfloop>
<cfelse>
    <p>No posts found.</p>
</cfif>
</cfoutput>
```

### Migration Validation Checklist
**Before writing ANY migration code, verify:**

✅ **Documentation Loaded:**
- [ ] Read `.ai/wheels/database/migrations/creating-migrations.md`
- [ ] Read `.ai/wheels/database/migrations/column-types.md`
- [ ] Read `.ai/wheels/troubleshooting/common-errors.md`

✅ **Anti-Pattern Check:**
- [ ] Will NOT use complex parameter binding for data seeding
- [ ] Will use direct SQL for reliability
- [ ] Will wrap operations in transactions

✅ **Implementation Pattern:**
```cfm
component extends="wheels.migrator.Migration" {
    function up() {
        transaction {
            t = createTable(name="posts", force=false);
            t.string(columnNames="title", allowNull=false);
            t.text(columnNames="content");
            t.timestamps();
            t.create();

            // Data seeding with direct SQL
            execute("INSERT INTO posts (title, content, createdAt, updatedAt)
                     VALUES ('Sample Post', 'Content here...', NOW(), NOW())");
        }
    }
}
```

## Code Review Templates

### Model Review Template
```
BEFORE COMMITTING MODEL CODE, VERIFY:

□ Argument Consistency Check:
  - All hasMany/belongsTo calls use same argument style
  - No mixing of positional and named arguments

□ Association Pattern Check:
  - Model name is SINGULAR (User.cfc, not Users.cfc)
  - Table name in database is PLURAL (users, not user)
  - Association names follow conventions

□ Validation Check:
  - Required validations present
  - No Rails-style validation options that don't exist in CFWheels

□ File Location Check:
  - File in /app/models/ directory
  - Filename matches class name exactly
```

### Controller Review Template
```
BEFORE COMMITTING CONTROLLER CODE, VERIFY:

□ Argument Consistency Check:
  - All model() calls use consistent argument style
  - All renderText/renderView calls use consistent argument style

□ Naming Pattern Check:
  - Controller name is PLURAL (PostsController.cfc)
  - Actions follow RESTful conventions

□ Query Handling Check:
  - No ArrayLen() calls on model results
  - Correct handling of query objects from associations

□ Error Handling Check:
  - Proper 404 handling for missing records
  - Consistent error response format
```

### View Review Template
```
BEFORE COMMITTING VIEW CODE, VERIFY:

□ Query Loop Check:
  - All query loops use <cfloop query="..."> syntax
  - No <cfloop array="..."> on query objects

□ Record Count Check:
  - Using .recordCount property, not ArrayLen()
  - Proper empty state handling

□ Form Helper Check:
  - Using available CFWheels form helpers correctly
  - No Rails-style helpers that don't exist

□ Output Escaping Check:
  - Proper HTML escaping in cfoutput blocks
  - CSRF protection in forms
```

## Anti-Pattern Detection Rules

### Critical Anti-Patterns (WILL BREAK)

**1. Mixed Arguments (Fatal)**
```cfm
❌ BAD:
hasMany("comments", dependent="delete")
model("Post").findByKey(params.key, include="comments")
renderText("Error", status=404)

✅ GOOD:
hasMany(name="comments", dependent="delete")
model("Post").findByKey(key=params.key, include="comments")
renderText(text="Error", status=404)
```

**2. Query as Array (Fatal)**
```cfm
❌ BAD:
ArrayLen(post.comments())
<cfloop array="#comments#" index="comment">
for (comment in post.comments()) {

✅ GOOD:
post.comments().recordCount
<cfloop query="comments">
post.comments().each(function(comment) {
```

**3. Incorrect Naming (Will Cause Issues)**
```cfm
❌ BAD:
Models: Users.cfc, Posts.cfc (should be singular)
Controllers: UserController.cfc, PostController.cfc (should be plural)

✅ GOOD:
Models: User.cfc, Post.cfc
Controllers: UsersController.cfc, PostsController.cfc
```

### Warning Anti-Patterns (May Break)

**1. Rails-Style Associations**
```cfm
❌ AVOID:
hasMany("comments", className="Comment", foreignKey="post_id")

✅ PREFER:
hasMany("comments") // CFWheels handles conventions
```

**2. Complex Migration Parameters**
```cfm
❌ AVOID:
execute(sql="INSERT INTO posts (title) VALUES (?)", parameters=[{value=title}])

✅ PREFER:
execute("INSERT INTO posts (title, createdAt, updatedAt) VALUES ('Title', NOW(), NOW())")
```

## Post-Implementation Validation Scripts

### Manual Validation Checklist
```bash
# 1. Syntax Check
wheels server start --validate

# 2. Test Run
wheels test run

# 3. Manual Pattern Check
# Search for anti-patterns in code:
grep -r "hasMany(" app/models/ # Check for consistent arguments
grep -r "ArrayLen(" app/views/ # Check for query/array confusion
grep -r "renderText(" app/controllers/ # Check for consistent arguments
```

### Validation Commands for CI/CD
```bash
#!/bin/bash
# Pre-commit validation script

echo "🔍 Checking for CFWheels anti-patterns..."

# Check for mixed arguments
if grep -r "hasMany(\"[^\"]*\",[[:space:]]*[a-zA-Z]" app/models/; then
    echo "❌ ERROR: Mixed arguments detected in hasMany calls"
    exit 1
fi

# Check for query/array confusion
if grep -r "ArrayLen(" app/views/ | grep -v "\.js"; then
    echo "❌ ERROR: ArrayLen() detected in views - likely query/array confusion"
    exit 1
fi

# Check for naming conventions
if find app/models/ -name "*s.cfc"; then
    echo "❌ ERROR: Plural model names detected - models should be singular"
    exit 1
fi

echo "✅ CFWheels pattern validation passed"
```

## Integration with Development Workflow

### IDE Integration
Configure your IDE to show warnings for:
- Mixed argument patterns
- ArrayLen() calls in view files
- Plural model names
- Query loops using array syntax

### Pre-Commit Hooks
Add validation script to git pre-commit hook:
```bash
#!/bin/sh
# .git/hooks/pre-commit
./validate-cfwheels-patterns.sh
```

### Documentation References
When validation fails, direct developers to:
- `.ai/wheels/troubleshooting/common-errors.md` for error solutions
- `.ai/wheels/patterns/` for correct implementation patterns
- `.ai/wheels/snippets/` for code examples

## Related
- [Common Errors](../troubleshooting/common-errors.md)
- [Controller Patterns](../controllers/)
- [Model Patterns](../database/)
- [View Patterns](../views/)

## Important Notes
- These validations are MANDATORY, not optional
- Each component type has specific anti-patterns to avoid
- Post-implementation validation should be automated where possible
- New anti-patterns discovered should be added to this document immediately