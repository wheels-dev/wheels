# Claude Code Integration Guide

🚨 **CRITICAL ENFORCEMENT DOCUMENT** 🚨

This file provides MANDATORY instructions for Claude Code and other AI assistants to ensure they ALWAYS consult the comprehensive documentation in this `.ai` folder BEFORE writing any code.

⛔ **VIOLATION OF THESE INSTRUCTIONS WILL RESULT IN BROKEN CODE** ⛔

## Documentation Integration Strategy

### Task-to-Documentation Mapping

When working on specific tasks, AI assistants should load the following documentation in order:

#### 🏗️ Model Development
**MANDATORY Reading Order (MUST READ ALL):**
1. `.ai/wheels/troubleshooting/common-errors.md` - CRITICAL ERROR PREVENTION
2. `.ai/wheels/database/associations/has-many.md` - Association patterns
3. `.ai/wheels/core-concepts/mvc-architecture/models.md` - Model fundamentals
4. `.ai/cfml/components/component-basics.md` - CFC basics
5. `.ai/wheels/patterns/validation-templates.md` - Validation checklists
6. `.ai/wheels/snippets/model-snippets.md` - Code examples

**CRITICAL Anti-Pattern Check (MUST VERIFY):**
- [ ] ❌ NO mixed arguments: `hasMany("comments", dependent="delete")`
- [ ] ✅ Consistent arguments: ALL named OR ALL positional
- [ ] ❌ NO ArrayLen() on associations: `ArrayLen(model.comments())`
- [ ] ✅ Use .recordCount: `model.comments().recordCount`
- [ ] ✅ Singular naming: User.cfc (not Users.cfc)
- [ ] ✅ Extends "Model" class
- [ ] ✅ Proper associations and validations

#### 🎮 Controller Development
**MANDATORY Reading Order (MUST READ ALL):**
1. `.ai/wheels/troubleshooting/common-errors.md` - CRITICAL ERROR PREVENTION
2. `.ai/wheels/controllers/rendering/views.md` - View rendering
3. `.ai/wheels/controllers/filters/authentication.md` - Authentication
4. `.ai/wheels/controllers/params/verification.md` - Parameter handling
5. `.ai/cfml/syntax/cfscript-vs-tags.md` - CFScript syntax
6. `.ai/wheels/patterns/validation-templates.md` - Validation checklists
7. `.ai/wheels/snippets/controller-snippets.md` - Code examples

**CRITICAL Anti-Pattern Check (MUST VERIFY):**
- [ ] ❌ NO mixed arguments: `renderText("error", status=404)`
- [ ] ✅ Consistent arguments: ALL named OR ALL positional
- [ ] ❌ NO ArrayLen() on model results
- [ ] ✅ Use .recordCount on queries
- [ ] ✅ Plural naming: PostsController.cfc (not PostController.cfc)
- [ ] ✅ Extends "Controller" class
- [ ] ✅ Proper parameter verification

#### 📄 View Development
**MANDATORY Reading Order (MUST READ ALL):**
1. `.ai/wheels/troubleshooting/common-errors.md` - CRITICAL ERROR PREVENTION
2. `.ai/wheels/views/layouts/structure.md` - Layout basics
3. `.ai/cfml/control-flow/loops.md` - Loop syntax (QUERY vs ARRAY)
4. `.ai/wheels/views/helpers/forms.md` - Form helpers
5. `.ai/wheels/patterns/validation-templates.md` - Validation checklists

**CRITICAL Anti-Pattern Check (MUST VERIFY):**
- [ ] ❌ NO array loops on queries: `<cfloop array="#query#">`
- [ ] ✅ Use query loops: `<cfloop query="queryName">`
- [ ] ❌ NO ArrayLen() on queries: `ArrayLen(posts)`
- [ ] ✅ Use .recordCount: `posts.recordCount`
- [ ] ✅ Proper HTML escaping in cfoutput
- [ ] ✅ CSRF protection in forms

#### 🗃️ Database Migration
**MANDATORY Reading Order (MUST READ ALL):**
1. `.ai/wheels/troubleshooting/common-errors.md` - CRITICAL ERROR PREVENTION
2. `.ai/wheels/database/migrations/creating-migrations.md` - Migration basics
3. `.ai/wheels/database/migrations/column-types.md` - Column types
4. `.ai/wheels/patterns/validation-templates.md` - Validation checklists

