# wheels docker init

Initialize Docker configuration for your Wheels application with support for multiple databases, CF engines, production mode, and Nginx reverse proxy.

## Synopsis

```bash
wheels docker init [options]
```

## Description

The `wheels docker init` command creates Docker configuration files for containerizing your Wheels application. It generates a `Dockerfile`, `docker-compose.yml`, `.dockerignore`, configures datasources in `CFConfig.json`, and optionally creates Nginx configuration for reverse proxy support.

## Options

| Option | Description | Default | Valid Values |
|--------|-------------|---------|--------------|
| `--db` | Database system to use | `mysql` | `h2`, `sqlite`, `mysql`, `postgres`, `mssql`, `oracle` |
| `--dbVersion` | Database version to use | varies by db | Any valid version for the selected database |
| `--cfengine` | CFML engine to use | `lucee` | `lucee`, `adobe` |
| `--cfVersion` | CFML engine version | `6` | Any valid version for the selected engine |
| `--port` | Custom application port (overrides server.json) | from server.json or `8080` | Any valid port number |
| `--force` | Overwrite existing Docker files without confirmation | `false` | `true`, `false` |
| `--production` | Generate production-ready configuration | `false` | `true`, `false` |
| `--nginx` | Include Nginx reverse proxy | `false` | `true`, `false` |

**Default Database Versions:**
- MySQL: `8.0`
- PostgreSQL: `15`
- MSSQL: `2019-latest`
- Oracle: `latest` (Oracle Database 23c Free)
- H2: embedded (no version needed)
- SQLite: embedded (no version needed)

## Examples

### Basic initialization (MySQL with Lucee 6)
```bash
wheels docker init
```

### Initialize with PostgreSQL
```bash
wheels docker init --db=postgres
```

### Initialize with specific database version
```bash
wheels docker init --db=postgres --dbVersion=13
```

### Initialize with Adobe ColdFusion
```bash
wheels docker init --cfengine=adobe --cfVersion=2023
```

### Initialize with H2 embedded database
```bash
wheels docker init --db=h2
```

### Initialize with SQLite file-based database
```bash
wheels docker init --db=sqlite
```

### Initialize with Oracle
```bash
wheels docker init --db=oracle
```

### Initialize with specific Oracle version
```bash
wheels docker init --db=oracle --dbVersion=23-slim
```

### Custom port
```bash
wheels docker init --port=3000
```

### Force overwrite existing files
```bash
wheels docker init --force
```

### Production configuration
```bash
wheels docker init --production
```

### Production with Nginx reverse proxy
```bash
wheels docker init --production --nginx
```

### Development with Nginx on custom port
```bash
wheels docker init --nginx --port=8080
```

### Full custom configuration
```bash
wheels docker init --db=postgres --dbVersion=15 --cfengine=lucee --cfVersion=6 --port=8888 --production --nginx
```

## What It Does

1. **Checks for existing files** (unless `--force` is used):
   - Detects existing `Dockerfile`, `docker-compose.yml`, and `.dockerignore`
   - Prompts before overwriting existing Docker configuration
   - Lists all files that will be replaced
   - Allows cancellation to prevent accidental overwrites

2. **Creates Dockerfile** optimized for CFML applications:
   - **Development mode** (default):
     - Hot-reload enabled
     - Development tools installed (curl, nano)
     - Source code mounted for live updates
     - `BOX_INSTALL=TRUE` for automatic dependency installation
   - **Production mode** (`--production`):
     - Security hardened with non-root user (UID 1001)
     - `box install --production` for optimized dependencies
     - Health checks configured (30s interval, 10s timeout, 3 retries)
     - Production environment variables set
     - No source volume mounts
     - Optimized image size
   - Based on `ortussolutions/commandbox:latest`
   - Installs H2 extension for Lucee if H2 database selected
   - SQLite JDBC driver included by default (no extension needed)
   - Exposes application port (custom, from server.json, or defaults to 8080)

3. **Generates docker-compose.yml** with:
   - Application service with port mapping or internal exposure
   - Database service (mysql, postgres, mssql, or oracle) if selected
   - File-based databases (H2, SQLite) run embedded within app container
   - Nginx reverse proxy service (if `--nginx`)
   - Environment variables for database connection
   - Volume mappings for data persistence
   - **Development mode**: Source code mounted for hot-reload, development command
   - **Production mode**: No source mounts, `restart: always` policies

