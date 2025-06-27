# Wheels Framework Templates

This directory contains application templates for quickly scaffolding new Wheels applications.

## Available Templates

### 1. Base Template (`/base`)
The standard Wheels application template with:
- Complete MVC structure
- Configuration for all environments
- Basic layout and view helpers
- H2 database configuration by default
- Example models and controllers
- Test suite setup

### 2. API Template (`/api`)
A lightweight template optimized for building APIs:
- JSON/XML response handling
- Token authentication scaffolding
- CORS configuration
- API versioning structure
- Rate limiting setup
- Minimal views (API documentation only)

## Testing Templates with Docker

The easiest way to test templates is using Docker containers, which provides a consistent environment across all platforms.

### Using Wheels CLI (Recommended)

```bash
# Navigate to the template directory
cd templates/base

# Run with default settings (Lucee 6, H2 database)
wheels docker:test

# Run with specific engine and database
wheels docker:test --engine=adobe@2021 --db=mysql --port=8081

# Run in detached mode
wheels docker:test --detach
```

**Available Options:**
- `--engine`: lucee@5, lucee@6, lucee@7, adobe@2018, adobe@2021, adobe@2023, adobe@2025
- `--db`: h2, mysql, postgres, sqlserver
- `--port`: Custom port (default: 8080)
- `--detach`: Run in background
- `--build`: Force rebuild images

### Using Shell Scripts

If you don't have the Wheels CLI installed:

```bash
cd templates/base
../../tools/docker/test-template.sh --engine=lucee@6 --db=postgres
```

### Docker Management Commands

```bash
# View container logs
wheels docker:test:logs --follow

# Stop containers
wheels docker:test:stop

# Clean up (remove containers, volumes, and test files)
wheels docker:test:clean
```

## Creating New Applications from Templates

To create a new application using a template:

```bash
# Using the base template
wheels generate app myapp --template=base

# Using the API template
wheels generate app myapi --template=api
```

## Template Structure

All templates follow this standard structure:

```
template-name/
├── box.json                # CommandBox dependencies
├── server.json             # Server configuration
├── Application.cfc         # Application configuration
├── index.cfm              # Entry point
├── app/                   # Application code
│   ├── controllers/       # Controllers
│   ├── models/            # Models
│   └── views/             # Views
├── config/                # Configuration files
│   ├── routes.cfm         # URL routing
│   ├── settings.cfm       # Application settings
│   └── */                 # Environment-specific settings
├── db/                    # Database migrations
├── public/                # Public assets
├── tests/                 # Test files
└── vendor/                # Third-party dependencies
```

### Docker Dependency Isolation

When running templates with Docker:
- Dependencies (WireBox, TestBox) are installed in Docker named volumes
- Individual application directories are mounted to avoid creating empty directories on the host
- The vendor directory only exists within the container, not on your host filesystem
- This prevents any pollution of your repository during testing

## Contributing Templates

When creating new templates:

1. Follow the existing structure
2. Include comprehensive documentation
3. Ensure compatibility with all supported CFML engines
4. Test with multiple databases
5. Include example code demonstrating best practices

## Notes

- Templates are designed to work with Wheels 3.x+
- Docker images are pre-built and cached for faster startup
- The `.wheels-test/` directory is created for Docker files and is git-ignored
- Database credentials for testing are standardized across all templates