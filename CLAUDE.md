# CLAUDE.md - CFWheels Documentation Dispatcher

This file provides guidance to Claude Code (claude.ai/code) when working with a Wheels application.

## 🚨 MANDATORY: Pre-Implementation Documentation Check

**BEFORE implementing ANY code, AI assistants MUST follow this workflow:**

### 🛑 STEP 1: Critical Error Prevention (ALWAYS FIRST)
- [ ] **READ** `.ai/wheels/troubleshooting/common-errors.md` - PREVENT FATAL ERRORS
- [ ] **READ** `.ai/wheels/patterns/validation-templates.md` - VALIDATION CHECKLISTS

### 📋 STEP 2: Task-Specific Documentation Loading

#### 🏗️ For Model Development
**MANDATORY Reading Order:**
- [ ] `.ai/wheels/models/data-handling.md` - Critical query vs array patterns
- [ ] `.ai/wheels/models/architecture.md` - Model fundamentals and structure
- [ ] `.ai/wheels/models/associations.md` - Relationship patterns (CRITICAL)
- [ ] `.ai/wheels/models/validations.md` - Validation methods and patterns
- [ ] `.ai/wheels/models/best-practices.md` - Model development guidelines

#### 🎮 For Controller Development
**MANDATORY Reading Order:**
- [ ] `.ai/wheels/controllers/architecture.md` - Controller fundamentals and CRUD
- [ ] `.ai/wheels/controllers/rendering.md` - View rendering and responses
- [ ] `.ai/wheels/controllers/filters.md` - Authentication and authorization
- [ ] `.ai/wheels/controllers/model-interactions.md` - Controller-model patterns
- [ ] `.ai/wheels/controllers/best-practices.md` - Controller development guidelines

#### 📄 For View Development
**MANDATORY Reading Order:**
- [ ] `.ai/wheels/views/data-handling.md` - CRITICAL query vs array patterns
- [ ] `.ai/wheels/views/architecture.md` - View structure and conventions
- [ ] `.ai/wheels/views/forms.md` - Form helpers and limitations (CRITICAL)
- [ ] `.ai/wheels/views/layouts.md` - Layout patterns and inheritance
- [ ] `.ai/wheels/views/best-practices.md` - View implementation checklist

#### ⚙️ For Configuration Work
**MANDATORY Reading Order:**
- [ ] `.ai/wheels/configuration/routing.md` - CRITICAL routing anti-patterns
- [ ] `.ai/wheels/configuration/environments.md` - Environment settings
- [ ] `.ai/wheels/configuration/framework-settings.md` - Global settings
- [ ] `.ai/wheels/configuration/best-practices.md` - Configuration guidelines

### 🔍 STEP 3: Anti-Pattern Validation (BEFORE WRITING CODE)
- [ ] **Verify** NO mixed argument styles in CFWheels functions
- [ ] **Verify** NO ArrayLen() usage on model associations (use .recordCount)
- [ ] **Verify** NO Rails-style nested resource routing
- [ ] **Verify** proper query vs array handling in views

### ✅ STEP 4: Implementation Using Documentation Patterns
- Use code templates from `.ai/wheels/` directories
- Follow established patterns from the loaded documentation
- Validate implementation against the read documentation

### 🚀 STEP 5: Post-Implementation Validation
- Run `wheels server start --validate` to check syntax
- Test functionality with sample data
- Verify all anti-patterns are avoided

## 📚 Documentation Index - Quick Reference

### Core Framework Documentation
- **Models**: `.ai/wheels/models/` - Data layer, ORM, associations, validations
- **Controllers**: `.ai/wheels/controllers/` - Request handling, filters, rendering
- **Views**: `.ai/wheels/views/` - Templates, layouts, forms, helpers
- **Configuration**: `.ai/wheels/configuration/` - Settings, routing, environments

### Critical Anti-Pattern Prevention
- **Common Errors**: `.ai/wheels/troubleshooting/common-errors.md`
- **Validation Templates**: `.ai/wheels/patterns/validation-templates.md`
- **Best Practices**: Each component directory contains `best-practices.md`

### MCP Server Integration (Fallback)
**If `.ai/` folder is not accessible, use MCP resources:**
- `wheels://.ai/wheels/models` - Model documentation
- `wheels://.ai/wheels/controllers` - Controller documentation
- `wheels://.ai/wheels/views` - View documentation
- `wheels://.ai/wheels/configuration` - Configuration documentation

