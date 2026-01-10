# Wheels env set

## Overview

The `wheels env set` command allows you to set or update environment variables in `.env` files. This command provides a quick and safe way to modify environment configuration files directly from the command line, supporting both creation of new variables and updating of existing ones.

## Synopsis

```bash
wheels env set KEY=VALUE [KEY2=VALUE2 ...] [--file=filename]
```

## CommandBox Parameter Syntax

This command supports multiple parameter formats:

- **Named parameters**: `KEY=VALUE` (e.g., `DB_HOST=localhost`, `API_KEY=secret`)
- **Flag parameters**: `--flag=value` (e.g., `--file=.env.production`)

**Parameter Mixing Rules:**

✅ **ALLOWED:**
- Named KEY=VALUE pairs: `wheels env set DB_HOST=localhost DB_PORT=3306`
- Named + file flag: `wheels env set DB_HOST=localhost --file=.env.production`
- Multiple variables: `wheels env set KEY1=value1 KEY2=value2 KEY3=value3`

❌ **NOT ALLOWED:**
- Positional parameters: This command does not support positional parameters

**Recommendation:** Use KEY=VALUE format with optional --file flag: `wheels env set DB_HOST=localhost --file=.env.production`

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| KEY=VALUE | KEY=VALUE | Yes | One or more environment variable assignments in KEY=VALUE format |
| --file | string | No | The .env file to update (default: `.env`) |

## Basic Usage Examples

### Set a Single Variable
```bash
wheels env set DB_HOST=localhost
```
Sets `DB_HOST` to `localhost` in the `.env` file

### Set Multiple Variables
```bash
wheels env set DB_PORT=3306 DB_NAME=myapp DB_USER=root
```
Sets multiple database-related variables in a single command

### Update Specific File
```bash
wheels env set --file=.env.production API_KEY=secret
```
Updates the `.env.production` file instead of the default `.env`

### Complex Values
```bash
wheels env set DATABASE_URL="mysql://user:pass@localhost:3306/db"
wheels env set API_ENDPOINT=https://api.example.com/v1
```
Sets variables with complex values including special characters

## How It Works

### File Handling
The command intelligently handles different scenarios:

1. **Existing File**: Updates or adds variables to the existing file
2. **Non-existent File**: Creates a new file with the specified variables
3. **Format Detection**: Automatically detects and preserves the file format (properties or JSON)

### Supported File Formats

#### Properties Format (Standard .env)
```env
DATABASE_HOST=localhost
DATABASE_PORT=3306
API_KEY=your-secret-key
```

#### JSON Format
```json
{
  "DATABASE_HOST": "localhost",
  "DATABASE_PORT": "3306",
  "API_KEY": "your-secret-key"
}
```

### Update Behavior

- **Existing Variables**: Overwrites the current value with the new one
- **New Variables**: Appends to the end of the file (for properties format)
- **Comments**: Preserves existing comments and empty lines
- **Line Format**: Maintains the original file structure and formatting

### Special Value Handling

- **Trailing Commas**: Automatically removes trailing commas from values
- **Equal Signs**: Values can contain `=` signs (everything after the first `=` is the value)
- **Whitespace**: Trims leading and trailing whitespace from keys and values
- **Special Characters**: Properly handles URLs, connection strings, and other complex values

## Security Features

### Sensitive Value Masking
When displaying updated variables, the command automatically masks sensitive values:
- Variables containing `password`, `secret`, `key`, or `token` (case-insensitive)
- Masked values appear as `***MASKED***` in the output
- Actual values are still written correctly to the file

### Git Security Warning
The command checks if your `.env` file is listed in `.gitignore`:
- Displays a warning if the file is not ignored
- Recommends adding it to prevent committing secrets
- Only checks when working with files containing `.env` in the name

## Output Information

After successful execution, the command displays:
- Confirmation message with the filename
- List of all updated/added variables
- Masked display for sensitive values
- Git security warning (if applicable)

### Sample Output
```
Environment variables updated in .env:
  DB_HOST = localhost
  DB_PORT = 3306
  DB_PASSWORD = ***MASKED***
  API_KEY = ***MASKED***

Warning: .env is not in .gitignore!
  Add it to .gitignore to prevent committing secrets.
```