4. **Creates Nginx configuration** (if `--nginx`):
   - Reverse proxy to application backend
   - Load balancing ready upstream configuration
   - WebSocket support with upgrade headers
   - Static asset caching with 1-day expiration
   - Custom upload size limits (100MB)
   - Health check endpoint at `/health`
   - **Production mode only**:
     - Security headers (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection, Referrer-Policy)
     - Gzip compression for text content types
   - **Port configuration**:
     - Development: Nginx on port 8080
     - Production: Nginx on port 80

5. **Creates .dockerignore** excluding:
   - `.git` and `.gitignore`
   - `node_modules`
   - `.CommandBox`
   - `server.json`
   - `logs` and `*.log`
   - `tests`
   - `.env`
   - **Production mode only**: README files, IDE configs (`.vscode`, `.idea`), `.DS_Store`

6. **Updates CFConfig.json**:
   - Configures `wheels-dev` datasource for selected database
   - Sets up proper JDBC drivers and connection strings:
     - MySQL: `com.mysql.cj.jdbc.Driver`
     - PostgreSQL: `org.postgresql.Driver`
     - MSSQL: `com.microsoft.sqlserver.jdbc.SQLServerDriver`
     - Oracle: `oracle.jdbc.OracleDriver`
   - Uses Docker service name `db` for host resolution
   - Configures appropriate ports and credentials
   - **Note**: Skipped for H2 and SQLite (file-based databases)

7. **Updates server.json for Docker compatibility**:
   - Sets `web.host` to `0.0.0.0` (required for Docker containers to accept external connections)
   - Sets `openBrowser` to `false` (Docker containers have no GUI)
   - Configures port from `--port` argument, existing server.json, or defaults to 8080
   - Sets CFEngine version (e.g., `lucee@6` or `adobe@2023`)
   - Adds `CFConfigFile` reference if missing

## Generated Files

### Development Dockerfile
```dockerfile
FROM ortussolutions/commandbox:latest

## Install curl and nano
RUN apt-get update && apt-get install -y curl nano

## Clean up the image
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

## Copy application files
COPY . /app
WORKDIR /app

## Install Dependencies
ENV BOX_INSTALL             TRUE

## Expose port
EXPOSE 8080

## Set Healthcheck URI
ENV HEALTHCHECK_URI         "http://127.0.0.1:8080/"

## Start the application
CMD ["box", "server", "start", "--console", "--force"]
```

### Production Dockerfile
```dockerfile
FROM ortussolutions/commandbox:latest

## Install required packages
RUN apt-get update && apt-get install -y curl nano && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

## Copy application files
COPY . /app
WORKDIR /app

## Install Dependencies
RUN box install --production

## Production optimizations
ENV ENVIRONMENT             production
ENV BOX_SERVER_PROFILE      production

## Security: Run as non-root user
RUN useradd -m -u 1001 appuser && \
    chown -R appuser:appuser /app
USER appuser

## Expose port
EXPOSE 8080

## Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://127.0.0.1:8080/ || exit 1

## Start the application
CMD ["box", "server", "start", "--console"]
```

### docker-compose.yml (Development with MySQL)
```yaml
version: "3.8"

services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      ENVIRONMENT: development
      DB_HOST: db
      DB_PORT: 3306
      DB_NAME: wheels
      DB_USER: wheels
      DB_PASSWORD: wheels
    volumes:
      - .:/app
      - ../../../core/src/wheels:/app/vendor/wheels
      - ../../../docs:/app/vendor/wheels/docs
      - ../../../tests:/app/tests
    command: sh -c "box install && box server start --console --force"
    depends_on:
      - db

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: wheels
      MYSQL_DATABASE: wheels
      MYSQL_USER: wheels
      MYSQL_PASSWORD: wheels
    ports:
      - "3306:3306"
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
```

### docker-compose.yml (Production with Nginx)
```yaml
version: "3.8"

services:
  app:
    build: .
    expose:
      - 8080
    environment:
      ENVIRONMENT: production
      DB_HOST: db
      DB_PORT: 3306
      DB_NAME: wheels
      DB_USER: wheels
      DB_PASSWORD: wheels
    restart: always
    depends_on:
      - db

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    restart: always
    depends_on:
      - app

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: wheels
      MYSQL_DATABASE: wheels
      MYSQL_USER: wheels
      MYSQL_PASSWORD: wheels
    ports:
      - "3306:3306"
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
```

