# Pre-Implementation Workflow

## Description
Mandatory step-by-step workflow that AI assistants MUST follow before writing any Wheels code. This workflow prevents the two most common Wheels errors through systematic documentation consultation and validation.

## Key Points
- Decision tree for determining documentation requirements
- Mandatory reading lists with specific file paths
- Code templates that must be used as starting points
- Post-implementation validation requirements
- Error prevention through pattern recognition

## 🚨 CRITICAL: This Workflow is MANDATORY, Not Optional 🚨

**VIOLATION OF THIS WORKFLOW WILL RESULT IN BROKEN CODE**

## Phase 1: Emergency Error Prevention (ALWAYS FIRST)

### 🛑 STOP: Load Critical Error Documentation
Before ANY code analysis or planning, read these files:

```bash
MUST READ FIRST:
1. .ai/wheels/troubleshooting/common-errors.md
2. .ai/wheels/patterns/validation-templates.md
```

**Purpose:** Prevent the two most common Wheels errors:
1. **Argument mixing** (`hasMany("comments", dependent="delete")`)
2. **Query/Array confusion** (`ArrayLen(model.comments())`)

### ⚠️ Error Pattern Recognition Training
After reading the error documentation, you MUST be able to identify these patterns:

**FATAL Pattern #1 - Mixed Arguments:**
```cfm
❌ hasMany("comments", dependent="delete")     // WILL BREAK
❌ model("Post").findByKey(params.key, include="comments")  // WILL BREAK
❌ renderText("Error", status=404)             // WILL BREAK
```

**FATAL Pattern #2 - Query as Array:**
```cfm
❌ ArrayLen(post.comments())                   // WILL BREAK
❌ <cfloop array="#comments#" index="comment">  // WILL BREAK
❌ for (comment in post.comments()) {          // MAY BREAK
```

## Phase 2: Task Type Identification and Documentation Loading

### 🔍 Task Type Decision Tree

Use this decision tree to determine what documentation to load:

```
START: What type of code are you writing?
│
├── Creating/Modifying a Model (*.cfc in /app/models/)
│   └── → Go to MODEL WORKFLOW
│
├── Creating/Modifying a Controller (*.cfc in /app/controllers/)
│   └── → Go to CONTROLLER WORKFLOW
│
├── Creating/Modifying a View (*.cfm in /app/views/)
│   └── → Go to VIEW WORKFLOW
│
├── Creating/Modifying a Migration (*.cfc in /app/migrator/migrations/)
│   └── → Go to MIGRATION WORKFLOW
│
├── Working with Forms or Form Helpers
│   └── → Go to FORM WORKFLOW
│
├── Working with Queries or Database Operations
│   └── → Go to QUERY WORKFLOW
│
├── Working with Associations (hasMany, belongsTo, etc.)
│   └── → Go to ASSOCIATION WORKFLOW
│
└── Multiple types or complex feature
    └── → Go to MULTI-COMPONENT WORKFLOW
```

### 📚 Mandatory Reading Lists by Task Type

#### MODEL WORKFLOW
**Required Reading Order (ALL files MUST be read):**
```bash
1. .ai/wheels/troubleshooting/common-errors.md          # Error prevention
2. .ai/wheels/patterns/validation-templates.md          # Validation checklist
3. .ai/wheels/database/associations/has-many.md         # Association patterns
4. .ai/wheels/core-concepts/mvc-architecture/models.md  # Model fundamentals
5. .ai/cfml/components/component-basics.md              # CFC syntax
6. .ai/wheels/snippets/model-snippets.md                # Code examples
```

**Anti-Pattern Checklist Before Writing:**
- [ ] Will NOT mix argument styles in associations
- [ ] Will use SINGULAR naming (User.cfc, not Users.cfc)
- [ ] Will NOT treat associations as arrays
- [ ] Will extend "Model" class
- [ ] Will use proper validation syntax

#### CONTROLLER WORKFLOW
**Required Reading Order (ALL files MUST be read):**
```bash
1. .ai/wheels/troubleshooting/common-errors.md          # Error prevention
2. .ai/wheels/patterns/validation-templates.md          # Validation checklist
3. .ai/wheels/controllers/rendering/views.md            # View rendering
4. .ai/wheels/controllers/filters/authentication.md     # Authentication
5. .ai/wheels/controllers/params/verification.md        # Parameter handling
6. .ai/cfml/syntax/cfscript-vs-tags.md                 # CFScript syntax
7. .ai/wheels/snippets/controller-snippets.md          # Code examples
```

**Anti-Pattern Checklist Before Writing:**
- [ ] Will NOT mix argument styles in model calls
- [ ] Will use PLURAL naming (PostsController.cfc)
- [ ] Will NOT treat model results as arrays
- [ ] Will extend "Controller" class
- [ ] Will handle 404s properly

