---
name: Wheels Documentation Generator
description: Generate documentation comments, README files, and API documentation for Wheels applications. Use when documenting code, creating project READMEs, or generating API docs.
---

# Wheels Documentation Generator

## Function Documentation

```cfm
/**
 * Authenticate user with email and password
 *
 * @param email User's email address
 * @param password User's password (plain text)
 * @return User object if authenticated, false otherwise
 */
public any function authenticate(required string email, required string password) {
    // Implementation
}
```

## Model Documentation

```cfm
/**
 * Post Model
 *
 * Represents a blog post with associated comments and tags.
 *
 * Associations:
 * - hasMany: comments (dependent delete)
 * - hasManyThrough: tags (through postTags)
 * - belongsTo: user
 *
 * Validations:
 * - title: presence, length (3-200)
 * - slug: presence, uniqueness
 * - content: presence, minimum length (10)
 */
component extends="Model" {
    // Implementation
}
```

## README Template

```markdown
# Project Name

## Description

Brief description of the application.

## Requirements

- Wheels 4.0+
- Lucee 5.x / Adobe ColdFusion 2018+
- Database (MySQL, PostgreSQL, SQL Server)

## Installation

1. Clone repository
2. Run migrations: `wheels migrate latest`
3. Start server: `wheels start`

## Configuration

Configure the datasource in `config/app.cfm` (`this.datasources`) and settings in `config/settings.cfm`

## Testing

Run tests: `wheels test run`

## License

MIT
```