### nginx.conf (Generated with --nginx)
```nginx
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;

    upstream app_backend {
        server app:8080;
    }

    server {
        listen 80;
        server_name _;

        # Max upload size
        client_max_body_size 100M;

        # Security headers (production only)
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;

        # Gzip compression (production only)
        gzip on;
        gzip_vary on;
        gzip_min_length 1024;
        gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;

        location / {
            proxy_pass http://app_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # WebSocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            # Timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        # Static assets caching
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            proxy_pass http://app_backend;
            proxy_cache_valid 200 1d;
            expires 1d;
            add_header Cache-Control "public, immutable";
        }

        # Health check endpoint
        location /health {
            access_log off;
            proxy_pass http://app_backend;
        }
    }
}
```

## Database Configurations

### MySQL
- **Image**: `mysql:8.0` (default)
- **Port**: 3306
- **Credentials**: wheels/wheels
- **Database**: wheels
- **Root Password**: wheels

### PostgreSQL
- **Image**: `postgres:15` (default)
- **Port**: 5432
- **Credentials**: wheels/wheels
- **Database**: wheels

### MSSQL
- **Image**: `mcr.microsoft.com/mssql/server:2019-latest` (default)
- **Port**: 1433
- **Credentials**: sa/Wheels123!
- **Database**: wheels
- **Note**: Requires EULA acceptance

### Oracle
- **Image**: `gvenzl/oracle-free:latest` (default - Oracle Database 23c Free)
- **Port**: 1521
- **Credentials**: wheels/wheels
- **SID**: FREE
- **Note**: Uses lightweight Oracle Free container image
- **Available tags**: `latest`, `23`, `23-slim`, `23-faststart`, `23-slim-faststart`

### H2
- **Embedded**: No separate container needed
- **Extension**: Automatically added to Lucee deployments via Dockerfile
- **Connection**: Configured in application settings
- **Storage**: Within application container filesystem at `./db/`
- **JDBC Driver**: `org.h2.Driver`

### SQLite
- **Embedded**: No separate container needed (file-based)
- **JDBC Driver**: `org.sqlite.JDBC` (included with Lucee/CommandBox by default)
- **Connection**: Configured in application settings
- **Storage**: Within application container filesystem at `./db/`
- **Database File**: `./db/database_name.db`
- **Characteristics**:
  - Serverless, zero-configuration
  - Single file database (easy to backup)
  - Ideal for development, testing, and prototyping
  - No username/password required
  - Creates auxiliary files during operation (.db-wal, .db-shm, .db-journal)
- **Use Cases**: Development, testing, embedded systems, portable applications
- **Limitations**:
  - Single writer (not suitable for high-concurrency)
  - Not recommended for production with multiple concurrent users

## Production vs Development Mode

### Development Mode (default)
- Source code mounted as volumes for hot-reload
- Full development tools installed (curl, nano)
- Debugging and verbose logging enabled
- No restart policies
- Direct port exposure (app accessible on configured port)
- Development-friendly error messages
- `box install` runs on container start with `--force` flag
- Volume mounts for Wheels core, docs, and tests (framework development)

### Production Mode (`--production`)
- **No source code volume mounts** - code baked into image
- Security hardened Dockerfile with non-root user (UID 1001)
- Automatic restart policies (`restart: always`)
- Health checks configured (30s interval, 10s timeout, 60s start period, 3 retries)
- Optimized image size with `box install --production`
- Production environment variable set
- Additional .dockerignore exclusions (docs, IDE configs)
- `BOX_SERVER_PROFILE=production` environment
- No command override in docker-compose (uses CMD from Dockerfile)

### Comparison Table

| Feature | Development | Production |
|---------|-------------|------------|
| Source Volume Mount | ✅ Yes | ❌ No |
| Hot Reload | ✅ Enabled | ❌ Disabled |
| User | root | appuser (1001) |
| Restart Policy | none | always |
| Health Checks | ❌ No | ✅ Yes |
| Security Headers | ❌ No | ✅ Yes (with nginx) |
| Gzip Compression | ❌ No | ✅ Yes (with nginx) |
| Install Command | `box install` | `box install --production` |
| Image Size | Larger | Optimized |

## Nginx Reverse Proxy

When using `--nginx`, an Nginx reverse proxy is configured between clients and your application.

### Benefits
- **Load balancing ready**: Upstream configuration supports multiple app instances
- **SSL termination point**: Add SSL certificates to nginx without app changes
- **Static asset caching**: 1-day cache for images, CSS, JS
- **Security headers**: Production mode adds security headers
- **Gzip compression**: Production mode compresses responses
- **WebSocket support**: Upgrade headers configured
- **Request buffering**: Better handling of slow clients
- **Health checks**: Dedicated `/health` endpoint