#### VIEW WORKFLOW
**Required Reading Order (ALL files MUST be read):**
```bash
1. .ai/wheels/troubleshooting/common-errors.md          # Error prevention
2. .ai/wheels/patterns/validation-templates.md          # Validation checklist
3. .ai/wheels/views/layouts/structure.md                # Layout patterns
4. .ai/cfml/control-flow/loops.md                      # Loop syntax
5. .ai/wheels/views/helpers/forms.md                   # Form helpers
```

**Anti-Pattern Checklist Before Writing:**
- [ ] Will NOT loop queries as arrays
- [ ] Will NOT use ArrayLen() on queries
- [ ] Will use `<cfloop query="...">` syntax
- [ ] Will use `.recordCount` for counts
- [ ] Will properly escape output

#### MIGRATION WORKFLOW
**Required Reading Order (ALL files MUST be read):**
```bash
1. .ai/wheels/troubleshooting/common-errors.md          # Error prevention
2. .ai/wheels/patterns/validation-templates.md          # Validation checklist
3. .ai/wheels/database/migrations/creating-migrations.md # Migration basics
4. .ai/wheels/database/migrations/column-types.md       # Column types
```

**Anti-Pattern Checklist Before Writing:**
- [ ] Will NOT use complex parameter binding for data seeding
- [ ] Will use direct SQL for data insertion
- [ ] Will wrap operations in transactions
- [ ] Will extend "Migration" class
- [ ] Will implement both up() and down()

#### ASSOCIATION WORKFLOW
**Required Reading Order (ALL files MUST be read):**
```bash
1. .ai/wheels/troubleshooting/common-errors.md          # Error prevention
2. .ai/wheels/patterns/validation-templates.md          # Validation checklist
3. .ai/wheels/database/associations/has-many.md         # hasMany patterns
4. .ai/wheels/database/associations/belongs-to.md       # belongsTo patterns
5. .ai/wheels/database/associations/has-one.md          # hasOne patterns
6. .ai/cfml/control-flow/loops.md                      # Loop syntax for queries
```

**Anti-Pattern Checklist Before Writing:**
- [ ] Will NOT mix argument styles in association calls
- [ ] Will NOT treat association results as arrays
- [ ] Will use consistent argument syntax throughout
- [ ] Will understand associations return QUERIES
- [ ] Will use proper loop syntax for query results

#### FORM WORKFLOW
**Required Reading Order (ALL files MUST be read):**
```bash
1. .ai/wheels/troubleshooting/common-errors.md          # Error prevention
2. .ai/wheels/patterns/validation-templates.md          # Validation checklist
3. .ai/wheels/views/helpers/forms.md                   # Form helpers
4. .ai/wheels/security/csrf-protection.md              # CSRF protection
```

#### QUERY WORKFLOW
**Required Reading Order (ALL files MUST be read):**
```bash
1. .ai/wheels/troubleshooting/common-errors.md          # Error prevention
2. .ai/cfml/database/query-basics.md                   # Query fundamentals
3. .ai/cfml/control-flow/loops.md                      # Loop syntax
4. .ai/wheels/database/queries/finding-records.md      # Finding records
```

## Phase 3: Code Template Selection

### 📋 Mandatory Code Templates

Based on your task type, you MUST use these templates as starting points:

#### Model Template (MANDATORY)
```cfm
component extends="Model" {
    function config() {
        // Choose ONE argument style and stick with it

        // Option 1: ALL NAMED arguments
        hasMany(name="comments", dependent="delete");
        belongsTo(name="user");
        validatesPresenceOf(properties="title,content");

        // Option 2: ALL POSITIONAL arguments
        hasMany("comments");
        belongsTo("user");
        validatesPresenceOf("title,content");

        // NEVER mix styles within the same component
    }

    // Custom methods using consistent argument style
    function findBySlug(required string slug) {
        return findOne(where="slug = '#arguments.slug#'");
    }
}
```

#### Controller Template (MANDATORY)
```cfm
component extends="Controller" {
    function config() {
        // Use consistent argument style
        filters(through="authenticate");
        verifies(params="key", paramsTypes="integer");
    }

    function show() {
        // ALL NAMED arguments
        post = model("Post").findByKey(key=params.key, include="comments");

        if (!isObject(post)) {
            renderText(text="Not found", status=404);
            return;
        }

        // Association returns QUERY, not array
        commentCount = post.comments().recordCount;
    }
}
```

#### View Template (MANDATORY)
```cfm
<cfparam name="posts">
<cfoutput>
<!-- Check record count correctly -->
<cfif posts.recordCount gt 0>
    <!-- Loop query correctly -->
    <cfloop query="posts">
        <h2>#posts.title#</h2>
        <!-- Access associations correctly -->
        <p>Comments: #posts.comments().recordCount#</p>
    </cfloop>
<cfelse>
    <p>No posts found.</p>
</cfif>
</cfoutput>
```

