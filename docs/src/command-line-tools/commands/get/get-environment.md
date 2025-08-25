# Wheels get environment

## Overview

The `wheels get environment` command displays the current environment setting for your Wheels application. It automatically detects which environment your application is configured to run in (development, staging, production, etc.) and shows where this configuration is coming from.

## Command Syntax

```bash
wheels get environment
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

Configured in: .env file
```

## How It Works

### Detection Priority

The command checks for environment configuration in the following order of precedence:

1. **`.env` file** - Looks for `WHEELS_ENV` variable in your `.env` file
2. **System environment variable** - Checks the `WHEELS_ENV` system environment variable
3. **`server.json`** - Looks for `env.WHEELS_ENV` in your CommandBox `server.json` file
4. **Default** - Falls back to `development` if no configuration is found

The first valid configuration found is used and reported.

### Configuration Sources

#### 1. .env File
The command looks for a `WHEELS_ENV` variable in your application's `.env` file:
```bash
# .env file
WHEELS_ENV=production
DATABASE_HOST=localhost
```

The regex pattern used ensures it correctly reads the value while ignoring:
- Comments after the value
- Trailing whitespace
- Lines that are commented out

#### 2. System Environment Variable
If not found in `.env`, it checks for a system-level environment variable:
```bash
# Linux/Mac
export WHEELS_ENV=staging

# Windows
set WHEELS_ENV=staging
```

#### 3. server.json Configuration
For CommandBox deployments, it checks the `server.json` file:
```json
{
  "env": {
    "WHEELS_ENV": "production"
  }
}
```

#### 4. Default Value
If no configuration is found anywhere, it defaults to `development`.

## Output Examples

### Configured in .env File
```
Current Environment:
production

Configured in: .env file
```

### Configured via System Variable
```
Current Environment:
staging

Configured in: System environment variable
```

### Configured in server.json
```
Current Environment:
production

Configured in: server.json
```

### Using Default
```
Current Environment:
development

Using default: development
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
# Verify which configuration source is being used
wheels get environment

# If unexpected, check each source in order
cat .env | grep WHEELS_ENV
echo $WHEELS_ENV
cat server.json | grep WHEELS_ENV
```

### CI/CD Pipeline Verification
```bash
# In deployment script
wheels get environment
if [ $? -eq 0 ]; then
    echo "Environment configured successfully"
fi
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

1. **Consistent Configuration** - Use one primary method for setting environment across your team

2. **Environment-Specific Files** - Consider using `.env.production`, `.env.development` files with the merge command

3. **Don't Commit Production Settings** - Keep production `.env` files out of version control

4. **Document Your Setup** - Document which configuration method your team uses in your README

5. **Verify Before Deployment** - Always run this command to verify environment before deploying

## Environment Precedence

Understanding precedence is important when multiple configurations exist:

```
.env file (highest priority)
    ↓
System environment variable
    ↓
server.json
    ↓
Default: development (lowest priority)
```

If `WHEELS_ENV` is set in both `.env` and as a system variable, the `.env` value takes precedence.

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
- The environment value is case-sensitive (`development` ≠ `Development`)
- Comments in `.env` files are properly ignored
- Whitespace around values is automatically trimmed
- The command provides clear feedback about where the configuration is coming from

## Troubleshooting

### Environment Not Changing
If changing `WHEELS_ENV` doesn't seem to work:
1. Run `wheels get environment` to see which source is being used
2. Remember `.env` file takes precedence over system variables
3. Restart your CommandBox server after changes
4. Check for typos in the variable name (`WHEELS_ENV` not `WHEEL_ENV`)

### Permission Errors
If you get permission errors:
- Ensure you have read access to `.env` and `server.json` files
- Check that you're in the correct directory
- Verify file ownership and permissions

### Unexpected Default
If you're getting the default `development` when you expect a different value:
- Check for typos in configuration files
- Ensure `.env` file is in the application root
- Verify system environment variables are properly exported
- Check that `server.json` has the correct structure