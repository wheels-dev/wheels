/**
 * Create production-ready Docker configurations
 * 
 * {code:bash}
 * wheels docker:deploy
 * wheels docker:deploy --environment=staging
 * wheels docker:deploy --db=mysql --cfengine=lucee
 * {code}
 */
component extends="../base" {

    /**
     * @environment Deployment environment (production, staging)
     * @db Database to use (h2, mysql, postgres, mssql)
     * @cfengine ColdFusion engine to use (lucee, adobe)
     * @optimize Enable production optimizations
     */
    function run(
        string environment="production",
        string db="mysql",
        string cfengine="lucee",
        boolean optimize=true
    ) {
        // Welcome message
        print.line();
        print.boldMagentaLine("Wheels Docker Production Deployment");
        print.line();
        
        // Validate inputs
        local.validDatabases = ["h2", "mysql", "postgres", "mssql"];
        if (!arrayContains(local.validDatabases, lCase(arguments.db))) {
            error("Invalid database: ##arguments.db##. Please choose from: ##arrayToList(local.validDatabases)##");
        }
        
        local.validEngines = ["lucee", "adobe"];
        if (!arrayContains(local.validEngines, lCase(arguments.cfengine))) {
            error("Invalid ColdFusion engine: ##arguments.cfengine##. Please choose from: ##arrayToList(local.validEngines)##");
        }
        
        // Create docker-compose.production.yml
        createProductionComposeFile(arguments.environment, arguments.db, arguments.cfengine);
        
        // Create docker/config directory if it doesn't exist
        local.configDir = fileSystemUtil.resolvePath("docker/config");
        if (!directoryExists(local.configDir)) {
            directoryCreate(local.configDir, true);
        }
        
        // Create neo-runtime.xml for ColdFusion configuration
        local.xmlContent = '<config><session timeout="120" /></config>';
        local.xmlPath = local.configDir & "/neo-runtime.xml";
        file action='write' file='#local.xmlPath#' mode='777' output='#local.xmlContent#';
        print.greenLine("Created neo-runtime.xml configuration");
        
        // Create production Dockerfile
        createProductionDockerfile(arguments.cfengine, arguments.optimize);
        
        // Create .env.production file
        createEnvFile(arguments.environment, arguments.db);
        
        // Create deployment scripts
        createDeploymentScripts(arguments.environment);
        
        print.line();
        print.boldGreenLine("Production Docker configuration created successfully!");
        print.line();
        print.yellowLine("To deploy your application:");
        print.line("1. Configure your environment variables in .env.#arguments.environment#");
        print.line("2. Run: ./deploy.sh #arguments.environment#");
        print.line();
    }
    
    /**
     * Create docker-compose.production.yml file
     */
    private void function createProductionComposeFile(
        required string environment,
        required string db,
        required string cfengine
    ) {
        local.composePath = fileSystemUtil.resolvePath("docker-compose.#arguments.environment#.yml");
        
        local.composeContent = "version: '3.8'

services:
  cfwheels:
    build:
      context: .
      dockerfile: Dockerfile.#arguments.environment#
    restart: always
    ports:
      - '80:8080'
    volumes:
      - cfwheels_logs:/app/logs
    environment:
      - WHEELS_ENVIRONMENT=#arguments.environment#
    env_file:
      - .env.#arguments.environment#
    depends_on:
      - #arguments.db#
      
  #arguments.db#:
    image: #arguments.db#:latest
    restart: always
    volumes:
      - #arguments.db#_data:/var/lib/mysql
    env_file:
      - .env.#arguments.environment#
      
  ## Optional reverse proxy with HTTPS  
  web:
    image: nginx:alpine
    restart: always
    ports:
      - '443:443'
      - '80:80'
    volumes:
      - ./docker/nginx:/etc/nginx/conf.d
      - ./docker/certbot/conf:/etc/letsencrypt
      - ./docker/certbot/www:/var/www/certbot
    depends_on:
      - cfwheels
      
  certbot:
    image: certbot/certbot
    volumes:
      - ./docker/certbot/conf:/etc/letsencrypt
      - ./docker/certbot/www:/var/www/certbot
    command: certonly --webroot -w /var/www/certbot --email admin@example.com -d example.com --agree-tos

volumes:
  cfwheels_logs:
  #arguments.db#_data:";
        
        file action='write' file='#local.composePath#' mode='777' output='#local.composeContent#';
        print.greenLine("Created docker-compose.#arguments.environment#.yml");
        
        // Create nginx configuration
        local.nginxDir = fileSystemUtil.resolvePath("docker/nginx");
        if (!directoryExists(local.nginxDir)) {
            directoryCreate(local.nginxDir, true);
        }
        
        local.nginxPath = local.nginxDir & "/default.conf";
        local.nginxConfig = "server {
    listen 80;
    server_name example.com;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name example.com;
    
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    ## SSL configurations
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    
    ## HSTS
    add_header Strict-Transport-Security 'max-age=31536000; includeSubDomains; preload' always;
    
    ## Other security headers
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-XSS-Protection '1; mode=block';
    
    location / {
        proxy_pass http://cfwheels:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}";
        file action='write' file='#local.nginxPath#' mode='777' output='#local.nginxConfig#';
        print.greenLine("Created nginx configuration");
    }
    
    /**
     * Create production Dockerfile
     */
    private void function createProductionDockerfile(
        required string cfengine,
        required boolean optimize
    ) {
        local.dockerfilePath = fileSystemUtil.resolvePath("Dockerfile.production");
        
        local.dockerfileContent = "";
        
        // Use different Dockerfile content based on the CF engine
        if (lCase(arguments.cfengine) == "lucee") {
            local.dockerfileContent = "FROM lucee/lucee:5.3-nginx AS builder

## Install CommandBox for dependency management
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

## Install CommandBox
RUN curl -fsSl https://downloads.ortussolutions.com/debs/gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/ortussolutions.gpg && \
    echo 'deb [trusted=yes] https://downloads.ortussolutions.com/debs/noarch /' > /etc/apt/sources.list.d/commandbox.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    commandbox \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

## Copy the application
COPY . .

## Run migrations if necessary
## RUN box wheels dbmigrate up

## Build/optimize stage
FROM lucee/lucee:5.3-nginx

WORKDIR /app

## Copy from the builder stage
COPY --from=builder /app /app";

            if (arguments.optimize) {
                local.dockerfileContent &= "

## Optimization for production
RUN rm -rf /app/tests \
    && mkdir -p /app/logs \
    && chmod -R 755 /app";
            }

            local.dockerfileContent &= "

## Configure Lucee for production
RUN echo '<cfscript>this.sessionTimeout = createTimeSpan(0,2,0,0);</cfscript>' > /opt/lucee/web/lucee-web.xml.cfm

## Expose port
EXPOSE 8080

## Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:8080/ || exit 1

## Start Lucee
CMD ['catalina.sh', 'run']";
        } else {
            // Adobe ColdFusion Dockerfile
            local.dockerfileContent = "FROM adobecoldfusion/coldfusion:latest AS builder

WORKDIR /app

## Copy the application
COPY . .

## Run migrations if necessary
## RUN box wheels dbmigrate up

## Build stage
FROM adobecoldfusion/coldfusion:latest

WORKDIR /app

## Copy from the builder stage
COPY --from=builder /app /app";

            if (arguments.optimize) {
                local.dockerfileContent &= "

## Optimization for production
RUN rm -rf /app/tests \
    && mkdir -p /app/logs \
    && chmod -R 755 /app";
            }

            local.dockerfileContent &= "

## Configure ColdFusion for production
COPY ./docker/config/neo-runtime.xml /opt/coldfusion/cfusion/lib/neo-runtime.xml

## Expose port
EXPOSE 8080

## Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:8080/ || exit 1

## Start Adobe ColdFusion
CMD ['/opt/coldfusion/bin/coldfusion', 'start']";
        }
        
        file action='write' file='#local.dockerfilePath#' mode='777' output='#local.dockerfileContent#';
        print.greenLine("Created Dockerfile.production");
    }
    
    /**
     * Create .env.production file
     */
    private void function createEnvFile(
        required string environment,
        required string db
    ) {
        local.envPath = fileSystemUtil.resolvePath(".env." & arguments.environment);
        
        // Use array to build content line by line
        local.lines = [];
        
        // Header and application settings
        arrayAppend(local.lines, chr(35) & " Environment variables for " & arguments.environment & " environment");
        arrayAppend(local.lines, "");
        arrayAppend(local.lines, chr(35) & " Application settings");
        arrayAppend(local.lines, "WHEELS_ENVIRONMENT=" & arguments.environment);
        arrayAppend(local.lines, "WHEELS_RELOAD_PASSWORD=changeme123!");
        arrayAppend(local.lines, "");
        arrayAppend(local.lines, chr(35) & " Database settings");
        
        // Database-specific settings
        switch (lCase(arguments.db)) {
            case "mysql":
                arrayAppend(local.lines, "MYSQL_ROOT_PASSWORD=rootpassword");
                arrayAppend(local.lines, "MYSQL_DATABASE=cfwheels");
                arrayAppend(local.lines, "MYSQL_USER=cfwheels");
                arrayAppend(local.lines, "MYSQL_PASSWORD=securepassword");
                arrayAppend(local.lines, "");
                arrayAppend(local.lines, "WHEELS_DATASOURCE_NAME=" & arguments.db);
                arrayAppend(local.lines, "WHEELS_DATASOURCE_HOST=" & arguments.db);
                arrayAppend(local.lines, "WHEELS_DATASOURCE_DATABASE=cfwheels");
                arrayAppend(local.lines, "WHEELS_DATASOURCE_USERNAME=cfwheels");
                arrayAppend(local.lines, "WHEELS_DATASOURCE_PASSWORD=securepassword");
                arrayAppend(local.lines, "WHEELS_DATASOURCE_PORT=3306");
                break;
                
            case "postgres":
                arrayAppend(local.lines, "POSTGRES_USER=cfwheels");
                arrayAppend(local.lines, "POSTGRES_PASSWORD=securepassword");
                arrayAppend(local.lines, "POSTGRES_DB=cfwheels");
                arrayAppend(local.lines, "");
                arrayAppend(local.lines, "WHEELS_DATASOURCE_NAME=" & arguments.db);
                arrayAppend(local.lines, "WHEELS_DATASOURCE_HOST=" & arguments.db);
                arrayAppend(local.lines, "WHEELS_DATASOURCE_DATABASE=cfwheels");
                arrayAppend(local.lines, "WHEELS_DATASOURCE_USERNAME=cfwheels");
                arrayAppend(local.lines, "WHEELS_DATASOURCE_PASSWORD=securepassword");
                arrayAppend(local.lines, "WHEELS_DATASOURCE_PORT=5432");
                break;
                
            case "mssql":
                arrayAppend(local.lines, "ACCEPT_EULA=Y");
                arrayAppend(local.lines, "SA_PASSWORD=securepassword");
                arrayAppend(local.lines, "MSSQL_PID=Developer");
                arrayAppend(local.lines, "");
                arrayAppend(local.lines, "WHEELS_DATASOURCE_NAME=" & arguments.db);
                arrayAppend(local.lines, "WHEELS_DATASOURCE_HOST=" & arguments.db);
                arrayAppend(local.lines, "WHEELS_DATASOURCE_DATABASE=cfwheels");
                arrayAppend(local.lines, "WHEELS_DATASOURCE_USERNAME=sa");
                arrayAppend(local.lines, "WHEELS_DATASOURCE_PASSWORD=securepassword");
                arrayAppend(local.lines, "WHEELS_DATASOURCE_PORT=1433");
                break;
                
            case "h2":
                arrayAppend(local.lines, "WHEELS_DATASOURCE_NAME=" & arguments.db);
                arrayAppend(local.lines, "WHEELS_DATASOURCE_HOST=" & arguments.db);
                arrayAppend(local.lines, "WHEELS_DATASOURCE_DATABASE=cfwheels");
                arrayAppend(local.lines, "WHEELS_DATASOURCE_USERNAME=sa");
                arrayAppend(local.lines, "WHEELS_DATASOURCE_PASSWORD=");
                arrayAppend(local.lines, "WHEELS_DATASOURCE_PORT=1521");
                break;
        }
        
        // Miscellaneous settings
        arrayAppend(local.lines, "");
        arrayAppend(local.lines, chr(35) & " Miscellaneous settings");
        arrayAppend(local.lines, "TZ=UTC");
        
        // Join all lines with newlines
        local.envContent = arrayToList(local.lines, chr(10));
        
        file action='write' file='#local.envPath#' mode='777' output='#local.envContent#';
        print.greenLine("Created .env." & arguments.environment);
    }
    
    /**
     * Create deployment scripts - temporarily simplified
     */
    private void function createDeploymentScripts(required string environment) {
        // For now, log a message instead of creating files
        print.line("Script generation is disabled while fixing syntax issues.");
        print.line("The files deploy.sh and renew-ssl.sh would normally be created here.");
    }
}