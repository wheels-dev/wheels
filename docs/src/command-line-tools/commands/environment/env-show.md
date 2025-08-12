# Wheels env Show (Commnig Soon)

## Overview

The `wheels env show` command displays environment variables from `.env` files in your Wheels project. This command provides a convenient way to view your application's configuration, with intelligent grouping, security masking, and multiple output formats. It helps you understand what environment variables are available and how they're organized.

## Command Syntax

```bash
wheels env show [options]
```

## Parameters

### Optional Parameters
- **`--key`** - Show a specific environment variable by key name
- **`--format`** - Output format: `table` (default) or `json`
- **`--file`** - Specific .env file to read (default: `.env`)

## Basic Usage Examples

### Show All Variables (Default)
```bash
wheels env show
```
Displays all environment variables from `.env` in a grouped, readable table format

### Show Specific Variable
```bash
wheels env show --key=DB_HOST
```
Shows only the `DB_HOST` variable and its value

### Show in JSON Format  
```bash
wheels env show --format=json
```
Outputs all variables as formatted JSON

### Show from Different File
```bash
wheels env show --file=.env.production
```
Displays variables from `.env.production` instead of `.env`

## Advanced Usage Examples

### Development vs Production Comparison
```bash
# View development variables
wheels env show --file=.env.development

# View production variables  
wheels env show --file=.env.production
```

### Check Specific Configuration
```bash
# Check database configuration
wheels env show --key=DB_NAME
wheels env show --key=DB_HOST

# Check API settings
wheels env show --key=API_KEY
```

### Export Configuration
```bash
# Export as JSON for processing
wheels env show --format=json > config.json

# Check specific file in JSON format
wheels env show --file=.env.staging --format=json
```

## Output Formats

### Table Format (Default)
The table format groups variables by prefix and displays them in an organized, readable way:

```
Environment Variables Viewer

Environment Variables from .env:

DB_* Variables:
  DB_HOST = localhost
  DB_NAME = myapp
  DB_PASSWORD = ********
  DB_PORT = 3306
  DB_USER = wheels

API_* Variables:
  API_BASE_URL = https://api.example.com
  API_KEY = ********
  API_TIMEOUT = 30

WHEELS_* Variables:
  WHEELS_ENV = development
  WHEELS_RELOAD_PASSWORD = ********

Other Variables:
  APP_NAME = My Application
  DEBUG_MODE = true
  PORT = 3000

Tip: Access these in your app with application.env['KEY_NAME']
Or use them in config files: set(dataSourceName=application.env['DB_NAME'])
Wheels automatically loads .env on application start
```

### JSON Format
Clean JSON output suitable for processing or integration:

```json
{
  "API_BASE_URL": "https://api.example.com",
  "API_KEY": "********",
  "APP_NAME": "My Application",
  "DB_HOST": "localhost",
  "DB_NAME": "myapp",
  "DB_PASSWORD": "********",
  "DB_PORT": "3306",
  "DEBUG_MODE": "true",
  "WHEELS_ENV": "development"
}
```

### Specific Key Output
When requesting a specific key:

```
Environment Variable: DB_HOST
Value: localhost
Source: .env
```

## Features

### Intelligent Grouping
Variables are automatically grouped by prefix for better organization:
- **DB_*** variables (database configuration)
- **API_*** variables (API settings)  
- **WHEELS_*** variables (framework settings)
- **Other Variables** (ungrouped items)

### Security Masking
Sensitive values are automatically masked when displayed:
- Variables containing `password` → `********`
- Variables containing `secret` → `********`
- Variables containing `key` → `********`

The actual values remain unchanged in your files - only the display is masked.

### Supported File Formats

#### Properties Format (Standard .env)
```bash
## Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_NAME=myapp
DB_USER=wheels
DB_PASSWORD="secret123"

## Application Settings  
WHEELS_ENV=development
DEBUG_MODE=true
```

#### JSON Format
```json
{
  "DB_HOST": "localhost",
  "DB_PORT": "3306",
  "DB_NAME": "myapp",
  "WHEELS_ENV": "development",
  "DEBUG_MODE": "true"
}
```

