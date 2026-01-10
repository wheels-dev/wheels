# Wheels Claude Skills

This directory contains **Claude Code Skills** specifically designed for Wheels framework development. Skills are specialized capabilities that Claude automatically activates based on your requests.

## What are Skills?

Skills are modular AI capabilities that:
- **Activate automatically** based on task context
- **Provide specialized knowledge** for specific development tasks
- **Prevent common errors** before code is written
- **Generate code following Wheels conventions**
- **Work together** to handle complex development workflows

## Available Skills

### Core Generator Skills

#### 1. [wheels-model-generator](wheels-model-generator/SKILL.md)
Generate Wheels ORM models with proper validations, associations, and methods.

**Activates when:**
- Creating new models
- Adding associations (hasMany, belongsTo, hasManyThrough)
- Adding validations
- Implementing custom model methods

**Key Features:**
- Association patterns (one-to-many, many-to-many)
- Validation patterns (presence, uniqueness, format, length)
- Callback implementation
- Custom method templates
- Anti-pattern prevention (mixed arguments)

#### 2. [wheels-controller-generator](wheels-controller-generator/SKILL.md)
Generate Wheels MVC controllers with CRUD actions, filters, and proper rendering.

**Activates when:**
- Creating new controllers
- Adding CRUD actions
- Implementing filters (authentication, authorization)
- Handling form submissions
- Rendering views or JSON

**Key Features:**
- Complete CRUD templates
- Authentication/authorization filters
- Parameter verification
- Flash messages
- API controller patterns
- Nested resource handling

#### 3. [wheels-view-generator](wheels-view-generator/SKILL.md)
Generate Wheels view templates with proper query handling and form helpers.

**Activates when:**
- Creating views (index, show, new, edit)
- Creating forms
- Displaying associated data
- Creating layouts or partials

**Key Features:**
- Index view templates (list views)
- Show view templates (detail views)
- Form view templates (new/edit)
- Layout templates
- Proper query handling (prevents query/array confusion)
- Form helper usage (textField with type, not emailField)
- Association display patterns

#### 4. [wheels-migration-generator](wheels-migration-generator/SKILL.md)
Generate database-agnostic Wheels migrations for schema changes.

**Activates when:**
- Creating database tables
- Adding/modifying columns
- Adding indexes or foreign keys
- Changing database schema

**Key Features:**
- Create table migrations
- Alter table migrations
- Database-agnostic date handling (prevents MySQL-specific functions)
- Join table patterns
- Index and foreign key management

### Quality Assurance Skills

#### 5. [wheels-anti-pattern-detector](wheels-anti-pattern-detector/SKILL.md)
**Automatically detect and prevent common Wheels errors before code is written.**

**Activates during:**
- ANY Wheels code generation
- Model generation
- Controller generation
- View generation
- Migration generation

**Detects:**
1. Mixed argument styles (`hasMany("comments", dependent="delete")`)
2. Query/array confusion (`ArrayLen(post.comments())`)
3. Association access in query loops
4. Non-existent form helpers (`emailField()`)
5. Rails-style nested routing
6. Database-specific SQL functions (`NOW()`, `DATE_SUB()`)
7. Missing CSRF protection
8. Inconsistent parameter styles

**Auto-fixes all detected issues before writing files!**

#### 6. [wheels-test-generator](wheels-test-generator/SKILL.md)
Generate TestBox BDD test specs for models, controllers, and integrations.

**Activates when:**
- Creating tests/specs
- Testing models or controllers
- Writing integration tests

**Key Features:**
- Model test templates (validations, associations)
- Controller test templates (actions, filters)
- Integration test templates (workflows)
- Proper setup/teardown patterns

#### 7. [wheels-debugging](wheels-debugging/SKILL.md)
Troubleshoot common Wheels errors and provide debugging guidance.

**Activates when:**
- Encountering errors
- Debugging issues
- Investigating unexpected behavior

**Provides:**
- Common error solutions
- Debugging strategies
- Error message interpretation
- Fix recommendations

### Advanced Skills

#### 8. [wheels-refactoring](wheels-refactoring/SKILL.md)
Refactor code for better performance, security, and maintainability.

