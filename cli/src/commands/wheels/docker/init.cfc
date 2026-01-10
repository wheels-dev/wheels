/**
 * Initialize Docker configuration for development
 *
 * {code:bash}
 * wheels docker:init
 * wheels docker:init --db=mysql
 * wheels docker:init --db=postgres --dbVersion=13
 * wheels docker:init --db=sqlite
 * wheels docker:init --db=oracle
 * wheels docker:init --db=oracle --dbVersion=23-slim
 * {code}
 */
component extends="DockerCommand" {

    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    /**
     * @db Database to use (h2, sqlite, mysql, postgres, mssql, oracle)
     * @dbVersion Database version to use
     * @cfengine ColdFusion engine to use (lucee, adobe)
     * @cfVersion ColdFusion engine version
     * @port Application port (overrides server.json)
     * @force Overwrite existing Docker files without confirmation
     * @production Generate production-ready configuration
     * @nginx Include Nginx reverse proxy
     */
    function run(
        string db="mysql",
        string dbVersion="",
        string cfengine="lucee",
        string cfVersion="6",
        string port="",
        boolean force=false,
        boolean production=false,
        boolean nginx=false
    ) {
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(
            argStruct=arguments,
            allowedValues={
                db: ["h2", "sqlite", "mysql", "postgres", "mssql", "oracle"],
                cfengine: ["lucee", "adobe"]
            }
        );
        // Welcome message
        detailOutput.header("Wheels Docker Configuration");

        // Interactive prompts for Deployment Configuration
        local.appName = ask("Application Name (default: #listLast(getCWD(), '\/')#): ");
        if (!len(trim(local.appName))) {
            local.appName = listLast(getCWD(), '\/');
        }
        
        local.imageName = ask("Docker Image Name (default: #local.appName#): ");
        if (!len(trim(local.imageName))) {
            local.imageName = local.appName;
        }
        
        print.line().boldCyanLine("Production Server Configuration").toConsole();
        local.serverHost = ask("Server Host/IP (e.g. 192.168.1.10): ");
        local.serverUser = "";
        
        if (len(trim(local.serverHost))) {
            local.serverUser = ask("Server User (default: ubuntu): ");
            if (!len(trim(local.serverUser))) {
                local.serverUser = "ubuntu";
            }
        }
        print.line().toConsole();

        // Check for existing files if force is not set
        if (!arguments.force) {
            local.existingFiles = [];
            if (fileExists(fileSystemUtil.resolvePath("Dockerfile"))) {
                arrayAppend(local.existingFiles, "Dockerfile");
            }
            if (fileExists(fileSystemUtil.resolvePath("docker-compose.yml"))) {
                arrayAppend(local.existingFiles, "docker-compose.yml");
            }
            if (fileExists(fileSystemUtil.resolvePath(".dockerignore"))) {
                arrayAppend(local.existingFiles, ".dockerignore");
            }
            if (fileExists(fileSystemUtil.resolvePath("config/deploy.yml"))) {
                arrayAppend(local.existingFiles, "config/deploy.yml");
            }

            if (arrayLen(local.existingFiles)) {
                detailOutput.line();
                detailOutput.statusWarning("The following Docker files already exist:");
                for (local.file in local.existingFiles) {
                    detailOutput.output("  - #local.file#", true);
                }
                detailOutput.line();

                if (!confirm("Do you want to overwrite these files? [y/n]")) {
                    detailOutput.statusFailed("Operation cancelled.");
                    return;
                }
            }
        }

        // Welcome message
        detailOutput.header("Wheels Docker Configuration");

        // Get application port - priority: command argument > server.json > default
        if (len(arguments.port) && isNumeric(arguments.port)) {
            local.appPort = val(arguments.port);
            detailOutput.statusSuccess("Using port #local.appPort# from command argument");
        } else {
            local.appPort = getAppPortFromServerJson();
        }

        // Update server.json for Docker compatibility (host and port)
        updateServerJsonForDocker(local.appPort);

        // Set CF engine
        setCFengine(arguments.cfengine, arguments.cfVersion);
        // Create Docker configuration files
        detailOutput.subHeader("Creating Docker Configuration Files");        
        createDockerfile(arguments.cfengine, arguments.cfVersion, local.appPort, arguments.db, arguments.production);
        createDockerCompose(arguments.db, arguments.dbVersion, arguments.cfengine, arguments.cfVersion, local.appPort, arguments.production, arguments.nginx);
        createDockerIgnore(arguments.production);
        configureDatasource(arguments.db);
        
        // Create Deployment Config
        createDeployConfig(local.appName, local.imageName, local.serverHost, local.serverUser);

        // Create Nginx configuration if requested
        if (arguments["nginx"]) {
            createNginxConfig(local.appPort, arguments.production);
        }

        detailOutput.line();
        detailOutput.statusSuccess("Docker configuration created successfully!");
        detailOutput.line();
        detailOutput.statusInfo("To start your Docker environment:");
        detailOutput.output("docker-compose up -d", true);
        detailOutput.line();
    }

    private function createDockerfile(string cfengine, string cfVersion, numeric appPort, string db, boolean production=false) {
        local.dockerContent = '';

        local.H2extension = '';
        if (arguments.cfengine == "lucee" && lCase(arguments.db) eq 'h2') {
            local.H2extension = '
##Add the H2 extension
ADD https://ext.lucee.org/org.lucee.h2-2.1.214.0001L.lex /usr/local/lib/serverHome/WEB-INF/lucee-server/deploy/org.lucee.h2-2.1.214.0001L.lex
            ';
        }
        // Note: SQLite JDBC driver is included with Lucee/CommandBox by default - no extension needed
        if (arguments.production) {
            // Production Dockerfile with optimizations
            local.dockerContent = 'FROM ortussolutions/commandbox:latest
#local.H2extension#
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
EXPOSE #arguments.appPort#

## Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://127.0.0.1:#arguments.appPort#/ || exit 1

## Start the application
CMD ["box", "server", "start", "--console"]';
        } else {
            // Development Dockerfile
            local.dockerContent = 'FROM ortussolutions/commandbox:latest
#local.H2extension#
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
EXPOSE #arguments.appPort#

## Set Healthcheck URI
ENV HEALTHCHECK_URI         "http://127.0.0.1:#arguments.appPort#/"

## Start the application
CMD ["box", "server", "start", "--console", "--force"]';
        }

        file action='write' file='#fileSystemUtil.resolvePath("Dockerfile")#' mode='777' output='#trim(local.dockerContent)#';
        detailOutput.create("Dockerfile");
    }

    private function createDockerCompose(string db, string dbVersion, string cfengine, string cfVersion, numeric appPort, boolean production=false, boolean nginx=false) {
        local.dbService = '';
        local.dbEnvironment = '';

        switch(arguments.db) {
            case "mysql":
                local.dbVersion = len(arguments.dbVersion) ? arguments.dbVersion : "8.0";
                local.dbService = '  db:
    image: mysql:#local.dbVersion#
    environment:
      MYSQL_ROOT_PASSWORD: wheels
      MYSQL_DATABASE: wheels
      MYSQL_USER: wheels
      MYSQL_PASSWORD: wheels
    ports:
      - "3306:3306"
    volumes:
      - db_data:/var/lib/mysql';
                local.dbEnvironment = '      
      DB_HOST: db
      DB_PORT: 3306
      DB_NAME: wheels
      DB_USER: wheels
      DB_PASSWORD: wheels';
                break;

            case "postgres":
                local.dbVersion = len(arguments.dbVersion) ? arguments.dbVersion : "15";
                local.dbService = '  db:
    image: postgres:#local.dbVersion#
    environment:
      POSTGRES_USER: wheels
      POSTGRES_PASSWORD: wheels
      POSTGRES_DB: wheels
    ports:
      - "5432:5432"
    volumes:
      - db_data:/var/lib/postgresql/data';
                local.dbEnvironment = '      
      DB_HOST: db
      DB_PORT: 5432
      DB_NAME: wheels
      DB_USER: wheels
      DB_PASSWORD: wheels';
                break;

            case "mssql":
                local.dbVersion = len(arguments.dbVersion) ? arguments.dbVersion : "2019-latest";
                local.dbService = '  db:
    image: mcr.microsoft.com/mssql/server:#local.dbVersion#
    environment:
      ACCEPT_EULA: Y
      SA_PASSWORD: Wheels123!
      MSSQL_DB: wheels
    ports:
      - "1433:1433"
    volumes:
      - db_data:/var/opt/mssql';
                local.dbEnvironment = '
      DB_HOST: db
      DB_PORT: 1433
      DB_NAME: wheels
      DB_USER: sa
      DB_PASSWORD: Wheels123!';
                break;

            case "oracle":
                local.dbVersion = len(arguments.dbVersion) ? arguments.dbVersion : "latest";
                local.dbService = '  db:
    image: gvenzl/oracle-free:#local.dbVersion#
    environment:
      ORACLE_PASSWORD: wheels
      APP_USER: wheels
      APP_USER_PASSWORD: wheels
    ports:
      - "1521:1521"
    volumes:
      - db_data:/opt/oracle/oradata';
                local.dbEnvironment = '
      DB_HOST: db
      DB_PORT: 1521
      DB_SID: FREE
      DB_USER: wheels
      DB_PASSWORD: wheels';
                break;

            case "h2":
                // H2 runs embedded, no separate service needed
                local.dbService = '';
                local.dbEnvironment = '
      DB_TYPE: h2';
                break;

            case "sqlite":
                // SQLite runs embedded (file-based), no separate service needed
                local.dbService = '';
                local.dbEnvironment = '
      DB_TYPE: sqlite';
                break;
        }

        // Determine environment and volumes based on production mode
        local.envMode = arguments.production ? "production" : "development";
        local.restartPolicy = arguments.production ? '
    restart: always' : '';

        // Configure app service ports based on nginx presence
        local.appPorts = '';
        if (!arguments.nginx) {
            // Expose app port directly if no nginx
            local.appPorts = '
    ports:
      - "#arguments.appPort#:#arguments.appPort#"';
        } else {
            // Only expose internally if using nginx
            local.appPorts = '
    expose:
      - #arguments.appPort#';
        }

        // Configure volumes based on mode
        local.volumes = '';
        if (arguments.production) {
            // Production: no source volume mounts
            local.volumes = '';
        } else {
            // Development: mount source for hot reload
            local.volumes = '
    volumes:
      - .:/app
      - ../../../core/src/wheels:/app/vendor/wheels
      - ../../../docs:/app/vendor/wheels/docs
      - ../../../tests:/app/tests';
        }

        // Build app depends_on based on database
        local.appDependsOn = '';
        if (len(local.dbService)) {
            local.appDependsOn = '
    depends_on:
      - db';
        }

        // Build app service
        local.composeContent = 'version: "3.8"

services:
  app:
    build: .#local.appPorts#
    environment:
      ENVIRONMENT: #local.envMode##local.dbEnvironment##local.volumes##local.restartPolicy##local.appDependsOn#';

        if (!arguments.production) {
            local.composeContent &= '
    command: sh -c "box install && box server start --console --force"';
        }

        // Add database service if needed
        if (len(local.dbService)) {
            local.composeContent &= '

#local.dbService#';
        }

        // Add nginx service if requested
        if (arguments.nginx) {
            local.nginxPort = arguments.production ? '80' : '8080';
            local.composeContent &= '

  nginx:
    image: nginx:alpine
    ports:
      - "#local.nginxPort#:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro#local.restartPolicy#
    depends_on:
      - app';
        }

        local.composeContent &= '

volumes:
  db_data:';

        file action='write' file='#fileSystemUtil.resolvePath("docker-compose.yml")#' mode='777' output='#trim(local.composeContent)#';
        detailOutput.create("docker-compose.yml");
    }

    private function createDockerIgnore(boolean production=false) {
        local.ignoreContent = '.git
.gitignore
node_modules
.CommandBox
server.json
logs
tests
.env
*.log';

        if (arguments.production) {
            // Additional exclusions for production
            local.ignoreContent &= '
README.md
*.md
.vscode
.idea
.DS_Store';
        }

        file action='write' file='#fileSystemUtil.resolvePath(".dockerignore")#' mode='777' output='#trim(local.ignoreContent)#';
        detailOutput.create(".dockerignore");
    }

    private function createNginxConfig(numeric appPort, boolean production=false) {
        local.sslConfig = '';
        local.productionHeaders = '';

        if (arguments.production) {
            local.productionHeaders = '
        ## Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;

        ## Gzip compression
        gzip on;
        gzip_vary on;
        gzip_min_length 1024;
        gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;';
        }

        local.nginxContent = 'events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ## Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    ## Performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;

    upstream app_backend {
        server app:#arguments.appPort#;
    }

    server {
        listen 80;
        server_name _;

        ## Max upload size
        client_max_body_size 100M;
#local.productionHeaders#

        location / {
            proxy_pass http://app:#arguments.appPort#;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            ## WebSocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            ## Timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        ## Static assets caching
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            proxy_pass http://app:#arguments.appPort#;
            proxy_cache_valid 200 1d;
            expires 1d;
            add_header Cache-Control "public, immutable";
        }

        ## Health check endpoint
        location /health {
            access_log off;
            proxy_pass http://app:#arguments.appPort#;
        }
    }
}';

        file action='write' file='#fileSystemUtil.resolvePath("nginx.conf")#' mode='777' output='#trim(local.nginxContent)#';
        detailOutput.create("nginx.conf");
    }

    private function getAppPortFromServerJson() {
        local.serverJsonPath = fileSystemUtil.resolvePath("server.json");
        local.appPort = 8080; // Default port

        // Check if server.json exists and try to extract port
        if (fileExists(local.serverJsonPath)) {
            try {
                local.serverContent = fileRead(local.serverJsonPath);
                local.serverData = deserializeJSON(local.serverContent);

                // Extract port from server.json if available
                if (structKeyExists(local.serverData, "web") &&
                    structKeyExists(local.serverData.web, "http") &&
                    structKeyExists(local.serverData.web.http, "port")) {
                    local.appPort = val(local.serverData.web.http.port);
                    detailOutput.statusSuccess("Using port #local.appPort# from existing server.json");
                } else {
                    detailOutput.statusWarning("Port not found in server.json, using default port #local.appPort#");
                }
            } catch (any e) {
                detailOutput.statusFailed("Error reading server.json: #e.message#");
                detailOutput.statusWarning("Using default port #local.appPort#");
            }
        } else {
            detailOutput.statusWarning("server.json not found, using default port #local.appPort#");
        }

        return local.appPort;
    }
    
    private function configureDatasource(string db) {
        local.cfconfigPath = fileSystemUtil.resolvePath("CFConfig.json");
        local.datasourceConfig = {};

        // Skip H2 and SQLite as they're file-based and don't need container connection
        if (arguments.db == "h2") {
            detailOutput.statusInfo("Skipping datasource configuration for H2 (embedded database)");
            return;
        }
        if (arguments.db == "sqlite") {
            detailOutput.statusInfo("Skipping datasource configuration for SQLite (file-based database)");
            return;
        }
        
        // Read existing CFConfig.json or create new structure
        if (fileExists(local.cfconfigPath)) {
            try {
                local.cfconfigContent = fileRead(local.cfconfigPath);
                if ( len( local.cfconfigContent ) ) {
                    local.cfconfigData = deserializeJSON(local.cfconfigContent);
                } else {
                    local.cfconfigData = {};
                }
            } catch (any e) {
                detailOutput.statusFailed("Error reading CFConfig.json: #e.message#");
                local.cfconfigData = { "datasources": {} };
            }
        } else {
            local.cfconfigData = { "datasources": {} };
        }
        
        // Configure datasource based on database type
        switch(arguments.db) {
            case "mysql":
                local.datasourceConfig = {
                    "class":"com.mysql.cj.jdbc.Driver",
                    "connectionLimit":"-1",
                    "connectionTimeout":"1",
                    "database":"wheels",
                    "dbdriver":"MySQL",
                    "dsn":"jdbc:mysql://{host}:{port}/{database}",
                    "host":"db",
                    "password":"wheels",
                    "port":"3306",
                    "username":"wheels"
                };
                break;
                
            case "postgres":
                local.datasourceConfig = {
                    "class":"org.postgresql.Driver",
                    "connectionLimit":"-1",
                    "connectionTimeout":"1",
                    "database":"wheels",
                    "dbdriver":"PostgreSql",
                    "dsn":"jdbc:postgresql://{host}:{port}/{database}",
                    "host":"db",
                    "password":"wheels",
                    "port":"5433",
                    "username":"wheels"
                };
                break;
                
            case "mssql":
                local.datasourceConfig = {
                    "class":"com.microsoft.sqlserver.jdbc.SQLServerDriver",
                    "connectionLimit":"-1",
                    "connectionTimeout":"1",
                    "database":"wheels",
                    "dbdriver":"MSSQL",
                    "dsn":"jdbc:sqlserver://{host}:{port}",
                    "host":"db",
                    "password":"Wheels123!",
                    "port":"1433",
                    "username":"sa"
                };
                break;

            case "oracle":
                local.datasourceConfig = {
                    "class":"oracle.jdbc.OracleDriver",
                    "connectionLimit":"-1",
                    "connectionTimeout":"1",
                    "database":"FREE",
                    "dbdriver":"Oracle",
                    "dsn":"jdbc:oracle:thin:@{host}:{port}/{database}",
                    "host":"db",
                    "password":"wheels",
                    "port":"1521",
                    "username":"wheels"
                };
                break;
        }
        
        // Add or update the 'wheels-dev' datasource
        local.cfconfigData.datasources["wheels-dev"] = local.datasourceConfig;
        
        // Write updated CFConfig.json
        local.updatedContent = serializeJSON(local.cfconfigData);
        file action='write' file='#local.cfconfigPath#' mode='777' output='#local.updatedContent#';
        detailOutput.create("CFConfig.json with #arguments.db# datasource configuration");
    }

    private function updateServerJsonForDocker(required numeric port) {
        local.serverJsonPath = fileSystemUtil.resolvePath("server.json");

        // Check if server.json exists
        if (!fileExists(local.serverJsonPath)) {
            detailOutput.statusWarning("server.json not found, creating new one with Docker settings");
            local.serverContent = {};
        } else {
            try {
                local.serverContent = deserializeJSON(fileRead(local.serverJsonPath));
            } catch (any e) {
                detailOutput.statusFailed("Error reading server.json: #e.message#");
                detailOutput.statusWarning("Creating new server.json with Docker settings");
                local.serverContent = {};
            }
        }

        // Ensure web structure exists
        if (!structKeyExists(local.serverContent, "web")) {
            local.serverContent.web = {};
        }

        // Update host to 0.0.0.0 for Docker compatibility
        local.serverContent.web.host = "0.0.0.0";

        // Disable browser opening in Docker (no GUI available)
        local.serverContent.openBrowser = false;

        // Ensure HTTP structure exists
        if (!structKeyExists(local.serverContent.web, "http")) {
            local.serverContent.web.http = {};
        }

        // Update or set port
        local.serverContent.web.http.port = toString(arguments.port);

        // Add CFConfigFile if not present
        if (!structKeyExists(local.serverContent, "CFConfigFile")) {
            local.serverContent.CFConfigFile = "CFConfig.json";
        }

        // Write updated server.json
        try {
            local.updatedContent = serializeJSON(local.serverContent);
            file action='write' file='#local.serverJsonPath#' mode='777' output='#local.updatedContent#';
            detailOutput.update("server.json for Docker (host: 0.0.0.0, port: #arguments.port#, openBrowser: false)");
        } catch (any e) {
            detailOutput.statusFailed("Error writing server.json: #e.message#");
        }
    }

    private function setCFengine(string cfengine, string cfVersion){
        local.serverJsonPath = fileSystemUtil.resolvePath("server.json");
        
        // Check if server.json exists
        if (fileExists(local.serverJsonPath)) {
            try {
                local.serverContent = deserializeJSON(fileRead(local.serverJsonPath));
                // Ensure the structure exists
                if (!structKeyExists(local.serverContent, "app")) {
                    local.serverContent.app = {};
                }
                // Set the cfengine
                local.serverContent.app.cfengine = "#arguments.cfengine#@#arguments.cfVersion#";
                local.updatedContent = serializeJSON(local.serverContent);
                file action='write' file='#local.serverJsonPath#' mode='777' output='#local.updatedContent#';
            } catch ( any e ){
                detailOutput.error("Not able to read server.json: #e.message#");
                return;
            }
        } else {
            detailOutput.error("server.json does not exist at #local.serverJsonPath#");
            return;
        }
    }

    private function createDeployConfig(string appName, string imageName, string serverHost, string serverUser) {
        if (!directoryExists(fileSystemUtil.resolvePath("config"))) {
            directoryCreate(fileSystemUtil.resolvePath("config"));
        }
        
        local.deployContent = "name: #arguments.appName#
image: #arguments.imageName#
servers:
";
        if (len(trim(arguments.serverHost))) {
            local.deployContent &= "  - host: #arguments.serverHost#
    user: #arguments.serverUser#
    role: production
";
        } else {
             local.deployContent &= "  ## - host: 192.168.1.10
  ##   user: ubuntu
  ##   role: production
";
        }
        
        file action='write' file='#fileSystemUtil.resolvePath("config/deploy.yml")#' mode='777' output='#trim(local.deployContent)#';
        detailOutput.create("config/deploy.yml");
    }
}