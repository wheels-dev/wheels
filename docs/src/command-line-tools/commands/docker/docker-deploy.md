# wheels docker deploy

Create production-ready Docker configurations with multi-stage builds, optimizations, and deployment scripts.

## Synopsis

```bash
wheels docker deploy [options]
```

## Description

The `wheels docker deploy` command generates production-ready Docker configurations for your Wheels application. It creates a multi-stage Dockerfile for optimized builds, production docker-compose configuration, nginx reverse proxy setup, and deployment scripts with automated health checks.

## Options

| Option | Description | Default | Valid Values |
|--------|-------------|---------|--------------|
| `--environment` | Deployment environment | `production` | `production`, `staging` |
| `--db` | Database system to use | `mysql` | `h2`, `mysql`, `postgres`, `mssql` |
| `--cfengine` | CFML engine to use | `lucee` | `lucee`, `adobe` |
| `--optimize` | Enable production optimizations | `true` | `true`, `false` |
| `--force` | Overwrite existing files without confirmation | `false` | `true`, `false` |

## Examples

### Basic production deployment
```bash
wheels docker deploy
```

### Staging environment
```bash
wheels docker deploy --environment=staging
```

### Production with PostgreSQL
```bash
wheels docker deploy --db=postgres
```

### Adobe ColdFusion deployment
```bash
wheels docker deploy --cfengine=adobe
```

### Deployment without optimizations
```bash
wheels docker deploy --optimize=false
```

### Full custom configuration
```bash
wheels docker deploy --environment=production --db=mysql --cfengine=lucee --optimize=true
```

### Overwrite existing files without prompting
```bash
wheels docker deploy --force
```

## What It Does

1. **Creates Dockerfile.production** with multi-stage build:
   - **Builder stage**: Installs dependencies, builds assets (Node.js, npm)
   - **Production stage**: Copies only necessary files
   - **CF Engine specific configurations**:
     - Lucee: Uses `lucee/lucee:5-nginx` with nginx integration
     - Adobe: Uses `ortussolutions/commandbox:adobe2023-alpine` for smaller image
   - **Box install** with `--production` flag
   - **Asset building** with `npm ci --only=production` and `npm run build`
   - **Production optimizations** (if enabled):
     - `COMMANDBOX_CFENGINE_SAVECLASS=false`
     - `COMMANDBOX_CFENGINE_BUFFEROUTPUT=false`
     - `COMMANDBOX_CFENGINE_TEMPLATECACHE=true`
     - `COMMANDBOX_CFENGINE_QUERYCACHE=true`
   - **Security hardening**:
     - Removes test directories, .git, docker files
     - Sets proper file permissions (755)
   - **Health check** configured (30s interval, 3s timeout, 40s start period, 3 retries)

2. **Creates docker-compose.production.yml** with:
   - Application service configuration:
     - Image: `wheels-app:latest`
     - Restart policy: `always`
     - Port mapping: `80:8080`
     - Environment variables placeholder
     - Volume mounts for logs and uploads
     - **Deploy configuration** (Docker Swarm ready):
       - 2 replicas
       - Rolling update strategy (1 at a time, 10s delay)
       - Restart policy (on-failure, 5s delay, 3 max attempts)
   - Database service (if not H2):
     - Appropriate image based on `--db` selection
     - Restart policy: `always`
     - Environment variables from secrets
     - Volume mount for data persistence
     - Placement constraint (manager node only)
   - Nginx reverse proxy service:
     - Image: `nginx:alpine`
     - SSL support on port 443
     - Configuration mounted from nginx.conf
     - SSL certificates volume
     - Depends on app service
   - Named volumes: `app_logs`, `app_uploads`, `db_data`, `ssl_certs`

3. **Creates nginx.conf** for production SSL:
   - Upstream configuration to `app:8080`
   - SSL/HTTP2 support on port 443
   - SSL certificate paths configured
   - Proxy headers: Host, X-Real-IP, X-Forwarded-For, X-Forwarded-Proto
   - Server name placeholder (your-domain.com)

4. **Creates deploy.sh** deployment script:
   - Loads environment variables from `.env.[environment]` file
   - Builds production Docker image
   - Tags image with timestamp version
   - Deploys using docker-compose
   - Waits for health checks (30 seconds)
   - Checks deployment status
   - **Automatic rollback** on failure
   - **Cleanup** of old images (keeps last 5)
   - Error handling with `set -e`
   - Makes script executable (Unix/Linux only)

5. **Creates .env.[environment].example**:
   - Database configuration placeholders
   - Application settings (URL, secret key)
   - Email configuration (SMTP)
   - Other services (Redis, S3)
   - Template for actual environment file

## File Overwrite Behavior

By default, the command will check for existing production Docker files and prompt for confirmation before overwriting:

- `Dockerfile.production`
- `docker-compose.production.yml`
- `nginx.conf`
- `deploy.sh`
- `.env.[environment].example`

**Without `--force`**: If any files exist, you'll see a list and be asked:
```
The following production Docker files already exist:
  - Dockerfile.production
  - docker-compose.production.yml
  - nginx.conf

Do you want to overwrite these files? [y/n]
```

**With `--force`**: All files are overwritten immediately without confirmation.

## Generated Files

### Dockerfile.production (Lucee)
```dockerfile
## Multi-stage build for production
FROM lucee/lucee:5-nginx AS builder

## Install build dependencies
RUN apt-get update && apt-get install -y nodejs npm

## Copy application files
COPY . /build
WORKDIR /build

## Install dependencies and build assets
RUN box install --production
RUN npm ci --only=production
RUN npm run build

## Production stage
FROM lucee/lucee:5-nginx

## Copy built application
COPY --from=builder /build /var/www
WORKDIR /var/www

## Configure Lucee for production
RUN echo "this.mappings["/vendor"] = expandPath("./vendor");" >> /opt/lucee/web/Application.cfc

## Production optimizations
ENV COMMANDBOX_CFENGINE_SAVECLASS=false
ENV COMMANDBOX_CFENGINE_BUFFEROUTPUT=false
ENV COMMANDBOX_CFENGINE_TEMPLATECACHE=true
ENV COMMANDBOX_CFENGINE_QUERYCACHE=true

## Security hardening
RUN rm -rf /app/tests /app/.git /app/docker
RUN chmod -R 755 /app

## Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1

## Expose port
EXPOSE 8080

## Start the application
CMD ["box", "server", "start", "--console", "--force", "--production"]
```

### Dockerfile.production (Adobe)
```dockerfile
## Multi-stage build for production
FROM ortussolutions/commandbox:adobe2023 AS builder

## Install build dependencies
RUN apt-get update && apt-get install -y nodejs npm

## Copy application files
COPY . /build
WORKDIR /build

## Install dependencies and build assets
RUN box install --production
RUN npm ci --only=production
RUN npm run build

## Production stage
FROM ortussolutions/commandbox:adobe2023-alpine

## Copy built application
COPY --from=builder /build /app
WORKDIR /app

## Production optimizations
ENV COMMANDBOX_CFENGINE_SAVECLASS=false
ENV COMMANDBOX_CFENGINE_BUFFEROUTPUT=false
ENV COMMANDBOX_CFENGINE_TEMPLATECACHE=true
ENV COMMANDBOX_CFENGINE_QUERYCACHE=true

## Security hardening
RUN rm -rf /app/tests /app/.git /app/docker
RUN chmod -R 755 /app

## Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1

## Expose port
EXPOSE 8080

## Start the application
CMD ["box", "server", "start", "--console", "--force", "--production"]
```

### docker-compose.production.yml (with MySQL)
```yaml
version: "3.8"

services:
  app:
    image: wheels-app:latest
    restart: always
    ports:
      - "80:8080"
    environment:
      ENVIRONMENT: production
      ## Add your production environment variables here
      ## DB_HOST: ${DB_HOST}
      ## DB_USER: ${DB_USER}
      ## DB_PASSWORD: ${DB_PASSWORD}
    volumes:
      - app_logs:/app/logs
      - app_uploads:/app/uploads
    deploy:
      replicas: 2
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
    depends_on:
      - db

  db:
    image: mysql:8.0
    restart: always
    environment:
      ## Configure your production database credentials
      ## These should come from environment variables or secrets
      DB_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db_data:/var/lib/mysql  ## Adjust path based on database type
    deploy:
      placement:
        constraints:
          - node.role == manager

  nginx:
    image: nginx:alpine
    restart: always
    ports:
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ssl_certs:/etc/nginx/ssl
    depends_on:
      - app

volumes:
  app_logs:
  app_uploads:
  db_data:
  ssl_certs:
```

### nginx.conf
```nginx
events {
    worker_connections 1024;
}

http {
    upstream wheels_app {
        server app:8080;
    }

    server {
        listen 443 ssl http2;
        server_name your-domain.com;

        ## SSL configuration
        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;

        location / {
            proxy_pass http://wheels_app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

### deploy.sh
```bash
#!/bin/bash

## Wheels Docker Deployment Script
## Environment: production

set -e

echo "Starting deployment to production..."

## Load environment variables
if [ -f .env.production ]; then
    export $(cat .env.production | grep -v "^#" | xargs)
fi

## Build the production image
echo "Building production image..."
docker build -t wheels-app:latest -f Dockerfile.production .

## Tag image with version
VERSION=$(date +%Y%m%d%H%M%S)
docker tag wheels-app:latest wheels-app:$VERSION