#### Migration Template (MANDATORY)
```cfm
component extends="wheels.migrator.Migration" {
    function up() {
        transaction {
            t = createTable(name="posts", force=false);
            t.string(columnNames="title", allowNull=false);
            t.text(columnNames="content");
            t.timestamps();
            t.create();

            // Use direct SQL for data seeding
            execute("INSERT INTO posts (title, content, createdAt, updatedAt)
                     VALUES ('Sample Post', 'Content here...', NOW(), NOW())");
        }
    }

    function down() {
        dropTable("posts");
    }
}
```

## Phase 4: Implementation with Continuous Validation

### 🔄 While Writing Code Checklist

For EVERY function call you write, check:

**Argument Consistency:**
- [ ] Are all arguments named? OR are all arguments positional?
- [ ] Am I mixing styles? (If yes, STOP and fix)

**Data Type Awareness:**
- [ ] Am I calling ArrayLen() on something that might be a query?
- [ ] Am I looping something as an array that might be a query?
- [ ] Am I using .recordCount for query counts?

**Naming Conventions:**
- [ ] Is my model name singular? (User.cfc, Post.cfc)
- [ ] Is my controller name plural? (UsersController.cfc, PostsController.cfc)

### 🚨 Emergency Stops During Implementation

**STOP and consult documentation if you:**
1. Get ANY error about "Missing argument name"
2. Get ANY error about "Can't cast Object type [Query] to Array"
3. Are unsure about argument syntax for any Wheels function
4. Are looping over model results or associations
5. Are counting records or checking if data exists

**When in doubt:**
1. Re-read `.ai/wheels/troubleshooting/common-errors.md`
2. Check `.ai/wheels/patterns/validation-templates.md`
3. Use the templates above as reference

## Phase 5: Post-Implementation Validation

### ✅ MANDATORY Validation Steps

**BEFORE considering your code complete:**

1. **Syntax Validation:**
   ```bash
   wheels server start --validate
   ```

2. **Test Validation:**
   ```bash
   wheels test run
   ```

3. **Anti-Pattern Detection:**
   ```bash
   # Check for mixed arguments
   grep -r "hasMany(\"[^\"]*\",[[:space:]]*[a-zA-Z]" app/models/

   # Check for query/array confusion
   grep -r "ArrayLen(" app/views/

   # Check for plural model names
   find app/models/ -name "*s.cfc"
   ```

4. **Manual Review Against Templates:**
   - Compare your code against the templates above
   - Verify all checklists are satisfied
   - Ensure consistent argument styles throughout

### 🚫 Code Review Rejection Criteria

Your code WILL BE REJECTED if:
- [ ] Any mixed argument styles found
- [ ] Any ArrayLen() calls on associations or model results
- [ ] Any array-style loops on query objects
- [ ] Incorrect naming conventions (plural models, singular controllers)
- [ ] Missing error handling for 404s
- [ ] No transaction wrapping for migrations

## Emergency Procedures

### 🆘 If You Encounter Unknown Patterns

**Step 1:** STOP writing code immediately
**Step 2:** Search for similar patterns in `.ai/wheels/snippets/`
**Step 3:** If not found, search in `.ai/wheels/patterns/`
**Step 4:** If still not found, consult `.ai/wheels/core-concepts/`
**Step 5:** Document new pattern for future reference

### 🆘 If You Get Errors

**Step 1:** Check error message against `.ai/wheels/troubleshooting/common-errors.md`
**Step 2:** If error matches known patterns, apply documented solution
**Step 3:** If new error, add to common-errors.md documentation
**Step 4:** Re-run validation workflow

### 🆘 If Documentation is Missing

**Use MCP Fallback:**
```bash
mcp resource read wheels://.ai/wheels/troubleshooting/common-errors
mcp resource read wheels://.ai/wheels/patterns/validation-templates
mcp resource read wheels://.ai/wheels/[relevant-path]
```

## Workflow Compliance Verification

### Self-Assessment Checklist

Before claiming workflow compliance, verify:

- [ ] I read ALL mandatory documentation for my task type
- [ ] I completed ALL anti-pattern checklists
- [ ] I used the mandatory code templates as starting points
- [ ] I followed continuous validation during implementation
- [ ] I completed ALL post-implementation validation steps
- [ ] I can explain why my code won't trigger the two common errors

### Peer Review Checklist

When reviewing AI-generated code, verify:

- [ ] Documentation reading requirements were met
- [ ] Anti-pattern checklists were completed
- [ ] Code follows mandatory templates
- [ ] No mixed argument styles present
- [ ] No query/array confusion present
- [ ] Proper naming conventions followed
- [ ] Error handling implemented correctly

## Related Documentation

- [Common Errors](../troubleshooting/common-errors.md) - CRITICAL first read
- [Validation Templates](../patterns/validation-templates.md) - Mandatory checklists
- [Code Snippets](../snippets/) - Template examples
- [MVC Architecture](../core-concepts/mvc-architecture/) - Framework fundamentals

## Important Notes

- This workflow is MANDATORY, not optional
- Each phase must be completed before proceeding to the next
- Skipping steps WILL result in broken code
- New error patterns must be documented immediately
- Workflow compliance is required for all AI-generated code
- This workflow prevents 90%+ of Wheels development errors