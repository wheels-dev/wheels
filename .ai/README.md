# Wheels Framework AI Knowledge Base

## Overview
This knowledge base contains focused, granular information about the Wheels framework, organized for AI coding assistants. Each file covers a specific concept with practical examples and usage patterns.

## Structure

### 📁 Core Concepts
- **[MVC Architecture](./core-concepts/mvc-architecture/)** - Models, Views, Controllers, and conventions
- **[ORM](./core-concepts/orm/)** - Object-relational mapping, properties, and table relationships
- **[Routing](./core-concepts/routing/)** - URL routing, resources, patterns, and HTTP methods

### 📁 Database
- **[Migrations](./database/migrations/)** - Creating, running, and managing database schema changes
- **[Queries](./database/queries/)** - Finding, creating, updating, and deleting records
- **[Associations](./database/associations/)** - Model relationships and nested properties
- **[Validations](./database/validations/)** - Data validation patterns and custom rules

### 📁 Controllers
- **[Filters](./controllers/filters/)** - Before/after filters, authentication, authorization
- **[Rendering](./controllers/rendering/)** - Views, JSON responses, and redirects
- **[Parameters](./controllers/params/)** - Parameter verification and security

### 📁 Views
- **[Helpers](./views/helpers/)** - Form helpers, links, dates, and custom helpers
- **[Layouts](./views/layouts/)** - Structure, content sections, and partials
- **[Assets](./views/assets/)** - Stylesheets, JavaScript, and image handling

### 📁 CLI Tools
- **[Generators](./cli/generators/)** - Models, controllers, scaffolds, and migrations
- **[Server](./cli/server/)** - Development server management
- **[Testing](./cli/testing/)** - Running tests and fixtures

### 📁 Patterns
- **[CRUD](./patterns/crud.md)** - Standard Create, Read, Update, Delete patterns
- **[Authentication](./patterns/authentication.md)** - User authentication and session management
- **[API Development](./patterns/api-development.md)** - Building RESTful APIs
- **[Service Layer](./patterns/service-layer.md)** - Business logic organization
- **[Error Handling](./patterns/error-handling.md)** - Exception handling and user feedback

### 📁 Configuration
- **[Environments](./configuration/environments.md)** - Development, testing, production settings
- **[Settings](./configuration/settings.md)** - Framework configuration options
- **[Datasources](./configuration/datasources.md)** - Database connection management
- **[Security](./configuration/security.md)** - CSRF, authentication, and security settings

### 📁 Code Snippets
- **[Model Snippets](./snippets/model-snippets.md)** - Common model patterns and code
- **[Controller Snippets](./snippets/controller-snippets.md)** - Controller action patterns
- **[View Snippets](./snippets/view-snippets.md)** - View helper usage examples
- **[Migration Snippets](./snippets/migration-snippets.md)** - Database migration patterns
- **[Route Snippets](./snippets/route-snippets.md)** - Routing configuration examples

## Quick Reference

### Getting Started
1. **[Installation](./introduction/requirements.md)** - System requirements and installation
2. **[New Application](./cli/generators/app.md)** - Creating your first Wheels app
3. **[MVC Conventions](./core-concepts/mvc-architecture/conventions.md)** - Naming and organization

### Common Tasks
- **Create Model**: `wheels g model User name:string,email:string`
- **Create Controller**: `wheels g controller Users index,show,new,create,edit,update,delete`
- **Create Migration**: `wheels g migration CreateUsersTable`
- **Run Migrations**: `wheels dbmigrate latest`
- **Start Server**: `wheels server start`

### Key Concepts
- **Models are singular**: User.cfc → users table
- **Controllers are plural**: Users.cfc handles users
- **Routes use resources**: `resources("users")` creates RESTful routes
- **Validations in models**: `validatesPresenceOf("name,email")`
- **Associations**: `hasMany("orders")`, `belongsTo("user")`

## File Organization
Each file follows a consistent structure:
- **Description**: Brief explanation of the concept
- **Key Points**: Important facts and features
- **Code Sample**: Practical, working examples
- **Usage**: Step-by-step instructions
- **Related**: Links to connected concepts
- **Important Notes**: Common pitfalls and best practices

## Best Practices
1. **Follow Conventions**: Wheels rewards convention over configuration
2. **Keep Controllers Thin**: Business logic belongs in models
3. **Use Validations**: Validate data at the model level
4. **Secure by Default**: Use CSRF protection and parameter verification
5. **Test Everything**: Write tests for models, controllers, and integrations

## Contributing
This knowledge base is extracted from official Wheels documentation and represents current best practices for the framework.

---

*Generated for AI coding assistant comprehension and reference*