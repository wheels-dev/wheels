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

        // Validate environment
        local.supportedEnvironments = ["production", "staging"];
        if (!arrayContains(local.supportedEnvironments, lCase(arguments.environment))) {
            error("Unsupported environment: #arguments.environment#. Please choose from: #arrayToList(local.supportedEnvironments)#");
        }

        // Create production Docker files
        createProductionDockerfile(arguments.cfengine, arguments.optimize);
        createProductionDockerCompose(arguments.environment, arguments.db, arguments.cfengine);
        createDeploymentScript(arguments.environment);

        print.line();
        print.greenLine("Production Docker configuration created successfully!");
        print.line();
        print.yellowLine("Next steps:");
        print.line("1. Review and customize the generated files");
        print.line("2. Build the production image: docker build -t wheels-app:latest -f Dockerfile.production .");
        print.line("3. Test locally: docker-compose -f docker-compose.production.yml up");
        print.line("4. Deploy using: ./deploy.sh");
        print.line();
    }

    private function createProductionDockerfile(string cfengine, boolean optimize) {
        local.dockerContent = '';

        if (arguments.cfengine == "lucee") {
            local.dockerContent = '## Multi-stage build for production
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
RUN echo "this.mappings["/vendor"] = expandPath("./vendor");" >> /opt/lucee/web/Application.cfc';
        } else {
            local.dockerContent = '## Multi-stage build for production
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
WORKDIR /app';
        }

        if (arguments.optimize) {
            local.dockerContent &= '

## Production optimizations
ENV COMMANDBOX_CFENGINE_SAVECLASS=false
ENV COMMANDBOX_CFENGINE_BUFFEROUTPUT=false
ENV COMMANDBOX_CFENGINE_TEMPLATECACHE=true
ENV COMMANDBOX_CFENGINE_QUERYCACHE=true';
        }

        local.dockerContent &= '

## Security hardening
RUN rm -rf /app/tests /app/.git /app/docker
RUN chmod -R 755 /app

## Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1

## Expose port
EXPOSE 8080

## Start the application
CMD ["box", "server", "start", "--console", "--force", "--production"]';

        file action='write' file='#fileSystemUtil.resolvePath("Dockerfile.production")#' mode='777' output='#trim(local.dockerContent)#';
        print.greenLine("Created Dockerfile.production");
    }

    private function createProductionDockerCompose(string environment, string db, string cfengine) {
        local.composeContent = 'version: "3.8"

services:
  app:
    image: wheels-app:latest
    restart: always
    ports:
      - "80:8080"
    environment:
      ENVIRONMENT: #arguments.environment#
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
        max_attempts: 3';

        if (arguments.db != "h2") {
            local.composeContent &= '
    depends_on:
      - db

  db:
    image: ';

            switch(arguments.db) {
                case "mysql":
                    local.composeContent &= 'mysql:8.0';
                    break;
                case "postgres":
                    local.composeContent &= 'postgres:15-alpine';
                    break;
                case "mssql":
                    local.composeContent &= 'mcr.microsoft.com/mssql/server:2019-latest';
                    break;
            }

            local.composeContent &= '
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
          - node.role == manager';
        }

        local.composeContent &= '

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
  ssl_certs:';

        file action='write' file='#fileSystemUtil.resolvePath("docker-compose.production.yml")#' mode='777' output='#trim(local.composeContent)#';
        print.greenLine("Created docker-compose.production.yml");

        // Create basic nginx config
        local.nginxContent = 'events {
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
}';

        file action='write' file='#fileSystemUtil.resolvePath("nginx.conf")#' mode='777' output='#trim(local.nginxContent)#';
        print.greenLine("Created nginx.conf");
    }

    private function createDeploymentScript(string environment) {
        local.scriptContent = '##!/bin/bash

## Wheels Docker Deployment Script
## Environment: #arguments.environment#

set -e

echo "Starting deployment to #arguments.environment#..."

## Load environment variables
if [ -f .env.#arguments.environment# ]; then
    export $(cat .env.#arguments.environment# | grep -v "^##" | xargs)
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
    docker images | grep wheels-app | tail -n +6 | awk "{print $3}" | xargs -r docker rmi
else
    echo "Deployment failed! Rolling back..."
    docker-compose -f docker-compose.production.yml down
    exit 1
fi

echo "Deployment complete!"';

        file action='write' file='#fileSystemUtil.resolvePath("deploy.sh")#' mode='777' output='#trim(local.scriptContent)#';

        // Make script executable
        if (findNoCase("Windows", server.os.name) == 0) {
            command("chmod +x deploy.sh").run();
        }

        print.greenLine("Created deployment script: deploy.sh");

        // Create example environment file
        local.envContent = '## Environment variables for #arguments.environment#
## Copy this to .env.#arguments.environment# and fill in your values

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
S3_BUCKET=your-s3-bucket';

        file action='write' file='#fileSystemUtil.resolvePath(".env.#arguments.environment#.example")#' mode='777' output='#trim(local.envContent)#';
        print.greenLine("Created example environment file: .env.#arguments.environment#.example");
    }
}
