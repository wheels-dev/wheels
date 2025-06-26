# wheels deploy init

Initialize deployment configuration for your Wheels application.

## Synopsis

```bash
wheels deploy:init [options]
```

## Description

The `wheels deploy:init` command creates a deployment configuration file (`deploy.json`), generates a Dockerfile, and sets up environment templates for deploying your Wheels application using Docker and container orchestration.

## Options

- `provider=<string>` - Cloud provider: digitalocean, aws, linode, custom (default: custom)
- `servers=<string>` - Comma-separated list of server IPs for custom provider
- `domain=<string>` - Primary domain for the application
- `app-name=<string>` - Application name for deployment
- `db=<string>` - Database type: mysql, postgres, mssql (default: mysql)
- `cfengine=<string>` - CF engine: lucee, adobe (default: lucee)
- `environment=<string>` - Environment name (creates deploy.{environment}.json)
- `--force` - Overwrite existing deploy.json (default: false)

## Examples

### Interactive initialization
```bash
wheels deploy:init
```

### Initialize with custom servers
```bash
wheels deploy:init provider=custom servers=192.168.1.100,192.168.1.101 domain=myapp.com
```

### Initialize for DigitalOcean
```bash
wheels deploy:init provider=digitalocean domain=myapp.com app-name=myapp
```

### Initialize with PostgreSQL and Adobe ColdFusion
```bash
wheels deploy:init db=postgres cfengine=adobe domain=myapp.com
```

### Initialize for staging environment
```bash
wheels deploy:init environment=staging servers=staging.example.com
```

### Force overwrite existing configuration
```bash
wheels deploy:init --force domain=myapp.com
```

## What It Does

The init command creates three key files:

1. **deploy.json** (or deploy.{environment}.json):
   - Docker registry configuration
   - Server list and SSH settings
   - Environment variables
   - Health check configuration
   - Database and Traefik settings

2. **Dockerfile**:
   - Base image for your CF engine (Lucee/Adobe)
   - Application dependencies
   - CommandBox installation
   - Port configuration

3. **.env.deploy**:
   - Environment variable template
   - Database credentials placeholder
   - Generated secret key
   - Production settings

## Generated deploy.json Structure

```json
{
  "service": "myapp",
  "image": "myapp",
  "servers": {
    "web": ["192.168.1.100", "192.168.1.101"]
  },
  "registry": {
    "server": "ghcr.io",
    "username": "your-github-username"
  },
  "env": {
    "clear": {
      "CFENGINE": "lucee",
      "DB_TYPE": "mysql",
      "WHEELS_ENV": "production"
    },
    "secret": [
      "DB_PASSWORD",
      "WHEELS_RELOAD_PASSWORD",
      "SECRET_KEY_BASE"
    ]
  },
  "ssh": {
    "user": "root"
  },
  "builder": {
    "multiarch": false
  },
  "healthcheck": {
    "path": "/",
    "port": 3000,
    "interval": 30
  },
  "accessories": {
    "db": {
      "image": "mysql:8",
      "host": "db",
      "port": 3306,
      "env": {
        "clear": {},
        "secret": []
      },
      "volumes": [
        "/var/lib/mysql:/var/lib/mysql"
      ]
    }
  },
  "traefik": {
    "enabled": true,
    "options": {
      "publish": ["443:443"],
      "volume": []
    },
    "args": {
      "entryPoints.web.address": ":80",
      "entryPoints.websecure.address": ":443",
      "certificatesresolvers.letsencrypt.acme.email": "admin@myapp.com"
    },
    "labels": {
      "traefik.http.routers.myapp.rule": "Host(`myapp.com`)",
      "traefik.http.routers.myapp.entrypoints": "websecure",
      "traefik.http.routers.myapp.tls.certresolver": "letsencrypt"
    }
  }
}
```

## Generated Dockerfile

### For Lucee
```dockerfile
FROM lucee/lucee:5.4

# Install additional dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /var/www

# Copy application files
COPY . /var/www/

# Install CommandBox for dependency management
RUN curl -fsSl https://downloads.ortussolutions.com/debs/gpg | apt-key add -
RUN echo "deb https://downloads.ortussolutions.com/debs/noarch /" | tee -a /etc/apt/sources.list.d/commandbox.list
RUN apt-get update && apt-get install -y commandbox

# Install dependencies
RUN box install

# Configure Lucee
COPY deploy/lucee-config.xml /opt/lucee/web/lucee-web.xml.cfm

# Expose port
EXPOSE 3000

# Start command
CMD ["box", "server", "start", "--console", "--force", "port=3000"]
```

### For Adobe ColdFusion
```dockerfile
FROM adobecoldfusion/coldfusion:latest

# Set working directory
WORKDIR /app

# Copy application files
COPY . /app/

# Install CommandBox
RUN curl -fsSl https://www.ortussolutions.com/parent/download/commandbox/type/bin -o /tmp/box && \
    chmod +x /tmp/box && \
    mv /tmp/box /usr/local/bin/box

# Install dependencies
RUN box install

# Expose port
EXPOSE 3000

# Start command
CMD ["box", "server", "start", "--console", "--force", "cfengine=adobe@2023", "port=3000"]
```

## Generated .env.deploy Template

```bash
# Production Environment Variables
DB_HOST=db
DB_PORT=3306
DB_NAME=myapp_production
DB_USERNAME=myapp_user
DB_PASSWORD=change_me_to_secure_password

WHEELS_ENV=production
WHEELS_RELOAD_PASSWORD=change_me_to_secure_password
SECRET_KEY_BASE=<64-character-generated-key>

# Additional configuration
APP_URL=https://myapp.com
```

## Database Configuration

The command configures database accessories based on your selection:

### MySQL
- Image: mysql:8
- Port: 3306
- Volume: /var/lib/mysql

### PostgreSQL
- Image: postgres:15
- Port: 5432
- Volume: /var/lib/postgresql

### SQL Server
- Image: mcr.microsoft.com/mssql/server:2022-latest
- Port: 1433
- Volume: /var/lib/mssql

## Traefik Configuration

Automatic HTTPS with Let's Encrypt:
- HTTP to HTTPS redirection
- Automatic SSL certificate generation
- Domain-based routing
- WebSocket support

## Interactive Mode

When parameters are not provided, the command prompts for:
- Application name (reads from server.json if available)
- Primary domain
- Server IPs (for custom provider)

## Next Steps

After running init:
1. Review and update `deploy.json` with your settings
2. Update `.env.deploy` with production credentials
3. Configure registry access (GitHub, Docker Hub, etc.)
4. Set up SSH access to your servers
5. Run `wheels deploy:setup` to provision servers
6. Run `wheels deploy:push` to deploy

## Best Practices

1. **Use environment-specific configs**: Create separate configs for staging/production
2. **Secure credentials**: Never commit `.env.deploy` to version control
3. **Test locally first**: Build and run Docker image locally
4. **Use SSH keys**: Configure passwordless SSH access
5. **Configure health checks**: Ensure your app has a working health endpoint

## Security Notes

- Generated secret keys are cryptographically random
- Passwords in `.env.deploy` must be changed before deployment
- Use secrets management for production credentials
- Configure firewall rules on target servers
- Use read-only filesystem where possible

## See Also

- [wheels deploy:setup](deploy-setup.md) - Setup deployment environment
- [wheels deploy:push](deploy-push.md) - Deploy application
- [wheels deploy:secrets](deploy-secrets.md) - Manage deployment secrets