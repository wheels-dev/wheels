# Wheels Framework AI Knowledge Base

## Overview
This knowledge base contains comprehensive information about CFML (ColdFusion Markup Language) and the Wheels framework, organized for AI coding assistants. The documentation is structured in two main sections to provide both foundational language knowledge and framework-specific guidance.

## Structure

The documentation is organized into two main sections:

### 📁 [CFML Language Documentation](./cfml/)
Core CFML language concepts, syntax, and features that apply to all CFML frameworks:

- **[Syntax](./cfml/syntax/)** - Basic CFML syntax, CFScript vs tags, comments
- **[Data Types](./cfml/data-types/)** - Variables, arrays, strings, structures, numbers, scopes
- **[Control Flow](./cfml/control-flow/)** - Conditionals, loops, exception handling
- **[Components](./cfml/components/)** - CFC basics, functions, properties
- **[Database](./cfml/database/)** - Query fundamentals and database interaction
- **[Advanced](./cfml/advanced/)** - Closures and advanced language features
- **[Best Practices](./cfml/best-practices/)** - Modern CFML development patterns

### 📁 [Wheels Framework Documentation](./wheels/)
Framework-specific patterns, conventions, and features:

#### Core Framework Areas
- **[CLI Tools](./wheels/cli/)** - Generators, server management, testing tools
- **[Configuration](./wheels/configuration/)** - Environment settings, framework configuration
- **[Controllers](./wheels/controllers/)** - Request handling, filters, rendering, parameters
- **[Core Concepts](./wheels/core-concepts/)** - MVC architecture, ORM, routing conventions
- **[Database](./wheels/database/)** - ActiveRecord ORM, migrations, associations, validations
- **[Views](./wheels/views/)** - Templates, layouts, helpers, assets

#### Development Support
- **[Communication](./wheels/communication/)** - Email, HTTP requests, API development
- **[Files](./wheels/files/)** - File uploads, downloads, asset management
- **[Patterns](./wheels/patterns/)** - Common development patterns and best practices
- **[Security](./wheels/security/)** - Authentication, authorization, CSRF protection
- **[Snippets](./wheels/snippets/)** - Code examples and quick reference patterns

## Quick Reference

### Getting Started with CFML + Wheels
1. **Understand CFML Basics**: Start with [CFML syntax](./cfml/syntax/) and [data types](./cfml/data-types/)
2. **Learn Wheels Conventions**: Review [MVC architecture](./wheels/core-concepts/) patterns
3. **Use CLI Tools**: Leverage [generators](./wheels/cli/) for rapid development

### 🚨 CRITICAL: MCP Tools Required
**If `.mcp.json` exists, use MCP tools exclusively - CLI commands are FORBIDDEN**

### ✅ MCP Development Tasks (MANDATORY when .mcp.json exists)
```javascript
// Generate application components
mcp__wheels__wheels_generate(type="model", name="User", attributes="name:string,email:string,active:boolean")
mcp__wheels__wheels_generate(type="controller", name="Users", actions="index,show,new,create,edit,update,delete")
mcp__wheels__wheels_generate(type="migration", name="CreateUsersTable")

// Database operations
mcp__wheels__wheels_migrate(action="latest")
mcp__wheels__wheels_migrate(action="up")
mcp__wheels__wheels_migrate(action="down")

// Server management
mcp__wheels__wheels_server(action="start")
mcp__wheels__wheels_server(action="stop")
mcp__wheels__wheels_test()
mcp__wheels__wheels_reload()
```

### ❌ Legacy CLI Commands (DO NOT USE if .mcp.json exists)
```bash
# These are FORBIDDEN when MCP tools are available
wheels g model User name:string,email:string,active:boolean
wheels g controller Users index,show,new,create,edit,update,delete
wheels dbmigrate latest
wheels server start
wheels test run
```

### Key Framework Concepts
- **Models are singular**: User.cfc → users table
- **Controllers are plural**: Users.cfc handles users resource
- **Routes use resources**: `resources("users")` creates RESTful routes
- **Validations in models**: `validatesPresenceOf("name,email")`
- **Associations**: `hasMany("orders")`, `belongsTo("user")`
- **CFScript preferred**: Modern CFML uses CFScript over tag-based syntax

## Documentation Structure
Each documentation file follows a consistent structure:
- **Description**: Brief explanation of the concept
- **Key Points**: Important facts and features
- **Code Sample**: Practical, working examples
- **Usage**: Step-by-step instructions
- **Related**: Links to connected concepts
- **Important Notes**: Common pitfalls and best practices

## How to Use This Knowledge Base

### For AI Assistants
1. **Start with context**: Determine if the question is about CFML language fundamentals or Wheels framework specifics
2. **Reference appropriately**: Use CFML docs for language questions, Wheels docs for framework patterns
3. **Combine knowledge**: Many questions require understanding both CFML syntax and Wheels conventions
4. **Follow patterns**: Use the established code examples and patterns shown in the documentation

### For Developers
1. **New to CFML?** Start with [CFML fundamentals](./cfml/)
2. **New to Wheels?** Begin with [core concepts](./wheels/core-concepts/)
3. **Specific task?** Check [snippets](./wheels/snippets/) and [patterns](./wheels/patterns/)
4. **Configuration issues?** Review [configuration](./wheels/configuration/) docs

## Best Practices

### CFML Development
- Use CFScript syntax for modern, readable code
- Understand variable scoping and lifecycle
- Leverage CFML's dynamic nature while maintaining type safety
- Follow contemporary CFML patterns from the best practices section

### Wheels Framework
1. **Follow Conventions**: Wheels rewards convention over configuration
2. **Keep Controllers Thin**: Business logic belongs in models
3. **Use Validations**: Validate data at the model level
4. **Secure by Default**: Use CSRF protection and parameter verification
5. **Test Everything**: Write tests for models, controllers, and integrations
6. **Leverage the ORM**: Use Wheels' ActiveRecord patterns for database operations

## Integration with Development Tools

This knowledge base is designed to work with:
- **AI coding assistants** (Claude Code, GitHub Copilot, etc.)
- **MCP (Model Context Protocol)** clients
- **Wheels development server** (AI documentation endpoints)
- **IDE integrations** and development workflows

## Contributing
This knowledge base combines:
- Official Wheels framework documentation
- CFML language reference materials
- Modern CFML development practices
- Community best practices and patterns

---

*Organized for comprehensive CFML and Wheels framework development support*