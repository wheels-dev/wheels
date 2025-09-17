# CFWheels Documentation Index

🚨 **COMPREHENSIVE DOCUMENTATION INDEX** 🚨

This file provides the complete index of CFWheels documentation for AI assistants. All technical content has been organized into the structured `.ai` folder for maximum efficiency and accuracy.

⛔ **CRITICAL: ALWAYS READ RELEVANT DOCUMENTATION BEFORE WRITING CODE** ⛔

## 🚨 MANDATORY Pre-Implementation Workflow

### 🛑 STEP 1: Critical Error Prevention (ALWAYS FIRST)
1. **`.ai/wheels/troubleshooting/common-errors.md`** - PREVENT FATAL ERRORS
2. **`.ai/wheels/patterns/validation-templates.md`** - VALIDATION CHECKLISTS

### 📋 STEP 2: Task-Specific Documentation Loading

#### 🏗️ For Model Development
**MANDATORY Reading Order:**
1. `.ai/wheels/models/data-handling.md` - Critical query vs array patterns
2. `.ai/wheels/models/architecture.md` - Model fundamentals and structure
3. `.ai/wheels/models/associations.md` - Relationship patterns (CRITICAL)
4. `.ai/wheels/models/validations.md` - Validation methods and patterns
5. `.ai/wheels/models/best-practices.md` - Model development guidelines

#### 🎮 For Controller Development
**MANDATORY Reading Order:**
1. `.ai/wheels/controllers/architecture.md` - Controller fundamentals and CRUD
2. `.ai/wheels/controllers/rendering.md` - View rendering and responses
3. `.ai/wheels/controllers/filters.md` - Authentication and authorization
4. `.ai/wheels/controllers/model-interactions.md` - Controller-model patterns
5. `.ai/wheels/controllers/best-practices.md` - Controller development guidelines

#### 📄 For View Development
**MANDATORY Reading Order:**
1. `.ai/wheels/views/data-handling.md` - CRITICAL query vs array patterns
2. `.ai/wheels/views/architecture.md` - View structure and conventions
3. `.ai/wheels/views/forms.md` - Form helpers and limitations (CRITICAL)
4. `.ai/wheels/views/layouts.md` - Layout patterns and inheritance
5. `.ai/wheels/views/best-practices.md` - View implementation checklist

#### ⚙️ For Configuration Work
**MANDATORY Reading Order:**
1. `.ai/wheels/configuration/routing.md` - CRITICAL routing anti-patterns
2. `.ai/wheels/configuration/environments.md` - Environment settings
3. `.ai/wheels/configuration/framework-settings.md` - Global settings
4. `.ai/wheels/configuration/best-practices.md` - Configuration guidelines

