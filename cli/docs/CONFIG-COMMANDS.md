# Wheels CLI Configuration Commands

This document describes the configuration and security commands implemented for the Wheels CLI framework.

## Overview

The configuration commands provide tools for managing, validating, and comparing environment configurations in Wheels applications. These commands help developers maintain consistent configurations across different environments and ensure security best practices.

## Commands

### config:dump

Export configuration settings for an environment.

**Usage:**
```bash
# Dump current environment config
wheels config:dump

# Dump specific environment config
wheels config:dump production

# Export to different formats
wheels config:dump --format=json       # Default
wheels config:dump --format=env        # .env format
wheels config:dump --format=cfml       # CFML struct format

# Save to file
wheels config:dump --output=config.json

# Show sensitive values (not recommended)
wheels config:dump --mask=false
```

**Features:**
- Exports configuration from .env files and config/environment/*.cfm files
- Masks sensitive values by default (passwords, keys, tokens, etc.)
- Supports multiple output formats
- Can save directly to file

### config:check

Validate configuration settings and identify potential issues.

**Usage:**
```bash
# Check current environment
wheels config:check

# Check specific environment
wheels config:check production

# Show detailed information
wheels config:check --verbose

# Attempt to fix issues
wheels config:check --fix
```

**Validation Checks:**
- Required configuration files (settings.cfm, app.cfm, routes.cfm)
- Environment-specific files and .env files
- Database configuration
- Security settings (reload password, encryption salt, secure cookies)
- Server configuration (server.json)
- Dependencies (box.json, Wheels installation)

**Auto-fix Capabilities:**
- Create missing server.json
- Create basic configuration files
- Generate basic settings structure

### config:diff

Compare configuration between environments.

**Usage:**
```bash
# Compare two environments
wheels config:diff development production

# Compare with current environment
wheels config:diff production

# Show only differences
wheels config:diff development production --changes-only

# Output as JSON
wheels config:diff development production --format=json
```

**Features:**
- Side-by-side comparison of configuration values
- Highlights differences, unique keys, and identical values
- Calculates configuration similarity percentage
- Masks sensitive values in output
- Table or JSON output formats

### secret

Generate secure secret keys for application security.

**Usage:**
```bash
# Generate a random secret key
wheels secret

# Generate with specific length
wheels secret --length=64

# Generate multiple keys
wheels secret --count=5

# Generate and save to .env file
wheels secret --save
wheels secret --save --key=MY_SECRET_KEY

# Generate specific types
wheels secret --type=hex          # Hexadecimal (default)
wheels secret --type=base64       # Base64 encoded
wheels secret --type=alphanumeric # Letters and numbers
wheels secret --type=uuid         # UUID format
```

**Features:**
- Uses Java SecureRandom for cryptographically strong randomness
- Multiple format options for different use cases
- Can save directly to .env file
- Provides security recommendations based on key type and length
- Shows usage examples for generated keys

## Security Considerations

1. **Sensitive Value Masking**: By default, all commands mask sensitive values containing keywords like "password", "secret", "key", "token", etc.

2. **Environment Isolation**: Commands respect environment boundaries and don't cross-contaminate configuration between environments.

3. **Secure Key Generation**: The `secret` command uses cryptographically secure random number generation suitable for encryption keys and tokens.

4. **Best Practices Enforcement**: The `config:check` command validates security settings and warns about common issues like:
   - Default passwords in production
   - Missing encryption salts
   - Insecure cookie settings

## Integration with Existing Tools

These commands integrate with:
- **commandbox-dotenv**: For .env file management
- **Wheels configuration system**: Reads from config/environment/*.cfm files
- **CommandBox server management**: Uses server.json for server configuration

## Examples

### Setting up a new environment
```bash
# Generate a secret key for the new environment
wheels secret --save --key=ENCRYPTION_SALT

# Check configuration is valid
wheels config:check

# Compare with production to ensure consistency
wheels config:diff development production
```

### Debugging configuration issues
```bash
# Check for problems
wheels config:check --verbose

# Export current config to review
wheels config:dump --format=env > current-config.env

# Compare with working environment
wheels config:diff broken-env working-env
```

### Security audit
```bash
# Check all environments for security issues
wheels config:check development
wheels config:check staging
wheels config:check production

# Generate new secrets for rotation
wheels secret --count=3 --length=64
```

## Testing

The configuration commands include comprehensive tests in `/tests/cli/commands/ConfigCommandsTest.cfc` that verify:
- Configuration export functionality
- Validation rules and error detection
- Environment comparison logic
- Secret key generation and entropy
- File operations and error handling

## Future Enhancements

Potential future improvements could include:
- Integration with external secret management systems
- Configuration templates for common scenarios
- Encrypted configuration storage
- Configuration history and versioning
- Remote configuration synchronization