## ⚡ Quick Start Guide

### New to Wheels?
1. **Install Wheels CLI**: `brew install wheels` on Mac and `choco install wheels` on Windows
2. **Generate an app**: `wheels g app myapp`
3. **Start developing**: `wheels server start`

### 🔥 Common Development Tasks
- **Create a model**: `wheels g model User name:string,email:string,active:boolean`
- **Create a controller**: `wheels g controller Users index,show,new,create,edit,update,delete`
- **Create full scaffold**: `wheels g scaffold Product name:string,price:decimal,instock:boolean`
- **Run migrations**: `wheels dbmigrate latest` `wheels dbmigrate up` `wheels dbmigrate down`
- **Run tests**: `wheels test run`
- **Reload application**: Visit `/?reload=true&password=yourpassword`

### 📖 For Detailed Implementation Guidance
**After using generators, ALWAYS consult the appropriate .ai documentation:**
- **Models**: Read `.ai/wheels/models/` for proper associations, validations, and patterns
- **Controllers**: Read `.ai/wheels/controllers/` for filters, rendering, and CRUD patterns
- **Views**: Read `.ai/wheels/views/` for templates, forms, and data handling
- **Configuration**: Read `.ai/wheels/configuration/` for routing and environment setup

## 🏗️ Application Architecture Overview

**For detailed architecture documentation, see:**
- **Models**: `.ai/wheels/models/architecture.md` - Data layer structure and ORM patterns
- **Controllers**: `.ai/wheels/controllers/architecture.md` - Request handling and MVC patterns
- **Views**: `.ai/wheels/views/architecture.md` - Template structure and conventions
- **Configuration**: `.ai/wheels/configuration/overview.md` - Settings and environment structure

### Quick MVC Reference
- **Models** (`/app/models/`): Data layer with ActiveRecord ORM → See `.ai/wheels/models/`
- **Views** (`/app/views/`): Templates and presentation → See `.ai/wheels/views/`
- **Controllers** (`/app/controllers/`): Request handling → See `.ai/wheels/controllers/`
- **Configuration** (`/config/`): App settings and routing → See `.ai/wheels/configuration/`

## 🛠️ Development Commands Reference

### Code Generation (CLI Commands)
```bash
# Models, Controllers, Views
wheels g model User name:string,email:string,active:boolean
wheels g controller Users index,show,new,create,edit,update,delete
wheels g scaffold Product name:string,price:decimal,instock:boolean

# Database migrations
wheels g migration CreateUsersTable
wheels dbmigrate latest

# Server management
wheels server start
wheels test run
```

**⚠️ CRITICAL: After using generators, ALWAYS read the corresponding .ai documentation:**
- **After generating models**: Read `.ai/wheels/models/`
- **After generating controllers**: Read `.ai/wheels/controllers/`
- **After generating views**: Read `.ai/wheels/views/`

## ⚙️ Configuration Quick Reference

**For complete configuration documentation:**
- **Environment Setup**: `.ai/wheels/configuration/environments.md`
- **Framework Settings**: `.ai/wheels/configuration/framework-settings.md`
- **Routing Configuration**: `.ai/wheels/configuration/routing.md` (CRITICAL)

### Essential Configuration Files
- `/config/environment.cfm` - Set current environment
- `/config/settings.cfm` - Global framework settings
- `/config/routes.cfm` - URL routing (see routing.md for anti-patterns)
- `/config/[environment]/settings.cfm` - Environment overrides

## 🏗️ MVC Implementation Patterns

**⚠️ CRITICAL: Do NOT copy code examples from this file. Always read the full documentation first:**

### Controller Development
**See:** `.ai/wheels/controllers/architecture.md` for complete controller patterns
- CRUD actions and REST patterns
- Filter implementation (authentication, authorization)
- Parameter verification and validation
- Rendering and response handling

### Model Development
**See:** `.ai/wheels/models/architecture.md` for complete model patterns
- Associations and relationships (CRITICAL: returns QUERIES not arrays)
- Validation methods and rules
- Callbacks and lifecycle hooks
- Custom finder methods

### View Development
**See:** `.ai/wheels/views/architecture.md` for complete view patterns
- Layout and template structure
- Query handling (CRITICAL: use .recordCount, not ArrayLen())
- Form helpers and limitations
- Partial and content rendering

## 🗄️ Database and Testing

