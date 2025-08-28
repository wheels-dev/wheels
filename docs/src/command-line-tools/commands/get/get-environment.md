# Wheels get environment

## Overview

The `wheels get environment` command displays the current environment setting for your Wheels application. It automatically detects which environment your application is configured to run in (development, staging, production, etc.) and shows where this configuration is coming from.

## Command Syntax

```bash
wheels get environment
```
## Alias

```bash
wheels get env
```

## Parameters

This command takes no parameters.

## Basic Usage

### Display Current Environment
```bash
wheels get environment
```

This will output something like:
```
Current Environment:
development

Configured in: .env file (WHEELS_ENV)
```

## How It Works

### Detection Priority

The command checks for environment configuration in the following order of precedence:

1. **`.env` file** - Looks for `WHEELS_ENV` variable first, then `Environment` variable
2. **System environment variable** - Checks for `WHEELS_ENV` first, then `Environment` system variable
3. **Default** - Falls back to `development` if no configuration is found

The first valid configuration found is used and reported, along with which specific variable name was found.

### Configuration Sources

#### 1. .env File
The command first looks for a `WHEELS_ENV` variable in your application's `.env` file:
```bash
# .env file - Primary variable
WHEELS_ENV=production
DATABASE_HOST=localhost
```

If `WHEELS_ENV` is not found, it then checks for `Environment`:
```bash
# .env file - Alternative variable
Environment=staging
DATABASE_HOST=localhost
```

The regex pattern used ensures it correctly reads the value while ignoring:
- Comments after the value (anything after `#`)
- Trailing whitespace
- Lines that are commented out

#### 2. System Environment Variable
If not found in `.env`, it checks for system-level environment variables in the same order:
```bash
# Linux/Mac - Primary variable
export WHEELS_ENV=staging

# Windows - Primary variable
set WHEELS_ENV=staging

# Or using the alternative variable
export Environment=production
```

#### 3. Default Value
If no configuration is found anywhere, it defaults to `development`.

## Variable Priority

The command checks for two different variable names in this specific order:

1. `WHEELS_ENV` in `.env` file
2. `Environment` in `.env` file
3. `WHEELS_ENV` system environment variable
4. `Environment` system environment variable
5. Default to `development`

## Output Examples

### Configured with WHEELS_ENV in .env
```
Current Environment:
production

Configured in: .env file (WHEELS_ENV)
```

### Configured with Environment in .env
```
Current Environment:
staging

Configured in: .env file (Environment)
```

### Configured via System Variable (WHEELS_ENV)
```
Current Environment:
staging

Configured in: System environment variable (WHEELS_ENV)
```

### Configured via System Variable (Environment)
```
Current Environment:
production

Configured in: System environment variable (Environment)
```

### Using Default
```
Current Environment:
development

Configured in: Using default
```

## Common Use Cases

### Verify Environment Before Deployment
```bash
# Check environment before starting server
wheels get environment
commandbox server start
```

### Troubleshooting Configuration Issues
```bash
# Verify which configuration source and variable is being used
wheels get environment

# Check each source manually
cat .env | grep -E "WHEELS_ENV|Environment"
echo $WHEELS_ENV
echo $Environment
```

### CI/CD Pipeline Verification
```bash
# In deployment script
wheels get environment
if [ $? -eq 0 ]; then
    echo "Environment configured successfully"
fi
```

### Supporting Legacy Systems
```bash
# If migrating from a system that uses "Environment" variable
# Both will work without changes:
# Old: Environment=production
# New: WHEELS_ENV=production
wheels get environment
```

## Error Handling

The command will show an error if:
- It's not run from a Wheels application directory
- There's an error reading configuration files
- File permissions prevent reading configuration

### Not a Wheels Application
```
Error: This command must be run from a Wheels application directory
```

### Read Error
```
Error reading environment: [specific error message]
```

## Best Practices

1. **Use WHEELS_ENV** - Prefer `WHEELS_ENV` over `Environment` for clarity and consistency

2. **Consistent Configuration** - Use one primary method for setting environment across your team

3. **Environment-Specific Files** - Consider using `.env.production`, `.env.development` files with the merge command

4. **Don't Commit Production Settings** - Keep production `.env` files out of version control

5. **Document Your Setup** - Document which configuration method and variable name your team uses

6. **Verify Before Deployment** - Always run this command to verify environment before deploying

## Environment Precedence

Understanding precedence is important when multiple configurations exist:

```
.env file - WHEELS_ENV (highest priority)
    ↓
.env file - Environment
    ↓
System variable - WHEELS_ENV
    ↓
System variable - Environment
    ↓
Default: development (lowest priority)
```

If both `WHEELS_ENV` and `Environment` are set in `.env`, only `WHEELS_ENV` will be used.

## Migration Guide

If you're migrating from a system that uses different environment variable names:

### From "Environment" to "WHEELS_ENV"
```bash
# Old configuration
Environment=production

# New configuration (both work)
WHEELS_ENV=production

# The command will detect either one
wheels get environment
```

### Gradual Migration
You can migrate gradually since the command checks both:
1. Leave existing `Environment` variables in place
2. Start using `WHEELS_ENV` for new deployments
3. The command will prefer `WHEELS_ENV` when both exist

## Integration with Other Commands

This command works well with other Wheels CLI commands:

```bash
# Check environment, then run migrations
wheels get environment
wheels db migrate

# Verify environment before running tests
wheels get environment
wheels test

# Check environment, then start server
wheels get environment
commandbox server start
```

## Tips

- The command must be run from your Wheels application root directory
- Environment values are case-sensitive (`development` ≠ `Development`)
- Comments in `.env` files are properly ignored using `#`
- Whitespace around values is automatically trimmed
- The command clearly shows which variable name was found
- `WHEELS_ENV` takes precedence over `Environment` when both exist

## Troubleshooting

### Environment Not Changing
If changing environment variables doesn't seem to work:
1. Run `wheels get environment` to see which source and variable is being used
2. Remember `.env` file takes precedence over system variables
3. Remember `WHEELS_ENV` takes precedence over `Environment`
4. Restart your CommandBox server after changes
5. Check for typos in variable names

### Variable Priority Issues
If the wrong environment is being detected:
- Check if both `WHEELS_ENV` and `Environment` are set
- Remember `WHEELS_ENV` has higher priority
- Use the output to see exactly which variable is being read

### Permission Errors
If you get permission errors:
- Ensure you have read access to `.env` files
- Check that you're in the correct directory
- Verify file ownership and permissions

### Unexpected Default
If you're getting the default `development` when you expect a different value:
- Check for typos in configuration files (it's `WHEELS_ENV` not `WHEEL_ENV`)
- Ensure `.env` file is in the application root
- Verify system environment variables are properly exported
- Check that values don't have quotes unless intended