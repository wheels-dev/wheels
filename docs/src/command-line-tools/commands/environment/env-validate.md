# Wheels env validate

## Overview

The `wheels env validate` command validates the format and content of `.env` files in your Wheels project. This command helps ensure your environment configuration is properly formatted, contains required variables, and follows best practices. It's essential for catching configuration errors before deployment and maintaining consistent environment setups across different environments.

## Command Syntax

```bash
wheels env validate [options]
```

## Parameters

### Optional Parameters
- **`--file`** - The .env file to validate (default: `.env`)
- **`--required`** - Comma-separated list of required keys that must be present
- **`--verbose`** - Show detailed validation information including all variables

## Basic Usage Examples

### Validate Default .env File
```bash
wheels env validate
```
Validates the `.env` file in your project root

### Validate Specific File
```bash
wheels env validate --file=.env.production
```
Validates the `.env.production` file

### Check Required Variables
```bash
wheels env validate --required=DB_HOST,DB_USER,DB_PASSWORD
```
Validates that specific required variables are present

### Detailed Validation
```bash
wheels env validate --verbose
```
Shows detailed information about all variables found

## Advanced Usage Examples

### Production Deployment Validation
```bash
wheels env validate --file=.env.production --required=DB_HOST,DB_NAME,DB_USER,DB_PASSWORD,API_KEY
```
Ensures production environment has all critical variables

### Multi-Environment Validation
```bash
# Validate all environment files
wheels env validate --file=.env.development
wheels env validate --file=.env.staging  
wheels env validate --file=.env.production
```

### Required Variables by Environment
```bash
# Development requirements
wheels env validate --file=.env.development --required=DB_HOST,WHEELS_ENV

# Production requirements
wheels env validate --file=.env.production --required=DB_HOST,DB_NAME,DB_USER,DB_PASSWORD,API_KEY,WHEELS_ENV
```

### Comprehensive Validation
```bash
wheels env validate --file=.env.production --required=DB_HOST,API_KEY --verbose
```
Combines required variable checking with detailed output

## Validation Checks

### Format Validation
The command validates several aspects of your `.env` file format:

#### 1. File Format Detection
- **Properties format**: Standard `KEY=VALUE` pairs
- **JSON format**: Valid JSON structure
- Automatic detection based on content

#### 2. Syntax Validation
- **Missing equals sign**: `KEY VALUE` (invalid)
- **Empty key names**: `=value` (invalid)
- **Valid key=value format**: `KEY=value` (valid)

#### 3. Key Name Standards
- **Valid characters**: Letters, numbers, underscores only
- **Standard format**: `UPPER_SNAKE_CASE` recommended
- **Non-standard warnings**: Mixed case, special characters

### Content Validation

#### 1. Required Variables
```bash
wheels env validate --required=DB_HOST,API_KEY
```
Ensures specified variables are present and have values

#### 2. Duplicate Key Detection
Identifies when the same key appears multiple times:
```
Line 15: Duplicate key: 'DB_HOST' (previous value will be overwritten)
```

#### 3. Placeholder Detection
Identifies common placeholder values in sensitive variables:
- `your_password`
- `your_secret` 
- `change_me`
- `xxx`
- `TODO`

## Sample Output

### Successful Validation
```
Validating: .env

Summary:
  Total variables: 12

Validation passed with no issues!
```

### Validation with Warnings
```
Validating: .env.development

Warnings:
  Line 5: Non-standard key name: 'dbHost' (should contain only letters, numbers, and underscores)
  Line 12: Placeholder value detected for 'API_KEY'

Summary:
  Total variables: 8

Validation passed with 2 warnings
```

### Validation with Errors
```
Validating: .env.production

Errors found:
  Line 3: Invalid format (missing '='): DB_HOST localhost
  Required key missing: 'API_KEY'
  Line 8: Empty key name

Warnings:
  Line 10: Duplicate key: 'DB_PORT' (previous value will be overwritten)

Summary:
  Total variables: 6

Validation failed with 3 errors
```

### Verbose Output
```
Validating: .env

Summary:
  Total variables: 10

Environment Variables:

  DB:
    DB_HOST = localhost
    DB_NAME = myapp
    DB_PASSWORD = ***MASKED***
    DB_PORT = 3306
    DB_USER = admin

  API:
    API_BASE_URL = https://api.example.com
    API_KEY = ***MASKED***
    API_TIMEOUT = 30

  Other:
    APP_NAME = My Application
    WHEELS_ENV = development

Validation passed with no issues!
```

## Error Types and Solutions

### Format Errors

#### Missing Equals Sign
```
Error: Line 5: Invalid format (missing '='): DB_HOST localhost
```
**Solution**: Add equals sign: `DB_HOST=localhost`