### Database Migrations
**See:** `.ai/wheels/database/migrations/` for complete migration documentation
- Migration creation and workflow
- Column types and constraints
- Index management and advanced features

### Testing
**See:** `.ai/wheels/testing/` for complete testing documentation
- Model testing patterns
- Controller testing patterns
- Test structure and organization

## 🔒 Security and Performance

### Security Practices
**See:** `.ai/wheels/security/` for complete security documentation
- CSRF protection implementation
- Input validation and sanitization
- SQL injection prevention

### Performance Optimization
**See:** `.ai/wheels/performance/` for complete performance documentation
- Caching strategies
- Database query optimization
- Production configuration

## 🚀 Deployment

**See:** `.ai/wheels/deployment/` for complete deployment documentation
- Production configuration
- Environment variable management
- Security hardening

## Native MCP Server

This Wheels application includes a native CFML MCP (Model Context Protocol) server that eliminates the need for Node.js dependencies. The MCP server provides AI coding assistants with direct access to your Wheels application.

### Accessing the MCP Server

The MCP server is available at `/wheels/mcp` and supports:
- **Resources**: Documentation, guides, project context, patterns
- **Tools**: Code generation (models, controllers, views, migrations)
- **Prompts**: Context-aware help for Wheels development

### MCP Client Configuration

Configure your AI coding assistant to use the native MCP server:

```json
{
  "mcpServers": {
    "wheels": {
      "type": "http",
      "url": "http://localhost:8080/wheels/mcp"
    }
  }
}
```

Replace `8080` with your development server port.

### Available Tools

- `wheels_generate` - Generate components (models, controllers, etc.)
- `wheels_migrate` - Run database migrations
- `wheels_test` - Execute tests
- `wheels_server` - Manage development server
- `wheels_reload` - Reload application

### Route Configuration

The MCP server routes are pre-configured in `/config/routes.cfm`:

```cfm
.post(pattern="/wheels/mcp", to="##mcp")
.get(pattern="/wheels/mcp", to="##mcp")
```

These routes must come before the `.wildcard()` route to function correctly.

## Common Patterns

### Service Layer Pattern
```cfm
// /app/lib/UserService.cfc
component {
    
    function createUser(required struct userData) {
        local.user = model("User").new(arguments.userData);
        
        transaction {
            if (local.user.save()) {
                sendWelcomeEmail(local.user);
                return local.user;
            } else {
                transaction action="rollback";
                return false;
            }
        }
    }
}
```

### API Development
```cfm
// API base controller
component extends="wheels.Controller" {
    
    function config() {
        provides("json");
        filters(through="authenticate");
    }
    
    private function authenticate() {
        // API authentication logic
    }
}

// API endpoint
function index() {
    users = model("User").findAll();
    renderWith(data={users=users});
}
```

### Error Handling
```cfm
// Global error handler in Application.cfc
function onError(exception, eventname) {
    if (get("environment") == "production") {
        WriteLog(file="application", text=exception.message, type="error");
        include "/app/views/errors/500.cfm";
    } else {
        return true; // Let ColdFusion handle it
    }
}
```

## 🐛 Troubleshooting and Common Issues

**⚠️ CRITICAL: For complete troubleshooting guidance, see:**
- **Common Errors**: `.ai/wheels/troubleshooting/common-errors.md` - PREVENT FATAL ERRORS
- **Configuration Issues**: `.ai/wheels/configuration/troubleshooting.md`
- **Model Issues**: `.ai/wheels/models/troubleshooting.md`
- **View Issues**: `.ai/wheels/views/troubleshooting.md`

### ⚡ Quick Error Prevention Checklist
- [ ] ❌ **NO** mixed argument styles: `hasMany("comments", dependent="delete")`
- [ ] ❌ **NO** ArrayLen() on model associations: `ArrayLen(user.posts())`
- [ ] ❌ **NO** Rails-style nested resources: `.resources("posts", function(nested) {...})`
- [ ] ❌ **NO** emailField() or passwordField() helpers (don't exist)
- [ ] ✅ **YES** use consistent arguments: ALL named OR ALL positional
- [ ] ✅ **YES** use .recordCount: `user.posts().recordCount`
- [ ] ✅ **YES** separate resource declarations: `.resources("posts").resources("comments")`
- [ ] ✅ **YES** use textField() with type attribute: `textField(type="email")`

**⚠️ When you encounter errors, ALWAYS check `.ai/wheels/troubleshooting/common-errors.md` first!**