## Deploy using docker-compose
echo "Deploying application..."
docker-compose -f docker-compose.production.yml up -d

## Wait for health checks
echo "Waiting for application to be healthy..."
sleep 30

## Check deployment status
if docker-compose -f docker-compose.production.yml ps | grep -q "healthy"; then
    echo "Deployment successful!"

    ## Clean up old images (keep last 5)
    docker images | grep wheels-app | tail -n +6 | awk '{print $3}' | xargs -r docker rmi
else
    echo "Deployment failed! Rolling back..."
    docker-compose -f docker-compose.production.yml down
    exit 1
fi

echo "Deployment complete!"
```

### .env.production.example
```bash
## Environment variables for production
## Copy this to .env.production and fill in your values

## Database configuration
DB_HOST=your-db-host
DB_USER=your-db-user
DB_PASSWORD=your-db-password
DB_NAME=your-db-name

## Application settings
APP_URL=https://your-domain.com
APP_KEY=your-secret-key

## Email configuration
MAIL_SERVER=smtp.example.com
MAIL_USERNAME=your-email@example.com
MAIL_PASSWORD=your-email-password

## Other services
REDIS_URL=redis://localhost:6379
S3_BUCKET=your-s3-bucket
```

## Database Images

Based on `--db` selection:

| Database | Image |
|----------|-------|
| MySQL | `mysql:8.0` |
| PostgreSQL | `postgres:15-alpine` |
| MSSQL | `mcr.microsoft.com/mssql/server:2019-latest` |
| H2 | No database service (embedded) |

## Multi-Stage Build Benefits

The generated Dockerfile uses multi-stage builds for:

1. **Smaller Production Images**:
   - Builder stage includes Node.js, npm, build tools
   - Production stage only includes runtime and built assets
   - Reduces final image size by 50-70%

2. **Security**:
   - No build tools in production image
   - Removes test files, .git, docker directories
   - Proper file permissions

3. **Build Caching**:
   - Dependencies cached in builder stage
   - Faster rebuilds when code changes

## Production Optimizations

When `--optimize=true` (default), the following CommandBox settings are configured:

| Setting | Value | Benefit |
|---------|-------|---------|
| `COMMANDBOX_CFENGINE_SAVECLASS` | `false` | Disables saving compiled classes |
| `COMMANDBOX_CFENGINE_BUFFEROUTPUT` | `false` | Disables output buffering for performance |
| `COMMANDBOX_CFENGINE_TEMPLATECACHE` | `true` | Enables template caching |
| `COMMANDBOX_CFENGINE_QUERYCACHE` | `true` | Enables query result caching |

## Docker Swarm Deployment

The generated `docker-compose.production.yml` includes Docker Swarm deployment configuration:

### Features
- **2 replicas** for high availability
- **Rolling updates**: 1 container at a time with 10s delay
- **Automatic restart** on failure (max 3 attempts, 5s delay)
- **Database placement**: Manager node only
- **Health checks**: Automatic monitoring

### Deploy to Swarm
```bash
# Initialize swarm (if not already)
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.production.yml wheels

# Check status
docker stack services wheels

# Scale application
docker service scale wheels_app=5

# View logs
docker service logs -f wheels_app
```

## Deployment Workflow

1. **Prepare Environment**:
   ```bash
   # Copy and configure environment file
   cp .env.production.example .env.production
   nano .env.production
   ```

2. **Build Production Image**:
   ```bash
   docker build -t wheels-app:latest -f Dockerfile.production .
   ```

3. **Test Locally**:
   ```bash
   docker-compose -f docker-compose.production.yml up
   ```

4. **Deploy**:
   ```bash
   ./deploy.sh
   ```

5. **Verify Deployment**:
   ```bash
   docker-compose -f docker-compose.production.yml ps
   docker-compose -f docker-compose.production.yml logs -f app
   ```

## SSL Configuration

The generated nginx configuration expects SSL certificates at:
- Certificate: `/etc/nginx/ssl/cert.pem`
- Private Key: `/etc/nginx/ssl/key.pem`

### Adding SSL Certificates

1. **Using Let's Encrypt (Certbot)**:
   ```bash
   # Install certbot
   apt-get install certbot

   # Get certificate
   certbot certonly --standalone -d your-domain.com

   # Copy to ssl_certs volume
   docker run --rm -v ssl_certs:/certs -v /etc/letsencrypt/live/your-domain.com:/source alpine \
     sh -c "cp /source/fullchain.pem /certs/cert.pem && cp /source/privkey.pem /certs/key.pem"
   ```

2. **Using Existing Certificates**:
   ```bash
   # Create and populate ssl_certs volume
   docker volume create ssl_certs
   docker run --rm -v ssl_certs:/certs -v /path/to/certs:/source alpine \
     sh -c "cp /source/cert.pem /certs/ && cp /source/key.pem /certs/"
   ```

3. **Update nginx.conf** with your domain name

## Environment Variables

Configure these in `.env.production`:

### Required
- `DB_HOST` - Database hostname
- `DB_USER` - Database username
- `DB_PASSWORD` - Database password
- `DB_NAME` - Database name

### Recommended
- `APP_URL` - Application URL
- `APP_KEY` - Application secret key
- `MAIL_SERVER` - SMTP server
- `MAIL_USERNAME` - Email username
- `MAIL_PASSWORD` - Email password

### Optional
- `REDIS_URL` - Redis connection string
- `S3_BUCKET` - S3 bucket name
- Custom application variables

## Health Checks

The deployment includes automatic health checks:

- **Interval**: 30 seconds
- **Timeout**: 3 seconds
- **Start Period**: 40 seconds
- **Retries**: 3 attempts
- **Endpoint**: `http://localhost:8080/`

