# wheels docs generate

Generates documentation for your Wheels application from code comments and annotations.

## Usage

```bash
wheels docs generate [--output=<dir>] [--format=<format>]  [--include=<components>] [--serve] [--verbose]
```

## Parameters

- `--output` - (Optional) Output directory for docs. Default: `docs/api`
- `--format` - (Optional) Documentation format: `html`, `json`, `markdown`. Default: `html`

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
/docs/api/
├── index.html
├── models/
│   ├── model.html/
├── controllers/
│   ├── controller.html
├── views/
|   └── view.html
├── services/
    └── view.html
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
Documentation Generator
==================================================

Generating documentation...

Scanning source files...
[OK] Found 1 models
[OK] Found 1 controllers

Writing documentation... [OK] HTML files generated

==================================================
[SUCCESS] Documentation generated successfully!

Summary:
  - Models: 1 files
  - Controllers: 1 files
  - Total: 2 components documented

Output directory: C:\path\to\docs\api\
```

## Documentation Features

### Auto-generated Content
- Class hierarchies and inheritance
- Method signatures and parameters
- Property types and defaults
- Relationship diagrams
- Route mappings
- Database ERD


## Notes

- Documentation is generated from code comments
- Use consistent JavaDoc format for best results
- Private methods are excluded by default