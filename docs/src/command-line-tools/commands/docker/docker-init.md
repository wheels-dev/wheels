# wheels docker init
*This command works correctly without options (parameters). Option support is under development and will be **available soon**.*

Initialize Docker configuration for your Wheels application.

## Synopsis

```bash
wheels docker init [options]
```

## Description

The `wheels docker init` command creates Docker configuration files for containerizing your Wheels application. It generates a `Dockerfile`, `docker-compose.yml`, and supporting configuration files optimized for Wheels applications.

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--engine` | CFML engine (lucee5, lucee6, adobe2018, adobe2021, adobe2023) | `lucee6` |
| `--database` | Database system (mysql, postgresql, sqlserver, none) | `mysql` |
| `--port` | Application port | `8080` |
| `--with-nginx` | Include Nginx reverse proxy | `false` |
| `--with-redis` | Include Redis for caching | `false` |
| `--production` | Generate production-ready configuration | `false` |
| `--force` | Overwrite existing Docker files | `false` |
| `--help` | Show help information |

## Examples

### Basic initialization
```bash
wheels docker init
```

### Initialize with Adobe ColdFusion
```bash
wheels docker init --engine=adobe2023
```

### Production setup with Nginx
```bash
wheels docker init --production --with-nginx --port=80
```

### Initialize with PostgreSQL
```bash
wheels docker init --database=postgresql
```

### Full stack with Redis
```bash
wheels docker init --with-nginx --with-redis --database=postgresql
```

## What It Does

1. **Creates Dockerfile** optimized for CFML applications:
   - Base image selection based on engine
   - Dependency installation
   - Application file copying
   - Environment configuration

2. **Generates docker-compose.yml** with:
   - Application service
   - Database service (if selected)
   - Nginx service (if selected)
   - Redis service (if selected)
   - Network configuration
   - Volume mappings

3. **Additional files**:
   - `.dockerignore` - Excludes unnecessary files
   - `docker-entrypoint.sh` - Container startup script
   - Configuration files for selected services

## Generated Files

### Dockerfile Example
```dockerfile
FROM ortussolutions/commandbox:lucee5

# Set working directory
WORKDIR /app

# Copy application files
COPY . /app

# Install dependencies
RUN box install

# Expose port
EXPOSE 8080

# Start server
CMD ["box", "server", "start", "--console"]
```

### docker-compose.yml Example
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - WHEELS_ENV=development
      - DB_HOST=database
    depends_on:
      - database
    volumes:
      - ./:/app

  database:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=wheels
      - MYSQL_DATABASE=wheels_app
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
```

## Configuration Options

### Development Mode
- Hot reload enabled
- Source code mounted as volume
- Debug ports exposed
- Development databases

### Production Mode
- Optimized image size
- Security hardening
- Health checks
- Restart policies
- Resource limits

## Use Cases

1. **Local Development**: Consistent development environment across team
2. **Testing**: Isolated test environments with different configurations
3. **CI/CD**: Containerized testing in pipelines
4. **Deployment**: Production-ready containers for cloud deployment

## Environment Variables

Common environment variables configured:

| Variable | Description |
|----------|-------------|
| `WHEELS_ENV` | Application environment |
| `WHEELS_DATASOURCE` | Database connection name |
| `DB_HOST` | Database hostname |
| `DB_PORT` | Database port |
| `DB_NAME` | Database name |
| `DB_USER` | Database username |
| `DB_PASSWORD` | Database password |

## Notes

- Requires Docker and Docker Compose installed
- Database passwords are set to defaults in development
- Production configurations should use secrets management
- The command detects existing Docker files and prompts before overwriting

## See Also

- [wheels docker deploy](docker-deploy.md) - Deploy using Docker
- [wheels deploy](../deploy/deploy.md) - General deployment commands
- [wheels ci init](../ci/ci-init.md) - Initialize CI configuration