### Custom Health Endpoint

To use a custom health check endpoint, edit `Dockerfile.production`:

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1
```

## Rollback

If deployment fails, the `deploy.sh` script automatically rolls back.

### Manual Rollback

```bash
# Stop current deployment
docker-compose -f docker-compose.production.yml down

# Deploy previous version
docker tag wheels-app:20240315120000 wheels-app:latest
docker-compose -f docker-compose.production.yml up -d
```

### Docker Swarm Rollback

```bash
# Rollback service
docker service rollback wheels_app

# Or rollback entire stack
docker stack deploy --prune -c docker-compose.production.yml wheels
```

## Notes

- **Multi-stage builds** significantly reduce production image size
- **Security hardening** removes unnecessary files and sets proper permissions
- **Automated deployment script** includes health checks and rollback
- **Docker Swarm ready** with deployment configuration included
- **SSL/HTTPS support** via nginx reverse proxy
- **Environment-specific configurations** via `.env` files
- **Image versioning** with timestamp tags
- **Old image cleanup** keeps last 5 versions
- Set `--optimize=false` to disable CF engine optimizations during debugging
- Database service only included if `--db` is not `h2`
- deployment script is executable on Unix/Linux (Windows users may need to use Git Bash or WSL)

## Troubleshooting

### Build failures
**Problem**: Multi-stage build fails

**Solutions**:
- Ensure `box.json` exists with all dependencies listed
- Check if `package.json` exists if using npm
- Verify base images are accessible
- Check for syntax errors in Application.cfc
- Review Docker build logs: `docker build -t wheels-app:latest -f Dockerfile.production . --progress=plain`

### Health check failures
**Problem**: Deployment marked as unhealthy

**Solutions**:
- Check application logs: `docker-compose -f docker-compose.production.yml logs app`
- Verify application starts correctly
- Increase start period in HEALTHCHECK directive
- Test health endpoint manually: `docker exec wheels_app curl http://localhost:8080/`
- Check for port conflicts

### Database connection issues
**Problem**: Application cannot connect to database

**Solutions**:
- Verify `.env.production` has correct database credentials
- Check database service is running: `docker-compose -f docker-compose.production.yml ps db`
- Ensure database service name matches `DB_HOST` in environment variables
- Check database logs: `docker-compose -f docker-compose.production.yml logs db`
- Verify network connectivity between containers

### SSL certificate errors
**Problem**: Nginx fails to start due to SSL issues

**Solutions**:
- Ensure SSL certificates exist in `ssl_certs` volume
- Check certificate file paths in `nginx.conf`
- Verify certificate permissions
- Test nginx configuration: `docker-compose -f docker-compose.production.yml exec nginx nginx -t`
- Use self-signed certificates for testing: `openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout key.pem -out cert.pem`

### Deployment script fails
**Problem**: `deploy.sh` exits with error

**Solutions**:
- Check `.env.production` file exists and is readable
- Verify Docker daemon is running
- Ensure sufficient disk space for images
- Check deployment logs for specific error
- Run script with debugging: `bash -x ./deploy.sh`
- Make script executable: `chmod +x deploy.sh`

### Old images not cleaned up
**Problem**: Disk space consumed by old images

**Solutions**:
- Manually clean up: `docker images | grep wheels-app | tail -n +6 | awk '{print $3}' | xargs docker rmi`
- Run Docker prune: `docker system prune -a --filter "until=168h"`
- Check deploy.sh cleanup logic is executing
- Increase storage or implement external image registry

## See Also

- [wheels docker init](docker-init.md) - Initialize Docker development configuration
- [Docker Multi-Stage Builds](https://docs.docker.com/build/building/multi-stage/) - Official Docker documentation
- [Docker Swarm](https://docs.docker.com/engine/swarm/) - Docker Swarm mode
- [Docker Compose](https://docs.docker.com/compose/) - Docker Compose reference