### Quote Handling
The command automatically handles quoted values:
- Double quotes: `KEY="value with spaces"`
- Single quotes: `KEY='another value'`
- Quotes are stripped from displayed values

## Error Handling and Validation

### Project Validation
The command ensures you're in a valid Wheels project:
```
This command must be run from a Wheels project root directory
```

### Missing File Handling
If the specified `.env` file doesn't exist, you'll see helpful guidance:
```
No .env file found in project root

Create a .env file with key=value pairs, for example:

## Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_NAME=myapp
DB_USER=wheels
DB_PASSWORD=secret

## Application Settings
WHEELS_ENV=development
WHEELS_RELOAD_PASSWORD=mypassword
```

### Key Not Found
When requesting a specific key that doesn't exist:
```
Environment variable 'MISSING_KEY' not found

Available keys in .env:
  - API_KEY
  - DB_HOST
  - DB_NAME
  - DEBUG_MODE
  - WHEELS_ENV
```

## Common Use Cases

### Configuration Review
```bash
# Review all current settings
wheels env show

# Check what's different between environments
wheels env show --file=.env.development
wheels env show --file=.env.production
```

### Debugging Configuration Issues
```bash
# Check if a specific variable is set
wheels env show --key=DB_HOST

# Verify API configuration
wheels env show --key=API_BASE_URL
wheels env show --key=API_KEY
```

### Environment Setup Verification
```bash
# Verify development setup
wheels env show --file=.env.development

# Check staging configuration
wheels env show --file=.env.staging
```

### Documentation and Export
```bash
# Generate configuration documentation
wheels env show --format=json > docs/environment-config.json

# Create environment template
wheels env show --file=.env.example
```

### Integration with Wheels Framework
The command provides helpful tips on how to use the variables in your Wheels application:

```cfml
<!-- In your Wheels application -->
<cfset dataSource = application.env['DB_NAME']>
<cfset apiKey = application.env['API_KEY']>
<cfset debugMode = application.env['DEBUG_MODE']>

<!-- In config files -->
<cfset set(dataSourceName=application.env['DB_NAME'])>
<cfset set(URLRewriting=application.env['URL_REWRITING'])>
```

## Best Practices

### 1. Regular Configuration Review
```bash
# Regularly review your environment configuration
wheels env show
```

### 2. Environment-Specific Checks
```bash
# Always verify environment-specific settings
wheels env show --file=.env.production --key=WHEELS_ENV
wheels env show --file=.env.development --key=DEBUG_MODE
```

### 3. Security Verification
```bash
# Check that sensitive values are properly set
wheels env show --key=API_KEY
wheels env show --key=DB_PASSWORD
```

### 4. Documentation Generation  
```bash
# Generate configuration documentation
wheels env show --format=json > config-docs.json
```

### 5. Troubleshooting Workflow
```bash
# When debugging configuration issues:
# 1. Check if variable exists
wheels env show --key=PROBLEMATIC_VAR

# 2. Review all variables for typos
wheels env show

# 3. Compare against working environment
wheels env show --file=.env.working
```

## Integration Tips

### With Other Wheels Commands
```bash
# View current config, then update if needed
wheels env show --key=DB_HOST
wheels env set DB_HOST=newhost.com

# Check merged configuration
wheels env merge .env.base .env.local --dry-run
wheels env show --file=.env.merged
```

### CI/CD Integration
```bash
# In deployment scripts
wheels env show --file=.env.production --format=json | jq '.DB_HOST'
```

### Development Workflow
```bash
# Quick environment check during development
wheels env show --key=WHEELS_ENV
wheels env show --key=DEBUG_MODE
```

## Tips and Shortcuts

- **Grouped display** makes it easy to understand related configurations
- **Security masking** protects sensitive data during demos or screen sharing
- **JSON output** is perfect for automation and integration scripts
- **Helpful error messages** guide you when files are missing or keys don't exist
- **Project validation** ensures you're running the command in the right location
- **Multiple file support** lets you easily compare different environment configurations