### Port Configuration
- **Development mode**: Nginx listens on port 8080, app exposed internally
- **Production mode**: Nginx listens on port 80, app exposed internally
- App is only accessible through nginx when `--nginx` is used

### Nginx Configuration Details
The generated `nginx.conf` includes:
- **Upstream**: `app_backend` pointing to `app:8080` (Docker service)
- **Worker connections**: 1024 concurrent connections
- **Client max body size**: 100MB for file uploads
- **Proxy headers**: Host, X-Real-IP, X-Forwarded-For, X-Forwarded-Proto
- **WebSocket support**: HTTP/1.1 with Upgrade and Connection headers
- **Timeouts**: 60s for connect, send, and read operations
- **Static caching**: 1 day expiration for assets
- **Health check**: `/health` endpoint with no access logging

### Production Security Headers (with --production --nginx)
```
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: no-referrer-when-downgrade
```

### Production Gzip Compression (with --production --nginx)
Enabled for:
- text/plain
- text/css
- text/xml
- text/javascript
- application/x-javascript
- application/xml+rss
- application/json

## server.json Docker Configuration

The command automatically updates your `server.json` with Docker-specific settings:

### Before Docker Init
```json
{
  "name": "myapp",
  "web": {
    "host": "localhost",
    "http": {
      "port": "8080"
    }
  },
  "openBrowser": true
}
```

### After Docker Init
```json
{
  "name": "myapp",
  "web": {
    "host": "0.0.0.0",
    "http": {
      "port": "8080"
    }
  },
  "openBrowser": false,
  "CFConfigFile": "CFConfig.json",
  "app": {
    "cfengine": "lucee@6"
  }
}
```

### Why These Changes?

| Setting | Value | Reason |
|---------|-------|--------|
| `web.host` | `0.0.0.0` | Docker containers must bind to all interfaces to accept external connections. Using `localhost` or `127.0.0.1` prevents access from outside the container. |
| `openBrowser` | `false` | Docker containers run in headless mode with no GUI. Attempting to open a browser will fail and cause errors. |
| `web.http.port` | (from --port or existing) | Ensures the application port matches the Dockerfile EXPOSE and docker-compose port mapping. |
| `CFConfigFile` | `CFConfig.json` | Required for datasource configuration to work properly. |

### Port Priority

The port configuration follows this priority order:
1. `--port` command argument (highest priority)
2. Existing value in `server.json`
3. Default: `8080` (lowest priority)

If you specify `--port=9000`, the command will:
- Update `server.json` with port `9000`
- Configure Dockerfile to `EXPOSE 9000`
- Set docker-compose port mapping to `9000:9000`

## Environment Variables

The following environment variables are configured in docker-compose.yml:

| Variable | Description | Example |
|----------|-------------|---------|
| `ENVIRONMENT` | Application environment mode | `development` or `production` |
| `BOX_SERVER_PROFILE` | CommandBox server profile (production only) | `production` |
| `DB_HOST` | Database hostname (Docker service name) | `db` |
| `DB_PORT` | Database port | `3306`, `5432`, `1433`, `1521` |
| `DB_NAME` | Database name | `wheels` |
| `DB_USER` | Database username | `wheels` or `sa` |
| `DB_PASSWORD` | Database password | `wheels` or `Wheels123!` |
| `DB_SID` | Oracle SID (Oracle only) | `FREE` |
| `DB_TYPE` | Database type (H2/SQLite only) | `h2` or `sqlite` |

## Starting Your Docker Environment

After running `wheels docker init`, start your containers:

```bash
# Start in detached mode
docker-compose up -d

# Start with build (after code changes in production)
docker-compose up -d --build

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f app
docker-compose logs -f nginx

# Stop containers
docker-compose down

# Stop and remove volumes (WARNING: deletes database data)
docker-compose down -v

# Restart a specific service
docker-compose restart app

# Rebuild and restart
docker-compose up -d --build --force-recreate
```

## Notes

- Requires Docker and Docker Compose installed
- Use `--force` to skip confirmation prompts when overwriting existing files
- **server.json is automatically configured for Docker compatibility**:
  - `web.host` changed to `0.0.0.0` (required for Docker networking)
  - `openBrowser` set to `false` (no GUI in containers)
  - `web.http.port` updated to match --port or existing value
  - `CFConfigFile` added if missing
  - CF engine version set (e.g., `lucee@6`)