**CRITICAL Anti-Pattern Check (MUST VERIFY):**
- [ ] ❌ NO complex parameter binding for data seeding
- [ ] ✅ Use direct SQL for data insertion
- [ ] ✅ Wrap operations in transactions
- [ ] ✅ Extends "Migration" class
- [ ] ✅ Implements both up() and down()

#### 🔧 Configuration
**Required Reading Order:**
1. `.ai/wheels/configuration/settings.md` - Framework settings
2. `.ai/wheels/configuration/environments.md` - Environment configs
3. `.ai/wheels/configuration/routing.md` - Route configuration

**Validation Checklist:**
- [ ] Uses proper environment structure
- [ ] Follows security best practices
- [ ] Implements appropriate routing

### 🚨 MANDATORY Pre-Implementation Workflow 🚨

**STEP 1: EMERGENCY ERROR PREVENTION (ALWAYS FIRST)**
```bash
# CRITICAL: Read this FIRST to prevent common errors
READ .ai/wheels/troubleshooting/common-errors.md
READ .ai/wheels/patterns/validation-templates.md
```

**STEP 2: Task-Specific Documentation Loading**
```bash
# Load ALL relevant documentation based on task:
if [model_work]; then
    READ .ai/wheels/database/associations/has-many.md
    READ .ai/wheels/core-concepts/mvc-architecture/models.md
    READ .ai/cfml/components/component-basics.md

if [controller_work]; then
    READ .ai/wheels/controllers/rendering/views.md
    READ .ai/wheels/controllers/filters/authentication.md
    READ .ai/cfml/syntax/cfscript-vs-tags.md

if [view_work]; then
    READ .ai/wheels/views/layouts/structure.md
    READ .ai/cfml/control-flow/loops.md
    READ .ai/wheels/views/helpers/forms.md

if [migration_work]; then
    READ .ai/wheels/database/migrations/creating-migrations.md
    READ .ai/wheels/database/migrations/column-types.md
```

**STEP 3: MANDATORY Anti-Pattern Validation**
- ✅ Verify NO mixed argument styles
- ✅ Verify NO ArrayLen() on queries
- ✅ Verify correct naming conventions
- ✅ Verify proper loop syntax for data types

**STEP 4: Code Implementation with Continuous Checking**
- Use code templates from `.ai/wheels/snippets/`
- Follow patterns from `.ai/wheels/patterns/`
- Check against validation templates while coding

**STEP 5: MANDATORY Post-Implementation Validation**
```bash
wheels server start --validate
wheels test run
# Manual anti-pattern check against validation templates
```

## Documentation Structure Guide

### CFML Language Documentation (`.ai/cfml/`)
- **Purpose**: Core CFML language concepts
- **When to Use**: When you need to understand CFML syntax, data types, or language features
- **Key Files**:
  - `syntax/cfscript.md` - Modern CFScript syntax
  - `data-types/structures.md` - Working with structs
  - `components/basics.md` - CFC fundamentals
  - `best-practices/modern-cfml.md` - Contemporary CFML patterns

### Wheels Framework Documentation (`.ai/wheels/`)
- **Purpose**: Framework-specific patterns and conventions
- **When to Use**: For any Wheels-specific development task
- **Key Directories**:
  - `core-concepts/` - MVC architecture and conventions
  - `database/` - ORM, models, migrations
  - `controllers/` - Request handling patterns
  - `views/` - Template and rendering patterns
  - `patterns/` - Common development patterns
  - `snippets/` - Ready-to-use code examples

## Integration Examples

### Example 1: Creating a User Model
**Before Implementation:**
1. Read `.ai/wheels/database/models.md`
2. Review `.ai/wheels/snippets/models/user-example.md`
3. Check `.ai/wheels/security/authentication.md`

**Implementation Validation:**
- Uses singular naming (`User.cfc`, not `Users.cfc`)
- Extends `Model` class
- Includes proper validations
- Implements security best practices