### 🔍 STEP 3: Anti-Pattern Validation (BEFORE WRITING CODE)
- [ ] ❌ **NO** mixed argument styles in CFWheels functions
- [ ] ❌ **NO** ArrayLen() usage on model associations (use .recordCount)
- [ ] ❌ **NO** Rails-style nested resource routing
- [ ] ❌ **NO** emailField() or passwordField() helpers (don't exist)
- [ ] ✅ **YES** consistent arguments: ALL named OR ALL positional
- [ ] ✅ **YES** use .recordCount: `user.posts().recordCount`
- [ ] ✅ **YES** separate resource declarations
- [ ] ✅ **YES** textField() with type attribute

## 📚 Complete Documentation Structure

### Core Framework Components

#### Models Documentation (`.ai/wheels/models/`)
- `architecture.md` - Model structure and fundamentals
- `data-handling.md` - Critical query vs array patterns
- `associations.md` - Relationship patterns (CRITICAL)
- `validations.md` - Validation rules and methods
- `callbacks.md` - Lifecycle hooks and events
- `methods-reference.md` - Complete method documentation
- `advanced-patterns.md` - Complex model examples
- `user-authentication.md` - Authentication model patterns
- `testing.md` - Model testing strategies
- `performance.md` - Query optimization
- `best-practices.md` - Development guidelines
- `advanced-features.md` - Timestamps and dirty tracking

#### Controllers Documentation (`.ai/wheels/controllers/`)
- `architecture.md` - Controller structure and CRUD patterns
- `rendering.md` - View rendering, redirects, flash messages
- `filters.md` - Authentication, authorization, data loading
- `model-interactions.md` - Controller-model patterns, validation
- `api.md` - JSON/XML APIs, authentication, versioning
- `security.md` - CSRF, parameter verification, sanitization
- `testing.md` - Controller testing patterns and helpers

#### Views Documentation (`.ai/wheels/views/`)
- `data-handling.md` - Critical query vs array patterns
- `architecture.md` - View structure and file organization
- `layouts.md` - Layout patterns and inheritance
- `partials.md` - Partial usage and patterns
- `forms.md` - Form helpers and CFWheels limitations
- `helpers.md` - View helpers and custom helpers
- `advanced-patterns.md` - AJAX, performance, caching
- `testing.md` - View testing patterns
- `best-practices.md` - Implementation checklist and patterns

#### Configuration Documentation (`.ai/wheels/configuration/`)
- `routing.md` - CRITICAL routing anti-patterns and patterns
- `environments.md` - Environment settings and switching
- `application.md` - Application.cfc settings (app.cfm)
- `framework-settings.md` - Global framework settings (settings.cfm)
- `overview.md` - File structure, loading order, general overview
- `best-practices.md` - Configuration best practices and patterns
- `troubleshooting.md` - Common issues and debugging
- `security.md` - Security considerations and hardening

## 🚨 Critical Anti-Pattern Prevention

### Most Common CFWheels Errors
1. **Mixed Arguments**: `hasMany("comments", dependent="delete")` ❌
2. **Query vs Array Confusion**: `ArrayLen(posts)` on query objects ❌
3. **Rails-style Routing**: Nested resource functions ❌
4. **Non-existent Helpers**: `emailField()`, `passwordField()` ❌

### Correct Patterns
1. **Consistent Arguments**: `hasMany(name="comments", dependent="delete")` ✅
2. **Query Methods**: `posts.recordCount` ✅
3. **Separate Resources**: `.resources("posts").resources("comments")` ✅
4. **CFWheels Helpers**: `textField(type="email")` ✅

## 🛠️ AI Assistant Implementation Guidelines

### 🛑 MANDATORY Pre-Code Actions (NO EXCEPTIONS)
1. **ALWAYS** read `.ai/wheels/troubleshooting/common-errors.md` FIRST
2. **ALWAYS** read component-specific .ai documentation
3. **VALIDATE** against anti-patterns before writing any code
4. **REFERENCE** code examples from .ai documentation as templates
5. **CHECK** implementation against validation templates continuously

### Quality Assurance Process
1. **Documentation First**: Always consult .ai documentation before coding
2. **Pattern Consistency**: Follow established patterns from .ai documentation
3. **Security Awareness**: Apply security practices from .ai documentation
4. **Convention Adherence**: Follow CFWheels naming and structure conventions
5. **Validation**: Test implementations against documented standards

## 🚀 Quick Reference Dispatchers

### Component Quick Access
- **Models**: `app/models/CLAUDE.md` → `.ai/wheels/models/`
- **Controllers**: `app/controllers/CLAUDE.md` → `.ai/wheels/controllers/`
- **Views**: `app/views/CLAUDE.md` → `.ai/wheels/views/`
- **Configuration**: Root `CLAUDE.md` → `.ai/wheels/configuration/`

### Critical Reading Priority
1. **Error Prevention**: `.ai/wheels/troubleshooting/common-errors.md`
2. **Data Handling**: Component-specific `data-handling.md` files
3. **Best Practices**: Component-specific `best-practices.md` files
4. **Architecture**: Component-specific `architecture.md` files

## ✅ Post-Implementation Validation

### MANDATORY Validation Commands
```bash
# 1. Syntax validation
wheels server start --validate

# 2. Test validation
wheels test run

# 3. Manual anti-pattern check
# Check implementation against .ai documentation patterns
```

### If Validation Fails
1. Consult `.ai/wheels/troubleshooting/common-errors.md`
2. Review appropriate component documentation in `.ai/wheels/`
3. Fix errors following documented patterns
4. Re-run validation until all checks pass

## 🎯 Success Criteria

**Your implementation is successful when:**
- [ ] All relevant .ai documentation has been read
- [ ] No anti-patterns are present in the code
- [ ] Patterns match those documented in .ai folder
- [ ] Validation commands pass successfully
- [ ] Code follows CFWheels conventions and best practices

🚨 **REMEMBER: The .ai folder contains the definitive, comprehensive documentation. ALWAYS use it as your primary reference!**