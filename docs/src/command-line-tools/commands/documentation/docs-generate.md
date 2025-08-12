# docs generate (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Generates documentation for your Wheels application from code comments and annotations.

## Usage

```bash
wheels docs generate [--output=<dir>] [--format=<format>] [--template=<template>] [--include=<components>] [--serve] [--verbose]
```

## Parameters

- `--output` - (Optional) Output directory for docs. Default: `docs/api`
- `--format` - (Optional) Documentation format: `html`, `json`, `markdown`. Default: `html`
- `--template` - (Optional) Documentation template to use: `default`, `bootstrap`, `minimal`. Default: `default`
- `--include` - (Optional) Components to include: `models`, `controllers`, `views`, `services`. Default: `models,controllers`
- `--serve` - (Optional) Start local server after generation
- `--verbose` - (Optional) Verbose output

## Description

The `docs generate` command automatically creates comprehensive documentation from your Wheels application by parsing:

- JavaDoc-style comments in CFCs
- Model relationships and validations
- Controller actions and routes
- Configuration files
- Database schema
- API endpoints

## Examples

### Generate complete documentation
```bash
wheels docs generate
```

### Generate markdown docs
```bash
wheels docs generate --format=markdown
```

### Generate with Bootstrap template
```bash
wheels docs generate --template=bootstrap
```

### Generate and serve immediately
```bash
wheels docs generate --serve
```

### Generate specific components with verbose output
```bash
wheels docs generate --include=models,controllers,services --verbose
```

### Custom output directory
```bash
wheels docs generate --output=public/api-docs --format=html
```

## Documentation Sources

### Model Documentation
```cfscript
/**
 * User model for authentication and authorization
 * 
 * @author John Doe
 * @since 1.0.0
 */
component extends="Model" {
    
    /**
     * Initialize user relationships and validations
     * @hint Sets up the user model configuration
     */
    function config() {
        // Relationships
        hasMany("orders");
        belongsTo("role");
        
        // Validations
        validatesPresenceOf("email,firstName,lastName");
        validatesUniquenessOf("email");
    }
    
    /**
     * Find active users with recent activity
     * 
     * @param days Number of days to look back
     * @return query Active users
     */
    public query function findActive(numeric days=30) {
        return findAll(
            where="lastLoginAt >= :date",
            params={date: dateAdd("d", -arguments.days, now())}
        );
    }
}
```

### Controller Documentation
```cfscript
/**
 * Handles user management operations
 * 
 * @displayname User Controller
 * @namespace /users
 */
component extends="Controller" {
    
    /**
     * Display paginated list of users
     * 
     * @hint GET /users
     * @access public
     * @return void
     */
    function index() {
        param name="params.page" default="1";
        users = model("user").findAll(
            page=params.page,
            perPage=20,
            order="createdAt DESC"
        );
    }
}
```

## Generated Output

### HTML Format
```
/docs/generated/
├── index.html
├── assets/
│   ├── css/
│   └── js/
├── models/
│   ├── index.html
│   └── user.html
├── controllers/
│   ├── index.html
│   └── users.html
├── api/
│   └── endpoints.html
└── database/
    └── schema.html
```

### Documentation includes:
- **Overview**: Application structure and architecture
- **Models**: Properties, methods, relationships, validations
- **Controllers**: Actions, filters, routes
- **API Reference**: Endpoints, parameters, responses
- **Database Schema**: Tables, columns, indexes
- **Configuration**: Settings and environment variables

## Output Example

```
Generating documentation...
========================

Scanning source files... ✓
✓ Found 15 models
✓ Found 12 controllers  
✓ Found 45 routes
✓ Found 8 API endpoints

Processing documentation...
✓ Extracting comments
✓ Building relationships
✓ Generating diagrams
✓ Creating index

Writing documentation...
✓ HTML files generated
✓ Assets copied
✓ Search index created

Documentation generated successfully!
- Output: /docs/generated/
- Files: 82
- Size: 2.4 MB

View documentation:
- Local: file:///path/to/docs/generated/index.html
- Serve: wheels docs serve
```

## Documentation Features

### Auto-generated Content
- Class hierarchies and inheritance
- Method signatures and parameters
- Property types and defaults
- Relationship diagrams
- Route mappings
- Database ERD

### Search Functionality
```javascript
// Built-in search in HTML docs
{
  "searchable": true,
  "index": "lunr",
  "fields": ["title", "content", "tags"]
}
```

### Custom Themes

Configure in `/config/docs-theme.json`:
```json
{
  "theme": "custom",
  "colors": {
    "primary": "#007bff",
    "secondary": "#6c757d"
  },
  "logo": "/assets/logo.png",
  "favicon": "/assets/favicon.ico",
  "customCSS": "/assets/custom.css"
}
```

## Integration

### CI/CD Documentation
```yaml
# Generate docs on every commit
- name: Generate Docs
  run: |
    wheels docs generate --format=html
    wheels docs generate --format=markdown --output=wiki/
```

### Git Hooks
```bash
#!/bin/bash
# pre-commit hook
wheels docs generate --include=api --format=json
git add docs/api/openapi.json
```

## Notes

- Documentation is generated from code comments
- Use consistent JavaDoc format for best results
- Private methods are excluded by default
- Images and diagrams are auto-generated
- Supports custom templates and themes