## Common Use Cases

### Initial Setup
```bash
# Create a new .env file with basic configuration
wheels env set APP_NAME=MyApp APP_ENV=development DEBUG=true
```

### Database Configuration
```bash
# Set all database variables at once
wheels env set DB_HOST=localhost DB_PORT=5432 DB_NAME=myapp DB_USER=appuser DB_PASSWORD=secret
```

### API Configuration
```bash
# Configure API endpoints and keys
wheels env set API_BASE_URL=https://api.example.com API_KEY=abc123 API_TIMEOUT=30
```

### Environment-Specific Settings
```bash
# Development settings
wheels env set --file=.env.development DEBUG=true LOG_LEVEL=debug

# Production settings
wheels env set --file=.env.production DEBUG=false LOG_LEVEL=error
```

### Updating Existing Values
```bash
# Change database host from localhost to production server
wheels env set DB_HOST=db.production.com

# Update multiple values
wheels env set APP_ENV=production DEBUG=false
```

## File Creation Behavior

When creating a new file, the command adds:
- Header comment indicating it was generated by the command
- Timestamp comment (optional)
- All specified variables

Example of a newly created file:
```env
# Wheels Environment Configuration
# Generated by wheels env set command

APP_NAME=MyApplication
APP_ENV=development
DEBUG=true
```

## Error Handling

The command will display an error and stop if:
- No KEY=VALUE pairs are provided
- File write permissions are insufficient
- The file path is invalid
- File system errors occur (disk full, etc.)

### Error Messages
```bash
# No arguments provided
Error: No key=value pairs provided. Usage: wheels env set KEY=VALUE

# File write failure
Error: Failed to update .env file: [specific error message]
```

## Best Practices

1. **Use quotes for complex values** containing spaces or special characters:
   ```bash
   wheels env set CONNECTION_STRING="Server=localhost;Database=myapp;User=root"
   ```

2. **Update multiple related variables together** to maintain consistency:
   ```bash
   wheels env set DB_HOST=newhost DB_PORT=3306 DB_NAME=newdb
   ```

3. **Keep sensitive values in separate files** not tracked by version control:
   ```bash
   wheels env set --file=.env.local API_SECRET=very-secret-key
   ```

4. **Always check .gitignore** to ensure sensitive files are not committed:
   ```bash
   echo ".env" >> .gitignore
   echo ".env.local" >> .gitignore
   ```

5. **Use environment-specific files** for different deployments:
   ```bash
   wheels env set --file=.env.production APP_ENV=production
   wheels env set --file=.env.staging APP_ENV=staging
   ```

## Tips and Tricks

### Batch Updates
Update multiple variables from different categories in one command:
```bash
wheels env set \
  APP_NAME=MyApp \
  DB_HOST=localhost \
  DB_PORT=5432 \
  CACHE_DRIVER=redis \
  MAIL_HOST=smtp.example.com
```

### Quick Environment Switch
```bash
# Switch to production settings
wheels env set APP_ENV=production DEBUG=false LOG_LEVEL=error

# Switch back to development
wheels env set APP_ENV=development DEBUG=true LOG_LEVEL=debug
```

### Creating Templates
```bash
# Create a template file for new projects
wheels env set --file=.env.example \
  APP_NAME=YourAppName \
  APP_ENV=development \
  DB_HOST=localhost \
  DB_PORT=3306 \
  DB_NAME=your_database \
  DB_USER=your_user \
  DB_PASSWORD=your_password
```

## Important Notes

1. **File Format Preservation**: The command preserves the original format (JSON or properties)
2. **Comment Preservation**: Existing comments and empty lines are maintained
3. **Atomic Updates**: All variables are updated in a single operation
4. **No Validation**: The command doesn't validate variable values
5. **Case Sensitive**: Variable names are case-sensitive
6. **Overwrite Behavior**: Existing values are always overwritten
7. **Trailing Comma Removal**: Automatically cleans trailing commas from values


## Security Recommendations

1. **Never commit .env files** containing real credentials
2. **Use .env.example** files as templates with dummy values
3. **Keep production secrets** in secure vaults or CI/CD systems
4. **Rotate credentials regularly** using this command
5. **Review git history** before pushing to ensure no secrets were committed