**Activates when:**
- Optimizing code
- Fixing anti-patterns
- Improving performance
- Enhancing security

**Patterns:**
- N+1 query elimination
- Eager loading optimization
- Security hardening
- Code quality improvements

#### 9. [wheels-api-generator](wheels-api-generator/SKILL.md)
Generate RESTful API controllers with JSON responses and proper HTTP status codes.

**Activates when:**
- Creating API endpoints
- Building JSON APIs
- Implementing web services

**Features:**
- RESTful controller templates
- Proper HTTP status codes
- API authentication
- Error handling

#### 10. [wheels-auth-generator](wheels-auth-generator/SKILL.md)
Generate authentication system with user model, sessions, and password hashing.

**Activates when:**
- Implementing user authentication
- Creating login/logout system
- Managing sessions

**Features:**
- User model with password hashing
- Sessions controller
- Authentication filters
- Secure password handling

#### 11. [wheels-deployment](wheels-deployment/SKILL.md)
Configure applications for production deployment with security and performance.

**Activates when:**
- Preparing for production
- Configuring servers
- Hardening security

**Provides:**
- Production configuration
- Security checklist
- Performance optimization
- Environment settings

#### 12. [wheels-documentation-generator](wheels-documentation-generator/SKILL.md)
Generate documentation comments, READMEs, and API documentation.

**Activates when:**
- Documenting code
- Creating READMEs
- Generating API docs

**Features:**
- Function documentation templates
- Model documentation
- README templates
- API documentation

#### 13. [wheels-plugin-generator](wheels-plugin-generator/SKILL.md)
Generate Wheels plugins with proper structure and ForgeBox packaging.

**Activates when:**
- Creating plugins
- Extending Wheels functionality
- Packaging reusable components

**Features:**
- Plugin directory structure
- Plugin configuration
- ForgeBox packaging
- Event handlers
- Mixin methods

#### 14. [wheels-email-generator](wheels-email-generator/SKILL.md)
Generate email functionality including mailers, templates, and configuration.

**Activates when:**
- Sending emails
- Creating notifications
- Implementing transactional emails

**Features:**
- Mailer controllers
- Email templates (HTML/text)
- Email layouts
- SMTP configuration
- Attachment handling

#### 15. [wheels-routing-generator](wheels-routing-generator/SKILL.md)
Generate RESTful routes, nested routes, and custom routing patterns.

**Activates when:**
- Creating routes
- Defining URL structure
- Implementing RESTful resources

**Features:**
- RESTful resource routes
- Nested routing
- Route constraints
- API versioning
- Named routes
- Route namespacing

## How Skills Work

### Automatic Activation

Skills activate automatically when Claude detects relevant keywords or task patterns:

```
User: "Create a Post model with comments association"

Claude: (automatically activates wheels-model-generator)
        (automatically activates wheels-anti-pattern-detector)
        → Generates model with correct patterns
        → Validates code before writing
        → Prevents mixed argument styles
```

### Skill Composition

Multiple skills work together on complex tasks:

```
User: "Create a blog with posts and comments"

Claude activates:
1. wheels-model-generator (Post and Comment models)
2. wheels-migration-generator (database tables)
3. wheels-controller-generator (Posts and Comments controllers)
4. wheels-view-generator (index, show, new, edit views)
5. wheels-anti-pattern-detector (validates all generated code)
6. wheels-test-generator (creates test specs)

Result: Complete, tested, validated blog feature!
```

### Validation Workflow

The anti-pattern-detector skill runs automatically during code generation:

```
1. Generate code (model/controller/view/migration)
2. Scan for anti-patterns
3. If found:
   - Display warning
   - Show before/after
   - Auto-fix
4. Write validated code to file
```

## Benefits Over .ai Folder Approach

| Feature | .ai Folder | Claude Skills |
|---------|------------|---------------|
| **Activation** | Manual loading | Automatic |
| **Token Usage** | 5,000-10,000 per task | 500-1,500 per task |
| **Specialization** | Generic docs | Task-specific |
| **Validation** | Manual | Automatic before file write |
| **Composition** | Sequential | Parallel & composable |
| **User Experience** | Slow, manual | Fast, seamless |

