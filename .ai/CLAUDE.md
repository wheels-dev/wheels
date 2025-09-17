# Claude Code Integration Guide

This file provides specific instructions for Claude Code and other AI assistants to effectively use the comprehensive documentation in this `.ai` folder.

## Documentation Integration Strategy

### Task-to-Documentation Mapping

When working on specific tasks, AI assistants should load the following documentation in order:

#### 🏗️ Model Development
**Required Reading Order:**
1. `.ai/cfml/components/` - CFC fundamentals
2. `.ai/wheels/database/models.md` - Wheels model patterns
3. `.ai/wheels/database/validations.md` - Model validation rules
4. `.ai/wheels/database/associations.md` - Model relationships
5. `.ai/wheels/snippets/models/` - Code examples

**Validation Checklist:**
- [ ] Uses CFScript syntax (not tag-based)
- [ ] Extends "Model" class
- [ ] Includes proper validation rules
- [ ] Follows singular naming convention
- [ ] Implements proper associations

#### 🎮 Controller Development
**Required Reading Order:**
1. `.ai/wheels/controllers/basics.md` - Controller fundamentals
2. `.ai/wheels/controllers/filters.md` - Authentication/authorization
3. `.ai/wheels/controllers/parameters.md` - Parameter handling
4. `.ai/wheels/controllers/rendering.md` - Response rendering
5. `.ai/wheels/snippets/controllers/` - Code examples

**Validation Checklist:**
- [ ] Uses plural naming convention
- [ ] Extends "Controller" class
- [ ] Implements proper filters
- [ ] Handles parameters securely
- [ ] Follows RESTful patterns

#### 📄 View Development
**Required Reading Order:**
1. `.ai/wheels/views/templates.md` - Template basics
2. `.ai/wheels/views/layouts.md` - Layout patterns
3. `.ai/wheels/views/helpers.md` - View helpers
4. `.ai/wheels/views/forms.md` - Form handling
5. `.ai/wheels/snippets/views/` - Code examples

**Validation Checklist:**
- [ ] Uses CFML template syntax
- [ ] Implements proper escaping
- [ ] Follows layout conventions
- [ ] Uses appropriate helpers

#### 🗃️ Database Migration
**Required Reading Order:**
1. `.ai/wheels/database/migrations.md` - Migration fundamentals
2. `.ai/wheels/cli/generators.md` - Generator usage
3. `.ai/wheels/snippets/migrations/` - Code examples

**Validation Checklist:**
- [ ] Extends "Migration" class
- [ ] Implements both up() and down()
- [ ] Uses proper column types
- [ ] Includes appropriate indexes

#### 🔧 Configuration
**Required Reading Order:**
1. `.ai/wheels/configuration/settings.md` - Framework settings
2. `.ai/wheels/configuration/environments.md` - Environment configs
3. `.ai/wheels/configuration/routing.md` - Route configuration

**Validation Checklist:**
- [ ] Uses proper environment structure
- [ ] Follows security best practices
- [ ] Implements appropriate routing

### Pre-Implementation Workflow

**Step 1: Context Assessment**
```bash
# Determine the type of work
if [model_work]; then load .ai/wheels/database/
if [controller_work]; then load .ai/wheels/controllers/
if [view_work]; then load .ai/wheels/views/
if [cfml_syntax_question]; then load .ai/cfml/
```

**Step 2: Pattern Validation**
- Read the relevant `.ai/wheels/patterns/` documentation
- Compare planned implementation against established patterns
- Ensure adherence to Wheels conventions

**Step 3: Code Example Reference**
- Check `.ai/wheels/snippets/` for relevant examples
- Use established code patterns as templates
- Adapt examples to specific requirements

**Step 4: Security Review**
- Consult `.ai/wheels/security/` for security requirements
- Implement CSRF protection where needed
- Follow parameter validation patterns

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

### Mandatory Pre-Code Actions
1. **Always** read the `.ai/README.md` first for context
2. **Load** task-specific documentation before coding
3. **Validate** against patterns and best practices
4. **Reference** code examples from snippets

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

## MCP Integration

The `.ai` documentation is designed to work with the native CFML MCP server at `/wheels/mcp`. Resources are available as:

- `wheels://.ai/cfml/syntax` - CFML syntax documentation
- `wheels://.ai/wheels/patterns` - Framework patterns
- `wheels://.ai/wheels/snippets` - Code examples
- `wheels://.ai/project/context` - Current project context

## Validation Commands

After implementing code based on `.ai` documentation:

```bash
# Run tests to validate implementation
wheels test run

# Check for syntax errors
wheels server start --validate

# Review generated code against patterns
# (Manual review using .ai documentation)
```

## Best Practices for AI Assistants

1. **Documentation First**: Always consult documentation before coding
2. **Pattern Consistency**: Follow established patterns from `.ai/wheels/patterns/`
3. **Security Awareness**: Apply security practices from `.ai/wheels/security/`
4. **Convention Adherence**: Follow Wheels naming and structure conventions
5. **Example Usage**: Use code examples from `.ai/wheels/snippets/` as templates
6. **Validation**: Test implementations against documented standards

This integration ensures that all AI-generated code adheres to the comprehensive knowledge base contained in the `.ai` documentation folder.