- Custom `--port` overrides the port from `server.json`
- Port priority: `--port` argument > `server.json` > default (8080)
- Database passwords are set to defaults suitable for **development only**
- **Production deployments MUST use secrets management and secure passwords**
- Production mode creates security-hardened configurations with non-root users
- Nginx adds reverse proxy capabilities for load balancing, caching, and security
- H2 and SQLite databases run embedded within the application container
- Volume mounts in development assume Wheels framework development structure
- When using `--nginx`, the app is only exposed internally to nginx
- CFConfig.json is updated with datasource configuration (skipped for H2 and SQLite)

## Troubleshooting

### Port conflicts
**Problem**: Port already in use on host machine

**Solutions**:
- Update the port in `server.json` before running `wheels docker init`
- Use `--port` argument to specify a different port
- Manually edit the ports in `docker-compose.yml` after generation
- Stop the conflicting service: `lsof -ti:8080 | xargs kill`

### Database connection issues
**Problem**: Application cannot connect to database

**Solutions**:
- Ensure the database container is fully started: `docker-compose logs db`
- Check for initialization errors in database logs
- Verify CFConfig.json has correct datasource configuration
- Confirm the `wheels-dev` datasource name matches your application config
- For MSSQL, ensure password meets complexity requirements
- Wait for database to fully initialize (can take 30-60 seconds first time)

### Permission issues
**Problem**: Permission denied errors in production mode

**Solutions**:
- The generated files have `777` permissions for development convenience
- Production Dockerfile runs as `appuser` (UID 1001)
- Ensure all files are readable by UID 1001
- Check volume mount permissions on host
- Adjust file permissions: `chmod -R 755 /path/to/app`

### Nginx not routing requests
**Problem**: 502 Bad Gateway or connection refused

**Solutions**:
- Verify app service is running: `docker-compose ps`
- Check app service logs: `docker-compose logs app`
- Ensure app is listening on the correct port internally
- Verify nginx config syntax: `docker-compose exec nginx nginx -t`
- Check nginx logs: `docker-compose logs nginx`
- Restart services: `docker-compose restart app nginx`

### Force overwrite not working
**Problem**: Still getting prompted despite using `--force`

**Solutions**:
- Ensure correct syntax: `wheels docker init --force` (not `--force=true`)
- Check for boolean parameter issues in command
- Use the exact parameter name: `--force`

### H2 database not working
**Problem**: H2 extension not loading or database errors

**Solutions**:
- Verify H2 extension was added to Dockerfile
- Check Lucee admin for H2 extension installation
- Ensure CFConfig.json doesn't have conflicting datasource config
- Check application logs for H2 initialization errors
- H2 works with Lucee only (not Adobe ColdFusion)

### SQLite database not working
**Problem**: SQLite connection errors or database not found

**Solutions**:
- Verify `./db/` directory exists in the container
- Check file permissions on database file (especially in production mode with UID 1001)
- Ensure absolute paths are used in datasource configuration
- SQLite JDBC driver is included by default (no extension installation needed)
- Check application logs for SQLite initialization errors
- Verify database file path in application settings
- In production, ensure database file is accessible by `appuser` (UID 1001)

### Container not accessible from host
**Problem**: Cannot access the application at http://localhost:8080

**Solutions**:
- Verify `server.json` has `web.host` set to `0.0.0.0` (not `localhost` or `127.0.0.1`)
- Check if port is already in use: `lsof -ti:8080` (Unix) or `netstat -ano | findstr :8080` (Windows)
- Ensure docker-compose port mapping matches server.json port
- Check container logs: `docker-compose logs app`
- Restart containers: `docker-compose restart app`
- If manually edited, run `wheels docker init --force` to regenerate proper configuration

### Application attempts to open browser
**Problem**: Errors about browser opening or display issues

**Solutions**:
- Verify `server.json` has `openBrowser: false`
- Run `wheels docker init --force` to update server.json automatically
- Manually set `"openBrowser": false` in server.json
- Rebuild containers: `docker-compose up -d --build`

## See Also

- [wheels docker deploy](docker-deploy.md) - Deploy using Docker
- [wheels deploy](../deploy/deploy.md) - General deployment commands
- [CommandBox Docker Images](https://hub.docker.com/r/ortussolutions/commandbox) - Official CommandBox images
- [Docker Compose Documentation](https://docs.docker.com/compose/) - Docker Compose reference
- [Nginx Documentation](https://nginx.org/en/docs/) - Nginx configuration reference