## Token Efficiency

**Example Task: Generate Post Model**

**With .ai folder:**
```
1. Read .ai/wheels/models/architecture.md (2,000 tokens)
2. Read .ai/wheels/models/associations.md (1,500 tokens)
3. Read .ai/wheels/models/validations.md (1,800 tokens)
4. Read .ai/wheels/troubleshooting/common-errors.md (1,200 tokens)
Total: 6,500 tokens
```

**With Skills:**
```
1. Activate wheels-model-generator (800 tokens)
2. Activate wheels-anti-pattern-detector (400 tokens)
Total: 1,200 tokens
```

**Result: 81% reduction in token usage!**

## Usage Examples

### Create a Model

```
User: "Create a User model with email and password validation"

Activated Skills:
- wheels-model-generator
- wheels-anti-pattern-detector

Generated:
- User.cfc with proper validations
- All validations use named parameters
- No anti-patterns present
```

### Create a CRUD Controller

```
User: "Create a Posts controller with full CRUD"

Activated Skills:
- wheels-controller-generator
- wheels-anti-pattern-detector

Generated:
- Posts.cfc with index, show, new, create, edit, update, delete
- Parameter verification configured
- Filters for findPost
- Flash messages
- Proper redirects
```

### Create Views

```
User: "Create views for the Posts controller"

Activated Skills:
- wheels-view-generator
- wheels-anti-pattern-detector

Generated:
- index.cfm (proper query loops)
- show.cfm (association display)
- new.cfm (form with validation errors)
- edit.cfm (pre-populated form)
- All use textField with type (not emailField)
- All forms include CSRF protection
```

### Complete Feature

```
User: "Create a blog with posts and comments"

Activated Skills:
- wheels-model-generator (x2 for Post and Comment)
- wheels-migration-generator (x2 for tables)
- wheels-controller-generator (x2 for controllers)
- wheels-view-generator (x8 for all views)
- wheels-anti-pattern-detector (validates everything)

Result: Complete blog feature with zero anti-patterns!
```

## Skill Development

### Creating New Skills

See [CLAUDE-SKILLS-ANALYSIS.md](../../CLAUDE-SKILLS-ANALYSIS.md) for:
- Skill architecture guidelines
- Template structure
- YAML frontmatter format
- Best practices
- Integration patterns

### Skill Template

```markdown
---
name: Skill Name
description: What the skill does and when Claude should activate it.
---

# Skill Name

## When to Use This Skill

Activate when:
- User requests X
- User mentions Y
- User is doing Z

## Templates

[Templates here]

## Patterns

[Patterns here]

## Related Skills

- skill-1
- skill-2
```

## Migration from .ai Folder

**Skills complement the .ai folder, not replace it:**

- **.ai folder**: Comprehensive reference documentation for humans and AI
- **Skills**: Focused, automatic, task-specific generation

Both serve different but complementary purposes.

## Testing Skills

To verify skills are working:

1. Request a common task (e.g., "create a User model")
2. Observe which skills activate (Claude will mention them)
3. Check generated code for proper patterns
4. Verify anti-patterns were prevented

## Troubleshooting

### Skill Not Activating

- Check skill description matches your request keywords
- Use more specific language (e.g., "create model" vs "make user thing")
- Mention skill explicitly if needed

### Wrong Pattern Generated

- Skill may need description refinement
- Report issue for skill improvement
- Use anti-pattern-detector to validate

## Contributing

To improve or add skills:

1. Follow skill template structure
2. Include comprehensive description for activation
3. Provide clear examples
4. Add anti-pattern rules
5. Test with various requests
6. Document in this README

## Version History

- **v1.0** (2025-10-20): Initial skill implementation
  - 12 core skills
  - Automatic anti-pattern detection
  - Comprehensive code generation
  - Token-efficient operation

---

**Skills are the future of AI-assisted Wheels development!**

For questions or suggestions, see [CLAUDE-SKILLS-ANALYSIS.md](../../CLAUDE-SKILLS-ANALYSIS.md).
