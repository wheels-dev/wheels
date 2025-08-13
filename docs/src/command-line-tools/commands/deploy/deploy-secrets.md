# wheels deploy secrets (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Manage deployment secrets and sensitive configuration.

## Synopsis

```bash
wheels deploy secrets [action] [name] [value] [options]
```

## Description

The `wheels deploy secrets` command provides secure management of sensitive data like API keys, database passwords, and other credentials used during deployment. Secrets are encrypted and stored separately from your codebase.

## Actions

| Action | Description |
|--------|-------------|
| `list` | List all secrets for a target |
| `set` | Set or update a secret |
| `get` | Retrieve a secret value |
| `delete` | Remove a secret |
| `sync` | Synchronize secrets with target |
| `rotate` | Rotate secret values |
| `export` | Export secrets to file |
| `import` | Import secrets from file |

## Arguments

| Argument | Description | Required |
|----------|-------------|----------|
| `action` | Action to perform | Yes |
| `name` | Secret name | For set/get/delete |
| `value` | Secret value | For set action |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--target` | Deployment target | `production` |
| `--env-file` | Environment file for bulk operations | |
| `--format` | Output format (table, json, dotenv) | `table` |
| `--force` | Skip confirmation prompts | `false` |
| `--encrypt` | Encryption method (aes256, rsa) | `aes256` |
| `--key-file` | Path to encryption key | `.wheels-deploy-key` |
| `--help` | Show help information | |

## Examples

### Set a secret
```bash
wheels deploy secrets set DB_PASSWORD mySecretPass123 --target=production
```

### Set secret interactively (hidden input)
```bash
wheels deploy secrets set API_KEY --target=production
# Prompts for value without displaying it
```

### List all secrets
```bash
wheels deploy secrets list --target=production
```

### Get a specific secret
```bash
wheels deploy secrets get DB_PASSWORD --target=production
```

### Delete a secret
```bash
wheels deploy secrets delete OLD_API_KEY --target=production
```

### Import from .env file
```bash
wheels deploy secrets import --env-file=.env.production --target=production
```

### Export secrets
```bash
wheels deploy secrets export --target=production --format=dotenv > .env.backup
```

### Rotate database password
```bash
wheels deploy secrets rotate DB_PASSWORD --target=production
```

## Secret Storage

Secrets are stored encrypted in:
- Local: `.wheels-deploy-secrets/[target].enc`
- Remote: Deployment target's secure storage

### Encryption

Secrets are encrypted using:
- AES-256 encryption by default
- Unique key per environment
- Optional RSA public key encryption

### Key Management

Encryption keys stored in:
```
.wheels-deploy-key        # Default key file
.wheels-deploy-key.pub    # Public key (RSA)
.wheels-deploy-key.priv   # Private key (RSA)
```

## Secret Types

### Environment Variables
Standard key-value pairs:
```bash
wheels deploy secrets set DATABASE_URL "mysql://user:pass@host/db"
wheels deploy secrets set REDIS_URL "redis://localhost:6379"
```

### File-based Secrets
Store file contents as secrets:
```bash
wheels deploy secrets set SSL_CERT --file=/path/to/cert.pem
wheels deploy secrets set SSH_KEY --file=~/.ssh/id_rsa
```

### Multi-line Secrets
```bash
wheels deploy secrets set PRIVATE_KEY --multiline
# Enter/paste content, end with Ctrl+D
```

## Bulk Operations

### Import from .env
```bash
# Import all variables from .env file
wheels deploy secrets import --env-file=.env.production

# Import with prefix
wheels deploy secrets import --env-file=.env --prefix=APP_
```

### Export Formats

Table format:
```bash
wheels deploy secrets list
```

JSON format:
```bash
wheels deploy secrets list --format=json
```

DotEnv format:
```bash
wheels deploy secrets export --format=dotenv
```

## Secret Rotation

Rotate secrets with automatic update:

```bash
# Rotate with auto-generated value
wheels deploy secrets rotate DB_PASSWORD

# Rotate with custom value
wheels deploy secrets rotate API_KEY --value=newKey123

# Rotate multiple secrets
wheels deploy secrets rotate DB_PASSWORD,REDIS_PASSWORD,API_KEY
```

## Synchronization

Sync secrets to deployment target:

```bash
# Sync all secrets
wheels deploy secrets sync --target=production

# Verify sync status
wheels deploy secrets sync --target=production --dry-run
```

## Access Control

### Team Sharing
Share encrypted secrets with team:
```bash
# Export encrypted secrets
wheels deploy secrets export --target=production --encrypted > secrets.enc

# Import on another machine
wheels deploy secrets import --file=secrets.enc --key-file=team-key
```

### Permission Levels
- Read: View secret names only
- Write: Set/update secrets
- Admin: Delete/rotate secrets

## Integration

### During Deployment
Secrets automatically injected:
```json
{
  "hooks": {
    "pre-deploy": [
      "wheels deploy secrets sync"
    ]
  }
}
```

### In Application
Access secrets via environment:
```cfml
<cfset dbPassword = env("DB_PASSWORD", "")>
<cfset apiKey = env("API_KEY", "")>
```

## Security Best Practices

1. **Never commit secrets** to version control
2. **Use strong encryption** keys
3. **Rotate secrets regularly**
4. **Limit access** to production secrets
5. **Audit secret usage** via logs
6. **Use different secrets** per environment

## Backup and Recovery

### Backup Secrets
```bash
# Encrypted backup
wheels deploy secrets export --target=production --encrypted > backup-$(date +%Y%m%d).enc

# Secure offsite backup
wheels deploy secrets export | gpg -c > secrets.gpg
```

### Restore Secrets
```bash
# From encrypted backup
wheels deploy secrets import --file=backup-20240115.enc

# From GPG encrypted file
gpg -d secrets.gpg | wheels deploy secrets import
```

## Troubleshooting

### Common Issues

1. **Encryption key not found**:
   ```bash
   wheels deploy secrets init --generate-key
   ```

2. **Permission denied**:
   - Check file permissions on key files
   - Verify user has deployment access

3. **Secret not available during deployment**:
   - Ensure secrets are synced
   - Check target configuration

## Use Cases

1. **Database Credentials**: Secure database passwords
2. **API Keys**: Third-party service credentials
3. **SSL Certificates**: Secure certificate storage
4. **OAuth Secrets**: Client secrets for OAuth
5. **Encryption Keys**: Application encryption keys

## Notes

- Secrets are never logged or displayed in plain text
- Use environment-specific secrets
- Regular rotation improves security
- Keep encryption keys secure and backed up
- Monitor secret access in production

## See Also

- [wheels deploy init](deploy-init.md) - Initialize deployment
- [wheels deploy exec](deploy-exec.md) - Execute deployment
- [wheels config set](../config/config-set.md) - Set configuration values
- [Security Best Practices](../../security/best-practices.md)