### Example 2: Building a REST API Controller
**Before Implementation:**
1. Read `.ai/wheels/controllers/api.md`
2. Review `.ai/wheels/patterns/rest-api.md`
3. Check `.ai/wheels/security/csrf.md`

**Implementation Validation:**
- Uses plural naming (`UsersController.cfc`)
- Implements proper content negotiation
- Includes authentication filters
- Follows RESTful conventions

## AI Assistant Instructions

### 🛑 MANDATORY Pre-Code Actions (NO EXCEPTIONS)
1. **ALWAYS** read `.ai/wheels/troubleshooting/common-errors.md` FIRST
2. **ALWAYS** read `.ai/wheels/patterns/validation-templates.md` SECOND
3. **LOAD** ALL task-specific documentation (see mapping above)
4. **VALIDATE** against anti-patterns before writing any code
5. **REFERENCE** code examples from snippets as templates
6. **CHECK** implementation against validation templates continuously

### Code Quality Assurance
- **CFML Standards**: Follow `.ai/cfml/best-practices/`
- **Wheels Conventions**: Adhere to `.ai/wheels/core-concepts/`
- **Security Requirements**: Implement `.ai/wheels/security/` guidelines
- **Performance Patterns**: Use `.ai/wheels/patterns/performance.md`

### Documentation Updates
When creating new patterns or solutions:
1. Document the pattern in appropriate `.ai/` subdirectory
2. Add code examples to `.ai/wheels/snippets/`
3. Update relevant mapping files
4. Test the documentation with other AI assistants

## MCP Integration (Emergency Fallback)

If `.ai/` folder is not accessible, use MCP resources from native CFML MCP server at `/wheels/mcp`:

**CRITICAL Resources (Load These First):**
```bash
mcp resource read wheels://.ai/wheels/troubleshooting/common-errors
mcp resource read wheels://.ai/wheels/patterns/validation-templates
```

**Task-Specific Resources:**
```bash
# For model work:
mcp resource read wheels://.ai/wheels/database/associations/has-many
mcp resource read wheels://.ai/wheels/core-concepts/mvc-architecture/models

# For controller work:
mcp resource read wheels://.ai/wheels/controllers/rendering/views
mcp resource read wheels://.ai/wheels/controllers/filters/authentication

# For view work:
mcp resource read wheels://.ai/wheels/views/layouts/structure
mcp resource read wheels://.ai/cfml/control-flow/loops

# For migration work:
mcp resource read wheels://.ai/wheels/database/migrations/creating-migrations
```

**Available MCP Resources:**
- `wheels://.ai/cfml/syntax/*` - CFML syntax documentation
- `wheels://.ai/wheels/patterns/*` - Framework patterns
- `wheels://.ai/wheels/snippets/*` - Code examples
- `wheels://.ai/wheels/troubleshooting/*` - Error prevention
- `wheels://.ai/project/context` - Current project context

## MANDATORY Validation Commands

**BEFORE committing ANY code, run these validation commands:**

```bash
# 1. Syntax validation
wheels server start --validate

# 2. Test validation
wheels test run

# 3. Anti-pattern detection (manual)
grep -r "hasMany(\"[^\"]*\",[[:space:]]*[a-zA-Z]" app/models/  # Check mixed args
grep -r "ArrayLen(" app/views/  # Check query/array confusion
find app/models/ -name "*s.cfc"  # Check plural model names

# 4. Manual review using validation templates
# Check implementation against .ai/wheels/patterns/validation-templates.md
```

**If ANY validation fails:**
1. Consult `.ai/wheels/troubleshooting/common-errors.md`
2. Review `.ai/wheels/patterns/validation-templates.md`
3. Fix errors before proceeding
4. Re-run validation until all checks pass

## Best Practices for AI Assistants

1. **Documentation First**: Always consult documentation before coding
2. **Pattern Consistency**: Follow established patterns from `.ai/wheels/patterns/`
3. **Security Awareness**: Apply security practices from `.ai/wheels/security/`
4. **Convention Adherence**: Follow Wheels naming and structure conventions
5. **Example Usage**: Use code examples from `.ai/wheels/snippets/` as templates
6. **Validation**: Test implementations against documented standards

This integration ensures that all AI-generated code adheres to the comprehensive knowledge base contained in the `.ai` documentation folder.