#### Empty Key Name
```
Error: Line 8: Empty key name
```
**Solution**: Provide a key name: `MY_KEY=value`

#### Invalid JSON
```
Error: Invalid JSON format: Unexpected character at position 15
```
**Solution**: Fix JSON syntax or convert to properties format

### Content Errors

#### Required Key Missing
```
Error: Required key missing: 'API_KEY'
```
**Solution**: Add the missing variable: `API_KEY=your-api-key`

#### Empty Required Value
```
Warning: Required key has empty value: 'DB_PASSWORD'
```
**Solution**: Provide a value: `DB_PASSWORD=your-password`

### Warning Types

#### Non-Standard Key Name
```
Warning: Line 3: Non-standard key name: 'dbHost' (should contain only letters, numbers, and underscores)
```
**Recommendation**: Use `DB_HOST` instead of `dbHost`

#### Placeholder Value
```
Warning: Line 7: Placeholder value detected for 'API_KEY'
```
**Recommendation**: Replace placeholder with actual value

#### Duplicate Key
```
Warning: Line 12: Duplicate key: 'DB_PORT' (previous value will be overwritten)
```
**Recommendation**: Remove duplicate or rename one key

## Common Use Cases

### Pre-Deployment Validation
```bash
# Validate production config before deployment
wheels env validate --file=.env.production --required=DB_HOST,DB_NAME,DB_USER,DB_PASSWORD,API_KEY

# Check staging environment
wheels env validate --file=.env.staging --required=DB_HOST,API_KEY
```

### Development Workflow
```bash
# Quick validation during development
wheels env validate

# Detailed check when debugging
wheels env validate --verbose
```

### CI/CD Integration
```bash
# In your deployment pipeline
wheels env validate --file=.env.production --required=DB_HOST,API_KEY
if [ $? -ne 0 ]; then
    echo "Environment validation failed!"
    exit 1
fi
```

### Environment Setup Verification
```bash
# Validate new team member's setup
wheels env validate --required=DB_HOST,WHEELS_ENV,API_KEY

# Check if all environments are properly configured
for env in development staging production; do
    wheels env validate --file=.env.$env
done
```

### Configuration Auditing
```bash
# Regular audit of all environment files
wheels env validate --file=.env.development --verbose
wheels env validate --file=.env.production --verbose
```

## Best Practices

### 1. Regular Validation
```bash
# Add to your development routine
wheels env validate
```

### 2. Environment-Specific Requirements
```bash
# Define different requirements for different environments
wheels env validate --file=.env.development --required=DB_HOST,WHEELS_ENV
wheels env validate --file=.env.production --required=DB_HOST,DB_NAME,DB_USER,DB_PASSWORD,API_KEY
```

### 3. Pre-Commit Validation
```bash
# Add to git pre-commit hooks
#!/bin/sh
wheels env validate --file=.env.example
```

### 4. Deployment Pipeline Integration
```bash
# In CI/CD pipeline
wheels env validate --file=.env.production --required=DB_HOST,API_KEY
```

### 5. Use Verbose Mode for Documentation
```bash
# Generate configuration documentation
wheels env validate --verbose > config-validation-report.txt
```

## Integration with Other Commands

### With Environment Setup
```bash
# Set variables then validate
wheels env set DB_HOST=localhost DB_PORT=3306
wheels env validate --required=DB_HOST,DB_PORT
```

### With File Merging
```bash
# Merge files then validate result
wheels env merge .env.base .env.local --output=.env.merged
wheels env validate --file=.env.merged --required=DB_HOST,API_KEY
```

### With Configuration Display
```bash
# Validate then show configuration
wheels env validate --verbose
wheels env show
```

## Exit Codes

The command returns different exit codes for automation:
- **0**: Validation passed (may have warnings)
- **1**: Validation failed (has errors)

This makes it perfect for use in scripts and CI/CD pipelines:

```bash
if wheels env validate --file=.env.production; then
    echo "Production config is valid"
    # Continue with deployment
else
    echo "Production config has errors"
    exit 1
fi
```

## Tips and Recommendations

### Security Best Practices
- Use the validation to catch placeholder values in sensitive variables
- Regularly validate that required security-related variables are present
- Use `--verbose` mode carefully in CI/CD (sensitive values are masked but logs might be visible)

### Development Workflow
- Validate environment files before committing changes
- Use different required variable lists for different environments
- Set up validation as part of your local development setup script

### Team Collaboration
- Include validation in project setup documentation
- Use validation to ensure consistent environment setup across team members
- Define standard required variables for your project type

### Automation
- Integrate validation into deployment pipelines
- Use exit codes to fail deployments when validation errors occur
- Set up regular validation checks for configuration drift detection