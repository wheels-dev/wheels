# wheels docs (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Base command for documentation generation and management.

> **Note**: This command is currently broken. Use subcommands directly.

## Synopsis

```bash
wheels docs [subcommand] [options]
```

## Description

The `wheels docs` command provides documentation tools for Wheels applications. It generates API documentation, manages inline documentation, and serves documentation locally. While the base command is currently broken, the subcommands `generate` and `serve` work correctly.

## Subcommands

| Command | Description | Status |
|---------|-------------|--------|
| `generate` | Generate documentation | ✓ Working |
| `serve` | Serve documentation locally | ✓ Working |

## Options

| Option | Description |
|--------|-------------|
| `--help` | Show help information |
| `--version` | Show version information |

## Current Status

The base `wheels docs` command is temporarily unavailable due to a known issue. Please use the subcommands directly:

- `wheels docs generate` - Generate documentation
- `wheels docs serve` - Serve documentation

## Expected Behavior (When Fixed)

When operational, running `wheels docs` without subcommands would:

1. Check for existing documentation
2. Generate if missing or outdated
3. Provide quick access links
4. Show documentation statistics

Expected output:
```
Wheels Documentation Status
==========================

Generated: 2024-01-15 10:30:45
Files: 156 documented (89%)
Coverage: 1,234 of 1,456 functions

Recent Changes:
- UserModel.cfc: 5 new methods
- OrderController.cfc: Updated examples
- config/routes.cfm: New route docs

Quick Actions:
- View docs: http://localhost:4000
- Regenerate: wheels docs generate
- Check coverage: wheels docs coverage
```

## Workaround

Until the base command is fixed, use this workflow:

```bash
# Generate documentation
wheels docs generate

# Serve documentation
wheels docs serve

# Or combine in one line
wheels docs generate && wheels docs serve
```

## Documentation System

### Supported Formats
- JavaDoc-style comments
- Markdown files
- Inline documentation
- README files

### Documentation Sources
```
/app/
├── models/          # Model documentation
├── controllers/     # Controller documentation
├── views/          # View helpers documentation
├── config/         # Configuration docs
├── docs/           # Additional documentation
└── README.md       # Project overview
```

## Configuration

Configure in `.wheels-docs.json`:

```json
{
  "docs": {
    "output": "./documentation",
    "format": "html",
    "theme": "wheels-default",
    "include": [
      "app/**/*.cfc",
      "app/**/*.cfm",
      "docs/**/*.md"
    ],
    "exclude": [
      "vendor/**",
      "tests/**"
    ],
    "options": {
      "private": false,
      "inherited": true,
      "examples": true
    }
  }
}
```

## Documentation Comments

### Component Documentation
```cfml
/**
 * User model for authentication and profile management
 * 
 * @author John Doe
 * @since 1.0.0
 */
component extends="Model" {
    
    /**
     * Authenticate user with credentials
     * 
     * @username The user's username or email
     * @password The user's password
     * @return User object if authenticated, false otherwise
     * 
     * @example
     * user = model("User").authenticate("john@example.com", "secret");
     * if (isObject(user)) {
     *     // Login successful
     * }
     */
    public any function authenticate(required string username, required string password) {
        // Implementation
    }
}
```

### Inline Documentation
```cfml
<!--- 
    @doc
    This view displays the user profile page
    
    @requires User object in 'user' variable
    @layout layouts/main
--->
```

## Integration

### Auto-generation
Set up automatic documentation generation:

```json
// package.json
{
  "scripts": {
    "docs:build": "wheels docs generate",
    "docs:watch": "wheels docs generate --watch",
    "docs:serve": "wheels docs serve"
  }
}
```

### CI/CD
```yaml
- name: Generate documentation
  run: |
    wheels docs generate
    wheels docs coverage --min=80
```

## When to Use Subcommands

### Generate Documentation
Use when:
- Adding new components
- Updating documentation comments
- Before releases
- Setting up documentation site

```bash
wheels docs generate
```

### Serve Documentation
Use when:
- Reviewing documentation
- Local development
- Team documentation access
- API exploration

```bash
wheels docs serve
```

## Troubleshooting

### Base Command Not Working
Error: "wheels docs command is broken"

Solution: Use subcommands directly:
```bash
wheels docs generate
wheels docs serve
```

### Missing Documentation
If documentation is not generated:
1. Check file patterns in config
2. Verify comment format
3. Look for syntax errors
4. Check exclude patterns

## Future Plans

The base command will be restored to provide:
- Documentation dashboard
- Coverage reports
- Quick statistics
- Change detection
- Auto-serve option

## Notes

- Subcommands work independently
- Documentation is generated incrementally
- Large projects may take time to document
- Keep documentation comments updated

## See Also

- [wheels docs generate](docs-generate.md) - Generate documentation
- [wheels docs serve](docs-serve.md) - Serve documentation
- [Documentation Best Practices](../../documentation/best-practices.md)
- [API Documentation Guide](../../documentation/api-guide.md)